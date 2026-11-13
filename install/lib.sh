#!/usr/bin/env bash
# install/**/*.sh が共有する helper。
# .chezmoiscripts の各テンプレートが先頭で 1 回 include し、単体で実行・source するときは各スクリプト冒頭の行が読み込む。
# macOS 標準の bash 3.2 でも動く構文だけを使う。
# 各テンプレートに展開されるため、変更するとこれを include する run_once_* / run_onchange_* が全て再実行される。

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

# sudo -v は TTY があればパスワードを聞いて資格情報をキャッシュする。
# verifypw=all の環境では NOPASSWD でも sudo -v が偽になるため、sudo -n true でも判定する
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

# chezmoi 経由では一時ファイルとして実行され BASH_SOURCE がリポジトリの外を指すため、chezmoi が渡す
# CHEZMOI_SOURCE_DIR (= <repo>/home) を使う。単体で実行・source するときはこのファイルの位置から求める
# shellcheck disable=SC2034  # include 先の各スクリプトが参照する
if [ -n "${CHEZMOI_SOURCE_DIR:-}" ]; then
    CHEZMOI_REPO_ROOT="$(cd "$CHEZMOI_SOURCE_DIR/.." && pwd)"
else
    CHEZMOI_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

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
