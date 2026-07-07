#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function update() {
    printf "%b\n" "${BLUE}Updating APT package lists...${NC}"
    sudo apt -yq update
}

# Docker など非ネイティブ環境では推奨パッケージを入れずイメージを軽量化する
# (imagemagick/graphviz の推奨で opencv/vtk/gdal/rocm 等が芋づる導入されるのを防ぐ)。
# native Ubuntu (デスクトップ等) では従来どおり推奨込みでインストールする。
apt_install_opts=()
if [ -f /.dockerenv ]; then
    apt_install_opts=(--no-install-recommends)
fi

apt_base=(
    # base / infra
    ca-certificates
    curl
    wget
    unzip
    gnupg
    build-essential
    pkgconf

    # shells / vcs
    fish
    zsh
    git
)

# software-properties-common (add-apt-repository を提供) は Ubuntu の PPA 追加
# (install/ubuntu/fastfetch.sh) でのみ使う。Debian trixie 以降は同パッケージが
# 公式リポジトリから削除されているため、Ubuntu のときだけ base に加える。
if [ "$(. /etc/os-release && echo "${ID:-}")" = "ubuntu" ]; then
    apt_base+=(software-properties-common)
fi

apt_tools=(
    # CLI tools
    exiv2
    graphviz
    htop
    imagemagick
    mupdf-tools
    pigz
    poppler-utils
    pv
    qpdf
    rename
    rlwrap
    tree
    vbindiff
)

function install_base() {
    printf "%b\n" "${BLUE}Installing base APT packages...${NC}"
    sudo apt install -yq "${apt_install_opts[@]}" "${apt_base[@]}"
}

function install_tools() {
    printf "%b\n" "${BLUE}Installing APT tool packages...${NC}"
    sudo apt install -yq "${apt_install_opts[@]}" "${apt_tools[@]}"
}

function install_chezmoi() {
    printf "%b\n" "${BLUE}Installing chezmoi...${NC}"
    if ! command -v chezmoi &>/dev/null; then
        sh -c "$(curl -fsLS get.chezmoi.io)"
    else
        printf "%b\n" "${BLUE}chezmoi is already installed.${NC}"
    fi
}


function install_docker() {
    if [ -f /.dockerenv ]; then
        printf "%b\n" "${BLUE}Running inside Docker, skipping Docker installation.${NC}"
        return
    fi
    printf "%b\n" "${BLUE}Installing Docker...${NC}"
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$USER"
    else
        printf "%b\n" "${BLUE}Docker is already installed.${NC}"
    fi
}

function upgrade() {
    printf "%b\n" "${BLUE}Upgrading APT packages...${NC}"
    sudo apt -yq upgrade
}

function clean() {
    printf "%b\n" "${BLUE}Cleaning up APT...${NC}"
    sudo apt -yq autoremove
    sudo apt -yq autoclean
    sudo apt -yq clean
    sudo rm -rf /var/lib/apt/lists/*
}

function main() {
    # 呼び出し側 (run_once_before の chezmoi テンプレート) が SKIP_CLI_TOOLS を必ず渡す契約。
    # 未設定は設定ミスとみなして落とす ("false" へ暗黙フォールバックしない)。
    if [ -z "${SKIP_CLI_TOOLS+x}" ]; then
        printf "%b\n" "${RED}SKIP_CLI_TOOLS is not set; it must be exported by the caller.${NC}" >&2
        exit 1
    fi

    update
    install_base
    # apt_tools と chezmoi/docker は base に対する追加分。SKIP_CLI_TOOLS=true でまとめてスキップする。
    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        printf "%b\n" "${BLUE}Skipping apt tools and chezmoi/docker (SKIP_CLI_TOOLS=true).${NC}"
    else
        install_tools
        install_chezmoi
        install_docker
    fi
    upgrade
    clean
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
