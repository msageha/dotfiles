---
name: gws-docs
description: "Google Docs: Reads a document, creates one, appends text, or writes formatted content (headings, lists, tables) using gws CLI."
allowed-tools: Bash(gws schema *)
argument-hint: "[document ID or action description]"
---

# docs (v1)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws docs <resource> <method> [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws docs +write --document <ID> --text <TEXT>` | Append plain text to the end of the document body |

`+write` inserts `--text` literally, so Markdown syntax in it shows up as-is. For content with headings, lists, emphasis or tables (Markdown sources included), use `documents.batchUpdate` instead (Writing Content below).

## Key Resources

### documents
- `get` — Get the latest version of a document.
- `create` — Create a blank document with a title.
- `batchUpdate` — Apply updates (insert text, formatting, etc.).

## Writing Content

- Convert Markdown to native Docs formatting (paragraph / heading styles, bullet lists, bold) via `documents.batchUpdate` requests; never insert raw Markdown syntax (`#`, `**`, `|`) as document text.

## Discovering Commands

```bash
gws docs --help
gws schema docs.<resource>.<method>
```
