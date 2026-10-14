# shellcheck shell=bash
# bash (~/.bash_profile) と zsh (~/.zprofile) が共有するツールのシェル統合 (prompt / hook / completion)。
# env.sh の後に source する。human の zsh は compinit (と aws_completer 用の bashcompinit) を済ませておく。
# _dotfiles_human_shell と _dotfiles_shell は env.sh が設定する。_fnox_hook でも参照するため unset しない
# shellcheck disable=SC2154

# mise 経由でのみ導入されるツールは mise activate の PATH 反映がプロンプト時のため、
# fresh シェルでは command -v が失敗しうる。mise which でフォールバックして実体パスを返す
_tool_path() {
    command -v "$1" 2>/dev/null && return 0
    command -v mise &>/dev/null && mise which "$1" 2>/dev/null
}

# --- OrbStack ---
if $_dotfiles_human_shell && [ -d "$HOME/.orbstack/shell" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.orbstack/shell/init.$_dotfiles_shell"
elif [ -d "$HOME/.orbstack/bin" ]; then
    export PATH="$PATH:$HOME/.orbstack/bin"
fi

if $_dotfiles_human_shell; then
    # --- Starship ---
    if _bin="$(_tool_path starship)"; then
        eval "$("$_bin" init "$_dotfiles_shell")"
    fi

    # --- fzf (CTRL-R / CTRL-T / ALT-C) ---
    if _bin="$(_tool_path fzf)"; then
        eval "$("$_bin" "--$_dotfiles_shell")"
    fi

    # --- zoxide ---
    if _bin="$(_tool_path zoxide)"; then
        eval "$("$_bin" init "$_dotfiles_shell")"
    fi

    # --- direnv ---
    if _bin="$(_tool_path direnv)"; then
        eval "$("$_bin" hook "$_dotfiles_shell")"
    fi
fi

# --- mise ---
if command -v mise &>/dev/null; then
    if $_dotfiles_human_shell; then
        eval "$(mise activate "$_dotfiles_shell")"
    else
        eval "$(mise activate "$_dotfiles_shell" --shims)"
    fi
fi

# --- 1Password CLI のデフォルトアカウント ---
export OP_ACCOUNT=my.1password.com

# --- fnox ---
if $_dotfiles_human_shell && command -v fnox &>/dev/null; then
    eval "$(fnox activate "$_dotfiles_shell")"
    _fnox_find_1password_config() {
        local dir="$PWD" config
        while [ "$dir" != "/" ]; do
            for config in "$dir"/fnox.toml "$dir"/fnox.local.toml "$dir"/fnox."${FNOX_PROFILE:-default}".toml; do
                [ -f "$config" ] || continue
                if grep -Eq 'type[[:space:]]*=[[:space:]]*["'\'']1password["'\'']' "$config"; then
                    printf '%s\n' "$config"
                    return 0
                fi
            done
            dir="${dir%/*}"
            [ -n "$dir" ] || dir="/"
        done
        return 1
    }

    _fnox_preauth_1password() {
        command -v op &>/dev/null || return 0

        local config_path
        config_path="$(_fnox_find_1password_config)" || return 0

        op whoami >/dev/null 2>&1 && return 0
        [ "${__FNOX_1PASSWORD_PREAUTH_FAILED_FOR:-}" = "$config_path" ] && return 1

        if op signin >/dev/null 2>&1; then
            unset __FNOX_1PASSWORD_PREAUTH_FAILED_FOR
            return 0
        fi
        export __FNOX_1PASSWORD_PREAUTH_FAILED_FOR="$config_path"
        echo "fnox: op signin に失敗したため secret をスキップ中 (op signin 成功後の cd で再読込されます)" >&2
        return 1
    }

    # fnox activate が定義する _fnox_hook を、1Password セッション失効時は hook-env を実行しない版で置き換える。
    # FNOX_PROMPT_AUTH=false は fnox 自身の auth_command 確認プロンプトを抑止するだけで、secret ごとに
    # 並列 spawn される op プロセスの認証ダイアログは素通しになる (secret の数だけダイアログが出る)
    _fnox_hook() {
        local previous_exit_status=$?
        trap -- '' SIGINT
        if _fnox_preauth_1password; then
            eval "$(command fnox hook-env -s "$_dotfiles_shell")"
        fi
        trap - SIGINT
        return $previous_exit_status
    }
fi

# --- AWS CLI / aws-sso-cli の補完 ---
# aws_completer は bash 形式の complete -C を前提とする (zsh は bashcompinit 経由)。
# aws-sso の補完は aws-sso-profile 等のヘルパー関数も含むため、completions.sh が生成する
# ファイル名一致の autoload には乗せず、この場で直接 source する
if $_dotfiles_human_shell; then
    if _bin="$(_tool_path aws_completer)"; then
        complete -C "$_bin" aws
    fi
    if _bin="$(_tool_path aws-sso)"; then
        eval "$("$_bin" setup completions --source --shell "$_dotfiles_shell")"
    fi
fi

# --- Claude Code の GitHub トークン ---
# GitHub MCP server (Claude Code の github plugin) が参照する GITHUB_PERSONAL_ACCESS_TOKEN を、
# gh の OAuth トークンから claude 起動時に注入する (PAT をファイルに置かず、gh auth token の ~170ms を
# シェル起動毎に払わない。fish の functions/claude.fish と同じ方式)。gh 未導入・未ログイン時は設定しない
claude() {
    if [ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ] && command -v gh &>/dev/null; then
        local gh_token
        gh_token="$(gh auth token 2>/dev/null)"
        if [ -n "$gh_token" ]; then
            export GITHUB_PERSONAL_ACCESS_TOKEN="$gh_token"
        fi
    fi
    command claude "$@"
}

unset _bin
