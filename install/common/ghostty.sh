#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

THEME_URL="https://raw.githubusercontent.com/dracula/ghostty/main/dracula"

function setup_ghostty() {
    # ghostty は OS ごとに設定ディレクトリが異なる
    local config_dir
    if [[ "$(uname)" == "Darwin" ]]; then
        config_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
    else
        config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
    fi

    # workingTree は git working tree が無い環境 (Docker ビルドは .dockerignore で
    # .git を除外) で sourceDir に落ちるため、常に解決される sourceDir から導出する
    local source_dir="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi/home}"
    local repo_root
    repo_root="$(cd "$source_dir/.." && pwd)"
    local config_src="${repo_root}/settings/common/ghostty/config.ghostty"

    mkdir -p "$config_dir/themes"
    cp "$config_src" "$config_dir/config.ghostty"
    printf "%b\n" "${BLUE}ghostty config installed to $config_dir/config.ghostty${NC}"

    # Dracula テーマ (取得失敗は警告のみで全体は止めない)
    if curl -fsSL "$THEME_URL" -o "$config_dir/themes/dracula"; then
        printf "%b\n" "${BLUE}ghostty dracula theme installed.${NC}"
    else
        printf "%b\n" "WARN: failed to fetch ghostty dracula theme from $THEME_URL" >&2
    fi
}

function main() {
    setup_ghostty
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
