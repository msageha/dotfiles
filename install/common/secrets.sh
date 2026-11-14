#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# chezmoi init --apply の後に単体で実行する。暗号化ファイルを適用するかは apply の開始時に age 秘密鍵の有無で決まり、
# chezmoi の実行中 (run スクリプトや hook) からは persistent state の lock で apply を呼び直せないため
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

    # session token は環境変数で渡るので、このプロセスでサインインして後続の fnox・chezmoi に引き継ぐ。
    # CLI にアカウントが未登録だと op signin は失敗する
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

    # --init が fnox の注入した API キーを chezmoi.toml に書き込む。暗号化ファイルも同じ apply で展開される
    log_step "API キーと暗号化した設定を適用しています..."
    fnox --config "$CHEZMOI_REPO_ROOT/fnox.toml" exec -- chezmoi apply --init

    # mise.toml の apply-ssh-keys と同じ操作。タスクはリポジトリの mise.toml の trust と開発ツールの導入を要するので使わない
    log_step "SSH 秘密鍵を配置しています..."
    chezmoi apply --override-data '{"apply_ssh_keys": true}' --less-interactive --error-on-conflict ~/.ssh
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
