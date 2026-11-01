---
name: gws-calendar
description: "Google Calendar: Lists/queries calendars, updates/deletes/moves events, manages calendar lists, and checks free/busy using gws CLI — for creating an event or a quick cross-calendar agenda, use gws-calendar-insert or gws-calendar-agenda instead."
allowed-tools: Read, Grep, Glob, Bash(gws schema *)
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
| `gws calendar +agenda` | Show upcoming events (see `gws-calendar-agenda` skill) |
| `gws calendar +insert` | Create a new event (see `gws-calendar-insert` skill) |

## Key Resources

### events
- `list` — List events on a calendar.
- `get` — Get event by ID.
- `insert` / `update` / `patch` / `delete` — Manage events.
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
