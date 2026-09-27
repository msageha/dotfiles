#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# macOS の既定 sudoers は %admin なので admin 所属で判定し、NOPASSWD 等の個別付与は sudo -n で拾う。
# lib.sh の has_privilege (sudo -v) を使わないのは、非 sudoer にも TTY パスワードプロンプトを出してしまうため
function has_admin_privilege() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    id -Gn | grep -qw admin || sudo -n true 2>/dev/null
}

function computer_name() {
    log_step "Setting computer name..."

    # config に computer_name が無い場合は空で渡ってくる。空名を scutil に設定しない
    if [ -z "${COMPUTER_NAME:-}" ]; then
        log_step "COMPUTER_NAME が未設定のためスキップ"
        return 0
    fi

    local current
    current="$(scutil --get ComputerName 2>/dev/null || true)"
    if [[ "$current" == "$COMPUTER_NAME" ]]; then
        log_step "コンピュータ名は既に '$COMPUTER_NAME' です。スキップ"
        return 0
    fi

    if ! has_admin_privilege; then
        log_warn "sudo が使えないためコンピュータ名の設定をスキップします。"
        return 0
    fi

    log_step "コンピュータ名を設定しています... ($COMPUTER_NAME)"
    sudo scutil --set ComputerName "$COMPUTER_NAME"
    sudo scutil --set HostName "$COMPUTER_NAME"
    sudo scutil --set LocalHostName "$COMPUTER_NAME" # Bonjour 名
    sudo dscacheutil -flushcache
}

function user_icon() {
    local icon="$CHEZMOI_REPO_ROOT/settings/common/icon.png"

    # Picture が同じパスで、JPEGPhoto (System Settings による上書き) が無ければスキップ。
    # dscl -read は属性が無くても exit 0 で "No such key" を返すため、出力で存在判定する
    local current
    current="$(dscl . -read "/Users/$USER" Picture 2>/dev/null | sed -n 's/^Picture: //p')"
    if [[ "$current" == "$icon" ]] && ! dscl . -read "/Users/$USER" JPEGPhoto 2>/dev/null | grep -q '^JPEGPhoto:'; then
        log_step "ユーザーアイコンは既に '$icon' です。スキップ"
        return 0
    fi

    if ! has_admin_privilege; then
        log_warn "sudo が使えないためユーザーアイコンの設定をスキップします。"
        return 0
    fi

    log_step "ユーザーアイコンを設定しています..."
    sudo sh -c 'dscl . -delete "/Users/$1" JPEGPhoto 2>/dev/null; dscl . -create "/Users/$1" Picture "$2"' _ "$USER" "$icon"
}

function system_settings() {
    log_step "システムの基本設定を行っています..."
    defaults write NSGlobalDomain AppleLanguages -array "ja-JP"
    defaults write NSGlobalDomain AppleLocale -string "ja_JP"
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true  # 保存ダイアログを常に展開
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true  # 印刷ダイアログを常に展開
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false  # iCloud への自動保存を無効化
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.1  # ウィンドウリサイズアニメーション高速化
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true  # 印刷完了後にプリンタアプリを自動終了
}

function dock_settings() {
    log_step "Dock の設定を行っています..."
    defaults write com.apple.dock orientation -string "right"
    defaults write com.apple.dock tilesize -int 50
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock magnification -bool false
    defaults write com.apple.dock mru-spaces -bool false  # Spaces の自動並べ替えを無効化
    defaults write com.apple.dock expose-group-apps -bool true  # Mission Control でアプリごとにウィンドウをグループ化
    defaults write com.apple.dock autohide-delay -float 0
    defaults write com.apple.dock autohide-time-modifier -float 0.5
}

function dock_apps() {
    log_step "Dock にアプリを追加しています..."
    if ! command -v dockutil &>/dev/null; then
        log_error "dockutil が見つかりません。brew install dockutil を実行してください。"
        return 1
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
            log_step "  '$app' が見つかりません。スキップ"
        fi
    done
    dockutil --add "$HOME/Downloads" --view grid --display folder --sort dateadded --no-restart
}

function menu_bar_settings() {
    log_step "メニューバーの設定を行っています..."
    defaults write com.apple.controlcenter.plist Bluetooth -int 18  # 18 = メニューバーに表示
    defaults write com.apple.controlcenter.plist BatteryShowPercentage -bool true
    defaults write com.apple.controlcenter.plist Sound -int 18
}

function finder_settings() {
    log_step "Finder の設定を行っています..."
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # リスト表示
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"  # 検索時にカレントフォルダを対象
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # ネットワーク上に .DS_Store を作成しない
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true  # USB 上に .DS_Store を作成しない
}

function hot_corners_settings() {
    log_step "ホットコーナーの設定を行っています..."
    defaults write com.apple.dock wvous-tr-corner -int 5  # 右上: スクリーンセーバー開始
    defaults write com.apple.dock wvous-br-corner -int 13  # 右下: ロック画面
    defaults write com.apple.dock wvous-tl-corner -int 5  # 左上: スクリーンセーバー開始
    defaults write com.apple.dock wvous-bl-corner -int 13  # 左下: ロック画面
}

function screensaver_settings() {
    log_step "スクリーンセーバーの設定を行っています..."
    defaults -currentHost write com.apple.screensaver idleTime -int 300
}

function wallpaper_settings() {
    log_step "壁紙の設定を行っています..."
    mkdir -p "$HOME/Pictures"
    # 取得失敗時に壊れた本文を壁紙にしないよう -f で HTTP エラーを検知し、失敗時はスキップする
    if ! curl -fsSL "https://raw.githubusercontent.com/dracula/wallpaper/f2b8cc4223bcc2dfd5f165ab80f701bbb84e3303/first-collection/macos.png" --output "$HOME/Pictures/wallpaper.png"; then
        log_warn "壁紙のダウンロードに失敗しました。スキップします。"
        return 0
    fi
    # macOS Sonoma (14) 以降では Finder の AppleScript が壁紙設定に対応しなくなったため System Events を使う
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$HOME/Pictures/wallpaper.png\"" || \
        log_warn "壁紙の設定に失敗しました (オートメーション許可が必要な場合があります)。"
}

function screenshot_settings() {
    log_step "スクリーンショットの設定を行っています..."
    mkdir -p "$HOME/Pictures/Screenshots"
    defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
    defaults write com.apple.screencapture show-thumbnail -bool false
    defaults write com.apple.screencapture style -string "window"
}

function keyboard_settings() {
    log_step "キーボード設定を行っています..."
    defaults write -g InitialKeyRepeat -int 15
    defaults write -g KeyRepeat -int 2
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false  # 長押しで特殊文字パネルを出さない (キーリピート優先)
}

function trackpad_settings() {
    log_step "トラックパッドの設定を行っています..."
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
    defaults write com.apple.AppleMultitouchTrackpad TrackpadPinch -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRotate -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture -int 1  # スマートズーム
    defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3  # 右端スワイプで通知センター
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2  # 4 本指横スワイプでデスクトップ切替
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2  # 4 本指縦スワイプで Mission Control
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFiveFingerPinchGesture -int 2  # 5 本指ピンチで Launchpad
    defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerPinchGesture -int 2  # 4 本指ピンチで Launchpad
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2  # 3 本指横スワイプでページ切替
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0  # 3 本指縦スワイプ無効 (BTT の新規タブ / タブを閉じるジェスチャを優先)
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0  # 3 本指タップ無効 (BTT のミドルクリックを優先)
    defaults write com.apple.dock showAppExposeGestureEnabled -bool true  # 4 本指下スワイプで App Exposé
    defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true
}

function window_manager_settings() {
    log_step "ウィンドウ管理の設定を行っています..."
    defaults write com.apple.WindowManager GloballyEnabled -bool false  # Stage Manager を無効化
    defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
    defaults write com.apple.WindowManager HideDesktop -bool true  # デスクトップクリックでウィンドウを隠す
    defaults write com.apple.WindowManager StageManagerHideWidgets -bool false
    defaults write com.apple.WindowManager StandardHideWidgets -bool false
}

function restart_services() {
    log_step "Finder、SystemUIServer、Dock を再起動しています..."
    killall Finder || true
    killall SystemUIServer || true
    killall Dock || true
}

function main() {
    computer_name
    user_icon
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
