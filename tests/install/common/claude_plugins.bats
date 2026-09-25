#!/usr/bin/env bats

load ../../test_helper

readonly SCRIPT_PATH="./install/common/claude_plugins.sh"

function setup() {
    # shellcheck source=install/common/claude_plugins.sh
    source "${SCRIPT_PATH}"
    # 実際の展開値と同じ形 (空白区切り) を .chezmoidata.toml から組み立てる
    CLAUDE_MARKETPLACES="$(chezmoi_template '{{ range $name, $repo := .claude.marketplaces }}{{ $name }}={{ $repo }} {{ end }}')"
    CLAUDE_PLUGINS="$(chezmoi_template '{{ range $id, $enabled := .claude.plugins }}{{ if $enabled }}{{ $id }} {{ end }}{{ end }}')"
    export CLAUDE_MARKETPLACES CLAUDE_PLUGINS
}

@test "[install/common] claude_plugins - unset contract variables abort main" {
    run env -u CLAUDE_PLUGINS bash -c 'source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
    [[ "$output" == *"CLAUDE_MARKETPLACES / CLAUDE_PLUGINS are not set"* ]]
    run env -u CLAUDE_MARKETPLACES bash -c 'source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
}

@test "[install/common] claude_plugins - contract values are rendered from .chezmoidata.toml" {
    [ -n "${CLAUDE_MARKETPLACES}" ]
    [ -n "${CLAUDE_PLUGINS}" ]
    local marketplace plugin
    for marketplace in ${CLAUDE_MARKETPLACES}; do
        [[ "${marketplace}" == *=*/* ]]
    done
    for plugin in ${CLAUDE_PLUGINS}; do
        # plugin id は <name>@<marketplace> で、marketplace は登録対象に含まれる
        [[ "${plugin}" == *@* ]]
        [[ " ${CLAUDE_MARKETPLACES} " == *" ${plugin#*@}="* ]]
    done
}

@test "[install/common] claude_plugins - main skips cleanly without claude" {
    if command -v claude &>/dev/null; then
        skip "claude is installed on this machine"
    fi
    run main
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude が見つかりません"* ]]
}

@test "[install/common] claude_plugins - empty plugin list is accepted (all plugins disabled)" {
    run env CLAUDE_PLUGINS= bash -c 'claude() { echo "claude $*"; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude plugin marketplace add"* ]]
    [[ "$output" != *"claude plugin install"* ]]
}

@test "[install/common] claude_plugins - enabled plugins are installed" {
    # skip_cli_tools=true では run_once_before テンプレートがこのスクリプトを include しない
    if cli_tools_skipped; then
        skip "coding agent plugins are not installed (skip_cli_tools=true)"
    fi
    command -v claude &>/dev/null || skip "claude not installed"
    local installed plugin
    installed="$(claude plugin list 2>/dev/null)"
    for plugin in ${CLAUDE_PLUGINS}; do
        echo "Checking ${plugin}"
        echo "${installed}" | grep -q "${plugin}"
    done
}
