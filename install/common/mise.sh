#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function install_tools() {
    log_step "Installing mise tools..."
    mise install --yes
    log_step "All mise tools installed successfully."
}

function prune() {
    log_step "Pruning unused tool versions..."
    mise prune --yes
    # prune は config から外れたツールの stale shim を掃除しないため、shim を再生成して除去する
    mise reshim
}

function main() {
    require_command mise
    install_tools
    prune
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
