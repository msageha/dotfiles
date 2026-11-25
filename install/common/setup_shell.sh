#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function create_bashrc() {
    log_step "Creating .bashrc and source .bash_profile..."
    touch "$HOME/.bashrc"
    if ! grep -Fxq "source \$HOME/.bash_profile" "$HOME/.bashrc"; then
        echo "source \$HOME/.bash_profile" >> "$HOME/.bashrc"
    fi
}

# ZDOTDIR を設定した zsh は $HOME 直下の startup file を読まないので、そこにあるマシン固有の設定 (installer の追記等) を移す。
# 移し先にもあると機械的には統合できず、symlink は移すと相対パスの参照先が変わるので、元の場所を残して知らせる
function move_zsh_files_to_zdotdir() {
    local zdotdir="$HOME/.config/zsh" name from to
    mkdir -p "$zdotdir"
    # ~/.zshenv の先頭の ZDOTDIR (modify_private_dot_zshenv) より後の行が別の値を設定すると、そちらが効いて
    # ~/.config/zsh の設定は読まれない
    if [ -f "$HOME/.zshenv" ] && grep -v -F 'then ZDOTDIR="$HOME/.config/zsh"; fi' "$HOME/.zshenv" | grep -Eq '(^|[^_[:alnum:]])ZDOTDIR='; then
        log_warn "${HOME}/.zshenv が ZDOTDIR を設定しているので、${zdotdir} の設定が読まれない可能性があります。"
    fi
    for name in .zshrc .zlogin .zlogout; do
        from="$HOME/$name"
        to="$zdotdir/$name"
        [ -e "$from" ] || [ -L "$from" ] || continue
        if [ -e "$to" ] || [ -L "$to" ]; then
            log_warn "${from} と ${to} の両方があります。${from} は読まれないので、必要な設定を ${to} へ移してから削除してください。"
        elif [ -L "$from" ]; then
            log_warn "${from} は symlink なので移しません。${from} は読まれないので、${to} から参照できるようにしてください。"
        else
            mv "$from" "$to"
        fi
    done

    [[ "$(uname)" == "Darwin" ]] || return 0
    # Terminal.app は保存したセッションを ${ZDOTDIR:-$HOME}/.zsh_sessions から復元する。起動中のセッションは終了時に
    # 起動時のディレクトリへ書き込むので、Terminal.app の実行中は移さない
    if [ -e "$HOME/.zsh_sessions" ] || [ -L "$HOME/.zsh_sessions" ]; then
        if pgrep -xq Terminal; then
            log_warn "Terminal.app の実行中は ${HOME}/.zsh_sessions を移しません。Terminal.app を終了してから ${zdotdir}/.zsh_sessions へ移してください。"
        elif [ -L "$HOME/.zsh_sessions" ]; then
            log_warn "${HOME}/.zsh_sessions は symlink なので移しません。${zdotdir}/.zsh_sessions から参照できるようにしてください。"
        elif [ -e "$zdotdir/.zsh_sessions" ] || [ -L "$zdotdir/.zsh_sessions" ]; then
            log_warn "${HOME}/.zsh_sessions と ${zdotdir}/.zsh_sessions の両方があります。${HOME}/.zsh_sessions は読まれないので、必要なら移してから削除してください。"
        else
            mv "$HOME/.zsh_sessions" "$zdotdir/.zsh_sessions"
        fi
    fi
    # Terminal.app が共有の履歴として書いていたファイル。.zshrc の HISTFILE と形式が同じとは限らないので統合しない
    if [ -f "$HOME/.zsh_history" ]; then
        log_warn "${HOME}/.zsh_history は読まれません。要る履歴は ${HOME}/.local/state/zsh_history へ移してから削除してください。"
    fi
}

function create_zshrc() {
    # ~/.zshenv (modify_private_dot_zshenv) が設定する ZDOTDIR の下。chezmoi から実行するこのプロセスには ZDOTDIR が無いのでパスを直接書く
    local zshrc="$HOME/.config/zsh/.zshrc"
    log_step "Creating ${zshrc} and source .zprofile..."
    mkdir -p "$(dirname "$zshrc")"
    touch "$zshrc"
    local block_begin="# >>> dotfiles zsh init >>>"
    local block_end="# <<< dotfiles zsh init <<<"
    if grep -Fxq "$block_begin" "$zshrc" && ! grep -Fxq "$block_end" "$zshrc"; then
        log_error "${zshrc} の管理ブロック終了マーカー (${block_end}) が見つかりません。巻き込み削除を避けるため更新をスキップします。手動で修復してください。"
        return 0
    fi
    # 既存の .zshrc の権限 (マシン固有の設定を 0600 にしている等) を、置き換えた後のファイルに引き継ぐ (GNU / BSD の stat)
    local mode
    mode="$(stat -c %a "$zshrc" 2>/dev/null || stat -f %Lp "$zshrc")"
    # 管理ブロックはマシン固有の追記 (installer が足すブロック等) より先に実行されるよう先頭に置く。
    # 既存の管理ブロックは取り除いて書き直す
    {
        printf '%s\n' "$block_begin"
        cat <<'EOF'
# login shell では zsh 自身が $ZDOTDIR/.zprofile を読むため、非 login の対話シェルのみ source する
if [[ ! -o login ]]; then
    source "$ZDOTDIR/.zprofile"
fi
# macOS の /etc/zshrc (.zprofile の後・.zshrc の前に読まれる) が HISTFILE を
# $ZDOTDIR/.zsh_history へ上書きするため、zsh の履歴ファイルは .zshrc 側で設定する。
# SAVEHIST > 0 でないと HISTFILE へ書き込まれない。サイズは bash (.bash_profile) と揃える
HISTFILE="$XDG_STATE_HOME/zsh_history"
HISTSIZE=10000
SAVEHIST=10000
# Terminal.app の /etc/zshrc_Apple_Terminal は、終了時に追記する共有の履歴ファイルを .zshrc より前に
# /etc/zshrc の HISTFILE から決めるので、同じファイルに向け直す
if [[ -n "${SHELL_SESSION_HISTFILE_SHARED-}" ]]; then
    SHELL_SESSION_HISTFILE_SHARED="$HISTFILE"
fi
EOF
        printf '%s\n' "$block_end"
        awk -v begin="$block_begin" -v end="$block_end" \
            '$0 == begin {skip=1} !skip {print} $0 == end {skip=0}' \
            "$zshrc"
    } > "${zshrc}.tmp"
    # symlink はリンク先に書き込んで残す (mv はリンク自体を通常のファイルに置き換える)
    if [ -L "$zshrc" ]; then
        cat "${zshrc}.tmp" > "$zshrc"
        rm "${zshrc}.tmp"
    else
        chmod "$mode" "${zshrc}.tmp"
        mv "${zshrc}.tmp" "$zshrc"
    fi
}

function main() {
    require_command zsh
    create_bashrc
    move_zsh_files_to_zdotdir
    create_zshrc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
