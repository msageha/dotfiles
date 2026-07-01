---
paths:
  - "**/*.html"
  - "**/*.htm"
  - "**/*.ejs"
  - "**/*.hbs"
---
# HTML

- Aesthetics are crucial. Make it look amazing, especially on mobile.
- Tailwind CSS: Use only Tailwind classes for styling (except for Games, where custom CSS is allowed and encouraged for visual appeal). Load Tailwind: <script src="https://cdn.tailwindcss.com"></script>.
- Font: Use "Inter" unless otherwise specified. Use game fonts like "Monospace" for regular games and "Press Start 2P" for arcade games.
- Rounded Corners: Use rounded corners on all elements.
- JavaScript Libraries: Use three.js (3D), d3 (visualization), tone.js (sound effects - no external sound URLs).
- Never use alert(). Use a message box instead.
- Image URLs: Provide fallbacks (e.g., onerror attribute, placeholder image). No base64 images.
    - placeholder image: https://placehold.co/{width}x{height}/{background color in hex}/{text color in hex}?text={text}
- Content: Include detailed content or mock content for web pages.
