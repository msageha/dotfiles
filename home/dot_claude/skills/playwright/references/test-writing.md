# Test Writing Reference (@playwright/test)

Contents: Project Setup / Recommended Config / Locator Priority / Test Structure / Page Object Model / Authentication / Network Mocking / Local Webapp Testing (Python) / CI (GitHub Actions)

## Project Setup (only when the user explicitly asked to add Playwright to the project; otherwise use the existing test runner and config)

```bash
npm init playwright@latest
```

Run this only when the user asked for Playwright tests and the project has no `@playwright/test` yet: it adds a dependency and scaffolds `tests/` and `playwright.config.ts`, so confirm before running it.

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
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
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

## Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test('should do expected behavior', async ({ page }) => {
    await page.goto('/path');
    await expect(page.getByRole('heading', { name: 'Title' })).toBeVisible();
    await page.getByRole('button', { name: 'Action' }).click();
    await expect(page).toHaveURL(/\/expected-path/);
  });
});
```

## Page Object Model (when test suite grows)

```typescript
export class LoginPage {
  constructor(private page: Page) {}

  readonly email = this.page.getByLabel('Email');
  readonly password = this.page.getByLabel('Password');
  readonly submitButton = this.page.getByRole('button', { name: 'Sign in' });

  async login(email: string, password: string) {
    await this.email.fill(email);
    await this.password.fill(password);
    await this.submitButton.click();
  }
}
```

Use POM when: 3+ tests share the same page interactions. Do NOT use POM for simple, one-off tests.

## Authentication (reuse login state)

```typescript
// auth.setup.ts
import { test as setup } from '@playwright/test';

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('user@example.com');
  await page.getByLabel('Password').fill('password');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await page.context().storageState({ path: '.auth/user.json' });
});
```

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

Mock only external/third-party services. Never mock your own application endpoints.

## Local Webapp Testing (Python)

For quick verification of local web applications:

```python
import os
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:3000')
    page.wait_for_load_state('networkidle')  # CRITICAL: wait for JS
    page.screenshot(path=os.path.join(os.environ.get('TMPDIR', '/tmp'), 'inspect.png'), full_page=True)
    # ... automation logic
    browser.close()
```

**Common pitfall:** Don't inspect DOM before `networkidle` on dynamic apps.

## CI (GitHub Actions)

```yaml
- name: Install Playwright Browsers
  run: npx playwright install --with-deps
- name: Run Playwright tests
  run: npx playwright test
- uses: actions/upload-artifact@v4
  if: ${{ !cancelled() }}
  with:
    name: playwright-report
    path: playwright-report/
    retention-days: 30
```

**Key CI settings:** `retries: 2`, `workers: 1` (or use sharding for parallelism), `trace: 'on-first-retry'`.
