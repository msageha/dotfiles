#!/usr/bin/env bash
set -euo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

function create_directories() {
    printf "%b\n" "${BLUE}Creating directories...${NC}"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Documents"
    mkdir -p "$HOME/Works/pkg"
    mkdir -p "$HOME/.ssh"
    mkdir -p "$HOME/.local/bin"   # ローカルコマンド (git-open / GOBIN / uv / mise 等) の配置先
    mkdir -p "$HOME/.local/state" # シェル/REPL 履歴 (HISTFILE 等) の保存先
}

function main() {
    create_directories
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
