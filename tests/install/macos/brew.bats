#!/usr/bin/env bats

load ../../test_helper

readonly SCRIPT_PATH="./install/macos/brew.sh"

function setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi
    # shellcheck source=install/macos/brew.sh
    source "${SCRIPT_PATH}"
}

function assert_brew_installed() {
    local installed="$1"
    shift
    local package name
    for package in "$@"; do
        # tap 付き名 ("satococoa/tap/wtp" -> "wtp") は末尾要素で照合する
        name="${package##*/}"
        echo "Checking ${package}"
        echo "${installed}" | grep -qx "${name}"
    done
}

@test "[install/macos] brew - install homebrew" {
    [ -x "$(command -v brew)" ]
}

@test "[install/macos] brew - packages installed according to the skip flags" {
    local installed
    installed="$(brew list --formula -1 2>/dev/null; brew list --cask -1 2>/dev/null)"

    # shellcheck disable=SC2154  # 配列は setup() の source で定義される
    assert_brew_installed "${installed}" "${formulae_base[@]}"
    if cli_tools_skipped; then
        skip "skip_cli_tools=true: formula tools and casks are not installed"
    fi
    # shellcheck disable=SC2154
    assert_brew_installed "${installed}" "${formulae[@]}"
    # cask は CI では導入されない (brew.sh の CI ガード)
    if [ -n "${CI:-}" ]; then
        skip "casks are not installed in CI"
    fi
    # shellcheck disable=SC2154
    assert_brew_installed "${installed}" "${casks_coding_agents[@]}"
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: GUI casks are not installed"
    fi
    # shellcheck disable=SC2154
    assert_brew_installed "${installed}" "${casks[@]}"
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
