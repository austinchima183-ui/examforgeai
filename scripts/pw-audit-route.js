// Single-route Playwright audit - called with route path and label as args
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const routePath = process.argv[2];
const routeLabel = process.argv[3];
const baseUrl = process.argv[4] || 'http://0.0.0.0:3000';
const screenshotDir = '/home/z/my-project/download/audit-screenshots';

const VIEWPORTS = [
  { name: 'desktop-1920', width: 1920, height: 1080, cat: 'desktop' },
  { name: 'desktop-1440', width: 1440, height: 900, cat: 'desktop' },
  { name: 'laptop-1280', width: 1280, height: 800, cat: 'laptop' },
  { name: 'tablet-768', width: 768, height: 1024, cat: 'tablet' },
  { name: 'mobile-375', width: 375, height: 812, cat: 'mobile' },
  { name: 'mobile-320', width: 320, height: 568, cat: 'mobile' },
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();
  
  const errors = [];
  const netErrors = [];
  const hydrationErrors = [];
  
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text().substring(0, 300));
    if (msg.text().toLowerCase().includes('hydration')) hydrationErrors.push(msg.text().substring(0, 300));
  });
  page.on('requestfailed', req => {
    netErrors.push(req.url().substring(0, 80) + ' - ' + (req.failure()?.errorText || 'unknown'));
  });

  const result = { status: 0, consoleErrors: [], networkErrors: [], hydrationErrors: [], a11yIssues: [], screenshots: [], overflowIssues: [], loadTime: 0, performance: {}, formInfo: {} };

  try {
    const start = Date.now();
    const resp = await page.goto(`${baseUrl}${routePath}`, { waitUntil: 'networkidle', timeout: 30000 });
    result.status = resp?.status() || 0;
    result.loadTime = Date.now() - start;
    await page.waitForTimeout(1500);
  } catch (err) {
    result.status = 0;
    errors.push('Nav failed: ' + err.message?.substring(0, 100));
  }

  result.consoleErrors = [...new Set(errors)];
  result.networkErrors = [...new Set(netErrors)];
  result.hydrationErrors = hydrationErrors;

  if (result.status >= 200 && result.status < 400) {
    // Accessibility
    try {
      const a11y = await page.evaluate(() => {
        const issues = [];
        document.querySelectorAll('img:not([alt])').forEach((img, i) => issues.push('Image missing alt: ' + (img.getAttribute('src')?.substring(0, 50) || 'img-' + i)));
        document.querySelectorAll('input,select,textarea').forEach((input, i) => {
          if (input.getAttribute('type') === 'hidden') return;
          const id = input.getAttribute('id');
          const hasLabel = input.getAttribute('aria-label') || input.getAttribute('aria-labelledby') || (id && document.querySelector('label[for="' + id + '"]'));
          if (!hasLabel) issues.push('Input missing label: ' + (input.getAttribute('name') || input.getAttribute('type') || 'input-' + i));
        });
        if (!document.documentElement.getAttribute('lang')) issues.push('Missing lang attribute on html');
        document.querySelectorAll('button').forEach((btn, i) => {
          if (!btn.textContent?.trim() && !btn.getAttribute('aria-label') && !btn.getAttribute('title')) {
            issues.push('Button without accessible text: btn-' + i);
          }
        });
        const ids = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
        const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
        if (dupes.length) issues.push('Duplicate IDs: ' + [...new Set(dupes)].join(', '));
        const headings = document.querySelectorAll('h1,h2,h3,h4,h5,h6');
        let lastLevel = 0;
        headings.forEach(h => {
          const level = parseInt(h.tagName[1]);
          if (lastLevel > 0 && level > lastLevel + 1) issues.push('Heading skip: ' + h.tagName + ' after H' + lastLevel);
          lastLevel = level;
        });
        // Contrast check
        const allText = document.querySelectorAll('p, span, div, h1, h2, h3, h4, h5, h6, a, label');
        let lightTextCount = 0;
        allText.forEach(el => {
          const style = window.getComputedStyle(el);
          const color = style.color;
          if (color && color.startsWith('rgb')) {
            const match = color.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
            if (match) {
              const [, r, g, b] = match.map(Number);
              if (r > 200 && g > 200 && b > 200) lightTextCount++;
            }
          }
        });
        if (lightTextCount > 0) issues.push(`Found ${lightTextCount} elements with potentially low contrast text`);
        // Page text summary
        const bodyText = document.body?.innerText?.substring(0, 500) || '';
        issues.push('PAGE_TEXT: ' + bodyText.replace(/\n/g, ' ').substring(0, 300));
        return issues;
      });
      result.a11yIssues = a11y;
    } catch (err) { /* ignore */ }

    // Screenshots
    for (const vp of VIEWPORTS) {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await page.waitForTimeout(500);
      const dir = path.join(screenshotDir, vp.cat);
      fs.mkdirSync(dir, { recursive: true });
      const fp = path.join(dir, routeLabel + '-' + vp.name + '.png');
      try {
        await page.screenshot({ path: fp, fullPage: true });
        result.screenshots.push(fp);
      } catch (err) { /* ignore */ }

      // Overflow check
      try {
        const overflow = await page.evaluate(() => {
          const html = document.documentElement;
          const body = document.body;
          if (body.scrollWidth > html.clientWidth + 2) {
            return 'H-scroll: ' + body.scrollWidth + 'px > ' + html.clientWidth + 'px';
          }
          return null;
        });
        if (overflow) result.overflowIssues.push(vp.name + ': ' + overflow);
      } catch (err) { /* ignore */ }
    }

    // Performance
    try {
      const metrics = await page.evaluate(() => {
        const nav = performance.getEntriesByType('navigation')[0];
        const paint = performance.getEntriesByType('paint');
        const fcp = paint.find(p => p.name === 'first-contentful-paint');
        return {
          ttfb: nav ? nav.responseStart - nav.requestStart : 0,
          fcp: fcp ? fcp.startTime : 0,
          domContentLoaded: nav ? nav.domContentLoadedEventEnd - nav.fetchStart : 0,
          domSize: document.querySelectorAll('*').length,
          transferSize: nav ? nav.transferSize : 0,
        };
      });
      result.performance = metrics;
    } catch (err) { /* ignore */ }

    // Form analysis
    try {
      const formInfo = await page.evaluate(() => {
        const forms = document.querySelectorAll('form');
        const inputs = document.querySelectorAll('input,select,textarea');
        const submitBtns = document.querySelectorAll('button[type="submit"],input[type="submit"]');
        return {
          formCount: forms.length,
          inputCount: inputs.length,
          submitCount: submitBtns.length,
          inputs: Array.from(inputs).map(inp => ({
            type: inp.getAttribute('type'),
            name: inp.getAttribute('name'),
            id: inp.getAttribute('id'),
            required: inp.hasAttribute('required'),
            hasLabel: !!(inp.getAttribute('aria-label') || inp.getAttribute('aria-labelledby') || (inp.id && document.querySelector('label[for="' + inp.id + '"]'))),
          })),
        };
      });
      result.formInfo = formInfo;
    } catch (err) { /* ignore */ }
  }

  await browser.close();
  console.log(JSON.stringify(result));
})().catch(err => {
  console.error(JSON.stringify({ error: err.message }));
});
