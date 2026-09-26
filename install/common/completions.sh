#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# 補完を生成するツール。導入されているものだけを対象にする
completion_tools=(mise fnox uv docker chezmoi gh ruff kubectl ngrok bat fd rg procs op stern yq pnpm)

# $1 = tool, $2 = fish | zsh | bash。補完スクリプトを stdout へ出力する
function print_completion() {
    local tool="$1" shell="$2"
    case "$tool" in
        mise)
            if [[ "$shell" == bash ]]; then
                mise completion bash --include-bash-completion-lib
            else
                mise completion "$shell"
            fi
            ;;
        # Docker Compose v2 は Docker CLI プラグインのため docker completion で両方カバーされる
        fnox | docker | chezmoi | kubectl | op | pnpm) "$tool" completion "$shell" ;;
        uv | ruff) "$tool" generate-shell-completion "$shell" ;;
        gh) gh completion -s "$shell" ;;
        # ngrok は SHELL 環境変数でシェル種別を判定する (bash / zsh のみ対応)
        ngrok) env SHELL="$(command -v "$shell")" ngrok completion ;;
        bat | stern) "$tool" --completion "$shell" ;;
        fd) fd --gen-completions "$shell" ;;
        rg) rg --generate "complete-$shell" ;;
        procs) procs --gen-completion-out "$shell" ;;
        yq) yq shell-completion "$shell" ;;
        *)
            log_error "no completion recipe for ${tool}"
            return 1
            ;;
    esac
}

# 生成途中の失敗で壊れたファイルや空ファイルを残さないよう、一時ファイルへ書いてから置き換える。
# mv は既存の symlink (kubectl.fish が symlink だった環境がある) もリンク先へ書き込まず実体ファイルで置き換える
function write_completion() {
    local tool="$1" shell="$2" out="$3"
    if print_completion "$tool" "$shell" > "$out.tmp" && [ -s "$out.tmp" ]; then
        mv "$out.tmp" "$out"
    else
        rm -f "$out.tmp"
        return 1
    fi
}

# $1 = fish | zsh | bash, $2 = 出力ディレクトリ。ツールごとに並列生成し、失敗は最後にまとめて報告する
function generate_completions() {
    local shell="$1" comp_dir="$2"
    log_step "Setting up ${shell} completions in parallel..."
    mkdir -p "$comp_dir"

    local pids=() names=() tool out
    for tool in "${completion_tools[@]}"; do
        command -v "$tool" &>/dev/null || continue
        [[ "$tool" == ngrok && "$shell" == fish ]] && continue
        case "$shell" in
            fish) out="$comp_dir/$tool.fish" ;;
            zsh) out="$comp_dir/_$tool" ;;
            bash) out="$comp_dir/$tool" ;;
        esac
        write_completion "$tool" "$shell" "$out" &
        pids+=($!)
        names+=("$tool")
    done

    local failed=() i
    for ((i = 0; i < ${#pids[@]}; i++)); do
        wait "${pids[$i]}" || failed+=("${names[$i]}")
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed ${shell} completions: ${failed[*]}"
        exit 1
    fi
    log_step "All ${shell} completions set up successfully."
}

function main() {
    if command -v fish &>/dev/null; then
        generate_completions fish "$HOME/.config/fish/completions"
    fi
    # zsh は fpath 上で autoload される _<cmd> 形式 (dot_zprofile が fpath に追加済み)
    if command -v zsh &>/dev/null; then
        generate_completions zsh "$HOME/.config/zsh/completions"
    fi
    # bash は dot_bash_profile が起動時にこのディレクトリ配下を source する
    if command -v bash &>/dev/null; then
        generate_completions bash "$HOME/.local/share/bash-completion/completions"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
