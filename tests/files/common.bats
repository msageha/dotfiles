#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles" {
    files_exists=(
        "${HOME}/.gitconfig"
        "${HOME}/.vimrc"
        "${HOME}/.tmux.conf"
        "${HOME}/.alias"
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
        "${HOME}/.ssh/config"
        "${HOME}/.gitignore"
        "${HOME}/.gitconfig.github"
        "${HOME}/.gitconfig.technoface.gitlab"
        "${HOME}/.gitconfig.sakanaai.github"
    )
    for file in "${files_exists[@]}"; do
        echo "Checking ${file}"
        [ -f "${file}" ]
    done

    directories_exists=(
        "${HOME}/.config"
        "${HOME}/.ssh"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
