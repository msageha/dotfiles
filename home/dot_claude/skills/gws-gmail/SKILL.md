---
name: gws-gmail
description: "Gmail: Sends an email or saves it as a draft, shows unread mail, reads or searches messages and threads, replies or forwards, and manages drafts, labels and settings using gws CLI."
allowed-tools: Bash(gws schema *), Bash(gws gmail +triage *)
argument-hint: "[action description or search query]"
---

# gmail (v1)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws gmail users [<sub-resource>] <method> --params '{"userId": "me"}' [flags]
```

## Helper Commands

| Command | Description |
|---------|-------------|
| `gws gmail +send --to <EMAILS> --subject <SUBJECT> --body <TEXT>` | Send a new email, or save it as a draft with `--draft` (`--cc`, `--bcc`, `-a <PATH>` to attach a file, `--html`, `--from <EMAIL>` for a send-as alias) |
| `gws gmail +triage` | List unread messages (sender, subject, date); read-only |
| `gws gmail +read --id <ID>` | Print a message's decoded body (`--headers` adds the headers) |
| `gws gmail +reply --message-id <ID> --body <TEXT>` | Reply in the original thread, quoting the message (`+reply-all`: same flags, all recipients) |
| `gws gmail +forward --message-id <ID> --to <EMAILS>` | Forward a message, with its attachments by default |

Use a helper when one covers the task: the raw `users` methods return and take message content base64url-encoded, and `+send` sets no threading headers, so reply with `+reply` / `+reply-all`. `gws gmail --help` lists every helper, and `gws gmail +<helper> --help` its other flags.

- `+send --html` takes fragment tags (`<p>`, `<b>`, `<a>`, `<br>`) in `--body`; no `<html>` / `<body>` wrapper is needed. Attachments are limited to 25 MB in total.
- `+triage --query <QUERY>` replaces the default `is:unread`, so include `is:unread` in the query to keep the unread filter. It lists at most `--max` messages (default 20).
- `+triage` prints a table by default although the `--format` help says json; pass `--format json` when parsing the result.

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
gws schema gmail.users[.<sub-resource>].<method>
```
