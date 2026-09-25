#!/usr/bin/env bats

@test "[install/common] fisher - installed by run_once_after_91_common" {
    command -v fish >/dev/null 2>&1 || skip "fish not installed"
    run fish -c "type -q fisher; and fisher --version"
    [ "$status" -eq 0 ]
}
