#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# gsettings を安全に適用する。スキーマ / キーが存在しない GNOME 構成や拡張未導入の環境では
# スキップし、set -e で apply 全体を止めないようにする
function gset() {
    local schema="$1" key="$2" value="$3"
    if ! gsettings writable "$schema" "$key" &>/dev/null; then
        log_warn "  skip: ${schema} ${key} (利用不可)"
        return 0
    fi
    gsettings set "$schema" "$key" "$value" \
        || log_warn "  failed: ${schema} ${key}"
}

function interface_settings() {
    log_step "インターフェース設定を適用中..."
    gset org.gnome.desktop.interface color-scheme 'prefer-dark'
    gset org.gnome.desktop.interface gtk-theme 'Yaru-dark'
    gset org.gnome.desktop.interface show-battery-percentage true
    gset org.gnome.desktop.interface clock-show-weekday true
    gset org.gnome.desktop.interface clock-show-seconds true
    gset org.gnome.desktop.interface enable-hot-corners false
}

function dock_settings() {
    log_step "Dock 設定を適用中..."
    gset org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
    gset org.gnome.shell.extensions.dash-to-dock dock-fixed false
    gset org.gnome.shell.extensions.dash-to-dock autohide true
    gset org.gnome.shell.extensions.dash-to-dock intellihide true # ウィンドウ重なり時に隠す
    gset org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
    gset org.gnome.shell.extensions.dash-to-dock show-mounts false
}

function nautilus_settings() {
    log_step "ファイルマネージャ設定を適用中..."
    gset org.gnome.nautilus.preferences default-folder-viewer 'list-view'
    gset org.gnome.nautilus.preferences show-hidden-files true
    gset org.gtk.Settings.FileChooser show-hidden true
    gset org.gtk.Settings.FileChooser sort-directories-first true
}

function keyboard_settings() {
    log_step "キーボード設定を適用中..."
    gset org.gnome.desktop.peripherals.keyboard repeat true
    gset org.gnome.desktop.peripherals.keyboard delay 'uint32 200'          # リピート開始までの遅延 (ms)
    gset org.gnome.desktop.peripherals.keyboard repeat-interval 'uint32 20' # リピート間隔 (ms)
}

function touchpad_settings() {
    log_step "タッチパッド設定を適用中..."
    gset org.gnome.desktop.peripherals.touchpad tap-to-click true
    gset org.gnome.desktop.peripherals.touchpad natural-scroll true
    gset org.gnome.desktop.peripherals.touchpad click-method 'fingers' # 2 本指で右クリック
}

function power_settings() {
    log_step "電源・画面ロック設定を適用中..."
    gset org.gnome.desktop.session idle-delay 'uint32 300'   # 5 分で画面オフ
    gset org.gnome.desktop.screensaver lock-enabled true
    gset org.gnome.desktop.screensaver lock-delay 'uint32 0' # 画面オフ後すぐロック
}

function wallpaper_settings() {
    log_step "Setting Dracula wallpaper..."

    local wallpaper_path="$HOME/Pictures/wallpaper.png"
    mkdir -p "$HOME/Pictures"

    # 取得失敗時に壊れた本文を壁紙にしないよう -f で HTTP エラーを検知し、失敗時はスキップする
    if ! curl -fsSL "https://raw.githubusercontent.com/dracula/wallpaper/f2b8cc4223bcc2dfd5f165ab80f701bbb84e3303/first-collection/ubuntu-2.png" \
        --output "$wallpaper_path"; then
        log_warn "壁紙のダウンロードに失敗しました。スキップします。"
        return 0
    fi

    gset org.gnome.desktop.background picture-uri "file://${wallpaper_path}"
    gset org.gnome.desktop.background picture-uri-dark "file://${wallpaper_path}"
    gset org.gnome.desktop.background picture-options "zoom"

    log_step "Dracula wallpaper has been set."
}

function main() {
    log_step "=== Applying Ubuntu system settings ==="

    if ! command -v gsettings &>/dev/null; then
        log_warn "gsettings not found. Skipping system settings."
        return 0
    fi

    interface_settings
    dock_settings
    nautilus_settings
    keyboard_settings
    touchpad_settings
    power_settings
    wallpaper_settings

    log_step "=== Ubuntu system settings applied ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
