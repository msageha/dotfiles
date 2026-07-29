#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/setup_shell.sh"

function setup() {
    # shellcheck source=install/common/setup_shell.sh
    source "${SCRIPT_PATH}"
    # 実際の $HOME を汚さないよう一時ディレクトリで検証する
    export HOME="${BATS_TEST_TMPDIR}"
}

@test "[common] setup_shell - create_zshrc creates guarded block on fresh home" {
    create_zshrc

    grep -Fxq "# >>> dotfiles zsh init >>>" "${HOME}/.zshrc"
    grep -Fxq "# <<< dotfiles zsh init <<<" "${HOME}/.zshrc"
    grep -Fq 'if [[ ! -o login ]]; then' "${HOME}/.zshrc"
    grep -Fq 'HISTFILE="$HOME/.local/state/zsh_history"' "${HOME}/.zshrc"
    # 二重実行の原因だった無条件 source が含まれないこと
    run grep -Fxq "source \$HOME/.zprofile" "${HOME}/.zshrc"
    [ "$status" -ne 0 ]
}

@test "[common] setup_shell - create_zshrc migrates legacy unconditional source" {
    printf '%s\n' "source \$HOME/.zprofile" "# machine local line" > "${HOME}/.zshrc"

    create_zshrc

    run grep -Fxq "source \$HOME/.zprofile" "${HOME}/.zshrc"
    [ "$status" -ne 0 ]
    grep -Fxq "# machine local line" "${HOME}/.zshrc"
    # 管理ブロックは機械ローカルな追記より前に挿入される
    [ "$(head -n 1 "${HOME}/.zshrc")" = "# >>> dotfiles zsh init >>>" ]
}

@test "[common] setup_shell - create_zshrc is idempotent" {
    create_zshrc
    create_zshrc

    [ "$(grep -Fxc "# >>> dotfiles zsh init >>>" "${HOME}/.zshrc")" -eq 1 ]
    [ "$(grep -Fxc "# <<< dotfiles zsh init <<<" "${HOME}/.zshrc")" -eq 1 ]
}

@test "[common] setup_shell - create_zshrc keeps file intact when end marker is missing" {
    # 終了マーカー欠損時にブロック開始以降のユーザー行を巻き込み削除しないこと
    printf '%s\n' "# >>> dotfiles zsh init >>>" "# stale managed line" "# user line" > "${HOME}/.zshrc"

    run create_zshrc
    [ "$status" -eq 0 ]
    [[ "$output" == *"終了マーカー"* ]]
    grep -Fxq "# user line" "${HOME}/.zshrc"
    # ファイルは書き換えられていない (マーカーの重複挿入もしない)
    [ "$(grep -Fxc "# >>> dotfiles zsh init >>>" "${HOME}/.zshrc")" -eq 1 ]
}

@test "[common] setup_shell - create_bashrc appends source line once" {
    create_bashrc
    create_bashrc

    [ "$(grep -Fxc "source \$HOME/.bash_profile" "${HOME}/.bashrc")" -eq 1 ]
}
