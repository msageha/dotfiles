#!/usr/bin/env bats

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
