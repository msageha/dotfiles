---
name: gws-calendar-insert
description: "Google Calendar: Creates a new event using gws CLI."
allowed-tools: Read, Grep, Glob
argument-hint: "--summary <TEXT> --start <TIME> --end <TIME>"
---

# calendar +insert

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

## Usage

```bash
gws calendar +insert --summary <TEXT> --start <TIME> --end <TIME>
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--calendar` | - | primary | Calendar ID |
| `--summary` | yes | - | Event title |
| `--start` | yes | - | Start time (RFC 3339, e.g. `2026-03-10T09:00:00+09:00`) |
| `--end` | yes | - | End time (RFC 3339) |
| `--location` | - | - | Event location |
| `--description` | - | - | Event description |
| `--attendee` | - | - | Attendee email (repeatable) |
| `--meet` | - | - | Add a Google Meet video conference link |
| `--dry-run` | - | - | Validate the request locally without sending it |

## Examples

```bash
gws calendar +insert --summary 'Standup' --start '2026-03-10T09:00:00+09:00' --end '2026-03-10T09:30:00+09:00'
gws calendar +insert --summary 'Review' --start ... --end ... --attendee alice@example.com
gws calendar +insert --summary 'Meet' --start ... --end ... --meet
```
