---
name: gws-gmail
description: "Gmail: Send, read, and manage email using gws CLI."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [action description or search query]
---

# gmail (v1)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

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
