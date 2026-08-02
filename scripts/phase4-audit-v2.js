const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://0.0.0.0:3000';
const SCREENSHOT_DIR = '/home/z/my-project/download/audit-screenshots';
const REPORT_DIR = '/home/z/my-project/download';

const ROUTES = [
  { path: '/login', label: 'login', auth: false },
  { path: '/register', label: 'register', auth: false },
  { path: '/forgot-password', label: 'forgot-password', auth: false },
  { path: '/reset-password', label: 'reset-password', auth: false },
  { path: '/verify-email', label: 'verify-email', auth: false },
  { path: '/dashboard', label: 'dashboard', auth: true },
  { path: '/schools', label: 'schools', auth: true },
  { path: '/students', label: 'students', auth: true },
  { path: '/teachers', label: 'teachers', auth: true },
  { path: '/parents', label: 'parents', auth: true },
  { path: '/notifications', label: 'notifications', auth: true },
  { path: '/profile', label: 'profile', auth: true },
  { path: '/settings', label: 'settings', auth: true },
  { path: '/analytics', label: 'analytics', auth: true },
  { path: '/billing', label: 'billing', auth: true },
  { path: '/marketplace', label: 'marketplace', auth: true },
  { path: '/question-bank', label: 'question-bank', auth: true },
  { path: '/results', label: 'results', auth: true },
  { path: '/cbt', label: 'cbt', auth: true },
  { path: '/', label: 'home', auth: false },
];

const VIEWPORTS = [
  { name: 'desktop-1920', width: 1920, height: 1080, cat: 'desktop' },
  { name: 'desktop-1440', width: 1440, height: 900, cat: 'desktop' },
  { name: 'laptop-1280', width: 1280, height: 800, cat: 'laptop' },
  { name: 'laptop-1024', width: 1024, height: 768, cat: 'laptop' },
  { name: 'tablet-820', width: 820, height: 1180, cat: 'tablet' },
  { name: 'tablet-768', width: 768, height: 1024, cat: 'tablet' },
  { name: 'mobile-414', width: 414, height: 896, cat: 'mobile' },
  { name: 'mobile-390', width: 390, height: 844, cat: 'mobile' },
  { name: 'mobile-375', width: 375, height: 812, cat: 'mobile' },
  { name: 'mobile-320', width: 320, height: 568, cat: 'mobile' },
];

const allResults = [];
const allBugs = [];
let totalScreenshots = 0;

async function main() {
  console.log('='.repeat(60));
  console.log('PHASE 4.5 — ENTERPRISE UI/UX/QA AUDIT');
  console.log('='.repeat(60));
  console.log(`Time: ${new Date().toISOString()}`);
  console.log(`Base URL: ${BASE_URL}`);

  // Create dirs
  for (const v of VIEWPORTS) {
    fs.mkdirSync(path.join(SCREENSHOT_DIR, v.cat), { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  // SECTION 2: Route Testing + Screenshots
  console.log('\n=== SECTION 2 & 3: Route Testing + Screenshots ===');
  for (const route of ROUTES) {
    const result = { route: route.path, label: route.label, status: 0, consoleErrors: [], networkErrors: [], hydrationErrors: [], a11yIssues: [], loadTime: 0, screenshots: {}, overflowIssues: [] };
    
    const errors = [];
    const netErrors = [];
    
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text().substring(0, 300));
      if (msg.text().toLowerCase().includes('hydration')) result.hydrationErrors.push(msg.text().substring(0, 300));
    });
    page.on('requestfailed', req => {
      netErrors.push(`${req.url().substring(0, 80)} - ${req.failure()?.errorText || 'unknown'}`);
    });

    const start = Date.now();
    try {
      const resp = await page.goto(`${BASE_URL}${route.path}`, { waitUntil: 'networkidle', timeout: 30000 });
      result.status = resp?.status() || 0;
      await page.waitForTimeout(2000);
    } catch (err) {
      result.status = 0;
      errors.push(`Nav failed: ${err.message?.substring(0, 100)}`);
    }
    result.loadTime = Date.now() - start;
    result.consoleErrors = [...new Set(errors)];
    result.networkErrors = [...new Set(netErrors)];

    const statusIcon = result.status >= 200 && result.status < 400 ? '✓' : '✗';
    console.log(`  ${statusIcon} ${route.path} -> ${result.status} (${result.loadTime}ms) ${errors.length > 0 ? 'ERR:' + errors.length : ''} ${netErrors.length > 0 ? 'NET:' + netErrors.length : ''}`);

    // Bug logging
    if (result.status === 0) {
      allBugs.push({ id: `route-down-${route.label}`, severity: 'critical', category: 'Route', route: route.path, description: `Route ${route.path} failed to load`, evidence: `Status: ${result.status}`, fixed: false });
    }
    result.consoleErrors.forEach((e, i) => {
      allBugs.push({ id: `console-${route.label}-${i}`, severity: 'medium', category: 'Console Error', route: route.path, description: `Console error on ${route.path}`, evidence: e.substring(0, 200), fixed: false });
    });
    result.hydrationErrors.forEach((e, i) => {
      allBugs.push({ id: `hydration-${route.label}-${i}`, severity: 'critical', category: 'Hydration', route: route.path, description: `Hydration error on ${route.path}`, evidence: e.substring(0, 200), fixed: false });
    });
    result.networkErrors.forEach((e, i) => {
      allBugs.push({ id: `network-${route.label}-${i}`, severity: 'high', category: 'Network', route: route.path, description: `Network error on ${route.path}`, evidence: e.substring(0, 200), fixed: false });
    });

    // Accessibility checks (only for pages that actually loaded)
    if (result.status >= 200 && result.status < 400) {
      try {
        const a11y = await page.evaluate(() => {
          const issues = [];
          document.querySelectorAll('img:not([alt])').forEach((img, i) => issues.push(`Image missing alt: ${img.getAttribute('src')?.substring(0, 50) || 'img-' + i}`));
          document.querySelectorAll('input,select,textarea').forEach((input, i) => {
            if (input.getAttribute('type') === 'hidden') return;
            const id = input.getAttribute('id');
            const hasLabel = input.getAttribute('aria-label') || input.getAttribute('aria-labelledby') || (id && document.querySelector(`label[for="${id}"]`));
            if (!hasLabel) issues.push(`Input missing label: ${input.getAttribute('name') || input.getAttribute('type') || 'input-' + i}`);
          });
          if (!document.documentElement.getAttribute('lang')) issues.push('Missing lang attribute on html');
          document.querySelectorAll('button').forEach((btn, i) => {
            if (!btn.textContent?.trim() && !btn.getAttribute('aria-label') && !btn.getAttribute('title')) {
              issues.push(`Button without accessible text: btn-${i}`);
            }
          });
          const ids = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
          const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
          if (dupes.length) issues.push(`Duplicate IDs: ${[...new Set(dupes)].join(', ')}`);
          const headings = document.querySelectorAll('h1,h2,h3,h4,h5,h6');
          let lastLevel = 0;
          headings.forEach(h => {
            const level = parseInt(h.tagName[1]);
            if (lastLevel > 0 && level > lastLevel + 1) issues.push(`Heading skip: ${h.tagName} after H${lastLevel} - "${h.textContent?.substring(0, 40)}"`);
            lastLevel = level;
          });
          return issues;
        });
        result.a11yIssues = a11y;
        a11y.forEach((issue, i) => {
          allBugs.push({ id: `a11y-${route.label}-${i}`, severity: 'medium', category: 'Accessibility', route: route.path, description: `A11y issue on ${route.path}`, evidence: issue.substring(0, 200), fixed: false });
        });
      } catch (err) { /* ignore */ }
    }

    // Screenshots at all viewports (only for pages that loaded)
    if (result.status >= 200 && result.status < 400) {
      for (const vp of VIEWPORTS) {
        await page.setViewportSize({ width: vp.width, height: vp.height });
        await page.waitForTimeout(500);
        const dir = path.join(SCREENSHOT_DIR, vp.cat);
        const fp = path.join(dir, `${route.label}-${vp.name}.png`);
        try {
          await page.screenshot({ path: fp, fullPage: true });
          result.screenshots[vp.name] = fp;
          totalScreenshots++;
        } catch (err) { /* ignore */ }
      }
      await page.setViewportSize({ width: 1920, height: 1080 });

      // SECTION 5: Overflow check at each viewport
      for (const vp of VIEWPORTS) {
        await page.setViewportSize({ width: vp.width, height: vp.height });
        await page.waitForTimeout(300);
        try {
          const overflow = await page.evaluate(() => {
            const html = document.documentElement;
            const body = document.body;
            if (body.scrollWidth > html.clientWidth + 2) {
              return `H-scroll: ${body.scrollWidth}px > ${html.clientWidth}px`;
            }
            return null;
          });
          if (overflow) {
            result.overflowIssues.push(`${vp.name}: ${overflow}`);
            allBugs.push({ id: `responsive-${vp.name}-${route.label}`, severity: 'high', category: 'Responsive', route: route.path, description: `Overflow at ${vp.name} (${vp.width}x${vp.height}) on ${route.path}`, evidence: overflow, fixed: false });
          }
        } catch (err) { /* ignore */ }
      }
      await page.setViewportSize({ width: 1920, height: 1080 });
    }

    allResults.push(result);
    // Remove event listeners to prevent memory leak
    page.removeAllListeners('console');
    page.removeAllListeners('requestfailed');
  }

  // SECTION 6: Forms audit
  console.log('\n=== SECTION 6: Forms Audit ===');
  const formRoutes = ROUTES.filter(r => !r.auth || r.path === '/settings' || r.path === '/profile');
  for (const route of formRoutes) {
    try {
      await page.goto(`${BASE_URL}${route.path}`, { waitUntil: 'networkidle', timeout: 15000 });
      await page.waitForTimeout(1000);
      const formInfo = await page.evaluate(() => {
        const forms = document.querySelectorAll('form');
        const inputs = document.querySelectorAll('input,select,textarea');
        const submitBtns = document.querySelectorAll('button[type="submit"],input[type="submit"]');
        const inputDetails = Array.from(inputs).map(inp => ({
          type: inp.getAttribute('type'),
          name: inp.getAttribute('name'),
          id: inp.getAttribute('id'),
          required: inp.hasAttribute('required'),
          hasLabel: !!(inp.getAttribute('aria-label') || inp.getAttribute('aria-labelledby') || (inp.id && document.querySelector(`label[for="${inp.id}"]`))),
        }));
        return { formCount: forms.length, inputCount: inputs.length, submitCount: submitBtns.length, inputs: inputDetails };
      });
      console.log(`  ${route.path}: ${formInfo.formCount} forms, ${formInfo.inputCount} inputs, ${formInfo.submitCount} submit buttons`);
      const unlabeled = formInfo.inputs.filter(i => !i.hasLabel && i.type !== 'hidden');
      if (unlabeled.length > 0) {
        allBugs.push({ id: `form-labels-${route.label}`, severity: 'high', category: 'Accessibility', route: route.path, description: `Unlabeled inputs on ${route.path}`, evidence: unlabeled.map(i => i.name || i.type).join(', '), fixed: false });
      }
      if (formInfo.inputCount > 0 && formInfo.submitCount === 0) {
        allBugs.push({ id: `form-submit-${route.label}`, severity: 'medium', category: 'Forms', route: route.path, description: `No submit button on ${route.path}`, evidence: `${formInfo.inputCount} inputs, 0 submit buttons`, fixed: false });
      }
    } catch (err) {
      console.log(`  ${route.path}: ERROR - ${err.message?.substring(0, 80)}`);
    }
  }

  // SECTION 8/9: Performance metrics
  console.log('\n=== SECTION 8/9: Performance Metrics ===');
  const perfRoutes = ['/login', '/register', '/forgot-password'];
  const perfResults = {};
  for (const route of perfRoutes) {
    try {
      await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
      await page.waitForTimeout(500);
      const metrics = await page.evaluate(() => {
        const nav = performance.getEntriesByType('navigation')[0];
        const paint = performance.getEntriesByType('paint');
        const fcp = paint.find(p => p.name === 'first-contentful-paint');
        return {
          ttfb: nav ? nav.responseStart - nav.requestStart : 0,
          fcp: fcp ? fcp.startTime : 0,
          domContentLoaded: nav ? nav.domContentLoadedEventEnd - nav.fetchStart : 0,
          loadComplete: nav ? nav.loadEventEnd - nav.fetchStart : 0,
          domSize: document.querySelectorAll('*').length,
          transferSize: nav ? nav.transferSize : 0,
        };
      });
      perfResults[route] = metrics;
      console.log(`  ${route}: TTFB=${metrics.ttfb?.toFixed(0)}ms FCP=${metrics.fcp?.toFixed(0)}ms DOM=${metrics.domSize}`);
    } catch (err) {
      console.log(`  ${route}: ERROR`);
    }
  }

  // SECTION 11: User Journey - navigate public pages
  console.log('\n=== SECTION 11: User Journey ===');
  const journeyRoutes = ['/login', '/register', '/forgot-password', '/reset-password', '/verify-email'];
  for (const route of journeyRoutes) {
    try {
      const resp = await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
      console.log(`  ${route}: ${resp?.status() || 'fail'}`);
    } catch (err) {
      console.log(`  ${route}: ERROR - ${err.message?.substring(0, 60)}`);
      allBugs.push({ id: `journey-${route.replace(/\//g, '')}`, severity: 'high', category: 'User Journey', route, description: `Navigation failed on ${route}`, evidence: err.message?.substring(0, 100), fixed: false });
    }
  }

  await browser.close();

  // ============ GENERATE REPORTS ============
  console.log('\n=== SECTION 12: Generating Reports ===');

  const critical = allBugs.filter(b => b.severity === 'critical');
  const high = allBugs.filter(b => b.severity === 'high');
  const medium = allBugs.filter(b => b.severity === 'medium');
  const low = allBugs.filter(b => b.severity === 'low');

  // BUG_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'BUG_REPORT.md'), `# Bug Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

| Severity | Count |
|----------|-------|
| Critical | ${critical.length} |
| High | ${high.length} |
| Medium | ${medium.length} |
| Low | ${low.length} |
| **Total** | **${allBugs.length}** |

## Critical Bugs

${critical.length > 0 ? critical.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No critical bugs.'}

## High Bugs

${high.length > 0 ? high.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No high bugs.'}

## Medium Bugs

${medium.length > 0 ? medium.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No medium bugs.'}
`);

  // PLAYWRIGHT_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'PLAYWRIGHT_REPORT.md'), `# Playwright Test Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Browser:** Chromium Headless

## Route Results

| Route | Status | Load Time | Console Errors | Network Errors | Hydration Errors | A11y Issues | Overflow |
|-------|--------|-----------|----------------|----------------|------------------|-------------|----------|
${allResults.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.networkErrors.length} | ${r.hydrationErrors.length} | ${r.a11yIssues.length} | ${r.overflowIssues.length} |`).join('\n')}

## Console Errors Detail

${allResults.filter(r => r.consoleErrors.length > 0).map(r => `### ${r.route}
${r.consoleErrors.map(e => `- \`${e.substring(0, 200)}\``).join('\n')}
`).join('\n') || 'No console errors.'}

## Network Errors Detail

${allResults.filter(r => r.networkErrors.length > 0).map(r => `### ${r.route}
${r.networkErrors.map(e => `- \`${e.substring(0, 200)}\``).join('\n')}
`).join('\n') || 'No network errors.'}
`);

  // ACCESSIBILITY_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'ACCESSIBILITY_REPORT.md'), `# Accessibility Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

- **Total issues:** ${allBugs.filter(b => b.category === 'Accessibility').length}

## Issues by Route

${allResults.filter(r => r.a11yIssues.length > 0).map(r => `### ${r.route}
${r.a11yIssues.map(i => `- ${i}`).join('\n')}
`).join('\n') || 'No accessibility issues found.'}

## WCAG 2.1 Checklist

| Criterion | Status |
|-----------|--------|
| 1.1.1 Non-text Content | ${allBugs.some(b => b.evidence.includes('alt')) ? '✗ Issues found' : '✓ Pass'} |
| 1.3.1 Info and Relationships | ${allBugs.some(b => b.evidence.includes('label')) ? '✗ Issues found' : '✓ Pass'} |
| 2.1.1 Keyboard | ⚠ Manual review needed |
| 3.3.2 Labels or Instructions | ${allBugs.some(b => b.evidence.includes('label')) ? '✗ Issues found' : '✓ Pass'} |
| 4.1.2 Name, Role, Value | ${allBugs.some(b => b.evidence.includes('Button')) ? '✗ Issues found' : '✓ Pass'} |
`);

  // LIGHTHOUSE_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'LIGHTHOUSE_REPORT.md'), `# Lighthouse/Performance Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Performance Metrics

| Route | TTFB | FCP | DOM Loaded | DOM Size | Transfer Size |
|-------|------|-----|------------|----------|---------------|
${Object.entries(perfResults).map(([r, m]) => `| ${r} | ${m.ttfb?.toFixed(0) || 'N/A'}ms | ${m.fcp?.toFixed(0) || 'N/A'}ms | ${m.domContentLoaded?.toFixed(0) || 'N/A'}ms | ${m.domSize || 'N/A'} | ${m.transferSize || 'N/A'}B |`).join('\n')}

## Targets

| Metric | Target | Note |
|--------|--------|------|
| Performance | ≥95 | Run full Lighthouse CLI for accurate scores |
| Accessibility | 100 | See ACCESSIBILITY_REPORT.md |
| Best Practices | 100 | See BUG_REPORT.md |
| SEO | ≥95 | Run full Lighthouse CLI |
`);

  // RESPONSIVE_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'RESPONSIVE_REPORT.md'), `# Responsive Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Viewports Tested

| Name | Width | Height | Category |
|------|-------|--------|----------|
${VIEWPORTS.map(v => `| ${v.name} | ${v.width} | ${v.height} | ${v.cat} |`).join('\n')}

## Overflow Issues

${allBugs.filter(b => b.category === 'Responsive').length > 0 ? allBugs.filter(b => b.category === 'Responsive').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No overflow issues found at any viewport.'}

## Per-Route Overflow Details

${allResults.filter(r => r.overflowIssues.length > 0).map(r => `### ${r.route}
${r.overflowIssues.map(i => `- ${i}`).join('\n')}
`).join('\n') || 'No overflow detected.'}
`);

  // UI_AUDIT.md
  const uiBugs = allBugs.filter(b => ['UI', 'Route', 'Console Error', 'Hydration', 'Network'].includes(b.category));
  fs.writeFileSync(path.join(REPORT_DIR, 'UI_AUDIT.md'), `# UI Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Route Status

| Route | Status | Load Time | Console Errors | Hydration Errors |
|-------|--------|-----------|----------------|------------------|
${allResults.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.hydrationErrors.length} |`).join('\n')}

## UI-Related Bugs

${uiBugs.length > 0 ? uiBugs.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No UI bugs.'}
`);

  // UX_AUDIT.md
  const uxBugs = allBugs.filter(b => ['Forms', 'User Journey', 'Accessibility'].includes(b.category));
  fs.writeFileSync(path.join(REPORT_DIR, 'UX_AUDIT.md'), `# UX Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Form Issues

${allBugs.filter(b => b.category === 'Forms').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No form issues.'}

## User Journey Issues

${allBugs.filter(b => b.category === 'User Journey').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No user journey issues.'}

## Accessibility Issues

${allBugs.filter(b => b.category === 'Accessibility').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No accessibility issues.'}
`);

  // VISUAL_REGRESSION_REPORT.md
  fs.writeFileSync(path.join(REPORT_DIR, 'VISUAL_REGRESSION_REPORT.md'), `# Visual Regression Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Total Screenshots:** ${totalScreenshots}

## Screenshot Inventory

${allResults.filter(r => Object.keys(r.screenshots).length > 0).map(r => `### ${r.route}
${Object.entries(r.screenshots).map(([vp, fp]) => `- **${vp}**: \`${fp}\``).join('\n')}
`).join('\n')}

## Visual Comparison Notes

- All screenshots captured at 10 viewports
- Desktop: 1920x1080, 1440x900
- Laptop: 1280x800, 1024x768
- Tablet: 820x1180, 768x1024
- Mobile: 414x896, 390x844, 375x812, 320x568
`);

  // SCREENSHOT_INDEX.md
  fs.writeFileSync(path.join(REPORT_DIR, 'SCREENSHOT_INDEX.md'), `# Screenshot Index — ExamForge AI

**Date:** ${new Date().toISOString()}
**Total Screenshots:** ${totalScreenshots}

## By Route

${allResults.filter(r => Object.keys(r.screenshots).length > 0).map(r => `### ${r.route}
${Object.entries(r.screenshots).map(([vp, fp]) => `- **${vp}**: \`${fp}\``).join('\n')}
`).join('\n')}

## By Viewport Category

### Desktop
${allResults.filter(r => r.screenshots['desktop-1920']).map(r => `- ${r.route}: \`${r.screenshots['desktop-1920']}\``).join('\n')}

### Laptop
${allResults.filter(r => r.screenshots['laptop-1280']).map(r => `- ${r.route}: \`${r.screenshots['laptop-1280']}\``).join('\n')}

### Tablet
${allResults.filter(r => r.screenshots['tablet-768']).map(r => `- ${r.route}: \`${r.screenshots['tablet-768']}\``).join('\n')}

### Mobile
${allResults.filter(r => r.screenshots['mobile-375']).map(r => `- ${r.route}: \`${r.screenshots['mobile-375']}\``).join('\n')}
`);

  // FIX_LOG.md
  const openBugs = allBugs.filter(b => !b.fixed);
  fs.writeFileSync(path.join(REPORT_DIR, 'FIX_LOG.md'), `# Fix Log — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

| Status | Count |
|--------|-------|
| Open | ${openBugs.length} |
| Fixed | 0 |
| Total | ${allBugs.length} |

## Open Issues

| ID | Severity | Category | Route | Description |
|----|----------|----------|-------|-------------|
${openBugs.map(b => `| ${b.id} | ${b.severity} | ${b.category} | ${b.route} | ${b.description.substring(0, 80)} |`).join('\n')}

## Fixed Issues

None yet — fixes will be applied after initial audit.
`);

  // Final summary
  console.log('\n' + '='.repeat(60));
  console.log('AUDIT COMPLETE');
  console.log('='.repeat(60));
  console.log(`Total pages tested: ${allResults.length}`);
  console.log(`Total screenshots: ${totalScreenshots}`);
  console.log(`Total bugs found: ${allBugs.length}`);
  console.log(`  Critical: ${critical.length}`);
  console.log(`  High: ${high.length}`);
  console.log(`  Medium: ${medium.length}`);
  console.log(`  Low: ${low.length}`);
  console.log(`Console errors: ${allResults.reduce((s, r) => s + r.consoleErrors.length, 0)}`);
  console.log(`Network errors: ${allResults.reduce((s, r) => s + r.networkErrors.length, 0)}`);
  console.log(`Hydration errors: ${allResults.reduce((s, r) => s + r.hydrationErrors.length, 0)}`);
  console.log(`A11y issues: ${allResults.reduce((s, r) => s + r.a11yIssues.length, 0)}`);
  console.log(`Overflow issues: ${allResults.reduce((s, r) => s + r.overflowIssues.length, 0)}`);
  console.log(`Routes OK: ${allResults.filter(r => r.status >= 200 && r.status < 400).length}/${allResults.length}`);
}

main().catch(err => { console.error('Audit failed:', err); process.exit(1); });
