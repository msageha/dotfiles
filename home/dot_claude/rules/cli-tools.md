---
# CLI アプリケーション本体 (エントリポイント配置の慣習ディレクトリ) に限定する。
# 全 .sh/.go/.py に適用すると、単発スクリプトやフックにまで subcommand /
# 複数出力形式 / ページングなどのアプリ要件を要求してしまう
# (言語ごとの基本規約は bash.md / go.md / python.md が別途カバーする)
paths:
  - "**/cmd/**"
  - "**/cli/**"
---
# Command Line Tools

These requirements apply to CLI applications, not to ad-hoc scripts or hooks.

- User Interface: Implement consistent CLI patterns (subcommands, flags, arguments).
- Help Documentation: Include --help output with examples and option descriptions.
- Input Validation: Validate all user inputs before processing.
- Error Handling: Display clear error messages. Return appropriate exit codes.
- Progress Indicators: Show progress for long-running operations.
- Color Output: Use ANSI colors for differentiated output (but respect NO_COLOR environment variable).
- Logging: Implement proper logging with verbosity levels.
- Configuration: Support config files and environment variables.
- Signal Handling: Implement proper cleanup on SIGINT and SIGTERM.
- Output Formatting: Support multiple output formats (plain text, JSON, CSV).
- Pagination: Implement paging for large outputs.
- Performance: Optimize for speed and memory usage.
- Testing: Include unit and integration tests.
- Follow POSIX argument conventions (-h, --help).
- Provide feedback on command success/failure.
