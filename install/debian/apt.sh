#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
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
    printf "%b\n" "${BLUE}Updating APT package lists...${NC}"
    run_privileged apt -yq update
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

    # shells / vcs
    fish
    zsh
    # chezmoi apply が .chezmoiexternal.toml (type = "git-repo") の取得に使うため、
    # SKIP_CLI_TOOLS の値に関係なく base に必要 (apk_base と同じ扱い)
    git
)

apt_tools=(
    build-essential
    gnupg
    pkgconf
    unzip
    wget
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
    run_privileged apt install -yq "${apt_install_opts[@]}" "${apt_base[@]}"
}

function install_tools() {
    printf "%b\n" "${BLUE}Installing APT tool packages...${NC}"
    run_privileged apt install -yq "${apt_install_opts[@]}" "${apt_tools[@]}"
}

function install_chezmoi() {
    printf "%b\n" "${BLUE}Installing chezmoi...${NC}"
    if ! command -v chezmoi &>/dev/null; then
        # インストール先を明示する (未指定だと ./bin に落ちる)。docker/Dockerfile.debian と同形式
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
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
        curl -fsSL https://get.docker.com | run_privileged sh
        run_privileged usermod -aG docker "$USER"
    else
        printf "%b\n" "${BLUE}Docker is already installed.${NC}"
    fi
}

function upgrade() {
    if [ -n "${CI:-}" ]; then
        printf "%b\n" "${BLUE}Skipping APT upgrade in CI.${NC}"
        return
    fi

    printf "%b\n" "${BLUE}Upgrading APT packages...${NC}"
    run_privileged apt -yq upgrade
}

function clean() {
    printf "%b\n" "${BLUE}Cleaning up APT...${NC}"
    run_privileged apt -yq autoremove
    run_privileged apt -yq autoclean
    run_privileged apt -yq clean
    run_privileged rm -rf /var/lib/apt/lists/*
}

function main() {
    # 呼び出し側 (run_once_before の chezmoi テンプレート) が SKIP_CLI_TOOLS を必ず渡す契約。
    # 未設定は設定ミスとみなして落とす ("false" へ暗黙フォールバックしない)。
    if [ -z "${SKIP_CLI_TOOLS+x}" ]; then
        printf "%b\n" "${RED}SKIP_CLI_TOOLS is not set; it must be exported by the caller.${NC}" >&2
        exit 1
    fi

    if ! has_privilege; then
        printf "%b\n" "${YELLOW}root/sudo 権限が無いため APT 関連の操作をすべてスキップします。${NC}" >&2
        return 0
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
