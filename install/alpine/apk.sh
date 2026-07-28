#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

function has_privilege() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    sudo -v 2>/dev/null || sudo -n true 2>/dev/null
}

# root では sudo を介さず直接実行する
function run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

function update() {
    printf "%b\n" "${BLUE}Updating APK package index...${NC}"
    run_privileged apk update
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
    run_privileged apk add "${apk_base[@]}"
}

function upgrade() {
    if [ -n "${CI:-}" ]; then
        printf "%b\n" "${BLUE}CI 環境のため APK upgrade をスキップします。${NC}"
        return 0
    fi

    printf "%b\n" "${BLUE}Upgrading APK packages...${NC}"
    run_privileged apk upgrade
}

function clean() {
    printf "%b\n" "${BLUE}Cleaning up APK cache...${NC}"
    run_privileged rm -rf /var/cache/apk/*
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
