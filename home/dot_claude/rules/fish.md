---
paths:
  - "**/*.fish"
---
# Fish Shell

- Functions: Use named functions with proper argument handling. Prefer functions over aliases for complex operations.
- Variables: Use scope modifiers (-l, -g) deliberately; export (-x) only when child processes need the variable.
- Path Handling: Use path manipulation builtins instead of string operations.
- Error Handling: Check $status after critical commands.
- Completions: Provide tab completions for custom commands.
- Configuration: Store settings in config.fish or dedicated conf.d files.
