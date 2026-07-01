#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)
NERD_FONTS_VERSION="v3.4.0"

function validation() {
    if ! command -v git &>/dev/null; then
        printf "%b\n" "${RED}Git could not be found, please install Git first.${NC}"
        exit 1
    fi
    if ! command -v curl &>/dev/null; then
        printf "%b\n" "${RED}curl could not be found, please install curl first.${NC}"
        exit 1
    fi
    if ! command -v unzip &>/dev/null; then
        printf "%b\n" "${RED}unzip could not be found, please install unzip first.${NC}"
        exit 1
    fi
    if ! command -v tar &>/dev/null; then
        printf "%b\n" "${RED}tar could not be found, please install tar first.${NC}"
        exit 1
    fi
}

function setup_fonts_dir() {
    if [[ "$(uname)" == "Darwin" ]]; then
        FONT_DIR="${HOME}/Library/Fonts"
    else
        FONT_DIR="${HOME}/.local/share/fonts"
    fi
    mkdir -p "$FONT_DIR"
    printf "%b\n" "${BLUE}Font directory set to ${FONT_DIR}${NC}"
}

# 作業ディレクトリを mktemp -d に隔離し、サブシェル関数 + trap EXIT で
# 並列実行時の cwd 競合を避けつつ一時ファイルを確実に削除する。
function install_source_code_pro() (
    if [ -f "$FONT_DIR/Source Code Pro Medium for Powerline.otf" ]; then
        printf "%b\n" "${BLUE}Source Code Pro font already installed.${NC}"
        exit 0
    fi
    printf "%b\n" "${BLUE}Installing Powerline fonts...${NC}"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    git clone --depth=1 https://github.com/powerline/fonts.git "$tmp/fonts"
    (cd "$tmp/fonts" && ./install.sh)
)

function install_sauce_code_pro_nerd_font() (
    if ls "$FONT_DIR"/SauceCodeProNerdFont*.ttf &>/dev/null; then
        printf "%b\n" "${BLUE}SauceCodePro Nerd Font already installed.${NC}"
        exit 0
    fi
    printf "%b\n" "${BLUE}Installing SauceCodePro Nerd Font...${NC}"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/SourceCodePro.zip" --output "$tmp/sauce-code-pro-nerd.zip"
    unzip -o "$tmp/sauce-code-pro-nerd.zip" -d "$tmp/extract"
    find "$tmp/extract" -name '*.ttf' -exec mv {} "$FONT_DIR/" \;
)

function install_source_han_code_jp() (
    if [ -f "$FONT_DIR/SourceHanCodeJP-Medium.otf" ]; then
        printf "%b\n" "${BLUE}Source Han Code JP font already installed.${NC}"
        exit 0
    fi
    printf "%b\n" "${BLUE}Installing Source Han Code JP font...${NC}"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fSL https://github.com/adobe-fonts/source-han-code-jp/archive/refs/tags/2.012R.zip --output "$tmp/source-han-code-jp.zip"
    unzip -j "$tmp/source-han-code-jp.zip" -d "$tmp/extract"
    mv "$tmp"/extract/*.otf "$FONT_DIR/"
)

function install_nerd_fonts_symbols() (
    if ls "$FONT_DIR"/SymbolsNerdFont*.ttf &>/dev/null; then
        printf "%b\n" "${BLUE}Nerd Fonts Symbols already installed.${NC}"
        exit 0
    fi
    printf "%b\n" "${BLUE}Installing Nerd Fonts Symbols Only...${NC}"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/NerdFontsSymbolsOnly.zip" --output "$tmp/nerd-fonts-symbols.zip"
    unzip -o "$tmp/nerd-fonts-symbols.zip" -d "$tmp/extract"
    find "$tmp/extract" -name '*.ttf' -exec mv {} "$FONT_DIR/" \;
)

function main() {
    validation
    setup_fonts_dir

    local pids=()
    local names=()

    install_source_code_pro &
    pids+=($!); names+=("Source Code Pro")
    install_sauce_code_pro_nerd_font &
    pids+=($!); names+=("SauceCodePro Nerd Font")
    install_source_han_code_jp &
    pids+=($!); names+=("Source Han Code JP")
    install_nerd_fonts_symbols &
    pids+=($!); names+=("Nerd Fonts Symbols")

    local failed=()
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed+=("${names[$i]}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf "%b\n" "${RED}Failed to install fonts: ${failed[*]}${NC}"
        exit 1
    fi
    printf "%b\n" "${BLUE}All fonts installed successfully.${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
