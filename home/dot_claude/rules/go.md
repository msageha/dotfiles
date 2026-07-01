---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
---
# Go

- Error Handling: Return errors explicitly. Use errors.Is() and errors.As() for checking.
- Naming: Follow Go naming conventions (CamelCase for exported, camelCase for unexported).
- Package Structure: Organize by domain functionality. Avoid deep hierarchies.
- Interfaces: Keep interfaces small and focused. Define them where they're used.
- Concurrency: Use goroutines and channels appropriately. Implement proper synchronization.
- Error Values: Create custom error types with meaningful context.
- Testing: Include table-driven tests. Use testify for assertions if needed.
- Documentation: Add godoc-compatible comments for all exported symbols.
- Dependency Injection: Pass dependencies explicitly rather than using global state.
- Resource Management: Use defer for cleanup operations.
- Error Wrapping: Use fmt.Errorf() with %w for wrapping errors.
- Context: Pass context.Context as the first parameter for cancelable operations.
- Struct Organization: Group related fields together. Use embedding judiciously.
- Avoid Interface Pollution: Only create interfaces when needed for testing or flexibility.
- Follow idiomatic Go style without excessive abstraction.
