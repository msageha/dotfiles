#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function main() {
    # CLAUDE_MARKETPLACES (name=owner/repo の空白区切り) と CLAUDE_PLUGINS (有効な plugin id の空白区切り) は
    # run_once_before テンプレートが .chezmoidata.toml の claude.* から export する。
    # CLAUDE_PLUGINS の未設定と空文字はどちらも 0 件とする (PowerShell は空文字を代入した環境変数を削除して両者を区別できないので、Windows 版とそろえる)
    if [ -z "${CLAUDE_MARKETPLACES+x}" ]; then
        log_error "CLAUDE_MARKETPLACES is not set; it must be exported by the caller."
        exit 1
    fi
    if ! command -v claude &>/dev/null; then
        log_warn "claude が見つかりません。plugin のインストールをスキップします。"
        return 0
    fi

    log_step "=== Installing Claude Code plugins ==="
    # marketplace add / plugin install / update は導入済みでも成功するので、分岐せず毎回実行して最新にする
    local marketplace plugin
    for marketplace in $CLAUDE_MARKETPLACES; do
        claude plugin marketplace add "${marketplace#*=}"
        claude plugin marketplace update "${marketplace%%=*}"
    done
    for plugin in ${CLAUDE_PLUGINS:-}; do
        log_step "Installing ${plugin}..."
        claude plugin install "$plugin"
        claude plugin update "$plugin"
    done
    log_step "=== All Claude Code plugins installed! ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
