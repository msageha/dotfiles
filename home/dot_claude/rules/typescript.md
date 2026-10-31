---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---
# TypeScript

- Type Safety: Avoid `any` and type assertions; prefer precise types, generics, and `unknown` with narrowing.
- Interface vs Type: Use interfaces for objects that can be extended, types for unions and intersections.
- Module System: Use ES modules (import/export) with named exports, except where a framework or tool requires a default export (e.g. Next.js pages, components loaded with React.lazy, `vite.config.*`). Avoid namespace syntax.
- Config: Enable strict mode in tsconfig.json for new projects.
