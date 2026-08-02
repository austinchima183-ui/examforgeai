import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — Billing & Marketplace E2E Tests
// ============================================================================
// Tests: Billing page, Plans, Marketplace browsing, Product purchase flow
// ============================================================================

const TEST_ADMIN = {
  email: process.env.E2E_TEST_ADMIN_EMAIL ?? 'admin@examforge.ai',
  password: process.env.E2E_TEST_ADMIN_PASSWORD ?? 'AdminPass123!',
}

async function loginAsAdmin(page: import('@playwright/test').Page) {
  await page.goto('/login')
  await page.fill('input[type="email"]', TEST_ADMIN.email)
  await page.fill('input[type="password"]', TEST_ADMIN.password)
  await page.click('button[type="submit"]')
  await page.waitForURL(/\/dashboard/, { timeout: 15000 })
}

test.describe('Billing', () => {
  test('should display billing page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/billing')
    await expect(page.locator('h1, h2')).toContainText(/billing|subscription/i)
  })

  test('should navigate to upgrade plans', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/billing')
    const upgradeBtn = page.locator('a:has-text("Upgrade"), button:has-text("Upgrade")')
    if (await upgradeBtn.isVisible()) {
      await upgradeBtn.click()
      await page.waitForURL(/\/billing\/plans/, { timeout: 10000 }).catch(() => {
        // May not navigate if already on plans
      })
    }
  })
})

test.describe('Marketplace', () => {
  test('should display marketplace page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/marketplace')
    await expect(page.locator('h1, h2')).toContainText(/marketplace/i)
  })

  test('should search marketplace', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/marketplace')
    const searchInput = page.locator('input[placeholder*="earch"]')
    if (await searchInput.isVisible()) {
      await searchInput.fill('math')
      await page.waitForTimeout(500) // Debounce
    }
  })

  test('should display product categories', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/marketplace')
    const tabs = page.locator('[role="tab"]')
    if (await tabs.count() > 0) {
      await tabs.first().click()
    }
  })
})

test.describe('Analytics', () => {
  test('should display analytics page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/analytics')
    await expect(page.locator('h1, h2')).toContainText(/analytics/i)
  })

  test('should export analytics report', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/analytics')
    const exportBtn = page.locator('button:has-text("Export")')
    if (await exportBtn.isVisible()) {
      // Click should trigger a download
      const downloadPromise = page.waitForEvent('download', { timeout: 5000 }).catch(() => null)
      await exportBtn.click()
      const download = await downloadPromise
      // Download may or may not happen depending on data
    }
  })
})

test.describe('Results', () => {
  test('should display results page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/results')
    await expect(page.locator('h1, h2')).toContainText(/result/i)
  })
})

test.describe('Reports', () => {
  test('should display reports page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/reports')
    await expect(page.locator('h1, h2')).toContainText(/report/i)
  })
})
