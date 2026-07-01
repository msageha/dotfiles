---
name: gws-sheets
description: "Google Sheets: Read and write spreadsheets using gws CLI."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [spreadsheet ID or action description]
---

# sheets (v4)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

```bash
gws sheets <resource> <method> [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws sheets +read` | Read values from a spreadsheet (see `gws-sheets-read` skill) |
| `gws sheets +append` | Append a row (see `gws-sheets-append` skill) |

## Key Resources

### spreadsheets
- `get` — Get spreadsheet metadata (use `fields` or `includeGridData` for grid data).
- `create` — Create a new spreadsheet.
- `batchUpdate` — Apply updates (formatting, add sheets, merge cells, etc.).
- `values` — Read/write cell values (get, update, append, batchGet, batchUpdate, clear).

## Discovering Commands

```bash
gws sheets --help
gws schema sheets.<resource>.<method>
```
