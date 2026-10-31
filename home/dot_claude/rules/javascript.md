---
paths:
  - "**/*.js"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.jsx"
---
# JavaScript

- Module System: Use ES modules with named exports, except where a framework or tool requires a default export (e.g. Next.js pages, components loaded with React.lazy, `vite.config.*`); `.cjs` files are CommonJS by definition — keep them CommonJS.
- Variable Declarations: Prefer const, then let. Never use var.
- Async Patterns: Use async/await instead of callbacks or promise chains. Handle rejections explicitly.
- Immutability: Create new objects/arrays instead of mutating shared state.
- Event Handling: Clean up event listeners, timers, and subscriptions.
