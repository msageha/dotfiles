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

function create_zshrc() {
    log_step "Creating .zshrc and source .zprofile..."
    touch "$HOME/.zshrc"
    local block_begin="# >>> dotfiles zsh init >>>"
    local block_end="# <<< dotfiles zsh init <<<"
    if grep -Fxq "$block_begin" "$HOME/.zshrc" && ! grep -Fxq "$block_end" "$HOME/.zshrc"; then
        log_error "${HOME}/.zshrc の管理ブロック終了マーカー (${block_end}) が見つかりません。巻き込み削除を避けるため更新をスキップします。手動で修復してください。"
        return 0
    fi
    # 管理ブロックは機械ローカルな追記 (installer 由来のブロック等) より先に実行されるよう先頭に置き、
    # 既存ブロックと旧形式の無条件 source (login shell で初期化が二重実行される) は取り除いて書き直す
    {
        printf '%s\n' "$block_begin"
        cat <<'EOF'
# login shell では zsh 自身が ~/.zprofile を読むため、非 login の対話シェルのみ source する
if [[ ! -o login ]]; then
    source "$HOME/.zprofile"
fi
# macOS の /etc/zshrc (~/.zprofile の後・~/.zshrc の前に読まれる) が HISTFILE を
# ~/.zsh_history へ上書きするため、zsh の履歴ファイルは ~/.zshrc 側で設定する。
# SAVEHIST > 0 でないと HISTFILE へ書き込まれない。サイズは bash (.bash_profile) と揃える
HISTFILE="$HOME/.local/state/zsh_history"
HISTSIZE=10000
SAVEHIST=10000
EOF
        printf '%s\n' "$block_end"
        awk -v begin="$block_begin" -v end="$block_end" -v legacy='source $HOME/.zprofile' \
            '$0 == begin {skip=1} $0 == legacy {next} !skip {print} $0 == end {skip=0}' \
            "$HOME/.zshrc"
    } > "$HOME/.zshrc.tmp"
    mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
}

function main() {
    require_command zsh
    create_bashrc
    create_zshrc
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
