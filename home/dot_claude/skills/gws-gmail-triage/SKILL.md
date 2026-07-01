---
name: gws-gmail-triage
description: "Gmail: Show unread inbox summary (sender, subject, date) using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [--max N] [--query 'search query']
---

# gmail +triage

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

## Usage

```bash
gws gmail +triage
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--max` | - | 20 | Maximum messages to show |
| `--query` | - | is:unread | Gmail search query |
| `--labels` | - | - | Include label names in output |

## Examples

```bash
gws gmail +triage
gws gmail +triage --max 5 --query 'from:boss'
gws gmail +triage --format json | jq '.[].subject'
gws gmail +triage --labels
```

## Tips

- Read-only — never modifies your mailbox.
- Defaults to table output format.
