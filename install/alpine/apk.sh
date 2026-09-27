#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Alpine (musl) は最小構成のみのため、後続の chezmoi スクリプトが前提とするツールだけを入れる
apk_base=(
    ca-certificates
    curl
    fish
    zsh
    git
)

function update() {
    log_step "Updating APK package index..."
    run_privileged apk update
}

function install_base() {
    log_step "Installing base APK packages..."
    run_privileged apk add "${apk_base[@]}"
}

function upgrade() {
    if [ -n "${CI:-}" ]; then
        log_step "CI 環境のため APK upgrade をスキップします。"
        return 0
    fi
    log_step "Upgrading APK packages..."
    run_privileged apk upgrade
}

function clean() {
    log_step "Cleaning up APK cache..."
    run_privileged rm -rf /var/cache/apk/*
}

function main() {
    if ! has_privilege; then
        log_warn "root/sudo 権限が無いため APK 関連の操作をすべてスキップします。"
        return 0
    fi

    update
    install_base
    upgrade
    clean
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
