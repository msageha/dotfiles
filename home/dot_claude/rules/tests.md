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
- Isolation: Run against temporary directories and fixtures; never write to real data in the repository or to production output locations.
