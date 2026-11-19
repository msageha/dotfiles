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
- Names: Within the project's naming convention, name each test (or table case / subtest) after the behavior it checks: the condition and the expected outcome in the specification's terms, so the names read as what the code under test must do. Do not name it after the function or the implementation steps.
- Isolation: Run against temporary directories and fixtures; never write to real data in the repository or to production output locations.
- Regression Tests: When asked to add a test for a bug fix, confirm that it fails on the code before the fix because of the bug (not because of an import or fixture error) and passes after the fix; a test that passes either way does not detect the bug.
- Test Doubles: Run the code under test for real. Replace a dependency with a fake or mock only where the real one cannot be controlled, must not be reached, or cannot safely produce the condition under test (external services, the clock, randomness, a dependency's failure), and replace it at an existing boundary. Fix the time and random values an assertion depends on; for property-based or generated-input tests, keep the generation and make failing inputs reproducible instead.
