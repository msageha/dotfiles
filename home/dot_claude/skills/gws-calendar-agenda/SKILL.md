---
name: gws-calendar-agenda
description: "Google Calendar: Show upcoming events across all calendars using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [--today] [--week] [--days N]
---

# calendar +agenda

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

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

## Examples

```bash
gws calendar +agenda
gws calendar +agenda --today
gws calendar +agenda --week --format table
gws calendar +agenda --days 3 --calendar 'Work'
```

## Tips

- Read-only — never modifies events.
- Queries all calendars by default; use `--calendar` to filter.
