---
paths:
  - "**/*.go"
  - "**/go.mod"
---
# Go

- Error Handling: Return errors explicitly. Check with errors.Is()/errors.As(). Wrap with fmt.Errorf() and %w. Create custom error types when callers need context.
- Interfaces: Define small interfaces in the package that consumes them, and only when a consumer must accept more than one real implementation; return concrete types. A test fake alone does not justify one: AGENTS.md「検証と完了」 forbids bending production code for tests, which is stricter than Go Code Review Comments, so test through the real implementation (e.g. against an httptest server).
- Package Structure: Avoid deep package hierarchies.
- Dependency Injection: Pass dependencies explicitly rather than using global state.
- Context: Pass context.Context as the first parameter for cancelable operations.
- Documentation: Write a godoc comment (starting with the symbol's name) for an exported symbol when its contract (behaviour, constraints, error cases) is not obvious from the name and signature, or when the project's linters or existing code document every exported symbol. This is narrower than go.dev's every-exported-name convention, following AGENTS.md「コード」 on comments.
- Testing: Prefer table-driven tests; use testify only if the project already uses it.
