---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Go

- Error Handling: Return errors explicitly. Check with errors.Is()/errors.As(). Wrap with fmt.Errorf() and %w. Create custom error types when callers need context.
- Interfaces: Keep interfaces small and focused. Define them where they're used. Only create them when needed for testing or flexibility.
- Package Structure: Organize by domain functionality. Avoid deep hierarchies.
- Dependency Injection: Pass dependencies explicitly rather than using global state.
- Context: Pass context.Context as the first parameter for cancelable operations.
- Documentation: Add godoc-compatible comments for exported symbols.
- Testing: Prefer table-driven tests, following the project's existing patterns (use testify only if the project already uses it).
