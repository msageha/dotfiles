---
name: gws-slides
description: "Google Slides: Read and write presentations using gws CLI."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [presentation ID or action description]
---

# slides (v1)

> **PREREQUISITE:** See `gws-shared` skill for auth, global flags, and security rules.

```bash
gws slides <resource> <method> [flags]
```

## Key Resources

### presentations
- `get` — Get the latest version of a presentation.
- `create` — Create a blank presentation with a title.
- `batchUpdate` — Apply updates (add slides, insert text, images, etc.).
- `pages` — Get page/slide details (get, getThumbnail).

## Discovering Commands

```bash
gws slides --help
gws schema slides.<resource>.<method>
```
