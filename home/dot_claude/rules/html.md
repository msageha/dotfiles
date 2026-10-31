---
paths:
  - "**/*.html"
  - "**/*.htm"
  - "**/*.ejs"
  - "**/*.hbs"
---
# HTML

- Semantics: Use semantic elements (header, nav, main, section, footer, button) instead of generic divs and spans.
- Document Head: Set lang on <html>, charset, viewport meta tag, and a meaningful <title>.
- Accessibility: Provide alt text for images, label form controls, keep a logical heading hierarchy, and ensure keyboard operability and sufficient contrast.
- Dependencies: Add CSS / JS dependencies through the project's build pipeline, not ad-hoc CDN script/style tags.
- Forms: Use the input type that matches the value (email, number, date, ...), name attributes, and built-in validation attributes before reaching for custom JS validation.
- Images / Media: Specify dimensions (width/height or aspect-ratio) to avoid layout shifts. Use loading="lazy" for offscreen images. Provide fallbacks for external resources.
- Dialogs: Use <dialog> or an in-page message component instead of alert()/confirm().
- Templates (.ejs/.hbs): Escape user-provided data by default; use raw/unescaped output only for trusted, sanitized content.
- Validity: Keep markup valid per the HTML spec (checkable with the W3C Nu validator): no misnested elements, unique ids, no deprecated attributes.
