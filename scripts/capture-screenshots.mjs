import { chromium } from 'playwright';

const PROD_URL = 'https://my-project-ei3uw3f3h-austinchima183-2014s-projects.vercel.app';
const SCREENSHOT_DIR = '/home/z/my-project/download/screenshots';

const pages = [
  { path: '/login', name: 'login' },
  { path: '/register', name: 'register' },
  { path: '/forgot-password', name: 'forgot-password' },
  { path: '/reset-password', name: 'reset-password' },
  { path: '/verify-email', name: 'verify-email' },
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
  });

  for (const page of pages) {
    const p = await context.newPage();
    try {
      console.log(`Capturing ${page.name}...`);
      await p.goto(`${PROD_URL}${page.path}`, { waitUntil: 'networkidle', timeout: 15000 });
      await p.screenshot({ path: `${SCREENSHOT_DIR}/${page.name}.png`, fullPage: true });
      console.log(`  ✅ ${page.name} captured`);
    } catch (e) {
      console.log(`  ❌ ${page.name} failed: ${e.message}`);
      try {
        await p.screenshot({ path: `${SCREENSHOT_DIR}/${page.name}-error.png`, fullPage: true });
      } catch {}
    }
    await p.close();
  }

  // Also capture protected routes (should show login page)
  for (const route of ['/dashboard', '/billing', '/marketplace']) {
    const p = await context.newPage();
    try {
      console.log(`Capturing redirect from ${route}...`);
      await p.goto(`${PROD_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
      await p.screenshot({ path: `${SCREENSHOT_DIR}/redirect-${route.replace(/\//g, '')}.png`, fullPage: true });
      console.log(`  ✅ redirect from ${route} captured`);
    } catch (e) {
      console.log(`  ❌ ${route} failed: ${e.message}`);
    }
    await p.close();
  }

  await browser.close();
  console.log('\nAll screenshots captured!');
})();
