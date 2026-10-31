---
name: gws-gmail-send
description: "Gmail: Sends an email (plain text or HTML, with CC/BCC, attachments, or a send-as alias) or saves it as a draft using gws CLI."
allowed-tools: Read, Grep, Glob
argument-hint: "--to <EMAIL> --subject <SUBJECT> --body <TEXT>"
---

# gmail +send

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

## Usage

```bash
gws gmail +send --to <EMAILS> --subject <SUBJECT> --body <TEXT>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--to` | yes | Recipient email address(es), comma-separated |
| `--subject` | yes | Email subject |
| `--body` | yes | Email body (plain text, or HTML with `--html`) |
| `--cc` | - | CC email address(es), comma-separated |
| `--bcc` | - | BCC email address(es), comma-separated |
| `--html` | - | Treat `--body` as HTML |
| `-a, --attach` | - | Attach a file (repeatable) |
| `--from` | - | Sender address for a send-as alias (omit to use the account default) |
| `--draft` | - | Save as a draft instead of sending |
| `--dry-run` | - | Show the request that would be sent without executing it |

## Examples

```bash
gws gmail +send --to alice@example.com --subject 'Hello' --body 'Hi Alice!'
gws gmail +send --to alice@example.com --subject 'Hello' --body 'Hi!' --cc bob@example.com
gws gmail +send --to alice@example.com --subject 'Hello' --body '<b>Bold</b> text' --html
gws gmail +send --to alice@example.com --subject 'Report' --body 'See attached' -a report.pdf -a data.csv
gws gmail +send --to alice@example.com --subject 'Hello' --body 'Hi!' --draft
```

## Tips

- Handles RFC 5322 formatting, MIME encoding, and base64 automatically.
- Attachments: total size limit 25 MB.
- With `--html`, use fragment tags (`<p>`, `<b>`, `<a>`, `<br>`); no `<html>`/`<body>` wrapper is needed.
- `--dry-run` and `--draft` let the user check the message before it is sent.
