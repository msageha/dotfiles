---
paths:
  - "**/mise.toml"
  - "**/.mise.toml"
  - "**/README.md"
  - "**/CONTRIBUTING.md"
---
# mise (mise.toml, and the task entrypoints documented in README / CONTRIBUTING)

- Entrypoint: In a repository whose `mise.toml` already defines tasks, define the setup / lint / test / build and similar operational commands you add or change as tasks there too, and document `mise run <task>` (not the raw command) as the entrypoint in README and how-to docs.
- Tools: In a repository that uses mise, declare the CLIs the repository relies on (e.g. `jq`, `gh`, `age`) under `[tools]` in `mise.toml`. If the repository uses Renovate, make sure it updates those version pins, adding a custom datasource or a minimum release age where its built-in mise support does not cover them.
- Python venv: Put the project venv on PATH through `[env]` `_.python.venv = { path = ".venv", create = true }` instead of documenting manual activation.
