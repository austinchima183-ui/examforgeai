import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: true,
  retries: 1,
  workers: 2,
  reporter: [['html', { outputFolder: 'playwright-report' }], ['list']],
  timeout: 45_000,
  expect: {
    timeout: 15_000,
  },
  use: {
    baseURL: 'https://my-project-austinchima183-2014s-projects.vercel.app',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  // No webServer — testing against LIVE deployment
})
