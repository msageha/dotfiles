#!/usr/bin/env bats

load ../../test_helper

readonly SCRIPT_PATH="./install/debian/coding_agent.sh"

function setup() {
    # shellcheck source=install/debian/coding_agent.sh
    source "${SCRIPT_PATH}"
}

@test "[install/debian] coding_agent - functions defined" {
    declare -F install_antigravity_cli >/dev/null
    declare -F install_claude_code >/dev/null
    declare -F install_codex >/dev/null
}

@test "[install/debian] coding_agent - CLIs available" {
    if [[ "$(uname)" != "Linux" ]] || ! command -v apt &>/dev/null; then
        skip "This test is only for Debian/Ubuntu"
    fi
    # skip_cli_tools=true では run_once_before_02_debian がこのスクリプトを include しない
    if cli_tools_skipped; then
        skip "coding agents are not installed (skip_cli_tools=true)"
    fi
    # インストーラが配置する CLI 名は agy (install_antigravity_cli の probe と揃える)
    for cli in agy claude codex; do
        echo "Checking ${cli}"
        command -v "${cli}" &>/dev/null
    done
}
