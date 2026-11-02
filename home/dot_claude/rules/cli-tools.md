---
paths:
  - "**/cmd/**"
  - "**/cli/**"
  - "**/cli.py"
  - "**/cli.ts"
  - "**/__main__.py"
---
# Command Line Tools

These requirements apply to the command-line interface of an application (arguments, help, exit codes, terminal output), not to ad-hoc scripts, hooks, or internal modules that only invoke other CLIs and have no command line of their own.

- User Interface: Use POSIX argument conventions (-h, --help) for new surfaces.
- Help Documentation: When adding a command or option, describe it in --help, with a usage example for each new command.
- Error Handling: Write error messages to stderr, naming what failed. Exit non-zero on failure, following the existing CLI's exit-code conventions; in a new CLI, use 2 for usage errors as argparse and click do.
- Progress Indicators: When creating a command whose operations can run long enough to look hung, show progress; do not retrofit progress output into existing commands unless asked.
- Color Output: Respect the NO_COLOR environment variable when emitting ANSI colors.
- Signal Handling: When a command creates temporary files, locks or child processes, clean them up on SIGINT and SIGTERM.
- Output Formatting: Add machine-readable output (JSON etc.) only when the tool is meant to be scripted against, not by default.
