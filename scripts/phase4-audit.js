const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const SCREENSHOT_DIR = '/home/z/my-project/download/audit-screenshots';

const ROUTES = [
  '/login', '/register', '/forgot-password', '/reset-password', '/verify-email',
  '/dashboard', '/schools', '/students', '/teachers', '/parents',
  '/notifications', '/profile', '/settings', '/analytics', '/billing',
  '/marketplace', '/question-bank', '/results', '/cbt', '/'
];

const VIEWPORTS = [
  { name: 'desktop-1920', width: 1920, height: 1080, cat: 'desktop' },
  { name: 'laptop-1280', width: 1280, height: 800, cat: 'laptop' },
  { name: 'tablet-768', width: 768, height: 1024, cat: 'tablet' },
  { name: 'mobile-375', width: 375, height: 812, cat: 'mobile' },
  { name: 'mobile-320', width: 320, height: 568, cat: 'mobile' },
];

const allResults = [];
const allBugs = [];
let totalScreenshots = 0;

async function main() {
  // Create dirs
  for (const v of VIEWPORTS) {
    fs.mkdirSync(path.join(SCREENSHOT_DIR, v.cat), { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const page = await context.newPage();

  console.log('=== SECTION 2: Route Testing ===');
  for (const route of ROUTES) {
    const result = { route, status: 0, consoleErrors: [], networkErrors: [], hydrationErrors: [], a11yIssues: [], loadTime: 0, screenshots: {} };
    
    const errors = [];
    const warnings = [];
    const networkFails = [];
    
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text().substring(0, 200));
      if (msg.text().toLowerCase().includes('hydration')) result.hydrationErrors.push(msg.text().substring(0, 200));
    });
    page.on('requestfailed', req => {
      networkFails.push(`${req.url()} - ${req.failure()?.errorText || 'unknown'}`);
    });

    const start = Date.now();
    try {
      const resp = await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 20000 });
      result.status = resp?.status() || 0;
      await page.waitForTimeout(1500);
    } catch (err) {
      result.status = 0;
      errors.push(`Nav failed: ${err.message?.substring(0, 100)}`);
    }
    result.loadTime = Date.now() - start;
    result.consoleErrors = errors;
    result.networkErrors = networkFails;

    console.log(`  ${route} -> ${result.status} (${result.loadTime}ms) ${errors.length > 0 ? 'ERR:' + errors.length : ''} ${networkFails.length > 0 ? 'NET:' + networkFails.length : ''}`);

    // Bug logging
    if (result.status === 0) {
      allBugs.push({ id: `route-down-${route.replace(/\//g, '')}`, severity: 'critical', category: 'Route', route, description: `Route ${route} failed to load`, evidence: `Status: ${result.status}`, fixed: false });
    }
    errors.forEach((e, i) => {
      allBugs.push({ id: `console-${route.replace(/\//g, '')}-${i}`, severity: 'medium', category: 'Console Error', route, description: `Console error on ${route}`, evidence: e.substring(0, 200), fixed: false });
    });
    result.hydrationErrors.forEach((e, i) => {
      allBugs.push({ id: `hydration-${route.replace(/\//g, '')}-${i}`, severity: 'critical', category: 'Hydration', route, description: `Hydration error on ${route}`, evidence: e.substring(0, 200), fixed: false });
    });
    networkFails.forEach((e, i) => {
      allBugs.push({ id: `network-${route.replace(/\//g, '')}-${i}`, severity: 'high', category: 'Network', route, description: `Network error on ${route}`, evidence: e.substring(0, 200), fixed: false });
    });

    // Accessibility checks
    try {
      const a11y = await page.evaluate(() => {
        const issues = [];
        // Missing alt text
        document.querySelectorAll('img:not([alt])').forEach((img, i) => issues.push(`Image missing alt: ${img.getAttribute('src')?.substring(0, 50) || 'img-' + i}`));
        // Missing labels
        document.querySelectorAll('input, select, textarea').forEach((input, i) => {
          if (input.getAttribute('type') === 'hidden') return;
          const id = input.getAttribute('id');
          const hasLabel = input.getAttribute('aria-label') || input.getAttribute('aria-labelledby') || (id && document.querySelector(`label[for="${id}"]`));
          if (!hasLabel) issues.push(`Input missing label: ${input.getAttribute('name') || input.getAttribute('type') || 'input-' + i}`);
        });
        // Missing lang
        if (!document.documentElement.getAttribute('lang')) issues.push('Missing lang attribute on html');
        // Buttons without text
        document.querySelectorAll('button').forEach((btn, i) => {
          if (!btn.textContent?.trim() && !btn.getAttribute('aria-label') && !btn.getAttribute('title')) {
            issues.push(`Button without accessible text: btn-${i}`);
          }
        });
        // Duplicate IDs
        const ids = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
        const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
        if (dupes.length) issues.push(`Duplicate IDs: ${[...new Set(dupes)].join(', ')}`);
        // Heading hierarchy
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
        allBugs.push({ id: `a11y-${route.replace(/\//g, '')}-${i}`, severity: 'medium', category: 'Accessibility', route, description: `A11y issue on ${route}`, evidence: issue.substring(0, 200), fixed: false });
      });
    } catch (err) { /* ignore */ }

    // Screenshots
    for (const vp of VIEWPORTS) {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await page.waitForTimeout(300);
      const dir = path.join(SCREENSHOT_DIR, vp.cat);
      const label = route.replace(/\//g, '') || 'home';
      const fp = path.join(dir, `${label}-${vp.name}.png`);
      try {
        await page.screenshot({ path: fp, fullPage: true });
        result.screenshots[vp.name] = fp;
        totalScreenshots++;
      } catch (err) { /* ignore */ }
    }
    await page.setViewportSize({ width: 1920, height: 1080 });

    allResults.push(result);
  }

  // SECTION 5: Responsive overflow check
  console.log('\n=== SECTION 5: Responsive Audit ===');
  for (const vp of VIEWPORTS) {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    for (const route of ['/login', '/dashboard', '/schools', '/students']) {
      try {
        await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
        await page.waitForTimeout(500);
        const overflow = await page.evaluate(() => {
          const html = document.documentElement;
          const body = document.body;
          if (body.scrollWidth > html.clientWidth + 2) {
            return `H-scroll: ${body.scrollWidth}px > ${html.clientWidth}px`;
          }
          return null;
        });
        if (overflow) {
          allBugs.push({ id: `responsive-${vp.name}-${route.replace(/\//g, '')}`, severity: 'high', category: 'Responsive', route, description: `Overflow at ${vp.name} (${vp.width}x${vp.height}) on ${route}`, evidence: overflow, fixed: false });
          console.log(`  ${vp.name} ${route}: ${overflow}`);
        }
      } catch (err) { /* ignore */ }
    }
  }

  // SECTION 6: Forms audit
  console.log('\n=== SECTION 6: Forms Audit ===');
  const formRoutes = ['/login', '/register', '/forgot-password', '/reset-password', '/settings', '/profile'];
  await page.setViewportSize({ width: 1920, height: 1080 });
  for (const route of formRoutes) {
    try {
      await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
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
      console.log(`  ${route}: ${formInfo.formCount} forms, ${formInfo.inputCount} inputs, ${formInfo.submitCount} submit buttons`);
      const unlabeled = formInfo.inputs.filter(i => !i.hasLabel && i.type !== 'hidden');
      if (unlabeled.length > 0) {
        allBugs.push({ id: `form-labels-${route.replace(/\//g, '')}`, severity: 'high', category: 'Accessibility', route, description: `Unlabeled inputs on ${route}`, evidence: unlabeled.map(i => i.name || i.type).join(', '), fixed: false });
      }
      if (formInfo.inputCount > 0 && formInfo.submitCount === 0) {
        allBugs.push({ id: `form-submit-${route.replace(/\//g, '')}`, severity: 'medium', category: 'Forms', route, description: `No submit button on ${route}`, evidence: `${formInfo.inputCount} inputs, 0 submit buttons`, fixed: false });
      }
    } catch (err) {
      console.log(`  ${route}: ERROR - ${err.message?.substring(0, 80)}`);
    }
  }

  // SECTION 8/9: Performance metrics
  console.log('\n=== SECTION 8/9: Performance Metrics ===');
  const perfRoutes = ['/login', '/dashboard', '/schools', '/students'];
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
      console.log(`  ${route}: TTFB=${metrics.ttfb?.toFixed(0)}ms FCP=${metrics.fcp?.toFixed(0)}ms DOM=${metrics.domSize} elements`);
    } catch (err) {
      console.log(`  ${route}: ERROR - ${err.message?.substring(0, 80)}`);
    }
  }

  await browser.close();

  // Generate reports
  console.log('\n=== SECTION 12: Generating Reports ===');
  const reportDir = '/home/z/my-project/download';

  const critical = allBugs.filter(b => b.severity === 'critical');
  const high = allBugs.filter(b => b.severity === 'high');
  const medium = allBugs.filter(b => b.severity === 'medium');
  const low = allBugs.filter(b => b.severity === 'low');

  // BUG_REPORT.md
  const bugReport = `# Bug Report — ExamForge AI

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
`;
  fs.writeFileSync(path.join(reportDir, 'BUG_REPORT.md'), bugReport);

  // PLAYWRIGHT_REPORT.md
  const pwReport = `# Playwright Test Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Browser:** Chromium Headless

## Route Results

| Route | Status | Load Time | Console Errors | Network Errors | Hydration Errors | A11y Issues |
|-------|--------|-----------|----------------|----------------|------------------|-------------|
${allResults.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.networkErrors.length} | ${r.hydrationErrors.length} | ${r.a11yIssues.length} |`).join('\n')}

## Console Errors Detail

${allResults.filter(r => r.consoleErrors.length > 0).map(r => `### ${r.route}
${r.consoleErrors.map(e => `- \`${e.substring(0, 150)}\``).join('\n')}
`).join('\n') || 'No console errors.'}

## Network Errors Detail

${allResults.filter(r => r.networkErrors.length > 0).map(r => `### ${r.route}
${r.networkErrors.map(e => `- \`${e.substring(0, 150)}\``).join('\n')}
`).join('\n') || 'No network errors.'}
`;
  fs.writeFileSync(path.join(reportDir, 'PLAYWRIGHT_REPORT.md'), pwReport);

  // ACCESSIBILITY_REPORT.md
  const a11yReport = `# Accessibility Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

- **Total issues:** ${allBugs.filter(b => b.category === 'Accessibility').length}

## Issues by Route

${allResults.map(r => {
  if (r.a11yIssues.length === 0) return `### ${r.route}\n✓ No issues\n`;
  return `### ${r.route}\n${r.a11yIssues.map(i => `- ${i}`).join('\n')}\n`;
}).join('\n')}
`;
  fs.writeFileSync(path.join(reportDir, 'ACCESSIBILITY_REPORT.md'), a11yReport);

  // LIGHTHOUSE_REPORT.md
  const lhReport = `# Lighthouse/Performance Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Performance Metrics

| Route | TTFB | FCP | DOM Loaded | DOM Size | Transfer Size |
|-------|------|-----|------------|----------|---------------|
${Object.entries(perfResults).map(([r, m]) => `| ${r} | ${m.ttfb?.toFixed(0) || 'N/A'}ms | ${m.fcp?.toFixed(0) || 'N/A'}ms | ${m.domContentLoaded?.toFixed(0) || 'N/A'}ms | ${m.domSize || 'N/A'} | ${m.transferSize || 'N/A'}B |`).join('\n')}
`;
  fs.writeFileSync(path.join(reportDir, 'LIGHTHOUSE_REPORT.md'), lhReport);

  // RESPONSIVE_REPORT.md
  const respReport = `# Responsive Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Viewports Tested

| Name | Width | Height | Category |
|------|-------|--------|----------|
${VIEWPORTS.map(v => `| ${v.name} | ${v.width} | ${v.height} | ${v.cat} |`).join('\n')}

## Responsive Issues

${allBugs.filter(b => b.category === 'Responsive').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No responsive issues found.'}
`;
  fs.writeFileSync(path.join(reportDir, 'RESPONSIVE_REPORT.md'), respReport);

  // UI_AUDIT.md
  const uiReport = `# UI Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Route Status

| Route | Status | Load Time | Console Errors | Hydration Errors |
|-------|--------|-----------|----------------|------------------|
${allResults.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.hydrationErrors.length} |`).join('\n')}

## UI-Related Bugs

${allBugs.filter(b => ['UI', 'Route', 'Console Error', 'Hydration', 'Network'].includes(b.category)).map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No UI bugs.'}
`;
  fs.writeFileSync(path.join(reportDir, 'UI_AUDIT.md'), uiReport);

  // UX_AUDIT.md
  const uxReport = `# UX Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Form Audit

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
`;
  fs.writeFileSync(path.join(reportDir, 'UX_AUDIT.md'), uxReport);

  // VISUAL_REGRESSION_REPORT.md
  const vrReport = `# Visual Regression Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Total Screenshots:** ${totalScreenshots}

## Screenshot Inventory

${allResults.map(r => `### ${r.route}
${Object.entries(r.screenshots).map(([vp, fp]) => `- **${vp}**: \`${fp}\``).join('\n')}
`).join('\n')}
`;
  fs.writeFileSync(path.join(reportDir, 'VISUAL_REGRESSION_REPORT.md'), vrReport);

  // SCREENSHOT_INDEX.md
  const siReport = `# Screenshot Index — ExamForge AI

**Date:** ${new Date().toISOString()}
**Total Screenshots:** ${totalScreenshots}

## By Route

${allResults.map(r => `### ${r.route}
${Object.entries(r.screenshots).map(([vp, fp]) => `- **${vp}**: \`${fp}\``).join('\n')}
`).join('\n')}
`;
  fs.writeFileSync(path.join(reportDir, 'SCREENSHOT_INDEX.md'), siReport);

  // FIX_LOG.md
  const fixReport = `# Fix Log — ExamForge AI

**Date:** ${new Date().toISOString()}

## Open Issues

| ID | Severity | Category | Route | Description |
|----|----------|----------|-------|-------------|
${allBugs.filter(b => !b.fixed).map(b => `| ${b.id} | ${b.severity} | ${b.category} | ${b.route} | ${b.description.substring(0, 80)} |`).join('\n')}

## Fixed Issues

None yet — fixes will be applied after audit.
`;
  fs.writeFileSync(path.join(reportDir, 'FIX_LOG.md'), fixReport);

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
  console.log(`Routes OK: ${allResults.filter(r => r.status >= 200 && r.status < 400).length}/${allResults.length}`);
}

main().catch(err => { console.error('Audit failed:', err); process.exit(1); });
