#!/usr/bin/env bash
set -Eeuo pipefail

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# master 追従だと取得時点の内容を検証できないため commit SHA で固定し、
# 取得物を sha256 で検証する。更新時は SHA と checksum を両方手動で上げる
# (checksum を renovate で自動再計算できないため自動追従はさせない)。
GIT_OPEN_COMMIT="63c0e77aaf18b72c839b1113c1e2f9514413643b"
GIT_OPEN_SHA256="b77e75528952693bf70b5ac289bd4580298f998bf938fbfd31753d605339a5e5"
GIT_OPEN_URL="https://raw.githubusercontent.com/paulirish/git-open/${GIT_OPEN_COMMIT}/git-open"
GIT_OPEN_PATH="$HOME/Works/bin/git-open"

function install_git_open() {
    if [ -x "$GIT_OPEN_PATH" ]; then
        printf "%b\n" "${BLUE}git-open is already installed. Skipping.${NC}"
        return
    fi

    printf "%b\n" "${BLUE}Installing git-open command...${NC}"
    mkdir -p "$HOME/Works/bin"
    local tmp_file actual_sha256
    tmp_file="$(mktemp)"
    curl -fsSL -o "$tmp_file" "$GIT_OPEN_URL"
    # sha256sum は Linux (coreutils/busybox)、shasum は macOS 標準
    if command -v sha256sum &>/dev/null; then
        actual_sha256="$(sha256sum "$tmp_file" | awk '{print $1}')"
    else
        actual_sha256="$(shasum -a 256 "$tmp_file" | awk '{print $1}')"
    fi
    if [ "$actual_sha256" != "$GIT_OPEN_SHA256" ]; then
        rm -f "$tmp_file"
        printf "%b\n" "${RED}git-open checksum mismatch (expected ${GIT_OPEN_SHA256}, got ${actual_sha256}). Aborting.${NC}" >&2
        return 1
    fi
    install -m 0755 "$tmp_file" "$GIT_OPEN_PATH"
    rm -f "$tmp_file"
    printf "%b\n" "${BLUE}git-open installed to $GIT_OPEN_PATH${NC}"
}

function main() {
    install_git_open
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
