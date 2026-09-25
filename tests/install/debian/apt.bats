#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/debian/apt.sh"

function setup() {
    # shellcheck source=install/debian/apt.sh
    source "${SCRIPT_PATH}"
}

@test "[install/debian] apt - base packages installed" {
    if [[ "$(uname)" != "Linux" ]] || ! command -v dpkg &>/dev/null; then
        skip "This test is only for Debian/Ubuntu"
    fi
    # root/sudo が無い環境では apt.sh 自体が全操作をスキップする
    has_privilege || skip "no root/sudo: apt.sh skips package installation"
    # shellcheck disable=SC2154  # apt_base は setup() の source で定義される
    for pkg in "${apt_base[@]}"; do
        echo "Checking ${pkg}"
        dpkg -s "${pkg}" &>/dev/null
    done
}

@test "[install/debian] apt - SKIP_CLI_TOOLS unset aborts main" {
    run env -u SKIP_CLI_TOOLS bash -c 'sudo() { :; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
}

@test "[install/debian] apt - SKIP_CLI_TOOLS=true skips tools and chezmoi/docker" {
    # base のみ実行し、追加ツール群はスキップする (sudo/curl はスタブで無害化)。
    # root で bats を実行すると run_privileged が sudo を介さず実 apt を叩いてしまうため、
    # id もスタブして非 root 扱いにし、必ず sudo スタブを経由させる。
    run env SKIP_CLI_TOOLS=true bash -c 'id() { echo 1000; }; sudo() { :; }; curl() { :; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping apt tools"* ]]
    [[ "$output" != *"Installing APT tool packages"* ]]
}

@test "[install/debian] apt - CI skips apt upgrade" {
    # GitHub runner 上の apt upgrade は snap refresh を誘発し、外部 download に長時間依存する。
    run env CI=true bash -c 'source '"${SCRIPT_PATH}"'; upgrade'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping APT upgrade in CI."* ]]
    [[ "$output" != *"Upgrading APT packages"* ]]
}

@test "[install/debian] apt - no root/sudo skips all APT operations" {
    # root で bats を実行すると has_privilege が id で真になってしまうため id もスタブする。
    run env SKIP_CLI_TOOLS=true bash -c 'id() { echo 1000; }; sudo() { return 1; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"root/sudo 権限が無いため"* ]]
    [[ "$output" != *"Updating APT package lists"* ]]
}
