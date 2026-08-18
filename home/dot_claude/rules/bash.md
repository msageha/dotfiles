---
paths:
  - "**/*.sh"
  - "**/*.bash"
---
# Bash Shell

- ShellCheck: Ensure scripts pass shellcheck validation.
- Error Handling: Use `set -euo pipefail`. Add trap-based cleanup when the script creates temp files or background processes.
- Variables: Quote all variable expansions. Handle paths with spaces.
- Ad-hoc / one-off scripts: keep them to the minimal structure the rules above require; add ceremony (getopts, logging frameworks, usage output, input validation) only when the script will be reused or shared.
- Maintained scripts with a CLI surface: parse arguments with getopts and print usage on misuse.
- Portability: Specify #!/bin/bash, and avoid bashisms only if POSIX compliance is needed.
