#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# ツールの導入は、mise の global config が変わるたびに、この prune より先に走る run_onchange_after_90_mise が行う
function prune() {
    log_step "Pruning unused tool versions..."
    mise prune --yes
    # prune は config から外れたツールの stale shim を掃除しないため、shim を再生成して除去する
    mise reshim
}

function main() {
    require_command mise
    prune
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
