---
name: playwright
description: "Writes, fixes, and debugs Playwright tests (@playwright/test) for TypeScript and JavaScript projects: test code, locators, playwright.config.ts, flaky-test debugging, auth state reuse, network mocking, and CI setup. Use when the user asks to write or fix E2E / Playwright tests or their config and CI (「E2E テストを書いて」「Playwright のテストを直して」「flaky なテストを調べて」). For operating or checking a running app in a real browser, delegate to the browser-debugger agent; for launching the project's app to see a change working, use /run."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[scenario description or test file path]"
---

# Playwright Skill

This skill covers writing and debugging test code with `@playwright/test`. Read `references/test-writing.md` before writing test code, `playwright.config.ts`, or CI config.

Operating a real browser interactively (navigating, filling forms, scraping, inspecting a local webapp, reading console / network logs) is not done here: delegate it to the browser-debugger agent, because page snapshots and logs are noisy and would flood the main context. To launch the project's app and see a change working, use /run.

## Golden Rules

1. **`getByRole()` over CSS/XPath** -- resilient to markup changes, mirrors how users see the page.
2. **No `page.waitForTimeout()`** -- fixed sleeps are flaky and slow; use `expect(locator).toBeVisible()` or `page.waitForURL()`. Do not wait for `networkidle` either: Playwright discourages it for testing, so rely on web-first assertions for readiness.
3. **Web-first assertions** -- `expect(locator)` auto-retries; `expect(await locator.textContent())` does not.
4. **Isolate every test** -- no shared state, no execution-order dependencies.
5. **`baseURL` in config** -- zero hardcoded URLs in tests.
6. **Retries: `2` in CI, `0` locally** -- surface flakiness where it matters.
7. **Traces: `'on-first-retry'`** -- rich debugging artifacts without CI slowdown.
8. **Fixtures over globals** -- share state via `test.extend()`, not module-level variables.
9. **One behavior per test** -- multiple related `expect()` calls are fine.
10. **Mock external services only** -- never mock your own app; mock third-party APIs, payment gateways, email.
11. **Test user-visible behavior, not implementation details** -- assert on what the user sees and does, never on internal state or DOM structure.

## Debugging

1. **UI Mode:** `npx playwright test --ui` -- visual test runner with time-travel debugging.
2. **Trace Viewer:** `npx playwright show-trace trace.zip` -- inspect snapshots, network, console.
3. **Headed mode:** `npx playwright test --headed` -- watch the browser.
4. **Console/Network:** Capture logs via `page.on('console', ...)` and `page.on('request', ...)`.
5. **Codegen:** `npx playwright codegen URL` -- record interactions and generate test code.

## Reference files (read only when needed)

- `references/test-writing.md` -- `@playwright/test` config, locator priority, test structure, Page Object Model, auth state reuse, network mocking, a Python quick-check snippet for local webapps, and a GitHub Actions CI snippet. Read when writing test code, `playwright.config.ts`, or CI config.
