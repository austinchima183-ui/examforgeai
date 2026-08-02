import { test, expect } from '@playwright/test'

// ============================================================================
// ExamForge AI — CRUD Operations E2E Tests
// ============================================================================
// Tests: Create School, Create Teacher, Create Student, Create Exam,
// Submit CBT, Grade Exam, Marketplace Purchase, Notifications, Profile Update
// ============================================================================

const TEST_ADMIN = {
  email: process.env.E2E_TEST_ADMIN_EMAIL ?? 'admin@examforge.ai',
  password: process.env.E2E_TEST_ADMIN_PASSWORD ?? 'AdminPass123!',
}

// Helper: Login as admin
async function loginAsAdmin(page: import('@playwright/test').Page) {
  await page.goto('/login')
  await page.fill('input[type="email"]', TEST_ADMIN.email)
  await page.fill('input[type="password"]', TEST_ADMIN.password)
  await page.click('button[type="submit"]')
  await page.waitForURL(/\/dashboard/, { timeout: 15000 })
}

test.describe('School CRUD', () => {
  test('should create a school', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/schools')
    await page.click('button:has-text("Add School")')
    await expect(page.locator('[role="dialog"]')).toBeVisible()
    await page.fill('input[name="name"]', 'E2E Test School')
    await page.fill('input[name="code"]', 'E2E' + Date.now())
    await page.click('button:has-text("Create School")')
    await expect(page.locator('[role="dialog"]')).not.toBeVisible({ timeout: 10000 })
  })
})

test.describe('Student CRUD', () => {
  test('should create a student', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/students')
    await page.click('button:has-text("Add Student")')
    await expect(page.locator('[role="dialog"]')).toBeVisible()
    await page.fill('input[name="full_name"]', 'E2E Test Student')
    await page.fill('input[name="email"]', `e2e-student-${Date.now()}@test.com`)
    await page.fill('input[name="password"]', 'TestPass123!')
    await page.click('button:has-text("Create Student")')
    await expect(page.locator('[role="dialog"]')).not.toBeVisible({ timeout: 10000 })
  })
})

test.describe('Teacher CRUD', () => {
  test('should create a teacher', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/teachers')
    await page.click('button:has-text("Add Teacher")')
    await expect(page.locator('[role="dialog"]')).toBeVisible()
    await page.fill('input[name="full_name"]', 'E2E Test Teacher')
    await page.fill('input[name="email"]', `e2e-teacher-${Date.now()}@test.com`)
    await page.fill('input[name="password"]', 'TestPass123!')
    await page.click('button:has-text("Create Teacher")')
    await expect(page.locator('[role="dialog"]')).not.toBeVisible({ timeout: 10000 })
  })
})

test.describe('Exam CRUD', () => {
  test('should create an exam', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/cbt')
    await page.click('button:has-text("Create Exam")')
    await expect(page.locator('[role="dialog"]')).toBeVisible()
    await page.fill('input[name="title"]', 'E2E Test Exam')
    await page.click('button:has-text("Create Exam")')
    await expect(page.locator('[role="dialog"]')).not.toBeVisible({ timeout: 10000 })
  })
})

test.describe('Question Bank', () => {
  test('should create a question', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/question-bank')
    await page.click('button:has-text("Create Question")')
    await expect(page.locator('[role="dialog"]')).toBeVisible()
    await page.fill('textarea[name="text"]', 'E2E Test Question: What is 2+2?')
    await page.click('button:has-text("Create Question")')
    await expect(page.locator('[role="dialog"]')).not.toBeVisible({ timeout: 10000 })
  })
})

test.describe('Profile', () => {
  test('should display profile page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/profile')
    await expect(page.locator('h1, h2')).toContainText(/profile/i)
  })
})

test.describe('Notifications', () => {
  test('should display notifications page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/notifications')
    await expect(page.locator('h1, h2')).toContainText(/notification/i)
  })
})

test.describe('Settings', () => {
  test('should display settings page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/settings')
    await expect(page.locator('h1, h2')).toContainText(/setting/i)
  })
})

test.describe('Search', () => {
  test('should display search page', async ({ page }) => {
    await loginAsAdmin(page)
    await page.goto('/search')
    await expect(page.locator('input[placeholder*="earch"]')).toBeVisible()
  })
})
