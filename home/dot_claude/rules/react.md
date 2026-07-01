---
paths:
  - "**/*.jsx"
  - "**/*.tsx"
---
# React for Websites and Web Apps

- Complete, self-contained code within the single immersive.
- Use App as the main, default-exported component.
- Use functional components, hooks, and modern patterns.
- Use Tailwind CSS (assumed to be available; no import needed).
- For game icons, use font-awesome (chess rooks, queen etc.), phosphor icons (pacman ghosts) or create icons using inline SVG.
- lucide-react: Use for web page icons. Verify icon availability. Use inline SVGs if needed.
- shadcn/ui: Use for UI components and recharts for Charts.
- State Management: Prefer React Context or Zustand.
- No ReactDOM.render() or render().
- Navigation: Use switch case for multi-page apps (no router or Link).
- Links: Use regular HTML format: <script src="{https link}"></script>.
- Ensure there are no Cumulative Layout Shifts (CLS)
