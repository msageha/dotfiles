---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# TypeScript

- Type Safety: Avoid `any` and type assertions; prefer precise types, generics, and `unknown` with narrowing.
- Interface vs Type: Use interfaces for objects that can be extended, types for unions and intersections.
- Module System: Use ES modules (import/export). Avoid namespace syntax.
- Config: Enable strict mode in tsconfig.json for new projects.
- Testing: Use the project's existing test runner and patterns; do not introduce a new framework.
- Linting: Follow the project's ESLint / Prettier (or Biome) configuration.
