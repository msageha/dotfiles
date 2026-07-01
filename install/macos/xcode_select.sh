#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function install() {
    if ! xcode-select -p &>/dev/null; then
        printf "%b\n" "${BLUE}Installing Xcode command line tools...${NC}"
        xcode-select --install
        # xcode-select --install は非同期のため、インストール完了を待機
        printf "%b\n" "${BLUE}Xcode command line tools のインストール完了を待機中...${NC}"
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
        printf "%b\n" "${BLUE}Xcode command line tools のインストールが完了しました。${NC}"
    else
        printf "%b\n" "${BLUE}Xcode command line tools are already installed.${NC}"
    fi
}

function main() {
    install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
