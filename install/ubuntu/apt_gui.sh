#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

# apt で入れる GUI 関連パッケージ
apt_apps=(
    fcitx5-mozc  # 日本語入力
)

# snap で入れる GUI アプリ
snap_apps=(
    discord
)

# snap (--classic) で入れる GUI アプリ
snap_classic_apps=(
    code               # Visual Studio Code
    ghostty
    pycharm-community
    goland
    datagrip
    webstorm
)

function has_privilege() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    sudo -v 2>/dev/null
}

function update() {
    printf "%b\n" "${BLUE}Updating APT package lists...${NC}"
    sudo apt update -yq
}

function install_apt_apps() {
    printf "%b\n" "${BLUE}Installing APT GUI packages...${NC}"
    sudo apt install -yq "${apt_apps[@]}"
}

function install_snap_apps() {
    printf "%b\n" "${BLUE}Installing snap apps...${NC}"
    for app in "${snap_apps[@]}"; do
        if snap list "$app" &>/dev/null; then
            printf "%b\n" "${BLUE}${app} is already installed. Skipping${NC}"
            continue
        fi
        printf "%b\n" "${BLUE}Installing ${app}...${NC}"
        sudo snap install "$app"
    done
    for app in "${snap_classic_apps[@]}"; do
        if snap list "$app" &>/dev/null; then
            printf "%b\n" "${BLUE}${app} is already installed. Skipping${NC}"
            continue
        fi
        printf "%b\n" "${BLUE}Installing ${app} (classic)...${NC}"
        sudo snap install "$app" --classic
    done
}

# Google Chrome は Ubuntu の apt リポジトリに無い (Google 配布のみ) ため公式 .deb を取得して入れる。
# .deb が apt リポジトリと署名鍵を自動設定するので、以降は apt upgrade で更新される。
# Linux 版は amd64 と arm64 のみ提供 (arm64 は 2026 Q2 提供開始)。それ以外や未公開時はスキップする。
function install_chrome() {
    printf "%b\n" "${BLUE}Installing Google Chrome...${NC}"
    if command -v google-chrome &>/dev/null; then
        printf "%b\n" "${BLUE}Google Chrome is already installed.${NC}"
        return 0
    fi

    local arch
    arch="$(dpkg --print-architecture)"
    case "$arch" in
        amd64 | arm64) ;;
        *)
            printf "%b\n" "${YELLOW}Google Chrome is not available for ${arch}. Skipping.${NC}"
            return 0
            ;;
    esac

    local deb
    deb="$(mktemp --suffix=.deb)"
    # shellcheck disable=SC2064  # $deb を今展開して trap に固定する
    trap "rm -f '$deb'" RETURN
    if ! curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_${arch}.deb" -o "$deb"; then
        printf "%b\n" "${YELLOW}Failed to download Google Chrome for ${arch} (build may not be published yet). Skipping.${NC}"
        return 0
    fi
    sudo apt install -yq "$deb"
}

function main() {
    printf "%b\n" "${BLUE}=== Starting GUI Application Installation ===${NC}"

    if ! has_privilege; then
        printf "%b\n" "${YELLOW}root/sudo 権限が無いため GUI アプリのインストールをすべてスキップします。${NC}" >&2
        return 0
    fi

    update
    install_apt_apps
    install_chrome
    install_snap_apps

    printf "%b\n" "${BLUE}=== All installations completed! ===${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
