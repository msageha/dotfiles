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
  reporter: 'html',
  use: {
    baseURL: '<local URL of the app>',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: '<command that starts the app>',
    url: '<local URL of the app>',
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

The state file holds session cookies, so add `playwright/.auth/` to `.gitignore`.

## Network Mocking

```typescript
await page.route('**/api/external-service', async route => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ data: 'mocked' }),
  });
});
```

Route only external or third-party services; let requests to the app's own endpoints reach the real app so the test still covers them.

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

Fill `<40-char commit SHA>` and `<tag>` when writing the workflow, not from memory: reuse the pin the repository already has for the action, otherwise resolve them from the action's newest release.

The Recommended Config above already sets the CI values (`retries` and `workers` through `process.env.CI`, and `trace`); for parallelism in CI, use sharding.
