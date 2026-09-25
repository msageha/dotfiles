#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/completions.sh"

function setup() {
    # shellcheck source=install/common/completions.sh
    source "${SCRIPT_PATH}"
}

# 各ツールをスタブし、ツール名と渡された引数を出力させる
function stub_tools() {
    local tool
    # shellcheck disable=SC2154  # completion_tools は setup() の source で定義される
    for tool in "${completion_tools[@]}"; do
        eval "function ${tool}() { echo \"${tool} \$*\"; }"
    done
    function env() { echo "env $*"; }
}

@test "[install/common] completions - every tool has a recipe for fish / zsh / bash" {
    stub_tools
    for shell in fish zsh bash; do
        for tool in "${completion_tools[@]}"; do
            # ngrok は bash / zsh のみ対応 (generate_completions が fish をスキップする)
            [[ "$tool" == ngrok && "$shell" == fish ]] && continue
            echo "Checking ${tool} (${shell})"
            run print_completion "$tool" "$shell"
            [ "$status" -eq 0 ]
            [ -n "$output" ]
            [[ "$output" == *"${shell}"* ]]
        done
    done
}

@test "[install/common] completions - mise passes --include-bash-completion-lib only for bash" {
    stub_tools
    run print_completion mise bash
    [[ "$output" == "mise completion bash --include-bash-completion-lib" ]]
    run print_completion mise zsh
    [[ "$output" == "mise completion zsh" ]]
}

@test "[install/common] completions - unknown tool fails and writes nothing" {
    run print_completion no-such-tool zsh
    [ "$status" -eq 1 ]
    run write_completion no-such-tool zsh "${BATS_TEST_TMPDIR}/_no-such-tool"
    [ "$status" -eq 1 ]
    [ ! -e "${BATS_TEST_TMPDIR}/_no-such-tool" ]
    [ ! -e "${BATS_TEST_TMPDIR}/_no-such-tool.tmp" ]
}

@test "[install/common] completions - failing generator leaves no partial file" {
    function gh() { echo partial; return 3; }
    run write_completion gh zsh "${BATS_TEST_TMPDIR}/_gh"
    [ "$status" -eq 1 ]
    [ ! -e "${BATS_TEST_TMPDIR}/_gh" ]
    [ ! -e "${BATS_TEST_TMPDIR}/_gh.tmp" ]
}

@test "[install/common] completions - generate_completions writes one file per available tool" {
    stub_tools
    # chezmoi と rg だけ「導入済み」に見せる
    function command() {
        if [ "$1" = "-v" ]; then
            case "$2" in chezmoi | rg) return 0 ;; *) return 1 ;; esac
        fi
        builtin command "$@"
    }
    run generate_completions zsh "${BATS_TEST_TMPDIR}/zsh"
    [ "$status" -eq 0 ]
    [ "$(ls "${BATS_TEST_TMPDIR}/zsh" | sort | tr '\n' ' ')" = "_chezmoi _rg " ]
    [ "$(cat "${BATS_TEST_TMPDIR}/zsh/_rg")" = "rg --generate complete-zsh" ]
}
