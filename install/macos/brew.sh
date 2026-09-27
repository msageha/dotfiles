#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# SKIP_CLI_TOOLS=true でも導入する最小セット。後続の chezmoi スクリプトが前提とする
# (dockutil: system_settings.sh の dock_apps、fish: setup_shell.sh / fisher.fish、mise: install/common/mise.sh)
formulae_base=(
    dockutil
    fish
    mise
)

# SKIP_CLI_TOOLS=true でまとめてスキップする CLI ツール群
formulae=(
    exiv2
    git
    git-secrets
    gnupg
    googleworkspace-cli
    graphviz
    htop
    httpie
    imagemagick
    mole
    mysql-client
    poppler
    pv
    satococoa/tap/wtp
    tree
    wget
)

# 配布形態が cask なだけで実体は CLI ツールのため SKIP_CLI_TOOLS で制御する
casks_coding_agents=(
    antigravity-cli
    claude-code@latest
    codex
)

# GUI アプリ。SKIP_GUI_TOOLS=true でスキップする
casks=(
    1password
    1password-cli
    android-studio
    bettertouchtool
    chatgpt
    claude
    cyberduck
    datagrip
    discord
    drawio
    elgato-stream-deck
    figma
    ghostty
    goland
    google-chrome
    google-japanese-ime
    grok-build
    insomnia
    keka
    mole-app
    ngrok
    obsidian
    openvpn-connect
    orbstack
    pycharm
    raycast
    visual-studio-code
    wakatime
    webstorm
    xcodes-app
)

# brew upgrade から除外するパッケージ。
# antigravity-cli は agy 自身が /opt/homebrew/bin/agy を上書きする自己更新型 CLI で、
# brew upgrade と衝突する (Error: It seems there is already a Binary at '/opt/homebrew/bin/agy')。
# 更新は agy の自己更新に委ね、install だけ brew で行う
upgrade_exclude=(
    antigravity-cli
)

function install_brew() {
    if command -v brew &>/dev/null; then
        log_step "Homebrew is already installed."
        return 0
    fi
    log_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

function doctor() {
    log_step "Running brew doctor..."
    brew doctor || true
}

function update() {
    log_step "Running brew update..."
    brew update
}

function install_packages() {
    log_step "Installing base formula packages..."
    brew install "${formulae_base[@]}"

    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        log_step "Skipping formula tools (SKIP_CLI_TOOLS=true)."
    else
        log_step "Installing formula packages..."
        brew install "${formulae[@]}"
    fi

    # cask (GUI アプリ・自己更新型 CLI) の導入は時間がかかり GUI を伴うため CI ではスキップする
    if [ -n "${CI:-}" ]; then
        log_step "CI 環境のため cask のインストールをスキップします。"
        return 0
    fi

    if [ "$SKIP_CLI_TOOLS" = "true" ]; then
        log_step "Skipping coding agent casks (SKIP_CLI_TOOLS=true)."
    else
        log_step "Installing coding agent casks..."
        brew install --cask "${casks_coding_agents[@]}"
    fi

    if [ "$SKIP_GUI_TOOLS" = "true" ]; then
        log_step "Skipping cask packages (SKIP_GUI_TOOLS=true)."
        return 0
    fi
    log_step "Installing cask packages..."
    brew install --cask "${casks[@]}"
}

function upgrade() {
    # cask を含む全更新は時間がかかるため CI ではスキップする
    if [ -n "${CI:-}" ]; then
        log_step "CI 環境のため brew upgrade をスキップします。"
        return 0
    fi
    log_step "Upgrading packages..."

    local exclude_pattern outdated
    exclude_pattern="$(printf '%s\n' "${upgrade_exclude[@]}")"
    outdated="$(brew outdated --quiet | grep -vxF "$exclude_pattern" || true)"
    if [ -z "$outdated" ]; then
        log_step "更新対象のパッケージはありません。"
        return 0
    fi
    # outdated は改行区切りの名前リスト。意図的に word splitting して個別に渡す
    # shellcheck disable=SC2086
    brew upgrade $outdated
}

function cleanup() {
    log_step "Cleaning up..."
    brew cleanup --prune=all
}

function main() {
    # SKIP_CLI_TOOLS / SKIP_GUI_TOOLS は run_once_before テンプレートが必ず export する契約。未設定は設定ミスとして落とす
    if [ -z "${SKIP_CLI_TOOLS+x}" ] || [ -z "${SKIP_GUI_TOOLS+x}" ]; then
        log_error "SKIP_CLI_TOOLS / SKIP_GUI_TOOLS are not set; they must be exported by the caller."
        exit 1
    fi

    install_brew
    doctor
    update
    install_packages
    upgrade
    cleanup
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
