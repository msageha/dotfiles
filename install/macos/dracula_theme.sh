#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

# Xcode の Dracula テーマ (*.xccolortheme) は .chezmoiexternal.toml の external が配置する

# https://draculatheme.com/terminal-app
function terminal_app_dracula() {
    printf "%b\n" "${BLUE}Terminal.app Draculaテーマをインストール中...${NC}"

    local repo_url="https://github.com/dracula/terminal-app.git"

    if defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q '"Dracula"'; then
        printf "%b\n" "${BLUE}  Draculaテーマは既にインストールされています。スキップ${NC}"
        return 0
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp_dir'" RETURN

    if ! git clone --depth 1 "$repo_url" "$tmp_dir" 2>/dev/null; then
        printf "%b\n" "${BLUE}  リポジトリのクローンに失敗しました。スキップ${NC}"
        return 0
    fi

    # open は非同期のため、固定 sleep ではなくプロファイルが実際に登録されるまでポーリングで待つ
    open "$tmp_dir/Dracula.terminal"
    local waited=0
    until defaults read com.apple.Terminal "Window Settings" 2>/dev/null | grep -q '"Dracula"'; do
        if [ "$waited" -ge 30 ]; then
            printf "%b\n" "${BLUE}  Dracula プロファイルの登録を確認できませんでした。続行します${NC}"
            break
        fi
        sleep 1
        waited=$((waited + 1))
    done
    defaults write com.apple.Terminal "Default Window Settings" -string "Dracula"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Dracula"

    # フォントを SauceCodePro Nerd Font 18pt に設定（Ghostty と統一）
    # PyObjC (AppKit) は CLT の python3 に含まれない場合があるため、無ければ
    # フォント設定だけスキップする
    if ! python3 -c 'import AppKit, Foundation' 2>/dev/null; then
        printf "%b\n" "${BLUE}  PyObjC が無いためフォント設定をスキップします${NC}"
        trap - RETURN
        rm -rf "$tmp_dir"
        printf "%b\n" "${BLUE}  Draculaテーマをインストールしデフォルトに設定しました${NC}"
        return 0
    fi
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
    prefs["Window Settings"]["Dracula"]["Font"] = font_data
    prefs.writeToFile_atomically_(plist_path, True)
    print("  フォントを SauceCodePro Nerd Font 18pt に設定しました")
PYTHON

    trap - RETURN
    rm -rf "$tmp_dir"

    printf "%b\n" "${BLUE}  Draculaテーマをインストールしデフォルトに設定しました${NC}"
}

function main() {
    terminal_app_dracula
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
