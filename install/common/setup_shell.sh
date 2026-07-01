#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function validate_bash() {
    if ! command -v bash &>/dev/null; then
        printf "%b\n" "${RED}Bash shell could not be found, please install Bash first.${NC}"
        exit 1
    fi
}

function validate_zsh() {
    if ! command -v zsh &>/dev/null; then
        printf "%b\n" "${RED}Zsh shell could not be found, please install Zsh first.${NC}"
        exit 1
    fi
}

function validate_fish() {
    if ! command -v fish &>/dev/null; then
        printf "%b\n" "${RED}Fish shell could not be found, please install Fish first.${NC}"
        exit 1
    fi
}

function create_bashrc() {
    printf "%b\n" "${BLUE}Creating .bashrc and source .bash_profile...${NC}"
    touch "$HOME/.bashrc"
    if ! grep -Fxq "source \$HOME/.bash_profile" "$HOME/.bashrc"; then
        # If not found, append the source command to .bashrc
        echo "source \$HOME/.bash_profile" >> "$HOME/.bashrc"
    fi
}

function create_zshrc() {
    printf "%b\n" "${BLUE}Creating .zshrc and source .zprofile...${NC}"
    touch "$HOME/.zshrc"
    if ! grep -Fxq "source \$HOME/.zprofile" "$HOME/.zshrc"; then
        # If not found, append the source command to .zshrc
        echo "source \$HOME/.zprofile" >> "$HOME/.zshrc"
    fi
}

function create_fish_config() {
    printf "%b\n" "${BLUE}Creating Fish config.fish...${NC}"
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
}

function main() {
    validate_bash
    validate_zsh
    validate_fish
    create_bashrc
    create_zshrc
    create_fish_config
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
