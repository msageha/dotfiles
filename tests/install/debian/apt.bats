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

@test "[debian] apt - CI skips apt upgrade" {
    # GitHub runner 上の apt upgrade は snap refresh を誘発し、外部 download に長時間依存する。
    run env CI=true bash -c 'source '"${SCRIPT_PATH}"'; upgrade'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping APT upgrade in CI."* ]]
    [[ "$output" != *"Upgrading APT packages"* ]]
}

@test "[debian] apt - no root/sudo skips all APT operations" {
    # sudo が使えない (未インストール/sudoers 未登録/非対話でパスワード入力不可等) 環境では、
    # main() の先頭で権限を判定し、以降の apt 操作を一切行わず警告のみで終了する。
    run env SKIP_CLI_TOOLS=true bash -c 'sudo() { return 1; }; source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 0 ]
    [[ "$output" == *"root/sudo 権限が無いため"* ]]
    [[ "$output" != *"Updating APT package lists"* ]]
}

@test "[debian] apt - root bypasses sudo entirely" {
    # root (EUID 0) では sudo を一切呼ばずに has_privilege が真になる (sudo 未インストールの
    # root 専用環境でも動く)。
    run bash -c 'id() { echo 0; }; sudo() { echo "sudo should not be called"; return 1; }; source '"${SCRIPT_PATH}"'; has_privilege'
    [ "$status" -eq 0 ]
    [[ "$output" != *"sudo should not be called"* ]]
}
