---
name: gws-drive
description: "Google Drive: Manage files, folders, and shared drives using gws CLI."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [file ID, search query, or action description]
---

# drive (v3)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

```bash
gws drive <resource> <method> [flags]
```

## Key Resources

### files
- `list` — List files. Supports `q` parameter for search. Returns trashed files by default (`trashed=false` to exclude).
- `get` — Get file metadata or content by ID. Use `alt=media` for content. For Google Docs/Sheets/Slides, use `export` instead.
- `create` — Create a file (up to 5,120 GB).
- `copy` — Copy a file with patch semantics.
- `update` — Update metadata/content.
- `export` — Export Google Workspace document to requested MIME type (max 10 MB).
- `download` — Download file content.

### drives
- `list` — List shared drives. Supports `q` for search.
- `get` / `create` / `update` — Manage shared drives.

### permissions
- `list` / `get` / `create` / `update` / `delete` — Manage file/drive sharing.

### comments / replies
- CRUD operations on file comments and replies.

## Discovering Commands

```bash
gws drive --help
gws schema drive.<resource>.<method>
```
