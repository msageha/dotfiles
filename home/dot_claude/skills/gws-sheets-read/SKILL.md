---
name: gws-sheets-read
description: "Google Sheets: Read values from a spreadsheet using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: --spreadsheet <ID> --range <RANGE>
---

# sheets +read

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

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
