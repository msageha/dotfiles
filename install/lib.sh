#!/usr/bin/env bash
# install/**/*.sh が共有する helper。
# chezmoi の各 .chezmoiscripts/*.sh.tmpl が先頭で 1 回 include し (後続の subshell に継承される)、
# スクリプトを単体で実行・source するときは各スクリプト冒頭の
# `declare -F log_step >/dev/null 2>&1 || source .../lib.sh` がこのファイルを読み込む。
# macOS 標準の bash 3.2 でも動く構文に限定する。

RED="\033[0;31m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m"

function log_step() {
    printf "%b\n" "${BLUE}$*${NC}"
}

function log_warn() {
    printf "%b\n" "${YELLOW}$*${NC}" >&2
}

function log_error() {
    printf "%b\n" "${RED}$*${NC}" >&2
}

function require_command() {
    if ! command -v "$1" &>/dev/null; then
        log_error "$1 could not be found, please install $1 first."
        exit 1
    fi
}

# root なら真。非 root は sudo -v (TTY があればパスワードを聞いて資格情報をキャッシュする) で判定し、
# verifypw=all 環境で sudo -v が偽になる NOPASSWD 構成は sudo -n true で拾う
function has_privilege() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    sudo -v 2>/dev/null || sudo -n true 2>/dev/null
}

function run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# chezmoi はスクリプト実行時に CHEZMOI_SOURCE_DIR (= <repo>/home) を渡す。
# 単体実行・source 時 (bats・CI の checkout 先など配置は任意) はこのファイルの位置から求める
if [ -n "${CHEZMOI_SOURCE_DIR:-}" ]; then
    CHEZMOI_REPO_ROOT="$(cd "$CHEZMOI_SOURCE_DIR/.." && pwd)"
else
    CHEZMOI_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export CHEZMOI_REPO_ROOT

# ログインシェルを経ずに実行される chezmoi スクリプトへ、導入済みツールの PATH を通す
function activate_tool_paths() {
    export PATH="$HOME/.local/bin:$PATH"
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if command -v mise &>/dev/null; then
        eval "$(mise activate bash --shims)"
    fi
}
