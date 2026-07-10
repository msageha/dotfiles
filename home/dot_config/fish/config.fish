# --- エイリアスの読み込み ---
if test -f $HOME/.alias
    source $HOME/.alias
end

# --- ヒストリーファイルの設定 ---
set -x NODE_REPL_HISTORY $HOME/.local/state/node_repl_history
set -x SQL_HISTORY $HOME/.local/state/sql_history
set -x MYSQL_HISTFILE $HOME/.local/state/mysql_history
set -x PSQL_HISTFILE $HOME/.local/state/psql_history
set -x PYTHON_HISTORY $HOME/.local/state/python_history

# --- functionの読み込み ---
for file in $HOME/.config/fish/functions/*.fish
    source $file
end

# --- fzf Dracula Theme ---
set -gx FZF_DEFAULT_OPTS "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

# --- カスタム関数のエイリアス ---
alias fgc=fzf_gcloud_config
alias fga=fzf_gcloud_auth
alias gssh=fzf_gcloud_ssh
alias fssh=fzf_ssh

# --- ローカルバイナリのパス追加 ---
# (uvでインストールしたツールや mise 本体用)
if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

# --- Homebrewの設定 ---
set -l brew_bin (command -v brew 2>/dev/null)
if test -z "$brew_bin"; and test -x /opt/homebrew/bin/brew
    set brew_bin /opt/homebrew/bin/brew
else if test -z "$brew_bin"; and test -x /usr/local/bin/brew
    set brew_bin /usr/local/bin/brew
end
if test -n "$brew_bin"
    "$brew_bin" shellenv fish | source
end

# --- Goの設定 ---
set -x GOPATH "$HOME/Works"
if test -d $HOME/Works/bin
    fish_add_path $HOME/Works/bin
end

# --- flutterのパス追加 ---
if type -q mise; and mise where flutter &>/dev/null
    set -x FLUTTER_ROOT (mise where flutter)
end
if test -d $HOME/.pub-cache/bin
    fish_add_path $HOME/.pub-cache/bin
end

# --- JDKの設定 ---
if test -f /opt/homebrew/opt/openjdk/bin/java
    fish_add_path /opt/homebrew/opt/openjdk/bin
    set -gx CPPFLAGS "-I/opt/homebrew/opt/openjdk/include" # Cプリプロセッサ用フラグ
end

# --- Google Cloud SDKのPython設定 ---
set -gx CLOUDSDK_PYTHON (type -p python3)

# --- Docker環境設定 --- (Docker内で動作している場合に設定)
if test -e /.dockerenv && test -z "$DOCKER_MACHINE_NAME"
    set -x DOCKER_MACHINE_NAME "docker"
end

# --- MySQLクライアントのパス追加 ---
if test -d /opt/homebrew/opt/mysql-client/bin/
    set -x MYSQL_CLIENT_PATH /opt/homebrew/opt/mysql-client
    fish_add_path $MYSQL_CLIENT_PATH/bin
end

# --- mysqlclient用のコンパイラフラグ設定 ---
if test (uname) = "Darwin"
    contains -- /opt/homebrew/lib/pkgconfig $PKG_CONFIG_PATH
    or set -gx PKG_CONFIG_PATH /opt/homebrew/lib/pkgconfig $PKG_CONFIG_PATH
    string match -q "*-L/opt/homebrew/lib*" -- "$LDFLAGS"
    or set -x LDFLAGS "-L/opt/homebrew/lib $LDFLAGS"
    string match -q "*-I/opt/homebrew/include*" -- "$CPPFLAGS"
    or set -x CPPFLAGS "-I/opt/homebrew/include $CPPFLAGS"
end

# --- orbstackの設定 ---
if test -d $HOME/.orbstack/shell
    source $HOME/.orbstack/shell/init2.fish
end

# --- Starshipの設定 ---
if type -q starship
    starship init fish | source
end

# --- Xcodeの設定 ---
# usr/bin は末尾に追加して Homebrew の git/python3 を優先しつつ simctl 等も引けるようにする
if type -q xcode-select; and xcode-select -p >/dev/null 2>&1
    set -gx DEVELOPER_DIR (xcode-select -p)
    fish_add_path -a $DEVELOPER_DIR/usr/bin
end

# --- direnvのフック設定 ---
set -l direnv_bin (command -v direnv 2>/dev/null)
if test -z "$direnv_bin"; and type -q mise
    set direnv_bin (mise which direnv 2>/dev/null)
end
if test -n "$direnv_bin"
    "$direnv_bin" hook fish | source
end

# --- miseの初期化 ---
if type -q mise
    mise activate fish | source
end

# --- AWS CLI / aws-sso-cliの補完初期化 ---
# aws-sso の補完は aws-sso-profile 等のヘルパー関数も含むため、fish の
# completions/*.fish 自動ロード (コマンド名一致が必須) には乗せず直接 source する。
if type -q aws_completer
    complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | string trim --right; end)'
end
if type -q aws-sso
    aws-sso setup completions --source --shell fish | source
end

# --- fnoxの初期化 ---
if status is-interactive; and type -q fnox
    fnox activate fish | string replace --regex '^__fnox_env_eval$' '' | source

    function __fnox_find_1password_config
        set -l dir $PWD
        while test "$dir" != /
            set -l fnox_profile default
            if set -q FNOX_PROFILE
                set fnox_profile $FNOX_PROFILE
            end
            for fnox_config in $dir/fnox.toml $dir/fnox.local.toml $dir/fnox.$fnox_profile.toml
                if test -f "$fnox_config"; and grep -Eq 'type[[:space:]]*=[[:space:]]*["'\'']1password["'\'']' "$fnox_config"
                    printf '%s\n' "$fnox_config"
                    return 0
                end
            end
            set dir (dirname "$dir")
        end
        return 1
    end

    function __fnox_preauth_1password
        type -q op; or return 0

        set -l config_path (__fnox_find_1password_config)
        or return 0

        op whoami >/dev/null 2>&1; and return 0
        if set -q __FNOX_1PASSWORD_PREAUTH_FAILED_FOR; and test "$__FNOX_1PASSWORD_PREAUTH_FAILED_FOR" = "$config_path"
            return 1
        end

        if op signin >/dev/null 2>&1
            set -e __FNOX_1PASSWORD_PREAUTH_FAILED_FOR
            return 0
        end
        set -gx __FNOX_1PASSWORD_PREAUTH_FAILED_FOR "$config_path"
        return 1
    end

    functions -e __fnox_env_eval
    functions -e __fnox_cd_hook

    function __fnox_env_eval --on-event fish_prompt
        if test "$FNOX_SHELL" = fish
            if __fnox_preauth_1password
                eval (command fnox hook-env -s fish | string collect)
            else
                eval (FNOX_PROMPT_AUTH=false command fnox hook-env -s fish | string collect)
            end
        end
    end

    function __fnox_cd_hook --on-variable PWD
        if test "$FNOX_SHELL" = fish
            __fnox_env_eval
        end
    end

    __fnox_env_eval
end

# --- カーソルスタイルの設定 ---
# Ghosttyの cursor-style = block に合わせて、常にblockカーソルを使用
set -g fish_cursor_default block
set -g fish_cursor_insert block
set -g fish_cursor_replace_one underscore
set -g fish_cursor_visual block

# --- GitHub トークンの動的注入 ---
# GitHub MCP server (Claude Code の github plugin) が参照する。gh の OAuth トークンを
# 都度取得することで PAT をファイルに置かない。gh 未導入・未ログイン時は設定しない。
# トークンは回転しうるためキャッシュに書かず、毎回評価する。
if not set -q GITHUB_PERSONAL_ACCESS_TOKEN; and type -q gh
    set -l gh_token (gh auth token 2>/dev/null)
    if test -n "$gh_token"
        set -gx GITHUB_PERSONAL_ACCESS_TOKEN $gh_token
    end
end

# --- fzfのシェル統合設定 (CTRL-R/CTRL-T/ALT-C キーバインド + 補完) ---
if type -q fzf
    fzf --fish | source
end

# --- zoxideの初期化 (z / zi コマンド) ---
if type -q zoxide
    zoxide init fish | source
end
