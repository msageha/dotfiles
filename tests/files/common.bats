#!/usr/bin/env bats

# bats file_tags=common
@test "[common] dotfiles" {
    files_exists=(
        "${HOME}/.config/git/config"
        "${HOME}/.vimrc"
        "${HOME}/.config/tmux/tmux.conf"
        "${HOME}/.alias"
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
        "${HOME}/.ssh/config"
        "${HOME}/.config/git/ignore"
        "${HOME}/.config/git/config.github"
    )
    # .config/git/config.technoface.gitlab / .config/git/config.sakanaai.github は
    # age 暗号化 (encrypted_*.age) のため、鍵 (~/.config/chezmoi/key.txt) が無い環境
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

@test "[common] gws-* skills are not deployed on non-macOS" {
    if [[ "$(uname)" == "Darwin" ]]; then
        skip "gws-* skills are deployed only on macOS"
    fi
    # skip_cli_tools=true では .claude/skills 自体が管理対象外
    # (.chezmoiignore の skipCodingAgent gate と同条件) のため、その場合は確認しない。
    if [ "$(chezmoi execute-template '{{ dig "skip_cli_tools" false . }}' 2>/dev/null)" == "true" ]; then
        skip "coding agent settings are not managed (skip_cli_tools=true)"
    fi
    # 個別 whitelist (.chezmoiignore の非 darwin 分岐) で gws-* 以外の skills は展開されること
    echo "Checking ${HOME}/.claude/skills/commit"
    [ -d "${HOME}/.claude/skills/commit" ]
    # gws-* skills は展開されないこと (マッチが無ければ glob はリテラルのまま残り -e は偽になる)
    for path in "${HOME}/.claude/skills/"gws-*; do
        echo "Checking absence of ${path}"
        [ ! -e "${path}" ]
    done
}
