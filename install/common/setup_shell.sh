#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

function validate_bash() {
    if ! command -v bash &>/dev/null; then
        printf "%b\n" "${RED}Bash shell could not be found, please install Bash first.${NC}"
        exit 1
    fi
}

function validate_zsh() {
    if ! command -v zsh &>/dev/null; then
        printf "%b\n" "${RED}Zsh shell could not be found, please install Zsh first.${NC}"
        exit 1
    fi
}

function validate_fish() {
    if ! command -v fish &>/dev/null; then
        printf "%b\n" "${RED}Fish shell could not be found, please install Fish first.${NC}"
        exit 1
    fi
}

function create_bashrc() {
    printf "%b\n" "${BLUE}Creating .bashrc and source .bash_profile...${NC}"
    touch "$HOME/.bashrc"
    if ! grep -Fxq "source \$HOME/.bash_profile" "$HOME/.bashrc"; then
        echo "source \$HOME/.bash_profile" >> "$HOME/.bashrc"
    fi
}

function create_zshrc() {
    printf "%b\n" "${BLUE}Creating .zshrc and source .zprofile...${NC}"
    touch "$HOME/.zshrc"
    local block_begin="# >>> dotfiles zsh init >>>"
    local block_end="# <<< dotfiles zsh init <<<"
    # 旧形式の無条件 source は login shell (zsh 自身も ~/.zprofile を読む) で
    # 初期化を二重実行させるため、見つけたら除去してブロック形式へ移行する
    if grep -Fxq "source \$HOME/.zprofile" "$HOME/.zshrc"; then
        # 全行が対象行のとき grep -v は exit 1 を返すが、空になるのは正常系
        grep -Fxv "source \$HOME/.zprofile" "$HOME/.zshrc" > "$HOME/.zshrc.tmp" || true
        mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
    fi
    if grep -Fxq "$block_begin" "$HOME/.zshrc" && ! grep -Fxq "$block_end" "$HOME/.zshrc"; then
        printf "%b\n" "${RED}~/.zshrc の管理ブロック終了マーカー (${block_end}) が見つかりません。巻き込み削除を避けるため更新をスキップします。手動で修復してください。${NC}" >&2
        return 0
    fi
    # 既存ブロックを除去してから書き直すことで、内容更新時も再実行で追従できる
    if grep -Fxq "$block_begin" "$HOME/.zshrc"; then
        awk -v begin="$block_begin" -v end="$block_end" \
            '$0 == begin {skip=1} !skip {print} $0 == end {skip=0}' \
            "$HOME/.zshrc" > "$HOME/.zshrc.tmp"
        mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
    fi
    # 機械ローカルな追記 (installer 由来のブロック等) より先に実行されるよう先頭へ挿入する
    {
        cat <<'EOF'
# >>> dotfiles zsh init >>>
# login shell では zsh 自身が ~/.zprofile を読むため、非 login の対話シェルのみ source する
# (無条件に source すると login shell で PATH 構築・compinit 等の初期化が二重実行される)
if [[ ! -o login ]]; then
    source "$HOME/.zprofile"
fi
# macOS の /etc/zshrc (~/.zprofile の後・~/.zshrc の前に読まれる) が HISTFILE を
# ~/.zsh_history へ上書きするため、zsh の履歴ファイルは ~/.zshrc 側で設定する
HISTFILE="$HOME/.local/state/zsh_history"
# <<< dotfiles zsh init <<<
EOF
        cat "$HOME/.zshrc"
    } > "$HOME/.zshrc.tmp"
    mv "$HOME/.zshrc.tmp" "$HOME/.zshrc"
}

function create_fish_config() {
    printf "%b\n" "${BLUE}Creating Fish config.fish...${NC}"
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
}

function main() {
    validate_bash
    validate_zsh
    validate_fish
    create_bashrc
    create_zshrc
    create_fish_config
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
