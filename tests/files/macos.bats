#!/usr/bin/env bats

load ../test_helper

function setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi
    # 期待するパッケージ一覧は install/macos/brew.sh の配列を正とする
    # shellcheck source=install/macos/brew.sh
    source ./install/macos/brew.sh
}

function brew_installed() {
    brew list --formula -1 2>/dev/null
    brew list --cask -1 2>/dev/null
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

@test "[files] macos - homebrew installed" {
    [ -x "$(command -v brew)" ]
}

@test "[files] macos - base formulae installed" {
    # shellcheck disable=SC2154  # 配列は setup() の source で定義される
    assert_brew_installed "$(brew_installed)" "${formulae_base[@]}"
}

@test "[files] macos - formula tools installed (skip_cli_tools=false)" {
    cli_tools_skipped && skip "skip_cli_tools=true: formula tools are not installed"
    # shellcheck disable=SC2154
    assert_brew_installed "$(brew_installed)" "${formulae[@]}"
}

@test "[files] macos - coding agent casks installed (skip_cli_tools=false, not CI)" {
    cli_tools_skipped && skip "skip_cli_tools=true: coding agent casks are not installed"
    # cask は CI では導入されない (brew.sh の CI ガード)
    [ -n "${CI:-}" ] && skip "casks are not installed in CI"
    # shellcheck disable=SC2154
    assert_brew_installed "$(brew_installed)" "${casks_coding_agents[@]}"
}

@test "[files] macos - GUI casks installed (skip_gui_tools=false, not CI)" {
    gui_tools_skipped && skip "skip_gui_tools=true: GUI casks are not installed"
    [ -n "${CI:-}" ] && skip "casks are not installed in CI"
    # shellcheck disable=SC2154
    assert_brew_installed "$(brew_installed)" "${casks[@]}"
}
