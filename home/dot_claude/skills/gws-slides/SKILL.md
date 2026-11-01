---
name: gws-slides
description: "Google Slides: Reads and writes presentations using gws CLI."
allowed-tools: Read, Grep, Glob, Bash(gws schema *)
argument-hint: "[presentation ID or action description]"
---

# slides (v1)

Before the first gws command, read the `gws-shared` skill (`../gws-shared/SKILL.md`) for auth, global flags, and when to confirm sends and writes.

```bash
gws slides <resource> <method> [flags]
```

## Key Resources

### presentations
- `get` — Get the latest version of a presentation.
- `create` — Create a blank presentation with a title.
- `batchUpdate` — Apply updates (add slides, insert text, images, etc.).
- `pages` — Get page/slide details (get, getThumbnail).

## Writing Content

- Keep decks short: one message per slide and as few slides as the content needs; move detail tables and architecture diagrams to appendix slides.
- Convert Markdown to native text styles via `presentations.batchUpdate`; never paste Markdown syntax (`#`, `**`, `|`) as slide text.

## Discovering Commands

```bash
gws slides --help
gws schema slides.<resource>.<method>
```
