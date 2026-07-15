---
name: gws-docs
description: "Google Docs: Get document contents, create new documents, or apply rich batchUpdate formatting using gws CLI — for simply appending plain text, use gws-docs-write instead."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [document ID or action description]
---

# docs (v1)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

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

## Discovering Commands

```bash
gws docs --help
gws schema docs.<resource>.<method>
```
