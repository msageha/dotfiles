#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

# git-secrets のフックを git テンプレートディレクトリに導入する。
# dot_gitconfig の init.templatedir = ~/.git-templates/git-secrets と対応し、
# 以後 git init / clone したリポジトリに pre-commit / commit-msg フックが入る。
# 検出パターンは chezmoi 管理の ~/.gitconfig [secrets] で設定済み。
TEMPLATE_DIR="$HOME/.git-templates/git-secrets"

function main() {
    # macOS は brew、それ以外は未導入のことがあるので、無ければスキップ (templatedir は
    # 空でも git が無視するため害は無い)。
    if ! command -v git-secrets &>/dev/null; then
        printf "%b\n" "${YELLOW}git-secrets が見つかりません。フック導入をスキップします。${NC}"
        return 0
    fi
    printf "%b\n" "${BLUE}Installing git-secrets hooks into ${TEMPLATE_DIR}...${NC}"
    mkdir -p "$TEMPLATE_DIR"
    # -f で既存フックを上書きするため再実行しても冪等
    git secrets --install -f "$TEMPLATE_DIR"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
