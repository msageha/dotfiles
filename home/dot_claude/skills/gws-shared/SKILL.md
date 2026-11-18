---
name: gws-shared
description: "gws CLI: Shared reference for authentication, global flags, output formatting, and when to confirm sends and writes. Read it before the first gws command in a task, or when a gws command fails with an auth or flag error."
user-invocable: false
allowed-tools: Bash(gws auth status)
---

# gws — Shared Reference

## Authentication

```bash
# Show the current authentication state
gws auth status

# Browser-based OAuth (interactive; opens a browser)
gws auth login

# Credentials file (OAuth or service account JSON). Set it on the same command line,
# because an exported variable does not persist between shell calls.
GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/path/to/key.json gws drive files list
```

- Credential precedence: `GOOGLE_WORKSPACE_CLI_TOKEN` (raw access token) > `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE` > credentials saved by `gws auth login` > Application Default Credentials (`GOOGLE_APPLICATION_CREDENTIALS`, then the gcloud ADC file).
- `gws auth export` prints decrypted credentials to stdout; use `gws auth status` to check auth instead.
- API commands, `--dry-run` included, load the saved encrypted credentials before sending the request, and delete them and the token caches when decryption fails, as happens in a sandbox that cannot reach the OS keyring (gws 0.22.5). `gws auth status` resolves the same encryption key (and creates one when the keyring has none), so it is not a side-effect-free probe. Run `gws` with saved credentials only where their encryption key is accessible (the OS keyring, or the `.encryption_key` file of the file backend), and after a keyring or decryption error, do not retry in the same environment.

## Global Flags

| Flag | Description |
|------|-------------|
| `--format <FORMAT>` | Output format: `json` (default), `table`, `yaml`, `csv` |
| `--dry-run` | Validate locally without calling the API |

## CLI Syntax

```bash
gws <service> <resource> [sub-resource] <method> [flags]
```

### Method Flags

| Flag | Description |
|------|-------------|
| `--params '{"key": "val"}'` | URL/query parameters |
| `--json '{"key": "val"}'` | Request body |
| `-o, --output <PATH>` | Save binary responses to file |
| `--upload <PATH>` | Upload file content (multipart) |
| `--page-all` | Auto-paginate (NDJSON output) |
| `--page-limit <N>` | Max pages when using --page-all (default: 10) |
| `--page-delay <MS>` | Delay between pages in ms (default: 100) |

## Sends and Writes

- Sending mail and writing or deleting data leave changes other people can see. Unless the user has asked for this send or write and stated its content and its recipient or target, show the `--dry-run` result (for mail, show the recipients, subject and body or save a draft with `--draft` instead, because the mail helpers' `--dry-run` output does not contain the message) and confirm before running the real command. Changes to sharing or access permissions always follow the AGENTS.md `安全` section: show the current and resulting entries and confirm, even when the request is specific.
- To delete, use the recoverable method where the API has one: Gmail `trash`, Drive `files update` with body `{"trashed": true}`. The `delete` methods of Gmail messages / threads and Drive files erase the item permanently, bypassing the trash; use them only when the user asks for permanent deletion.
