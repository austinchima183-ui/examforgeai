import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — Authentication E2E Tests
// ============================================================================
// Tests: Login, Register, Password Reset, Session persistence
// ============================================================================

const TEST_USER = {
  email: process.env.E2E_TEST_USER_EMAIL ?? 'test@examforge.ai',
  password: process.env.E2E_TEST_USER_PASSWORD ?? 'TestPass123!',
}

const TEST_ADMIN = {
  email: process.env.E2E_TEST_ADMIN_EMAIL ?? 'admin@examforge.ai',
  password: process.env.E2E_TEST_ADMIN_PASSWORD ?? 'AdminPass123!',
}

test.describe('Authentication', () => {
  test('should display login page', async ({ page }) => {
    await page.goto('/login')
    await expect(page.locator('h1, h2')).toContainText(/login|sign in/i)
    await expect(page.locator('input[type="email"]')).toBeVisible()
    await expect(page.locator('input[type="password"]')).toBeVisible()
  })

  test('should show error on invalid credentials', async ({ page }) => {
    await page.goto('/login')
    await page.fill('input[type="email"]', 'invalid@example.com')
    await page.fill('input[type="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')
    await expect(page.locator('[role="alert"], .text-destructive')).toBeVisible({ timeout: 10000 })
  })

  test('should login successfully with valid credentials', async ({ page }) => {
    await page.goto('/login')
    await page.fill('input[type="email"]', TEST_USER.email)
    await page.fill('input[type="password"]', TEST_USER.password)
    await page.click('button[type="submit"]')
    await page.waitForURL(/\/dashboard/, { timeout: 15000 })
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('should redirect unauthenticated users to login', async ({ page }) => {
    await page.goto('/students')
    await page.waitForURL(/\/login/, { timeout: 10000 })
    await expect(page).toHaveURL(/\/login/)
  })

  test('should redirect authenticated users away from login', async ({ page }) => {
    // Login first
    await page.goto('/login')
    await page.fill('input[type="email"]', TEST_USER.email)
    await page.fill('input[type="password"]', TEST_USER.password)
    await page.click('button[type="submit"]')
    await page.waitForURL(/\/dashboard/, { timeout: 15000 })

    // Try to access login again
    await page.goto('/login')
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
    await expect(page).toHaveURL(/\/dashboard/)
  })

  test('should display register page', async ({ page }) => {
    await page.goto('/register')
    await expect(page.locator('input[type="email"]')).toBeVisible()
    await expect(page.locator('input[type="password"]')).toBeVisible()
  })

  test('should show forgot password page', async ({ page }) => {
    await page.goto('/forgot-password')
    await expect(page.locator('input[type="email"]')).toBeVisible()
  })
})

test.describe('RBAC', () => {
  test('should enforce role-based access on /schools', async ({ page }) => {
    // Login as student (should not access /schools)
    await page.goto('/login')
    await page.fill('input[type="email"]', TEST_USER.email)
    await page.fill('input[type="password"]', TEST_USER.password)
    await page.click('button[type="submit"]')
    await page.waitForURL(/\/dashboard/, { timeout: 15000 })

    // Try to access /schools (should be redirected)
    await page.goto('/schools')
    await page.waitForURL(/\/dashboard/, { timeout: 10000 })
  })
})
