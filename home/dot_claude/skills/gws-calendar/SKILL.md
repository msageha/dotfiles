---
name: gws-calendar
description: "Google Calendar: Shows the agenda or upcoming events, creates, updates, deletes or moves events, checks free/busy, and manages calendars using gws CLI."
allowed-tools: Bash(gws schema *), Bash(gws calendar +agenda *)
argument-hint: "[action description]"
---

# calendar (v3)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws calendar <resource> <method> [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws calendar +agenda` | List upcoming events across all calendars (`--today`, `--tomorrow`, `--week`, `--days <N>`, `--calendar <NAME>` to filter); read-only |
| `gws calendar +insert --summary <TEXT> --start <TIME> --end <TIME>` | Create a timed event (`--attendee <EMAIL>` adds a guest, `--meet` a Google Meet link) |

`gws calendar +<helper> --help` lists the other flags.

- `+agenda --calendar <NAME>` keeps every calendar whose name contains `<NAME>` (case-sensitive) or whose ID equals it.
- `+agenda` prints a table by default although its `--help` says json; pass `--format json` when parsing the result.
- `+insert` sends `--start` / `--end` as `dateTime`, so they take RFC 3339 date-times and the helper creates timed, non-recurring events only. For an all-day or recurring event, or a field without a flag, use `events insert`.
- `+insert --attendee` adds guests without asking Calendar to email them (`sendUpdates` is left unset). When the user wants invitations sent, use `events insert` with `sendUpdates` set to `all`.

## Key Resources

### events
- `list` — List events on a calendar.
- `get` — Get event by ID.
- `insert` / `patch` / `update` / `delete` — Manage events. `patch` changes only the fields sent; `update` replaces the whole event, so fields left out of the body are cleared.
- `quickAdd` — Create event from simple text string.
- `move` — Move event to another calendar.
- `instances` — List instances of recurring event.

### calendars
- `get` / `insert` / `patch` / `update` / `delete` / `clear` — Manage calendars.

### calendarList
- `list` / `get` / `insert` / `delete` / `patch` / `update` — Manage user's calendar list.

### freebusy
- `query` — Query free/busy information.

## Discovering Commands

```bash
gws calendar --help
gws schema calendar.<resource>.<method>
```
