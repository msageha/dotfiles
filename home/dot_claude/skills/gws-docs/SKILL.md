---
name: gws-docs
description: "Google Docs: Gets document contents, creates new documents, or applies rich batchUpdate formatting using gws CLI — for simply appending plain text, use gws-docs-write instead."
allowed-tools: Read, Grep, Glob, Bash(gws schema *)
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
| `gws docs +write` | Append text to a document (see `gws-docs-write` skill) |

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
