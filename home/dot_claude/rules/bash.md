---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/Makefile"
---
# Bash Shell

- ShellCheck: Ensure scripts pass shellcheck validation.
- Error Handling: Use set -e and trap for proper error management.
- Input Validation: Always validate and sanitize user inputs.
- Variables: Use meaningful variable names. Quote all variable expansions.
- Functions: Implement modular functions with local variables.
- Comments: Document script purpose, usage, and parameter details.
- Path Handling: Use proper path manipulation techniques.
- Command Substitution: Prefer $(command) over backticks.
- File Operations: Use -f, -d flags for file tests. Handle spaces in filenames.
- Options: Implement getopts for command-line arguments.
- Exit Codes: Use meaningful exit codes and check return values.
- Portability: Specify #!/bin/bash and avoid bashisms if POSIX compliance is needed.
- Logging: Implement proper logging with timestamps and log levels.
- Avoid hardcoded paths. Use configuration files or environment variables.
- Include usage/help information and proper error messages.
