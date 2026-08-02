# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: auth.spec.ts >> Authentication >> should display login page
- Location: e2e/auth.spec.ts:20:7

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('h1, h2')
Expected pattern: /login|sign in/i
Received string:  "Welcome back"
Timeout: 5000ms

Call log:
  - Expect "toContainText" with timeout 5000ms
  - waiting for locator('h1, h2')
    14 × locator resolved to <h1 class="text-2xl font-bold tracking-tight">Welcome back</h1>
       - unexpected value "Welcome back"

```

```yaml
- heading "Welcome back" [level=1]
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test'
  2  | 
  3  | // ============================================================================
  4  | // ExamForge AI — Authentication E2E Tests
  5  | // ============================================================================
  6  | // Tests: Login, Register, Password Reset, Session persistence
  7  | // ============================================================================
  8  | 
  9  | const TEST_USER = {
  10 |   email: process.env.E2E_TEST_USER_EMAIL ?? 'test@examforge.ai',
  11 |   password: process.env.E2E_TEST_USER_PASSWORD ?? 'TestPass123!',
  12 | }
  13 | 
  14 | const TEST_ADMIN = {
  15 |   email: process.env.E2E_TEST_ADMIN_EMAIL ?? 'admin@examforge.ai',
  16 |   password: process.env.E2E_TEST_ADMIN_PASSWORD ?? 'AdminPass123!',
  17 | }
  18 | 
  19 | test.describe('Authentication', () => {
  20 |   test('should display login page', async ({ page }) => {
  21 |     await page.goto('/login')
> 22 |     await expect(page.locator('h1, h2')).toContainText(/login|sign in/i)
     |                                          ^ Error: expect(locator).toContainText(expected) failed
  23 |     await expect(page.locator('input[type="email"]')).toBeVisible()
  24 |     await expect(page.locator('input[type="password"]')).toBeVisible()
  25 |   })
  26 | 
  27 |   test('should show error on invalid credentials', async ({ page }) => {
  28 |     await page.goto('/login')
  29 |     await page.fill('input[type="email"]', 'invalid@example.com')
  30 |     await page.fill('input[type="password"]', 'wrongpassword')
  31 |     await page.click('button[type="submit"]')
  32 |     await expect(page.locator('[role="alert"], .text-destructive')).toBeVisible({ timeout: 10000 })
  33 |   })
  34 | 
  35 |   test('should login successfully with valid credentials', async ({ page }) => {
  36 |     await page.goto('/login')
  37 |     await page.fill('input[type="email"]', TEST_USER.email)
  38 |     await page.fill('input[type="password"]', TEST_USER.password)
  39 |     await page.click('button[type="submit"]')
  40 |     await page.waitForURL(/\/dashboard/, { timeout: 15000 })
  41 |     await expect(page).toHaveURL(/\/dashboard/)
  42 |   })
  43 | 
  44 |   test('should redirect unauthenticated users to login', async ({ page }) => {
  45 |     await page.goto('/students')
  46 |     await page.waitForURL(/\/login/, { timeout: 10000 })
  47 |     await expect(page).toHaveURL(/\/login/)
  48 |   })
  49 | 
  50 |   test('should redirect authenticated users away from login', async ({ page }) => {
  51 |     // Login first
  52 |     await page.goto('/login')
  53 |     await page.fill('input[type="email"]', TEST_USER.email)
  54 |     await page.fill('input[type="password"]', TEST_USER.password)
  55 |     await page.click('button[type="submit"]')
  56 |     await page.waitForURL(/\/dashboard/, { timeout: 15000 })
  57 | 
  58 |     // Try to access login again
  59 |     await page.goto('/login')
  60 |     await page.waitForURL(/\/dashboard/, { timeout: 10000 })
  61 |     await expect(page).toHaveURL(/\/dashboard/)
  62 |   })
  63 | 
  64 |   test('should display register page', async ({ page }) => {
  65 |     await page.goto('/register')
  66 |     await expect(page.locator('input[type="email"]')).toBeVisible()
  67 |     await expect(page.locator('input[type="password"]')).toBeVisible()
  68 |   })
  69 | 
  70 |   test('should show forgot password page', async ({ page }) => {
  71 |     await page.goto('/forgot-password')
  72 |     await expect(page.locator('input[type="email"]')).toBeVisible()
  73 |   })
  74 | })
  75 | 
  76 | test.describe('RBAC', () => {
  77 |   test('should enforce role-based access on /schools', async ({ page }) => {
  78 |     // Login as student (should not access /schools)
  79 |     await page.goto('/login')
  80 |     await page.fill('input[type="email"]', TEST_USER.email)
  81 |     await page.fill('input[type="password"]', TEST_USER.password)
  82 |     await page.click('button[type="submit"]')
  83 |     await page.waitForURL(/\/dashboard/, { timeout: 15000 })
  84 | 
  85 |     // Try to access /schools (should be redirected)
  86 |     await page.goto('/schools')
  87 |     await page.waitForURL(/\/dashboard/, { timeout: 10000 })
  88 |   })
  89 | })
  90 | 
```