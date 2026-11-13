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

- Claude `permissions.allow`: Collapse the entries a wildcard covers into one `Bash(<tool>:*)` entry instead of listing individual subcommands.
- Codex rules: A `decision = "allow"` prefix rule in `~/.codex/rules/*.rules` runs the matching command outside the sandbox without approval, even in a session started with `-s read-only`; read-only delegations therefore pass `--ignore-rules` (`codex exec` and `codex exec review` accept it, top-level `codex review` does not). When adding an allow rule, check that no read-only workflow that omits `--ignore-rules` would then run that command outside its sandbox.
- Proposing permissions: Base each proposed rule (allow / ask / deny / an exception) on actual usage, approval history and risk; AGENTS.md「安全」 covers the general policy. Do not loosen your own permission or sandbox settings on your own initiative to get past a block: propose the minimal concrete rule, and once the user approves it, add it to the user's global settings (the chezmoi source) yourself.
- Allowlist from history: When the user asks to generate `permissions.allow` from their execution history, keep every command they repeatedly approved (interpreters, shells, delete and network commands included) instead of excluding them on your own safety judgement; state the residual risk as a note and leave the trade-off to the user.
