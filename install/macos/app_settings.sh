#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)
CHEZMOI_SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi/home}"
CHEZMOI_REPO_ROOT="$(cd "$CHEZMOI_SOURCE_DIR/.." && pwd)"

# VS Codeの設定
function vscode() {
    printf "%b\n" "${BLUE}VS Codeの設定を適用中...${NC}"
    # ウィンドウ状態の保存を無効化は VS Code の Settings Sync で管理されない
    defaults write com.microsoft.VSCode ApplePersistenceIgnoreState -bool true
}

function bettertouchtool() {
    # BTT はアクティベート状態を CLI から確実に判定する手段が無いため、初回に
    # アクティベートリンクを開いたらマーカーを作り、以降はリンクを開かない。
    # 再アクティベートしたい場合はこのマーカーを削除する。
    local marker="$HOME/.local/state/chezmoi/btt-activated"
    if [ -f "$marker" ]; then
        printf "%b\n" "${BLUE}BetterTouchTool は既にアクティベート済み (マーカーあり)。アクティベートをスキップします。${NC}"
    else
        printf "%b\n" "${BLUE}BetterTouchToolのライセンスをActivateします...${NC}"
        open /Applications/BetterTouchTool.app
        # ライセンスの btt://license/... ディープリンクは age 暗号化して保管している。
        # 平文をディスクに残さないよう、その場で復号して開く。復号には chezmoi.toml に
        # 設定済みの age 鍵 (~/.config/chezmoi/key.txt) を使う。
        local encrypted_license="$CHEZMOI_REPO_ROOT/settings/macos/btt/encrypted_licence.txt.age"
        local license_url
        if license_url="$(chezmoi decrypt "$encrypted_license" 2>/dev/null)" && [ -n "$license_url" ]; then
            open "$license_url"
            mkdir -p "$(dirname "$marker")"
            touch "$marker"
        else
            printf "%b\n" "${BLUE}ライセンスの復号に失敗しました (age 鍵が未設定の可能性)。アクティベートをスキップします。${NC}"
        fi
    fi

    # 設定 preset は内容が前回 import 時から変わった場合のみ開く (不要な import を回避)。
    # 強制的に再 import したい場合はハッシュ記録ファイルを削除する。
    local preset="$CHEZMOI_REPO_ROOT/settings/macos/btt/Default.bttpreset"
    local preset_hash_file="$HOME/.local/state/chezmoi/btt-preset.sha256"
    local current_hash
    current_hash="$(shasum -a 256 "$preset" | awk '{print $1}')"
    if [ -f "$preset_hash_file" ] && [ "$(cat "$preset_hash_file")" = "$current_hash" ]; then
        printf "%b\n" "${BLUE}BetterTouchTool 設定に変更なし。import をスキップします。${NC}"
    else
        printf "%b\n" "${BLUE}BetterTouchTool設定ファイルを開いています...${NC}"
        open "$preset"
        mkdir -p "$(dirname "$preset_hash_file")"
        printf '%s\n' "$current_hash" > "$preset_hash_file"
    fi
}

function raycast() {
    # 設定ファイルは内容が前回 import 時から変わった場合のみ開く (不要な import を回避)。
    # 強制的に再 import したい場合はハッシュ記録ファイルを削除する。
    local config="$CHEZMOI_REPO_ROOT/settings/macos/Raycast.rayconfig"
    local config_hash_file="$HOME/.local/state/chezmoi/raycast-config.sha256"
    local current_hash
    current_hash="$(shasum -a 256 "$config" | awk '{print $1}')"
    if [ -f "$config_hash_file" ] && [ "$(cat "$config_hash_file")" = "$current_hash" ]; then
        printf "%b\n" "${BLUE}Raycast 設定に変更なし。import をスキップします。${NC}"
    else
        printf "%b\n" "${BLUE}Raycast設定ファイルを開いています...${NC}"
        open "$config"
        mkdir -p "$(dirname "$config_hash_file")"
        printf '%s\n' "$current_hash" > "$config_hash_file"
    fi
}

function main() {
    vscode
    bettertouchtool
    raycast
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
