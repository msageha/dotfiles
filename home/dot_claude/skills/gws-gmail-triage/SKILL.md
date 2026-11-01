---
name: gws-gmail-triage
description: "Gmail: Shows an unread inbox summary (sender, subject, date) using gws CLI."
allowed-tools: Bash(gws gmail +triage *)
argument-hint: "[--max N] [--query 'search query']"
---

# gmail +triage

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth and global flags.

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
- Output defaults to `table` (the `--help` text says json); pass `--format json` when parsing the result.
