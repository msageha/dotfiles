---
name: playwright
description: "Writes, fixes, and debugs Playwright tests (@playwright/test) in TypeScript / JavaScript: locators, playwright.config.ts, flaky tests, auth state reuse, network mocking, and CI setup (「E2E テストを書いて」「Playwright のテストを直して」「flaky なテストを調べて」). To operate or check a running app in a real browser, delegate to the browser-debugger agent; to launch the app to see a change working, use /run where available."
allowed-tools: Read, Grep, Glob
argument-hint: "[scenario description or test file path]"
---

# Playwright Skill

This skill covers writing and debugging test code with `@playwright/test`. Read `references/test-writing.md` before writing test code, `playwright.config.ts`, or CI config.

Operating a real browser interactively (navigating, filling forms, scraping, inspecting a local webapp, reading console / network logs) is not done here: delegate it to the browser-debugger agent, because page snapshots and logs are noisy and would flood the main context. To launch the project's app and see a change working, use /run where available.

## Defaults

In an existing project, follow its config and conventions (retries, trace, reporter, locator style, fixtures) instead of rewriting them to match this list; the values below are the defaults for a new suite or config.

1. Prefer `getByRole()` over CSS / XPath selectors: it survives markup changes and mirrors how users perceive the page.
2. Wait with web-first assertions (`expect(locator).toBeVisible()`) or `page.waitForURL()` instead of `page.waitForTimeout()`, because fixed sleeps are flaky and slow. Do not wait for `networkidle` either: Playwright discourages it for testing.
3. Assert through `expect(locator)`, which retries until the condition holds; `expect(await locator.textContent())` checks once and does not retry.
4. Keep each test independent, with no shared state or dependence on execution order.
5. Set `baseURL` in the config and use relative paths in tests rather than hardcoded URLs.
6. Use `retries: 2` in CI and `0` locally, so flakiness shows up in local runs and CI does not fail on a single flaky attempt.
7. Use `trace: 'on-first-retry'`, which records debugging artifacts only for retried tests and keeps passing runs fast.
8. Share setup through fixtures (`test.extend()`) rather than module-level variables.
9. Cover one behavior per test; several related `expect()` calls are fine.
10. Mock external services (third-party APIs, payment gateways, email) and leave the app under test unmocked, since a mocked app no longer tests the app.
11. Assert on what the user sees and does rather than on internal state or DOM structure, so tests survive refactoring.

## Debugging

Capture console and network logs via `page.on('console', ...)` and `page.on('request', ...)`.

## Reference files (read only when needed)

- `references/test-writing.md` -- `@playwright/test` config, locator priority, test structure, Page Object Model, auth state reuse, network mocking, and a GitHub Actions CI snippet. Read when writing test code, `playwright.config.ts`, or CI config.
