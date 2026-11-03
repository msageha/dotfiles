# Agent / human の判定は ~/.config/shell/env.sh と同じ (理由はそちらのコメント)
set -l agent_shell false
switch "$DOTFILES_SHELL_MODE"
    case agent
        set agent_shell true
    case human
    case '*'
        if test -n "$AI_AGENT$CLAUDECODE$CODEX_CI$CODEX_SANDBOX$GEMINI_CLI$CURSOR_AGENT$ANTIGRAVITY_AGENT"; or test "$GROK_AGENT" = 1
            set agent_shell true
        end
end
set -l human_shell false
if test "$agent_shell" = false; and status is-interactive; and isatty stdin; and isatty stdout
    set human_shell true
end

# editor / pager / prompt を止める Agent 用の値 (.chezmoidata.toml の agent_env から生成)
source $HOME/.config/fish/agent-env.fish

set -gx NODE_REPL_HISTORY $HOME/.local/state/node_repl_history
set -gx SQL_HISTORY $HOME/.local/state/sql_history
set -gx MYSQL_HISTFILE $HOME/.local/state/mysql_history
set -gx PSQL_HISTFILE $HOME/.local/state/psql_history
set -gx PYTHON_HISTORY $HOME/.local/state/python_history
set -gx RIPGREP_CONFIG_PATH $HOME/.config/ripgrep/config

if test "$human_shell" = true
    if test -f $HOME/.alias
        source $HOME/.alias
    end

    # fzf / eza / grep の配色は Dracula テーマ (https://github.com/dracula)
    set -gx FZF_DEFAULT_OPTS "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"

    set -gx EZA_COLORS "uu=36:uR=31:un=35:gu=37:da=2;34:ur=34:uw=95:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:xx=95:"
    set -gx GREP_COLORS "mt=1;38;2;255;85;85:fn=38;2;255;121;198:ln=38;2;80;250;123:bn=38;2;80;250;123:se=38;2;139;233;253"
    if test (uname) = "Darwin"
        # macOS の BSD grep は GREP_COLORS を解さないため単数形の GREP_COLOR も設定する
        set -gx GREP_COLOR "1;38;2;255;85;85"
    end
    # ls は fish 組み込みの ls 関数が色オプションを付けるので alias 不要。ただし macOS 13+ の ls は
    # COLORTERM か CLICOLOR が無いと色を出さず、fish の対処は Terminal.app 限定のため CLICOLOR を設定する
    # (GNU ls は CLICOLOR を無視する)
    set -gx CLICOLOR 1
    # GREP_COLORS / GREP_COLOR は --color=auto を付けたときだけ効く
    if echo x | grep --color=auto -q x 2>/dev/null
        alias grep='grep --color=auto'
    end

    # man ページの Dracula テーマ (https://github.com/dracula/man-pages)
    set -gx MANPAGER "less -s -M +Gg"
    set -gx LESS_TERMCAP_mb (printf '\e[1;31m') # begin blink
    set -gx LESS_TERMCAP_md (printf '\e[1;34m') # begin bold
    set -gx LESS_TERMCAP_so (printf '\e[01;45;37m') # begin reverse video
    set -gx LESS_TERMCAP_us (printf '\e[01;36m') # begin underline
    set -gx LESS_TERMCAP_me (printf '\e[0m') # reset bold/blink
    set -gx LESS_TERMCAP_se (printf '\e[0m') # reset reverse video
    set -gx LESS_TERMCAP_ue (printf '\e[0m') # reset underline
    set -gx GROFF_NO_SGR 1

    alias fgc=fzf_gcloud_config
    alias fga=fzf_gcloud_auth
    alias gssh=fzf_gcloud_ssh
    alias fssh=fzf_ssh
end

# uv で入れたツールと mise 本体の置き場
if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

set -l brew_bin (command -v brew 2>/dev/null)
if test -z "$brew_bin"; and test -x /opt/homebrew/bin/brew
    set brew_bin /opt/homebrew/bin/brew
else if test -z "$brew_bin"; and test -x /usr/local/bin/brew
    set brew_bin /usr/local/bin/brew
end
if test -n "$brew_bin"
    __source_cached_init brew-shellenv "$brew_bin" shellenv fish
end

# crontab 等の CLI は VISUAL を EDITOR より優先して参照するため両方を揃える。
# VSCode は --wait が無いと即座に制御を返し、呼び出し元が編集完了と誤認する。
# code の検出は brew shellenv で PATH が揃った後に行う必要がある。
if test "$human_shell" = true
    if type -q code
        set -gx EDITOR "code --wait"
    else
        set -gx EDITOR vim
    end
    set -gx VISUAL $EDITOR

    # LS_COLORS の Dracula テーマ (https://github.com/dracula/dircolors。.chezmoiexternal.toml が取得)。
    # dircolors は GNU coreutils にしか無く、macOS 標準には無い
    set -l dircolors_bin (command -v dircolors; or command -v gdircolors)
    if test -n "$dircolors_bin"; and test -f $HOME/.config/dircolors/dracula/.dircolors
        eval ($dircolors_bin -c $HOME/.config/dircolors/dracula/.dircolors | string replace 'setenv LS_COLORS' 'set -gx LS_COLORS')
    end
end

set -gx GOPATH "$HOME/Works"
# mise activate 環境では mise が GOBIN を上書きするため、これは mise が無いときの値
set -gx GOBIN "$HOME/.local/bin"
# Takumi Guard (悪性パッケージを遮断する proxy)。`,direct` を付けると未収載・ブロック済みの module で
# proxy を迂回できてしまうため URL だけを指定する。認証 token は ~/.netrc (modify_private_dot_netrc)
set -gx GOPROXY "https://golang.flatt.tech"

if test -f /opt/homebrew/opt/openjdk/bin/java
    fish_add_path /opt/homebrew/opt/openjdk/bin
    set -gx CPPFLAGS "-I/opt/homebrew/opt/openjdk/include"
end

set -gx CLOUDSDK_PYTHON (type -p python3)

if test -e /.dockerenv && test -z "$DOCKER_MACHINE_NAME"
    set -gx DOCKER_MACHINE_NAME "docker"
end

if test -d /opt/homebrew/opt/mysql-client/bin/
    set -gx MYSQL_CLIENT_PATH /opt/homebrew/opt/mysql-client
    fish_add_path $MYSQL_CLIENT_PATH/bin
end

# mysqlclient (Python) のビルド用
if test (uname) = "Darwin"
    contains -- /opt/homebrew/lib/pkgconfig $PKG_CONFIG_PATH
    or set -gx PKG_CONFIG_PATH /opt/homebrew/lib/pkgconfig $PKG_CONFIG_PATH
    string match -q "*-L/opt/homebrew/lib*" -- "$LDFLAGS"
    or set -gx LDFLAGS "-L/opt/homebrew/lib $LDFLAGS"
    string match -q "*-I/opt/homebrew/include*" -- "$CPPFLAGS"
    or set -gx CPPFLAGS "-I/opt/homebrew/include $CPPFLAGS"
end

if test -d $HOME/.orbstack/shell
    source $HOME/.orbstack/shell/init2.fish
end

# usr/bin は末尾に追加して Homebrew の git/python3 を優先しつつ simctl 等も引けるようにする
if type -q xcode-select; and xcode-select -p >/dev/null 2>&1
    set -gx DEVELOPER_DIR (xcode-select -p)
    fish_add_path -a $DEVELOPER_DIR/usr/bin
end

# 以降のツール検出は mise 由来のツールも解決できる __tool_path で行う
if test "$human_shell" = true
    set -l direnv_bin (__tool_path direnv)
    if test -n "$direnv_bin"
        __source_cached_init direnv-hook "$direnv_bin" hook fish
    end
end

if type -q mise
    if test "$human_shell" = true
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end

set -gx OP_ACCOUNT my.1password.com

if test "$human_shell" = true
    # Dracula テーマ (https://github.com/dracula/fish) は fisher が themes/ に置く。
    # fish >= 3.4 は導入だけでは適用されないため明示的に choose する
    if test -f $HOME/.config/fish/themes/"Dracula Official.theme"
        fish_config theme choose "Dracula Official"
    end

    # Ghostty の cursor-style = block に揃える
    set -g fish_cursor_default block
    set -g fish_cursor_insert block
    set -g fish_cursor_replace_one underscore
    set -g fish_cursor_visual block

    set -l starship_bin (__tool_path starship)
    if test -n "$starship_bin"
        # `starship init fish` は full-init を都度生成する stub なので full-init 本体をキャッシュする
        __source_cached_init starship-init "$starship_bin" init fish --print-full-init
    end

    # aws_completer は補完の実行時 (PATH 反映後) に解決されるので、__tool_path は登録の判定にだけ使う
    set -l aws_completer_bin (__tool_path aws_completer)
    if test -n "$aws_completer_bin"
        complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | string trim --right; end)'
    end
    # aws-sso の補完はヘルパー関数 (aws-sso-profile 等) も定義するため、コマンド名で自動ロードされる
    # completions/ には置かず直接 source する
    set -l aws_sso_bin (__tool_path aws-sso)
    if test -n "$aws_sso_bin"
        __source_cached_init aws-sso-completions "$aws_sso_bin" setup completions --source --shell fish
    end

    set -l fzf_bin (__tool_path fzf)
    if test -n "$fzf_bin"
        __source_cached_init fzf-fish "$fzf_bin" --fish
    end

    set -l zoxide_bin (__tool_path zoxide)
    if test -n "$zoxide_bin"
        __source_cached_init zoxide-init "$zoxide_bin" init fish
    end
end

if test "$human_shell" = true; and type -q fnox
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

    # op whoami は 1 回 ~70ms かかるため結果を TTL 付きでキャッシュする。
    # 失効側の TTL は、別タブでの signin を早く拾えるよう短くする
    set -g __fnox_op_session_status 1
    set -g __fnox_op_session_expires 0
    function __fnox_op_session_ok
        set -l now (date +%s)
        if test $now -lt $__fnox_op_session_expires
            return $__fnox_op_session_status
        end
        if op whoami >/dev/null 2>&1
            set -g __fnox_op_session_status 0
            set -g __fnox_op_session_expires (math $now + 300)
        else
            set -g __fnox_op_session_status 1
            set -g __fnox_op_session_expires (math $now + 60)
        end
        return $__fnox_op_session_status
    end

    # 起動時・プロンプト時は op signin しない (Touch ID 待ちで数秒止まり、タブを開く操作が固まるため)。
    # 失効は config ごとに 1 回だけ通知し、signin は fnox の明示実行時 (下の fnox wrapper) に行う
    function __fnox_preauth_1password
        type -q op; or return 0

        set -l config_path (__fnox_find_1password_config)
        or return 0

        if __fnox_op_session_ok
            return 0
        end
        if not set -q __fnox_op_notified_for; or test "$__fnox_op_notified_for" != "$config_path"
            set -g __fnox_op_notified_for "$config_path"
            echo "fnox: 1Password セッション失効のため secret をスキップ中 (fnox 実行時に op signin します)" >&2
        end
        return 1
    end

    functions -e __fnox_env_eval
    functions -e __fnox_cd_hook

    # 失効時は hook-env を実行しない。FNOX_PROMPT_AUTH=false では、secret ごとに並列に起動される
    # op の認証ダイアログは抑止できない (secret の数だけダイアログが出る)
    function __fnox_env_eval --on-event fish_prompt
        if test "$FNOX_SHELL" = fish
            if __fnox_preauth_1password
                eval (command fnox hook-env -s fish | string collect)
            end
        end
    end

    function __fnox_cd_hook --on-variable PWD
        if test "$FNOX_SHELL" = fish
            __fnox_env_eval
        end
    end

    # fnox activate が定義する fnox wrapper を、1Password の signin 付きのものに置き換える。
    # 明示実行時は Touch ID 待ちで止まってよいのでここで signin し、失敗したら中断する
    # (そのまま実行すると op が secret ごとに認証ダイアログを出す)。deactivate / shell の扱いは activate 版と同じ
    functions -e fnox
    function fnox
        if type -q op; and __fnox_find_1password_config >/dev/null; and not __fnox_op_session_ok
            if op signin >/dev/null 2>&1
                set -g __fnox_op_session_status 0
                set -g __fnox_op_session_expires (math (date +%s) + 300)
                set -e __fnox_op_notified_for
                __fnox_env_eval
            else
                echo "fnox: op signin に失敗したため中断 (1Password 認証なしで実行するには command fnox)" >&2
                return 1
            end
        end
        set -l command $argv[1]
        switch "$command"
            case deactivate shell
                eval (command fnox "$command" $argv[2..-1])
            case '*'
                command fnox "$command" $argv[2..-1]
        end
    end

    __fnox_env_eval
end
