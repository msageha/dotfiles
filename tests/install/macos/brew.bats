#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/macos/brew.sh"

function setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi
    # shellcheck source=install/macos/brew.sh
    source "${SCRIPT_PATH}"
}

@test "[macos] brew - install homebrew" {
    [ -x "$(command -v brew)" ]
}

@test "[macos] brew - check basic packages" {
    local installed
    installed="$(brew list --formula -1 2>/dev/null; brew list --cask -1 2>/dev/null)"

    local missing=()
    local packages=("${formulae_base[@]}" "${formulae[@]}" "${casks[@]}")
    for package in "${packages[@]}"; do
        # Handle tap prefix (e.g. "satococoa/tap/wtp" -> "wtp")
        local name="${package##*/}"
        if ! echo "${installed}" | grep -qx "${name}"; then
            missing+=("${package}")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing brew packages: ${missing[*]}"
    fi
}

@test "[macos] brew - SKIP_CLI_TOOLS / SKIP_GUI_TOOLS unset aborts main" {
    # 呼び出し側 (run_once_before) が両変数を必ず渡す契約。未設定なら exit 1。
    run env -u SKIP_CLI_TOOLS -u SKIP_GUI_TOOLS bash -c 'source '"${SCRIPT_PATH}"'; main'
    [ "$status" -eq 1 ]
}

@test "[macos] brew - SKIP_CLI_TOOLS=true / SKIP_GUI_TOOLS=true skips tools and casks" {
    # base のみ実行し、追加ツール群・cask はスキップする (brew はスタブで無害化)。
    run env SKIP_CLI_TOOLS=true SKIP_GUI_TOOLS=true bash -c 'brew() { :; }; source '"${SCRIPT_PATH}"'; install'
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping formula tools"* ]]
    [[ "$output" != *"Installing formula packages"* ]]
    [[ "$output" != *"Installing cask packages"* ]]
}
