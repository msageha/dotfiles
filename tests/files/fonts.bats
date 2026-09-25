#!/usr/bin/env bats

load ../test_helper

function setup() {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    if [[ "$(uname)" == "Darwin" ]]; then
        FONT_DIR="${HOME}/Library/Fonts"
    else
        FONT_DIR="${HOME}/.local/share/fonts"
    fi
}

@test "[files] fonts - powerline fonts" {
    [ -f "${FONT_DIR}/powerline-fonts/Source Code Pro Medium for Powerline.otf" ]
}

@test "[files] fonts - SauceCodePro Nerd Font" {
    ls "${FONT_DIR}"/sauce-code-pro-nerd-font/SauceCodeProNerdFont*.ttf
}

@test "[files] fonts - Source Han Code JP" {
    expected=14
    count=$(find "${FONT_DIR}/source-han-code-jp" -maxdepth 1 -type f -name "SourceHanCodeJP-*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}

@test "[files] fonts - Nerd Fonts Symbols" {
    ls "${FONT_DIR}"/nerd-fonts-symbols/SymbolsNerdFont*.ttf
}
