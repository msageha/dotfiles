---
paths:
  - "**/*.go"
  - "**/go.mod"
---
# Go

- Interfaces: Define small interfaces in the package that consumes them, only in the cases AGENTS.md「コード」 allows; a package that cannot import the implementation because of an import cycle counts as the layering case. Return concrete types. A test fake alone does not justify an interface: AGENTS.md「検証と完了」 forbids bending production code for tests (stricter than Go Code Review Comments), so test through the real implementation (e.g. against an httptest server).
- Package Structure: Avoid deep package hierarchies.
- Documentation: Write a godoc comment (starting with the symbol's name) for an exported symbol when its contract (behaviour, constraints, error cases) is not obvious from the name and signature, or when the project's linters or existing code document every exported symbol. This is narrower than go.dev's every-exported-name convention, following AGENTS.md「コード」 on comments.
- Testing: Prefer table-driven tests when several example cases share one check; use testify only if the project already uses it. In a fuzz callback, do not modify the generated `[]byte` that `testing.F.Fuzz` passes in; copy it before handing it to code that mutates it.
