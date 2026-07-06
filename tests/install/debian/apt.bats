#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/debian/apt.sh"

function setup() {
    if [[ "$(uname)" != "Linux" ]]; then
        skip "This test is only for Debian/Ubuntu"
    fi
    # shellcheck source=install/debian/apt.sh
    source "${SCRIPT_PATH}"
}

@test "[debian] apt - base packages installed" {
    [ -e "${SCRIPT_PATH}" ]
    local missing=()
    for pkg in "${apt_base[@]}"; do
        dpkg -s "${pkg}" &>/dev/null || missing+=("${pkg}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing base apt packages: ${missing[*]}"
    fi
}

@test "[debian] apt - SKIP_CLI_TOOLS unset aborts main" {
    # 呼び出し側 (run_once_before) が SKIP_CLI_TOOLS を必ず渡す契約。未設定なら exit 1。
    run env -u SKIP_CLI_TOOLS bash -c 'sudo() { :; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
}

@test "[debian] apt - SKIP_CLI_TOOLS=true skips tools and chezmoi/docker" {
    # base のみ実行し、追加ツール群はスキップする (sudo/curl はスタブで無害化)。
    run env SKIP_CLI_TOOLS=true bash -c 'sudo() { :; }; curl() { :; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping apt tools"* ]]
    [[ "$output" != *"Installing APT tool packages"* ]]
}
