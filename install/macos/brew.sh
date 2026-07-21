#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
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

# base formulae — SKIP_CLI_TOOLS=true でも導入する最小セット。
# 後続の chezmoi スクリプトが前提とするツールのみを置く
# (dockutil: system_settings.sh の dock_apps、fish: setup_shell.sh / fisher.sh、
# git: fonts.sh 等、mise: install/common/mise.sh)。
formulae_base=(
    dockutil
    fish
    mise
)

# Formula tools — テスト/開発に必要なため CI でも導入する。
# SKIP_CLI_TOOLS=true でまとめてスキップする
formulae=(
    exiv2
    git
    git-secrets
    gnupg
    googleworkspace-cli
    graphviz
    htop
    httpie
    imagemagick
    mole
    mysql-client
    poppler
    pv
    satococoa/tap/wtp
    tree
    wget
)

# Cask (GUI アプリ) — CI ではインストールしない。SKIP_GUI_TOOLS=true でもスキップする
casks=(
    1password
    1password-cli
    android-studio
    antigravity-cli
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
    the-unarchiver
    visual-studio-code
    wakatime
    webstorm
    xcodes-app
)

function install() {
    printf "%b\n" "${BLUE}Installing base formula packages...${NC}"
    brew install "${formulae_base[@]}"

    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        printf "%b\n" "${BLUE}Skipping formula tools (SKIP_CLI_TOOLS=true).${NC}"
    else
        printf "%b\n" "${BLUE}Installing formula packages...${NC}"
        brew install "${formulae[@]}"
    fi

    # cask は macOS 専用のため CI (Linux) ではスキップする
    if [ -n "${CI:-}" ]; then
        printf "%b\n" "${BLUE}CI 環境のため cask のインストールをスキップします。${NC}"
        return 0
    fi
    if [ "$SKIP_GUI_TOOLS" = "true" ]; then
        printf "%b\n" "${BLUE}Skipping cask packages (SKIP_GUI_TOOLS=true).${NC}"
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
    # 呼び出し側 (run_once_before の chezmoi テンプレート) が SKIP_CLI_TOOLS /
    # SKIP_GUI_TOOLS を必ず渡す契約。未設定は設定ミスとみなして落とす
    # ("false" へ暗黙フォールバックしない)。
    if [ -z "${SKIP_CLI_TOOLS+x}" ] || [ -z "${SKIP_GUI_TOOLS+x}" ]; then
        printf "%b\n" "${RED}SKIP_CLI_TOOLS / SKIP_GUI_TOOLS are not set; they must be exported by the caller.${NC}" >&2
        exit 1
    fi

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
