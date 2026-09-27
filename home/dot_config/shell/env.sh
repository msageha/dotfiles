# shellcheck shell=bash
# bash (~/.bash_profile) と zsh (~/.zprofile) が共有する環境変数と PATH。両シェルで解釈できる構文のみ使う。
# ツールのシェル統合 (prompt / hook / completion) はこの後に source する integrations.sh にある

# --- エイリアス (bash / zsh / fish 共有) ---
if [ -f "$HOME/.alias" ]; then
    source "$HOME/.alias"
fi

# --- REPL 履歴の保存先 ---
export NODE_REPL_HISTORY="$HOME/.local/state/node_repl_history"
export SQL_HISTORY="$HOME/.local/state/sql_history"
export MYSQL_HISTFILE="$HOME/.local/state/mysql_history"
export PSQL_HISTFILE="$HOME/.local/state/psql_history"
export PYTHON_HISTORY="$HOME/.local/state/python_history"

# --- Dracula テーマ (fzf / eza / ripgrep / grep / man) ---
# (https://github.com/dracula/fzf, dracula/eza, dracula/ripgrep, dracula/grep, dracula/man-pages)
export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
export EZA_COLORS="uu=36:uR=31:un=35:gu=37:da=2;34:ur=34:uw=95:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:xx=95:"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"
export GREP_COLORS="mt=1;38;2;255;85;85:fn=38;2;255;121;198:ln=38;2;80;250;123:bn=38;2;80;250;123:se=38;2;139;233;253"
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS の BSD grep は GREP_COLORS を解さないため単数形の GREP_COLOR も設定する
    export GREP_COLOR="1;38;2;255;85;85"
fi
export MANPAGER="less -s -M +Gg"
export LESS_TERMCAP_mb=$'\e[1;31m'      # begin bold
export LESS_TERMCAP_md=$'\e[1;34m'      # begin blink
export LESS_TERMCAP_so=$'\e[01;45;37m'  # begin reverse video
export LESS_TERMCAP_us=$'\e[01;36m'     # begin underline
export LESS_TERMCAP_me=$'\e[0m'         # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'         # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m'         # reset underline
export GROFF_NO_SGR=1                   # for konsole

# --- PATH: ツール置き場を先に通す ---
# brew / mise / direnv / starship などの activate は PATH が揃っている前提のため、
# それらより前に静的なバイナリ置き場 (uv で入れたツールや mise 本体は ~/.local/bin) を PATH へ追加する
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# --- Homebrew ---
_brew_bin="$(command -v brew || true)"
if [ -z "$_brew_bin" ] && [ -x /opt/homebrew/bin/brew ]; then
    _brew_bin="/opt/homebrew/bin/brew"
elif [ -z "$_brew_bin" ] && [ -x /usr/local/bin/brew ]; then
    _brew_bin="/usr/local/bin/brew"
fi
if [ -n "$_brew_bin" ]; then
    eval "$("$_brew_bin" shellenv)"
fi
unset _brew_bin

# --- デフォルトエディタ ---
# crontab 等の CLI は VISUAL を EDITOR より優先して参照するため両方を揃える。
# git のコミットエディタはここではなく gitconfig の core.editor = vim が最優先される。
# VSCode は --wait が無いと即座に制御を返し、呼び出し元が編集完了と誤認する。
# code の検出は brew shellenv で PATH が揃った後に行う必要がある
if command -v code &>/dev/null; then
    export EDITOR="code --wait"
else
    export EDITOR="vim"
fi
export VISUAL="$EDITOR"

# --- dircolors (LS_COLORS) の Dracula テーマ (https://github.com/dracula/dircolors。.chezmoiexternal.toml で取得) ---
# GNU dircolors があるときのみ有効 (Linux / brew coreutils)。macOS 標準環境には無い
_dircolors_bin="$(command -v dircolors || command -v gdircolors || true)"
if [ -n "$_dircolors_bin" ] && [ -f "$HOME/.config/dircolors/dracula/.dircolors" ]; then
    eval "$("$_dircolors_bin" -b "$HOME/.config/dircolors/dracula/.dircolors")"
fi
unset _dircolors_bin

# --- ls / grep のカラー出力 ---
# LS_COLORS / GREP_COLORS は --color=auto を付けて実行しない限り効かず、login shell は
# ~/.bashrc (ディストリ既定の alias 定義元) を読まないためここで張る。
# 古い BSD ls (macOS 12 以前など) は --color 非対応のため、動作確認してから張る。
# Apple 製 ls (FreeBSD 由来) は LS_COLORS でなく LSCOLORS を見るため dracula 配色にはならず、
# さらに COLORTERM / CLICOLOR が無いと --color=auto でも色を出さない (man ls) ため CLICOLOR を設定する
# (GNU ls は CLICOLOR を無視するため他 OS でも無害)
export CLICOLOR=1
if ls --color=auto -d . &>/dev/null; then
    alias ls='ls --color=auto'
fi
if echo x | grep --color=auto -q x &>/dev/null; then
    alias grep='grep --color=auto'
fi

# --- Go ---
export GOPATH="$HOME/Works"
# go install のバイナリは ~/.local/bin (PATH 設定済み) に置く。mise activate 環境では
# mise が GOBIN を自身の管理ディレクトリへ上書きするため、これは mise 不在時のフォールバック
export GOBIN="$HOME/.local/bin"

# --- JDK (Homebrew openjdk) ---
if [ -f /opt/homebrew/opt/openjdk/bin/java ]; then
    export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
    export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
fi

# --- Google Cloud SDK ---
CLOUDSDK_PYTHON="$(command -v python3)"
export CLOUDSDK_PYTHON

# --- Docker コンテナ内の識別 ---
if [ -e /.dockerenv ] && [ -z "$DOCKER_MACHINE_NAME" ]; then
    export DOCKER_MACHINE_NAME="docker"
fi

# --- MySQL クライアント (Homebrew mysql-client) ---
if [ -d "/opt/homebrew/opt/mysql-client/bin/" ]; then
    export MYSQL_CLIENT_PATH="/opt/homebrew/opt/mysql-client"
    export PATH="$MYSQL_CLIENT_PATH/bin:$PATH"
fi

# --- mysqlclient 等のビルド用コンパイラフラグ (macOS) ---
if [[ "$(uname)" == "Darwin" ]]; then
    [[ "$PKG_CONFIG_PATH" != */opt/homebrew/lib/pkgconfig* ]] && export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
    [[ "$LDFLAGS" != *-L/opt/homebrew/lib* ]] && export LDFLAGS="-L/opt/homebrew/lib $LDFLAGS"
    [[ "$CPPFLAGS" != *-I/opt/homebrew/include* ]] && export CPPFLAGS="-I/opt/homebrew/include $CPPFLAGS"
fi
