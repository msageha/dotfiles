#!/usr/bin/env bash
set -Eeuo pipefail

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color (リセット)

# 公式 marketplace (claude-plugins-official) から plugin を取得する共通処理。
# add / install は導入済みでもエラーにならず冪等なため、分岐せず常に実行して最新化する。
function install_plugin() {
    local plugin_id="$1"
    claude plugin install "$plugin_id"
    claude plugin update "$plugin_id"
}

function cloudflare() {
    printf "%b\n" "${BLUE}Installing cloudflare/skills...${NC}"
    install_plugin cloudflare@claude-plugins-official
}

function github() {
    printf "%b\n" "${BLUE}Installing GitHub MCP server...${NC}"
    install_plugin github@claude-plugins-official
}

function semgrep() {
    printf "%b\n" "${BLUE}Installing Semgrep...${NC}"
    install_plugin semgrep@claude-plugins-official
}

function agent_sdk_dev() {
    printf "%b\n" "${BLUE}Installing agent-sdk-dev...${NC}"
    install_plugin agent-sdk-dev@claude-plugins-official
}

function plugin_dev() {
    printf "%b\n" "${BLUE}Installing plugin-dev...${NC}"
    install_plugin plugin-dev@claude-plugins-official
}

function claude_md_management() {
    printf "%b\n" "${BLUE}Installing claude-md-management...${NC}"
    install_plugin claude-md-management@claude-plugins-official
}

function skill_creator() {
    printf "%b\n" "${BLUE}Installing skill-creator...${NC}"
    install_plugin skill-creator@claude-plugins-official
}

function sonatype_guide() {
    printf "%b\n" "${BLUE}Installing sonatype-guide...${NC}"
    install_plugin sonatype-guide@claude-plugins-official
}

lsp_plugins=(
    pyright-lsp
    gopls-lsp
    clangd-lsp
    swift-lsp
    typescript-lsp
)

function lsp() {
    printf "%b\n" "${BLUE}Installing language servers...${NC}"
    local name
    for name in "${lsp_plugins[@]}"; do
        install_plugin "${name}@claude-plugins-official"
    done
}

function main() {
    if ! command -v claude &>/dev/null; then
        printf "%b\n" "${YELLOW}claude が見つかりません。plugin のインストールをスキップします。${NC}"
        return 0
    fi

    printf "%b\n" "${BLUE}=== Installing Claude Code plugins ===${NC}"
    claude plugin marketplace add anthropics/claude-plugins-official
    claude plugin marketplace update claude-plugins-official

    cloudflare
    github
    semgrep
    agent_sdk_dev
    plugin_dev
    claude_md_management
    skill_creator
    sonatype_guide
    lsp

    printf "%b\n" "${BLUE}=== All Claude Code plugins installed! ===${NC}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
