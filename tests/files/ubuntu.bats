#!/usr/bin/env bats

@test "[ubuntu] dotfiles" {
    if [[ "$(uname)" != "Linux" ]] || [[ ! -f "/etc/os-release" ]] || ! grep -q "ubuntu" /etc/os-release; then
        skip "This test is only for Ubuntu"
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
        "${HOME}/.local/share/fonts"
        "${HOME}/Works/bin"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
