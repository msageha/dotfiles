---
name: gws-sheets-read
description: "Google Sheets: Reads values from a spreadsheet using gws CLI."
allowed-tools: Bash(gws sheets +read *)
argument-hint: "--spreadsheet <ID> --range <RANGE>"
---

# sheets +read

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth and global flags.

## Usage

```bash
gws sheets +read --spreadsheet <ID> --range <RANGE>
```

## Flags

| Flag | Required | Description |
|------|----------|-------------|
| `--spreadsheet` | yes | Spreadsheet ID |
| `--range` | yes | Range to read (e.g. `Sheet1!A1:B2`) |

## Examples

```bash
gws sheets +read --spreadsheet ID --range 'Sheet1!A1:D10'
gws sheets +read --spreadsheet ID --range Sheet1
```

## Tips

- Read-only — never modifies the spreadsheet.
- For advanced options, use the raw `values.get` API (see `gws-sheets`).
