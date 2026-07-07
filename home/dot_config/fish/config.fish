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
alias fenv=fzf_load_env

# --- miseの初期化 ---
if type -q mise
    mise activate fish | source
end

# --- flutterのパス追加 ---
if type -q mise; and mise where flutter &>/dev/null
    set -x FLUTTER_ROOT (mise where flutter)
end
if test -d $HOME/.pub-cache/bin
    fish_add_path $HOME/.pub-cache/bin
end

# --- ローカルバイナリのパス追加 ---
# (uvでインストールしたツール用)
if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

# --- Goの設定 ---
set -x GOPATH "$HOME/Works"
if test -d $HOME/Works/bin
    fish_add_path $HOME/Works/bin
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

# # --- MySQLクライアントのパス追加 ---
# if test -d /opt/homebrew/opt/mysql-client/bin/
#     set -x MYSQL_CLIENT_PATH /opt/homebrew/opt/mysql-client
#     fish_add_path $MYSQL_CLIENT_PATH/bin
# end

# # --- mysqlclient用のコンパイラフラグ設定 ---
# if test (uname) = "Darwin"
#     string match -q "*/opt/homebrew/lib/pkgconfig*" -- "$PKG_CONFIG_PATH"
#     or set -x PKG_CONFIG_PATH "/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
#     string match -q "*-L/opt/homebrew/lib*" -- "$LDFLAGS"
#     or set -x LDFLAGS "-L/opt/homebrew/lib $LDFLAGS"
#     string match -q "*-I/opt/homebrew/include*" -- "$CPPFLAGS"
#     or set -x CPPFLAGS "-I/opt/homebrew/include $CPPFLAGS"
# end

# --- orbstackの設定 ---
if test -d $HOME/.orbstack/shell
    source $HOME/.orbstack/shell/init2.fish
end

# --- Starshipの設定 ---
if type -q starship
    starship init fish | source
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


# --- FISH_CONFIG_CACHEの設定 ---
set -l FISH_CONFIG_CACHE $HOME/.cache/fish/config.fish

# キャッシュファイルのチェックと更新
if test -f $FISH_CONFIG_CACHE
    set -l cache_mtime 0
    if test (uname) = "Darwin"
        set cache_mtime (stat -f %m $FISH_CONFIG_CACHE)
    else if test (uname) = "Linux"
        set cache_mtime (stat -c %Y $FISH_CONFIG_CACHE)
    end
    set -l current_time (date +%s)
    set -l one_week_ago (math $current_time - 604800) # 1週間(604800秒)

    if test $cache_mtime -ge $one_week_ago
        source $FISH_CONFIG_CACHE
        return
    end
end

# 親ディレクトリを作成し、ファイルを再作成
mkdir -p (dirname $FISH_CONFIG_CACHE)
rm -f $FISH_CONFIG_CACHE
touch $FISH_CONFIG_CACHE

# --- Homebrewの設定 ---
if type -q brew
    brew shellenv fish | source
end

# --- Xcodeの設定 ---
# usr/bin は末尾に追加 (-a) して Homebrew の git/python3 を優先する。
# xcode-select -p が成功する (developer dir が存在する) ときだけキャッシュに書く。
if type -q xcode-select; and xcode-select -p >/dev/null 2>&1
    echo "fish_add_path -a (xcode-select -p)/usr/bin" >> $FISH_CONFIG_CACHE
end

# --- direnvのフック設定 ---
if type -q direnv
    direnv hook fish >> $FISH_CONFIG_CACHE
end

# --- fzfのシェル統合設定 (CTRL-R/CTRL-T/ALT-C キーバインド + 補完) ---
if type -q fzf
    fzf --fish >> $FISH_CONFIG_CACHE
end

# --- zoxideの初期化 (z / zi コマンド) ---
if type -q zoxide
    zoxide init fish >> $FISH_CONFIG_CACHE
end

# キャッシュファイルを読み込み
source $FISH_CONFIG_CACHE
