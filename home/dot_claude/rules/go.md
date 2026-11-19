---
paths:
  - "**/*.go"
  - "**/go.mod"
---
# Go

- Interfaces: Define small interfaces in the package that consumes them, only in the cases AGENTS.md「コード」 allows; a package that cannot import the implementation because of an import cycle counts as the layering case. Return concrete types. A test fake alone does not justify an interface: AGENTS.md「検証と完了」 forbids bending production code for tests (stricter than Go Code Review Comments), so test through the real implementation (e.g. against an httptest server).
- Package Structure: Avoid deep package hierarchies.
- Documentation: Write a godoc comment (starting with the symbol's name) for an exported symbol when its contract (behaviour, constraints, error cases) is not obvious from the name and signature, or when the project's linters or existing code document every exported symbol. This is narrower than go.dev's every-exported-name convention, following AGENTS.md「コード」 on comments.
- Testing: A test that calls only a package's exported API (a library's public API, or a lower-level test the Tests rule (`tests.md`) allows) needs no access to unexported code. In a new test file, put it in an external test package (`package <name>_test` in the same directory), which can reach only exported identifiers, unless the package's existing tests use the package itself. Prefer table-driven tests when several example cases share one check; use testify only if the project already uses it. Plain `go test` runs only a fuzz test's seed corpus, so count a fuzz test as a property-based test only where the project's usual verification actually fuzzes that target (with `go test`, a `-fuzz` pattern that selects it). Inside the fuzz callback, discard an input outside the property with `t.Skip`, and do not modify a `[]byte` argument; copy it before handing it to code that mutates it or keeps it after the callback returns.
