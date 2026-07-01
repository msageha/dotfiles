---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# TypeScript

- Type Safety: Always use proper type annotations. Avoid 'any' type unless absolutely necessary.
- Interface vs Type: Use interfaces for objects that can be extended, types for unions and intersections.
- Nullability: Use optional chaining (?.) and nullish coalescing (??) operators for null safety.
- Async Code: Use async/await pattern rather than raw promises. Always handle rejections.
- Generics: Implement generic types for reusable components and functions.
- Module System: Use ES modules (import/export). Avoid namespace syntax.
- Config: Include tsconfig.json with strict mode enabled if necessary.
- Code Organization: Follow feature-based structure. Group related functionality.
- Testing: Include Jest/Mocha test cases with proper mocking.
- Linting: Follow ESLint + Prettier standards with consistent spacing and semicolons.
- Include comprehensive type definitions and avoid type assertions.
