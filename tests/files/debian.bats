#!/usr/bin/env bats

load ../test_helper

function setup() {
    if [[ "$(uname)" != "Linux" ]] || ! command -v apt &>/dev/null; then
        skip "This test is only for Debian/Ubuntu"
    fi
}

@test "[files] debian - base APT packages installed" {
    command -v dpkg &>/dev/null || skip "dpkg not available"
    # root/sudo が無い環境では apt.sh 自体が全操作をスキップする (テストからパスワードを聞かないよう sudo -n で判定する)
    { [ "$(id -u)" -eq 0 ] || sudo -n true 2>/dev/null; } || skip "no root/sudo: apt.sh skips package installation"
    # 期待するパッケージ一覧は install/debian/apt.sh の配列を正とする
    # shellcheck source=install/debian/apt.sh
    source ./install/debian/apt.sh
    # shellcheck disable=SC2154  # apt_base は source で定義される
    for pkg in "${apt_base[@]}"; do
        echo "Checking ${pkg}"
        dpkg -s "${pkg}" &>/dev/null
    done
}

@test "[files] debian - coding agent CLIs installed (skip_cli_tools=false)" {
    # skip_cli_tools=true では run_once_before_02_debian が coding_agent.sh を include しない
    cli_tools_skipped && skip "coding agents are not installed (skip_cli_tools=true)"
    # インストーラが配置する CLI 名は agy (install_antigravity_cli の probe と揃える)
    for cli in agy claude codex; do
        echo "Checking ${cli}"
        command -v "${cli}" &>/dev/null
    done
}
