#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

completion_tools=(mise fnox uv docker chezmoi gh ruff kubectl ngrok bat fd rg procs op stern yq pnpm)

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
        # Docker Compose v2 は Docker CLI のプラグインなので、docker の補完に含まれる
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

# 生成に失敗したとき壊れたファイルや空ファイルを残さないよう、一時ファイルへ書いてから mv で置き換える
# (mv は既存の symlink のリンク先へは書き込まず、symlink 自体を置き換える)
function write_completion() {
    local tool="$1" shell="$2" out="$3"
    if print_completion "$tool" "$shell" > "$out.tmp" && [ -s "$out.tmp" ]; then
        mv "$out.tmp" "$out"
    else
        rm -f "$out.tmp"
        return 1
    fi
}

# mise の shim は、config から外したツールでも版が入っている間は PATH に残る。shim は PATH のほかの場所の実体へ
# 実行を回すが、mise で有効でなく実体もほかに無いと "No version is set for shim" で失敗するので、使えないツールとして扱う
function has_tool() {
    local path
    path="$(command -v "$1")" || return 1
    # grep -q は一致した時点で抜けるので、書き込み中の type が SIGPIPE で落ち、pipefail で偽になりうる
    case "$path" in
        */mise/shims/*) mise which "$1" &>/dev/null || type -aP "$1" | grep -v '/mise/shims/' >/dev/null ;;
    esac
}

function generate_completions() {
    local shell="$1" comp_dir="$2"
    log_step "Setting up ${shell} completions in parallel..."
    mkdir -p "$comp_dir"

    local pids=() names=() tool out
    for tool in "${completion_tools[@]}"; do
        has_tool "$tool" || continue
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

# 補完の生成先から外れた ~/.config の補完を知らせる。利用者が置いたものかもしれないので消さない。
# fish は ~/.config/fish/completions の補完を生成した同名の補完より優先して読み、zsh は ~/.config/zsh/completions を fpath に入れない
function warn_completions_in_config() {
    local tool comp
    for tool in "${completion_tools[@]}"; do
        if [ -e "$HOME/.config/fish/completions/$tool.fish" ] && [ -e "$HOME/.local/share/fish/vendor_completions.d/$tool.fish" ]; then
            log_warn "${HOME}/.config/fish/completions/${tool}.fish が生成した補完より優先されます。不要なら削除してください。"
        fi
    done
    for comp in "$HOME/.config/zsh/completions"/*; do
        [ -e "$comp" ] || continue
        log_warn "${comp} は zsh の fpath に入らないので読まれません。要るなら ${HOME}/.local/share/zsh/site-functions へ移してください。"
    done
}

function main() {
    # 補完は生成物なので、手で書く設定を置く ~/.config ではなく XDG の data 側 (~/.local/share) に書く。
    # fish は vendor_completions.d を補完の検索先に含める
    if command -v fish &>/dev/null; then
        generate_completions fish "$HOME/.local/share/fish/vendor_completions.d"
    fi
    # zsh は fpath 上の _<cmd> を autoload する (このディレクトリは dot_zprofile が fpath に足す)
    if command -v zsh &>/dev/null; then
        generate_completions zsh "$HOME/.local/share/zsh/site-functions"
    fi
    # bash は dot_bash_profile が起動時にこのディレクトリ配下を source する
    if command -v bash &>/dev/null; then
        generate_completions bash "$HOME/.local/share/bash-completion/completions"
    fi
    warn_completions_in_config
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
