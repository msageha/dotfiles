#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# Xcode の Dracula テーマ (*.xccolortheme) は .chezmoiexternal.toml の external が配置する

# https://draculatheme.com/terminal-app
function terminal_app_dracula() {
    log_step "Terminal.app Dracula テーマをインストール中..."

    if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q '"Dracula"'; then
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

    # open は非同期のため、固定 sleep ではなくプロファイルが実際に登録されるまでポーリングで待つ
    open "$tmp_dir/Dracula.terminal"
    local waited=0
    until defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q '"Dracula"'; do
        if [ "$waited" -ge 30 ]; then
            log_step "  Dracula プロファイルの登録を確認できませんでした。続行します"
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done
    defaults write com.apple.Terminal "Default Window Settings" -string "Dracula"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Dracula"

    # フォントを SauceCodePro Nerd Font 18pt に設定する (Ghostty と統一)。
    # PyObjC (AppKit) は CLT の python3 に含まれない場合があるため、無ければフォント設定だけスキップする
    if python3 -c 'import AppKit, Foundation' 2>/dev/null; then
        python3 - <<'PYTHON'
import AppKit, Foundation

font = AppKit.NSFont.fontWithName_size_("SauceCodeProNFM-Regular", 18)
if font is None:
    print("  警告: SauceCodePro Nerd Font が見つかりません。フォント設定をスキップ")
    raise SystemExit(0)

font_data = Foundation.NSKeyedArchiver.archivedDataWithRootObject_requiringSecureCoding_(font, False)

plist_path = Foundation.NSString.stringWithString_(
    Foundation.NSHomeDirectory() + "/Library/Preferences/com.apple.Terminal.plist"
)
prefs = Foundation.NSMutableDictionary.dictionaryWithContentsOfFile_(plist_path)
if prefs and "Window Settings" in prefs and "Dracula" in prefs["Window Settings"]:
    window_settings = prefs["Window Settings"].mutableCopy()
    dracula = window_settings["Dracula"].mutableCopy()
    dracula["Font"] = font_data
    window_settings["Dracula"] = dracula
    prefs["Window Settings"] = window_settings
    prefs.writeToFile_atomically_(plist_path, True)
    print("  フォントを SauceCodePro Nerd Font 18pt に設定しました")
PYTHON
    else
        log_step "  PyObjC が無いためフォント設定をスキップします"
    fi

    log_step "  Dracula テーマをインストールしデフォルトに設定しました"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    terminal_app_dracula
fi
