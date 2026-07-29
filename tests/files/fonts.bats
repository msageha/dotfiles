#!/usr/bin/env bats

# bats file_tags=files
# フォントは .chezmoiexternal.toml の archive external として chezmoi apply で
# 導入元ごとのサブディレクトリへ展開される。skip_gui_tools=true の環境では
# 導入されない (external 側のガードと同条件) ため、その場合はスキップする。
function gui_tools_skipped() {
    [ "$(chezmoi execute-template '{{ dig "skip_gui_tools" false . }}' 2>/dev/null)" = "true" ]
}

function setup() {
    if [[ "$(uname)" == "Darwin" ]]; then
        FONT_DIR="${HOME}/Library/Fonts"
    else
        FONT_DIR="${HOME}/.local/share/fonts"
    fi
}

@test "[files] fonts - powerline fonts" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    [ -f "${FONT_DIR}/powerline-fonts/Source Code Pro Medium for Powerline.otf" ]
}

@test "[files] fonts - SauceCodePro Nerd Font" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    ls "${FONT_DIR}"/sauce-code-pro-nerd-font/SauceCodeProNerdFont*.ttf
}

@test "[files] fonts - Source Han Code JP" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    expected=14
    count=$(find "${FONT_DIR}/source-han-code-jp" -maxdepth 1 -type f -name "SourceHanCodeJP-*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}

@test "[files] fonts - Nerd Fonts Symbols" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    ls "${FONT_DIR}"/nerd-fonts-symbols/SymbolsNerdFont*.ttf
}
