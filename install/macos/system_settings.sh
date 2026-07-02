#!/usr/bin/env bash
set -Eeuo pipefail  # エラー処理と未定義変数の扱いを強化

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color (リセット)

# 1. コンピュータ名の変更
function computer_name() {
    printf "%b\n" "${BLUE}Setting computer name...${NC}"

    # すでに目的の名前ならスキップする
    local current
    current="$(scutil --get ComputerName 2>/dev/null || true)"
    if [[ "$current" == "$COMPUTER_NAME" ]]; then
        printf "%b\n" "${BLUE}コンピュータ名は既に '$COMPUTER_NAME' です。スキップ${NC}"
        return 0
    fi

    # コンピュータのネットワーク名を変更し、DNSキャッシュをクリア
    printf "%b\n" "${BLUE}コンピュータ名を設定しています... ($COMPUTER_NAME)${NC}"
    sudo scutil --set ComputerName "$COMPUTER_NAME"  # 環境変数を使用
    sudo scutil --set HostName "$COMPUTER_NAME"  # ホスト名を変更
    sudo scutil --set LocalHostName "$COMPUTER_NAME"  # Bonjour名
    sudo dscacheutil -flushcache  # DNSキャッシュをクリア
}


# 2. システムの基本設定
function system_settings() {
    printf "%b\n" "${BLUE}システムの基本設定を行っています...${NC}"
    defaults write NSGlobalDomain AppleLanguages -array "ja-JP"
    defaults write NSGlobalDomain AppleLocale -string "ja_JP"
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"  # ダークモード
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false  # ダブルクリックで最小化を無効化
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false  # 自動大文字機能を無効化
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false  # 自動ピリオド挿入を無効化
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false  # 自動スペルチェックを無効化
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false  # スマートクォートを無効化
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false  # スマートダッシュを無効化
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true  # 保存ダイアログを常に展開
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true  # 印刷ダイアログを常に展開
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # iCloudへの自動保存を無効化
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true  # 全ファイルの拡張子を表示
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.1  # ウィンドウリサイズアニメーション高速化
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true  # 印刷完了後にプリンタアプリを自動終了
}

# 3. Dockの設定
function dock_settings() {
    printf "%b\n" "${BLUE}Dockの設定を行っています...${NC}"
    defaults write com.apple.dock orientation -string "right"  # 右にDockを配置
    defaults write com.apple.dock tilesize -int 50  # Dockアイコンのサイズを50に設定
    defaults write com.apple.dock show-recents -bool false  # 最近のアプリを非表示
    defaults write com.apple.dock autohide -bool true  # Dockを自動で隠す
    defaults write com.apple.dock magnification -bool false  # 拡大機能を無効化
    defaults write com.apple.dock mru-spaces -bool false  # Spacesの自動並べ替えを無効化
    defaults write com.apple.dock expose-group-apps -bool true  # Mission Controlでアプリごとにウィンドウをグループ化
    defaults write com.apple.dock autohide-delay -float 0  # Dock表示の遅延をなくす
    defaults write com.apple.dock autohide-time-modifier -float 0.5  # Dockアニメーション高速化
}

# 4. Dockに固定するアプリを追加
function dock_apps() {
    printf "%b\n" "${BLUE}Dockにアプリを追加しています...${NC}"
    if ! command -v dockutil &>/dev/null; then
        printf "%b\n" "${RED}dockutil が見つかりません。brew install dockutil を実行してください。${NC}"
        exit 1
    fi
    dockutil --remove all --no-restart
    local -a apps=(
        "/Applications/Google Chrome.app"
        "/Applications/DataGrip.app"
        "/Applications/PyCharm.app"
        "/Applications/Goland.app"
        "/Applications/WebStorm.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Discord.app"
    )
    for app in "${apps[@]}"; do
        if [[ -d "$app" ]]; then
            dockutil --add "$app" --no-restart
        else
            printf "%b\n" "${BLUE}  '$app' が見つかりません。スキップ${NC}"
        fi
    done

    # Dockにフォルダを追加
    dockutil --add "$HOME/Downloads" --view grid --display folder --sort dateadded --no-restart
}

# 5. メニューバーの設定
function menu_bar_settings() {
    printf "%b\n" "${BLUE}メニューバーの設定を行っています...${NC}"
    # Bluetoothアイコン表示、バッテリーのパーセント表示、音量アイコンを有効化
    defaults write com.apple.controlcenter.plist Bluetooth -int 18  # Bluetoothアイコン表示
    defaults write com.apple.controlcenter.plist BatteryShowPercentage -bool true  # バッテリーパーセント表示
    defaults write com.apple.controlcenter.plist Sound -int 18  # 音量アイコン表示
}

# 6. Finderの設定
function finder_settings() {
    printf "%b\n" "${BLUE}Finderの設定を行っています...${NC}"
    # 隠しファイル表示、パスバー、ステータスバーの表示を有効化
    defaults write com.apple.finder AppleShowAllFiles true  # 隠しファイルを表示
    defaults write com.apple.finder ShowPathbar -bool true  # パスバーを表示
    defaults write com.apple.finder ShowStatusBar -bool true  # ステータスバーを表示
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # デフォルト表示をリスト表示に設定
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false  # 拡張子変更の警告を無効化
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # 検索時にカレントフォルダを対象
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # ネットワーク上に.DS_Storeを作成しない
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true  # USB上に.DS_Storeを作成しない
    # _FXShowPosixPathInTitle は macOS Ventura (13) 以降で無効化されたため削除
}

# 7. ホットコーナーの設定
function hot_corners_settings() {
    printf "%b\n" "${BLUE}ホットコーナーの設定を行っています...${NC}"
    defaults write com.apple.dock wvous-tr-corner -int 5  # 右上で、スクリーンセイバー開始
    defaults write com.apple.dock wvous-br-corner -int 13  # 右下で、ロック画面
    defaults write com.apple.dock wvous-tl-corner -int 5  # 左上で、スクリーンセイバー開始
    defaults write com.apple.dock wvous-bl-corner -int 13  # 左下で、ロック画面
}

# 8. スクリーンセーバーの設定
function screensaver_settings() {
    printf "%b\n" "${BLUE}スクリーンセーバーの設定を行っています...${NC}"
    # 5分後にスクリーンセーバーを起動
    defaults -currentHost write com.apple.screensaver idleTime -int 300
}

# 9. 壁紙の設定
function wallpaper_settings() {
    printf "%b\n" "${BLUE}壁紙の設定を行っています...${NC}"
    # Draculaテーマの壁紙をダウンロードして設定
    mkdir -p "$HOME/Pictures"
    # 取得失敗時に壊れた本文を壁紙にしないよう -f で HTTP エラーを検知し、失敗時はスキップする
    if ! curl -fsSL "https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/macos.png" --output "$HOME/Pictures/wallpaper.png"; then
        printf "%b\n" "${RED}壁紙のダウンロードに失敗しました。スキップします。${NC}"
        return 0
    fi
    # macOS Sonoma (14) 以降では Finder の AppleScript が壁紙設定に対応しなくなったため System Events を使用
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$HOME/Pictures/wallpaper.png\"" || \
        printf "%b\n" "${RED}壁紙の設定に失敗しました (オートメーション許可が必要な場合があります)。${NC}"
}

# 10. スクリーンショットの設定
function screenshot_settings() {
    printf "%b\n" "${BLUE}スクリーンショットの設定を行っています...${NC}"
    mkdir -p "$HOME/Pictures/Screenshots"
    defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
    defaults write com.apple.screencapture show-thumbnail -bool false  # 撮影後のサムネイルを非表示
    defaults write com.apple.screencapture style -string "window"  # ウィンドウキャプチャモード
}

# 11. キーボード設定
function keyboard_settings() {
    printf "%b\n" "${BLUE}キーボード設定を行っています...${NC}"
    # キーリピート速度を調整
    defaults write -g InitialKeyRepeat -int 15  # 最初のリピートまでの時間
    defaults write -g KeyRepeat -int 2  # リピート速度
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # 長押しで特殊文字パネルを出さない（キーリピート優先）
}

# 12. トラックパッドの設定
function trackpad_settings() {
    printf "%b\n" "${BLUE}トラックパッドの設定を行っています...${NC}"
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true  # 2本指で右クリック
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false  # 3本指ドラッグ無効
    defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true  # ピンチズーム有効
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true  # 回転ジェスチャー有効
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 1  # スマートズーム有効
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3  # 右端スワイプで通知センター
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2  # 4本指横スワイプでデスクトップ切替
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2  # 4本指縦スワイプでMission Control
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 2  # 5本指ピンチでLaunchpad
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2  # 4本指ピンチでLaunchpad
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2  # 3本指横スワイプでページ切替
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0  # 3本指縦スワイプ無効 (BTTの新規タブ/タブを閉じるジェスチャを優先。Mission Control/App Exposéは4本指)
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0  # 3本指タップ無効 (BTTのミドルクリックジェスチャを優先)
    defaults write com.apple.dock showAppExposeGestureEnabled -bool true  # App Exposéジェスチャ有効 (4本指下スワイプ)
    defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true  # 慣性スクロール有効
}

# 13. ウィンドウ管理の設定
function window_manager_settings() {
    printf "%b\n" "${BLUE}ウィンドウ管理の設定を行っています...${NC}"
    defaults write com.apple.WindowManager GloballyEnabled -bool false  # Stage Managerを無効化
    defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false  # タイルウィンドウのマージンを無効化
    defaults write com.apple.WindowManager HideDesktop -bool true  # デスクトップクリックでウィンドウを隠す
    defaults write com.apple.WindowManager StageManagerHideWidgets -bool false  # ウィジェットを表示
    defaults write com.apple.WindowManager StandardHideWidgets -bool false  # 標準モードでもウィジェットを表示
}

# 14. Finder、SystemUIServer、Dockの再起動
function restart_services() {
    printf "%b\n" "${BLUE}Finder、SystemUIServer、Dockを再起動しています...${NC}"
    killall Finder || true
    killall SystemUIServer || true
    killall Dock || true
}

function main() {
    computer_name
    system_settings
    dock_settings
    dock_apps
    menu_bar_settings
    finder_settings
    hot_corners_settings
    screensaver_settings
    wallpaper_settings
    screenshot_settings
    keyboard_settings
    trackpad_settings
    window_manager_settings
    restart_services
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
