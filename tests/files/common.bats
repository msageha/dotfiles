#!/usr/bin/env bats

load ../test_helper

@test "[files] dotfiles" {
    files_exists=(
        "${HOME}/.config/git/config"
        "${HOME}/.vimrc"
        "${HOME}/.config/tmux/tmux.conf"
        "${HOME}/.alias"
        "${HOME}/.bash_profile"
        "${HOME}/.zprofile"
        "${HOME}/.config/shell/env.sh"
        "${HOME}/.config/shell/integrations.sh"
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

    # ~/.ssh は chezmoi が、.local/bin / .local/state / .cache/zsh は
    # install/common/setup_directory.sh (run_once_before_01_common) が作る
    directories_exists=(
        "${HOME}/.config"
        "${HOME}/.ssh"
        "${HOME}/.local/bin"
        "${HOME}/.local/state"
        "${HOME}/.cache/zsh"
    )
    for directory in "${directories_exists[@]}"; do
        echo "Checking ${directory}"
        [ -d "${directory}" ]
    done
}

@test "[files] gws-* skills are not deployed on non-macOS" {
    if [[ "$(uname)" == "Darwin" ]]; then
        skip "gws-* skills are deployed only on macOS"
    fi
    # skip_cli_tools=true では .claude/skills 自体が管理対象外 (.chezmoiignore の skipCodingAgent gate)
    if cli_tools_skipped; then
        skip "coding agent settings are not managed (skip_cli_tools=true)"
    fi
    # skills ディレクトリは展開され、gws-* だけが .chezmoiignore の非 darwin 分岐で除外されること
    echo "Checking ${HOME}/.claude/skills/commit"
    [ -d "${HOME}/.claude/skills/commit" ]
    # マッチが無ければ glob はリテラルのまま残り -e は偽になる
    for path in "${HOME}/.claude/skills/"gws-*; do
        echo "Checking absence of ${path}"
        [ ! -e "${path}" ]
    done
}
