---
name: gws-docs-write
description: "Google Docs: Append text to a document using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: --document <ID> --text <TEXT>
---

# docs +write

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

## Usage

```bash
gws docs +write --document <ID> --text <TEXT>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--document` | yes | Document ID |
| `--text` | yes | Text to append (plain text) |

## Examples

```bash
gws docs +write --document DOC_ID --text 'Hello, world!'
```

## Tips

- Text is inserted at the end of the document body.
- For rich formatting, use the raw batchUpdate API instead.

> **CAUTION:** This is a **write** command — confirm with the user before executing.
