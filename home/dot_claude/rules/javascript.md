---
paths:
  - "**/*.js"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.jsx"
---
# JavaScript

- Module System: Use ES modules with named exports (`.cjs` files are CommonJS by definition — keep them CommonJS).
- Variable Declarations: Prefer const, then let. Never use var.
- Async Patterns: Use async/await instead of callbacks or promise chains. Handle rejections explicitly.
- Immutability: Create new objects/arrays instead of mutating shared state.
- Event Handling: Clean up event listeners, timers, and subscriptions.
- Testing: Use the project's existing test runner (Vitest, Jest, node:test, ...) and its patterns; do not introduce a new one.
- Formatting: Follow the project's formatter configuration.
