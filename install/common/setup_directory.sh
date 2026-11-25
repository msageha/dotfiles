#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function create_directories() {
    log_step "Creating directories..."
    mkdir -p "$HOME/.local/bin"   # ローカルコマンド (git-open / GOBIN / uv / mise 等) の配置先
    mkdir -p "$HOME/.local/state" # シェル / REPL 履歴 (HISTFILE 等) の保存先
    mkdir -p "$HOME/.cache/zsh"   # zsh 補完キャッシュ (zcompdump) の保存先
}

# XDG の場所を使うよう設定したツール (env.sh・fish の config.fish・go env) は元の場所を読まないので、
# 既存のデータを移す。移し先にもデータがあると機械的には統合できないので、元の場所を残して知らせる
function move_to_xdg() {
    local from="$1" to="$2"
    [ -e "$from" ] || [ -L "$from" ] || return 0
    if [ -e "$to" ] || [ -L "$to" ]; then
        log_warn "${from} と ${to} の両方があります。${from} は読まれないので、必要なデータを ${to} へ移してから削除してください。"
        return 0
    fi
    # symlink は移すと相対パスのリンク先が変わる
    if [ -L "$from" ]; then
        log_warn "${from} は symlink なので移しません。${to} から参照できるようにしてください。"
        return 0
    fi
    mkdir -p "$(dirname "$to")"
    mv "$from" "$to"
}

function move_data_to_xdg() {
    log_step "Moving data to XDG base directories..."
    move_to_xdg "$HOME/.ipython" "$HOME/.config/ipython"
    move_to_xdg "$HOME/.jupyter" "$HOME/.config/jupyter"
    move_to_xdg "$HOME/Works/pkg/mod" "$HOME/.cache/go/mod"
    if [[ "$(uname)" == "Darwin" ]]; then
        move_to_xdg "$HOME/.matplotlib" "$HOME/.config/matplotlib"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_directories
    move_data_to_xdg
fi
