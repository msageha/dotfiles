---
name: gws-sheets-append
description: "Google Sheets: Append a row to a spreadsheet using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: --spreadsheet <ID> --values <CSV>
---

# sheets +append

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

## Usage

```bash
gws sheets +append --spreadsheet <ID>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--spreadsheet` | yes | Spreadsheet ID |
| `--values` | - | Comma-separated values (single row) |
| `--json-values` | - | JSON array of rows, e.g. `'[["a","b"],["c","d"]]'` |

## Examples

```bash
gws sheets +append --spreadsheet ID --values 'Alice,100,true'
gws sheets +append --spreadsheet ID --json-values '[["a","b"],["c","d"]]'
```

## Tips

- Use `--values` for simple single-row appends.
- Use `--json-values` for bulk multi-row inserts.

> **CAUTION:** This is a **write** command — confirm with the user before executing.
