#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

state_dir="$HOME/.local/state/chezmoi"

# 設定ファイルを開くとアプリが import を始めるので、前回の import から内容が変わったときだけ開く。
# 再 import させたいときは $state_dir/<name>.sha256 を消す
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
    # アプリが無いと open が分かりにくいエラーで止まるため、先に原因を示して止める
    if [ ! -d "/Applications/BetterTouchTool.app" ]; then
        log_error "BetterTouchTool.app が見つかりません。brew install --cask bettertouchtool で導入してから再実行してください。"
        return 1
    fi

    open_if_changed "BetterTouchTool" "$CHEZMOI_REPO_ROOT/settings/macos/btt/dotfiles.bttpreset" btt-preset

    # BTT にはログイン時の起動を設定する defaults の key が無いため、macOS のログイン項目に登録する。
    # 初回は System Events の Automation 許可を求めるダイアログが出るので、拒否されても apply を止めないよう失敗は警告にとどめる
    log_step "BetterTouchTool をログイン項目に登録しています..."
    if ! osascript -e 'tell application "System Events"
        if not (exists login item "BetterTouchTool") then
            make login item at end with properties {path:"/Applications/BetterTouchTool.app", hidden:false}
        end if
    end tell' >/dev/null; then
        log_warn "BetterTouchTool をログイン項目に登録できませんでした。システム設定 > 一般 > ログイン項目 で追加してください。"
    fi
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
