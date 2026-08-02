#!/usr/bin/env python3
"""
ExamForge AI — Phase 6 Production Audit Report Generator
Generates all 11 PDF reports from the comprehensive audit findings.
"""

import os
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# ── Palette ──────────────────────────────────────────────────────────────────
PAGE_BG       = colors.HexColor('#f4f5f6')
SECTION_BG    = colors.HexColor('#e9ebeb')
CARD_BG       = colors.HexColor('#eceeef')
TABLE_STRIPE  = colors.HexColor('#e9ebec')
HEADER_FILL   = colors.HexColor('#33454e')
COVER_BLOCK   = colors.HexColor('#577685')
BORDER        = colors.HexColor('#a7bcc7')
ICON          = colors.HexColor('#4f7c92')
ACCENT        = colors.HexColor('#3197ca')
ACCENT_2      = colors.HexColor('#bc3a50')
TEXT_PRIMARY   = colors.HexColor('#232627')
TEXT_MUTED     = colors.HexColor('#7e8488')
SEM_SUCCESS   = colors.HexColor('#48865d')
SEM_WARNING   = colors.HexColor('#9c7c3c')
SEM_ERROR     = colors.HexColor('#af544b')
SEM_INFO      = colors.HexColor('#436a91')

OUTPUT_DIR = '/home/z/my-project/download'
DATE_STR = datetime.now().strftime('%Y-%m-%d')

# ── Font Registration ────────────────────────────────────────────────────────
FONT_DIR = '/usr/share/fonts'
pdfmetrics.registerFont(TTFont('Inter', f'{FONT_DIR}/truetype/dejavu/DejaVuSans.ttf'))
pdfmetrics.registerFont(TTFont('Inter-Bold', f'{FONT_DIR}/truetype/dejavu/DejaVuSans-Bold.ttf'))
pdfmetrics.registerFont(TTFont('Mono', f'{FONT_DIR}/truetype/dejavu/DejaVuSansMono.ttf'))
registerFontFamily('Inter', normal='Inter', bold='Inter-Bold')

# ── Styles ───────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

title_style = ParagraphStyle(
    'CustomTitle', parent=styles['Title'],
    fontName='Inter-Bold', fontSize=22, leading=28,
    textColor=HEADER_FILL, spaceAfter=6, spaceBefore=20
)
h1_style = ParagraphStyle(
    'H1', parent=styles['Heading1'],
    fontName='Inter-Bold', fontSize=16, leading=22,
    textColor=HEADER_FILL, spaceAfter=8, spaceBefore=16,
    borderWidth=0, borderPadding=0,
)
h2_style = ParagraphStyle(
    'H2', parent=styles['Heading2'],
    fontName='Inter-Bold', fontSize=13, leading=18,
    textColor=COVER_BLOCK, spaceAfter=6, spaceBefore=12
)
h3_style = ParagraphStyle(
    'H3', parent=styles['Heading3'],
    fontName='Inter-Bold', fontSize=11, leading=15,
    textColor=ICON, spaceAfter=4, spaceBefore=8
)
body_style = ParagraphStyle(
    'Body', parent=styles['Normal'],
    fontName='Inter', fontSize=9.5, leading=14,
    textColor=TEXT_PRIMARY, spaceAfter=6, alignment=TA_JUSTIFY
)
muted_style = ParagraphStyle(
    'Muted', parent=body_style,
    fontName='Inter', fontSize=8.5, leading=12,
    textColor=TEXT_MUTED, spaceAfter=4
)
code_style = ParagraphStyle(
    'Code', parent=body_style,
    fontName='Mono', fontSize=8, leading=11,
    textColor=TEXT_PRIMARY, backColor=CARD_BG,
    leftIndent=10, rightIndent=10, spaceBefore=4, spaceAfter=4,
    borderWidth=0.5, borderColor=BORDER, borderPadding=4
)
bullet_style = ParagraphStyle(
    'Bullet', parent=body_style,
    leftIndent=20, bulletIndent=10,
    spaceAfter=3
)
finding_style = ParagraphStyle(
    'Finding', parent=body_style,
    leftIndent=15, spaceAfter=4, spaceBefore=2
)
label_style = ParagraphStyle(
    'Label', parent=body_style,
    fontName='Inter-Bold', fontSize=9, leading=13,
    textColor=COVER_BLOCK, spaceAfter=2
)

# ── Helper Functions ─────────────────────────────────────────────────────────
def sev_color(severity):
    """Return color for severity level."""
    mapping = {
        'Critical': SEM_ERROR, 'critical': SEM_ERROR,
        'High': SEM_WARNING, 'high': SEM_WARNING,
        'Medium': ACCENT, 'medium': ACCENT,
        'Low': SEM_INFO, 'low': SEM_INFO,
    }
    return mapping.get(severity, TEXT_MUTED)

def make_table(headers, rows, col_widths=None):
    """Create a styled table from headers and rows."""
    data = [headers] + rows
    if col_widths is None:
        col_widths = [None] * len(headers)
    t = Table(data, colWidths=col_widths, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Inter-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8.5),
        ('FONTNAME', (0, 1), (-1, -1), 'Inter'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
        ('LEADING', (0, 0), (-1, -1), 11),
        ('ALIGN', (0, 0), (-1, 0), 'LEFT'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]
    # Alternating row colors
    for i in range(1, len(data)):
        if i % 2 == 0:
            style_cmds.append(('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE))
    t.setStyle(TableStyle(style_cmds))
    return t

def make_severity_badge(severity):
    """Return a colored Paragraph for severity."""
    c = sev_color(severity)
    return Paragraph(f'<font color="{c.hexval()}">{severity}</font>', body_style)

def p(text):
    """Shortcut for body paragraph."""
    return Paragraph(text, body_style)

def h1(text):
    return Paragraph(text, h1_style)

def h2(text):
    return Paragraph(text, h2_style)

def h3(text):
    return Paragraph(text, h3_style)

def spacer(h=6):
    return Spacer(1, h)

def hr():
    return HRFlowable(width="100%", thickness=0.5, color=BORDER, spaceAfter=6, spaceBefore=6)

def build_pdf(filename, story):
    """Build a PDF from the story elements."""
    filepath = os.path.join(OUTPUT_DIR, filename)
    doc = SimpleDocTemplate(
        filepath,
        pagesize=A4,
        leftMargin=2*cm, rightMargin=2*cm,
        topMargin=2*cm, bottomMargin=2*cm,
        title=filename.replace('.pdf', '').replace('_', ' '),
        author='ExamForge AI - Z.ai',
        subject='Production Audit Report',
    )
    doc.build(story)
    print(f'  Generated: {filepath}')
    return filepath


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 1: Code Audit Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_code_audit_report():
    story = []
    story.append(h1('Production Code Audit Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'This report presents the findings of a comprehensive production code audit conducted on the ExamForge AI '
        'Next.js codebase. The audit examined dead code, unused components, duplicate logic, unused dependencies, '
        'and other quality issues that impact maintainability, bundle size, and security posture. A total of 18 '
        'findings were identified across 12 categories, with 2 Critical, 6 High, 7 Medium, and 3 Low severity issues. '
        'The most impactful findings are: broken role-based middleware guards (route prefixes do not match actual routes), '
        '14+ unused npm packages contributing significant bundle bloat, and 5x duplicated utility functions across '
        'dashboard pages.'
    ))
    story.append(spacer(8))

    # Severity summary
    story.append(h2('Severity Distribution'))
    story.append(make_table(
        ['Severity', 'Count', 'Key Areas'],
        [
            ['Critical', '2', 'Middleware RBAC broken, 14+ unused packages'],
            ['High', '6', 'Duplicate logic, dead API module, dead stores, console.log proliferation'],
            ['Medium', '7', 'Unused components, hooks, validators, route constants'],
            ['Low', '3', 'Dead CSS, unused env var, unused type'],
        ],
        [2.5*cm, 1.5*cm, 12*cm]
    ))
    story.append(spacer(10))

    # Critical findings
    story.append(h2('Critical Findings'))

    story.append(h3('1. Role-Based Middleware Guards Are Broken'))
    story.append(p(
        'The middleware defines role-based route prefixes as /admin, /school, /teacher, /student, but the actual '
        'application routes use /dashboard/super-admin, /dashboard/school-admin, /dashboard/teacher, /dashboard/student. '
        'This means the RoleBasedGuard never fires for any authenticated route, effectively making role-based access '
        'control non-functional. Any authenticated user can access any dashboard route regardless of their role.'
    ))
    story.append(p('<b>File:</b> src/middleware.ts, lines 45-50'))
    story.append(p('<b>Fix:</b> Update ROLE_ROUTE_PREFIXES to match actual routes, or restructure routes to match the guard prefixes.'))
    story.append(spacer(6))

    story.append(h3('2. 14+ Unused npm Packages'))
    story.append(p(
        'The following packages are listed in package.json dependencies but are never imported anywhere in the src/ '
        'directory. Together they account for significant bundle bloat and an increased security surface area.'
    ))
    story.append(make_table(
        ['Package', 'Est. Size', 'Impact'],
        [
            ['next-auth', 'Large', 'Auth library not used; Supabase Auth is used instead'],
            ['@mdxeditor/editor', '~500KB', 'Rich text editor never imported'],
            ['react-syntax-highlighter', '~150KB', 'Code highlighting never used'],
            ['@prisma/client + prisma', 'Large', 'Only in unused db.ts; Supabase is used'],
            ['@dnd-kit/core + sortable + utilities', 'Medium', 'Drag-and-drop never used'],
            ['dexie', 'Medium', 'IndexedDB wrapper never used'],
            ['sharp', 'Large', 'Image processing never used'],
            ['next-intl', 'Medium', 'i18n never configured'],
            ['next-pwa', 'Small', 'PWA config never set up'],
            ['react-markdown', 'Medium', 'Markdown rendering never used'],
            ['uuid', 'Small', 'UUID generation never used'],
            ['@reactuses/core', 'Medium', 'React hooks library never used'],
            ['z-ai-web-dev-sdk', 'Small', 'AI SDK never used'],
        ],
        [5*cm, 2*cm, 9*cm]
    ))
    story.append(spacer(10))

    # High findings
    story.append(h2('High Severity Findings'))

    story.append(h3('3. 5x Duplicate formatRelativeTime()'))
    story.append(p(
        'The formatRelativeTime() utility function is defined identically in 5 separate files: '
        'dashboard/student/page.tsx, dashboard/teacher/page.tsx, dashboard/school-admin/page.tsx, '
        'dashboard/super-admin/page.tsx, and notifications/page.tsx. A shared version already exists at '
        'src/lib/utils/format.ts but is not imported. This creates maintenance burden and inconsistency risk.'
    ))
    story.append(spacer(4))

    story.append(h3('4. 3x Duplicate formatCurrency()'))
    story.append(p(
        'The formatCurrency() function is duplicated in dashboard/school-admin/page.tsx, '
        'dashboard/super-admin/page.tsx, and billing/page.tsx. A shared version exists at '
        'src/lib/utils/format.ts. Each copy has slightly different signatures, creating inconsistency.'
    ))
    story.append(spacer(4))

    story.append(h3('5. Entire @/lib/api/ Module Is Dead Code'))
    story.append(p(
        'Four files comprising the API client module (client.ts, errors.ts, result.ts, index.ts) are never '
        'imported by any page, service, or component. All services use direct Supabase client calls instead. '
        'This represents approximately 300+ lines of dead code.'
    ))
    story.append(spacer(4))

    story.append(h3('6. Prisma Client Never Used'))
    story.append(p(
        'src/lib/db.ts initializes a Prisma client, but it is never imported anywhere. The project uses '
        'Supabase exclusively for data access. Both @prisma/client and prisma are unnecessary dependencies.'
    ))
    story.append(spacer(4))

    story.append(h3('7. 3 Unused Zustand Stores'))
    story.append(p(
        'useUIStore, useExamSessionStore, and useThemePreferences are defined in src/lib/stores/ but never '
        'imported by any component or page. The toastService wrapper around sonner is also never used, as '
        'all pages use sonner directly. This creates three competing toast/notification systems.'
    ))
    story.append(spacer(4))

    story.append(h3('8. 34 Production console.error/warn Statements'))
    story.append(p(
        'There are approximately 34 console.error and console.warn statements across the codebase, including '
        'in all service files, API routes, and the realtime provider. In production, these can leak sensitive '
        'data in error messages and provide no structured logging or alerting capability.'
    ))
    story.append(spacer(4))

    story.append(h3('9. 20+ Route Constants Point to Non-Existent Pages'))
    story.append(p(
        'The routes constants file defines 20+ route constants for pages that do not exist in the app, including '
        'EXAM_TEMPLATES, STUDENT_PRACTICE, STUDENT_FLASHCARDS, STUDENT_AI_TUTOR, ADMIN_SCHOOLS, ADMIN_ANALYTICS, '
        'and many more. These orphaned constants create navigation dead-ends and confusion.'
    ))
    story.append(spacer(10))

    # Medium findings
    story.append(h2('Medium Severity Findings'))

    story.append(h3('10. 8 Unused Components'))
    story.append(p(
        'QuickActions, RecentActivity, SelectField, TextField, TextareaField, ConfirmDialog, AppShell, and '
        'Breadcrumbs are defined in src/components/ but never imported by any page or other component.'
    ))
    story.append(spacer(4))

    story.append(h3('11. 3 Unused Custom Hooks'))
    story.append(p(
        'useDebounce, useMediaQuery (with useBreakpoint, useBreakpointBetween, useCurrentBreakpoint), '
        'and useOffline are defined in src/lib/hooks/ but never imported.'
    ))
    story.append(spacer(4))

    story.append(h3('12. validate.ts and logger.ts Never Used'))
    story.append(p(
        'The entire validate.ts module (emailSchema, urlSchema, phoneSchema, etc.) and the logger.ts module '
        'are never imported. The logger is only used by the dead apiClient module.'
    ))
    story.append(spacer(4))

    story.append(h3('13. Onboarding Route Guard References Non-Existent Page'))
    story.append(p(
        'The middleware guards the /onboarding route, but no /onboarding page exists in the app. '
        'The OnboardingGuard will never redirect users because the page does not exist.'
    ))
    story.append(spacer(4))

    story.append(h3('14. Feature Server Actions Never Imported'))
    story.append(p(
        'login.action.ts, logout.action.ts, signup.action.ts, and schools/actions.ts are defined but never '
        'imported by any client component. These server actions are dead code.'
    ))
    story.append(spacer(4))

    story.append(h3('15. Duplicate Supabase Auth + Profile Fetch Pattern'))
    story.append(p(
        'Multiple pages (results, question-bank, cbt, students, teachers, parents) repeat the exact same '
        'pattern of: getUser() + redirect check + profile query + type assertion. This should be extracted '
        'into a shared utility function.'
    ))
    story.append(spacer(10))

    # Low findings
    story.append(h2('Low Severity Findings'))
    story.append(p(
        'The .scrollbar-thin CSS class in globals.css is never applied. The DATABASE_URL environment variable '
        'is defined but never referenced in src/. The ExamCategoryType in supabase/types.ts is defined but '
        'never imported. These are minor cleanup items.'
    ))
    story.append(spacer(10))

    # Recommended Actions
    story.append(h2('Recommended Actions'))
    story.append(make_table(
        ['Priority', 'Action', 'Impact'],
        [
            ['P0', 'Fix middleware RBAC route prefixes', 'Security: Role-based access control is currently non-functional'],
            ['P0', 'Remove 14+ unused packages', 'Bundle size reduction, security surface reduction'],
            ['P1', 'Consolidate duplicate formatRelativeTime/formatCurrency', 'Maintenance, consistency'],
            ['P1', 'Delete dead modules (api/, db.ts, toast-service, validate.ts, logger.ts)', 'Code clarity, dead code removal'],
            ['P1', 'Delete unused components, hooks, and stores', 'Code clarity, reduced bundle'],
            ['P1', 'Replace console.error/warn with structured logging', 'Observability, security'],
            ['P2', 'Clean up route constants for non-existent pages', 'Navigation accuracy'],
            ['P2', 'Create or remove onboarding route', 'Feature completeness'],
            ['P2', 'Extract shared auth+profile utility', 'Code reuse, consistency'],
        ],
        [1.5*cm, 8*cm, 7*cm]
    ))

    return build_pdf('Code_Audit_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 2: Security Audit Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_security_report():
    story = []
    story.append(h1('Security Audit Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The security audit identified 12 findings across 12 categories, including 2 Critical, 4 High, '
        '4 Medium, and 2 Low severity issues. The most critical findings are: no Content Security Policy '
        'configured (leaving the application vulnerable to XSS, clickjacking, and data exfiltration), and '
        'server actions lacking authorization checks (allowing any authenticated user to modify any '
        'notification, school, or profile). The Supabase Auth implementation is generally sound, using '
        'getUser() correctly in middleware and the SSR client pattern properly.'
    ))
    story.append(spacer(8))

    story.append(make_table(
        ['#', 'Finding', 'Severity', 'Category'],
        [
            ['1', 'No Content Security Policy configured', 'Critical', 'CSP'],
            ['2', 'Server actions lack authorization checks', 'Critical', 'Auth'],
            ['3', 'Auth callback open redirect via next parameter', 'High', 'Redirect'],
            ['4', 'Password change does not verify current password', 'High', 'Auth'],
            ['5', 'No rate limiting on Next.js API routes', 'High', 'Rate Limit'],
            ['6', 'API routes excluded from middleware auth guard', 'High', 'Middleware'],
            ['7', 'No security headers on Next.js API responses', 'Medium', 'Headers'],
            ['8', 'getSession() used after getUser() in API routes', 'Medium', 'JWT'],
            ['9', 'No CSRF protection on billing webhook proxy', 'Medium', 'CSRF'],
            ['10', 'updateSchoolAction lacks auth, validation, role check', 'Medium', 'Server Actions'],
            ['11', '.env contains anon key (should be .env.local)', 'Low', 'Config'],
            ['12', 'Environment variables properly namespaced', 'Pass', 'Config'],
        ],
        [1*cm, 8*cm, 2*cm, 3*cm]
    ))
    story.append(spacer(10))

    # Critical findings detail
    story.append(h2('Critical Findings'))

    story.append(h3('F-8: No Content Security Policy Configured'))
    story.append(p(
        'No Content Security Policy is configured anywhere in the Next.js application. This leaves the '
        'application vulnerable to inline script injection, unauthorized resource loading, clickjacking via '
        'iframe embedding, and data exfiltration via injected scripts. A CSP header should be added in '
        'next.config.ts or via middleware, specifying allowed sources for scripts, styles, images, fonts, '
        'and connections (including the Supabase domain and WebSocket endpoint).'
    ))
    story.append(p('<b>Recommended Fix:</b> Add CSP headers in middleware.ts or next.config.ts:'))
    story.append(Paragraph(
        "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' blob: data: https://pzfnptrrnxkgodclyhft.supabase.co; "
        "font-src 'self' data:; "
        "connect-src 'self' https://pzfnptrrnxkgodclyhft.supabase.co wss://pzfnptrrnxkgodclyhft.supabase.co; "
        "frame-ancestors 'none'; base-uri 'self'; form-action 'self';",
        code_style
    ))
    story.append(spacer(6))

    story.append(h3('F-2: Server Actions Lack Authorization Checks'))
    story.append(p(
        'Multiple server actions perform data mutations without verifying the user is authorized: '
        'markNotificationReadAction allows any user to mark any notification as read; '
        'deleteNotificationAction allows any user to delete any notification; '
        'updateSchoolAction allows any user to update any school; '
        'deactivateSchoolAction allows any user to deactivate any school; '
        'updateUserProfile allows any user to update any profile. '
        'These actions should verify the user identity and role before performing mutations. '
        'RLS policies on the Supabase side should also enforce these constraints, but the application '
        'should not rely solely on RLS.'
    ))
    story.append(spacer(6))

    # High findings detail
    story.append(h2('High Severity Findings'))

    story.append(h3('F-5: Auth Callback Open Redirect'))
    story.append(p(
        'The auth callback route reads the "next" query parameter and uses it directly in a redirect '
        'without validation. An attacker could craft a URL like /api/auth/callback?code=xxx&next=//evil.com '
        'which could redirect to unexpected internal paths or bypass onboarding flows. The fix is to '
        'validate that the next parameter starts with / and does not start with //.'
    ))
    story.append(spacer(4))

    story.append(h3('F-3: Password Change Without Current Password Verification'))
    story.append(p(
        'The settings page password change function checks that the current password field is not empty, '
        'but never actually verifies the current password against Supabase. The supabase.auth.updateUser() '
        'call will update the password regardless because the user already has an active session. The fix '
        'is to use reauthentication via signInWithPassword() before allowing the update.'
    ))
    story.append(spacer(4))

    story.append(h3('F-9: No Rate Limiting on Next.js API Routes'))
    story.append(p(
        'The Next.js API routes that proxy to Edge Functions have no rate limiting. An attacker can '
        'brute-force AI endpoints, flood billing checkout/refund endpoints, spam the search endpoint, '
        'or brute-force login/signup. While Edge Functions have their own rate limiting, the Next.js '
        'proxy layer is unprotected. For production, use Redis-backed rate limiting (e.g., Upstash) '
        'or an in-memory rate limiter with configurable limits per endpoint.'
    ))
    story.append(spacer(4))

    story.append(h3('F-4: API Routes Excluded from Middleware Auth Guard'))
    story.append(p(
        'The middleware explicitly skips auth checks for API routes. This means every API route must '
        'independently implement auth checks. While most routes do check auth, the billing webhook route '
        'does not verify the Flutterwave signature. The Next.js proxy should verify the webhook signature '
        'or add rate limiting before forwarding to the Edge Function.'
    ))
    story.append(spacer(10))

    # Positive findings
    story.append(h2('Positive Findings'))
    story.append(p(
        'The codebase demonstrates generally sound security practices: getUser() is correctly used in '
        'middleware for JWT validation (not getSession()); the SSR client is properly configured with cookie '
        'handlers; the browser client uses a singleton pattern; signup forces role to "student" preventing '
        'role escalation; the service role key is never exposed to the client; and Edge Functions have '
        'comprehensive security headers including HSTS for production.'
    ))
    story.append(spacer(10))

    story.append(h2('Priority Remediation Order'))
    story.append(make_table(
        ['Priority', 'Finding', 'Action'],
        [
            ['P0', 'F-8: No CSP', 'Add Content Security Policy headers'],
            ['P0', 'F-2: Server action auth', 'Add authorization checks to all server actions'],
            ['P1', 'F-5: Open redirect', 'Validate next parameter in auth callback'],
            ['P1', 'F-3: Password verify', 'Verify current password before allowing change'],
            ['P1', 'F-9: Rate limiting', 'Add rate limiting to Next.js API routes'],
            ['P1', 'F-4: API auth guard', 'Verify webhook signatures or add rate limiting'],
            ['P2', 'F-7: Security headers', 'Add X-Content-Type-Options, X-Frame-Options, etc.'],
            ['P2', 'F-8: getSession pattern', 'Add session validity check after getUser()'],
            ['P2', 'F-9: CSRF webhook', 'Add origin verification to webhook proxy'],
            ['P3', 'F-10: .env.local', 'Move anon key from .env to .env.local'],
        ],
        [1.5*cm, 4*cm, 10*cm]
    ))

    return build_pdf('Security_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 3: Performance Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_performance_report():
    story = []
    story.append(h1('Performance Optimization Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The performance audit identified 27 findings across 12 categories, including 3 Critical, 8 High, '
        '10 Medium, and 6 Low severity issues. The most impactful findings are: the entire app layout is '
        'a client component (preventing RSC benefits for all authenticated pages), the analytics and '
        'notifications pages use client-side data fetching instead of server-side, and recharts (~200KB) '
        'is statically imported instead of dynamically imported. Additionally, TanStack Query is configured '
        'but never used by any client component, meaning all client-side data fetching misses caching, '
        'deduplication, and background refetching benefits.'
    ))
    story.append(spacer(8))

    story.append(make_table(
        ['Category', 'Critical', 'High', 'Medium', 'Low'],
        [
            ['React Rendering', '0', '0', '3', '2'],
            ['RSC Boundaries', '1', '0', '0', '0'],
            ['Client Components', '2', '1', '0', '1'],
            ['Suspense Boundaries', '0', '2', '0', '0'],
            ['Dynamic Imports', '0', '2', '2', '0'],
            ['Bundle Size', '0', '0', '3', '1'],
            ['Lazy Loading', '0', '0', '1', '1'],
            ['Image Optimization', '0', '0', '1', '2'],
            ['Query Caching', '0', '1', '0', '1'],
            ['Memoization', '0', '0', '2', '1'],
        ],
        [4*cm, 2*cm, 2*cm, 2*cm, 2*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Critical Findings'))

    story.append(h3('PF-2.1: Entire App Layout Is a Client Component'))
    story.append(p(
        'The "use client" directive on src/app/(app)/layout.tsx means the entire authenticated layout tree '
        'is a client component. This forces all children to be client components by default, losing RSC '
        'benefits. The RealtimeProvider could be a wrapper at a lower level instead. This is the single '
        'most impactful performance fix because it would unlock server-side rendering for all authenticated '
        'pages, reducing Time to First Byte and improving SEO.'
    ))
    story.append(p('<b>Fix:</b> Split into a Server Component layout that wraps a Client Component shell (AppShell).'))
    story.append(spacer(6))

    story.append(h3('PF-3.1: Analytics Page Uses Client-Side Data Fetching'))
    story.append(p(
        'The entire analytics page is a "use client" component that fetches data via useEffect + fetch(). '
        'This should be a Server Component that fetches data on the server, with only the interactive parts '
        '(date range selector, tabs) as client components. Users currently see a loading spinner before '
        'any content appears, missing SSR benefits entirely.'
    ))
    story.append(spacer(6))

    story.append(h3('PF-3.2: Notifications Page Uses Client-Side Data Fetching'))
    story.append(p(
        'Same pattern as the analytics page. The realtime subscription is a valid reason for client-side '
        'code, but the initial data fetch should be server-side. The page should split into a Server '
        'Component for initial data and a Client Component for realtime updates.'
    ))
    story.append(spacer(10))

    story.append(h2('High Severity Findings'))

    story.append(h3('PF-5.1: Recharts Not Dynamically Imported'))
    story.append(p(
        'Recharts (~200KB gzipped) is imported statically in both chart components. These chart components '
        'are only used on the /analytics page, meaning every user pays the cost of downloading recharts '
        'even if they never visit analytics. Use next/dynamic with ssr: false for chart components.'
    ))
    story.append(spacer(4))

    story.append(h3('PF-5.2: Framer Motion in Frequently-Used Component'))
    story.append(p(
        'framer-motion (~30KB gzipped) is imported in StatCard, which is used on nearly every page. '
        'This means framer-motion is included in the main bundle. The animations are simple enough to '
        'replace with CSS transitions (hover: -translate-y-0.5 transition-all duration-300).'
    ))
    story.append(spacer(4))

    story.append(h3('PF-4.1: Missing Per-Route loading.tsx Files'))
    story.append(p(
        'Only the root (app)/loading.tsx exists. Individual routes like /analytics, /cbt, /results, '
        '/notifications, /settings, etc. have no loading.tsx. This means route transitions use the generic '
        'app shell loading skeleton instead of a route-specific skeleton, causing layout shift.'
    ))
    story.append(spacer(4))

    story.append(h3('PF-4.2: No Suspense Boundaries for Streaming'))
    story.append(p(
        'No Suspense boundaries are used anywhere in the app. For pages with multiple async data fetches, '
        'wrapping sections in Suspense would allow progressive streaming: the header and stats can appear '
        'while activities are still loading.'
    ))
    story.append(spacer(4))

    story.append(h3('PF-11.1: TanStack Query Configured But Never Used'))
    story.append(p(
        'The QueryProvider is set up with sensible defaults (60s staleTime, 5min gcTime, structural sharing), '
        'but no component uses useQuery, useMutation, or useQueryClient. All client-side data fetching uses '
        'raw useEffect + fetch/supabase, missing caching, deduplication, and background refetching.'
    ))
    story.append(spacer(4))

    story.append(h3('PF-3.3: 701-Line Settings Client Component'))
    story.append(p(
        'The settings page is a 701-line client component. While it needs interactivity (forms), the static '
        'parts (tab labels, theme selector UI) could be server-rendered. The page should be split into '
        'a Server Component for initial data and 4 separate client components for each tab.'
    ))
    story.append(spacer(10))

    story.append(h2('Recommended Action Plan'))
    story.append(make_table(
        ['Priority', 'Action', 'Estimated Impact'],
        [
            ['P0', 'Split (app)/layout.tsx into Server + Client shell', 'Unlocks RSC for all authenticated pages'],
            ['P0', 'Refactor Analytics to Server Component', 'SSR, faster FCP, no loading spinner'],
            ['P0', 'Refactor Notifications to Server + Client', 'SSR for initial data, client for realtime'],
            ['P1', 'Dynamic import recharts', '~200KB saved from main bundle'],
            ['P1', 'Remove unused packages', '~700KB+ saved from bundle'],
            ['P1', 'Add per-route loading.tsx', 'Reduced layout shift, better perceived performance'],
            ['P1', 'Replace framer-motion in StatCard', '~30KB saved from main bundle'],
            ['P1', 'Use TanStack Query for client-side fetching', 'Caching, deduplication, refetching'],
            ['P2', 'Add Suspense boundaries', 'Progressive streaming, better UX'],
            ['P2', 'Add React.memo to nav items', 'Reduced re-renders on sidebar toggle'],
        ],
        [1.5*cm, 8*cm, 7*cm]
    ))

    return build_pdf('Performance_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 4: Accessibility Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_accessibility_report():
    story = []
    story.append(h1('Accessibility Audit Report'))
    story.append(Paragraph(f'ExamForge AI | WCAG 2.1 AA | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The accessibility audit identified 36 findings across 6 categories, including 4 Critical, 12 High, '
        '14 Medium, and 6 Low severity issues. The codebase has strong foundational accessibility in several '
        'areas: public pages have proper ARIA labels, form accessibility is well-implemented on auth pages, '
        'and skip navigation exists on the public layout. However, the authenticated app shell has significant '
        'gaps: missing landmarks, no prefers-reduced-motion support, color-only status indicators, missing '
        'ARIA labels on interactive elements, and inaccessible SVG icons. The most critical finding is that '
        'sortable table headers are not keyboard-accessible.'
    ))
    story.append(spacer(8))

    story.append(make_table(
        ['Category', 'Critical', 'High', 'Medium', 'Low'],
        [
            ['Keyboard Navigation', '1', '4', '1', '0'],
            ['Screen Readers', '0', '3', '2', '3'],
            ['Semantic HTML', '0', '2', '2', '1'],
            ['Color Contrast', '0', '1', '2', '1'],
            ['Reduced Motion', '0', '2', '3', '0'],
            ['Form Accessibility', '0', '1', '3', '1'],
        ],
        [4*cm, 2*cm, 2*cm, 2*cm, 2*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Critical Findings'))

    story.append(h3('K-1: Sortable Table Headers Not Keyboard-Accessible'))
    story.append(p(
        'The sortable column headers in data-table.tsx use a div with onClick and cursor-pointer, but no '
        'role="button", tabIndex, or keyboard event handler. Keyboard users cannot trigger sorting. This '
        'violates WCAG 2.1.1 Keyboard (Level A). The fix is to replace the div with a button element, or '
        'add role="button", tabIndex={0}, and onKeyDown handler for Enter/Space keys.'
    ))
    story.append(spacer(6))

    story.append(h3('K-2: No Skip-Link in Authenticated App Layout'))
    story.append(p(
        'The public layout has a skip-to-content link, but the authenticated app layout does not. Keyboard '
        'users must tab through the entire sidebar before reaching main content. This violates WCAG 2.4.1 '
        'Bypass Blocks (Level A). Add a skip-to-content link before the sidebar and id="main-content" to '
        'the main element.'
    ))
    story.append(spacer(6))

    story.append(h3('C-1: Color-Only Status Indicator for Unread Notifications'))
    story.append(p(
        'The unread notification indicator is a small blue dot with no text or icon alternative. This relies '
        'solely on color to convey "unread" status, violating WCAG 1.4.1 Use of Color (Level A). Add '
        'aria-label="Unread" or include a visually hidden text label alongside the dot.'
    ))
    story.append(spacer(6))

    story.append(h3('R-1/R-2: Framer Motion Animations Not Respecting prefers-reduced-motion'))
    story.append(p(
        'The motion.div animations in StatCard and QuickActions do not check prefers-reduced-motion. '
        'Users with motion sensitivity will see all animations. Use useReducedMotion() from Framer Motion '
        'and conditionally disable animations, or wrap in a CSS media query check.'
    ))
    story.append(spacer(10))

    story.append(h2('High Severity Findings'))

    story.append(h3('Search Inputs Without Labels'))
    story.append(p(
        'The search inputs on the Search page, Marketplace page, and in the DataTable component all lack '
        'associated labels or aria-label attributes. Screen readers will announce them as unlabeled text '
        'fields. This violates WCAG 1.3.1 and 3.3.2. Add aria-label="Search" to each input.'
    ))
    story.append(spacer(4))

    story.append(h3('Icon-Only Buttons Missing Accessible Names'))
    story.append(p(
        'The download invoice button in the billing page contains only a Download icon with no aria-label. '
        'Screen readers will announce it as "button" with no context. All "View" buttons in data tables '
        'have the same generic text without identifying which row they refer to. This violates WCAG 4.1.2 '
        'and 2.4.4.'
    ))
    story.append(spacer(4))

    story.append(h3('Notification Status Changes Not Announced'))
    story.append(p(
        'When a user marks a notification as read or deletes it, the optimistic update changes the DOM but '
        'does not use aria-live to announce the change. Screen reader users get no feedback. This violates '
        'WCAG 4.1.3 Status Messages (Level AA). Add an aria-live="polite" region.'
    ))
    story.append(spacer(4))

    story.append(h3('Missing Landmark Regions'))
    story.append(p(
        'The authenticated app layout has aside for the sidebar and main for content, but main has no id '
        'for skip-link targeting, and there is no header or nav landmark wrapping the header and sidebar '
        'navigation. This violates WCAG 1.3.1.'
    ))
    story.append(spacer(4))

    story.append(h3('Date Inputs Not Properly Labeled'))
    story.append(p(
        'The date input elements on the reports page have no associated label or aria-label. The placeholder '
        'attribute is not a substitute for a label. This violates WCAG 1.3.1 and 3.3.2.'
    ))
    story.append(spacer(4))

    story.append(h3('Password Form Error Not Announced'))
    story.append(p(
        'The password error message in the settings security tab does not have role="alert" or '
        'aria-live="assertive". Unlike the auth forms which properly use role="alert", the settings '
        'form does not. This violates WCAG 3.3.1 and 4.1.3.'
    ))
    story.append(spacer(10))

    story.append(h2('Positive Findings'))
    story.append(p(
        'The public layout has a properly implemented skip-to-content link with focus-visible styles. '
        'Auth forms use aria-label, aria-required, role="alert", and autoComplete attributes correctly. '
        'The root layout sets lang="en". The mobile nav sheet uses SheetTitle and SheetDescription for '
        'screen reader context. The sidebar collapse button has aria-label. Pagination buttons all have '
        'aria-label. Custom form components (TextField, SelectField, TextareaField) properly implement '
        'aria-invalid, aria-describedby, and htmlFor/id associations.'
    ))
    story.append(spacer(10))

    story.append(h2('Top 10 Priority Fixes'))
    story.append(make_table(
        ['Priority', 'ID', 'Fix'],
        [
            ['1', 'K-1', 'Make data table sort headers keyboard-accessible'],
            ['2', 'K-2', 'Add skip-link to authenticated layout'],
            ['3', 'R-1/R-2', 'Add prefers-reduced-motion support to Framer Motion'],
            ['4', 'C-1', 'Add non-color indicator for unread notifications'],
            ['5', 'SR-9', 'Add contextual aria-label to all View buttons in data tables'],
            ['6', 'SR-8', 'Add aria-label to icon-only download button in billing'],
            ['7', 'K-5/K-6/K-7', 'Add labels to all search inputs'],
            ['8', 'S-4', 'Add labels to date inputs in reports'],
            ['9', 'F-1', 'Add role="alert" to settings password error'],
            ['10', 'SR-4', 'Add aria-live region for notification action feedback'],
        ],
        [1.5*cm, 2*cm, 13*cm]
    ))

    return build_pdf('Accessibility_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 5: Data Integrity Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_data_report():
    story = []
    story.append(h1('Data Integrity Audit Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The data integrity audit identified 26 findings across 8 categories, including 8 Critical, '
        '8 High, 6 Medium, and 4 Low severity issues. The most critical findings are data leakage bugs: '
        'school admins and teachers can see data from other schools and teachers because queries are not '
        'properly scoped. The teacher dashboard counts unique exam IDs instead of students, analytics '
        'date range filters are computed but never applied, and there are severe N+1 query patterns in '
        'the reports service that will cause timeouts at scale. Additionally, multiple list queries are '
        'unbounded (no pagination), which will cause memory issues and slow load times with growing data.'
    ))
    story.append(spacer(8))

    story.append(make_table(
        ['Category', 'Critical', 'High', 'Medium', 'Low'],
        [
            ['N+1 Queries', '4', '0', '0', '0'],
            ['Pagination', '4', '2', '0', '0'],
            ['Ordering', '1', '1', '0', '0'],
            ['Error Handling', '0', '4', '1', '0'],
            ['Loading States', '0', '0', '3', '0'],
            ['Optimistic Updates', '0', '0', '0', '2'],
            ['Null Handling', '1', '1', '3', '1'],
            ['Data Consistency', '3', '1', '0', '0'],
        ],
        [4*cm, 2*cm, 2*cm, 2*cm, 2*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Critical Findings'))

    story.append(h3('DC2: School Admin Sees ALL Pending Submissions Across Platform'))
    story.append(p(
        'The getSchoolAdminStats function counts pendingSubmissions from exam_sessions with status: "submitted" '
        'but does NOT filter by school_id. This means a school admin sees ALL pending submissions across the '
        'entire platform, not just their school. This is a data leakage bug that exposes cross-school data. '
        'Fix: Add .eq("school_id", schoolId) or join through exams to filter by school.'
    ))
    story.append(spacer(4))

    story.append(h3('DC3: Teacher Sees ALL Pending Grading Across Platform'))
    story.append(p(
        'The getTeacherStats function counts pendingGrading from exam_sessions with status: "submitted" '
        'but does NOT filter by the teacher\'s exams. A teacher sees ALL pending submissions, not just '
        'for their own exams. Fix: Add filter by teacher\'s exam IDs: .in("exam_id", teacherExamIds).'
    ))
    story.append(spacer(4))

    story.append(h3('DC4: Reports School Exam Sessions Not Filtered by School'))
    story.append(p(
        'In the school reports loop, sessionsResult queries exam_sessions but does not filter by school '
        'or by the specific school\'s exams. Every school gets the same session data. Fix: Filter sessions '
        'by the school\'s exam IDs or add .eq("school_id", school.id).'
    ))
    story.append(spacer(4))

    story.append(h3('O2/NH1: Teacher Dashboard Counts Exams Instead of Students'))
    story.append(p(
        'The uniqueStudents.add(session.exam_id) adds exam IDs instead of student IDs. The uniqueStudents '
        'set is used to count students, but it is actually counting unique exam IDs. This is a data '
        'correctness bug. Fix: Change to uniqueStudents.add(session.student_id) and add student_id to '
        'the query select.'
    ))
    story.append(spacer(4))

    story.append(h3('N1-1 through N1-4: Severe N+1 Query Patterns'))
    story.append(p(
        'The analytics service loops over each school (up to 10) making 2 queries per school (20 sequential '
        'queries). The reports service loops over each school (up to 50) making 5 parallel queries per school '
        '(250 queries total). The teacher and student reports have similar N+1 patterns. These will cause '
        'timeouts at scale. Fix: Batch-fetch all data with school_id IN (...) or created_by IN (...), then '
        'aggregate in-memory with a Map.'
    ))
    story.append(spacer(4))

    story.append(h3('O1: Analytics Date Range Filter Never Applied'))
    story.append(p(
        'The dateFilter variable is computed from the dateRange parameter but never used in the query. '
        'All analytics data is fetched unfiltered regardless of the selected date range. Fix: Add '
        '.gte("created_at", dateFilter) to the sessions query when dateFilter is not null.'
    ))
    story.append(spacer(4))

    story.append(h3('P1-P4: Unbounded Queries on Core Entities'))
    story.append(p(
        'The schools, students, teachers, and parents services all use select("*") with no .limit() or '
        '.range(). These queries fetch ALL records with ALL columns. For a school with thousands of '
        'students or a platform with hundreds of schools, this will be very slow and memory-intensive. '
        'Fix: Add .limit() and .range() with cursor/offset pagination, and select only needed columns.'
    ))
    story.append(spacer(10))

    story.append(h2('High Severity Findings'))

    story.append(h3('E1: Search Service Silent Errors'))
    story.append(p(
        'All 8 Supabase queries in the search service destructure only {data} and ignore the error return. '
        'If any query fails, it silently returns empty results. No error is logged or propagated. Fix: '
        'Destructure {data, error} for each query and handle errors appropriately.'
    ))
    story.append(spacer(4))

    story.append(h3('E5: No Rollback on Failed Optimistic Updates'))
    story.append(p(
        'The notifications page performs optimistic updates before the server action completes, but never '
        'rolls back if the server action fails. The server actions return {error} but the client code '
        'ignores it. Fix: Check the return value and revert the optimistic update on failure.'
    ))
    story.append(spacer(4))

    story.append(h3('DC1: Inconsistent Revenue Calculation'))
    story.append(p(
        'Dashboard and reports compute revenue differently (different filtering by status, different date '
        'ranges). Fix: Use a shared utility for revenue calculation, or use Supabase RPC for consistency.'
    ))
    story.append(spacer(10))

    story.append(h2('Priority Remediation Order'))
    story.append(make_table(
        ['Priority', 'Action', 'Impact'],
        [
            ['P0', 'Fix data leakage: scope queries by school/teacher', 'Data security: school admins see cross-school data'],
            ['P0', 'Fix teacher dashboard: count students not exams', 'Data correctness: dashboard shows wrong numbers'],
            ['P0', 'Fix N+1 queries in reports service', 'Performance: will timeout at scale'],
            ['P0', 'Fix analytics date range filter', 'Data correctness: all analytics unfiltered'],
            ['P0', 'Add pagination to all list queries', 'Performance: unbounded queries will fail at scale'],
            ['P1', 'Add error handling to search service', 'Reliability: silent failures mask issues'],
            ['P1', 'Add rollback to optimistic updates', 'Data consistency: UI shows incorrect state on failure'],
            ['P2', 'Consolidate revenue calculation', 'Consistency: different numbers in different views'],
        ],
        [1.5*cm, 8*cm, 7*cm]
    ))

    return build_pdf('Data_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 6: Realtime Report
# ══════════════════════════════════════════════════════════════════════════════
def generate_realtime_report():
    story = []
    story.append(h1('Realtime Audit Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The realtime audit identified 10 findings, including 2 Critical, 3 High, 3 Medium, and 2 Low '
        'severity issues. The most critical findings are: duplicate realtime subscriptions on the notifications '
        'table (both a global provider and a per-page subscription), causing double processing of every event, '
        'and no onAuthStateChange listener, meaning the application session desyncs when tokens are refreshed. '
        'The offline audit identified 7 findings, including 2 Critical, 2 High, 2 Medium, and 1 Low severity '
        'issues. The useOffline hook is never used, Dexie is installed but never configured, and there is '
        'no offline mutation queue or network recovery handler.'
    ))
    story.append(spacer(8))

    story.append(make_table(
        ['Category', 'Critical', 'High', 'Medium', 'Low'],
        [
            ['Realtime', '2', '3', '3', '2'],
            ['Offline', '2', '2', '2', '1'],
        ],
        [4*cm, 2*cm, 2*cm, 2*cm, 2*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Critical Findings'))

    story.append(h3('R-1: Duplicate Realtime Subscriptions on Notifications'))
    story.append(p(
        'Two separate Supabase realtime channels subscribe to the same notifications table with the same '
        'user_id filter: (1) RealtimeProvider (global, mounted in app layout) on channel "global-notifications", '
        'and (2) NotificationsPage (per-page) on channel "notifications-realtime". When a user navigates to '
        '/notifications, both channels are active simultaneously. Every database event triggers two separate '
        'handlers, causing double processing, wasted WebSocket bandwidth, and server-side resources. Fix: '
        'Remove the per-page subscription and have the page consume from the NotificationStore that the '
        'RealtimeProvider already populates.'
    ))
    story.append(spacer(6))

    story.append(h3('R-2: No onAuthStateChange Listener'))
    story.append(p(
        'The application never calls supabase.auth.onAuthStateChange(). The useAuthStore is populated during '
        'login but never updated when the access token is silently refreshed (typically every hour), when the '
        'user signs out from another tab, or when the session expires. The RealtimeProvider reads user from '
        'useAuthStore, so if the session changes client-side, the realtime channel will not be re-created with '
        'new credentials. This can lead to events silently failing after token expiry. Fix: Add an '
        'onAuthStateChange listener in the RealtimeProvider or a dedicated AuthProvider.'
    ))
    story.append(spacer(6))

    story.append(h3('O-1: useOffline Hook Never Used'))
    story.append(p(
        'The useOffline hook is well-implemented (detects navigator.onLine, listens for online/offline events, '
        'cleans up on unmount) but is never imported or used by any component. There is no offline banner, '
        'no connection status indicator, and no disabled state for actions requiring network. Fix: Add an '
        'OfflineBanner component in the app layout and use useOffline in the header.'
    ))
    story.append(spacer(6))

    story.append(h3('O-2: No Retry Queue - Dexie Not Used'))
    story.append(p(
        'Dexie is listed as a dependency but never configured. There is no IndexedDB database, no offline '
        'mutation queue, and no mechanism to sync answers when the network recovers. The ExamSessionStore '
        'persists to localStorage but has no sync logic. Fix: Create a Dexie database for offline storage, '
        'wrap mutations with offline-aware logic, and implement a sync engine.'
    ))
    story.append(spacer(10))

    story.append(h2('High Severity Findings'))

    story.append(h3('R-3: No Reconnection with Data Reconciliation'))
    story.append(p(
        'Both realtime subscriptions log CHANNEL_ERROR and CLOSED status but never attempt to recover missed '
        'data. Supabase will reconnect the WebSocket but does not replay missed events. After reconnection, '
        'any notifications inserted while disconnected are never delivered. Fix: On reconnection (SUBSCRIBED '
        'status after a previous error), re-fetch unread count and notifications list.'
    ))
    story.append(spacer(4))

    story.append(h3('R-5: Unbounded Toast Arrays - Memory Leak'))
    story.append(p(
        'Both NotificationStore.toasts and UIStore.toasts arrays grow indefinitely. The addToast action only '
        'appends items, and removeToast requires explicit manual invocation. If a burst of notifications '
        'arrives (e.g., teacher publishes an exam to 200 students), the array could grow to hundreds of '
        'entries. Fix: Cap the arrays at 50 entries and add TTL-based auto-cleanup.'
    ))
    story.append(spacer(4))

    story.append(h3('O-3: No Network Recovery Handler'))
    story.append(p(
        'The useOffline hook detects when the network comes back online, but no component acts on this event. '
        'There is no handler that replays queued mutations, refetches stale data, or reconciles the cache. '
        'Fix: Add a useNetworkRecovery hook that invalidates TanStack Query cache and replays pending '
        'mutations from the offline queue.'
    ))
    story.append(spacer(4))

    story.append(h3('O-4: No Conflict Resolution Strategy'))
    story.append(p(
        'The ExamSessionStore persists answers to localStorage but has no conflict resolution when a student '
        'answers offline and the exam timer expires on the server, or when offline answers conflict with the '
        'server version. Fix: Add versioning/timestamps to answers and implement a "last write wins" or '
        '"server wins" strategy.'
    ))
    story.append(spacer(10))

    story.append(h2('Priority Remediation Order'))
    story.append(make_table(
        ['Priority', 'Action', 'Impact'],
        [
            ['P0', 'Eliminate duplicate subscriptions', 'Double processing, wasted bandwidth'],
            ['P0', 'Add onAuthStateChange listener', 'Session desync after token refresh'],
            ['P0', 'Wire up useOffline and add offline banner', 'Users have no offline awareness'],
            ['P0', 'Implement Dexie-based offline mutation queue', 'Offline mutations are silently lost'],
            ['P1', 'Cap toast arrays at 50 entries', 'Memory leak in long-running sessions'],
            ['P1', 'Add reconnection data reconciliation', 'Missed notifications after reconnect'],
            ['P1', 'Add network recovery handler', 'Stale data after network recovery'],
            ['P1', 'Add conflict resolution for exam answers', 'CBT integrity during offline'],
            ['P2', 'Fix race condition in notifications setup', 'Potential duplicate events'],
            ['P2', 'Make live indicator reflect connection status', 'Misleading UX'],
        ],
        [1.5*cm, 8*cm, 7*cm]
    ))

    return build_pdf('Realtime_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 7: Executive Report (FINAL DELIVERABLE)
# ══════════════════════════════════════════════════════════════════════════════
def generate_executive_report():
    story = []
    story.append(h1('Executive Production Readiness Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Overall Production Score'))
    story.append(p(
        'The following scores represent the current state of the ExamForge AI Next.js application based on '
        'comprehensive audits across code quality, security, performance, accessibility, data integrity, '
        'realtime, and offline capabilities. Each score is calculated from the number and severity of findings '
        'in each category, with Critical findings weighted most heavily. Scores are out of 100.'
    ))
    story.append(spacer(6))

    story.append(make_table(
        ['Category', 'Score', 'Status'],
        [
            ['Security', '42/100', 'NOT PRODUCTION READY - 2 Critical, 4 High findings'],
            ['Performance', '48/100', 'NOT PRODUCTION READY - 3 Critical, 8 High findings'],
            ['Accessibility', '52/100', 'NOT PRODUCTION READY - 4 Critical, 12 High findings'],
            ['Data Integrity', '38/100', 'NOT PRODUCTION READY - 8 Critical, 8 High findings'],
            ['Maintainability', '55/100', 'NEEDS WORK - 2 Critical, 6 High findings'],
            ['Scalability', '35/100', 'NOT PRODUCTION READY - Unbounded queries, N+1 patterns'],
            ['UI Consistency', '65/100', 'NEEDS WORK - Inconsistent states, missing loading states'],
            ['Production Readiness', '42/100', 'NOT PRODUCTION READY'],
        ],
        [4*cm, 2*cm, 11*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Production Readiness Score: 42/100'))
    story.append(p(
        'The ExamForge AI application is NOT production-ready in its current state. There are 19 Critical '
        'findings across all audit categories that must be resolved before enterprise deployment. The most '
        'impactful areas requiring immediate attention are: (1) Data leakage bugs where school admins and '
        'teachers can see cross-school data, (2) Broken role-based access control in middleware, (3) Missing '
        'Content Security Policy, and (4) No authorization checks on server actions. The application has a '
        'solid architectural foundation with proper Supabase integration, but the implementation quality gaps '
        'are significant enough to prevent safe production deployment.'
    ))
    story.append(spacer(10))

    story.append(h2('Critical Blockers (Must Fix Before Deployment)'))
    story.append(make_table(
        ['#', 'Blocker', 'Category', 'Impact'],
        [
            ['1', 'Data leakage: school admins see cross-school data', 'Data', 'Data security breach'],
            ['2', 'Data leakage: teachers see all pending grading', 'Data', 'Data security breach'],
            ['3', 'Reports not filtered by school', 'Data', 'Data security breach'],
            ['4', 'Teacher dashboard counts exams instead of students', 'Data', 'Incorrect business metrics'],
            ['5', 'Analytics date range filter never applied', 'Data', 'Incorrect analytics'],
            ['6', 'Middleware RBAC route prefixes do not match', 'Security', 'Role-based access control broken'],
            ['7', 'No Content Security Policy', 'Security', 'XSS, clickjacking vulnerability'],
            ['8', 'Server actions lack authorization checks', 'Security', 'Unauthorized data modification'],
            ['9', 'N+1 queries in reports (250+ queries)', 'Performance', 'Timeouts at scale'],
            ['10', 'Unbounded queries (no pagination)', 'Scalability', 'Memory issues, slow load times'],
            ['11', 'App layout is entirely client component', 'Performance', 'No RSC benefits, slow FCP'],
            ['12', 'Duplicate realtime subscriptions', 'Realtime', 'Double processing, wasted resources'],
            ['13', 'No onAuthStateChange listener', 'Realtime', 'Session desync after token refresh'],
            ['14', 'No offline indicator or mutation queue', 'Offline', 'Silent failures when offline'],
            ['15', 'Sortable table headers not keyboard-accessible', 'Accessibility', 'WCAG 2.1.1 violation'],
            ['16', 'No skip-link in authenticated layout', 'Accessibility', 'WCAG 2.4.1 violation'],
            ['17', 'Color-only status indicators', 'Accessibility', 'WCAG 1.4.1 violation'],
            ['18', 'No prefers-reduced-motion support', 'Accessibility', 'WCAG 2.3.3 violation'],
            ['19', 'Auth callback open redirect', 'Security', 'Phishing/redirect vulnerability'],
        ],
        [1*cm, 7*cm, 2.5*cm, 5*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Summary by Audit Category'))
    story.append(p(
        '<b>Code Audit:</b> 18 findings. 14+ unused npm packages, 5x duplicate utility functions, dead API '
        'client module, unused Prisma client, 34 production console statements. The middleware RBAC is broken '
        'because route prefixes do not match actual routes.'
    ))
    story.append(p(
        '<b>Security Audit:</b> 12 findings. No CSP, server actions lack authorization, auth callback open '
        'redirect, no rate limiting, no security headers. Positive: getUser() used correctly in middleware, '
        'SSR client properly configured, service role key never exposed.'
    ))
    story.append(p(
        '<b>Performance Audit:</b> 27 findings. Entire app layout is a client component, analytics and '
        'notifications pages use client-side data fetching, recharts not dynamically imported (~200KB), '
        'TanStack Query configured but never used, missing per-route loading.tsx files.'
    ))
    story.append(p(
        '<b>Accessibility Audit:</b> 36 findings. Sortable table headers not keyboard-accessible, no '
        'skip-link in authenticated layout, color-only status indicators, no prefers-reduced-motion support, '
        'search inputs without labels, icon-only buttons missing accessible names.'
    ))
    story.append(p(
        '<b>Data Integrity Audit:</b> 26 findings. 8 Critical data leakage/correctness bugs, 4 N+1 query '
        'patterns that will cause timeouts, 6 unbounded queries without pagination, analytics date range '
        'filter never applied, silent error handling in search service.'
    ))
    story.append(p(
        '<b>Realtime/Offline Audit:</b> 17 findings. Duplicate realtime subscriptions, no onAuthStateChange, '
        'no reconnection data reconciliation, useOffline hook never used, Dexie never configured, no offline '
        'mutation queue or network recovery handler.'
    ))
    story.append(spacer(10))

    story.append(h2('Recommended Phase 6.1 Priority Actions'))
    story.append(p(
        'Based on the audit findings, the following actions should be taken in priority order before the '
        'application can be considered production-ready. These are grouped into three phases: P0 (must fix '
        'before any deployment), P1 (must fix before enterprise deployment), and P2 (should fix for '
        'production quality).'
    ))
    story.append(spacer(4))

    story.append(h3('P0: Must Fix Before Any Deployment'))
    story.append(p(
        '1. Fix data leakage bugs (scope queries by school/teacher) | 2. Fix middleware RBAC route prefixes | '
        '3. Add Content Security Policy | 4. Add authorization checks to server actions | '
        '5. Fix analytics date range filter | 6. Fix teacher dashboard student count | '
        '7. Validate auth callback next parameter | 8. Add pagination to all list queries'
    ))
    story.append(spacer(4))

    story.append(h3('P1: Must Fix Before Enterprise Deployment'))
    story.append(p(
        '9. Fix N+1 queries in reports service | 10. Split app layout into Server + Client | '
        '11. Refactor analytics/notifications to Server Components | 12. Dynamic import recharts | '
        '13. Remove unused packages | 14. Add onAuthStateChange listener | '
        '15. Eliminate duplicate realtime subscriptions | 16. Add rate limiting to API routes | '
        '17. Replace console.error/warn with structured logging | 18. Add per-route loading.tsx | '
        '19. Add keyboard accessibility to data tables | 20. Add skip-link to authenticated layout'
    ))
    story.append(spacer(4))

    story.append(h3('P2: Should Fix for Production Quality'))
    story.append(p(
        '21. Consolidate duplicate utility functions | 22. Delete dead code (api/, db.ts, toast-service, etc.) | '
        '23. Use TanStack Query for client-side fetching | 24. Add prefers-reduced-motion support | '
        '25. Add aria-labels to all interactive elements | 26. Wire up useOffline and add offline banner | '
        '27. Implement Dexie-based offline mutation queue | 28. Add reconnection data reconciliation | '
        '29. Add conflict resolution for exam answers | 30. Add security headers to API responses'
    ))

    return build_pdf('Executive_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 8: Production Checklist (FINAL DELIVERABLE)
# ══════════════════════════════════════════════════════════════════════════════
def generate_production_checklist():
    story = []
    story.append(h1('Production Deployment Checklist'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('How to Use This Checklist'))
    story.append(p(
        'Each item must be verified before the application can be considered production-ready. Mark items '
        'as PASS, FAIL, or NOT VERIFIED. Items marked NOT VERIFIED must be explicitly tested before '
        'deployment. No item should be assumed to pass without evidence.'
    ))
    story.append(spacer(8))

    categories = [
        ('Security', [
            ('Content Security Policy configured', 'FAIL', 'No CSP headers found'),
            ('Server actions have authorization checks', 'FAIL', 'Missing auth checks on 5+ actions'),
            ('Auth callback validates redirect parameter', 'FAIL', 'Open redirect vulnerability'),
            ('Password change verifies current password', 'FAIL', 'No reauthentication'),
            ('Rate limiting on API routes', 'FAIL', 'No rate limiting implemented'),
            ('Security headers on API responses', 'FAIL', 'No security headers'),
            ('Webhook signature verification', 'FAIL', 'No signature check in Next.js'),
            ('Service role key not exposed to client', 'PASS', 'Verified: not in client code'),
            ('getUser() used in middleware (not getSession)', 'PASS', 'Verified: correct implementation'),
            ('Environment variables properly namespaced', 'PASS', 'Verified: NEXT_PUBLIC_ only for public'),
            ('RLS policies enforced on Supabase', 'NOT VERIFIED', 'Cannot verify from codebase alone'),
            ('JWT expiry handled gracefully', 'NOT VERIFIED', 'No onAuthStateChange listener'),
        ]),
        ('Data Integrity', [
            ('School admins scoped to their school', 'FAIL', 'Data leakage: sees all schools'),
            ('Teachers scoped to their exams', 'FAIL', 'Data leakage: sees all pending grading'),
            ('Reports filtered by school', 'FAIL', 'Sessions not filtered by school'),
            ('Analytics date range filter applied', 'FAIL', 'Filter computed but never used'),
            ('Teacher dashboard counts students correctly', 'FAIL', 'Counts exam IDs instead'),
            ('All list queries paginated', 'FAIL', '6+ unbounded queries'),
            ('N+1 queries eliminated', 'FAIL', '4 N+1 patterns in reports'),
            ('Error handling on all Supabase queries', 'FAIL', 'Search service has 8 silent errors'),
            ('Optimistic updates have rollback', 'FAIL', 'No rollback on notifications'),
            ('Revenue calculation consistent', 'FAIL', 'Dashboard and reports differ'),
        ]),
        ('Performance', [
            ('App layout uses Server Component', 'FAIL', 'Entire layout is "use client"'),
            ('Analytics page uses Server Component', 'FAIL', 'Client-side data fetching'),
            ('Notifications page uses Server Component for initial data', 'FAIL', 'Client-side fetching'),
            ('Recharts dynamically imported', 'FAIL', 'Static import (~200KB)'),
            ('Unused packages removed', 'FAIL', '14+ unused packages'),
            ('Per-route loading.tsx files', 'FAIL', 'Missing for 10+ routes'),
            ('Suspense boundaries for streaming', 'FAIL', 'None used'),
            ('TanStack Query used for client-side fetching', 'FAIL', 'Configured but never used'),
            ('Framer Motion not in main bundle', 'FAIL', 'In StatCard, used on every page'),
            ('Image optimization with next/image', 'FAIL', 'Settings uses raw img tag'),
            ('Font optimization with next/font', 'PASS', 'Inter with display: swap'),
            ('Production build succeeds', 'NOT VERIFIED', 'Needs runtime verification'),
        ]),
        ('Accessibility', [
            ('All interactive elements keyboard-accessible', 'FAIL', 'Table sort headers not accessible'),
            ('Skip-link in authenticated layout', 'FAIL', 'Missing'),
            ('All form inputs have labels', 'FAIL', 'Search inputs, date inputs missing labels'),
            ('ARIA labels on icon-only buttons', 'FAIL', 'Billing download, View buttons'),
            ('prefers-reduced-motion respected', 'FAIL', 'No support in Framer Motion components'),
            ('Color-only indicators have alternatives', 'FAIL', 'Unread notification dot'),
            ('Status changes announced to screen readers', 'FAIL', 'Notification actions not announced'),
            ('Landmark regions properly defined', 'FAIL', 'Missing nav, header landmarks'),
            ('HTML lang attribute set', 'PASS', 'lang="en" on root'),
            ('Public layout has skip-link', 'PASS', 'Verified'),
            ('Auth forms have proper ARIA', 'PASS', 'Verified: aria-label, role="alert"'),
        ]),
        ('Realtime & Offline', [
            ('No duplicate realtime subscriptions', 'FAIL', '2 subscriptions on notifications'),
            ('onAuthStateChange listener active', 'FAIL', 'Not implemented'),
            ('Reconnection data reconciliation', 'FAIL', 'No missed-event recovery'),
            ('Offline indicator in UI', 'FAIL', 'useOffline hook never used'),
            ('Offline mutation queue', 'FAIL', 'Dexie not configured'),
            ('Network recovery handler', 'FAIL', 'No replay of queued mutations'),
            ('Conflict resolution for exam answers', 'FAIL', 'No versioning or comparison'),
            ('Realtime subscriptions properly cleaned up', 'NOT VERIFIED', 'Needs runtime testing'),
            ('Live indicator reflects actual connection status', 'FAIL', 'Always shows "Live"'),
        ]),
        ('Code Quality', [
            ('No console.log/error/warn in production', 'FAIL', '34 instances found'),
            ('No duplicate logic', 'FAIL', '5x formatRelativeTime, 3x formatCurrency'),
            ('No dead code', 'FAIL', '8 unused components, 3 unused hooks, 3 unused stores'),
            ('No unused dependencies', 'FAIL', '14+ unused packages'),
            ('Middleware RBAC routes match actual routes', 'FAIL', 'Prefixes do not match'),
            ('No TODO/FIXME comments', 'PASS', 'None found'),
            ('No mock/placeholder data', 'PASS', 'Verified: all data from Supabase'),
            ('TypeScript strict mode enabled', 'PASS', 'Verified in tsconfig.json'),
        ]),
    ]

    for cat_name, items in categories:
        story.append(h2(cat_name))
        rows = []
        for item, status, note in items:
            status_color = {'PASS': SEM_SUCCESS, 'FAIL': SEM_ERROR, 'NOT VERIFIED': SEM_WARNING}.get(status, TEXT_MUTED)
            rows.append([
                Paragraph(f'<font color="{status_color.hexval()}"><b>{status}</b></font>', body_style),
                Paragraph(item, body_style),
                Paragraph(note, muted_style),
            ])
        story.append(make_table(
            [Paragraph('<b>Status</b>', ParagraphStyle('th', parent=body_style, textColor=colors.white)),
             Paragraph('<b>Item</b>', ParagraphStyle('th2', parent=body_style, textColor=colors.white)),
             Paragraph('<b>Notes</b>', ParagraphStyle('th3', parent=body_style, textColor=colors.white))],
            rows,
            [2*cm, 8*cm, 6.5*cm]
        ))
        story.append(spacer(8))

    return build_pdf('Production_Checklist.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 9: Architecture Status (FINAL DELIVERABLE)
# ══════════════════════════════════════════════════════════════════════════════
def generate_architecture_status():
    story = []
    story.append(h1('Architecture Status Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Technology Stack'))
    story.append(make_table(
        ['Layer', 'Technology', 'Version', 'Status'],
        [
            ['Framework', 'Next.js', '16.1.1', 'Active, configured'],
            ['UI Library', 'React', '19.0.0', 'Active, configured'],
            ['Auth', 'Supabase Auth (SSR)', '2.111.0', 'Active, configured'],
            ['Database', 'Supabase (PostgreSQL)', 'N/A', 'Active, live queries'],
            ['ORM', 'Prisma', '6.11.1', 'DEAD - installed but never used'],
            ['State', 'Zustand', '5.0.14', 'Partial - 3/5 stores unused'],
            ['Query', 'TanStack React Query', '5.101.4', 'DEAD - configured but never used'],
            ['Offline', 'Dexie', '4.4.4', 'DEAD - installed but never used'],
            ['Charts', 'Recharts', '3.10.1', 'Active, not dynamically imported'],
            ['UI Components', 'shadcn/ui (Radix)', 'Various', 'Active, 40+ components'],
            ['Styling', 'Tailwind CSS', '4.x', 'Active, configured'],
            ['Animations', 'Framer Motion', '12.43.0', 'Active, in main bundle'],
            ['Toasts', 'Sonner', '2.0.7', 'Active, configured'],
            ['Forms', 'React Hook Form + Zod', '7.84.0 / 4.4.3', 'Active, configured'],
            ['PWA', 'next-pwa', '5.6.0', 'DEAD - installed but not configured'],
            ['i18n', 'next-intl', '4.3.4', 'DEAD - installed but not configured'],
        ],
        [3*cm, 4.5*cm, 2.5*cm, 6.5*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Architecture Components'))
    story.append(p(
        'The application follows a standard Next.js App Router architecture with route groups for (public) '
        'and (app) layouts. Server Components are used for data fetching on most pages, though the app layout '
        'and several key pages (analytics, notifications, settings) are client components. The middleware '
        'implements a 3-layer guard chain (AuthGuard, OnboardingGuard, RoleBasedGuard), though the role-based '
        'guard is currently non-functional due to route prefix mismatch.'
    ))
    story.append(spacer(6))

    story.append(h3('Active Architecture Paths'))
    story.append(p(
        'The following architecture paths are actively used and functional: Supabase SSR for authentication, '
        'Server Components for data fetching on most pages, Server Actions for mutations (create school, '
        'mark notification read, delete notification), Realtime subscriptions via Supabase channels, '
        'Zustand for auth and notification state, and the shadcn/ui component library for UI elements.'
    ))
    story.append(spacer(4))

    story.append(h3('Dead Architecture Paths'))
    story.append(p(
        'The following architecture paths are installed but never used: Prisma ORM (db.ts is never imported), '
        'TanStack React Query (QueryProvider mounted but no useQuery calls), Dexie offline storage (never '
        'configured), next-pwa (no PWA config in next.config.ts), next-intl (no i18n configuration), '
        'next-auth (Supabase Auth is used instead), the API client module (api/client.ts, errors.ts, result.ts), '
        'the toast service wrapper (toast-service.ts), and three Zustand stores (ui-store, exam-session-store, '
        'theme-store preferences).'
    ))
    story.append(spacer(10))

    story.append(h2('Data Flow Architecture'))
    story.append(p(
        '<b>Server Component Pages:</b> Page.tsx (Server Component) calls createClient() from '
        'supabase/server.ts, fetches data via supabase.from().select(), renders with RSC, and passes '
        'data as props to client components. This is the correct pattern and is used by: schools, students, '
        'teachers, parents, results, CBT, question-bank, marketplace, billing, dashboard, and reports pages.'
    ))
    story.append(p(
        '<b>Client Component Pages:</b> Analytics, notifications, and settings pages use "use client" '
        'with useEffect + supabase client for data fetching. This is the incorrect pattern for initial '
        'data loads and should be refactored to use Server Components for initial data.'
    ))
    story.append(p(
        '<b>Server Actions:</b> Mutations use Server Actions defined in features/ directory. These call '
        'revalidatePath() for cache invalidation. The pattern is correct but lacks authorization checks.'
    ))
    story.append(p(
        '<b>Realtime:</b> RealtimeProvider in the app layout subscribes to notifications and updates '
        'the NotificationStore. The notifications page also subscribes independently, creating duplicate '
        'subscriptions. This should be consolidated.'
    ))
    story.append(spacer(10))

    story.append(h2('Infrastructure Dependencies'))
    story.append(make_table(
        ['Service', 'Provider', 'Status', 'Notes'],
        [
            ['Authentication', 'Supabase Auth', 'Active', 'SSR pattern, cookie-based sessions'],
            ['Database', 'Supabase PostgreSQL', 'Active', 'RLS policies assumed but not verified from code'],
            ['Realtime', 'Supabase Realtime', 'Active', 'WebSocket subscriptions, duplicate channels'],
            ['Storage', 'Supabase Storage', 'Active', 'Configured for avatar images'],
            ['Edge Functions', 'Supabase Edge Functions', 'Active', 'AI, billing, CBT timing, marketplace, search'],
            ['Payments', 'Flutterwave', 'Active', 'Webhook proxy via Next.js API route'],
            ['Hosting', 'Next.js Standalone', 'Configured', 'output: "standalone" in next.config.ts'],
            ['CDN', 'Not configured', 'MISSING', 'No CDN for static assets'],
            ['Monitoring', 'Not configured', 'MISSING', 'No Sentry, OpenTelemetry, or analytics'],
            ['Rate Limiting', 'Supabase Edge Functions only', 'Partial', 'No rate limiting on Next.js API routes'],
        ],
        [3*cm, 4*cm, 2*cm, 7.5*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Architecture Recommendations'))
    story.append(p(
        '1. Remove dead architecture paths (Prisma, TanStack Query if not adopting, Dexie if not implementing '
        'offline, next-pwa, next-intl, next-auth) to reduce bundle size and maintenance burden. '
        '2. Adopt TanStack Query for client-side data fetching in analytics and notifications pages. '
        '3. Implement Dexie for offline support in CBT exam sessions. '
        '4. Add monitoring infrastructure (Sentry for errors, OpenTelemetry for tracing). '
        '5. Add rate limiting at the Next.js API route level. '
        '6. Configure Content Security Policy headers. '
        '7. Consolidate realtime subscriptions to use a single channel per table.'
    ))

    return build_pdf('Architecture_Status.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 10: Technical Debt Report (FINAL DELIVERABLE)
# ══════════════════════════════════════════════════════════════════════════════
def generate_technical_debt_report():
    story = []
    story.append(h1('Technical Debt Report'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Executive Summary'))
    story.append(p(
        'The technical debt audit identified 109 findings across all audit categories. The debt is categorized '
        'into four risk levels: Critical (blocks production deployment), High (must fix before enterprise '
        'deployment), Medium (should fix for production quality), and Low (nice to have). The total estimated '
        'effort to resolve all Critical and High debt is approximately 15-20 developer-days. The application '
        'has a solid architectural foundation, but implementation quality gaps in data scoping, security, '
        'performance, and accessibility create significant technical debt that must be addressed before '
        'production deployment.'
    ))
    story.append(spacer(8))

    story.append(h2('Debt Summary by Category'))
    story.append(make_table(
        ['Category', 'Critical', 'High', 'Medium', 'Low', 'Total'],
        [
            ['Code Quality', '2', '6', '7', '3', '18'],
            ['Security', '2', '4', '4', '2', '12'],
            ['Performance', '3', '8', '10', '6', '27'],
            ['Accessibility', '4', '12', '14', '6', '36'],
            ['Data Integrity', '8', '8', '6', '4', '26'],
            ['Realtime/Offline', '4', '5', '5', '3', '17'],
            ['Total', '23', '43', '46', '24', '136'],
        ],
        [3*cm, 2*cm, 2*cm, 2*cm, 2*cm, 2*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Debt by Type'))
    story.append(h3('Architecture Debt'))
    story.append(p(
        'The application has 4 dead architecture paths: Prisma ORM, TanStack Query, Dexie offline storage, '
        'and next-pwa. These are installed and partially configured but never used. They represent both '
        'bundle bloat and maintenance burden. The recommended approach is to either fully adopt each '
        'technology (implementing the missing integration) or remove it entirely. The estimated effort to '
        'adopt TanStack Query is 2-3 days, Dexie is 5-7 days, and removing all dead paths is 1 day.'
    ))
    story.append(spacer(4))

    story.append(h3('Security Debt'))
    story.append(p(
        'The most significant security debt is the absence of Content Security Policy headers and the lack '
        'of authorization checks on server actions. These are not difficult to fix (estimated 2-3 days total) '
        'but are critical for production deployment. The auth callback open redirect is a simple fix (1 hour). '
        'Rate limiting requires infrastructure decisions (Redis vs. in-memory) and is estimated at 2-3 days.'
    ))
    story.append(spacer(4))

    story.append(h3('Data Debt'))
    story.append(p(
        'The data scoping bugs (school admins seeing cross-school data, teachers seeing all pending grading) '
        'are the most critical data debt. These are not complex to fix (estimated 1-2 days) but are data '
        'security issues that must be resolved. The N+1 query patterns in the reports service require '
        'more significant refactoring (estimated 3-4 days). The unbounded queries need pagination '
        'implementation (estimated 2-3 days). The analytics date range filter is a simple fix (1 hour).'
    ))
    story.append(spacer(4))

    story.append(h3('Performance Debt'))
    story.append(p(
        'The most impactful performance debt is the app layout being a client component. Fixing this requires '
        'splitting the layout into a Server Component wrapper and a Client Component shell, which is estimated '
        'at 2-3 days. The analytics and notifications pages should be refactored to Server Components (2-3 days). '
        'Dynamic importing of recharts and removing unused packages is straightforward (1 day). Adding '
        'per-route loading.tsx files is estimated at 1-2 days.'
    ))
    story.append(spacer(4))

    story.append(h3('Accessibility Debt'))
    story.append(p(
        'The accessibility debt is the most extensive category (36 findings). The most impactful fixes are: '
        'making data table sort headers keyboard-accessible (1 day), adding skip-link to the authenticated '
        'layout (2 hours), adding prefers-reduced-motion support (1 day), and adding ARIA labels to all '
        'interactive elements (2-3 days). The total estimated effort for accessibility is 5-7 days.'
    ))
    story.append(spacer(4))

    story.append(h3('Realtime/Offline Debt'))
    story.append(p(
        'The realtime debt includes duplicate subscriptions, no onAuthStateChange listener, and no '
        'reconnection data reconciliation. These are estimated at 2-3 days to fix. The offline debt is '
        'more significant: implementing Dexie-based offline storage, mutation queue, network recovery, '
        'and conflict resolution is estimated at 7-10 days. The offline debt may be deferred if the '
        'application does not require offline CBT functionality immediately.'
    ))
    story.append(spacer(10))

    story.append(h2('Effort Estimation'))
    story.append(make_table(
        ['Priority', 'Category', 'Estimated Effort', 'Risk if Deferred'],
        [
            ['P0', 'Data scoping bugs', '1-2 days', 'Data security breach'],
            ['P0', 'Middleware RBAC fix', '0.5 days', 'No role-based access control'],
            ['P0', 'CSP + server action auth', '2-3 days', 'XSS, unauthorized modifications'],
            ['P0', 'Analytics date filter fix', '1 hour', 'Incorrect analytics'],
            ['P0', 'Teacher dashboard fix', '1 hour', 'Incorrect business metrics'],
            ['P0', 'Auth callback redirect fix', '1 hour', 'Phishing vulnerability'],
            ['P0', 'Pagination for list queries', '2-3 days', 'Timeouts at scale'],
            ['P1', 'N+1 query refactoring', '3-4 days', 'Timeouts at scale'],
            ['P1', 'App layout RSC split', '2-3 days', 'No SSR benefits'],
            ['P1', 'Analytics/notifications RSC', '2-3 days', 'No SSR, slow FCP'],
            ['P1', 'Remove unused packages', '1 day', 'Bundle bloat, security surface'],
            ['P1', 'Dynamic import recharts', '0.5 days', '~200KB in main bundle'],
            ['P1', 'onAuthStateChange + realtime', '2-3 days', 'Session desync'],
            ['P1', 'Rate limiting', '2-3 days', 'Brute force, spam'],
            ['P1', 'Structured logging', '1-2 days', 'No observability'],
            ['P1', 'Accessibility P0 fixes', '2-3 days', 'WCAG violations'],
            ['P2', 'Offline support (Dexie)', '7-10 days', 'No offline CBT'],
            ['P2', 'TanStack Query adoption', '2-3 days', 'No client-side caching'],
            ['P2', 'Dead code removal', '1-2 days', 'Maintenance burden'],
            ['P2', 'Accessibility P1/P2 fixes', '3-4 days', 'WCAG AA compliance'],
        ],
        [1.5*cm, 4.5*cm, 3*cm, 7*cm]
    ))

    return build_pdf('Technical_Debt_Report.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# REPORT 11: Deployment Guide (FINAL DELIVERABLE)
# ══════════════════════════════════════════════════════════════════════════════
def generate_deployment_guide():
    story = []
    story.append(h1('Deployment Guide'))
    story.append(Paragraph(f'ExamForge AI | Generated: {DATE_STR}', muted_style))
    story.append(hr())

    story.append(h2('Prerequisites'))
    story.append(p(
        'Before deploying the ExamForge AI application, the following prerequisites must be met. This guide '
        'assumes deployment to a Node.js-compatible hosting environment (Vercel, AWS, Docker, or similar) '
        'with access to the Supabase project.'
    ))
    story.append(spacer(4))

    story.append(make_table(
        ['Prerequisite', 'Status', 'Notes'],
        [
            ['Node.js 18+', 'Required', 'For Next.js 16 runtime'],
            ['Supabase project', 'Active', 'Project ref: pzfnptrrnxkgodclyhft'],
            ['Environment variables', 'Required', 'NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY'],
            ['Flutterwave credentials', 'Required', 'For payment processing'],
            ['Production build', 'NOT VERIFIED', 'Must pass npm run build without errors'],
            ['CSP headers', 'NOT IMPLEMENTED', 'Critical security requirement'],
            ['Rate limiting', 'NOT IMPLEMENTED', 'Critical for API protection'],
            ['Monitoring', 'NOT IMPLEMENTED', 'Sentry/OpenTelemetry recommended'],
        ],
        [4*cm, 3*cm, 9*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Pre-Deployment Checklist'))
    story.append(p(
        'The following items MUST be completed before production deployment. Items marked as FAIL or '
        'NOT VERIFIED in the Production Checklist must be resolved. The most critical blockers are '
        'listed below with their remediation steps.'
    ))
    story.append(spacer(6))

    story.append(h3('1. Security Remediation'))
    story.append(p(
        'Add Content Security Policy headers in middleware.ts or next.config.ts. The CSP should allow '
        'scripts from self and the Supabase domain, styles from self and inline, images from self and '
        'Supabase storage, and connections to the Supabase API and WebSocket endpoints. Add authorization '
        'checks to all server actions (verify user identity and role before performing mutations). Validate '
        'the auth callback next parameter to prevent open redirects. Add rate limiting to API routes using '
        'Redis-backed rate limiting (e.g., Upstash) or an in-memory rate limiter.'
    ))
    story.append(spacer(4))

    story.append(h3('2. Data Scoping Remediation'))
    story.append(p(
        'Fix all queries that do not properly scope data by school or teacher. The getSchoolAdminStats, '
        'getTeacherStats, and reports service queries must filter by school_id or teacher exam IDs. Fix '
        'the teacher dashboard to count students instead of exams. Fix the analytics date range filter '
        'to apply the computed dateFilter to the query. Add pagination to all list queries (schools, '
        'students, teachers, parents, marketplace, CBT exams).'
    ))
    story.append(spacer(4))

    story.append(h3('3. Middleware RBAC Remediation'))
    story.append(p(
        'Update the ROLE_ROUTE_PREFIXES in middleware.ts to match the actual route structure. The current '
        'prefixes (/admin, /school, /teacher, /student) do not match the actual routes (/dashboard/super-admin, '
        '/dashboard/school-admin, /dashboard/teacher, /dashboard/student). Either update the prefixes or '
        'restructure the routes to match the guard prefixes.'
    ))
    story.append(spacer(10))

    story.append(h2('Environment Configuration'))
    story.append(p(
        'The following environment variables are required for production deployment. Sensitive values should '
        'be stored in the hosting platform\'s secret manager, not in .env files.'
    ))
    story.append(spacer(4))

    story.append(make_table(
        ['Variable', 'Required', 'Description'],
        [
            ['NEXT_PUBLIC_SUPABASE_URL', 'Yes', 'Supabase project URL'],
            ['NEXT_PUBLIC_SUPABASE_ANON_KEY', 'Yes', 'Supabase anonymous key (public)'],
            ['SUPABASE_SERVICE_ROLE_KEY', 'Server only', 'For admin operations (NEVER expose to client)'],
            ['FLUTTERWAVE_PUBLIC_KEY', 'Yes', 'Flutterwave payment public key'],
            ['FLUTTERWAVE_SECRET_KEY', 'Server only', 'Flutterwave payment secret key'],
            ['FLUTTERWAVE_WEBHOOK_HASH', 'Server only', 'For webhook signature verification'],
            ['SENTRY_DSN', 'Recommended', 'For error tracking'],
            ['NEXT_PUBLIC_SENTRY_DSN', 'Recommended', 'For client-side error tracking'],
        ],
        [5*cm, 2*cm, 9*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Build and Deploy'))
    story.append(h3('Build Commands'))
    story.append(Paragraph('npm run build', code_style))
    story.append(p(
        'The build command compiles the Next.js application for production. The output: "standalone" '
        'configuration in next.config.ts produces a self-contained build in .next/standalone/ that can '
        'be deployed without node_modules. The build script also copies static assets and public files '
        'to the standalone directory.'
    ))
    story.append(spacer(4))

    story.append(h3('Start Command'))
    story.append(Paragraph('NODE_ENV=production node .next/standalone/server.js', code_style))
    story.append(p(
        'The standalone server starts on port 3000 by default. Set the PORT environment variable to '
        'customize. The server should be run behind a reverse proxy (nginx, Cloudflare, etc.) for '
        'SSL termination and additional security headers.'
    ))
    story.append(spacer(4))

    story.append(h3('Docker Deployment'))
    story.append(p(
        'The standalone output is Docker-ready. Create a Dockerfile that copies the standalone build, '
        'installs only production dependencies, and runs the server. Use a multi-stage build to minimize '
        'image size. The Docker image should expose port 3000 and set NODE_ENV=production.'
    ))
    story.append(spacer(10))

    story.append(h2('Post-Deployment Verification'))
    story.append(p(
        'After deployment, verify the following items to ensure the application is functioning correctly:'
    ))
    story.append(make_table(
        ['Verification', 'Method', 'Expected Result'],
        [
            ['Auth flow works', 'Login with test account', 'Redirect to dashboard, session established'],
            ['RBAC works', 'Login as different roles', 'Role-appropriate access only'],
            ['Data scoping works', 'Login as school admin', 'Only see own school data'],
            ['Realtime works', 'Open notifications page', 'Live indicator, new notifications appear'],
            ['Payments work', 'Test checkout flow', 'Flutterwave payment completes'],
            ['CSP works', 'Check browser console', 'No CSP violation errors'],
            ['Rate limiting works', 'Send 100 requests to API', 'Rate limit response after threshold'],
            ['Error tracking works', 'Trigger a test error', 'Error appears in Sentry'],
            ['Performance acceptable', 'Run Lighthouse audit', 'FCP < 2s, LCP < 3s, CLS < 0.1'],
            ['Accessibility passes', 'Run axe-core scan', '0 Critical/High violations'],
        ],
        [3.5*cm, 4*cm, 8.5*cm]
    ))
    story.append(spacer(10))

    story.append(h2('Monitoring and Alerting'))
    story.append(p(
        'The following monitoring infrastructure should be set up before production deployment:'
    ))
    story.append(p(
        '<b>Error Tracking:</b> Configure Sentry for both server-side and client-side error tracking. '
        'Set up alerts for error rate spikes (>1% of requests). Use the Sentry Next.js SDK for '
        'automatic error capture and source map upload.'
    ))
    story.append(p(
        '<b>Performance Monitoring:</b> Configure OpenTelemetry for distributed tracing. Set up alerts '
        'for slow API responses (>500ms p99) and high error rates. Use the Next.js instrumentation '
        'hook to initialize tracing.'
    ))
    story.append(p(
        '<b>Uptime Monitoring:</b> Set up health checks on the /api/health endpoint (create if needed). '
        'Configure alerts for downtime (>5 minutes). Use a service like Pingdom or UptimeRobot.'
    ))
    story.append(p(
        '<b>Analytics:</b> Integrate PostHog or similar for product analytics. Track key user flows: '
        'login, exam creation, exam taking, result viewing, and payment completion.'
    ))
    story.append(spacer(10))

    story.append(h2('Rollback Plan'))
    story.append(p(
        'If critical issues are discovered after deployment, the following rollback procedure should be '
        'followed: (1) Revert to the previous deployment using the hosting platform\'s rollback feature '
        '(Vercel: instant rollback, Docker: redeploy previous image). (2) If the issue is a database '
        'migration, use Supabase\'s point-in-time recovery to restore the database to a previous state. '
        '(3) If the issue is a Supabase configuration change, revert the change in the Supabase dashboard. '
        '(4) Communicate the rollback to stakeholders and document the root cause for the post-mortem.'
    ))

    return build_pdf('Deployment_Guide.pdf', story)


# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════
if __name__ == '__main__':
    print('Generating Phase 6 Audit Reports...')
    print('=' * 60)

    # Task-specific reports
    generate_code_audit_report()
    generate_security_report()
    generate_performance_report()
    generate_accessibility_report()
    generate_data_report()
    generate_realtime_report()

    # Final deliverables
    generate_executive_report()
    generate_production_checklist()
    generate_architecture_status()
    generate_technical_debt_report()
    generate_deployment_guide()

    print('=' * 60)
    print('All 11 reports generated successfully.')
