# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: billing-marketplace.spec.ts >> Marketplace >> should display product categories
- Location: e2e/billing-marketplace.spec.ts:59:7

# Error details

```
TimeoutError: page.waitForURL: Timeout 15000ms exceeded.
=========================== logs ===========================
waiting for navigation until "load"
============================================================
```

# Page snapshot

```yaml
- generic [active] [ref=e1]:
  - generic [ref=e2]:
    - link "Skip to main content" [ref=e3] [cursor=pointer]:
      - /url: "#main-content"
    - generic [ref=e8]:
      - banner [ref=e9]:
        - generic [ref=e10]: ExamForge AI
        - paragraph [ref=e16]: AI-Powered Exam Creation & Assessment Platform
      - main [ref=e17]:
        - generic [ref=e18]:
          - generic [ref=e19]:
            - heading "Welcome back" [level=1] [ref=e20]
            - paragraph [ref=e21]: Sign in to your account to continue
          - form "Sign in form" [ref=e22]:
            - generic [ref=e23]:
              - generic [ref=e24]: Email
              - textbox "Email" [ref=e25]:
                - /placeholder: you@example.com
                - text: admin@examforge.ai
            - generic [ref=e26]:
              - generic [ref=e27]:
                - generic [ref=e28]: Password
                - link "Forgot password?" [ref=e29] [cursor=pointer]:
                  - /url: /forgot-password
              - textbox "Password" [ref=e30]:
                - /placeholder: Enter your password
                - text: AdminPass123!
            - alert [ref=e31]: Invalid email or password. Please try again.
            - button "Sign In" [ref=e32]
          - paragraph [ref=e33]:
            - text: Don't have an account?
            - link "Create an account" [ref=e34] [cursor=pointer]:
              - /url: /register
      - contentinfo [ref=e35]: © 2026 ExamForge AI. All rights reserved.
  - region "Notifications alt+T"
  - alert [ref=e36]
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test'
  2   | 
  3   | // ============================================================================
  4   | // ExamForge AI — Billing & Marketplace E2E Tests
  5   | // ============================================================================
  6   | // Tests: Billing page, Plans, Marketplace browsing, Product purchase flow
  7   | // ============================================================================
  8   | 
  9   | const TEST_ADMIN = {
  10  |   email: process.env.E2E_TEST_ADMIN_EMAIL ?? 'admin@examforge.ai',
  11  |   password: process.env.E2E_TEST_ADMIN_PASSWORD ?? 'AdminPass123!',
  12  | }
  13  | 
  14  | async function loginAsAdmin(page: import('@playwright/test').Page) {
  15  |   await page.goto('/login')
  16  |   await page.fill('input[type="email"]', TEST_ADMIN.email)
  17  |   await page.fill('input[type="password"]', TEST_ADMIN.password)
  18  |   await page.click('button[type="submit"]')
> 19  |   await page.waitForURL(/\/dashboard/, { timeout: 15000 })
      |              ^ TimeoutError: page.waitForURL: Timeout 15000ms exceeded.
  20  | }
  21  | 
  22  | test.describe('Billing', () => {
  23  |   test('should display billing page', async ({ page }) => {
  24  |     await loginAsAdmin(page)
  25  |     await page.goto('/billing')
  26  |     await expect(page.locator('h1, h2')).toContainText(/billing|subscription/i)
  27  |   })
  28  | 
  29  |   test('should navigate to upgrade plans', async ({ page }) => {
  30  |     await loginAsAdmin(page)
  31  |     await page.goto('/billing')
  32  |     const upgradeBtn = page.locator('a:has-text("Upgrade"), button:has-text("Upgrade")')
  33  |     if (await upgradeBtn.isVisible()) {
  34  |       await upgradeBtn.click()
  35  |       await page.waitForURL(/\/billing\/plans/, { timeout: 10000 }).catch(() => {
  36  |         // May not navigate if already on plans
  37  |       })
  38  |     }
  39  |   })
  40  | })
  41  | 
  42  | test.describe('Marketplace', () => {
  43  |   test('should display marketplace page', async ({ page }) => {
  44  |     await loginAsAdmin(page)
  45  |     await page.goto('/marketplace')
  46  |     await expect(page.locator('h1, h2')).toContainText(/marketplace/i)
  47  |   })
  48  | 
  49  |   test('should search marketplace', async ({ page }) => {
  50  |     await loginAsAdmin(page)
  51  |     await page.goto('/marketplace')
  52  |     const searchInput = page.locator('input[placeholder*="earch"]')
  53  |     if (await searchInput.isVisible()) {
  54  |       await searchInput.fill('math')
  55  |       await page.waitForTimeout(500) // Debounce
  56  |     }
  57  |   })
  58  | 
  59  |   test('should display product categories', async ({ page }) => {
  60  |     await loginAsAdmin(page)
  61  |     await page.goto('/marketplace')
  62  |     const tabs = page.locator('[role="tab"]')
  63  |     if (await tabs.count() > 0) {
  64  |       await tabs.first().click()
  65  |     }
  66  |   })
  67  | })
  68  | 
  69  | test.describe('Analytics', () => {
  70  |   test('should display analytics page', async ({ page }) => {
  71  |     await loginAsAdmin(page)
  72  |     await page.goto('/analytics')
  73  |     await expect(page.locator('h1, h2')).toContainText(/analytics/i)
  74  |   })
  75  | 
  76  |   test('should export analytics report', async ({ page }) => {
  77  |     await loginAsAdmin(page)
  78  |     await page.goto('/analytics')
  79  |     const exportBtn = page.locator('button:has-text("Export")')
  80  |     if (await exportBtn.isVisible()) {
  81  |       // Click should trigger a download
  82  |       const downloadPromise = page.waitForEvent('download', { timeout: 5000 }).catch(() => null)
  83  |       await exportBtn.click()
  84  |       const download = await downloadPromise
  85  |       // Download may or may not happen depending on data
  86  |     }
  87  |   })
  88  | })
  89  | 
  90  | test.describe('Results', () => {
  91  |   test('should display results page', async ({ page }) => {
  92  |     await loginAsAdmin(page)
  93  |     await page.goto('/results')
  94  |     await expect(page.locator('h1, h2')).toContainText(/result/i)
  95  |   })
  96  | })
  97  | 
  98  | test.describe('Reports', () => {
  99  |   test('should display reports page', async ({ page }) => {
  100 |     await loginAsAdmin(page)
  101 |     await page.goto('/reports')
  102 |     await expect(page.locator('h1, h2')).toContainText(/report/i)
  103 |   })
  104 | })
  105 | 
```