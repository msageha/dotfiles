---
paths:
  - "**/*.html"
  - "**/*.astro"
  - "**/*.jsx"
  - "**/*.tsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.htm"
  - "**/*.ejs"
  - "**/*.hbs"
---
# Web UI (templates, components, stylesheets)

- UI Consistency: Give screens and similar features the same look and behaviour so they can be used without explanatory text; keep explanations minimal, in wording a non-specialist understands, with hover hints (tooltips) where a control needs one, and keep decoration restrained.
- Dialogs: Use <dialog> or an in-page message component instead of alert()/confirm().
- Hand-off: After changing UI, start the project's dev server (or another local server or playground with sample data) and give the user the URL to try the change themselves, in addition to (not instead of) checking it yourself in a real browser. In a non-interactive run (a subagent, `codex exec` and the like), stop any server you started before finishing and report the command that starts it instead of a URL, so no background process is left behind.
