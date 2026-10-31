---
name: gws-calendar-agenda
description: "Google Calendar: Shows upcoming events across all calendars using gws CLI."
allowed-tools: Bash(gws calendar +agenda *)
argument-hint: "[--today] [--week] [--days N]"
---

# calendar +agenda

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth and global flags.

## Usage

```bash
gws calendar +agenda
```

## Flags

| Flag | Description |
|------|-------------|
| `--today` | Show today's events |
| `--tomorrow` | Show tomorrow's events |
| `--week` | Show this week's events |
| `--days <N>` | Number of days ahead to show |
| `--calendar <NAME>` | Filter to specific calendar name or ID |
| `--timezone <TZ>` | IANA timezone override (e.g. `America/Denver`) |

## Examples

```bash
gws calendar +agenda
gws calendar +agenda --today
gws calendar +agenda --week --format table
gws calendar +agenda --days 3 --calendar 'Work'
gws calendar +agenda --today --timezone America/New_York
```

## Tips

- Read-only — never modifies events.
- Queries all calendars by default; use `--calendar` to filter.
- Uses the Google account timezone by default; override with `--timezone`.
- Output defaults to `table` (the `--help` text says json); pass `--format json` when parsing the result.
