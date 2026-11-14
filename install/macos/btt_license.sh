#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# BTT のアクティベート状態は CLI から確実に判定できないため、リンクを開いたらマーカーを作り、以降は開かない。
# 再アクティベートするときはマーカーを消す
function activate_btt_license() {
    local marker="$HOME/.local/state/chezmoi/btt-activated"
    if [ -f "$marker" ]; then
        log_step "BetterTouchTool は既にアクティベート済み (マーカーあり)。アクティベートをスキップします。"
        return 0
    fi

    # アプリが無いと open が分かりにくいエラーで止まるため、先に原因を示して止める
    if [ ! -d "/Applications/BetterTouchTool.app" ]; then
        log_error "BetterTouchTool.app が見つかりません。brew install --cask bettertouchtool で導入してから再実行してください。"
        return 1
    fi

    log_step "BetterTouchTool のライセンスを Activate します..."
    open /Applications/BetterTouchTool.app
    # ライセンスの btt://license/... リンクは age で暗号化してあり、平文をディスクに残さないよう
    # chezmoi の config に設定した age 鍵でその場で復号して開く
    local license_url
    license_url="$(chezmoi decrypt "$CHEZMOI_REPO_ROOT/settings/macos/btt/encrypted_licence.txt.age")"
    open "$license_url"
    mkdir -p "$(dirname "$marker")"
    touch "$marker"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    activate_btt_license
fi
