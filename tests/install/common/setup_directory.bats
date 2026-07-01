#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/setup_directory.sh"

function setup() {
    # shellcheck source=install/common/setup_directory.sh
    source "${SCRIPT_PATH}"
}

@test "[common] setup_directory" {
    run create_directories

    directories_exists=(
        "${HOME}/Downloads"
        "${HOME}/Documents"
        "${HOME}/Works/bin"
        "${HOME}/Works/pkg"
        "${HOME}/.ssh"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
