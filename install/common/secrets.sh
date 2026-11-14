#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# 1Password から age 秘密鍵・API キー・SSH 秘密鍵を取得して適用する。
# 暗号化ファイルを適用するかは apply の開始時に age 秘密鍵の有無で決まり、chezmoi の実行中 (run スクリプトや hook) からは
# persistent state の lock で chezmoi apply を呼び直せないため、chezmoi init --apply の後に単体で実行する
function main() {
    activate_tool_paths
    local skip_secrets
    skip_secrets="$(chezmoi execute-template '{{ dig "skip_secrets" true . }}')"
    if [ "$skip_secrets" != "false" ]; then
        log_step "skip_secrets=true のため、secret の展開をスキップします。"
        return 0
    fi
    require_command op
    require_command fnox

    # 手でサインインしたときの session token は環境変数で渡るので、このプロセスで取得して後続の op・fnox・chezmoi に継承させる。
    # 1Password アプリの CLI 連携が有効なら whoami が通り、サインインは要らない。
    # アプリの連携も CLI へのアカウント登録も無いと op signin は失敗するので、そのときは登録と同時にサインインする
    if ! op whoami &>/dev/null; then
        if [ -z "$(op account list)" ]; then
            log_step "1Password のアカウントを CLI に登録してサインインします..."
            eval "$(op account add --signin)"
        else
            log_step "1Password にサインインします..."
            eval "$(op signin)"
        fi
    fi

    local age_key="$HOME/.config/chezmoi/key.txt"
    if [ ! -f "$age_key" ]; then
        log_step "age 秘密鍵を 1Password から取得しています..."
        mkdir -p "$(dirname "$age_key")"
        op read --out-file "$age_key" --file-mode 0600 'op://Private/age-identity/password'
    fi

    # fnox が注入した API キーを、--init が chezmoi.toml の data.apiKeys に書き込む。age 秘密鍵があるので暗号化ファイルも展開される
    log_step "API キーと暗号化した設定を適用しています..."
    fnox --config "$CHEZMOI_REPO_ROOT/fnox.toml" exec -- chezmoi apply --init

    # mise.toml の apply-ssh-keys タスクと同じ操作。タスクはリポジトリの mise.toml の trust と開発ツールの導入を要するので、直接実行する
    log_step "SSH 秘密鍵を配置しています..."
    chezmoi apply --override-data '{"apply_ssh_keys": true}' --less-interactive --error-on-conflict ~/.ssh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
