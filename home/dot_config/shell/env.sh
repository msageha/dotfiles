# shellcheck shell=bash
# bash (~/.bash_profile) と zsh (~/.zprofile) が共有する環境変数と PATH。両シェルで解釈できる構文のみ使う。
# ツールのシェル統合 (prompt / hook / completion) はこの後に source する integrations.sh にある

if [ -n "${ZSH_VERSION:-}" ]; then
    _dotfiles_shell=zsh
else
    _dotfiles_shell=bash
fi

# Agent は AI coding agent が付ける marker 環境変数で判定する (GROK_AGENT は grok の agent 定義の選択にも
# 使われるため、agent の terminal に付く値 1 だけを見る)。human は Agent でない対話 shell で stdin / stdout が TTY のとき。
# どちらでもない非対話 shell (GUI アプリがログイン shell から環境を取り込む処理など) の環境は人間の shell に
# 継承されるため、Agent 用の値を足さない。DOTFILES_SHELL_MODE=human|agent は marker の継承が実態とずれるときの上書き
case "${DOTFILES_SHELL_MODE:-}" in
    agent) _dotfiles_agent_shell=true ;;
    human) _dotfiles_agent_shell=false ;;
    *)
        _dotfiles_agent_shell=false
        if [ -n "${AI_AGENT:-}${CLAUDECODE:-}${CODEX_CI:-}${CODEX_SANDBOX:-}${GEMINI_CLI:-}${CURSOR_AGENT:-}${ANTIGRAVITY_AGENT:-}" ] || [ "${GROK_AGENT:-}" = 1 ]; then
            _dotfiles_agent_shell=true
        fi
        ;;
esac
_dotfiles_human_shell=false
case "$-" in
    *i*)
        if ! $_dotfiles_agent_shell && [ -t 0 ] && [ -t 1 ]; then
            _dotfiles_human_shell=true
        fi
        ;;
esac

# editor / pager / prompt を止める Agent 用の値 (.chezmoidata.toml の agent_env から生成)
source "$HOME/.config/shell/agent-env.sh"

if $_dotfiles_human_shell && [ -f "$HOME/.alias" ]; then
    source "$HOME/.alias"
fi

export NODE_REPL_HISTORY="$HOME/.local/state/node_repl_history"
export SQL_HISTORY="$HOME/.local/state/sql_history"
export MYSQL_HISTFILE="$HOME/.local/state/mysql_history"
export PSQL_HISTFILE="$HOME/.local/state/psql_history"
export PYTHON_HISTORY="$HOME/.local/state/python_history"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# Dracula テーマの配色 (https://github.com/dracula/ の fzf / eza / grep / man-pages)
if $_dotfiles_human_shell; then
    export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
    export EZA_COLORS="uu=36:uR=31:un=35:gu=37:da=2;34:ur=34:uw=95:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:xx=95:"
    export GREP_COLORS="mt=1;38;2;255;85;85:fn=38;2;255;121;198:ln=38;2;80;250;123:bn=38;2;80;250;123:se=38;2;139;233;253"
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS の BSD grep は GREP_COLORS を解さないため単数形の GREP_COLOR も設定する
        export GREP_COLOR="1;38;2;255;85;85"
    fi
    export MANPAGER="less -s -M +Gg"
    export LESS_TERMCAP_mb=$'\e[1;31m'      # 点滅の開始
    export LESS_TERMCAP_md=$'\e[1;34m'      # 太字の開始
    export LESS_TERMCAP_so=$'\e[01;45;37m'  # 反転表示の開始
    export LESS_TERMCAP_us=$'\e[01;36m'     # 下線の開始
    export LESS_TERMCAP_me=$'\e[0m'         # 太字・点滅の終了
    export LESS_TERMCAP_se=$'\e[0m'         # 反転表示の終了
    export LESS_TERMCAP_ue=$'\e[0m'         # 下線の終了
    export GROFF_NO_SGR=1                   # groff の SGR 出力を止め、LESS_TERMCAP_* の配色を効かせる
fi

# brew / mise / direnv / starship などの activate は PATH が揃っている前提のため、
# それらより前に静的なバイナリ置き場 (uv で入れたツールや mise 本体は ~/.local/bin) を PATH へ追加する
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

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

# crontab 等の CLI は VISUAL を EDITOR より優先して参照するため両方を揃える。
# VSCode は --wait が無いと即座に制御を返し、呼び出し元が編集完了と誤認する。
# code の検出は brew shellenv で PATH が揃った後に行う必要がある
if $_dotfiles_human_shell; then
    if command -v code &>/dev/null; then
        export EDITOR="code --wait"
    else
        export EDITOR="vim"
    fi
    export VISUAL="$EDITOR"

    # LS_COLORS の Dracula テーマ (https://github.com/dracula/dircolors。.chezmoiexternal.toml で取得)。
    # GNU dircolors があるときのみ有効 (Linux / brew coreutils)。macOS 標準環境には無い
    _dircolors_bin="$(command -v dircolors || command -v gdircolors || true)"
    if [ -n "$_dircolors_bin" ] && [ -f "$HOME/.config/dircolors/dracula/.dircolors" ]; then
        eval "$("$_dircolors_bin" -b "$HOME/.config/dircolors/dracula/.dircolors")"
    fi
    unset _dircolors_bin

    # LS_COLORS / GREP_COLORS は --color=auto を付けたときだけ効く。login shell は ~/.bashrc を読まないため alias もここで定義する
    # (--color 非対応の古い BSD ls もあるため、動くことを確かめてから)。
    # macOS の ls は COLORTERM か CLICOLOR が無いと色を出さないため CLICOLOR を設定する (GNU ls は無視する)
    export CLICOLOR=1
    if ls --color=auto -d . &>/dev/null; then
        alias ls='ls --color=auto'
    fi
    if echo x | grep --color=auto -q x &>/dev/null; then
        alias grep='grep --color=auto'
    fi
fi

export GOPATH="$HOME/Works"
# go install のバイナリは ~/.local/bin (PATH 設定済み) に置く。mise activate 環境では
# mise が GOBIN を自身の管理ディレクトリへ上書きするため、これは mise 不在時のフォールバック
export GOBIN="$HOME/.local/bin"
# Takumi Guard (悪性パッケージを遮断する proxy)。`,direct` を付けると未収載・ブロック済みの module で proxy を迂回できてしまうため URL だけを指定する。
# 認証 token は ~/.netrc (modify_private_dot_netrc)
export GOPROXY="https://golang.flatt.tech"

if [ -f /opt/homebrew/opt/openjdk/bin/java ]; then
    export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
    export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
fi

# DEVELOPER_DIR は xcrun / ビルドツールが参照する。Homebrew の git / python3 を優先しつつ
# simctl 等の Xcode 専用ツールも引けるように usr/bin は末尾に追加する
if xcode-select -p &>/dev/null; then
    DEVELOPER_DIR="$(xcode-select -p)"
    export DEVELOPER_DIR
    export PATH="$PATH:$DEVELOPER_DIR/usr/bin"
fi

CLOUDSDK_PYTHON="$(command -v python3)"
export CLOUDSDK_PYTHON

if [ -e /.dockerenv ] && [ -z "$DOCKER_MACHINE_NAME" ]; then
    export DOCKER_MACHINE_NAME="docker"
fi

if [ -d "/opt/homebrew/opt/mysql-client/bin/" ]; then
    export MYSQL_CLIENT_PATH="/opt/homebrew/opt/mysql-client"
    export PATH="$MYSQL_CLIENT_PATH/bin:$PATH"
fi

# Homebrew のライブラリに依存するネイティブ拡張 (mysqlclient 等) のビルド用
if [[ "$(uname)" == "Darwin" ]]; then
    [[ "$PKG_CONFIG_PATH" != */opt/homebrew/lib/pkgconfig* ]] && export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
    [[ "$LDFLAGS" != *-L/opt/homebrew/lib* ]] && export LDFLAGS="-L/opt/homebrew/lib $LDFLAGS"
    [[ "$CPPFLAGS" != *-I/opt/homebrew/include* ]] && export CPPFLAGS="-I/opt/homebrew/include $CPPFLAGS"
fi
