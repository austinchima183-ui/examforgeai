import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — CRUD Operations E2E Tests
// ============================================================================

test.describe('CRUD Operations', () => {
  // These tests verify that the pages load without JavaScript errors
  // Full CRUD testing requires authenticated sessions

  test('home page loads successfully', async ({ page }) => {
    await page.goto('/')

    // Verify the page loads
    await expect(page).toHaveTitle(/ExamForge AI/)

    // Verify no console errors
    const errors: string[] = []
    page.on('console', (msg) => {
      if (msg.type() === 'error') errors.push(msg.text())
    })
    await page.waitForTimeout(2000)
    // Filter out known non-critical errors
    const criticalErrors = errors.filter(e =>
      !e.includes('favicon') &&
      !e.includes('404') &&
      !e.includes('net::ERR')
    )
    expect(criticalErrors.length).toBe(0)
  })

  test('login page has correct meta tags', async ({ page }) => {
    await page.goto('/login')

    const title = await page.title()
    expect(title).toContain('ExamForge AI')

    // Verify the page has a description meta tag
    const description = await page.getAttribute('meta[name="description"]', 'content')
    expect(description).toBeTruthy()
  })

  test('public pages are accessible without authentication', async ({ page }) => {
    const publicRoutes = ['/login', '/register', '/forgot-password']

    for (const route of publicRoutes) {
      await page.goto(route)
      await expect(page).toHaveTitle(/ExamForge AI/)
    }
  })

  test('protected routes redirect to login', async ({ page }) => {
    const protectedRoutes = ['/dashboard', '/students', '/teachers', '/schools']

    for (const route of protectedRoutes) {
      await page.goto(route)
      // Should redirect to login
      await expect(page).toHaveURL(/\/login/, { timeout: 10000 })
    }
  })
})
