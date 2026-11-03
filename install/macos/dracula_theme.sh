#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Xcode の Dracula テーマ (*.xccolortheme) は .chezmoiexternal.toml の external が配置する

function terminal_app_has_dracula() {
    # defaults read は空白や記号を含まないキーを引用符なしで出力する
    defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q '^    Dracula = '
}

# https://draculatheme.com/terminal-app
function terminal_app_dracula() {
    log_step "Terminal.app Dracula テーマをインストール中..."

    if terminal_app_has_dracula; then
        log_step "  Dracula テーマは既にインストールされています。スキップ"
        return 0
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064  # $tmp_dir を今展開して trap に固定する
    trap "rm -rf '$tmp_dir'" RETURN

    if ! git clone --depth 1 https://github.com/dracula/terminal-app.git "$tmp_dir" 2>/dev/null; then
        log_step "  リポジトリのクローンに失敗しました。スキップ"
        return 0
    fi

    # フォントを SauceCodePro Nerd Font Mono 18pt にする (Ghostty と統一)。
    # Terminal が起動中だと plist を直接書き換えても上書きされるため、import 前のプロファイルに埋め込む。
    # PyObjC は CLT の python3 に無いことがあるため、OS 標準の JXA で NSFont をアーカイブする
    local font_data
    font_data="$(osascript -l JavaScript -e '
        ObjC.import("AppKit");
        const font = $.NSFont.fontWithNameSize("SauceCodeProNFM", 18);
        font.isNil() ? "" : $.NSKeyedArchiver.archivedDataWithRootObjectRequiringSecureCodingError(font, false, null).base64EncodedStringWithOptions(0).js;
    ')"
    if [ -n "$font_data" ]; then
        plutil -replace Font -data "$font_data" "$tmp_dir/Dracula.terminal"
    else
        log_step "  警告: SauceCodePro Nerd Font が見つかりません。フォント設定をスキップ"
    fi

    # open は非同期のため、固定 sleep ではなくプロファイルが実際に登録されるまでポーリングで待つ
    open "$tmp_dir/Dracula.terminal"
    local waited=0
    until terminal_app_has_dracula; do
        if [ "$waited" -ge 30 ]; then
            log_step "  Dracula プロファイルの登録を確認できませんでした。スキップ"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    # open で起動済みの Terminal は defaults write を読み直さないため、Terminal 自身に設定させる
    # (初回は呼び出し元のアプリに Terminal の Automation 許可を求めるダイアログが出る)
    if ! osascript -e 'tell application "Terminal"
        set default settings to settings set "Dracula"
        set startup settings to settings set "Dracula"
    end tell' >/dev/null; then
        log_step "  警告: Dracula をデフォルトに設定できませんでした。Terminal の設定で手動で選んでください"
        return 0
    fi

    log_step "  Dracula テーマをインストールしデフォルトに設定しました"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    terminal_app_dracula
fi
