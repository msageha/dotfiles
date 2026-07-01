---
name: gws-calendar
description: "Google Calendar: Manage calendars and events using gws CLI."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [action description]
---

# calendar (v3)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

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
