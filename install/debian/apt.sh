#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Docker コンテナ内では推奨パッケージを入れずイメージを軽くする (imagemagick / graphviz の推奨パッケージで opencv / vtk / gdal / rocm 等まで入るため)
apt_install_opts=()
if [ -f /.dockerenv ]; then
    apt_install_opts=(--no-install-recommends)
fi

# SKIP_CLI_TOOLS=true でも導入する最小セット
apt_base=(
    ca-certificates
    curl
    fish
    zsh
    git
)

apt_tools=(
    build-essential
    gnupg
    pkgconf
    unzip
    wget
    exiv2
    git-secrets
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

function update() {
    log_step "Updating APT package lists..."
    run_privileged apt -yq update
}

function install_base() {
    log_step "Installing base APT packages..."
    run_privileged apt install -yq "${apt_install_opts[@]}" "${apt_base[@]}"
}

function install_tools() {
    log_step "Installing APT tool packages..."
    run_privileged apt install -yq "${apt_install_opts[@]}" "${apt_tools[@]}"
}

function install_chezmoi() {
    log_step "Installing chezmoi..."
    if command -v chezmoi &>/dev/null; then
        log_step "chezmoi is already installed."
        return 0
    fi
    # -b を省くとカレントディレクトリの ./bin に入る
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
}

# get.docker.com の curl | sh は検証していないスクリプトを root で実行することになるため、
# 公式の apt リポジトリから GPG 署名を検証して入れる (https://docs.docker.com/engine/install/debian/#install-using-the-repository)
function install_docker() {
    if [ -f /.dockerenv ]; then
        log_step "Running inside Docker, skipping Docker installation."
        return 0
    fi
    log_step "Installing Docker..."
    if command -v docker &>/dev/null; then
        log_step "Docker is already installed."
        return 0
    fi

    local os_id codename
    os_id="$(. /etc/os-release && echo "$ID")"
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    if [ "$os_id" != "ubuntu" ] && [ "$os_id" != "debian" ]; then
        log_warn "Docker の apt リポジトリは ubuntu/debian のみ対応です (ID=${os_id})。スキップします。"
        return 0
    fi

    run_privileged install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${os_id}/gpg" | run_privileged tee /etc/apt/keyrings/docker.asc > /dev/null
    run_privileged chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${os_id} ${codename} stable" \
        | run_privileged tee /etc/apt/sources.list.d/docker.list > /dev/null
    run_privileged apt -yq update
    run_privileged apt install -yq "${apt_install_opts[@]}" \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # $USER は cron や一部のコンテナでは未設定で、set -u で落ちるため id -un を使う
    run_privileged usermod -aG docker "$(id -un)"
}

function upgrade() {
    # GitHub Actions の runner では apt upgrade が snap refresh を誘発し、外部からのダウンロードに長時間かかる
    if [ -n "${CI:-}" ]; then
        log_step "Skipping APT upgrade in CI."
        return 0
    fi
    log_step "Upgrading APT packages..."
    run_privileged apt -yq upgrade
}

function clean() {
    log_step "Cleaning up APT..."
    run_privileged apt -yq autoremove
    run_privileged apt -yq autoclean
    run_privileged apt -yq clean
    run_privileged rm -rf /var/lib/apt/lists/*
}

function main() {
    # SKIP_CLI_TOOLS は run_once_before テンプレートが必ず export する
    if [ -z "${SKIP_CLI_TOOLS+x}" ]; then
        log_error "SKIP_CLI_TOOLS is not set; it must be exported by the caller."
        exit 1
    fi

    if ! has_privilege; then
        log_warn "root/sudo 権限が無いため APT 関連の操作をすべてスキップします。"
        return 0
    fi

    update
    install_base
    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        log_step "Skipping apt tools and chezmoi/docker (SKIP_CLI_TOOLS=true)."
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
