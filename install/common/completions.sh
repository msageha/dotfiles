#!/usr/bin/env bash
set -euo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

function gen_completion() {
    local name="$1"
    shift
    printf "%b\n" "${BLUE}setup for $name${NC}" >&2
    "$@"
    printf "%b\n" "${BLUE}done: $name${NC}" >&2
}

function fish_completions() {
    printf "%b\n" "${BLUE}Setting up Fish completions in parallel...${NC}"
    local comp_dir="$HOME/.config/fish/completions"
    mkdir -p "$comp_dir"

    local pids=()
    local names=()

    if command -v mise &>/dev/null; then
        gen_completion mise mise completion fish > "$comp_dir/mise.fish" &
        pids+=($!); names+=("mise")
    fi
    if command -v uv &>/dev/null; then
        gen_completion uv uv generate-shell-completion fish > "$comp_dir/uv.fish" &
        pids+=($!); names+=("uv")
    fi
    # Docker Compose v2 は Docker CLI プラグインのため、docker completion fish で両方カバーされる
    if command -v docker &>/dev/null; then
        gen_completion docker docker completion fish > "$comp_dir/docker.fish" &
        pids+=($!); names+=("docker")
    else
        gen_completion docker curl -sfL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/fish/docker.fish > "$comp_dir/docker.fish" &
        pids+=($!); names+=("docker")
    fi
    if command -v chezmoi &>/dev/null; then
        gen_completion chezmoi chezmoi completion fish > "$comp_dir/chezmoi.fish" &
        pids+=($!); names+=("chezmoi")
    fi
    if command -v gh &>/dev/null; then
        gen_completion gh gh completion -s fish > "$comp_dir/gh.fish" &
        pids+=($!); names+=("gh")
    fi
    if command -v rustup &>/dev/null; then
        gen_completion rustup rustup completions fish > "$comp_dir/rustup.fish" &
        pids+=($!); names+=("rustup")
    fi
    if command -v ruff &>/dev/null; then
        gen_completion ruff ruff generate-shell-completion fish > "$comp_dir/ruff.fish" &
        pids+=($!); names+=("ruff")
    fi
    if command -v kubectl &>/dev/null; then
        if [[ -L "$comp_dir/kubectl.fish" ]]; then
            rm -f "$comp_dir/kubectl.fish"
        fi
        gen_completion kubectl kubectl completion fish > "$comp_dir/kubectl.fish" &
        pids+=($!); names+=("kubectl")
    fi

    if command -v bat &>/dev/null; then
        gen_completion bat bat --completion fish > "$comp_dir/bat.fish" &
        pids+=($!); names+=("bat")
    fi
    if command -v fd &>/dev/null; then
        gen_completion fd fd --gen-completions fish > "$comp_dir/fd.fish" &
        pids+=($!); names+=("fd")
    fi
    if command -v rg &>/dev/null; then
        gen_completion rg rg --generate complete-fish > "$comp_dir/rg.fish" &
        pids+=($!); names+=("rg")
    fi
    if command -v procs &>/dev/null; then
        gen_completion procs procs --gen-completion-out fish > "$comp_dir/procs.fish" &
        pids+=($!); names+=("procs")
    fi
    if command -v op &>/dev/null; then
        gen_completion op op completion fish > "$comp_dir/op.fish" &
        pids+=($!); names+=("op")
    fi
    if command -v stern &>/dev/null; then
        gen_completion stern stern --completion fish > "$comp_dir/stern.fish" &
        pids+=($!); names+=("stern")
    fi
    if command -v yq &>/dev/null; then
        gen_completion yq yq shell-completion fish > "$comp_dir/yq.fish" &
        pids+=($!); names+=("yq")
    fi
    if command -v pnpm &>/dev/null; then
        gen_completion pnpm pnpm completion fish > "$comp_dir/pnpm.fish" &
        pids+=($!); names+=("pnpm")
    fi

    local failed=()
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed+=("${names[$i]}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf "%b\n" "${RED}Failed Fish completions: ${failed[*]}${NC}"
        exit 1
    fi
    printf "%b\n" "${BLUE}All Fish completions set up successfully.${NC}"
}

function zsh_completions() {
    printf "%b\n" "${BLUE}Setting up Zsh completions in parallel...${NC}"
    # fpath 上で autoload される _<cmd> 形式で配置する (dot_zprofile が fpath に追加済み)
    local comp_dir="$HOME/.config/zsh/completions"
    mkdir -p "$comp_dir"

    local pids=()
    local names=()

    if command -v mise &>/dev/null; then
        gen_completion mise mise completion zsh > "$comp_dir/_mise" &
        pids+=($!); names+=("mise")
    fi
    if command -v uv &>/dev/null; then
        gen_completion uv uv generate-shell-completion zsh > "$comp_dir/_uv" &
        pids+=($!); names+=("uv")
    fi
    # Docker Compose v2 は Docker CLI プラグインのため、docker completion zsh で両方カバーされる
    if command -v docker &>/dev/null; then
        gen_completion docker docker completion zsh > "$comp_dir/_docker" &
        pids+=($!); names+=("docker")
    else
        gen_completion docker curl -sfL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > "$comp_dir/_docker" &
        pids+=($!); names+=("docker")
    fi
    if command -v chezmoi &>/dev/null; then
        gen_completion chezmoi chezmoi completion zsh > "$comp_dir/_chezmoi" &
        pids+=($!); names+=("chezmoi")
    fi
    if command -v gh &>/dev/null; then
        gen_completion gh gh completion -s zsh > "$comp_dir/_gh" &
        pids+=($!); names+=("gh")
    fi
    if command -v rustup &>/dev/null; then
        gen_completion rustup rustup completions zsh > "$comp_dir/_rustup" &
        pids+=($!); names+=("rustup")
    fi
    if command -v ruff &>/dev/null; then
        gen_completion ruff ruff generate-shell-completion zsh > "$comp_dir/_ruff" &
        pids+=($!); names+=("ruff")
    fi
    if command -v kubectl &>/dev/null; then
        gen_completion kubectl kubectl completion zsh > "$comp_dir/_kubectl" &
        pids+=($!); names+=("kubectl")
    fi
    if command -v ngrok &>/dev/null; then
        gen_completion ngrok ngrok completion > "$comp_dir/_ngrok" &
        pids+=($!); names+=("ngrok")
    fi
    if command -v bat &>/dev/null; then
        gen_completion bat bat --completion zsh > "$comp_dir/_bat" &
        pids+=($!); names+=("bat")
    fi
    if command -v fd &>/dev/null; then
        gen_completion fd fd --gen-completions zsh > "$comp_dir/_fd" &
        pids+=($!); names+=("fd")
    fi
    if command -v rg &>/dev/null; then
        gen_completion rg rg --generate complete-zsh > "$comp_dir/_rg" &
        pids+=($!); names+=("rg")
    fi
    if command -v procs &>/dev/null; then
        gen_completion procs procs --gen-completion-out zsh > "$comp_dir/_procs" &
        pids+=($!); names+=("procs")
    fi
    if command -v op &>/dev/null; then
        gen_completion op op completion zsh > "$comp_dir/_op" &
        pids+=($!); names+=("op")
    fi
    if command -v stern &>/dev/null; then
        gen_completion stern stern --completion zsh > "$comp_dir/_stern" &
        pids+=($!); names+=("stern")
    fi
    if command -v yq &>/dev/null; then
        gen_completion yq yq shell-completion zsh > "$comp_dir/_yq" &
        pids+=($!); names+=("yq")
    fi
    if command -v pnpm &>/dev/null; then
        gen_completion pnpm pnpm completion zsh > "$comp_dir/_pnpm" &
        pids+=($!); names+=("pnpm")
    fi

    local failed=()
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed+=("${names[$i]}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf "%b\n" "${RED}Failed Zsh completions: ${failed[*]}${NC}"
        exit 1
    fi
    printf "%b\n" "${BLUE}All Zsh completions set up successfully.${NC}"
}

function bash_completions() {
    printf "%b\n" "${BLUE}Setting up Bash completions in parallel...${NC}"
    # dot_bash_profile が起動時にこのディレクトリ配下を source する
    local comp_dir="$HOME/.local/share/bash-completion/completions"
    mkdir -p "$comp_dir"

    local pids=()
    local names=()

    if command -v mise &>/dev/null; then
        gen_completion mise mise completion bash > "$comp_dir/mise" &
        pids+=($!); names+=("mise")
    fi
    if command -v uv &>/dev/null; then
        gen_completion uv uv generate-shell-completion bash > "$comp_dir/uv" &
        pids+=($!); names+=("uv")
    fi
    # Docker Compose v2 は Docker CLI プラグインのため、docker completion bash で両方カバーされる
    if command -v docker &>/dev/null; then
        gen_completion docker docker completion bash > "$comp_dir/docker" &
        pids+=($!); names+=("docker")
    else
        gen_completion docker curl -sfL https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker > "$comp_dir/docker" &
        pids+=($!); names+=("docker")
    fi
    if command -v chezmoi &>/dev/null; then
        gen_completion chezmoi chezmoi completion bash > "$comp_dir/chezmoi" &
        pids+=($!); names+=("chezmoi")
    fi
    if command -v gh &>/dev/null; then
        gen_completion gh gh completion -s bash > "$comp_dir/gh" &
        pids+=($!); names+=("gh")
    fi
    if command -v rustup &>/dev/null; then
        gen_completion rustup rustup completions bash > "$comp_dir/rustup" &
        pids+=($!); names+=("rustup")
    fi
    if command -v ruff &>/dev/null; then
        gen_completion ruff ruff generate-shell-completion bash > "$comp_dir/ruff" &
        pids+=($!); names+=("ruff")
    fi
    if command -v kubectl &>/dev/null; then
        gen_completion kubectl kubectl completion bash > "$comp_dir/kubectl" &
        pids+=($!); names+=("kubectl")
    fi
    if command -v bat &>/dev/null; then
        gen_completion bat bat --completion bash > "$comp_dir/bat" &
        pids+=($!); names+=("bat")
    fi
    if command -v fd &>/dev/null; then
        gen_completion fd fd --gen-completions bash > "$comp_dir/fd" &
        pids+=($!); names+=("fd")
    fi
    if command -v rg &>/dev/null; then
        gen_completion rg rg --generate complete-bash > "$comp_dir/rg" &
        pids+=($!); names+=("rg")
    fi
    if command -v procs &>/dev/null; then
        gen_completion procs procs --gen-completion-out bash > "$comp_dir/procs" &
        pids+=($!); names+=("procs")
    fi
    if command -v op &>/dev/null; then
        gen_completion op op completion bash > "$comp_dir/op" &
        pids+=($!); names+=("op")
    fi
    if command -v stern &>/dev/null; then
        gen_completion stern stern --completion bash > "$comp_dir/stern" &
        pids+=($!); names+=("stern")
    fi
    if command -v yq &>/dev/null; then
        gen_completion yq yq shell-completion bash > "$comp_dir/yq" &
        pids+=($!); names+=("yq")
    fi
    if command -v pnpm &>/dev/null; then
        gen_completion pnpm pnpm completion bash > "$comp_dir/pnpm" &
        pids+=($!); names+=("pnpm")
    fi

    local failed=()
    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed+=("${names[$i]}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        printf "%b\n" "${RED}Failed Bash completions: ${failed[*]}${NC}"
        exit 1
    fi
    printf "%b\n" "${BLUE}All Bash completions set up successfully.${NC}"
}

function main() {
    if command -v fish &>/dev/null; then
        fish_completions
    fi
    if command -v zsh &>/dev/null; then
        zsh_completions
    fi
    if command -v bash &>/dev/null; then
        bash_completions
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
