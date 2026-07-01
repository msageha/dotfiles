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
        "${HOME}/Works/bin"
    )
    # フォントは skip_gui_tools=true の環境では導入されない
    # (run_once_after_91_common.sh.tmpl のガードと同条件) ため、その場合は確認しない。
    if [ "$(chezmoi execute-template '{{ dig "skip_gui_tools" false . }}' 2>/dev/null)" != "true" ]; then
        directories_exists+=("${HOME}/.local/share/fonts")
    fi
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}
