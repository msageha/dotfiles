#!/usr/bin/env bats

# apply 後のコーディングエージェント設定が well-formed か検証するスモークテスト。
# 特に chezmoi:modify-template (~/.codex/config.toml, ~/.grok/config.toml, ~/.claude.json)
# はテンプレート側の構文回帰が rendered 側の破損として現れるため、ここで検出する。

load ../test_helper

function setup() {
    # skip_cli_tools=true ではコーディングエージェント設定は管理対象外 (.chezmoiignore の skipCodingAgent gate)
    if cli_tools_skipped; then
        skip "coding agent settings are not managed (skip_cli_tools=true)"
    fi
    command -v python3 &>/dev/null || skip "python3 not available"
    python3 -c 'import tomllib' 2>/dev/null || skip "python3 tomllib not available (needs >= 3.11)"
}

function assert_valid_toml() {
    local file="$1"
    [ -f "${file}" ]
    python3 -c "import tomllib, sys; tomllib.load(open(sys.argv[1], 'rb'))" "${file}"
}

function assert_valid_json() {
    local file="$1"
    [ -f "${file}" ]
    python3 -c "import json, sys; json.load(open(sys.argv[1]))" "${file}"
}

@test "[files] coding agents - codex config files are valid TOML" {
    assert_valid_toml "${HOME}/.codex/config.toml"
    for profile_config in "${HOME}/.codex/"*.config.toml; do
        [ -e "${profile_config}" ] || continue
        echo "Checking ${profile_config}"
        assert_valid_toml "${profile_config}"
    done
    for agent_config in "${HOME}/.codex/agents/"*.toml; do
        [ -e "${agent_config}" ] || continue
        echo "Checking ${agent_config}"
        assert_valid_toml "${agent_config}"
    done
}

@test "[files] coding agents - codex model catalogs are valid JSON" {
    for catalog in "${HOME}/.codex/"*.json; do
        echo "Checking ${catalog}"
        assert_valid_json "${catalog}"
    done
}

@test "[files] coding agents - grok config.toml is valid TOML" {
    assert_valid_toml "${HOME}/.grok/config.toml"
}

@test "[files] coding agents - claude settings are valid JSON" {
    assert_valid_json "${HOME}/.claude.json"
    assert_valid_json "${HOME}/.claude/settings.json"
}

@test "[files] coding agents - gemini settings are valid JSON" {
    assert_valid_json "${HOME}/.gemini/settings.json"
    assert_valid_json "${HOME}/.gemini/config/mcp_config.json"
    assert_valid_json "${HOME}/.gemini/antigravity-cli/settings.json"
}

@test "[files] coding agents - enabled claude plugins are installed" {
    command -v claude &>/dev/null || skip "claude not installed"
    local installed plugin
    installed="$(claude plugin list 2>/dev/null)"
    # 有効な plugin の一覧は .chezmoidata.toml (install スクリプトへの export と同じ range 式)
    for plugin in $(chezmoi_template '{{ range $id, $enabled := .claude.plugins }}{{ if $enabled }}{{ $id }} {{ end }}{{ end }}'); do
        echo "Checking ${plugin}"
        echo "${installed}" | grep -q "${plugin}"
    done
}
