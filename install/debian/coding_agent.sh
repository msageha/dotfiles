#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function install_antigravity_cli() {
    log_step "Installing antigravity-cli..."
    # update に使う agy を probe する (antigravity を probe すると agy だけ無い環境で失敗する)
    if ! command -v agy &>/dev/null; then
        curl -fsSL https://antigravity.google/cli/install.sh | bash
    else
        agy update
    fi
}

function install_claude_code() {
    log_step "Installing Claude Code..."
    if ! command -v claude &>/dev/null; then
        curl -fsSL https://claude.ai/install.sh | bash
    else
        claude update
    fi
}

function install_codex() {
    log_step "Installing Codex CLI..."
    if ! command -v codex &>/dev/null; then
        curl -fsSL https://chatgpt.com/codex/install.sh | sh
    else
        codex update
    fi
}

function main() {
    log_step "=== Installing coding agents ==="
    install_antigravity_cli
    install_claude_code
    install_codex
    log_step "=== All coding agents installed! ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
