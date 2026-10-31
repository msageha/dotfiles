---
name: gws-sheets-append
description: "Google Sheets: Appends a row to a spreadsheet using gws CLI."
allowed-tools: Read, Grep, Glob
argument-hint: "--spreadsheet <ID> --values <CSV>"
---

# sheets +append

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

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
| `--dry-run` | - | Validate the request locally without sending it |

## Examples

```bash
gws sheets +append --spreadsheet ID --values 'Alice,100,true'
gws sheets +append --spreadsheet ID --json-values '[["a","b"],["c","d"]]'
```

## Tips

- Use `--values` for simple single-row appends.
- Use `--json-values` for bulk multi-row inserts.
