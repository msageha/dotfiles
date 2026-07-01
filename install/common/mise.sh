#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

function validate_mise() {
    if ! command -v mise &>/dev/null; then
        printf "%b\n" "${RED}mise could not be found, please install mise first.${NC}"
        exit 1
    fi
}

function install() {
    printf "%b\n" "${BLUE}Installing mise tools...${NC}"
    mise install --yes
    printf "%b\n" "${BLUE}All mise tools installed successfully.${NC}"
}

function prune() {
    printf "%b\n" "${BLUE}Pruning unused tool versions...${NC}"
    mise prune --yes
}

function main() {
    validate_mise
    install
    prune
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
