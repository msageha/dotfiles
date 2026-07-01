#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

# Xcode に Dracula テーマをインストール
# https://draculatheme.com/xcode
function xcode_dracula() {
    printf "%b\n" "${BLUE}Xcode Draculaテーマをインストール中...${NC}"

    local theme_dir="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"
    local repo_url="https://github.com/dracula/xcode.git"

    # テーマディレクトリを作成
    mkdir -p "$theme_dir"

    # 既にテーマが存在する場合はスキップ
    if [[ -f "$theme_dir/Dracula.xccolortheme" ]]; then
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

    # Dracula.xccolortheme と Alucard.xccolortheme を配置
    for theme_file in "$tmp_dir/"*.xccolortheme; do
        [[ -f "$theme_file" ]] && cp "$theme_file" "$theme_dir/"
    done

    trap - RETURN
    rm -rf "$tmp_dir"

    printf "%b\n" "${BLUE}  Draculaテーマをインストールしました${NC}"
    printf "%b\n" "${BLUE}  Xcode → Preferences → Themes から選択してください${NC}"
}

# Terminal.app に Dracula テーマをインストール
# https://draculatheme.com/terminal-app
function terminal_app_dracula() {
    printf "%b\n" "${BLUE}Terminal.app Draculaテーマをインストール中...${NC}"

    local repo_url="https://github.com/dracula/terminal-app.git"

    # 既にプロファイルが存在する場合はスキップ
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

    # Dracula.terminal をインポートしてデフォルトに設定
    open "$tmp_dir/Dracula.terminal"
    sleep 1
    defaults write com.apple.Terminal "Default Window Settings" -string "Dracula"
    defaults write com.apple.Terminal "Startup Window Settings" -string "Dracula"

    # フォントを SauceCodePro Nerd Font 18pt に設定（Ghostty と統一）
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
    xcode_dracula
    terminal_app_dracula
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
