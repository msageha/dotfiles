#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

state_dir="$HOME/.local/state/chezmoi"

# 設定ファイルは内容が前回 import 時から変わった場合のみ開く (不要な import を回避)。
# 強制的に再 import したい場合は $state_dir/<name>.sha256 を削除する
function open_if_changed() {
    local label="$1" file="$2" hash_file="$state_dir/$3.sha256" current_hash
    current_hash="$(shasum -a 256 "$file" | awk '{print $1}')"
    if [ -f "$hash_file" ] && [ "$(cat "$hash_file")" = "$current_hash" ]; then
        log_step "${label} 設定に変更なし。import をスキップします。"
        return 0
    fi
    log_step "${label} 設定ファイルを開いています..."
    open "$file"
    mkdir -p "$state_dir"
    printf '%s\n' "$current_hash" > "$hash_file"
}

function vscode() {
    log_step "VS Code の設定を適用中..."
    # ApplePersistenceIgnoreState は Settings Sync の対象外なのでここで設定する
    defaults write com.microsoft.VSCode ApplePersistenceIgnoreState -bool true
}

function bettertouchtool() {
    # cask の導入失敗などでアプリが無い場合は open の不明瞭なエラーで止まる前に原因を明示する
    if [ ! -d "/Applications/BetterTouchTool.app" ]; then
        log_error "BetterTouchTool.app が見つかりません。brew install --cask bettertouchtool で導入してから再実行してください。"
        return 1
    fi

    # BTT はアクティベート状態を CLI から確実に判定する手段が無いため、初回に
    # アクティベートリンクを開いたらマーカーを作り、以降はリンクを開かない。
    # 再アクティベートしたい場合はこのマーカーを削除する
    local marker="$state_dir/btt-activated"
    if [ -f "$marker" ]; then
        log_step "BetterTouchTool は既にアクティベート済み (マーカーあり)。アクティベートをスキップします。"
    else
        log_step "BetterTouchTool のライセンスを Activate します..."
        open /Applications/BetterTouchTool.app
        # ライセンスの btt://license/... ディープリンクは age 暗号化して保管している。
        # 平文をディスクに残さないよう、その場で復号して開く (chezmoi.toml の age 鍵を使う)
        local license_url
        if license_url="$(chezmoi decrypt "$CHEZMOI_REPO_ROOT/settings/macos/btt/encrypted_licence.txt.age" 2>/dev/null)" && [ -n "$license_url" ]; then
            open "$license_url"
            mkdir -p "$state_dir"
            touch "$marker"
        else
            log_step "ライセンスの復号に失敗しました (age 鍵が未設定の可能性)。アクティベートをスキップします。"
        fi
    fi

    open_if_changed "BetterTouchTool" "$CHEZMOI_REPO_ROOT/settings/macos/btt/dotfiles.bttpreset" btt-preset
}

function main() {
    vscode
    bettertouchtool
    open_if_changed "Raycast" "$CHEZMOI_REPO_ROOT/settings/macos/Raycast.rayconfig" raycast-config
    open_if_changed "Stream Deck" "$CHEZMOI_REPO_ROOT/settings/macos/dotfiles.streamDeckProfile" streamdeck-profile
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
