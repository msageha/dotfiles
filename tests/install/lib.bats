#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/lib.sh"

@test "[install] lib - has_privilege: sudo -v false negative falls back to sudo -n true" {
    # verifypw=all 環境 (パスワード必須のグループルールと NOPASSWD ルールの併存。
    # CI コンテナの -G sudo + NOPASSWD:ALL 等) では sudo -v が失敗しても
    # 実コマンドは last-match の NOPASSWD で通る。sudo -n true への fallback で真と判定する。
    run bash -c 'sudo() { [ "$1" = "-v" ] && return 1; return 0; }; source '"${SCRIPT_PATH}"'; has_privilege'
    [ "$status" -eq 0 ]
}

@test "[install] lib - has_privilege: root bypasses sudo entirely" {
    run bash -c 'id() { echo 0; }; sudo() { echo "sudo should not be called"; return 1; }; source '"${SCRIPT_PATH}"'; has_privilege'
    [ "$status" -eq 0 ]
    [[ "$output" != *"sudo should not be called"* ]]
}

@test "[install] lib - run_privileged executes directly as root" {
    run bash -c 'id() { echo 0; }; sudo() { echo "sudo should not be called"; return 127; }; source '"${SCRIPT_PATH}"'; run_privileged echo ok'
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
    [[ "$output" != *"sudo should not be called"* ]]
}

@test "[install] lib - run_privileged uses sudo for non-root" {
    run bash -c 'id() { echo 1000; }; sudo() { echo "via sudo: $*"; }; source '"${SCRIPT_PATH}"'; run_privileged echo ok'
    [ "$status" -eq 0 ]
    [[ "$output" == *"via sudo: echo ok"* ]]
}

@test "[install] lib - require_command exits 1 for a missing command" {
    run bash -c 'source '"${SCRIPT_PATH}"'; require_command definitely-missing-command-xyz'
    [ "$status" -eq 1 ]
    [[ "$output" == *"definitely-missing-command-xyz could not be found"* ]]
}

@test "[install] lib - CHEZMOI_REPO_ROOT follows CHEZMOI_SOURCE_DIR when set" {
    run env CHEZMOI_SOURCE_DIR=./home bash -c 'source '"${SCRIPT_PATH}"'; echo "$CHEZMOI_REPO_ROOT"'
    [ "$status" -eq 0 ]
    [ "$output" = "$(pwd)" ]
}

@test "[install] lib - CHEZMOI_REPO_ROOT resolves from the lib location when unset" {
    # bats / CI の checkout 先など、既定の ~/.local/share/chezmoi が無い配置でも単体実行できること
    run env -u CHEZMOI_SOURCE_DIR HOME="${BATS_TEST_TMPDIR}" bash -c 'source '"${SCRIPT_PATH}"'; echo "$CHEZMOI_REPO_ROOT"'
    [ "$status" -eq 0 ]
    [ "$output" = "$(pwd)" ]
}

@test "[install] lib - install scripts load the lib when sourced standalone" {
    for script in install/common/*.sh install/macos/*.sh install/debian/*.sh install/ubuntu/*.sh install/alpine/*.sh; do
        echo "Checking ${script}"
        run env -u CHEZMOI_SOURCE_DIR bash -c 'source '"${script}"'; declare -F log_step run_privileged >/dev/null'
        [ "$status" -eq 0 ]
    done
}
