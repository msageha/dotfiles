# Test Writing Reference (@playwright/test)

Contents: Project Setup / Recommended Config / Locator Priority / Page Object Model / Authentication / Network Mocking / CI (GitHub Actions)

## Project Setup

```bash
npm init playwright@latest
```

Run this only when the user explicitly asked to add Playwright to a project that has no `@playwright/test` yet, and confirm first: it adds a dependency and scaffolds `tests/` and `playwright.config.ts`. Otherwise use the existing test runner and config.

## Recommended Config (`playwright.config.ts`)

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  // The html reporter's default opens a report server on failure and waits, which blocks a non-interactive run.
  reporter: [['html', { open: 'never' }]],
  use: {
    baseURL: '<local URL of the app>',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: '<command that starts the app>',
    url: '<local URL of the app>',
    // A reused server must run this checkout's code against test data; check that before relying on it.
    reuseExistingServer: !process.env.CI,
  },
});
```

## Locator Priority (most to least preferred)

1. `page.getByRole('button', { name: 'Submit' })` -- accessible, resilient
2. `page.getByLabel('Email')` -- for form fields
3. `page.getByPlaceholder('Enter email')` -- fallback for unlabeled inputs
4. `page.getByText('Welcome')` -- for visible text content
5. `page.getByTestId('submit-btn')` -- when semantic locators aren't possible
6. CSS/XPath -- last resort only

## Page Object Model

```typescript
import type { Locator, Page } from '@playwright/test';

export class LoginPage {
  readonly email: Locator;
  readonly password: Locator;
  readonly submitButton: Locator;

  constructor(page: Page) {
    this.email = page.getByLabel('Email');
    this.password = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
  }

  async login(email: string, password: string) {
    await this.email.fill(email);
    await this.password.fill(password);
    await this.submitButton.click();
  }
}
```

Use POM when 3+ tests share the same page interactions. For simple, one-off tests, keep the locators inline; a page object there adds indirection without reuse.

## Authentication (reuse login state)

```typescript
// auth.setup.ts
import { test as setup, expect } from '@playwright/test';

setup('authenticate', async ({ page }) => {
  const { E2E_USER, E2E_PASSWORD } = process.env;
  if (!E2E_USER || !E2E_PASSWORD) throw new Error('E2E_USER and E2E_PASSWORD must be set');

  await page.goto('/login');
  await page.getByLabel('Email').fill(E2E_USER);
  await page.getByLabel('Password').fill(E2E_PASSWORD);
  await page.getByRole('button', { name: 'Sign in' }).click();
  // The click returns before the login redirects finish; wait for a signed-in element so the saved state includes the session cookies.
  await expect(page.getByRole('button', { name: '<button shown only when signed in>' })).toBeVisible();
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

Run this file from a `setup` project (`{ name: 'setup', testMatch: /.*\.setup\.ts/ }`) and give each test project `dependencies: ['setup']` and `use.storageState: 'playwright/.auth/user.json'`; the default `testMatch` does not pick the file up, and tests start signed out unless they load the saved state.

Sharing one account this way suits tests that do not change server-side state another test reads (the account's settings, its cart). When tests change such state, isolate it, for example by authenticating one account per parallel worker and passing its `storageState` to that worker's tests through a worker-scoped fixture, with each test resetting the server-side state it changes ([one account per parallel worker](https://playwright.dev/docs/auth#moderate-one-account-per-parallel-worker)); otherwise the results depend on execution order when tests run in parallel. This isolates only per-account state: no two runs in progress at once (CI shards included) may use the same account, and state shared across accounts (a tenant's settings, shared inventory) needs its own separation.

The state file holds session cookies, so add `playwright/.auth/` to `.gitignore`.

## Network Mocking

```typescript
await page.route('https://api.<third-party>.example/<endpoint>', async route => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ data: 'mocked' }),
  });
});
```

Match the external service's origin and the endpoint the condition needs rather than a path alone, which can also match the app's own endpoints, or a whole origin, which replaces every other call to it, and route only services that item 10 in SKILL.md allows mocking; let requests to the app's own endpoints reach the real app so the test still covers them. `page.route()` affects only requests the page makes; replace calls the app's server makes to an external service at the server's existing dependency boundary instead.

## CI (GitHub Actions)

```yaml
- name: Install Playwright Browsers
  run: npx playwright install --with-deps
- name: Run Playwright tests
  run: npx playwright test
- uses: actions/upload-artifact@<40-char commit SHA> # <tag>
  if: ${{ !cancelled() }}
  with:
    name: playwright-report
    path: playwright-report/
    retention-days: 30
```

The uploaded report includes traces, screenshots and logs, which can contain credentials and tokens, and anyone who can read the repository's workflow runs can download it; upload it only when its contents and audience satisfy AGENTS.md's rules for secrets.

Fill `<40-char commit SHA>` and `<tag>` when writing the workflow, not from memory: reuse the pin the repository already has for the action, otherwise resolve them as the GitHub Actions rule (`~/.claude/rules/github-actions.md`) describes.

The Recommended Config above already sets the CI values (`retries` and `workers` through `process.env.CI`, and `trace`); for parallelism in CI, use sharding.
