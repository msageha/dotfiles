---
name: playwright
description: "Playwright: browser automation, E2E testing, and web application testing. Covers CLI-first automation, test generation, debugging, and CI/CD patterns for TypeScript and JavaScript projects."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [URL, scenario description, or test file path]
---

# Playwright Skill

Browser automation and E2E testing using Playwright. Supports CLI-first automation and `@playwright/test` for structured test suites.

## Decision Tree

```
User task -> Is it browser automation (scraping, form fill, debugging)?
    |-- Yes -> CLI-first approach (see CLI Workflow below)
    |
    |-- No -> Did the user ask for test code (test generation / E2E suite)?
        |-- Yes -> @playwright/test approach (read references/test-writing.md)
        |
        |-- No -> Is it a local webapp to verify?
            |-- Yes -> Reconnaissance-then-action:
                1. Start server if needed
                2. Navigate and wait for networkidle
                3. Take screenshot or inspect DOM
                4. Identify selectors from rendered state
                5. Execute actions with discovered selectors
```

## Golden Rules

1. **`getByRole()` over CSS/XPath** -- resilient to markup changes, mirrors how users see the page.
2. **Never `page.waitForTimeout()`** -- use `expect(locator).toBeVisible()` or `page.waitForURL()`.
3. **Web-first assertions** -- `expect(locator)` auto-retries; `expect(await locator.textContent())` does not.
4. **Isolate every test** -- no shared state, no execution-order dependencies.
5. **`baseURL` in config** -- zero hardcoded URLs in tests.
6. **Retries: `2` in CI, `0` locally** -- surface flakiness where it matters.
7. **Traces: `'on-first-retry'`** -- rich debugging artifacts without CI slowdown.
8. **Fixtures over globals** -- share state via `test.extend()`, not module-level variables.
9. **One behavior per test** -- multiple related `expect()` calls are fine.
10. **Mock external services only** -- never mock your own app; mock third-party APIs, payment gateways, email.
11. **Test user-visible behavior, not implementation details** -- assert on what the user sees and does, never on internal state or DOM structure.

## CLI Workflow (Playwright MCP or playwright-cli)

When a Playwright MCP server is available, the interaction loop is:

```
1. Navigate to the target URL
2. Take a snapshot to get element references
3. Interact using refs from the snapshot (click, fill, type)
4. Re-snapshot after navigation or significant DOM changes
5. Capture artifacts (screenshot, PDF) when useful
```

**Re-snapshot after:** navigation, UI-changing clicks, modal open/close, tab switches. Refs go stale -- if a command fails, snapshot again.

### Common CLI Patterns

**Form fill:**
```
open URL -> snapshot -> fill fields -> click submit -> snapshot -> screenshot
```

**Debug a UI flow:**
```
open URL (headed) -> snapshot -> interact -> capture console/network logs -> screenshot
```

**Data extraction:**
```
open URL -> snapshot -> evaluate JS to extract text/data
```

## Debugging

1. **UI Mode:** `npx playwright test --ui` -- visual test runner with time-travel debugging.
2. **Trace Viewer:** `npx playwright show-trace trace.zip` -- inspect snapshots, network, console.
3. **Headed mode:** `npx playwright test --headed` -- watch the browser.
4. **Console/Network:** Capture logs via `page.on('console', ...)` and `page.on('request', ...)`.
5. **Codegen:** `npx playwright codegen URL` -- record interactions and generate test code.

## Reference files (read only when needed)

- `references/test-writing.md` -- `@playwright/test` config, locator priority, test structure, Page Object Model, auth state reuse, network mocking, GitHub Actions CI snippet, and a Python quick-check snippet for local webapps. Read when writing test code, `playwright.config.ts`, or CI config.
