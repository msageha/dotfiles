#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/brew.sh"

function setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi
    # shellcheck source=install/macos/brew.sh
    source "${SCRIPT_PATH}"
}

@test "[install/macos] brew - SKIP_CLI_TOOLS / SKIP_GUI_TOOLS unset aborts main" {
    run env -u SKIP_CLI_TOOLS -u SKIP_GUI_TOOLS bash -c 'source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
}

@test "[install/macos] brew - SKIP_CLI_TOOLS=true / SKIP_GUI_TOOLS=true skips tools and casks" {
    # base のみ実行し、追加ツール群・cask はスキップする (brew はスタブで無害化)。
    run env SKIP_CLI_TOOLS=true SKIP_GUI_TOOLS=true bash -c 'brew() { :; }; source '"${SCRIPT_PATH}"'; install_packages'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping formula tools"* ]]
    [[ "$output" != *"Installing formula packages"* ]]
    [[ "$output" != *"Installing coding agent casks"* ]]
    [[ "$output" != *"Installing cask packages"* ]]
}

@test "[install/macos] brew - SKIP_CLI_TOOLS=false / SKIP_GUI_TOOLS=true installs coding agent casks" {
    # CLI あり GUI なし構成でも coding agent は Debian 側 (coding_agent.sh) と同様に導入する。
    # CI では cask 全体が early return するため、CI を外して gating 自体を検証する。
    run env -u CI SKIP_CLI_TOOLS=false SKIP_GUI_TOOLS=true bash -c 'brew() { :; }; source '"${SCRIPT_PATH}"'; install_packages'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing coding agent casks"* ]]
    [[ "$output" == *"Skipping cask packages"* ]]
    [[ "$output" != *"Installing cask packages"* ]]
}
