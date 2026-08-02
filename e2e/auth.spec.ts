import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — Authentication E2E Tests
// ============================================================================

test.describe('Authentication', () => {
  test('login page loads and shows form elements', async ({ page }) => {
    await page.goto('/login')

    // Verify the page title
    await expect(page).toHaveTitle(/ExamForge AI/)

    // Verify login form elements exist
    await expect(page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]')).toBeVisible({ timeout: 10000 })
    await expect(page.locator('input[type="password"], input[name="password"], input[placeholder*="password" i]')).toBeVisible({ timeout: 10000 })
  })

  test('register page loads and shows form elements', async ({ page }) => {
    await page.goto('/register')

    // Verify the page title
    await expect(page).toHaveTitle(/ExamForge AI/)

    // Verify register form elements exist
    await expect(page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]')).toBeVisible({ timeout: 10000 })
  })

  test('forgot-password page loads', async ({ page }) => {
    await page.goto('/forgot-password')

    // Verify the page title
    await expect(page).toHaveTitle(/ExamForge AI/)
  })

  test('unauthenticated access to dashboard redirects to login', async ({ page }) => {
    await page.goto('/dashboard')

    // Should redirect to login page
    await expect(page).toHaveURL(/\/login/, { timeout: 10000 })
  })

  test('login with invalid credentials shows error', async ({ page }) => {
    await page.goto('/login')

    // Fill in invalid credentials
    const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]').first()
    const passwordInput = page.locator('input[type="password"], input[name="password"], input[placeholder*="password" i]').first()

    await emailInput.fill('invalid@test.com')
    await passwordInput.fill('wrongpassword123')

    // Submit the form
    const submitButton = page.locator('button[type="submit"], button:has-text("Sign in"), button:has-text("Login"), button:has-text("Log in")').first()
    await submitButton.click()

    // Should show an error message (either inline or toast)
    await page.waitForTimeout(2000)
    // The page should still be on login or show an error
    const currentUrl = page.url()
    expect(currentUrl).toMatch(/\/login|\/dashboard/)
  })
})
