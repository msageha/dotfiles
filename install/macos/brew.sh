#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)


function install_brew() {
    if ! command -v brew &>/dev/null; then
        printf "%b\n" "${BLUE}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        printf "%b\n" "${BLUE}Homebrew is already installed.${NC}"
    fi
}

function doctor() {
    printf "%b\n" "${BLUE}Running brew doctor...${NC}"
    brew doctor || true
}

function update() {
    printf "%b\n" "${BLUE}Running brew update...${NC}"
    brew update
}

# Formula tools — テスト/開発に必要なため CI でも導入する
formulae=(
    antigravity-cli
    mise
    chezmoi
    dockutil
    exiv2
    fish
    git
    git-secrets
    gnupg
    googleworkspace-cli
    graphviz
    htop
    httpie
    imagemagick
    mole
    mupdf
    mysql-client
    p7zip
    pigz
    pkgconf
    poppler
    pv
    qpdf
    rename
    rlwrap
    satococoa/tap/wtp
    tree
    vbindiff
    wget

    # CTF tools
    # aircrack-ng bfg binutils binwalk cifer dex2jar dns2tcp fcrackzip foremost hydra john knock netpbm nmap pngcheck socat sqlmap tcpflow tcpreplay ucspi-tcp xpdf x
)

# Cask (GUI アプリ) — CI ではインストールしない
casks=(
    1password
    android-studio
    bettertouchtool
    chatgpt
    claude
    claude-code
    codex
    cyberduck
    datagrip
    discord
    drawio
    dropbox
    figma
    ghostty
    goland
    google-chrome
    google-drive
    google-japanese-ime
    grok-build
    insomnia
    mole-app
    ngrok
    obsidian
    openvpn-connect
    orbstack
    pycharm
    raycast
    simple-comic
    the-unarchiver
    visual-studio-code
    vlc
    wakatime
    webstorm
    xcodes-app
    zoom
)

function install() {
    printf "%b\n" "${BLUE}Installing formula packages...${NC}"
    brew install "${formulae[@]}"

    # cask は macOS 専用のため CI (Linux) ではスキップする
    if [ -n "${CI:-}" ]; then
        printf "%b\n" "${BLUE}CI 環境のため cask のインストールをスキップします。${NC}"
        return 0
    fi
    printf "%b\n" "${BLUE}Installing cask packages...${NC}"
    brew install --cask "${casks[@]}"
}

# brew upgrade の対象から除外するパッケージ。
# antigravity-cli は自己更新する CLI で、agy 自身が /opt/homebrew/bin/agy を
# 上書きするため brew upgrade と衝突する (Error: It seems there is already a
# Binary at '/opt/homebrew/bin/agy')。更新は agy の自己更新に委ね、brew upgrade
# の対象からは外す。install は引き続き brew で行う。
upgrade_exclude=(
    antigravity-cli
)

function upgrade() {
    # --greedy は cask を含む全更新で時間がかかるため CI ではスキップする
    if [ -n "${CI:-}" ]; then
        printf "%b\n" "${BLUE}CI 環境のため brew upgrade をスキップします。${NC}"
        return 0
    fi
    printf "%b\n" "${BLUE}Upgrading packages...${NC}"

    # 更新可能なパッケージ (formula/cask 両方) を列挙し、除外対象を取り除く。
    local exclude_pattern
    exclude_pattern="$(printf '%s\n' "${upgrade_exclude[@]}")"
    local outdated
    outdated="$(brew outdated --quiet | grep -vxF "$exclude_pattern" || true)"

    if [ -z "$outdated" ]; then
        printf "%b\n" "${BLUE}更新対象のパッケージはありません。${NC}"
        return 0
    fi

    # outdated は改行区切りの名前リスト。意図的に word splitting して個別に渡す。
    # shellcheck disable=SC2086
    brew upgrade $outdated
}

function cleanup() {
    printf "%b\n" "${BLUE}Cleaning up...${NC}"
    brew cleanup --prune=all
}

function main() {
    install_brew
    doctor
    update
    install
    upgrade
    cleanup
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
