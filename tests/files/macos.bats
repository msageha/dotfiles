#!/usr/bin/env bats

@test "[macos] dotfiles" {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "This test is only for macOS"
    fi

    files_exists=(
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
    )
    for file in "${files_exists[@]}"; do
        echo "Checking ${file}"
        [ -f "${file}" ]
    done

    directories_exists=(
        "${HOME}/Library/Fonts"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
