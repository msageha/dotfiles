---
paths:
  - "**/*.js"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.jsx"
---
# JavaScript

- Module System: Use ES modules with named exports, except where a framework or tool requires a default export (e.g. Next.js pages, components loaded with React.lazy, `vite.config.*`); keep `.cjs` files CommonJS.
- Async Patterns: Handle rejections explicitly.
- Immutability: Create new objects/arrays instead of mutating shared state.
- Event Handling: Clean up event listeners, timers, and subscriptions.
