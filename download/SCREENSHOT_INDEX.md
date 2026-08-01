# Screenshot Index — ExamForge AI

**Date:** 2026-08-01T22:36:19.916338+00:00
**Total Screenshots:** 0 (unable to capture due to memory constraints)

## Status

Screenshots could not be captured during this audit phase. The Playwright Chromium browser process requires approximately 500MB+ of memory, and when combined with the Next.js server (~300MB), the total exceeds the available 3.9GB RAM in the current environment.

## Recommendations

1. Run screenshot capture in CI/CD with ≥8GB RAM
2. Use `npx playwright test --workers=1` to limit memory usage
3. Consider using a lighter screenshot tool (e.g., puppeteer-core with minimal Chrome)
4. Capture screenshots after each deploy for visual regression
