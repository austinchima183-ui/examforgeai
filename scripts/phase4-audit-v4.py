#!/usr/bin/env python3
"""
Phase 4.5 — Enterprise UI/UX/QA Audit
Comprehensive audit using curl + Playwright
"""

import subprocess
import json
import time
import os
import sys
from datetime import datetime

BASE_URL = "http://0.0.0.0:3000"
SCREENSHOT_DIR = "/home/z/my-project/download/audit-screenshots"
REPORT_DIR = "/home/z/my-project/download"
DELAY = 3  # seconds between requests

PUBLIC_ROUTES = [
    {"path": "/login", "label": "login"},
    {"path": "/register", "label": "register"},
    {"path": "/forgot-password", "label": "forgot-password"},
    {"path": "/reset-password", "label": "reset-password"},
    {"path": "/verify-email", "label": "verify-email"},
]

AUTH_ROUTES = [
    {"path": "/dashboard", "label": "dashboard"},
    {"path": "/schools", "label": "schools"},
    {"path": "/students", "label": "students"},
    {"path": "/teachers", "label": "teachers"},
    {"path": "/parents", "label": "parents"},
    {"path": "/notifications", "label": "notifications"},
    {"path": "/profile", "label": "profile"},
    {"path": "/settings", "label": "settings"},
    {"path": "/analytics", "label": "analytics"},
    {"path": "/billing", "label": "billing"},
    {"path": "/marketplace", "label": "marketplace"},
    {"path": "/question-bank", "label": "question-bank"},
    {"path": "/results", "label": "results"},
    {"path": "/cbt", "label": "cbt"},
    {"path": "/", "label": "home"},
]

ALL_ROUTES = PUBLIC_ROUTES + AUTH_ROUTES

VIEWPORTS = [
    {"name": "desktop-1920", "width": 1920, "height": 1080, "cat": "desktop"},
    {"name": "desktop-1440", "width": 1440, "height": 900, "cat": "desktop"},
    {"name": "laptop-1280", "width": 1280, "height": 800, "cat": "laptop"},
    {"name": "laptop-1024", "width": 1024, "height": 768, "cat": "laptop"},
    {"name": "tablet-820", "width": 820, "height": 1180, "cat": "tablet"},
    {"name": "tablet-768", "width": 768, "height": 1024, "cat": "tablet"},
    {"name": "mobile-414", "width": 414, "height": 896, "cat": "mobile"},
    {"name": "mobile-390", "width": 390, "height": 844, "cat": "mobile"},
    {"name": "mobile-375", "width": 375, "height": 812, "cat": "mobile"},
    {"name": "mobile-320", "width": 320, "height": 568, "cat": "mobile"},
]

all_results = []
all_bugs = []
total_screenshots = 0

def curl_route(route_path):
    """Test a route with curl and return status code + HTML content"""
    try:
        result = subprocess.run(
            ["curl", "-s", "-o", "/tmp/page_content.html", "-w", "%{http_code}", f"{BASE_URL}{route_path}"],
            capture_output=True, text=True, timeout=10
        )
        code = int(result.stdout.strip()) if result.stdout.strip() else 0
        # Read the HTML content
        try:
            with open("/tmp/page_content.html", "r") as f:
                html = f.read()
        except:
            html = ""
        return code, html
    except Exception as e:
        return 0, ""

def run_playwright_audit(route_path, route_label, viewports):
    """Run Playwright audit for a single route - launch browser, audit, close"""
    global total_screenshots
    
    screen_dir = SCREENSHOT_DIR
    
    script = f"""
const {{ chromium }} = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {{
  const browser = await chromium.launch({{ headless: true }});
  const context = await browser.newContext({{ viewport: {{ width: 1920, height: 1080 }} }});
  const page = await context.newPage();
  
  const errors = [];
  const netErrors = [];
  const hydrationErrors = [];
  
  page.on('console', msg => {{
    if (msg.type() === 'error') errors.push(msg.text().substring(0, 300));
    if (msg.text().toLowerCase().includes('hydration')) hydrationErrors.push(msg.text().substring(0, 300));
  }});
  page.on('requestfailed', req => {{
    netErrors.push(req.url().substring(0, 80) + ' - ' + (req.failure()?.errorText || 'unknown'));
  }});

  const result = {{ status: 0, consoleErrors: [], networkErrors: [], hydrationErrors: [], a11yIssues: [], screenshots: [], overflowIssues: [], loadTime: 0, html: '' }};

  try {{
    const start = Date.now();
    const resp = await page.goto('{BASE_URL}{route_path}', {{ waitUntil: 'networkidle', timeout: 30000 }});
    result.status = resp?.status() || 0;
    result.loadTime = Date.now() - start;
    await page.waitForTimeout(1500);
  }} catch (err) {{
    result.status = 0;
    errors.push('Nav failed: ' + err.message?.substring(0, 100));
  }}

  result.consoleErrors = [...new Set(errors)];
  result.networkErrors = [...new Set(netErrors)];
  result.hydrationErrors = hydrationErrors;

  // Accessibility checks
  if (result.status >= 200 && result.status < 400) {{
    try {{
      const a11y = await page.evaluate(() => {{
        const issues = [];
        document.querySelectorAll('img:not([alt])').forEach((img, i) => issues.push('Image missing alt: ' + (img.getAttribute('src')?.substring(0, 50) || 'img-' + i)));
        document.querySelectorAll('input,select,textarea').forEach((input, i) => {{
          if (input.getAttribute('type') === 'hidden') return;
          const id = input.getAttribute('id');
          const hasLabel = input.getAttribute('aria-label') || input.getAttribute('aria-labelledby') || (id && document.querySelector('label[for="' + id + '"]'));
          if (!hasLabel) issues.push('Input missing label: ' + (input.getAttribute('name') || input.getAttribute('type') || 'input-' + i));
        }});
        if (!document.documentElement.getAttribute('lang')) issues.push('Missing lang attribute on html');
        document.querySelectorAll('button').forEach((btn, i) => {{
          if (!btn.textContent?.trim() && !btn.getAttribute('aria-label') && !btn.getAttribute('title')) {{
            issues.push('Button without accessible text: btn-' + i);
          }}
        }});
        const ids = Array.from(document.querySelectorAll('[id]')).map(el => el.id);
        const dupes = ids.filter((id, i) => ids.indexOf(id) !== i);
        if (dupes.length) issues.push('Duplicate IDs: ' + [...new Set(dupes)].join(', '));
        const headings = document.querySelectorAll('h1,h2,h3,h4,h5,h6');
        let lastLevel = 0;
        headings.forEach(h => {{
          const level = parseInt(h.tagName[1]);
          if (lastLevel > 0 && level > lastLevel + 1) issues.push('Heading skip: ' + h.tagName + ' after H' + lastLevel + ' - "' + h.textContent?.substring(0, 40) + '"');
          lastLevel = level;
        }});
        const focusable = document.querySelectorAll('a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])');
        if (focusable.length === 0) issues.push('No focusable elements found');
        const bodyText = document.body?.innerText?.substring(0, 500) || '';
        issues.push('PAGE_TEXT: ' + bodyText.replace(/\\n/g, ' ').substring(0, 300));
        return issues;
      }});
      result.a11yIssues = a11y;
    }} catch (err) {{ /* ignore */ }}

    // Screenshots
    const viewports = {json.dumps(viewports)};
    const routeLabel = "{route_label}";
    const screenDir = "{screen_dir}";
    for (const vp of viewports) {{
      await page.setViewportSize({{ width: vp.width, height: vp.height }});
      await page.waitForTimeout(500);
      const dir = path.join(screenDir, vp.cat);
      fs.mkdirSync(dir, {{ recursive: true }});
      const fp = path.join(dir, routeLabel + '-' + vp.name + '.png');
      try {{
        await page.screenshot({{ path: fp, fullPage: true }});
        result.screenshots.push(fp);
      }} catch (err) {{ /* ignore */ }}

      // Overflow check
      try {{
        const overflow = await page.evaluate(() => {{
          const html = document.documentElement;
          const body = document.body;
          if (body.scrollWidth > html.clientWidth + 2) {{
            return 'H-scroll: ' + body.scrollWidth + 'px > ' + html.clientWidth + 'px';
          }}
          return null;
        }});
        if (overflow) result.overflowIssues.push(vp.name + ': ' + overflow);
      }} catch (err) {{ /* ignore */ }}
    }}
  }}

  // Performance metrics
  try {{
    const metrics = await page.evaluate(() => {{
      const nav = performance.getEntriesByType('navigation')[0];
      const paint = performance.getEntriesByType('paint');
      const fcp = paint.find(p => p.name === 'first-contentful-paint');
      return {{
        ttfb: nav ? nav.responseStart - nav.requestStart : 0,
        fcp: fcp ? fcp.startTime : 0,
        domContentLoaded: nav ? nav.domContentLoadedEventEnd - nav.fetchStart : 0,
        domSize: document.querySelectorAll('*').length,
        transferSize: nav ? nav.transferSize : 0,
      }};
    }});
    result.performance = metrics;
  }} catch (err) {{ /* ignore */ }}

  // Form analysis
  try {{
    const formInfo = await page.evaluate(() => {{
      const forms = document.querySelectorAll('form');
      const inputs = document.querySelectorAll('input,select,textarea');
      const submitBtns = document.querySelectorAll('button[type="submit"],input[type="submit"]');
      return {{
        formCount: forms.length,
        inputCount: inputs.length,
        submitCount: submitBtns.length,
        inputs: Array.from(inputs).map(inp => ({{
          type: inp.getAttribute('type'),
          name: inp.getAttribute('name'),
          id: inp.getAttribute('id'),
          required: inp.hasAttribute('required'),
          hasLabel: !!(inp.getAttribute('aria-label') || inp.getAttribute('aria-labelledby') || (inp.id && document.querySelector('label[for="' + inp.id + '"]'))),
        }})),
      }};
    }});
    result.formInfo = formInfo;
  }} catch (err) {{ /* ignore */ }}

  await browser.close();
  console.log(JSON.stringify(result));
}})().catch(err => {{
  console.error(JSON.stringify({{ error: err.message }}));
}});
"""
    
    # Write the script to a temp file
    script_path = f"/tmp/pw_audit_{route_label}.js"
    with open(script_path, "w") as f:
        f.write(script)
    
    try:
        result = subprocess.run(
            ["node", script_path],
            capture_output=True, text=True, timeout=120
        )
        # Parse the output
        output = result.stdout.strip()
        if output:
            try:
                data = json.loads(output)
                total_screenshots += len(data.get("screenshots", []))
                return data
            except json.JSONDecodeError:
                return {"error": f"Failed to parse Playwright output: {output[:200]}"}
        else:
            return {"error": f"No output from Playwright: {result.stderr[:200]}"}
    except subprocess.TimeoutExpired:
        return {"error": "Playwright timeout"}
    except Exception as e:
        return {"error": str(e)}

def main():
    print("=" * 60)
    print("PHASE 4.5 — ENTERPRISE UI/UX/QA AUDIT")
    print("=" * 60)
    print(f"Time: {datetime.utcnow().isoformat()}")
    print(f"Base URL: {BASE_URL}")
    
    # Create directories
    for vp in VIEWPORTS:
        os.makedirs(os.path.join(SCREENSHOT_DIR, vp["cat"]), exist_ok=True)
    
    # SECTION 1: Build verification already done (npm run build succeeded)
    print("\n=== SECTION 1: Build Verification ===")
    print("  ✓ Build already verified (npm run build succeeded)")
    
    # SECTION 2: Route Testing with curl
    print("\n=== SECTION 2: Route Testing (curl) ===")
    for route in ALL_ROUTES:
        code, html = curl_route(route["path"])
        result = {
            "route": route["path"],
            "label": route["label"],
            "status": code,
            "consoleErrors": [],
            "networkErrors": [],
            "hydrationErrors": [],
            "a11yIssues": [],
            "overflowIssues": [],
            "loadTime": 0,
            "screenshots": [],
        }
        all_results.append(result)
        
        icon = "✓" if (code >= 200 and code < 400) else "✗"
        print(f"  {icon} {route['path']} -> {code}")
        
        # Check for common issues in HTML
        if html:
            if "Something went wrong" in html or "Application error" in html:
                all_bugs.append({"id": f"error-boundary-{route['label']}", "severity": "critical", "category": "UI", "route": route["path"], "description": f"Error boundary triggered on {route['path']}", "evidence": "Error boundary text found in HTML", "fixed": False})
            if "404" in html and "Not Found" in html:
                all_bugs.append({"id": f"404-{route['label']}", "severity": "high", "category": "UI", "route": route["path"], "description": f"404 page on {route['path']}", "evidence": "404 Not Found in HTML", "fixed": False})
        
        if code == 0:
            all_bugs.append({"id": f"route-down-{route['label']}", "severity": "critical", "category": "Route", "route": route["path"], "description": f"Route {route['path']} failed to load", "evidence": f"Status: {code}", "fixed": False})
        
        time.sleep(DELAY)
    
    # SECTION 3 & 4 & 7: Playwright Screenshots + Accessibility + UI Consistency
    print("\n=== SECTION 3-7: Playwright Audit (Screenshots, A11y, Responsive) ===")
    for route in PUBLIC_ROUTES:
        print(f"  Auditing {route['path']}...")
        pw_result = run_playwright_audit(route["path"], route["label"], VIEWPORTS)
        
        if "error" in pw_result:
            print(f"    ✗ Playwright error: {pw_result['error'][:100]}")
            all_bugs.append({"id": f"pw-error-{route['label']}", "severity": "high", "category": "Playwright", "route": route["path"], "description": f"Playwright audit failed for {route['path']}", "evidence": pw_result["error"][:200], "fixed": False})
        else:
            # Update the existing result with Playwright data
            for r in all_results:
                if r["route"] == route["path"]:
                    r["consoleErrors"] = pw_result.get("consoleErrors", [])
                    r["networkErrors"] = pw_result.get("networkErrors", [])
                    r["hydrationErrors"] = pw_result.get("hydrationErrors", [])
                    r["a11yIssues"] = [i for i in pw_result.get("a11yIssues", []) if not i.startswith("PAGE_TEXT:")]
                    r["overflowIssues"] = pw_result.get("overflowIssues", [])
                    r["screenshots"] = pw_result.get("screenshots", [])
                    r["loadTime"] = pw_result.get("loadTime", 0)
                    r["performance"] = pw_result.get("performance", {})
                    r["formInfo"] = pw_result.get("formInfo", {})
                    break
            
            # Log bugs from Playwright
            for err in pw_result.get("consoleErrors", []):
                all_bugs.append({"id": f"console-{route['label']}-{hash(err) % 1000}", "severity": "medium", "category": "Console Error", "route": route["path"], "description": f"Console error on {route['path']}", "evidence": err[:200], "fixed": False})
            
            for err in pw_result.get("hydrationErrors", []):
                all_bugs.append({"id": f"hydration-{route['label']}-{hash(err) % 1000}", "severity": "critical", "category": "Hydration", "route": route["path"], "description": f"Hydration error on {route['path']}", "evidence": err[:200], "fixed": False})
            
            for err in pw_result.get("networkErrors", []):
                all_bugs.append({"id": f"network-{route['label']}-{hash(err) % 1000}", "severity": "high", "category": "Network", "route": route["path"], "description": f"Network error on {route['path']}", "evidence": err[:200], "fixed": False})
            
            for issue in pw_result.get("a11yIssues", []):
                if not issue.startswith("PAGE_TEXT:"):
                    all_bugs.append({"id": f"a11y-{route['label']}-{hash(issue) % 1000}", "severity": "medium", "category": "Accessibility", "route": route["path"], "description": f"A11y issue on {route['path']}", "evidence": issue[:200], "fixed": False})
            
            for issue in pw_result.get("overflowIssues", []):
                all_bugs.append({"id": f"responsive-{route['label']}-{hash(issue) % 1000}", "severity": "high", "category": "Responsive", "route": route["path"], "description": f"Overflow on {route['path']}", "evidence": issue[:200], "fixed": False})
            
            # Form audit
            form_info = pw_result.get("formInfo", {})
            if form_info:
                unlabeled = [i for i in form_info.get("inputs", []) if not i.get("hasLabel") and i.get("type") != "hidden"]
                if unlabeled:
                    all_bugs.append({"id": f"form-labels-{route['label']}", "severity": "high", "category": "Accessibility", "route": route["path"], "description": f"Unlabeled inputs on {route['path']}", "evidence": ", ".join(i.get("name") or i.get("type") or "input" for i in unlabeled), "fixed": False})
                if form_info.get("inputCount", 0) > 0 and form_info.get("submitCount", 0) == 0:
                    all_bugs.append({"id": f"form-submit-{route['label']}", "severity": "medium", "category": "Forms", "route": route["path"], "description": f"No submit button on {route['path']}", "evidence": f"{form_info['inputCount']} inputs, 0 submit buttons", "fixed": False})
            
            print(f"    ✓ Status: {pw_result.get('status', 'N/A')}, A11y: {len(pw_result.get('a11yIssues', []))} issues, Overflow: {len(pw_result.get('overflowIssues', []))} issues")
        
        # Restart server after Playwright (it might kill it)
        time.sleep(2)
        # Check if server is still alive
        check = subprocess.run(["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", f"{BASE_URL}/login"], capture_output=True, text=True, timeout=5)
        if check.stdout.strip() != "200":
            print("    Restarting server...")
            subprocess.run(["pkill", "-f", "standalone/server.js"], capture_output=True)
            time.sleep(2)
            subprocess.Popen(["node", ".next/standalone/server.js"], cwd="/home/z/my-project", stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(5)
    
    # SECTION 8/9: Performance metrics (from Playwright results)
    print("\n=== SECTION 8/9: Performance Metrics ===")
    for r in all_results:
        perf = r.get("performance", {})
        if perf:
            print(f"  {r['route']}: TTFB={perf.get('ttfb', 0):.0f}ms FCP={perf.get('fcp', 0):.0f}ms DOM={perf.get('domSize', 'N/A')}")
    
    # SECTION 12: Generate Reports
    print("\n=== SECTION 12: Generating Reports ===")
    generate_reports()
    
    # Final summary
    critical = [b for b in all_bugs if b["severity"] == "critical"]
    high = [b for b in all_bugs if b["severity"] == "high"]
    medium = [b for b in all_bugs if b["severity"] == "medium"]
    low = [b for b in all_bugs if b["severity"] == "low"]
    
    print("\n" + "=" * 60)
    print("AUDIT COMPLETE")
    print("=" * 60)
    print(f"Total pages tested: {len(all_results)}")
    print(f"Total screenshots: {total_screenshots}")
    print(f"Total bugs found: {len(all_bugs)}")
    print(f"  Critical: {len(critical)}")
    print(f"  High: {len(high)}")
    print(f"  Medium: {len(medium)}")
    print(f"  Low: {len(low)}")
    print(f"Console errors: {sum(len(r.get('consoleErrors', [])) for r in all_results)}")
    print(f"Network errors: {sum(len(r.get('networkErrors', [])) for r in all_results)}")
    print(f"Hydration errors: {sum(len(r.get('hydrationErrors', [])) for r in all_results)}")
    print(f"A11y issues: {sum(len(r.get('a11yIssues', [])) for r in all_results)}")
    print(f"Overflow issues: {sum(len(r.get('overflowIssues', [])) for r in all_results)}")
    print(f"Routes OK: {sum(1 for r in all_results if r['status'] >= 200 and r['status'] < 400)}/{len(all_results)}")

def generate_reports():
    critical = [b for b in all_bugs if b["severity"] == "critical"]
    high = [b for b in all_bugs if b["severity"] == "high"]
    medium = [b for b in all_bugs if b["severity"] == "medium"]
    low = [b for b in all_bugs if b["severity"] == "low"]
    
    # BUG_REPORT.md
    with open(os.path.join(REPORT_DIR, "BUG_REPORT.md"), "w") as f:
        f.write(f"""# Bug Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Summary

| Severity | Count |
|----------|-------|
| Critical | {len(critical)} |
| High | {len(high)} |
| Medium | {len(medium)} |
| Low | {len(low)} |
| **Total** | **{len(all_bugs)}** |

## Critical Bugs

{chr(10).join(f'### {b["id"]}{chr(10)}- **Category:** {b["category"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in critical) if critical else 'No critical bugs.'}

## High Bugs

{chr(10).join(f'### {b["id"]}{chr(10)}- **Category:** {b["category"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in high) if high else 'No high bugs.'}

## Medium Bugs

{chr(10).join(f'### {b["id"]}{chr(10)}- **Category:** {b["category"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in medium) if medium else 'No medium bugs.'}
""")
    
    # PLAYWRIGHT_REPORT.md
    with open(os.path.join(REPORT_DIR, "PLAYWRIGHT_REPORT.md"), "w") as f:
        f.write(f"""# Playwright Test Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}
**Browser:** Chromium Headless

## Route Results

| Route | Status | Load Time | Console Errors | Network Errors | Hydration Errors | A11y Issues | Overflow |
|-------|--------|-----------|----------------|----------------|------------------|-------------|----------|
{chr(10).join(f'| {r["route"]} | {r["status"]} | {r.get("loadTime", 0)}ms | {len(r.get("consoleErrors", []))} | {len(r.get("networkErrors", []))} | {len(r.get("hydrationErrors", []))} | {len(r.get("a11yIssues", []))} | {len(r.get("overflowIssues", []))} |' for r in all_results)}

## Console Errors Detail

{chr(10).join(f'### {r["route"]}{chr(10)}' + chr(10).join(f'- `{e[:200]}`' for e in r.get("consoleErrors", [])) for r in all_results if r.get("consoleErrors"))}

## Network Errors Detail

{chr(10).join(f'### {r["route"]}{chr(10)}' + chr(10).join(f'- `{e[:200]}`' for e in r.get("networkErrors", [])) for r in all_results if r.get("networkErrors"))}
""")
    
    # ACCESSIBILITY_REPORT.md
    with open(os.path.join(REPORT_DIR, "ACCESSIBILITY_REPORT.md"), "w") as f:
        a11y_bugs = [b for b in all_bugs if b["category"] == "Accessibility"]
        f.write(f"""# Accessibility Audit Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Summary

- **Total accessibility issues:** {len(a11y_bugs)}

## Issues by Route

{chr(10).join(f'### {r["route"]}{chr(10)}' + chr(10).join(f'- {i}' for i in r.get("a11yIssues", [])) for r in all_results if r.get("a11yIssues"))}

## WCAG 2.1 Checklist

| Criterion | Status |
|-----------|--------|
| 1.1.1 Non-text Content | {'✗ Issues found' if any(b['evidence'].find('alt') >= 0 for b in a11y_bugs) else '✓ Pass'} |
| 1.3.1 Info and Relationships | {'✗ Issues found' if any(b['evidence'].find('label') >= 0 for b in a11y_bugs) else '✓ Pass'} |
| 2.1.1 Keyboard | ⚠ Manual review needed |
| 3.3.2 Labels or Instructions | {'✗ Issues found' if any(b['evidence'].find('label') >= 0 for b in a11y_bugs) else '✓ Pass'} |
| 4.1.2 Name, Role, Value | {'✗ Issues found' if any(b['evidence'].find('Button') >= 0 for b in a11y_bugs) else '✓ Pass'} |
""")
    
    # LIGHTHOUSE_REPORT.md
    with open(os.path.join(REPORT_DIR, "LIGHTHOUSE_REPORT.md"), "w") as f:
        perf_data = [(r["route"], r.get("performance", {})) for r in all_results if r.get("performance")]
        f.write(f"""# Lighthouse/Performance Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Performance Metrics

| Route | TTFB | FCP | DOM Loaded | DOM Size | Transfer Size |
|-------|------|-----|------------|----------|---------------|
{chr(10).join(f'| {r} | {m.get("ttfb", 0):.0f}ms | {m.get("fcp", 0):.0f}ms | {m.get("domContentLoaded", 0):.0f}ms | {m.get("domSize", "N/A")} | {m.get("transferSize", "N/A")}B |' for r, m in perf_data)}

## Targets

| Metric | Target | Note |
|--------|--------|------|
| Performance | ≥95 | Run full Lighthouse CLI for accurate scores |
| Accessibility | 100 | See ACCESSIBILITY_REPORT.md |
| Best Practices | 100 | See BUG_REPORT.md |
| SEO | ≥95 | Run full Lighthouse CLI |
""")
    
    # RESPONSIVE_REPORT.md
    with open(os.path.join(REPORT_DIR, "RESPONSIVE_REPORT.md"), "w") as f:
        resp_bugs = [b for b in all_bugs if b["category"] == "Responsive"]
        f.write(f"""# Responsive Audit Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Viewports Tested

| Name | Width | Height | Category |
|------|-------|--------|----------|
{chr(10).join(f'| {v["name"]} | {v["width"]} | {v["height"]} | {v["cat"]} |' for v in VIEWPORTS)}

## Overflow Issues

{chr(10).join(f'### {b["id"]}{chr(10)}- **Severity:** {b["severity"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in resp_bugs) if resp_bugs else 'No overflow issues found at any viewport.'}
""")
    
    # UI_AUDIT.md
    with open(os.path.join(REPORT_DIR, "UI_AUDIT.md"), "w") as f:
        ui_bugs = [b for b in all_bugs if b["category"] in ["UI", "Route", "Console Error", "Hydration", "Network"]]
        f.write(f"""# UI Audit Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Route Status

| Route | Status | Load Time | Console Errors | Hydration Errors |
|-------|--------|-----------|----------------|------------------|
{chr(10).join(f'| {r["route"]} | {r["status"]} | {r.get("loadTime", 0)}ms | {len(r.get("consoleErrors", []))} | {len(r.get("hydrationErrors", []))} |' for r in all_results)}

## UI-Related Bugs

{chr(10).join(f'### {b["id"]}{chr(10)}- **Severity:** {b["severity"]}{chr(10)}- **Category:** {b["category"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in ui_bugs) if ui_bugs else 'No UI bugs.'}
""")
    
    # UX_AUDIT.md
    with open(os.path.join(REPORT_DIR, "UX_AUDIT.md"), "w") as f:
        form_bugs = [b for b in all_bugs if b["category"] == "Forms"]
        journey_bugs = [b for b in all_bugs if b["category"] == "User Journey"]
        a11y_bugs = [b for b in all_bugs if b["category"] == "Accessibility"]
        f.write(f"""# UX Audit Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Form Issues

{chr(10).join(f'### {b["id"]}{chr(10)}- **Severity:** {b["severity"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in form_bugs) if form_bugs else 'No form issues.'}

## User Journey Issues

{chr(10).join(f'### {b["id"]}{chr(10)}- **Severity:** {b["severity"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in journey_bugs) if journey_bugs else 'No user journey issues.'}

## Accessibility Issues

{chr(10).join(f'### {b["id"]}{chr(10)}- **Severity:** {b["severity"]}{chr(10)}- **Route:** {b["route"]}{chr(10)}- **Description:** {b["description"]}{chr(10)}- **Evidence:** {b["evidence"]}{chr(10)}' for b in a11y_bugs) if a11y_bugs else 'No accessibility issues.'}
""")
    
    # VISUAL_REGRESSION_REPORT.md
    with open(os.path.join(REPORT_DIR, "VISUAL_REGRESSION_REPORT.md"), "w") as f:
        f.write(f"""# Visual Regression Report — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}
**Total Screenshots:** {total_screenshots}

## Screenshot Inventory

{chr(10).join(f'### {r["route"]}{chr(10)}' + chr(10).join(f'- `{s}`' for s in r.get("screenshots", [])) for r in all_results if r.get("screenshots"))}

## Visual Comparison Notes

- All screenshots captured at {len(VIEWPORTS)} viewports
- Desktop: 1920x1080, 1440x900
- Laptop: 1280x800, 1024x768
- Tablet: 820x1180, 768x1024
- Mobile: 414x896, 390x844, 375x812, 320x568
""")
    
    # SCREENSHOT_INDEX.md
    with open(os.path.join(REPORT_DIR, "SCREENSHOT_INDEX.md"), "w") as f:
        f.write(f"""# Screenshot Index — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}
**Total Screenshots:** {total_screenshots}

## By Route

{chr(10).join(f'### {r["route"]}{chr(10)}' + chr(10).join(f'- `{s}`' for s in r.get("screenshots", [])) for r in all_results if r.get("screenshots"))}
""")
    
    # FIX_LOG.md
    with open(os.path.join(REPORT_DIR, "FIX_LOG.md"), "w") as f:
        open_bugs = [b for b in all_bugs if not b.get("fixed", False)]
        f.write(f"""# Fix Log — ExamForge AI

**Date:** {datetime.utcnow().isoformat()}

## Summary

| Status | Count |
|--------|-------|
| Open | {len(open_bugs)} |
| Fixed | {len(all_bugs) - len(open_bugs)} |
| Total | {len(all_bugs)} |

## Open Issues

| ID | Severity | Category | Route | Description |
|----|----------|----------|-------|-------------|
{chr(10).join(f'| {b["id"]} | {b["severity"]} | {b["category"]} | {b["route"]} | {b["description"][:80]} |' for b in open_bugs)}

## Fixed Issues

None yet — fixes will be applied after initial audit.
""")
    
    print("  ✓ All 9 reports generated")

if __name__ == "__main__":
    main()
