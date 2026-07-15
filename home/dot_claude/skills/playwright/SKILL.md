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
    |-- No -> Is it test generation / E2E testing?
        |-- Yes -> @playwright/test approach (see Test Writing below)
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

## CLI Workflow (Playwright MCP or playwright-cli)

When a Playwright MCP server is available, use it directly for browser interaction:

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

## Test Writing (@playwright/test)

### Project Setup

```bash
npm init playwright@latest
```

### Recommended Config (`playwright.config.ts`)

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

### Locator Priority (most to least preferred)

1. `page.getByRole('button', { name: 'Submit' })` -- accessible, resilient
2. `page.getByLabel('Email')` -- for form fields
3. `page.getByPlaceholder('Enter email')` -- fallback for unlabeled inputs
4. `page.getByText('Welcome')` -- for visible text content
5. `page.getByTestId('submit-btn')` -- when semantic locators aren't possible
6. CSS/XPath -- last resort only

### Test Structure

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

### Page Object Model (when test suite grows)

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

### Authentication (reuse login state)

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

### Network Mocking

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
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:3000')
    page.wait_for_load_state('networkidle')  # CRITICAL: wait for JS
    page.screenshot(path='/tmp/inspect.png', full_page=True)
    # ... automation logic
    browser.close()
```

**Common pitfall:** Don't inspect DOM before `networkidle` on dynamic apps.

## Debugging

1. **UI Mode:** `npx playwright test --ui` -- visual test runner with time-travel debugging.
2. **Trace Viewer:** `npx playwright show-trace trace.zip` -- inspect snapshots, network, console.
3. **Headed mode:** `npx playwright test --headed` -- watch the browser.
4. **Console/Network:** Capture logs via `page.on('console', ...)` and `page.on('request', ...)`.
5. **Codegen:** `npx playwright codegen URL` -- record interactions and generate test code.

## CI/CD (GitHub Actions)

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

## Anti-Patterns to Avoid

- `page.waitForTimeout(ms)` -- always use proper waits
- `page.locator('.css-hash-123')` -- fragile, use semantic locators
- Shared mutable state between tests
- Testing implementation details instead of user-visible behavior
- Hardcoded URLs instead of `baseURL`
- `expect(await locator.isVisible()).toBe(true)` -- use `await expect(locator).toBeVisible()`
