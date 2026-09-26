#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function create_directories() {
    log_step "Creating directories..."
    mkdir -p "$HOME/.local/bin"   # ローカルコマンド (git-open / GOBIN / uv / mise 等) の配置先
    mkdir -p "$HOME/.local/state" # シェル / REPL 履歴 (HISTFILE 等) の保存先
    mkdir -p "$HOME/.cache/zsh"   # zsh 補完キャッシュ (zcompdump) の保存先
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_directories
fi
