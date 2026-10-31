---
paths:
  - "**/.claude/settings*.json"
  - "**/dot_claude/*settings*.json.tmpl"
  - "**/.codex/config.toml"
  - "**/.codex/*.config.toml"
  - "**/.codex/rules/**"
  - "**/dot_codex/*config.toml"
  - "**/dot_codex/rules/**"
  - "**/.grok/config.toml"
  - "**/dot_grok/*config.toml"
  - "**/.gemini/**/settings.json"
  - "**/dot_gemini/**/*settings.json.tmpl"
---
# Agent Harness Settings and Permissions (Claude settings.json / Codex config.toml and rules / Grok config.toml / Gemini settings.json)

- Claude `permissions.allow`: In Claude Code `settings.json` `permissions.allow`, collapse every entry a wildcard covers into `Bash(tool:*)` form instead of listing individual subcommands.
- Allowlist from history: When the user asks to generate `permissions.allow` from their execution history, keep every command they repeatedly approved (interpreters, shells, delete and network commands included) instead of excluding them on your own safety judgement; state the residual risk as a note and leave the trade-off to the user.
