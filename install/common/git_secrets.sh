#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# dot_config/git/config.tmpl の init.templatedir = ~/.config/git/templates/git-secrets と対応し、
# 以後 git init / clone したリポジトリに pre-commit / commit-msg フックが入る。
# 検出パターンは chezmoi 管理の ~/.config/git/config [secrets] で設定済み。
TEMPLATE_DIR="$HOME/.config/git/templates/git-secrets"

function main() {
    # templatedir が存在しないと git init 時に警告が出るため、フック無しでも空ディレクトリだけは用意する
    mkdir -p "$TEMPLATE_DIR"
    # Alpine には git-secrets パッケージが無い (v3.22 時点で確認) ため恒常スキップになる
    if ! command -v git-secrets &>/dev/null; then
        log_warn "git-secrets が見つかりません。フック導入をスキップします。"
        return 0
    fi
    log_step "Installing git-secrets hooks into ${TEMPLATE_DIR}..."
    git secrets --install -f "$TEMPLATE_DIR"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
