---
paths:
  - "**/*.fish"
  - "**/*.fish.tmpl"
---
# Fish Shell

- Functions: Parse options with `argparse` when a function takes flags. Prefer functions over aliases for complex operations.
- Variables: Declare a function's own variables with `set -l` at the function's top level (`-l` is scoped to the enclosing block, so use `-f` for a variable first set inside a block and read after it) and set or erase globals with `-g`, because without a scope flag `set` acts on an existing variable of that name in its narrowest scope, global and universal included; export (`-x`) only when child processes need the variable.
- Path Handling: Use path manipulation builtins instead of string operations.
- Error Handling: Stop when a command that later steps depend on fails (`<command>; or return 1`) instead of continuing.
- Configuration: Store settings in config.fish or dedicated conf.d files.
