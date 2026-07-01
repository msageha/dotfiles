#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
NC="\033[0m" # No Color (リセット)

function validate_fish() {
    if ! command -v fish &>/dev/null; then
        printf "%b\n" "${RED}Fish shell could not be found, please install Fish first.${NC}"
        exit 1
    fi
}

function main() {
    validate_fish
    # workingTree は git 非存在環境 (Docker 等) で sourceDir に落ちるため、
    # 常に解決される sourceDir からリポジトリルートを導出する
    local source_dir="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi/home}"
    local repo_root
    repo_root="$(cd "$source_dir/.." && pwd)"
    fish "${repo_root}/install/common/fisher.fish"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
