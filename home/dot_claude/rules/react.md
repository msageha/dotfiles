---
paths:
  - "**/*.jsx"
  - "**/*.tsx"
---
# React

- Components: Use functional components and hooks. No class components or legacy APIs (ReactDOM.render, createElement chains).
- State Management: Keep state minimal and colocated. Lift to React Context or a store (e.g. Zustand) only when state is genuinely shared.
- Effects: Use useEffect only for real side effects, with correct dependency arrays and cleanup functions. Derive values during render instead of syncing them via effects.
- Composition: Prefer small, composable components over deep prop drilling or premature abstraction.
- Data Fetching: Handle loading, error, and empty states explicitly. Ignore or cancel stale responses on unmount.
- Lists: Use stable, unique keys for dynamic lists. Do not use array indexes as keys for reorderable data.
- Accessibility: Use semantic elements and ARIA attributes. Ensure interactive components are keyboard-operable.
- Performance: Memoize (memo/useMemo/useCallback) only for measured bottlenecks. Reserve space for async content to avoid layout shifts (CLS).
- Styling / UI: Follow the project's existing styling and component conventions (e.g. Tailwind, shadcn/ui, CSS Modules). Do not introduce a new styling approach unilaterally.
- Routing: Use the project's established router and navigation patterns rather than ad-hoc conditional rendering.
- Testing: Use React Testing Library; query by role/label and assert behavior, not implementation details.
