---
paths:
  - "**/*.jsx"
  - "**/*.tsx"
---
# React

- Components: Use functional components and hooks. No class components or legacy APIs (ReactDOM.render, createElement chains), except error boundaries, which React still cannot express as a function component: use react-error-boundary if the project has it, otherwise a single `ErrorBoundary` class.
- State Management: Keep state minimal and colocated. Lift to React Context or a store (e.g. Zustand) only when state is genuinely shared.
- Effects: Use useEffect only for real side effects, with correct dependency arrays and cleanup functions. Derive values during render instead of syncing them via effects.
- Composition: Pass JSX as `children` rather than drilling props through intermediate components.
- Data Fetching: Handle loading, error, and empty states explicitly. Ignore or cancel stale responses on unmount.
- Lists: Use stable, unique keys for dynamic lists. Do not use array indexes as keys for reorderable data.
- Accessibility: Use semantic elements and ARIA attributes. Ensure interactive components are keyboard-operable.
- Performance: Memoize (memo/useMemo/useCallback) only for measured bottlenecks. Reserve space for async content to avoid layout shifts (CLS).
- Routing: Navigate through a router instead of ad-hoc conditional rendering.
- Testing: When asked to write component tests, use React Testing Library only if the project already uses it; if no component test framework exists, report that and confirm before adding one; query by role/label and assert behavior, not implementation details.
