---
paths:
  - "**/.gitignore"
---
# gitignore

- Whitelist Format: When creating a `.gitignore`, ignore everything (`*`) and allow tracked paths with `!`. Allow each parent directory as well as the paths under it (`!/<dir>/`, `!/<dir>/**`), because git does not descend into an ignored directory, and re-ignore what must stay untracked inside an allowed directory (secrets, caches, build output) after the allow lines, because the last matching pattern wins. When editing an existing one, keep its style and add entries in that style; convert a blacklist-style file to whitelist only when asked.
