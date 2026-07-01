#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

# fastfetch は PPA (Launchpad) 経由で導入するため Ubuntu 専用。
# Debian には PPA が無いので install/debian には置かない。
function install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        printf "%b\n" "${BLUE}fastfetch is already installed.${NC}"
        return 0
    fi
    printf "%b\n" "${BLUE}Installing fastfetch...${NC}"
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    sudo apt install -yq fastfetch
}

function main() {
    # apt.sh と同じく呼び出し側 (run_once_before) が SKIP_CLI_TOOLS を必ず渡す契約。
    # 未設定は設定ミスとみなして落とす ("false" へ暗黙フォールバックしない)。
    if [ -z "${SKIP_CLI_TOOLS+x}" ]; then
        printf "%b\n" "${RED}SKIP_CLI_TOOLS is not set; it must be exported by the caller.${NC}" >&2
        exit 1
    fi
    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        printf "%b\n" "${BLUE}Skipping fastfetch (SKIP_CLI_TOOLS=true).${NC}"
        return 0
    fi
    install_fastfetch
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
