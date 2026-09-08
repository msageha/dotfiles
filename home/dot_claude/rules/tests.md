---
paths:
  - "**/tests/**"
  - "**/test/**"
  - "**/__tests__/**"
  - "**/*_test.*"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*.py"
  - "**/conftest.py"
---
# Tests

- Creation: Add or extend tests only when the user asked for them; repairing an existing test that your change broke, or one that fails on every run, is in scope (AGENTS.md 検証・完了条件).
- Coverage: When asked to write tests, cover normal, error and boundary cases and assert externally observable behavior; do not pin implementation strings or unreachable branches.
- Isolation: Run against temporary directories and fixtures; never write to real data in the repository or to production output locations.
- Follow the project's existing framework, layout and naming (see the language rule for defaults).
