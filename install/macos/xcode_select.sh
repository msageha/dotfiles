#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function install_xcode_clt() {
    if xcode-select -p &>/dev/null; then
        log_step "Xcode command line tools are already installed."
        return 0
    fi
    log_step "Installing Xcode command line tools..."
    xcode-select --install
    # xcode-select --install は非同期 (GUI ダイアログ) のため、完了するまで待つ
    log_step "Xcode command line tools のインストール完了を待機中..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    log_step "Xcode command line tools のインストールが完了しました。"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_xcode_clt
fi
