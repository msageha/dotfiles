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
  - "**/*.vue"
  - "**/*.svelte"
---
# Web UI (templates, components, stylesheets)

- UI Consistency: Give screens and similar features the same look and behaviour so they can be used without explanatory text; keep explanations minimal, in wording a non-specialist understands, with hover hints (tooltips) where a control needs one, and keep decoration restrained.
- Dialogs: Use <dialog> or an in-page message component instead of alert()/confirm().
- Screen States: Show the loading, error and empty states a view can actually reach; an empty state says why it is empty and what the user can do next, where known. Prevent a duplicate submission while a request is pending, from every way of submitting (button, Enter key), where sending twice would cause harm; this does not replace making the server side safe to run twice.
- Forms: Show a field's error next to that field with how to fix it, and errors that involve several fields or the whole submission at the form; keep what the user entered when submission fails, except passwords and other secrets. Where an error would reveal something the user may not know (whether an account exists, on a sign-in or reset form), show one message for the whole form and return the same response (status, redirect) either way. Checks in the browser are for the user's convenience and do not replace the server's validation.
- Destructive Actions: Before an action that cannot be undone (a permanent delete, a payment), show what will be lost or changed and ask for confirmation, unless the flow already shows that on the final step and its control names the action (Delete, Pay); where an existing undo reverses all of the action's effects, offer it instead of a confirmation.
- Hand-off: After changing UI, start the project's dev server (or another local server or playground with sample data) and give the user the URL to try the change themselves, in addition to (not instead of) checking it yourself in a real browser. In a non-interactive run (a subagent, `codex exec` and the like), stop any server you started before finishing and report the command that starts it instead of a URL, so no background process is left behind.
