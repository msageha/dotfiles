---
paths:
  - "**/cmd/**"
  - "**/cli/**"
---
# Command Line Tools

These requirements apply to CLI applications, not to ad-hoc scripts or hooks.

- User Interface: Follow the project's existing CLI framework and subcommand/flag patterns. Use POSIX argument conventions (-h, --help) for new surfaces.
- Help Documentation: Include --help output with examples and option descriptions.
- Error Handling: Display clear error messages. Return appropriate exit codes.
- Progress Indicators: Show progress for long-running operations.
- Color Output: Respect the NO_COLOR environment variable when emitting ANSI colors.
- Signal Handling: Implement proper cleanup on SIGINT and SIGTERM.
- Output Formatting: Add machine-readable output (JSON etc.) only when the tool is meant to be scripted against, not by default.
- Testing: Follow the project's existing test framework and patterns.
