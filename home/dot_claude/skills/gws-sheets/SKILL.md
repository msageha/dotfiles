---
name: gws-sheets
description: "Google Sheets: Reads a range, appends rows, updates or clears values, creates spreadsheets, and applies formatting or structural changes using gws CLI."
allowed-tools: Bash(gws schema *), Bash(gws sheets +read *)
argument-hint: "[spreadsheet ID or action description]"
---

# sheets (v4)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws sheets <resource> <method> [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws sheets +read --spreadsheet <ID> --range <RANGE>` | Read the values of a range (`<sheet>!A1:D10`) or of a whole sheet (`<sheet>`); read-only |
| `gws sheets +append --spreadsheet <ID> --values <CSV>` | Append one row, or several with `--json-values '<JSON array of rows>'` instead of `--values` |

`gws sheets +<helper> --help` lists the flags.

- `+read` takes only the range. For an option it has no flag for (such as `valueRenderOption` to get formulas instead of displayed values), use `spreadsheets values get`.
- `+append` targets the range `A1`, so rows are appended to the table on the first sheet. To append to another sheet, use `spreadsheets values append` with a `range`.
- `+append --values` splits on every comma; pass a value that contains a comma through `--json-values`.
- `+append --json-values` accepts strings only, so quote numbers and booleans (`"100"`, `"true"`); `USER_ENTERED` still stores them as a number and a boolean. With an unquoted one the helper only prints `Warning: --json-values is not valid JSON` and sends an empty `values`, so no row is appended.
- `+append` sends `valueInputOption` `USER_ENTERED`, so values are parsed as if typed into the UI and text that starts with `=` becomes a formula. To store text unparsed, use `spreadsheets values append` with `RAW`.

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
