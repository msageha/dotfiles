#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/setup_shell.sh"

function setup() {
    # shellcheck source=install/common/setup_shell.sh
    source "${SCRIPT_PATH}"
    # 実際の $HOME を汚さないよう一時ディレクトリで検証する
    export HOME="${BATS_TEST_TMPDIR}"
}

@test "[install/common] setup_shell - create_zshrc creates guarded block on fresh home" {
    create_zshrc

    grep -Fxq "# >>> dotfiles zsh init >>>" "${HOME}/.config/zsh/.zshrc"
    grep -Fxq "# <<< dotfiles zsh init <<<" "${HOME}/.config/zsh/.zshrc"
    grep -Fq 'if [[ ! -o login ]]; then' "${HOME}/.config/zsh/.zshrc"
    grep -Fq 'HISTFILE="$XDG_STATE_HOME/zsh_history"' "${HOME}/.config/zsh/.zshrc"
    grep -Fxq 'SAVEHIST=10000' "${HOME}/.config/zsh/.zshrc"
    grep -Fxq 'HISTSIZE=10000' "${HOME}/.config/zsh/.zshrc"
    # login shell で初期化を二重実行させる無条件 source が含まれないこと
    run grep -Fxq "source \"\$ZDOTDIR/.zprofile\"" "${HOME}/.config/zsh/.zshrc"
    [ "$status" -ne 0 ]
}

@test "[install/common] setup_shell - create_zshrc is idempotent" {
    create_zshrc
    create_zshrc

    [ "$(grep -Fxc "# >>> dotfiles zsh init >>>" "${HOME}/.config/zsh/.zshrc")" -eq 1 ]
    [ "$(grep -Fxc "# <<< dotfiles zsh init <<<" "${HOME}/.config/zsh/.zshrc")" -eq 1 ]
}

@test "[install/common] setup_shell - create_zshrc keeps file intact when end marker is missing" {
    mkdir -p "${HOME}/.config/zsh"
    printf '%s\n' "# >>> dotfiles zsh init >>>" "# stale managed line" "# user line" > "${HOME}/.config/zsh/.zshrc"

    run create_zshrc
    [ "$status" -eq 0 ]
    [[ "$output" == *"終了マーカー"* ]]
    grep -Fxq "# user line" "${HOME}/.config/zsh/.zshrc"
    [ "$(grep -Fxc "# >>> dotfiles zsh init >>>" "${HOME}/.config/zsh/.zshrc")" -eq 1 ]
}

@test "[install/common] setup_shell - create_bashrc appends source line once" {
    create_bashrc
    create_bashrc

    [ "$(grep -Fxc "source \$HOME/.bash_profile" "${HOME}/.bashrc")" -eq 1 ]
}
