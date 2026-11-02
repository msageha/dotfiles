---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.sh.tmpl"
  - "**/*.bats"
---
# Bash Shell (including bats tests)

- ShellCheck: Ensure scripts pass shellcheck validation.
- Error Handling: In scripts that are executed, use `set -euo pipefail`, and add trap-based cleanup when the script creates temp files or background processes. Files that are sourced (libraries, rc / profile files) leave the caller's shell options unchanged, because `set -eu` sourced into an interactive shell makes a single failing command or unset variable exit that shell.
- Variables: Quote all variable expansions. Handle paths with spaces.
- Ad-hoc / one-off scripts: keep them to the minimal structure the rules above require; add ceremony (getopts, logging frameworks, usage output, input validation) only when the script will be reused or shared.
- Maintained scripts with a CLI surface: parse arguments with getopts and print usage on misuse.
- Portability: Use `#!/usr/bin/env bash` (macOS ships bash 3.2 at /bin/bash). If the script must run under POSIX sh, use `#!/bin/sh` and avoid bashisms (check with `shellcheck -s sh`).
- Bats tests (`.bats`): Keep the `#!/usr/bin/env bats` shebang and leave out `set -euo pipefail`, since bats already runs each test with `set -e`. Check an expected failure with `run !` or with `run` plus a `$status` check, because `set -e` does not fire on a `!`-negated command. On Bats 1.7 or later, declare `bats_require_minimum_version 1.5.0` before `run !` (otherwise bats warns BW02); older Bats has no such command, so use the `$status` check there.
