---
name: gws-calendar-insert
description: "Google Calendar: Create a new event using gws CLI."
allowed-tools: Bash, Read, Grep, Glob
argument-hint: --summary <TEXT> --start <TIME> --end <TIME>
---

# calendar +insert

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

## Usage

```bash
gws calendar +insert --summary <TEXT> --start <TIME> --end <TIME>
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--calendar` | - | primary | Calendar ID |
| `--summary` | yes | - | Event title |
| `--start` | yes | - | Start time (ISO 8601) |
| `--end` | yes | - | End time (ISO 8601) |
| `--location` | - | - | Event location |
| `--description` | - | - | Event description |
| `--attendee` | - | - | Attendee email (repeatable) |

## Examples

```bash
gws calendar +insert --summary 'Standup' --start '2026-03-10T09:00:00+09:00' --end '2026-03-10T09:30:00+09:00'
gws calendar +insert --summary 'Review' --start ... --end ... --attendee alice@example.com
```

> **CAUTION:** This is a **write** command — confirm with the user before executing.
