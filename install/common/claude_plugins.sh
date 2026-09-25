#!/usr/bin/env bash
set -euo pipefail
declare -F log_step >/dev/null 2>&1 || source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

function main() {
    # CLAUDE_MARKETPLACES (name=owner/repo の空白区切り) と CLAUDE_PLUGINS (有効な plugin id の空白区切り) は
    # run_once_before テンプレートが .chezmoidata.toml の claude.* から必ず export する契約。
    # 未設定は設定ミスとして落とす (有効な plugin が 0 件の空文字は正常)
    if [ -z "${CLAUDE_MARKETPLACES+x}" ] || [ -z "${CLAUDE_PLUGINS+x}" ]; then
        log_error "CLAUDE_MARKETPLACES / CLAUDE_PLUGINS are not set; they must be exported by the caller."
        exit 1
    fi
    if ! command -v claude &>/dev/null; then
        log_warn "claude が見つかりません。plugin のインストールをスキップします。"
        return 0
    fi

    log_step "=== Installing Claude Code plugins ==="
    # marketplace add / plugin install / update は導入済みでもエラーにならず冪等なため、分岐せず常に実行して最新化する
    local marketplace plugin
    for marketplace in $CLAUDE_MARKETPLACES; do
        claude plugin marketplace add "${marketplace#*=}"
        claude plugin marketplace update "${marketplace%%=*}"
    done
    for plugin in $CLAUDE_PLUGINS; do
        log_step "Installing ${plugin}..."
        claude plugin install "$plugin"
        claude plugin update "$plugin"
    done
    log_step "=== All Claude Code plugins installed! ==="
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
