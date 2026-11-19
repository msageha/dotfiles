---
paths:
  - "**/.claude/settings*.json"
  - "**/.codex/config.toml"
  - "**/.codex/*.config.toml"
  - "**/.codex/rules/**"
  - "**/.grok/config.toml"
  - "**/.gemini/**/settings.json"
  - "**/dot_claude/*settings*.json.tmpl"
  - "**/dot_codex/*config.toml"
  - "**/.chezmoitemplates/codex/config.toml.modify"
  - "**/dot_codex/rules/**"
  - "**/dot_grok/*config.toml"
  - "**/dot_gemini/**/*settings.json.tmpl"
---
# Agent Harness Settings and Permissions (Claude settings.json / Codex config.toml and rules / Grok config.toml / Gemini settings.json)

- Claude `permissions.allow`: List one `Bash(<tool>:*)` entry per tool instead of individual subcommand entries.
- Codex rules: A `decision = "allow"` prefix rule in a user or project `.rules` file runs the matching command outside the sandbox without approval, even in a session started with `-s read-only`; read-only delegations therefore pass `--ignore-rules` (`codex exec` and `codex exec review` accept it; top-level `codex review` and the Claude Code codex plugin cannot pass it, so their read-only runs execute allowed commands outside the sandbox). A pattern matches a prefix of the command's tokens and cannot restrict the arguments after it. Before adding an allow rule, check what the command accepts after the prefix (options that run a command, such as `--exec` or `--upload-pack`, and destructive ones such as `--force`), choose a prefix that leaves out the forms that must not pass, state the remaining exposure when proposing the rule, and check that every read-only `codex exec` invocation in skills and instruction files passes `--ignore-rules`.
- Proposing permissions: Base each proposed rule (allow / ask / deny / an exception) on actual usage, approval history and risk; AGENTS.md「安全」 covers the general policy. Do not loosen your own permission or sandbox settings on your own initiative to get past a block: propose the minimal concrete rule, and once the user approves it, add it to the user's global settings (the chezmoi source) yourself.
- Allowlist from history: When the user asks to generate `permissions.allow` from their execution history, keep every command they repeatedly approved (interpreters, shells, delete and network commands included) instead of excluding them on your own safety judgement; state the residual risk as a note and leave the trade-off to the user.
