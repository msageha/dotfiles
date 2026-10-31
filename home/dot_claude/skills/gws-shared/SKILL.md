---
name: gws-shared
description: "gws CLI: Shared reference for authentication, global flags, output formatting, and when to confirm sends and writes. Read it before the first gws command in a task, or when a gws command fails with an auth or flag error."
user-invocable: false
allowed-tools: Bash(gws schema *)
---

# gws — Shared Reference

## Installation

The `gws` binary must be on `$PATH`.

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

## Global Flags

| Flag | Description |
|------|-------------|
| `--format <FORMAT>` | Output format: `json` (default), `table`, `yaml`, `csv` |
| `--dry-run` | Validate locally without calling the API |
| `--sanitize <TEMPLATE>` | Screen responses through a Model Armor template (requires cloud-platform scope) |

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

## Sends, Writes, and Content Screening

- Sending mail and writing or deleting data leave changes other people can see. Unless the user has stated the content and the recipient or target, show the `--dry-run` result (for mail, `--draft` also works) and confirm before running the real command.
- Model Armor screening applies only when a template is configured. If `GOOGLE_WORKSPACE_CLI_SANITIZE_TEMPLATE` is set, the CLI uses it as the default template and no flag is needed; otherwise pass `--sanitize` only when the user provides a template.
