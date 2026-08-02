import { chromium } from 'playwright';
import { execSync } from 'child_process';
import fs from 'fs';

const PROD_URL = 'https://my-project-ei3uw3f3h-austinchima183-2014s-projects.vercel.app';
const OUTPUT_DIR = '/home/z/my-project/download';

// Run Lighthouse using the CLI
const pages = [
  { url: `${PROD_URL}/login`, name: 'login' },
  { url: `${PROD_URL}/register`, name: 'register' },
];

for (const page of pages) {
  console.log(`\nRunning Lighthouse on ${page.name}...`);
  try {
    const cmd = `npx lighthouse "${page.url}" --output=json --output-path="${OUTPUT_DIR}/lighthouse-${page.name}.json" --chrome-flags="--headless --no-sandbox" --only-categories=performance,accessibility,best-practices,seo --quiet`;
    execSync(cmd, { timeout: 120000 });
    console.log(`  ✅ Lighthouse report saved for ${page.name}`);
  } catch (e) {
    console.log(`  ⚠️ Lighthouse failed for ${page.name}: ${e.message.slice(0, 100)}`);
  }
}

// Parse and display results
for (const page of pages) {
  const reportPath = `${OUTPUT_DIR}/lighthouse-${page.name}.json`;
  if (fs.existsSync(reportPath)) {
    try {
      const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
      const cats = report.categories || {};
      console.log(`\n=== Lighthouse Results: ${page.name} ===`);
      for (const [key, cat] of Object.entries(cats)) {
        const score = Math.round(cat.score * 100);
        const emoji = score >= 90 ? '🟢' : score >= 70 ? '🟡' : '🔴';
        console.log(`  ${emoji} ${cat.title}: ${score}/100`);
      }
      
      // Get specific metrics
      const audits = report.audits || {};
      const metrics = {
        'first-contentful-paint': 'FCP',
        'largest-contentful-paint': 'LCP',
        'interactive': 'TTI',
        'total-blocking-time': 'TBT',
        'cumulative-layout-shift': 'CLS',
        'speed-index': 'Speed Index',
      };
      console.log('\n  Core Web Vitals:');
      for (const [key, label] of Object.entries(metrics)) {
        if (audits[key]) {
          console.log(`    ${label}: ${audits[key].displayValue}`);
        }
      }
    } catch (e) {
      console.log(`  ⚠️ Could not parse report for ${page.name}`);
    }
  }
}
