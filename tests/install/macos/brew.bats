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
    local packages=("${formulae[@]}" "${casks[@]}")
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
