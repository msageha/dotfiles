---
paths:
  - "**/mise.toml"
  - "**/.mise.toml"
  - "**/README.md"
  - "**/CONTRIBUTING.md"
---
# mise

- Entrypoint: In a repository whose `mise.toml` already defines tasks, define the setup / lint / test / build and similar operational commands you add or change as tasks there too, and document `mise run <task>` (not the raw command) as the entrypoint in README and how-to docs.
- Tools: In a repository that uses mise, declare the CLIs the repository relies on (e.g. `jq`, `gh`, `age`) under `[tools]` in `mise.toml`. If the repository uses Renovate, make sure it updates those version pins: configure a datasource for any tool its built-in mise manager cannot look up, and when `minimumReleaseAge` is set, pick a datasource that reports release timestamps, since by default Renovate holds back an update that has none.
- Python venv: In a repository that uses mise, put the project venv on PATH through `[env]` `_.python.venv = { path = ".venv" }` instead of documenting manual activation. Add `create = true` only when no setup step (e.g. `uv sync`) creates the venv.
