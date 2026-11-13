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

    # BTT のアクティベート状態は CLI から確実に判定できないため、初回にリンクを開いたらマーカーを作り、以降は開かない。
    # 再アクティベートするときはマーカーを消す
    local marker="$state_dir/btt-activated"
    if [ -f "$marker" ]; then
        log_step "BetterTouchTool は既にアクティベート済み (マーカーあり)。アクティベートをスキップします。"
    else
        log_step "BetterTouchTool のライセンスを Activate します..."
        open /Applications/BetterTouchTool.app
        # ライセンスの btt://license/... リンクは age で暗号化してあり、平文をディスクに残さないよう
        # chezmoi の config に設定した age 鍵でその場で復号して開く
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
