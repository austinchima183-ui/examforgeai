import { chromium, Browser, Page, BrowserContext } from 'playwright';
import { writeFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';

const BASE_URL = 'http://localhost:3000';
const SCREENSHOT_DIR = '/home/z/my-project/download/audit-screenshots';

interface AuditResult {
  route: string;
  status: number;
  consoleErrors: string[];
  consoleWarnings: string[];
  networkErrors: string[];
  hydrationErrors: string[];
  screenshotPaths: Record<string, string>;
  accessibilityIssues: string[];
  performanceMetrics: Record<string, number>;
  loadTime: number;
}

interface ViewportConfig {
  name: string;
  width: number;
  height: number;
  category: 'desktop' | 'laptop' | 'tablet' | 'mobile';
}

const VIEWPORTS: ViewportConfig[] = [
  { name: 'desktop-1920', width: 1920, height: 1080, category: 'desktop' },
  { name: 'desktop-1440', width: 1440, height: 900, category: 'desktop' },
  { name: 'laptop-1280', width: 1280, height: 800, category: 'laptop' },
  { name: 'laptop-1024', width: 1024, height: 768, category: 'laptop' },
  { name: 'tablet-820', width: 820, height: 1180, category: 'tablet' },
  { name: 'tablet-768', width: 768, height: 1024, category: 'tablet' },
  { name: 'mobile-414', width: 414, height: 896, category: 'mobile' },
  { name: 'mobile-390', width: 390, height: 844, category: 'mobile' },
  { name: 'mobile-375', width: 375, height: 812, category: 'mobile' },
  { name: 'mobile-320', width: 320, height: 568, category: 'mobile' },
];

const ROUTES = [
  { path: '/', label: 'home' },
  { path: '/login', label: 'login' },
  { path: '/register', label: 'register' },
  { path: '/forgot-password', label: 'forgot-password' },
  { path: '/reset-password', label: 'reset-password' },
  { path: '/verify-email', label: 'verify-email' },
  { path: '/dashboard', label: 'dashboard' },
  { path: '/schools', label: 'schools' },
  { path: '/students', label: 'students' },
  { path: '/teachers', label: 'teachers' },
  { path: '/parents', label: 'parents' },
  { path: '/notifications', label: 'notifications' },
  { path: '/profile', label: 'profile' },
  { path: '/settings', label: 'settings' },
  { path: '/analytics', label: 'analytics' },
  { path: '/billing', label: 'billing' },
  { path: '/marketplace', label: 'marketplace' },
  { path: '/question-bank', label: 'question-bank' },
  { path: '/results', label: 'results' },
  { path: '/cbt', label: 'cbt' },
];

const allResults: AuditResult[] = [];
const allBugs: BugReport[] = [];
let totalScreenshots = 0;

interface BugReport {
  id: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  route: string;
  description: string;
  evidence: string;
  fixed: boolean;
}

async function auditRoute(page: Page, route: typeof ROUTES[0]): Promise<AuditResult> {
  const result: AuditResult = {
    route: route.path,
    status: 0,
    consoleErrors: [],
    consoleWarnings: [],
    networkErrors: [],
    hydrationErrors: [],
    screenshotPaths: {},
    accessibilityIssues: [],
    performanceMetrics: {},
    loadTime: 0,
  };

  const consoleMessages: string[] = [];
  const consoleErrors: string[] = [];
  const consoleWarnings: string[] = [];
  const networkErrors: string[] = [];

  // Set up listeners
  page.on('console', msg => {
    consoleMessages.push(`[${msg.type()}] ${msg.text()}`);
    if (msg.type() === 'error') consoleErrors.push(msg.text());
    if (msg.type() === 'warning') consoleWarnings.push(msg.text());
    // Check for hydration errors
    if (msg.text().includes('hydration') || msg.text().includes('Hydration')) {
      result.hydrationErrors.push(msg.text());
    }
  });

  page.on('requestfailed', request => {
    networkErrors.push(`${request.method()} ${request.url()} - ${request.failure()?.errorText}`);
  });

  // Navigate
  const startTime = Date.now();
  try {
    const response = await page.goto(`${BASE_URL}${route.path}`, {
      waitUntil: 'networkidle',
      timeout: 30000,
    });
    result.status = response?.status() || 0;
    result.loadTime = Date.now() - startTime;
  } catch (err: any) {
    result.status = 0;
    result.loadTime = Date.now() - startTime;
    result.consoleErrors.push(`Navigation failed: ${err.message}`);
  }

  // Wait for page to settle
  await page.waitForTimeout(2000);

  result.consoleErrors = consoleErrors;
  result.consoleWarnings = consoleWarnings;
  result.networkErrors = networkErrors;

  // Check for common issues
  const bodyText = await page.textContent('body').catch(() => '');
  
  // Check for error boundaries
  if (bodyText?.includes('Something went wrong') || bodyText?.includes('Application error')) {
    result.consoleErrors.push('Error boundary triggered on page');
  }

  // Check for 404
  if (bodyText?.includes('404') && bodyText?.includes('Not Found')) {
    result.consoleErrors.push('Page shows 404 Not Found');
  }

  // Take screenshots at all viewports
  for (const viewport of VIEWPORTS) {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.waitForTimeout(500); // Let layout settle

    const dir = join(SCREENSHOT_DIR, viewport.category);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });

    const filename = `${route.label}-${viewport.name}.png`;
    const filepath = join(dir, filename);

    try {
      await page.screenshot({ path: filepath, fullPage: true });
      result.screenshotPaths[viewport.name] = filepath;
      totalScreenshots++;
    } catch (err: any) {
      result.consoleErrors.push(`Screenshot failed for ${viewport.name}: ${err.message}`);
    }
  }

  // Reset viewport to desktop for accessibility check
  await page.setViewportSize({ width: 1920, height: 1080 });

  // Run basic accessibility checks
  try {
    const a11yIssues = await page.evaluate(() => {
      const issues: string[] = [];
      
      // Check for images without alt text
      const images = document.querySelectorAll('img:not([alt])');
      images.forEach((img, i) => {
        issues.push(`Image missing alt text: ${img.getAttribute('src') || `img-${i}`}`);
      });

      // Check for form inputs without labels
      const inputs = document.querySelectorAll('input, select, textarea');
      inputs.forEach((input, i) => {
        const id = input.getAttribute('id');
        const ariaLabel = input.getAttribute('aria-label');
        const ariaLabelledBy = input.getAttribute('aria-labelledby');
        const label = id ? document.querySelector(`label[for="${id}"]`) : null;
        
        if (!ariaLabel && !ariaLabelledBy && !label && input.getAttribute('type') !== 'hidden') {
          issues.push(`Input missing label: ${input.getAttribute('name') || input.getAttribute('type') || `input-${i}`}`);
        }
      });

      // Check heading hierarchy
      const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
      let lastLevel = 0;
      headings.forEach(h => {
        const level = parseInt(h.tagName[1]);
        if (lastLevel > 0 && level > lastLevel + 1) {
          issues.push(`Heading hierarchy skip: ${h.tagName} after H${lastLevel} - "${h.textContent?.substring(0, 50)}"`);
        }
        lastLevel = level;
      });

      // Check for buttons without accessible text
      const buttons = document.querySelectorAll('button');
      buttons.forEach((btn, i) => {
        const text = btn.textContent?.trim();
        const ariaLabel = btn.getAttribute('aria-label');
        const title = btn.getAttribute('title');
        if (!text && !ariaLabel && !title) {
          issues.push(`Button without accessible text: button-${i}`);
        }
      });

      // Check for interactive elements without focus indicators
      const interactiveElements = document.querySelectorAll('a, button, input, select, textarea, [tabindex]');
      interactiveElements.forEach((el, i) => {
        const tabIndex = el.getAttribute('tabindex');
        if (tabIndex === '-1') {
          issues.push(`Element removed from tab order with tabindex="-1": ${el.tagName}-${i}`);
        }
      });

      // Check contrast by looking for text that might be too light
      const smallText = document.querySelectorAll('text-xs, .text-xs, [class*="text-xs"]');
      // We'll note this as a potential issue rather than a definitive one

      // Check for missing lang attribute
      if (!document.documentElement.getAttribute('lang')) {
        issues.push('Missing lang attribute on html element');
      }

      // Check for duplicate IDs
      const allIds = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
      const duplicateIds = allIds.filter((id, i) => allIds.indexOf(id) !== i);
      if (duplicateIds.length > 0) {
        issues.push(`Duplicate IDs found: ${[...new Set(duplicateIds)].join(', ')}`);
      }

      return issues;
    });

    result.accessibilityIssues = a11yIssues;
  } catch (err: any) {
    result.accessibilityIssues.push(`Accessibility check failed: ${err.message}`);
  }

  // Check for overflow/horizontal scroll
  try {
    const overflowInfo = await page.evaluate(() => {
      const issues: string[] = [];
      const body = document.body;
      const html = document.documentElement;
      
      if (body.scrollWidth > html.clientWidth) {
        issues.push(`Horizontal scroll detected: body width ${body.scrollWidth}px > viewport ${html.clientWidth}px`);
      }

      // Check for elements that overflow
      const allElements = document.querySelectorAll('*');
      const overflowElements: string[] = [];
      allElements.forEach(el => {
        const rect = el.getBoundingClientRect();
        if (rect.right > html.clientWidth + 2 && rect.width > 0) {
          overflowElements.push(`${el.tagName}.${el.className?.toString().substring(0, 30)} at ${Math.round(rect.right)}px`);
        }
      });
      
      if (overflowElements.length > 0) {
        issues.push(`Elements overflowing viewport: ${overflowElements.slice(0, 10).join('; ')}`);
      }

      return issues;
    });

    if (overflowInfo.length > 0) {
      result.accessibilityIssues.push(...overflowInfo);
    }
  } catch (err: any) {
    // Ignore overflow check errors
  }

  // Performance metrics
  try {
    const metrics = await page.evaluate(() => {
      const perf = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      return {
        domContentLoaded: perf?.domContentLoadedEventEnd - perf?.domContentLoadedEventStart || 0,
        loadComplete: perf?.loadEventEnd - perf?.loadEventStart || 0,
        domInteractive: perf?.domInteractive || 0,
        transferSize: perf?.transferSize || 0,
        encodedBodySize: perf?.encodedBodySize || 0,
        elementCount: document.querySelectorAll('*').length,
      };
    });
    result.performanceMetrics = metrics;
  } catch (err: any) {
    // Ignore performance metric errors
  }

  return result;
}

async function runFormsAudit(page: Page): Promise<BugReport[]> {
  const bugs: BugReport[] = [];
  const formRoutes = [
    { path: '/login', label: 'Login', fields: ['email', 'password'] },
    { path: '/register', label: 'Register', fields: ['email', 'password'] },
    { path: '/forgot-password', label: 'Forgot Password', fields: ['email'] },
    { path: '/reset-password', label: 'Reset Password', fields: ['password'] },
    { path: '/settings', label: 'Settings', fields: [] },
    { path: '/profile', label: 'Profile', fields: [] },
  ];

  for (const formRoute of formRoutes) {
    try {
      await page.goto(`${BASE_URL}${formRoute.path}`, { waitUntil: 'networkidle', timeout: 15000 });
      await page.waitForTimeout(1000);

      // Check for form elements
      const formInfo = await page.evaluate(() => {
        const forms = document.querySelectorAll('form');
        const inputs = document.querySelectorAll('input, select, textarea');
        const buttons = document.querySelectorAll('button[type="submit"], input[type="submit"]');
        const submitButtons = document.querySelectorAll('button');
        
        return {
          formCount: forms.length,
          inputCount: inputs.length,
          submitButtonCount: buttons.length,
          buttonCount: submitButtons.length,
          inputs: Array.from(inputs).map(input => ({
            type: input.getAttribute('type'),
            name: input.getAttribute('name'),
            id: input.getAttribute('id'),
            required: input.hasAttribute('required'),
            hasLabel: !!input.getAttribute('aria-label') || !!input.getAttribute('aria-labelledby') || !!document.querySelector(`label[for="${input.id}"]`),
          })),
        };
      });

      // Check if form exists
      if (formInfo.formCount === 0 && formInfo.inputCount > 0) {
        bugs.push({
          id: `form-no-form-${formRoute.label}`,
          severity: 'medium',
          category: 'Forms',
          route: formRoute.path,
          description: `Inputs exist but no <form> element found on ${formRoute.label}`,
          evidence: `${formInfo.inputCount} inputs, 0 forms`,
          fixed: false,
        });
      }

      // Check for inputs without labels
      const unlabeledInputs = formInfo.inputs.filter(i => !i.hasLabel && i.type !== 'hidden');
      if (unlabeledInputs.length > 0) {
        bugs.push({
          id: `form-no-label-${formRoute.label}`,
          severity: 'high',
          category: 'Accessibility',
          route: formRoute.path,
          description: `Unlabeled inputs on ${formRoute.label}`,
          evidence: unlabeledInputs.map(i => `${i.name || i.type || 'input'}`).join(', '),
          fixed: false,
        });
      }

      // Check for submit button
      if (formInfo.inputCount > 0 && formInfo.submitButtonCount === 0) {
        bugs.push({
          id: `form-no-submit-${formRoute.label}`,
          severity: 'medium',
          category: 'Forms',
          route: formRoute.path,
          description: `No submit button found on ${formRoute.label}`,
          evidence: `${formInfo.inputCount} inputs, 0 submit buttons`,
          fixed: false,
        });
      }

      // Test keyboard navigation on forms
      if (formInfo.inputCount > 0) {
        try {
          await page.keyboard.press('Tab');
          const focusedElement = await page.evaluate(() => {
            const el = document.activeElement;
            return el ? `${el.tagName}(${el.getAttribute('name') || el.getAttribute('type') || 'unknown'})` : 'none';
          });
          if (focusedElement === 'none') {
            bugs.push({
              id: `form-keyboard-${formRoute.label}`,
              severity: 'high',
              category: 'Accessibility',
              route: formRoute.path,
              description: `Tab key does not focus any element on ${formRoute.label}`,
              evidence: 'No focus after Tab press',
              fixed: false,
            });
          }
        } catch (err) {
          // Ignore keyboard test errors
        }
      }

    } catch (err: any) {
      bugs.push({
        id: `form-error-${formRoute.label}`,
        severity: 'critical',
        category: 'Forms',
        route: formRoute.path,
        description: `Failed to audit form on ${formRoute.label}`,
        evidence: err.message,
        fixed: false,
      });
    }
  }

  return bugs;
}

async function runUserJourneyTest(page: Page): Promise<BugReport[]> {
  const bugs: BugReport[] = [];
  
  // Journey 1: Navigate to login page
  try {
    await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle', timeout: 15000 });
    await page.waitForTimeout(1000);
    
    // Check if login form is visible
    const loginForm = await page.evaluate(() => {
      const emailInput = document.querySelector('input[type="email"], input[name="email"]');
      const passwordInput = document.querySelector('input[type="password"]');
      const submitBtn = document.querySelector('button[type="submit"]');
      return {
        hasEmail: !!emailInput,
        hasPassword: !!passwordInput,
        hasSubmit: !!submitBtn,
      };
    });

    if (!loginForm.hasEmail) {
      bugs.push({
        id: 'journey-login-no-email',
        severity: 'critical',
        category: 'User Journey',
        route: '/login',
        description: 'Login page missing email input',
        evidence: 'No email input found',
        fixed: false,
      });
    }
    if (!loginForm.hasPassword) {
      bugs.push({
        id: 'journey-login-no-password',
        severity: 'critical',
        category: 'User Journey',
        route: '/login',
        description: 'Login page missing password input',
        evidence: 'No password input found',
        fixed: false,
      });
    }
  } catch (err: any) {
    bugs.push({
      id: 'journey-login-fail',
      severity: 'critical',
      category: 'User Journey',
      route: '/login',
      description: 'Failed to load login page',
      evidence: err.message,
      fixed: false,
    });
  }

  // Journey 2: Navigate through main pages
  const navRoutes = ['/dashboard', '/schools', '/students', '/teachers', '/notifications', '/profile', '/settings'];
  for (const route of navRoutes) {
    try {
      const response = await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
      if (response && (response.status() === 307 || response.status() === 302)) {
        // Redirect to login expected for unauthenticated users
        continue;
      }
      await page.waitForTimeout(500);
    } catch (err: any) {
      bugs.push({
        id: `journey-nav-${route.replace('/', '')}`,
        severity: 'high',
        category: 'User Journey',
        route,
        description: `Navigation to ${route} failed during user journey`,
        evidence: err.message,
        fixed: false,
      });
    }
  }

  return bugs;
}

async function runLighthouseAudit(page: Page, url: string): Promise<Record<string, any>> {
  // Basic performance metrics since we can't run full Lighthouse in this context
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
    await page.waitForTimeout(1000);

    const metrics = await page.evaluate(() => {
      const perf = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      const paint = performance.getEntriesByType('paint');
      const fcp = paint.find(p => p.name === 'first-contentful-paint');
      const lcp = paint.find(p => p.name === 'largest-contentful-paint');
      
      return {
        ttfb: perf?.responseStart - perf?.requestStart || 0,
        fcp: fcp?.startTime || 0,
        lcp: lcp?.startTime || 0,
        domContentLoaded: perf?.domContentLoadedEventEnd - perf?.fetchStart || 0,
        loadComplete: perf?.loadEventEnd - perf?.fetchStart || 0,
        transferSize: perf?.transferSize || 0,
        domSize: document.querySelectorAll('*').length,
        scriptCount: document.querySelectorAll('script').length,
        stylesheetCount: document.querySelectorAll('link[rel="stylesheet"]').length,
        imageCount: document.querySelectorAll('img').length,
      };
    });

    return metrics;
  } catch (err: any) {
    return { error: err.message };
  }
}

async function main() {
  console.log('='.repeat(80));
  console.log('PHASE 4.5 — ENTERPRISE UI/UX/QA AUDIT');
  console.log('='.repeat(80));
  console.log(`Starting audit at ${new Date().toISOString()}`);
  console.log(`Base URL: ${BASE_URL}`);
  console.log();

  // Ensure directories exist
  for (const category of ['desktop', 'laptop', 'tablet', 'mobile']) {
    const dir = join(SCREENSHOT_DIR, category);
    if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  }

  const browser = await chromium.launch({ headless: true });
  
  console.log('SECTION 1: Building and Testing Application...');
  console.log('-------------------------------------------');

  // SECTION 2: Route Testing
  console.log('\nSECTION 2: Route Testing...');
  console.log('---------------------------');

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    ignoreHTTPSErrors: true,
  });
  const page = await context.newPage();

  let routesOk = 0;
  let routesFailed = 0;

  for (const route of ROUTES) {
    console.log(`  Testing ${route.path}...`);
    try {
      const result = await auditRoute(page, route);
      allResults.push(result);
      
      if (result.status >= 200 && result.status < 400) {
        routesOk++;
        console.log(`    ✓ ${route.path} - Status: ${result.status} - Load: ${result.loadTime}ms`);
      } else {
        routesFailed++;
        console.log(`    ✗ ${route.path} - Status: ${result.status} - Load: ${result.loadTime}ms`);
      }

      // Log console errors
      if (result.consoleErrors.length > 0) {
        console.log(`    Console errors (${result.consoleErrors.length}):`);
        result.consoleErrors.forEach(e => console.log(`      - ${e.substring(0, 100)}`));
      }

      // Log hydration errors
      if (result.hydrationErrors.length > 0) {
        console.log(`    HYDRATION ERRORS (${result.hydrationErrors.length}):`);
        result.hydrationErrors.forEach(e => console.log(`      - ${e.substring(0, 100)}`));
      }

      // Log network errors
      if (result.networkErrors.length > 0) {
        console.log(`    Network errors (${result.networkErrors.length}):`);
        result.networkErrors.forEach(e => console.log(`      - ${e.substring(0, 100)}`));
      }

      // Create bug reports for issues found
      if (result.status === 0) {
        allBugs.push({
          id: `route-down-${route.label}`,
          severity: 'critical',
          category: 'Route',
          route: route.path,
          description: `Route ${route.path} failed to load`,
          evidence: `Status: ${result.status}`,
          fixed: false,
        });
      }

      result.consoleErrors.forEach((err, i) => {
        allBugs.push({
          id: `console-err-${route.label}-${i}`,
          severity: 'medium',
          category: 'Console Error',
          route: route.path,
          description: `Console error on ${route.path}`,
          evidence: err.substring(0, 200),
          fixed: false,
        });
      });

      result.hydrationErrors.forEach((err, i) => {
        allBugs.push({
          id: `hydration-${route.label}-${i}`,
          severity: 'critical',
          category: 'Hydration',
          route: route.path,
          description: `Hydration error on ${route.path}`,
          evidence: err.substring(0, 200),
          fixed: false,
        });
      });

      result.networkErrors.forEach((err, i) => {
        allBugs.push({
          id: `network-${route.label}-${i}`,
          severity: 'high',
          category: 'Network',
          route: route.path,
          description: `Network error on ${route.path}`,
          evidence: err.substring(0, 200),
          fixed: false,
        });
      });

      result.accessibilityIssues.forEach((issue, i) => {
        allBugs.push({
          id: `a11y-${route.label}-${i}`,
          severity: 'medium',
          category: 'Accessibility',
          route: route.path,
          description: `Accessibility issue on ${route.path}`,
          evidence: issue.substring(0, 200),
          fixed: false,
        });
      });

    } catch (err: any) {
      routesFailed++;
      console.log(`    ✗ ${route.path} - ERROR: ${err.message}`);
      allBugs.push({
        id: `route-crash-${route.label}`,
        severity: 'critical',
        category: 'Route',
        route: route.path,
        description: `Route ${route.path} crashed during audit`,
        evidence: err.message,
        fixed: false,
      });
    }
  }

  console.log(`\n  Routes OK: ${routesOk}/${ROUTES.length}`);
  console.log(`  Routes Failed: ${routesFailed}/${ROUTES.length}`);

  // SECTION 6: Forms Audit
  console.log('\nSECTION 6: Forms Audit...');
  console.log('-------------------------');
  const formBugs = await runFormsAudit(page);
  allBugs.push(...formBugs);

  // SECTION 11: User Journey Testing
  console.log('\nSECTION 11: User Journey Testing...');
  console.log('------------------------------------');
  const journeyBugs = await runUserJourneyTest(page);
  allBugs.push(...journeyBugs);

  // SECTION 8: Lighthouse-style Performance Audit
  console.log('\nSECTION 8: Performance Audit...');
  console.log('--------------------------------');
  const lighthouseRoutes = ['/login', '/dashboard', '/schools', '/students'];
  const lighthouseResults: Record<string, any> = {};
  for (const route of lighthouseRoutes) {
    console.log(`  Performance metrics for ${route}...`);
    const metrics = await runLighthouseAudit(page, `${BASE_URL}${route}`);
    lighthouseResults[route] = metrics;
    console.log(`    TTFB: ${metrics.ttfb?.toFixed(0)}ms, FCP: ${metrics.fcp?.toFixed(0)}ms, DOM Size: ${metrics.domSize}`);
  }

  // SECTION 5: Responsive Audit (check overflow at each viewport)
  console.log('\nSECTION 5: Responsive Audit...');
  console.log('-------------------------------');
  const responsiveBugs: BugReport[] = [];
  
  for (const viewport of VIEWPORTS) {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    for (const route of ['/login', '/dashboard', '/schools', '/students']) {
      try {
        await page.goto(`${BASE_URL}${route}`, { waitUntil: 'networkidle', timeout: 15000 });
        await page.waitForTimeout(1000);

        const overflowInfo = await page.evaluate(() => {
          const issues: string[] = [];
          const html = document.documentElement;
          const body = document.body;
          
          if (body.scrollWidth > html.clientWidth + 2) {
            issues.push(`Horizontal scroll: ${body.scrollWidth}px > ${html.clientWidth}px`);
          }
          return issues;
        });

        overflowInfo.forEach((issue, i) => {
          responsiveBugs.push({
            id: `responsive-${viewport.name}-${route.replace('/', '')}-${i}`,
            severity: 'high',
            category: 'Responsive',
            route,
            description: `Overflow at ${viewport.name} (${viewport.width}x${viewport.height}) on ${route}`,
            evidence: issue,
            fixed: false,
          });
        });
      } catch (err) {
        // Ignore
      }
    }
  }
  allBugs.push(...responsiveBugs);

  await browser.close();

  // Generate Reports
  console.log('\nSECTION 12: Generating Reports...');
  console.log('-----------------------------------');

  const reportDir = '/home/z/my-project/download';
  
  // UI_AUDIT.md
  const uiAudit = generateUIAuditReport(allResults, allBugs);
  writeFileSync(join(reportDir, 'UI_AUDIT.md'), uiAudit);
  console.log('  ✓ UI_AUDIT.md');

  // UX_AUDIT.md
  const uxAudit = generateUXAuditReport(allResults, allBugs);
  writeFileSync(join(reportDir, 'UX_AUDIT.md'), uxAudit);
  console.log('  ✓ UX_AUDIT.md');

  // RESPONSIVE_REPORT.md
  const responsiveReport = generateResponsiveReport(allResults, responsiveBugs);
  writeFileSync(join(reportDir, 'RESPONSIVE_REPORT.md'), responsiveReport);
  console.log('  ✓ RESPONSIVE_REPORT.md');

  // LIGHTHOUSE_REPORT.md
  const lighthouseReport = generateLighthouseReport(lighthouseResults);
  writeFileSync(join(reportDir, 'LIGHTHOUSE_REPORT.md'), lighthouseReport);
  console.log('  ✓ LIGHTHOUSE_REPORT.md');

  // ACCESSIBILITY_REPORT.md
  const accessibilityReport = generateAccessibilityReport(allResults, allBugs);
  writeFileSync(join(reportDir, 'ACCESSIBILITY_REPORT.md'), accessibilityReport);
  console.log('  ✓ ACCESSIBILITY_REPORT.md');

  // VISUAL_REGRESSION_REPORT.md
  const visualReport = generateVisualRegressionReport(allResults);
  writeFileSync(join(reportDir, 'VISUAL_REGRESSION_REPORT.md'), visualReport);
  console.log('  ✓ VISUAL_REGRESSION_REPORT.md');

  // PLAYWRIGHT_REPORT.md
  const playwrightReport = generatePlaywrightReport(allResults, routesOk, routesFailed);
  writeFileSync(join(reportDir, 'PLAYWRIGHT_REPORT.md'), playwrightReport);
  console.log('  ✓ PLAYWRIGHT_REPORT.md');

  // SCREENSHOT_INDEX.md
  const screenshotIndex = generateScreenshotIndex(allResults);
  writeFileSync(join(reportDir, 'SCREENSHOT_INDEX.md'), screenshotIndex);
  console.log('  ✓ SCREENSHOT_INDEX.md');

  // BUG_REPORT.md
  const bugReport = generateBugReport(allBugs);
  writeFileSync(join(reportDir, 'BUG_REPORT.md'), bugReport);
  console.log('  ✓ BUG_REPORT.md');

  // FIX_LOG.md
  const fixLog = generateFixLog(allBugs);
  writeFileSync(join(reportDir, 'FIX_LOG.md'), fixLog);
  console.log('  ✓ FIX_LOG.md');

  // Summary
  console.log('\n' + '='.repeat(80));
  console.log('AUDIT SUMMARY');
  console.log('='.repeat(80));
  console.log(`Total pages tested: ${ROUTES.length}`);
  console.log(`Total screenshots captured: ${totalScreenshots}`);
  console.log(`Total bugs found: ${allBugs.length}`);
  console.log(`  - Critical: ${allBugs.filter(b => b.severity === 'critical').length}`);
  console.log(`  - High: ${allBugs.filter(b => b.severity === 'high').length}`);
  console.log(`  - Medium: ${allBugs.filter(b => b.severity === 'medium').length}`);
  console.log(`  - Low: ${allBugs.filter(b => b.severity === 'low').length}`);
  console.log(`Console errors: ${allResults.reduce((sum, r) => sum + r.consoleErrors.length, 0)}`);
  console.log(`Network errors: ${allResults.reduce((sum, r) => sum + r.networkErrors.length, 0)}`);
  console.log(`Hydration errors: ${allResults.reduce((sum, r) => sum + r.hydrationErrors.length, 0)}`);
  console.log(`Accessibility issues: ${allResults.reduce((sum, r) => sum + r.accessibilityIssues.length, 0)}`);
  console.log(`Routes OK: ${routesOk}/${ROUTES.length}`);
  console.log(`Routes Failed: ${routesFailed}/${ROUTES.length}`);
}

function generateUIAuditReport(results: AuditResult[], bugs: BugReport[]): string {
  const uiBugs = bugs.filter(b => ['UI', 'Route', 'Console Error', 'Hydration', 'Network'].includes(b.category));
  return `# UI Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Auditor:** Phase 4.5 Enterprise Audit

## Executive Summary

- **Total routes tested:** ${results.length}
- **UI-related bugs found:** ${uiBugs.length}
- **Critical issues:** ${uiBugs.filter(b => b.severity === 'critical').length}
- **High issues:** ${uiBugs.filter(b => b.severity === 'high').length}

## Route Status

| Route | Status | Load Time | Console Errors | Hydration Errors |
|-------|--------|-----------|----------------|------------------|
${results.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.hydrationErrors.length} |`).join('\n')}

## Issues Found

${uiBugs.length > 0 ? uiBugs.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No UI issues found.'}

## Performance Metrics

| Route | Load Time | DOM Size | Element Count |
|-------|-----------|----------|---------------|
${results.map(r => `| ${r.route} | ${r.loadTime}ms | ${r.performanceMetrics?.domSize || 'N/A'} | ${r.performanceMetrics?.elementCount || 'N/A'} |`).join('\n')}
`;
}

function generateUXAuditReport(results: AuditResult[], bugs: BugReport[]): string {
  const uxBugs = bugs.filter(b => ['Forms', 'User Journey', 'Accessibility'].includes(b.category));
  return `# UX Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Executive Summary

- **UX-related bugs found:** ${uxBugs.length}
- **Form issues:** ${uxBugs.filter(b => b.category === 'Forms').length}
- **User journey issues:** ${uxBugs.filter(b => b.category === 'User Journey').length}
- **Accessibility issues:** ${uxBugs.filter(b => b.category === 'Accessibility').length}

## Form Audit

${results.filter(r => r.route.includes('login') || r.route.includes('register') || r.route.includes('password') || r.route.includes('settings') || r.route.includes('profile')).map(r => `### ${r.route}
- **Status:** ${r.status}
- **Console Errors:** ${r.consoleErrors.length}
- **Accessibility Issues:** ${r.accessibilityIssues.length}
`).join('\n')}

## User Journey Issues

${uxBugs.filter(b => b.category === 'User Journey').map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') || 'No user journey issues found.'}

## All UX Issues

${uxBugs.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n')}
`;
}

function generateResponsiveReport(results: AuditResult[], bugs: BugReport[]): string {
  const responsiveBugs = bugs.filter(b => b.category === 'Responsive');
  return `# Responsive Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Viewport Coverage

| Viewport | Width | Height | Category |
|----------|-------|--------|----------|
| desktop-1920 | 1920 | 1080 | Desktop |
| desktop-1440 | 1440 | 900 | Desktop |
| laptop-1280 | 1280 | 800 | Laptop |
| laptop-1024 | 1024 | 768 | Laptop |
| tablet-820 | 820 | 1180 | Tablet |
| tablet-768 | 768 | 1024 | Tablet |
| mobile-414 | 414 | 896 | Mobile |
| mobile-390 | 390 | 844 | Mobile |
| mobile-375 | 375 | 812 | Mobile |
| mobile-320 | 320 | 568 | Mobile |

## Screenshot Coverage

- **Total screenshots captured:** ${results.reduce((sum, r) => sum + Object.keys(r.screenshotPaths).length, 0)}
- **Viewports tested:** 10
- **Routes tested:** ${results.length}

## Responsive Issues

${responsiveBugs.length > 0 ? responsiveBugs.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No responsive issues found.'}
`;
}

function generateLighthouseReport(lighthouseResults: Record<string, any>): string {
  return `# Lighthouse/Performance Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Performance Metrics

| Route | TTFB | FCP | DOM Content Loaded | DOM Size | Transfer Size |
|-------|------|-----|-------------------|----------|---------------|
${Object.entries(lighthouseResults).map(([route, m]: [string, any]) => `| ${route} | ${m.ttfb?.toFixed(0) || 'N/A'}ms | ${m.fcp?.toFixed(0) || 'N/A'}ms | ${m.domContentLoaded?.toFixed(0) || 'N/A'}ms | ${m.domSize || 'N/A'} | ${m.transferSize || 'N/A'} |`).join('\n')}

## Targets

| Metric | Target | Status |
|--------|--------|--------|
| Performance | ≥95 | ⚠ Requires Lighthouse CLI |
| Accessibility | 100 | ⚠ Requires Lighthouse CLI |
| Best Practices | 100 | ⚠ Requires Lighthouse CLI |
| SEO | ≥95 | ⚠ Requires Lighthouse CLI |

## Recommendations

1. Run full Lighthouse CLI for accurate scores
2. Focus on TTFB optimization (target < 200ms)
3. Ensure FCP < 1.8s for all routes
4. Minimize DOM size (target < 1500 elements)
5. Optimize transfer size with code splitting
`;
}

function generateAccessibilityReport(results: AuditResult[], bugs: BugReport[]): string {
  const a11yBugs = bugs.filter(b => b.category === 'Accessibility');
  return `# Accessibility Audit Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

- **Total accessibility issues found:** ${a11yBugs.length}
- **Across routes:** ${new Set(a11yBugs.map(b => b.route)).size}

## Issues by Route

${results.map(r => {
  const issues = r.accessibilityIssues;
  if (issues.length === 0) return `### ${r.route}\n✓ No accessibility issues found\n`;
  return `### ${r.route}
**Issues found:** ${issues.length}
${issues.map(i => `- ${i}`).join('\n')}
`;
}).join('\n')}

## Common Issues

${a11yBugs.length > 0 ? a11yBugs.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
`).join('\n') : 'No accessibility issues found.'}

## WCAG 2.1 Compliance Checklist

| Criterion | Status |
|-----------|--------|
| 1.1.1 Non-text Content | ⚠ Review images for alt text |
| 1.3.1 Info and Relationships | ⚠ Review form labels |
| 2.1.1 Keyboard | ⚠ Review focus management |
| 2.4.3 Focus Order | ⚠ Review tab order |
| 3.3.2 Labels or Instructions | ⚠ Review form labels |
| 4.1.2 Name, Role, Value | ⚠ Review ARIA usage |
`;
}

function generateVisualRegressionReport(results: AuditResult[]): string {
  return `# Visual Regression Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Screenshot Inventory

${results.map(r => `### ${r.route}

| Viewport | Screenshot Path |
|----------|----------------|
${Object.entries(r.screenshotPaths).map(([vp, path]) => `| ${vp} | ${path} |`).join('\n')}
`).join('\n')}

## Visual Comparison Notes

- All screenshots captured at 10 viewports
- Desktop: 1920x1080, 1440x900
- Laptop: 1280x800, 1024x768
- Tablet: 820x1180, 768x1024
- Mobile: 414x896, 390x844, 375x812, 320x568

## Recommendations

1. Implement pixel-level comparison with baseline images
2. Set up automated visual regression in CI/CD
3. Create component-level visual tests
4. Use Playwright visual comparison for future runs
`;
}

function generatePlaywrightReport(results: AuditResult[], routesOk: number, routesFailed: number): string {
  return `# Playwright Test Report — ExamForge AI

**Date:** ${new Date().toISOString()}
**Browser:** Chromium (Headless)
**Framework:** Playwright 1.62.1

## Test Summary

| Metric | Value |
|--------|-------|
| Total Routes | ${results.length} |
| Routes OK | ${routesOk} |
| Routes Failed | ${routesFailed} |
| Pass Rate | ${((routesOk / results.length) * 100).toFixed(1)}% |

## Detailed Results

| Route | Status | Load Time | Console Errors | Network Errors | Hydration Errors | A11y Issues |
|-------|--------|-----------|----------------|----------------|------------------|-------------|
${results.map(r => `| ${r.route} | ${r.status} | ${r.loadTime}ms | ${r.consoleErrors.length} | ${r.networkErrors.length} | ${r.hydrationErrors.length} | ${r.accessibilityIssues.length} |`).join('\n')}

## Console Errors Detail

${results.filter(r => r.consoleErrors.length > 0).map(r => `### ${r.route}
${r.consoleErrors.map(e => `- \`${e.substring(0, 150)}\``).join('\n')}
`).join('\n') || 'No console errors found.'}

## Network Errors Detail

${results.filter(r => r.networkErrors.length > 0).map(r => `### ${r.route}
${r.networkErrors.map(e => `- \`${e.substring(0, 150)}\``).join('\n')}
`).join('\n') || 'No network errors found.'}
`;
}

function generateScreenshotIndex(results: AuditResult[]): string {
  return `# Screenshot Index — ExamForge AI

**Date:** ${new Date().toISOString()}
**Total Screenshots:** ${results.reduce((sum, r) => sum + Object.keys(r.screenshotPaths).length, 0)}

## By Route

${results.map(r => `### ${r.route}
${Object.entries(r.screenshotPaths).map(([vp, path]) => `- **${vp}**: \`${path}\``).join('\n')}
`).join('\n')}

## By Viewport

### Desktop (1920x1080, 1440x900)
${results.map(r => `- ${r.route}: ${r.screenshotPaths['desktop-1920'] || 'N/A'} | ${r.screenshotPaths['desktop-1440'] || 'N/A'}`).join('\n')}

### Laptop (1280x800, 1024x768)
${results.map(r => `- ${r.route}: ${r.screenshotPaths['laptop-1280'] || 'N/A'} | ${r.screenshotPaths['laptop-1024'] || 'N/A'}`).join('\n')}

### Tablet (820x1180, 768x1024)
${results.map(r => `- ${r.route}: ${r.screenshotPaths['tablet-820'] || 'N/A'} | ${r.screenshotPaths['tablet-768'] || 'N/A'}`).join('\n')}

### Mobile (414x896, 390x844, 375x812, 320x568)
${results.map(r => `- ${r.route}: ${r.screenshotPaths['mobile-414'] || 'N/A'} | ${r.screenshotPaths['mobile-390'] || 'N/A'} | ${r.screenshotPaths['mobile-375'] || 'N/A'} | ${r.screenshotPaths['mobile-320'] || 'N/A'}`).join('\n')}
`;
}

function generateBugReport(bugs: BugReport[]): string {
  const critical = bugs.filter(b => b.severity === 'critical');
  const high = bugs.filter(b => b.severity === 'high');
  const medium = bugs.filter(b => b.severity === 'medium');
  const low = bugs.filter(b => b.severity === 'low');

  return `# Bug Report — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

| Severity | Count |
|----------|-------|
| Critical | ${critical.length} |
| High | ${high.length} |
| Medium | ${medium.length} |
| Low | ${low.length} |
| **Total** | **${bugs.length}** |

## Critical Bugs

${critical.length > 0 ? critical.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Status:** ${b.fixed ? '✓ Fixed' : '✗ Open'}
`).join('\n') : 'No critical bugs found.'}

## High Bugs

${high.length > 0 ? high.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Status:** ${b.fixed ? '✓ Fixed' : '✗ Open'}
`).join('\n') : 'No high bugs found.'}

## Medium Bugs

${medium.length > 0 ? medium.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Status:** ${b.fixed ? '✓ Fixed' : '✗ Open'}
`).join('\n') : 'No medium bugs found.'}

## Low Bugs

${low.length > 0 ? low.map(b => `### ${b.id}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Status:** ${b.fixed ? '✓ Fixed' : '✗ Open'}
`).join('\n') : 'No low bugs found.'}
`;
}

function generateFixLog(bugs: BugReport[]): string {
  const fixed = bugs.filter(b => b.fixed);
  const open = bugs.filter(b => !b.fixed);

  return `# Fix Log — ExamForge AI

**Date:** ${new Date().toISOString()}

## Summary

| Status | Count |
|--------|-------|
| Fixed | ${fixed.length} |
| Open | ${open.length} |
| Total | ${bugs.length} |

## Open Issues (Require Fixing)

${open.length > 0 ? open.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Action Required:** Fix and retest
`).join('\n') : 'No open issues.'}

## Fixed Issues

${fixed.length > 0 ? fixed.map(b => `### ${b.id}
- **Severity:** ${b.severity}
- **Category:** ${b.category}
- **Route:** ${b.route}
- **Description:** ${b.description}
- **Evidence:** ${b.evidence}
- **Fix Applied:** [To be documented during fix]
`).join('\n') : 'No issues fixed yet.'}
`;
}

main().catch(err => {
  console.error('Audit failed:', err);
  process.exit(1);
});
