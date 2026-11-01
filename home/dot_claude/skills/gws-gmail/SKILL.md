---
name: gws-gmail
description: "Gmail: Reads/searches messages and threads, or manages drafts/labels/settings using gws CLI — for sending an email (including HTML, attachments, CC/BCC) or an unread inbox summary, use gws-gmail-send or gws-gmail-triage instead."
allowed-tools: Read, Grep, Glob, Bash(gws schema *)
argument-hint: "[action description or search query]"
---

# gmail (v1)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws gmail <resource> <method> [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws gmail +send` | Send an email (see `gws-gmail-send` skill) |
| `gws gmail +triage` | Show unread inbox summary (see `gws-gmail-triage` skill) |

## Key Resources

### users
- `getProfile` — Get current user's Gmail profile.
- `messages` — List, get, send, trash, untrash, delete messages.
- `drafts` — List, get, create, update, send, delete drafts.
- `labels` — List, get, create, update, patch, delete labels.
- `threads` — List, get, trash, untrash, delete threads.
- `history` — List history of mailbox changes.
- `settings` — Manage user settings (filters, forwarding, etc.).

## Discovering Commands

```bash
gws gmail --help
gws schema gmail.<resource>.<method>
```
