---
paths:
  - "**/mise.toml"
  - "**/.mise.toml"
  - "**/README.md"
  - "**/CONTRIBUTING.md"
---
# mise

- Entrypoint: In a repository whose `mise.toml` already defines tasks, define the setup / lint / test / build and similar operational commands you add or change as tasks there too, and document `mise run <task>` (not the raw command) as the entrypoint in README and how-to docs.
- Python venv: Put the project venv on PATH through `[env]` `_.python.venv = { path = ".venv", create = true }` instead of documenting manual activation.
