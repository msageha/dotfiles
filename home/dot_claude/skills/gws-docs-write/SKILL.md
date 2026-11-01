---
name: gws-docs-write
description: "Google Docs: Appends text to a document using gws CLI."
allowed-tools: Read, Grep, Glob
argument-hint: "--document <ID> --text <TEXT>"
---

# docs +write

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

## Usage

```bash
gws docs +write --document <ID> --text <TEXT>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--document` | yes | Document ID |
| `--text` | yes | Text to append (plain text) |
| `--dry-run` | - | Validate the request locally without sending it |

## Examples

```bash
gws docs +write --document DOC_ID --text 'Hello, world!'
```

## Tips

- Text is inserted at the end of the document body.
- For rich formatting, use the raw batchUpdate API instead.
