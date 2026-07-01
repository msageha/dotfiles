#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

# Create necessary directories
function create_directories() {
    printf "%b\n" "${BLUE}Creating directories...${NC}"
    mkdir -p "$HOME/Downloads"
    mkdir -p "$HOME/Documents"
    mkdir -p "$HOME/Works/bin"
    mkdir -p "$HOME/Works/pkg"
    mkdir -p "$HOME/.ssh"
    mkdir -p "$HOME/.local/state"  # シェル/REPL 履歴 (HISTFILE 等) の保存先
}

function main() {
    create_directories
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
