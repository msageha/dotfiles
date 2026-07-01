#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/fisher.sh"

function setup() {
    # shellcheck source=install/common/fisher.sh
    source "${SCRIPT_PATH}"
}

@test "[common] fisher - validate" {
    [ -e "${SCRIPT_PATH}" ]
    run validate_fish
    [ "$status" -eq 0 ]
}

@test "[common] fisher - install" {
    command -v fish >/dev/null 2>&1 || skip "fish not installed"
    fish -c "type -q fisher" || skip "fisher not installed"
    run fish -c "fisher --version"
    [ "$status" -eq 0 ]
}
