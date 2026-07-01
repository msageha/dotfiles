#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

GIT_OPEN_URL="https://raw.githubusercontent.com/paulirish/git-open/master/git-open"
GIT_OPEN_PATH="$HOME/Works/bin/git-open"

function install_git_open() {
    if [ -x "$GIT_OPEN_PATH" ]; then
        printf "%b\n" "${BLUE}git-open is already installed. Skipping.${NC}"
        return
    fi

    printf "%b\n" "${BLUE}Installing git-open command...${NC}"
    mkdir -p "$HOME/Works/bin"
    curl -fsSL -o "$GIT_OPEN_PATH" "$GIT_OPEN_URL"
    chmod +x "$GIT_OPEN_PATH"
    printf "%b\n" "${BLUE}git-open installed to $GIT_OPEN_PATH${NC}"
}

function main() {
    install_git_open
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
