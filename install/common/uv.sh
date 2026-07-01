#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

function validate_uv() {
    if ! command -v uv &>/dev/null; then
        printf "%b\n" "${RED}uv could not be found, please install uv first.${NC}"
        exit 1
    fi
}

function install() {
    printf "%b\n" "${BLUE}Installing uv-managed CLI tools...${NC}"
    local -a tools=(ruff ty pre-commit)
    for tool in "${tools[@]}"; do
        printf "%b\n" "${BLUE}Installing ${tool}...${NC}"
        uv tool install "$tool"
    done
    printf "%b\n" "${BLUE}All uv tools installed successfully.${NC}"
}

function main() {
    validate_uv
    install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
