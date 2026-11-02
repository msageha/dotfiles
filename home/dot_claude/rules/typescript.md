---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
  - "**/*.astro"
---
# TypeScript

- Type Safety: Avoid `any` and type assertions; prefer precise types, generics, and `unknown` with narrowing.
- Interface vs Type: Use an interface for an object shape and a type alias only for what an interface cannot express (unions, intersections, mapped and conditional types), so that object shapes use one form and extending one with `extends` reports conflicting members.
- Module System: Use ES modules (import/export) with named exports, except where a framework or tool requires a default export (e.g. Next.js pages, components loaded with React.lazy, `vite.config.*`). Avoid namespace syntax.
- Config: Enable strict mode in tsconfig.json for new projects.
