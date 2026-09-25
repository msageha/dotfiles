#!/usr/bin/env bats

load ../../test_helper

readonly SCRIPT_PATH="./install/common/claude_plugins.sh"

function setup() {
    # shellcheck source=install/common/claude_plugins.sh
    source "${SCRIPT_PATH}"
    # .chezmoiscripts の export 行と同じ range 式で .chezmoidata.toml から組み立てる
    # (テンプレート本体は OS gate があり macOS では描画されないため直接は使えない)
    CLAUDE_MARKETPLACES="$(chezmoi_template '{{ range $name, $repo := .claude.marketplaces }}{{ $name }}={{ $repo }} {{ end }}')"
    CLAUDE_PLUGINS="$(chezmoi_template '{{ range $id, $enabled := .claude.plugins }}{{ if $enabled }}{{ $id }} {{ end }}{{ end }}')"
    export CLAUDE_MARKETPLACES CLAUDE_PLUGINS
}

@test "[install/common] claude_plugins - unset CLAUDE_MARKETPLACES aborts main" {
    run env -u CLAUDE_MARKETPLACES bash -c 'source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
    [[ "$output" == *"CLAUDE_MARKETPLACES is not set"* ]]
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

@test "[install/common] claude_plugins - empty or unset CLAUDE_PLUGINS means no plugins (PowerShell 版と同じ契約)" {
    run env CLAUDE_PLUGINS= bash -c 'claude() { echo "claude $*"; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude plugin marketplace add"* ]]
    [[ "$output" != *"claude plugin install"* ]]
    run env -u CLAUDE_PLUGINS bash -c 'claude() { echo "claude $*"; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude plugin marketplace add"* ]]
    [[ "$output" != *"claude plugin install"* ]]
}
