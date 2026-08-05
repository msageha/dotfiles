#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/system_settings.sh"

function setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi
    export CHEZMOI_SOURCE_DIR="./home"
    # shellcheck source=install/macos/system_settings.sh
    source "${SCRIPT_PATH}"
}

@test "[macos] system_settings - no sudo skips computer name" {
    # sudo を持たないユーザー (CI runner 等) ではパスワードプロンプトを出さずスキップする。
    run env CHEZMOI_SOURCE_DIR=./home COMPUTER_NAME=new-name bash -c 'scutil() { echo "old-name"; }; sudo() { echo "SUDO CALLED"; return 1; }; source '"${SCRIPT_PATH}"'; has_privilege() { return 1; }; computer_name'
    [ "$status" -eq 0 ]
    [[ "$output" == *"sudo が使えないためコンピュータ名の設定をスキップします"* ]]
    [[ "$output" != *"SUDO CALLED"* ]]
}

@test "[macos] system_settings - sudo available sets computer name" {
    run env CHEZMOI_SOURCE_DIR=./home COMPUTER_NAME=new-name bash -c 'scutil() { echo "old-name"; }; sudo() { echo "sudo $*"; }; source '"${SCRIPT_PATH}"'; has_privilege() { return 0; }; computer_name'
    [ "$status" -eq 0 ]
    [[ "$output" == *"コンピュータ名を設定しています"* ]]
    [[ "$output" == *"sudo scutil --set ComputerName new-name"* ]]
}

@test "[macos] system_settings - no sudo skips user icon" {
    run env CHEZMOI_SOURCE_DIR=./home bash -c 'dscl() { :; }; sudo() { echo "SUDO CALLED"; return 1; }; source '"${SCRIPT_PATH}"'; has_privilege() { return 1; }; user_icon'
    [ "$status" -eq 0 ]
    [[ "$output" == *"sudo が使えないためユーザーアイコンの設定をスキップします"* ]]
    [[ "$output" != *"SUDO CALLED"* ]]
}

@test "[macos] system_settings - sudo available sets user icon" {
    run env CHEZMOI_SOURCE_DIR=./home bash -c 'dscl() { :; }; sudo() { echo "sudo $*"; }; source '"${SCRIPT_PATH}"'; has_privilege() { return 0; }; user_icon'
    [ "$status" -eq 0 ]
    [[ "$output" == *"ユーザーアイコンを設定しています"* ]]
    [[ "$output" == *"sudo sh -c"* ]]
}
