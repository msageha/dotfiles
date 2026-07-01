#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function install_rust() {
    if ! command -v rustc &>/dev/null || ! command -v cargo &>/dev/null; then
        printf "%b\n" "${BLUE}Installing Rust via rustup...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        printf "%b\n" "${BLUE}Rust is already installed.${NC}"
    fi
}

function install_binstall() {
    if ! command -v cargo-binstall &>/dev/null; then
        printf "%b\n" "${BLUE}Installing cargo-binstall...${NC}"
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
}

rust_tools=(
    bat
    bottom
    du-dust
    duf
    eza
    fd-find
    hexyl
    procs
    ripgrep
    tokei
    websocat
    starship
    zoxide
)
function install() {
    printf "%b\n" "${BLUE}Installing Rust tools...${NC}"
    cargo binstall --no-confirm --force "${rust_tools[@]}"
}

function main() {
    install_rust
    install_binstall
    install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
