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

- Coverage: When asked to write tests, cover normal, error and boundary cases and assert externally observable behavior; do not pin implementation strings or unreachable branches.
- Names: Within the project's naming convention, name each test (or table case / subtest) after the behavior it checks, as the condition and the expected outcome in the terms of the specification, so that the test names read as what the code under test must do; do not name it after the function or the implementation steps.
- Isolation: Run against temporary directories and fixtures; never write to real data in the repository or to production output locations.
