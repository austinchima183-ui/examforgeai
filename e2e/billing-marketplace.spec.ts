import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — Billing & Marketplace E2E Tests
// ============================================================================

test.describe('Billing & Marketplace', () => {
  test('billing page redirects unauthenticated users', async ({ page }) => {
    await page.goto('/billing')

    // Should redirect to login since billing requires authentication
    await expect(page).toHaveURL(/\/login/, { timeout: 10000 })
  })

  test('marketplace page redirects unauthenticated users', async ({ page }) => {
    await page.goto('/marketplace')

    // Should redirect to login since marketplace requires authentication
    await expect(page).toHaveURL(/\/login/, { timeout: 10000 })
  })

  test('webhook endpoint returns 401 without signature', async ({ request }) => {
    const response = await request.post('/api/billing/webhook', {
      data: { event: 'test' },
    })

    // Should return 401 because no valid signature is provided
    expect(response.status()).toBe(401)
  })

  test('checkout endpoint requires authentication', async ({ request }) => {
    const response = await request.post('/api/billing/checkout', {
      data: { amount: 1000, email: 'test@test.com' },
    })

    // Should return 401 or 403 because no session is provided
    expect([401, 403, 405]).toContain(response.status())
  })
})
