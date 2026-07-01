---
name: gws-gmail-send
description: "Gmail: Send an email using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: --to <EMAIL> --subject <SUBJECT> --body <TEXT>
---

# gmail +send

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

## Usage

```bash
gws gmail +send --to <EMAIL> --subject <SUBJECT> --body <TEXT>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--to` | yes | Recipient email address |
| `--subject` | yes | Email subject |
| `--body` | yes | Email body (plain text) |

## Examples

```bash
gws gmail +send --to alice@example.com --subject 'Hello' --body 'Hi Alice!'
```

## Tips

- Handles RFC 2822 formatting and base64 encoding automatically.
- For HTML bodies, attachments, or CC/BCC, use the raw API: `gws gmail users messages send --json '...'`

> **CAUTION:** This is a **write** command — confirm with the user before executing.
