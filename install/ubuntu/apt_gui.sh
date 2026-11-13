#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

apt_apps=(
    fcitx5-mozc # 日本語入力
)

snap_apps=(
    discord
)

snap_classic_apps=(
    code # Visual Studio Code
    ghostty
    pycharm-community
    goland
    datagrip
    webstorm
)

function update() {
    log_step "Updating APT package lists..."
    run_privileged apt -yq update
}

function install_apt_apps() {
    log_step "Installing APT GUI packages..."
    run_privileged apt install -yq "${apt_apps[@]}"
}

function install_snap_app() {
    local app="$1"
    shift
    if snap list "$app" &>/dev/null; then
        log_step "${app} is already installed. Skipping"
        return 0
    fi
    log_step "Installing ${app}${1:+ ($1)}..."
    run_privileged snap install "$app" "$@"
}

function install_snap_apps() {
    log_step "Installing snap apps..."
    if ! command -v snap &>/dev/null; then
        log_warn "snap が見つかりません (snapd 非搭載環境)。snap アプリのインストールをスキップします。"
        return 0
    fi
    local app
    for app in "${snap_apps[@]}"; do
        install_snap_app "$app"
    done
    for app in "${snap_classic_apps[@]}"; do
        install_snap_app "$app" --classic
    done
}

# Google Chrome は Ubuntu の apt リポジトリに無いため、Google の .deb から入れる。
# .deb が Google の apt リポジトリと署名鍵を登録するので、以降は apt upgrade で更新される
function install_chrome() {
    log_step "Installing Google Chrome..."
    if command -v google-chrome &>/dev/null; then
        log_step "Google Chrome is already installed."
        return 0
    fi

    local arch
    arch="$(dpkg --print-architecture)"
    # Linux 版は amd64 と arm64 だけが配布されている
    case "$arch" in
        amd64 | arm64) ;;
        *)
            log_warn "Google Chrome is not available for ${arch}. Skipping."
            return 0
            ;;
    esac

    local deb
    deb="$(mktemp --suffix=.deb)"
    # shellcheck disable=SC2064  # $deb を今展開して trap に固定する
    trap "rm -f '$deb'" RETURN
    if ! curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_${arch}.deb" -o "$deb"; then
        log_warn "Failed to download Google Chrome for ${arch} (build may not be published yet). Skipping."
        return 0
    fi
    run_privileged apt install -yq "$deb"
}

function main() {
    log_step "=== Installing Ubuntu GUI apps ==="
    if ! has_privilege; then
        log_warn "root/sudo 権限が無いため GUI アプリのインストールをすべてスキップします。"
        return 0
    fi

    update
    install_apt_apps
    install_chrome
    install_snap_apps
    log_step "=== All Ubuntu GUI apps installed! ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
