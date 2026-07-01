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
    )
    # .gitconfig.technoface.gitlab / .gitconfig.sakanaai.github は age 暗号化
    # (encrypted_*.age) のため、鍵 (~/.config/chezmoi/key.txt) が無い環境
    # (CI・鍵未配置マシン) では .chezmoiignore により適用されない。よって
    # 「常に存在する」前提の本テストには含めない。
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
