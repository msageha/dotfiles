#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function install_antigravity_cli() {
    printf "%b\n" "${BLUE}Installing antigravity-cli...${NC}"
    if ! command -v antigravity &>/dev/null; then
        curl -fsSL https://antigravity.google/cli/install.sh | bash
    else
        agy update
    fi
}

function install_claude_code() {
    printf "%b\n" "${BLUE}Installing Claude Code...${NC}"
    if ! command -v claude &>/dev/null; then
        curl -fsSL https://claude.ai/install.sh | bash
    else
        claude update
    fi
}

function install_codex() {
    printf "%b\n" "${BLUE}Installing Codex CLI...${NC}"
    if ! command -v codex &>/dev/null; then
        curl -fsSL https://chatgpt.com/codex/install.sh | sh
    else
        codex update
    fi
}

function main() {
    printf "%b\n" "${BLUE}=== Installing coding agents ===${NC}"

    install_antigravity_cli
    install_claude_code
    install_codex

    printf "%b\n" "${BLUE}=== All coding agents installed! ===${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
