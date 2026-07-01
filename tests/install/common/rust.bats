#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/rust.sh"

function setup() {
    # shellcheck source=install/common/rust.sh
    source "${SCRIPT_PATH}"
}


@test "[common] rust - validate" {
    [ -e "${SCRIPT_PATH}" ]
    run command -v rustc
    [ "$status" -eq 0 ]
    run command -v cargo
    [ "$status" -eq 0 ]
}

@test "[common] rust - install tools" {
    local installed
    installed="$(cargo install --list 2>/dev/null)"

    local missing=()
    for tool in "${rust_tools[@]}"; do
        if ! echo "${installed}" | grep -q "^${tool}"; then
            missing+=("${tool}")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing Rust tools: ${missing[*]}"
    fi
}
