#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

# gsettings を安全に適用する。スキーマ/キーが存在しない GNOME 構成や拡張未導入の
# 環境ではスキップし、set -e で apply 全体を止めないようにする。
function gset() {
    local schema="$1" key="$2" value="$3"
    if ! gsettings writable "$schema" "$key" &>/dev/null; then
        printf "%b\n" "${YELLOW}  skip: ${schema} ${key} (利用不可)${NC}"
        return 0
    fi
    gsettings set "$schema" "$key" "$value" \
        || printf "%b\n" "${YELLOW}  failed: ${schema} ${key}${NC}"
}

# 1. 外観・インターフェース
function interface_settings() {
    printf "%b\n" "${BLUE}インターフェース設定を適用中...${NC}"
    gset org.gnome.desktop.interface color-scheme 'prefer-dark'    # ダークモード
    gset org.gnome.desktop.interface gtk-theme 'Yaru-dark'         # GTK テーマ (Ubuntu)
    gset org.gnome.desktop.interface show-battery-percentage true  # バッテリー残量を%表示
    gset org.gnome.desktop.interface clock-show-weekday true       # 時計に曜日を表示
    gset org.gnome.desktop.interface clock-show-seconds true       # 時計に秒を表示
    gset org.gnome.desktop.interface enable-hot-corners false      # ホットコーナーを無効化
}

# 2. Dock
function dock_settings() {
    printf "%b\n" "${BLUE}Dock設定を適用中...${NC}"
    gset org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'   # 左に配置
    gset org.gnome.shell.extensions.dash-to-dock dock-fixed false       # 画面に固定しない
    gset org.gnome.shell.extensions.dash-to-dock autohide true          # 自動で隠す
    gset org.gnome.shell.extensions.dash-to-dock intellihide true       # ウィンドウ重なり時に隠す
    gset org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32   # アイコンサイズ
    gset org.gnome.shell.extensions.dash-to-dock show-mounts false       # マウント済みボリュームを表示しない
}

# 3. ファイルマネージャ
function nautilus_settings() {
    printf "%b\n" "${BLUE}ファイルマネージャ設定を適用中...${NC}"
    gset org.gnome.nautilus.preferences default-folder-viewer 'list-view'  # リスト表示をデフォルトに
    gset org.gnome.nautilus.preferences show-hidden-files true             # 隠しファイルを表示
    gset org.gtk.Settings.FileChooser show-hidden true                     # ファイル選択ダイアログでも隠し表示
    gset org.gtk.Settings.FileChooser sort-directories-first true          # ディレクトリを先頭に
}

# 4. キーボード
function keyboard_settings() {
    printf "%b\n" "${BLUE}キーボード設定を適用中...${NC}"
    gset org.gnome.desktop.peripherals.keyboard repeat true
    gset org.gnome.desktop.peripherals.keyboard delay 'uint32 200'           # リピート開始までの遅延(ms)
    gset org.gnome.desktop.peripherals.keyboard repeat-interval 'uint32 20'  # リピート間隔(ms)
}

# 5. タッチパッド
function touchpad_settings() {
    printf "%b\n" "${BLUE}タッチパッド設定を適用中...${NC}"
    gset org.gnome.desktop.peripherals.touchpad tap-to-click true       # タップでクリック
    gset org.gnome.desktop.peripherals.touchpad natural-scroll true     # ナチュラルスクロール
    gset org.gnome.desktop.peripherals.touchpad click-method 'fingers'  # 2本指で右クリック
}

# 6. 電源・画面ロック
function power_settings() {
    printf "%b\n" "${BLUE}電源・画面ロック設定を適用中...${NC}"
    gset org.gnome.desktop.session idle-delay 'uint32 300'      # 5分で画面オフ
    gset org.gnome.desktop.screensaver lock-enabled true        # 画面ロックを有効化
    gset org.gnome.desktop.screensaver lock-delay 'uint32 0'    # 画面オフ後すぐロック
}

# 7. 壁紙の設定
function wallpaper_settings() {
    printf "%b\n" "${BLUE}Setting Dracula wallpaper...${NC}"

    local wallpaper_path="$HOME/Pictures/wallpaper.png"
    mkdir -p "$HOME/Pictures"

    curl -fsSL "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/ubuntu-2.png" \
        --output "$wallpaper_path"

    gset org.gnome.desktop.background picture-uri "file://${wallpaper_path}"
    gset org.gnome.desktop.background picture-uri-dark "file://${wallpaper_path}"
    gset org.gnome.desktop.background picture-options "zoom"

    printf "%b\n" "${BLUE}Dracula wallpaper has been set.${NC}"
}

function main() {
    printf "%b\n" "${BLUE}=== Applying Ubuntu system settings ===${NC}"

    if ! command -v gsettings &>/dev/null; then
        printf "%b\n" "${YELLOW}gsettings not found. Skipping system settings.${NC}"
        return 0
    fi

    interface_settings
    dock_settings
    nautilus_settings
    keyboard_settings
    touchpad_settings
    power_settings
    wallpaper_settings

    printf "%b\n" "${BLUE}=== Ubuntu system settings applied ===${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
