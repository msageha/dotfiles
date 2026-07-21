#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

function has_privilege() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    sudo -v 2>/dev/null
}

function update() {
    printf "%b\n" "${BLUE}Updating APK package index...${NC}"
    sudo apk update
}

apk_base=(
    # base / infra
    ca-certificates
    curl
    # shells / vcs
    fish
    zsh
    git
)

function install_base() {
    printf "%b\n" "${BLUE}Installing base APK packages...${NC}"
    sudo apk add "${apk_base[@]}"
}

function upgrade() {
    printf "%b\n" "${BLUE}Upgrading APK packages...${NC}"
    sudo apk upgrade
}

function clean() {
    printf "%b\n" "${BLUE}Cleaning up APK cache...${NC}"
    sudo rm -rf /var/cache/apk/*
}

function main() {
    if ! has_privilege; then
        printf "%b\n" "${YELLOW}root/sudo 権限が無いため APK 関連の操作をすべてスキップします。${NC}" >&2
        return 0
    fi

    update
    install_base
    upgrade
    clean
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
