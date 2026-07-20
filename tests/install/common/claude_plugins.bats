#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/claude_plugins.sh"

function setup() {
    # shellcheck source=install/common/claude_plugins.sh
    source "${SCRIPT_PATH}"

    plugin_names=(
        cloudflare
        github
        agent-sdk-dev
        plugin-dev
        claude-md-management
        skill-creator
        sonatype-guide
        "${lsp_plugins[@]}"
    )
}

@test "[common] claude_plugins - functions defined" {
    [ -e "${SCRIPT_PATH}" ]
    declare -F cloudflare >/dev/null
    declare -F github >/dev/null
    declare -F agent_sdk_dev >/dev/null
    declare -F plugin_dev >/dev/null
    declare -F claude_md_management >/dev/null
    declare -F skill_creator >/dev/null
    declare -F sonatype_guide >/dev/null
    declare -F lsp >/dev/null
    [ "${#lsp_plugins[@]}" -gt 0 ]
}

@test "[common] claude_plugins - main skips cleanly without claude" {
    if command -v claude &>/dev/null; then
        skip "claude is installed on this machine"
    fi
    run main
    [ "$status" -eq 0 ]
}

@test "[common] claude_plugins - plugins installed" {
    command -v claude &>/dev/null || skip "claude not installed"
    local installed
    installed="$(claude plugin list 2>/dev/null)"

    local missing=()
    local name
    for name in "${plugin_names[@]}"; do
        echo "${installed}" | grep -q "${name}@claude-plugins-official" || missing+=("${name}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing plugins: ${missing[*]}"
    fi
}
