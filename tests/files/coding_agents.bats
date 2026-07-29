#!/usr/bin/env bats

# apply 後のコーディングエージェント設定が well-formed か検証するスモークテスト。
# 特に chezmoi:modify-template (~/.codex/config.toml, ~/.grok/config.toml, ~/.claude.json)
# はテンプレート側の構文回帰が rendered 側の破損として現れるため、ここで検出する。

function setup() {
    # skip_cli_tools=true (または Windows の skip_windows_extras=true) では
    # コーディングエージェント設定は管理対象外 (.chezmoiignore の skipCodingAgent gate)
    if [ "$(chezmoi execute-template '{{ or (dig "skip_cli_tools" false .) (dig "skip_windows_extras" false .) }}' 2>/dev/null)" == "true" ]; then
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

@test "[common] coding agents - codex config files are valid TOML" {
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

@test "[common] coding agents - grok config.toml is valid TOML" {
    assert_valid_toml "${HOME}/.grok/config.toml"
}

@test "[common] coding agents - claude settings are valid JSON" {
    assert_valid_json "${HOME}/.claude.json"
    assert_valid_json "${HOME}/.claude/settings.json"
}

@test "[common] coding agents - gemini settings are valid JSON" {
    assert_valid_json "${HOME}/.gemini/settings.json"
    assert_valid_json "${HOME}/.gemini/config/mcp_config.json"
    assert_valid_json "${HOME}/.gemini/antigravity-cli/settings.json"
}
