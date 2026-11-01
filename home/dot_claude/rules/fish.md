---
paths:
  - "**/*.fish"
---
# Fish Shell

- Functions: Use named functions, and parse options with `argparse` when a function takes flags. Prefer functions over aliases for complex operations.
- Variables: Use scope modifiers (-l, -g) deliberately; export (-x) only when child processes need the variable.
- Path Handling: Use path manipulation builtins instead of string operations.
- Error Handling: Stop when a command that later steps depend on fails (`command; or return 1`) instead of continuing.
- Configuration: Store settings in config.fish or dedicated conf.d files.
