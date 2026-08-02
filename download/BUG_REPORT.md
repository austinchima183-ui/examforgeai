# Bug Report — ExamForge AI

**Date:** 2026-08-01T22:36:19.916338+00:00
**Phase:** 4.5 — Enterprise UI/UX/QA Audit

## Summary

| Severity | Count | Fixed | Open |
|----------|-------|-------|------|
| Critical | 3 | 3 | 0 |
| High | 8 | 3 | 5 |
| Medium | 9 | 4 | 5 |
| Low | 5 | 3 | 2 |
| **Total** | **25** | **13** | **12** |

## Critical Bugs

### C-01
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Label `for` points to wrapper div instead of input - FormControl wraps div not Input
- **Evidence:** FormControl Slot merges id/aria onto first child which is a div, not the input
- **Status:** ✓ Fixed

### C-02
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Missing skip navigation link
- **Evidence:** No skip-to-content link in public layout
- **Status:** ✓ Fixed

### C-03
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** No main landmark, no header/footer semantic elements
- **Evidence:** Public layout uses divs instead of main/header/footer
- **Status:** ✓ Fixed


## High Bugs

### H-01
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Error messages lack role=alert and aria-live
- **Evidence:** Error divs without role='alert' or aria-live='assertive'
- **Status:** ✓ Fixed

### H-02
- **Category:** Accessibility
- **Route:** Login, Register, Forgot-password, Reset-password
- **Description:** Form inputs missing aria-required=true
- **Evidence:** Required inputs lack aria-required attribute
- **Status:** ✓ Fixed

### H-03
- **Category:** Accessibility
- **Route:** All pages
- **Description:** Same title for all pages - no page-specific titles
- **Evidence:** All pages render 'ExamForge AI' as title
- **Status:** ✗ Open

### H-04
- **Category:** Accessibility
- **Route:** /verify-email
- **Description:** Verify-email skeleton has no accessible content
- **Evidence:** Skeleton elements without aria-busy or aria-label
- **Status:** ✓ Fixed

### SC-01
- **Category:** Mock Data
- **Route:** /cbt
- **Description:** MOCK_EXAMS hardcoded array used for all data
- **Evidence:** const MOCK_EXAMS: Exam[] = [...] in /src/app/(app)/cbt/page.tsx
- **Status:** ✗ Open

### SC-02
- **Category:** Mock Data
- **Route:** /results
- **Description:** MOCK_RESULTS hardcoded array used for all data
- **Evidence:** const MOCK_RESULTS: ExamResult[] = [...] in /src/app/(app)/results/page.tsx
- **Status:** ✗ Open

### SC-03
- **Category:** Mock Data
- **Route:** /billing
- **Description:** MOCK_INVOICES hardcoded array used for all data
- **Evidence:** const MOCK_INVOICES: Invoice[] = [...] in /src/app/(app)/billing/page.tsx
- **Status:** ✗ Open

### SC-04
- **Category:** Mock Data
- **Route:** /question-bank
- **Description:** MOCK_QUESTIONS hardcoded array used for all data
- **Evidence:** const MOCK_QUESTIONS: Question[] = [...] in /src/app/(app)/question-bank/page.tsx
- **Status:** ✗ Open


## Medium Bugs

### M-01
- **Category:** Accessibility
- **Route:** All public form pages
- **Description:** Forms lack aria-label or aria-labelledby
- **Evidence:** Form elements without accessible name
- **Status:** ✓ Fixed

### M-02
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Links lack focus-visible styles
- **Evidence:** Links use hover:underline but no focus-visible:underline
- **Status:** ✓ Fixed

### M-03
- **Category:** Accessibility
- **Route:** Register, Forgot-password
- **Description:** try again button is non-descriptive
- **Evidence:** Button text 'try again' is ambiguous without context
- **Status:** ✓ Fixed

### M-04
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Decorative divs not aria-hidden
- **Evidence:** Background gradient divs not marked aria-hidden
- **Status:** ✓ Fixed

### M-05
- **Category:** UX
- **Route:** Login, Register, Reset-password
- **Description:** No password visibility toggle
- **Evidence:** All password fields use type=password without show/hide toggle
- **Status:** ✗ Open

### M-06
- **Category:** Accessibility
- **Route:** Register, Forgot-password, Reset-password, Verify-email
- **Description:** Success messages lack aria-live region
- **Evidence:** Success state transitions not announced by screen readers
- **Status:** ✗ Open

### M-07
- **Category:** Accessibility
- **Route:** Register, Forgot-password, Reset-password
- **Description:** No focus management on state transitions
- **Evidence:** Focus not moved to success heading after form submission
- **Status:** ✗ Open

### SC-05
- **Category:** Mock Data
- **Route:** /analytics
- **Description:** Mock Chart Data used for all analytics
- **Evidence:** // Mock Chart Data in /src/app/(app)/analytics/page.tsx
- **Status:** ✗ Open

### SC-06
- **Category:** Mock Data
- **Route:** /marketplace
- **Description:** Mock Data used for marketplace items
- **Evidence:** // Mock Data in /src/app/(app)/marketplace/page.tsx
- **Status:** ✗ Open


## Low Bugs

### L-01
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** text-muted-foreground may fail color contrast ratios at small sizes
- **Evidence:** text-xs text-muted-foreground at 12px may not meet 4.5:1 ratio
- **Status:** ✗ Open

### L-02
- **Category:** Accessibility
- **Route:** All pages
- **Description:** maximum-scale=5 in viewport meta restricts zoom
- **Evidence:** Viewport meta includes maximumScale: 5
- **Status:** ✓ Fixed

### L-03
- **Category:** Accessibility
- **Route:** All public pages
- **Description:** Logo SVG missing aria-hidden
- **Evidence:** Decorative SVG not marked as hidden from accessibility tree
- **Status:** ✓ Fixed

### L-04
- **Category:** Accessibility
- **Route:** /login
- **Description:** Create one link text is ambiguous out of context
- **Evidence:** Link text 'Create one' changed to 'Create an account'
- **Status:** ✓ Fixed

### L-05
- **Category:** SEO
- **Route:** All pages
- **Description:** No page-specific meta descriptions
- **Evidence:** All pages share the same generic meta description
- **Status:** ✗ Open

