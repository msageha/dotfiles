#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

function install_git_open() {
    if [ -x "$HOME/.local/bin/git-open" ]; then
        printf "%b\n" "${BLUE}git-open is already installed. Skipping.${NC}"
        return
    fi

    printf "%b\n" "${BLUE}Installing git-open command...${NC}"
    curl -fsSL -o "$HOME/.local/bin/git-open" \
        "https://raw.githubusercontent.com/paulirish/git-open/63c0e77aaf18b72c839b1113c1e2f9514413643b/git-open"
    chmod +x "$HOME/.local/bin/git-open"
    printf "%b\n" "${BLUE}git-open installed to $HOME/.local/bin/git-open${NC}"
}

function main() {
    install_git_open
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
