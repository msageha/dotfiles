#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/debian/coding_agent.sh"

function setup() {
    if [[ "$(uname)" != "Linux" ]]; then
        skip "This test is only for Debian/Ubuntu"
    fi
    # shellcheck source=install/debian/coding_agent.sh
    source "${SCRIPT_PATH}"
}

@test "[debian] coding_agent - functions defined" {
    [ -e "${SCRIPT_PATH}" ]
    declare -F install_antigravity_cli >/dev/null
    declare -F install_claude_code >/dev/null
    declare -F install_codex >/dev/null
}

@test "[debian] coding_agent - CLIs available" {
    local missing=()
    command -v antigravity &>/dev/null || missing+=("antigravity")
    command -v claude &>/dev/null || missing+=("claude")
    command -v codex &>/dev/null || missing+=("codex")
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing coding agent CLIs: ${missing[*]}"
    fi
}
