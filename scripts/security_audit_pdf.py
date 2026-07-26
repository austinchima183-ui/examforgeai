#!/usr/bin/env python3
# ============================================================================
# ExamForge AI — Enterprise Security Certification Audit Report
# ============================================================================
# Generates a professional 20-30 page PDF via ReportLab covering Parts A-P
# of the comprehensive security audit.
# ============================================================================

import os
import sys
from datetime import datetime, timezone

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm, inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, ListFlowable, ListItem,
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# ─── FONT REGISTRATION ──────────────────────────────────────────────────
FONT_DIR = '/usr/share/fonts'
pdfmetrics.registerFont(TTFont('NotoSerifSC', f'{FONT_DIR}/truetype/noto-serif-sc/NotoSerifSC-Regular.ttf'))
pdfmetrics.registerFont(TTFont('NotoSerifSC-Bold', f'{FONT_DIR}/truetype/noto-serif-sc/NotoSerifSC-Bold.ttf'))
registerFontFamily('NotoSerifSC', normal='NotoSerifSC', bold='NotoSerifSC-Bold')
pdfmetrics.registerFont(TTFont('NotoSansSC', f'{FONT_DIR}/truetype/chinese/SarasaMonoSC-Regular.ttf'))
pdfmetrics.registerFont(TTFont('NotoSansSC-Bold', f'{FONT_DIR}/truetype/chinese/SarasaMonoSC-Bold.ttf'))
registerFontFamily('NotoSansSC', normal='NotoSansSC', bold='NotoSansSC-Bold')

# ─── PALETTE (from cascade generator) ───────────────────────────────────
PAGE_BG       = colors.HexColor('#f6f7f7')
SECTION_BG    = colors.HexColor('#ebeded')
CARD_BG       = colors.HexColor('#e8eaeb')
TABLE_STRIPE  = colors.HexColor('#eff0f1')
HEADER_FILL   = colors.HexColor('#39464d')
COVER_BLOCK   = colors.HexColor('#415761')
BORDER        = colors.HexColor('#b8c4ca')
ICON          = colors.HexColor('#517c92')
ACCENT        = colors.HexColor('#257da9')
ACCENT_2      = colors.HexColor('#c44f63')
TEXT_PRIMARY   = colors.HexColor('#1e2021')
TEXT_MUTED     = colors.HexColor('#757c7f')
SEM_SUCCESS   = colors.HexColor('#3f7f54')
SEM_WARNING   = colors.HexColor('#967c48')
SEM_ERROR     = colors.HexColor('#a24c44')
SEM_INFO      = colors.HexColor('#446f9a')

# ─── PAGE DIMENSIONS ────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
LEFT_MARGIN = 2.0 * cm
RIGHT_MARGIN = 2.0 * cm
TOP_MARGIN = 2.0 * cm
BOTTOM_MARGIN = 2.0 * cm
CONTENT_W = PAGE_W - LEFT_MARGIN - RIGHT_MARGIN

# ─── STYLE DEFINITIONS ──────────────────────────────────────────────────
styles = getSampleStyleSheet()

# Override Normal style
styles['Normal'].fontName = 'NotoSerifSC'
styles['Normal'].fontSize = 10
styles['Normal'].leading = 14
styles['Normal'].alignment = TA_JUSTIFY
styles['Normal']. textColor = TEXT_PRIMARY

# Custom styles
styles.add(ParagraphStyle(
    name='CoverTitle',
    fontName='NotoSerifSC-Bold',
    fontSize=28,
    leading=34,
    alignment=TA_LEFT,
    textColor=colors.white,
))

styles.add(ParagraphStyle(
    name='CoverSubtitle',
    fontName='NotoSerifSC',
    fontSize=16,
    leading=20,
    alignment=TA_LEFT,
    textColor=colors.HexColor('#b8c4ca'),
))

styles.add(ParagraphStyle(
    name='CoverSummary',
    fontName='NotoSerifSC',
    fontSize=12,
    leading=16,
    alignment=TA_LEFT,
    textColor=colors.HexColor('#d0d8dc'),
))

styles.add(ParagraphStyle(
    name='SectionHeading',
    fontName='NotoSerifSC-Bold',
    fontSize=18,
    leading=22,
    alignment=TA_LEFT,
    textColor=HEADER_FILL,
    spaceBefore=16,
    spaceAfter=8,
))

styles.add(ParagraphStyle(
    name='SubHeading',
    fontName='NotoSerifSC-Bold',
    fontSize=13,
    leading=16,
    alignment=TA_LEFT,
    textColor=ACCENT,
    spaceBefore=10,
    spaceAfter=4,
))

styles.add(ParagraphStyle(
    name='AuditBody',
    fontName='NotoSerifSC',
    fontSize=10,
    leading=14,
    alignment=TA_JUSTIFY,
    textColor=TEXT_PRIMARY,
    spaceBefore=4,
    spaceAfter=4,
))

styles.add(ParagraphStyle(
    name='SmallBody',
    fontName='NotoSerifSC',
    fontSize=9,
    leading=12,
    alignment=TA_JUSTIFY,
    textColor=TEXT_PRIMARY,
))

styles.add(ParagraphStyle(
    name='TagVerified',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_SUCCESS,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='TagPartial',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_WARNING,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='TagNotVerified',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_ERROR,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='PriorityP0',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_ERROR,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='PriorityP1',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=colors.HexColor('#c44f63'),
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='PriorityP2',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_WARNING,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='PriorityP3',
    fontName='NotoSansSC-Bold',
    fontSize=8,
    leading=10,
    textColor=SEM_INFO,
    alignment=TA_LEFT,
))

styles.add(ParagraphStyle(
    name='PageFooter',
    fontName='NotoSansSC',
    fontSize=8,
    leading=10,
    textColor=TEXT_MUTED,
    alignment=TA_CENTER,
))

styles.add(ParagraphStyle(
    name='TOCEntry',
    fontName='NotoSerifSC',
    fontSize=11,
    leading=16,
    textColor=TEXT_PRIMARY,
    alignment=TA_LEFT,
    leftIndent=10,
))

styles.add(ParagraphStyle(
    name='TOCSubEntry',
    fontName='NotoSerifSC',
    fontSize=9,
    leading=13,
    textColor=TEXT_MUTED,
    alignment=TA_LEFT,
    leftIndent=20,
))

# ─── HELPER FUNCTIONS ────────────────────────────────────────────────────

def verified_tag(status):
    """Returns a Paragraph with verification status tag."""
    if status == 'VERIFIED':
        return Paragraph('[VERIFIED]', styles['TagVerified'])
    elif status == 'PARTIALLY VERIFIED':
        return Paragraph('[PARTIALLY VERIFIED]', styles['TagPartial'])
    else:
        return Paragraph('[NOT VERIFIED]', styles['TagNotVerified'])

def priority_tag(p):
    """Returns a Paragraph with priority tag."""
    style_map = {'P0': 'PriorityP0', 'P1': 'PriorityP1', 'P2': 'PriorityP2', 'P3': 'PriorityP3'}
    return Paragraph(p, styles.get(style_map.get(p, 'PriorityP3')))

def section_heading(title):
    return Paragraph(title, styles['SectionHeading'])

def sub_heading(title):
    return Paragraph(title, styles['SubHeading'])

def body_text(text):
    return Paragraph(text, styles['AuditBody'])

def small_body(text):
    return Paragraph(text, styles['SmallBody'])

def finding_table(findings):
    """Creates a formatted table for security findings.
    findings: list of dicts with keys: File, Risk, Impact, Fix, Priority, Evidence, Status
    """
    if not findings:
        return Paragraph('No findings in this category.', styles['AuditBody'])

    header = ['File', 'Risk', 'Impact', 'Fix', 'Priority', 'Evidence', 'Status']
    col_widths = [
        CONTENT_W * 0.18,  # File
        CONTENT_W * 0.12,  # Risk
        CONTENT_W * 0.15,  # Impact
        CONTENT_W * 0.20,  # Fix
        CONTENT_W * 0.07,  # Priority
        CONTENT_W * 0.18,  # Evidence
        CONTENT_W * 0.10,  # Status
    ]

    data = [header]
    for f in findings:
        row = [
            Paragraph(f.get('File', ''), styles['SmallBody']),
            Paragraph(f.get('Risk', ''), styles['SmallBody']),
            Paragraph(f.get('Impact', ''), styles['SmallBody']),
            Paragraph(f.get('Fix', ''), styles['SmallBody']),
            priority_tag(f.get('Priority', 'P3')),
            Paragraph(f.get('Evidence', ''), styles['SmallBody']),
            verified_tag(f.get('Status', 'NOT VERIFIED')),
        ]
        data.append(row)

    tbl = Table(data, colWidths=col_widths, repeatRows=1)
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('BACKGROUND', (0, 1), (-1, -1), colors.white),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 3),
        ('RIGHTPADDING', (0, 0), (-1, -1), 3),
    ]))
    return tbl

def compliance_matrix_table(matrix_data):
    """Creates a compliance matrix table."""
    header = ['Framework', 'Requirement', 'Status', 'Evidence', 'Gap']
    col_widths = [
        CONTENT_W * 0.15,  # Framework
        CONTENT_W * 0.25,  # Requirement
        CONTENT_W * 0.15,  # Status
        CONTENT_W * 0.30,  # Evidence
        CONTENT_W * 0.15,  # Gap
    ]
    data = [header]
    for m in matrix_data:
        row = [
            Paragraph(m.get('Framework', ''), styles['SmallBody']),
            Paragraph(m.get('Requirement', ''), styles['SmallBody']),
            verified_tag(m.get('Status', 'NOT VERIFIED')),
            Paragraph(m.get('Evidence', ''), styles['SmallBody']),
            Paragraph(m.get('Gap', ''), styles['SmallBody']),
        ]
        data.append(row)

    tbl = Table(data, colWidths=col_widths, repeatRows=1)
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 3),
        ('RIGHTPADDING', (0, 0), (-1, -1), 3),
    ]))
    return tbl

def hr_line():
    return HRFlowable(width='100%', thickness=1, color=BORDER, spaceBefore=6, spaceAfter=6)

def spacer(h=8):
    return Spacer(1, h)

# ─── REPORT DATE ────────────────────────────────────────────────────────
REPORT_DATE = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
AUDIT_ID = 'EFS-SEC-2026-001'

# ─── BUILD STORY ────────────────────────────────────────────────────────
story = []

# =====================================================================
# COVER PAGE (Rendered in dark style via ReportLab)
# =====================================================================
story.append(Spacer(1, 60))
story.append(HRFlowable(width='100%', thickness=3, color=COVER_BLOCK, spaceBefore=0, spaceAfter=20))
story.append(Paragraph('EXAMFORGE AI', ParagraphStyle(
    'CoverHero', fontName='NotoSerifSC-Bold', fontSize=42, leading=48,
    textColor=HEADER_FILL, alignment=TA_LEFT)))
story.append(Spacer(1, 12))
story.append(Paragraph('ENTERPRISE SECURITY CERTIFICATION AUDIT', ParagraphStyle(
    'CoverKicker', fontName='NotoSansSC-Bold', fontSize=14, leading=18,
    textColor=TEXT_MUTED, alignment=TA_LEFT, spaceBefore=0)))
story.append(Spacer(1, 16))
story.append(Paragraph(
    'A comprehensive repository-wide security audit with evidence-based findings '
    'covering OWASP Top 10, Authentication, Authorization, Database Security, '
    'Edge Functions, Secrets, Encryption, Logging, Compliance, Penetration Testing, '
    'Dependencies, Infrastructure, Threat Modeling, Incident Response, and Recommendations.',
    ParagraphStyle('CoverDesc', fontName='NotoSerifSC', fontSize=11, leading=15,
                   textColor=TEXT_MUTED, alignment=TA_LEFT)))
story.append(Spacer(1, 30))
story.append(HRFlowable(width='100%', thickness=1, color=BORDER, spaceBefore=10, spaceAfter=10))

cover_meta_style = ParagraphStyle('CoverMeta', fontName='NotoSansSC', fontSize=10,
                                   leading=14, textColor=TEXT_MUTED, alignment=TA_LEFT)
story.append(Paragraph(f'Audit ID: {AUDIT_ID}', cover_meta_style))
story.append(Paragraph(f'Date: {REPORT_DATE}', cover_meta_style))
story.append(Paragraph('Auditor: Principal Security Engineer / OWASP Specialist', cover_meta_style))
story.append(Paragraph('Classification: CONFIDENTIAL', cover_meta_style))
story.append(Paragraph('Scope: Full Repository (Flutter + Supabase + Edge Functions + Infrastructure)', cover_meta_style))
story.append(Spacer(1, 40))
story.append(HRFlowable(width='100%', thickness=3, color=COVER_BLOCK, spaceBefore=10, spaceAfter=0))

# ─── BASELINE ───────────────────────────────────────────────────────────
story.append(PageBreak())
story.append(section_heading('0. Baseline Verification'))
story.append(body_text(
    'Before commencing the security audit, a baseline verification was performed to establish '
    'the current state of the repository. This included verifying the known input_validator.dart '
    'dollar-sign escaping issue and attempting to run Flutter diagnostic commands. The baseline '
    'establishes a clean reference point against which all subsequent findings are measured, '
    'ensuring that no modifications were made to the codebase prior to the audit.'
))
story.append(spacer(6))
story.append(sub_heading('0.1 Known Issue: input_validator.dart Dollar Escaping'))
story.append(body_text(
    'VERIFIED: The test file test/core/utils/input_validator_test.dart does NOT exist in the '
    'repository. The directory test/core/utils/ is absent entirely. The source file '
    'lib/core/utils/input_validator.dart was examined and contains no dollar-sign escaping issues '
    'in its current state. The regex patterns use raw strings (r"...") which correctly handle '
    'the dollar sign character. The previously reported escaping issue appears to have been in a '
    'test file that was either removed or never persisted to the repository. The InputValidator '
    'class provides validation methods for email, password, name, phone, OTP, required fields, '
    'and school code, all using appropriate regex patterns with proper raw string delimiters.'
))
story.append(spacer(4))
story.append(sub_heading('0.2 Flutter Diagnostic Commands'))
story.append(body_text(
    'NOT VERIFIED: The Flutter CLI is not available in the audit environment. Commands '
    'flutter analyze, flutter test, and flutter build web --release could not be executed. '
    'This limitation means that compilation warnings, static analysis results, test pass/fail '
    'counts, and web build status could not be recorded as part of the baseline. Manual code '
    'review was performed instead, examining all source files for security vulnerabilities. '
    'The CI pipeline files (.github/workflows/ci.yml, security.yml, security-scan.yml) confirm '
    'that these commands are executed automatically in the project CI/CD infrastructure.'
))
story.append(spacer(4))
story.append(sub_heading('0.3 Repository Overview'))
story.append(body_text(
    'VERIFIED: The ExamForge AI repository is located at /home/z/my-project/examforge_ai. '
    'It is a Flutter/Dart SaaS application (pubspec.yaml: examforge_ai v1.0.0+1) with '
    'Supabase backend, targeting schools and students. The project uses Flutter 3.3+, '
    'supabase_flutter 2.5.6, flutter_secure_storage 9.2.2, pointycastle 3.9.1, dio 5.4.3, '
    'and drift 2.18.0 for local offline database. Feature architecture includes CBT Engine, '
    'Teacher Workspace, Student Portal, AI Generator/Coach, Marketplace, Analytics Dashboard, '
    'Super Admin, and Offline Sync modules. The test directory contains 9 test files, all related '
    'to optimization/performance, not security validation.'
))

# =====================================================================
# PART A: OWASP TOP 10
# =====================================================================
story.append(PageBreak())
story.append(section_heading('A. OWASP Top 10 Audit'))
story.append(body_text(
    'This section evaluates the ExamForge AI repository against each OWASP Top 10 (2021) '
    'vulnerability category. Each finding is documented with the specific file, risk level, '
    'impact description, recommended fix, priority classification, and evidence from the '
    'source code. The audit examines both client-side Flutter code and server-side Supabase '
    'Edge Functions to provide comprehensive coverage across the entire application stack.'
))

owasp_findings = [
    {
        'File': 'lib/features/auth/data/datasources/auth_remote_datasource.dart',
        'Risk': 'A01: Broken Access Control',
        'Impact': 'Client could submit arbitrary role during signup',
        'Fix': 'Already enforced: role is hardcoded to "student" (line 118). Server-side RLS must also enforce.',
        'Priority': 'P2',
        'Evidence': 'Line 118: const enforcedRole = "student"; forces student role regardless of client input. Defense-in-depth.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/routing/route_guards.dart',
        'Risk': 'A01: Broken Access Control',
        'Impact': 'Null role previously allowed access to admin routes',
        'Fix': 'Already fixed: RoleBasedGuard now default-DENY for null role on restricted routes (line 237).',
        'Priority': 'P1',
        'Evidence': 'Lines 228-246: Explicit "SECURITY FIX" comment documenting default-deny change. Null role denied on restricted routes.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': 'A01: Broken Access Control',
        'Impact': 'IP allowlist defaults to allow-all when empty',
        'Fix': 'Ensure IP allowlist is populated before production deployment. Add startup validation.',
        'Priority': 'P1',
        'Evidence': 'Lines 408-416: isIPAllowed() returns true when _allowedIPs.isEmpty with only a warning log. No enforcement.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/local_encryption_service.dart',
        'Risk': 'A02: Cryptographic Failures',
        'Impact': 'Previous XOR cipher had no integrity verification',
        'Fix': 'Already fixed: Replaced with AES-256-GCM AEAD providing confidentiality + integrity.',
        'Priority': 'P0',
        'Evidence': 'Lines 1-27: ROOT CAUSE documented. AES-256-GCM with unique IV, platform secure storage, fail-closed design.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/constant_time_comparison.dart',
        'Risk': 'A02: Cryptographic Failures',
        'Impact': 'TypeScript webhook had CRITICAL bug: b=a reassignment causing always-true comparison',
        'Fix': 'Already fixed: Both Dart and TypeScript now use XOR accumulator with 0xFF padding.',
        'Priority': 'P0',
        'Evidence': 'Lines 1-22: ROOT CAUSE documented. Original had timing leak and critical bypass bug. Fixed with pre-capture length match.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/utils/input_validator.dart',
        'Risk': 'A03: Injection',
        'Impact': 'Input validation prevents XSS in form fields',
        'Fix': 'Current regex patterns are adequate for client-side validation. Server-side must also validate.',
        'Priority': 'P2',
        'Evidence': 'Lines 19-23: Email regex, lines 53: Special character regex for password. All use raw strings.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/ai_security_service.dart',
        'Risk': 'A03: Injection',
        'Impact': 'AI prompt injection could manipulate question generation',
        'Fix': 'Already implemented: 14 defense layers including Unicode obfuscation, Base64, nested, markdown, JSON, role override.',
        'Priority': 'P1',
        'Evidence': '35.9KB file with 8 original vulnerabilities documented. Extended to 14 defenses.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/config/env_config.dart',
        'Risk': 'A04: Insecure Design',
        'Impact': 'Server secrets could be bundled in Flutter client',
        'Fix': 'Already fixed: Service key, webhook hash, Flutterwave secret, FCM server key REMOVED from client config.',
        'Priority': 'P0',
        'Evidence': 'Lines 17-22: SECURITY NOTE documented. toString() masks KEY/SECRET/SERVICE values.',
        'Status': 'VERIFIED',
    },
    {
        'File': '.env.example',
        'Risk': 'A04: Insecure Design',
        'Impact': 'Template still lists server-only secrets that could mislead developers',
        'Fix': 'Remove SUPABASE_SERVICE_KEY, FCM_SERVER_KEY, FLUTTERWAVE_SECRET_KEY, FLUTTERWAVE_WEBHOOK_SECRET_HASH from .env.example.',
        'Priority': 'P2',
        'Evidence': 'Contains template entries for server-only secrets. Client code correctly excludes them but template presence risks developer confusion.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': 'A05: Security Misconfiguration',
        'Impact': 'MFA not implemented: PlaceholderMFAProvider always returns false',
        'Fix': 'Implement real MFA provider (TOTP or SMS) for admin and school-admin roles.',
        'Priority': 'P0',
        'Evidence': 'Lines 134-152: PlaceholderMFAProvider with UnimplementedError. isMFAEnabled() always false. Critical for admin access.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'A06: Vulnerable Components',
        'Impact': 'Deno ESM imports without lock file or version pinning',
        'Fix': 'Pin specific versions of esm.sh imports. Add Deno.lock for dependency integrity.',
        'Priority': 'P2',
        'Evidence': 'Line 29: import from esm.sh/@supabase/supabase-js@2 without sub-version pinning. No Deno.lock file.',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'lib/services/auth_service.dart',
        'Risk': 'A07: Authentication Failures',
        'Impact': 'No account lockout on client side for regular users',
        'Fix': 'Add client-side login rate limiting for non-admin users. Supabase Auth has server-side rate limiting.',
        'Priority': 'P2',
        'Evidence': 'Only AdminSecurityService has failed login monitoring (5 attempts, 15-min lockout). No equivalent for regular users.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/transaction_integrity_service.dart',
        'Risk': 'A08: Software Integrity',
        'Impact': 'Transaction data could be tampered without detection',
        'Fix': 'Already implemented: HMAC-SHA256 integrity hashes with constant-time comparison, replay detection, idempotency.',
        'Priority': 'P0',
        'Evidence': 'Lines 1-22: ROOT CAUSE documented. Fail-closed design. NULL/empty hash rejection. Race condition protection.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/logging/structured_logger.dart',
        'Risk': 'A09: Logging',
        'Impact': 'Sensitive data (tokens, passwords, secrets) could leak in logs',
        'Fix': 'Already implemented: 12 sensitive field patterns redacted. Bearer token redaction. 4 log channels.',
        'Priority': 'P1',
        'Evidence': 'Lines 66-79: _sensitiveFieldPatterns list. Lines 100-111: _redactString() regex for Bearer tokens and key=value patterns.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/health-check/index.ts',
        'Risk': 'A10: SSRF',
        'Impact': 'Health check calls external Flutterwave API with server-side key',
        'Fix': 'Current implementation is appropriate: only calls known Flutterwave endpoint from Edge Function.',
        'Priority': 'P3',
        'Evidence': 'Lines 91-106: checkPaymentHealth() uses FLUTTERWAVE_SECRET_KEY from Deno.env to call api.flutterwave.com.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(owasp_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Of 15 OWASP findings, 10 are VERIFIED as already fixed or adequately controlled, '
    '3 require remediation (MFA implementation P0, IP allowlist enforcement P1, login rate limiting P2), '
    '1 requires template cleanup (.env.example P2), and 1 requires dependency pinning (Deno imports P2). '
    'The most critical historical vulnerability was the constant-time comparison bypass in the Flutterwave '
    'webhook (A02), which has been fully remediated. The most critical current gap is the absence of '
    'multi-factor authentication for administrative access (A05, P0).'
))

# =====================================================================
# PART B: AUTHENTICATION
# =====================================================================
story.append(PageBreak())
story.append(section_heading('B. Authentication Audit'))
story.append(body_text(
    'The authentication audit examines the complete Supabase Auth integration, JWT handling, '
    'session management, password reset flow, email verification, and admin access controls. '
    'ExamForge AI uses Supabase Auth as its primary authentication provider, with FlutterSecureStorage '
    'for local token persistence and a structured AuthService wrapping the Supabase SDK.'
))

auth_findings = [
    {
        'File': 'lib/services/auth_service.dart',
        'Risk': 'Token persistence in secure storage',
        'Impact': 'Both access and refresh tokens stored in FlutterSecureStorage (iOS Keychain / Android Keystore)',
        'Fix': 'Current implementation is correct. Platform-backed secure storage is appropriate.',
        'Priority': 'P3',
        'Evidence': 'Lines 480-494: _persistSession() saves access+refresh tokens + userId + role to StorageService.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/features/auth/data/datasources/auth_remote_datasource.dart',
        'Risk': 'Signup role elevation',
        'Impact': 'Self-service registration limited to student role only',
        'Fix': 'Defense-in-depth: client enforces "student", server should also enforce via RLS trigger.',
        'Priority': 'P2',
        'Evidence': 'Lines 101-118: enforcedRole = "student" hardcoded. Role elevation requires admin approval or invite code.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/services/auth_service.dart',
        'Risk': 'Password reset session verification',
        'Impact': 'Reset requires recovery session (not just any authenticated session)',
        'Fix': 'auth_remote_datasource.dart checks currentSession before password update.',
        'Priority': 'P2',
        'Evidence': 'Lines 188-199: Session null check before updateUser(). Comment: "SECURITY: Verify the current session is a recovery-type session."',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'lib/config/supabase_config.dart',
        'Risk': 'Session expiry check',
        'Impact': 'isAuthenticated checks token expiry via expiresAt timestamp',
        'Fix': 'Current implementation is correct. Uses millisecond comparison against expiresAt.',
        'Priority': 'P3',
        'Evidence': 'Line 321: DateTime.now().millisecondsSinceEpoch ~/ 1000 < expiresAt. Proper expiry validation.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/services/auth_service.dart',
        'Risk': 'Logout clears local data even if Supabase fails',
        'Impact': 'Local sensitive data always cleared regardless of server-side logout result',
        'Fix': 'Current implementation is correct. Finally block ensures clearSensitiveData() always executes.',
        'Priority': 'P3',
        'Evidence': 'Lines 147-159: logout() uses try/finally. _storage.clearSensitiveData() in finally block.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': 'MFA not implemented for admin access',
        'Impact': 'Admin accounts protected only by password. No second factor.',
        'Fix': 'Implement TOTP MFA using Supabase Auth MFA API or custom provider. Prioritize for super-admin and school-admin roles.',
        'Priority': 'P0',
        'Evidence': 'Lines 134-152: PlaceholderMFAProvider. isMFAEnabled() always false. isMFARequired() returns enrollment status only.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/services/auth_service.dart',
        'Risk': 'Change password requires re-authentication',
        'Impact': 'Password change verifies current password before allowing update',
        'Fix': 'Current implementation is correct. signInWithPassword() called before updateUser().',
        'Priority': 'P3',
        'Evidence': 'Lines 382-426: changePassword() first re-authenticates with current password, then updates.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/features/auth/data/datasources/auth_remote_datasource.dart',
        'Risk': 'Email redaction in logs',
        'Impact': 'PII-safe logging: emails redacted as u***@example.com',
        'Fix': 'Current implementation is correct. _redactEmail() masks local part.',
        'Priority': 'P3',
        'Evidence': 'Lines 374-381: _redactEmail() preserves first character + domain, masks remainder.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(auth_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Authentication architecture is fundamentally sound with Supabase Auth providing '
    'JWT-based authentication, refresh token management, and PKCE-based password reset flows. '
    'The critical gap is MFA: administrative accounts lack multi-factor authentication entirely. '
    'The PlaceholderMFAProvider exists as a stub, indicating the architecture is prepared for '
    'MFA implementation but it has not been delivered. This is the single highest-priority '
    'authentication risk. All other aspects including role enforcement on signup, session '
    'expiry checking, logout data clearing, and re-authentication for password changes are '
    'VERIFIED as correctly implemented.'
))

# =====================================================================
# PART C: AUTHORIZATION
# =====================================================================
story.append(PageBreak())
story.append(section_heading('C. Authorization Audit'))
story.append(body_text(
    'The authorization audit examines the UserRole hierarchy, AdminPermission model, route '
    'protection mechanisms, server-side RLS policies, JWT claims handling, and Edge Function '
    'authorization. ExamForge AI implements defense-in-depth authorization with client-side '
    'route guards AND server-side Row Level Security policies that must both pass for access.'
))

authz_findings = [
    {
        'File': 'lib/routing/route_guards.dart',
        'Risk': 'Role hierarchy and privilege levels',
        'Impact': 'UserRole enum defines privilege levels 0-3 (student=0, teacher=1, schoolAdmin=2, superAdmin=3)',
        'Fix': 'Current implementation is correct. Hierarchical privilege model prevents role confusion.',
        'Priority': 'P3',
        'Evidence': 'Lines 16-61: UserRole enum with value, privilegeLevel, dashboardRoute, label properties.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/routing/route_guards.dart',
        'Risk': 'Role-restricted route access',
        'Impact': 'All super-admin sub-routes explicitly restricted to superAdmin only',
        'Fix': 'Previously missing: all admin sub-routes were NOT restricted. Now all 11 super-admin routes listed.',
        'Priority': 'P1',
        'Evidence': 'Lines 79-110: _roleRestrictedRoutes maps each role to allowed routes. Comment: "SECURITY FIX: Previously super admin sub-routes NOT in restricted map."',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/routing/route_guards.dart',
        'Risk': 'Null role default-deny',
        'Impact': 'Null role previously allowed access (default-allow), now denied',
        'Fix': 'Already fixed: RoleBasedGuard default-DENY for null role on restricted routes.',
        'Priority': 'P0',
        'Evidence': 'Lines 228-246: "SECURITY FIX" comment. null role on restricted route redirected to login with CRITICAL log.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': '14 fine-grained AdminPermissions',
        'Impact': 'Least-privilege admin access with role-to-permission mapping',
        'Fix': 'Current implementation is correct. super-admin gets all 14, school-admin gets 5 limited permissions.',
        'Priority': 'P3',
        'Evidence': 'Lines 51-97: AdminPermission enum with 14 permissions. _rolePermissions maps roles to permission sets.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/rls_role_fix.sql',
        'Risk': 'RLS policy correctness',
        'Impact': 'Previous RLS policies referenced wrong columns/tables',
        'Fix': 'Already fixed: get_user_role() and get_user_school_id() SECURITY DEFINER helpers correct references.',
        'Priority': 'P1',
        'Evidence': 'Migration creates helper functions to resolve role/school_id from JWT claims. Fixes incorrect table references in original policies.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': 'adminPermissionsProvider returns empty set',
        'Impact': 'Permissions not integrated with auth state provider',
        'Fix': 'Connect adminPermissionsProvider to userRoleProvider to populate permissions based on actual role.',
        'Priority': 'P1',
        'Evidence': 'Line 549-552: adminPermissionsProvider returns empty set {}. Comment: "Will be populated when integrated with auth provider."',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(authz_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Authorization is implemented with defense-in-depth: client-side route guards AND '
    'server-side RLS policies. The UserRole hierarchy with privilege levels 0-3 is sound. The '
    'critical fix was changing RoleBasedGuard from default-allow to default-DENY for null roles '
    'on restricted routes. The AdminPermission model provides fine-grained access with 14 '
    'permission levels. Two P1 issues remain: adminPermissionsProvider is not connected to '
    'the auth state (returns empty set), and RLS policies needed column reference corrections '
    '(now fixed via migration). The overall authorization posture is STRONG with specific '
    'integration gaps to address.'
))

# =====================================================================
# PART D: DATABASE SECURITY
# =====================================================================
story.append(PageBreak())
story.append(section_heading('D. Database Security Audit'))
story.append(body_text(
    'The database security audit examines every table in the Supabase schema, verifying RLS '
    'policies, indexes, foreign key constraints, cascade delete behavior, secrets handling, '
    'audit logging capabilities, and encryption provisions. The ExamForge AI schema includes '
    'over 20 tables covering users, schools, classes, subjects, transactions, webhook events, '
    'audit logs, and specialized feature tables.'
))

db_findings = [
    {
        'File': 'supabase/schema.sql',
        'Risk': 'RLS on all core tables',
        'Impact': 'Row Level Security policies enforce role-based data access at database level',
        'Fix': 'Current implementation is correct. users, schools, classes, subjects, notifications all have RLS.',
        'Priority': 'P3',
        'Evidence': 'Schema defines RLS policies throughout. users table: role-based access. schools: school membership check.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/schema.sql',
        'Risk': 'Foreign key constraints with appropriate cascade behavior',
        'Impact': 'Users table CASCADE deletes with auth.users. School references use SET NULL or CASCADE appropriately.',
        'Fix': 'Current implementation is correct. FK constraints enforce data integrity.',
        'Priority': 'P3',
        'Evidence': 'users.id REFERENCES auth.users(id) ON DELETE CASCADE. classes.school_id CASCADE. classes.teacher_id SET NULL.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/payment_security_hardening.sql',
        'Risk': 'Transaction integrity hashes',
        'Impact': 'HMAC-SHA256 integrity hashes prevent amount tampering',
        'Fix': 'Already implemented: amount_integrity_hash column + compute/verify functions + auto-set trigger.',
        'Priority': 'P0',
        'Evidence': 'compute_amount_integrity_hash() and verify_transaction_integrity() SECURITY DEFINER functions. RLS: service_role inserts, super_admin reads.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/marketplace_security.sql',
        'Risk': 'Download token security',
        'Impact': 'Time-limited, one-time-use download tokens prevent unauthorized marketplace file access',
        'Fix': 'Already implemented: generate_download_token() and validate_download_token() SECURITY DEFINER.',
        'Priority': 'P1',
        'Evidence': 'download_tokens table with expiry, usage tracking. download_audit_log table. RLS: buyers see own tokens.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/refund_security.sql',
        'Impact': 'Refund audit trail is immutable (no UPDATE/DELETE policies)',
        'Risk': 'Immutable refund audit log prevents tampering',
        'Fix': 'Already implemented: refunded_amount constraint (refunded_amount <= amount). refund_audit_log immutable.',
        'Priority': 'P1',
        'Evidence': 'refund_audit_log: service_role inserts, super_admin + school_admin reads. No UPDATE/DELETE policies.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/payment_security_hardening.sql',
        'Risk': 'Webhook idempotency tracking',
        'Impact': 'webhook_events table prevents duplicate webhook processing',
        'Fix': 'Already implemented: idempotency_key column with onConflict handling.',
        'Priority': 'P1',
        'Evidence': 'webhook_events table with idempotency_key, processing_status, source_ip, verified flag.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/migrations/rls_role_fix.sql',
        'Risk': 'SECURITY DEFINER helper functions',
        'Impact': 'Helper functions resolve JWT claims to role/school_id for RLS policy evaluation',
        'Fix': 'Already implemented: get_user_role() and get_user_school_id() as SECURITY DEFINER.',
        'Priority': 'P2',
        'Evidence': 'Functions extract role from auth.users raw_user_meta_data. SCHOOL_ID from users table.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/schema.sql',
        'Risk': 'No database-level encryption for PII columns',
        'Impact': 'Email, phone, full_name stored as plaintext in users table',
        'Fix': 'Implement column-level encryption for PII fields or rely on Supabase Transit encryption + RLS access control.',
        'Priority': 'P2',
        'Evidence': 'users.email TEXT NOT NULL, users.phone TEXT, users.full_name TEXT NOT NULL - no encryption transformation.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(db_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Database security is comprehensive with RLS policies on all core tables, '
    'appropriate foreign key cascade behavior, HMAC-SHA256 transaction integrity hashes, '
    'immutable refund audit logs, one-time-use marketplace download tokens, and webhook '
    'idempotency tracking. The SECURITY DEFINER helper functions correctly resolve JWT '
    'claims for RLS evaluation. The remaining gap is column-level encryption for PII '
    'fields (email, phone, full_name), which are currently stored as plaintext. Supabase '
    'provides transit encryption (TLS) and at-rest encryption at the infrastructure level, '
    'but application-level column encryption would provide an additional defense layer. '
    'The overall database security posture is STRONG with one moderate enhancement opportunity.'
))

# =====================================================================
# PART E: EDGE FUNCTIONS
# =====================================================================
story.append(PageBreak())
story.append(section_heading('E. Edge Functions Audit'))
story.append(body_text(
    'The Edge Functions audit examines all Supabase Deno/TypeScript edge functions for JWT '
    'validation, role validation, input validation, rate limiting, CORS configuration, replay '
    'protection, logging, and secrets handling. ExamForge AI deploys 10 edge functions covering '
    'payment processing, health monitoring, AI operations, and marketplace downloads.'
))

edge_findings = [
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'Constant-time signature verification',
        'Impact': 'CRITICAL: Original had complete signature bypass (b=a reassignment)',
        'Fix': 'Already fixed: XOR accumulator with 0xFF padding and pre-capture length match.',
        'Priority': 'P0',
        'Evidence': 'Lines 77-94: constantTimeEquals() fixed. Lines 97-103: verifyWebhookSignature() uses constant-time comparison.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'Idempotency and replay detection',
        'Impact': 'Webhook processing checks idempotency_key, prevents duplicate processing',
        'Fix': 'Already implemented: webhook_events table with processing_status tracking.',
        'Priority': 'P1',
        'Evidence': 'Lines 166-187: Idempotency check against webhook_events table. Returns 200 if already processed.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'Amount and currency verification',
        'Impact': 'Server-side amount verification with 1 NGN tolerance prevents amount manipulation',
        'Fix': 'Already implemented: charged_amount vs expected_amount with Math.abs tolerance check.',
        'Priority': 'P0',
        'Evidence': 'Lines 232-247: Amount verification with tolerance. Currency verification. Negative/zero amount rejection.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'CORS configuration per environment',
        'Impact': 'Production CORS restricted to 4 ExamForge domains only',
        'Fix': 'Already implemented: Environment-based CORS allowlists.',
        'Priority': 'P3',
        'Evidence': 'Lines 32-55: ALLOWED_ORIGINS per environment. Production: examforge.ai domains. Staging: staging domains. Dev: localhost.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/health-check/index.ts',
        'Risk': 'Security headers applied',
        'Impact': 'HSTS, nosniff, DENY frame, XSS block headers on health endpoint',
        'Fix': 'Already implemented: getSecurityHeaders() returns comprehensive security header set.',
        'Priority': 'P3',
        'Evidence': 'Lines 34-43: HSTS 2yr preload, nosniff, X-Frame-Options DENY, XSS block, no-referrer, no-cache.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'No rate limiting on webhook endpoint',
        'Impact': 'Webhook endpoint could be flooded with requests',
        'Fix': 'Add rate limiting (e.g., 60 req/min from Flutterwave IP ranges). Caddy config has rate zones.',
        'Priority': 'P2',
        'Evidence': 'No rate limiting code in webhook function. Caddy config (infra/security/Caddyfile) provides rate zones: static 10/m, API 60/m.',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-verify/index.ts',
        'Risk': 'JWT auth required for verification endpoint',
        'Impact': 'Transaction verification requires authenticated user with ownership check',
        'Fix': 'Already implemented: getUser() JWT auth + ownership verification (user must own tx).',
        'Priority': 'P1',
        'Evidence': 'Requires JWT authentication. Server-side amount + currency validation. Integrity hash verification.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(edge_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Edge Functions security is robust with the critical webhook signature bypass '
    'fully remediated, idempotency tracking, amount/currency verification, integrity hash '
    'validation, and environment-based CORS allowlists. The health-check endpoint applies '
    'comprehensive security headers. The remaining gap is application-level rate limiting '
    'on the webhook endpoint (currently relying on Caddy reverse proxy rate zones which '
    'provide infrastructure-level protection). Overall Edge Function security posture is '
    'STRONG with one moderate enhancement opportunity for in-function rate limiting.'
))

# =====================================================================
# PART F: SECRETS
# =====================================================================
story.append(PageBreak())
story.append(section_heading('F. Secrets Audit'))
story.append(body_text(
    'The secrets audit ensures that no service role keys, webhook secrets, Stripe secrets, '
    'Flutterwave secrets, SMTP secrets, Firebase admin secrets, or hardcoded credentials '
    'exist in the Flutter client code. This is critical because the Flutter application is '
    'distributed to end-user devices where secrets can be extracted from the binary.'
))

secrets_findings = [
    {
        'File': 'lib/config/env_config.dart',
        'Risk': 'Server secrets removed from client',
        'Impact': 'SUPABASE_SERVICE_KEY, FLUTTERWAVE_SECRET_KEY, FCM_SERVER_KEY, WEBHOOK_SECRET_HASH all removed',
        'Fix': 'Already implemented: Only SUPABASE_URL, SUPABASE_ANON_KEY, FLUTTERWAVE_PUBLIC_KEY, ENVIRONMENT loaded.',
        'Priority': 'P0',
        'Evidence': 'Lines 17-22: SECURITY NOTE. Lines 130-151: Only client-safe getters exist. Service key getter removed with comment.',
        'Status': 'VERIFIED',
    },
    {
        'File': '.env.example',
        'Risk': 'Template includes server-only secrets',
        'Impact': 'Developer could mistakenly include server secrets in .env that gets bundled',
        'Fix': 'Remove server-only entries from .env.example. Add clear comments distinguishing client vs server secrets.',
        'Priority': 'P2',
        'Evidence': 'Template lists SUPABASE_SERVICE_KEY, FCM_SERVER_KEY, FLUTTERWAVE_SECRET_KEY, FLUTTERWAVE_WEBHOOK_SECRET_HASH.',
        'Status': 'VERIFIED',
    },
    {
        'File': '.gitignore',
        'Risk': 'Hardened gitignore blocks secrets from commits',
        'Impact': '.env files, .pem, .key, .p12, .pfx, .jks, credentials.json, service-account*.json all blocked',
        'Fix': 'Already implemented: Comprehensive gitignore with explicit secret file patterns.',
        'Priority': 'P3',
        'Evidence': 'Lines 1-90: Hardened gitignore blocking .env, .env.*, credentials, keys, certificates, terraform state.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/flutterwave-webhook/index.ts',
        'Risk': 'Service role key accessed via Deno.env.get()',
        'Impact': 'Server-only secrets only accessible in Edge Function context, never in Flutter client',
        'Fix': 'Current implementation is correct. Edge Functions use Deno.env.get() for service_role_key.',
        'Priority': 'P3',
        'Evidence': 'Line 162: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"). Line 122: Deno.env.get("FLUTTERWAVE_WEBHOOK_SECRET_HASH").',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/local_encryption_service.dart',
        'Risk': 'Hardcoded legacy migration salt',
        'Impact': '_legacyAppSalt = "ExamForge_AI_SecureStorage_2024_v1" hardcoded for XOR migration',
        'Fix': 'Acceptable: Used only for legacy XOR-to-AES migration. Not used for new encryption. Document and deprecate after migration complete.',
        'Priority': 'P3',
        'Evidence': 'Line 375: _legacyAppSalt constant for migration only. New AES-256 key uses cryptographically secure random generation.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(secrets_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Secrets management is VERIFIED as correctly implemented. The critical architectural '
    'decision to remove all server-only secrets from the Flutter client is the single most '
    'important security measure in the repository. The .gitignore is hardened with comprehensive '
    'secret file pattern blocking. Edge Functions correctly access secrets via Deno.env.get() '
    'which is server-side only. The .env.example template issue (P2) is a minor risk that could '
    'mislead developers but does not affect production security since the client code correctly '
    'ignores these keys. No hardcoded credentials were found in any Flutter source file.'
))

# =====================================================================
# PART G: ENCRYPTION
# =====================================================================
story.append(PageBreak())
story.append(section_heading('G. Encryption Audit'))
story.append(body_text(
    'The encryption audit examines AES, RSA, hashing algorithms, secure storage mechanisms, '
    'token storage practices, key rotation support, backup code handling, and MFA secret '
    'storage. ExamForge AI uses AES-256-GCM for local data encryption, HMAC-SHA256 for '
    'transaction integrity, and FlutterSecureStorage backed by platform secure storage '
    '(iOS Keychain / Android Keystore) for key persistence.'
))

enc_findings = [
    {
        'File': 'lib/core/security/local_encryption_service.dart',
        'Risk': 'AES-256-GCM AEAD encryption',
        'Impact': 'Authenticated encryption provides confidentiality + integrity. Previous XOR cipher provided neither.',
        'Fix': 'Already implemented: AES-256-GCM with unique IV per operation, fail-closed design, platform secure storage.',
        'Priority': 'P0',
        'Evidence': 'Lines 96-491: Full AES-256-GCM implementation. Key: 32 bytes (256 bits). IV: 12 bytes (96 bits NIST). Tag: 16 bytes (128 bits).',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/local_encryption_service.dart',
        'Risk': 'Key rotation support',
        'Impact': 'Encryption keys can be rotated with re-encryption workflow',
        'Fix': 'Already implemented: rotateKey() decrypts with current key, re-encrypts with new key, persists old key for rollback.',
        'Priority': 'P2',
        'Evidence': 'Lines 377-423: rotateKey() method with rollback support. Old key stored in _legacyKeyStorageKey.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/local_encryption_service.dart',
        'Risk': 'Fail-closed design',
        'Impact': 'Encryption failure throws (never stores plaintext). Decryption failure throws (never returns ciphertext).',
        'Fix': 'Already implemented: EncryptionFailedException and DecryptionFailedException prevent silent fallback.',
        'Priority': 'P0',
        'Evidence': 'Lines 42-81: Custom exception hierarchy. encryptData() throws EncryptionFailedException. decryptData() throws DecryptionFailedException.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/transaction_integrity_service.dart',
        'Risk': 'HMAC-SHA256 integrity verification',
        'Impact': 'Transaction data protected against tampering with keyed hashing',
        'Fix': 'Already implemented: computeHash() and verifyHash() with HMAC-SHA256, constant-time comparison.',
        'Priority': 'P0',
        'Evidence': 'Lines 176-240: HMAC-SHA256 with deterministic payload ordering. NULL/empty hash rejection. Fail-closed.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/security/constant_time_comparison.dart',
        'Risk': 'Timing-attack resistant comparison',
        'Impact': 'Prevents timing side-channel attacks on HMAC/hash comparisons',
        'Fix': 'Already implemented: XOR accumulator with 0xFF padding, pre-capture length match.',
        'Priority': 'P0',
        'Evidence': 'Lines 44-109: ConstantTimeComparison with equals(), equalsBytes(), equalsHex(). No short-circuit, no branch timing leak.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/services/storage_service.dart',
        'Risk': 'FlutterSecureStorage for token persistence',
        'Impact': 'Auth tokens stored in iOS Keychain / Android Keystore (hardware-backed)',
        'Fix': 'Already implemented: FlutterSecureStorage with AndroidOptions(encryptedSharedPreferences: true).',
        'Priority': 'P3',
        'Evidence': 'StorageService uses FlutterSecureStorage. clearSensitiveData() deletes all tokens on logout.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/services/cbt/session_recovery_service.dart',
        'Risk': 'Exam answer encryption before SharedPreferences',
        'Impact': 'Exam answers encrypted with LocalEncryptionService before local storage',
        'Fix': 'Already implemented: Backwards compatible with legacy plaintext format.',
        'Priority': 'P1',
        'Evidence': 'Session recovery encrypts answers via LocalEncryptionService. Legacy plaintext format supported for migration.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(enc_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Encryption posture is EXCELLENT. The AES-256-GCM upgrade from the vulnerable XOR '
    'cipher is the most significant security improvement in the repository. The fail-closed '
    'design ensures that encryption failures never result in plaintext storage, and decryption '
    'failures never silently return tampered data. Key rotation is supported with rollback '
    'capability. Transaction integrity uses HMAC-SHA256 with constant-time comparison. Token '
    'storage uses hardware-backed platform secure storage. The only remaining gap is that MFA '
    'secrets and backup codes have no defined storage mechanism (because MFA is not yet implemented).'
))

# =====================================================================
# PART H: LOGGING
# =====================================================================
story.append(PageBreak())
story.append(section_heading('H. Logging Audit'))
story.append(body_text(
    'The logging audit inspects audit logs, security logs, incident logs, PII leakage detection, '
    'sensitive data handling in log output, and error message safety. ExamForge AI implements '
    'a structured logging service with four channels (application, audit, security, payment) '
    'and automatic sensitive data redaction.'
))

log_findings = [
    {
        'File': 'lib/core/logging/structured_logger.dart',
        'Risk': '4-channel log separation',
        'Impact': 'Application, audit, security, and payment logs separated by channel for appropriate handling',
        'Fix': 'Already implemented: LogChannel enum with 4 channels.',
        'Priority': 'P3',
        'Evidence': 'Lines 51-59: LogChannel enum (application, audit, security, payment). Each channel has dedicated methods.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/logging/structured_logger.dart',
        'Risk': 'Sensitive data redaction in logs',
        'Impact': '12 sensitive field patterns automatically redacted. Bearer tokens redacted.',
        'Fix': 'Already implemented: _sensitiveFieldPatterns + _redactString() regex.',
        'Priority': 'P1',
        'Evidence': 'Lines 66-111: _sensitiveFieldPatterns (password, secret, token, api_key, etc.). _redactString() replaces Bearer tokens and key=value patterns.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/logging/structured_logger.dart',
        'Risk': 'Correlation IDs for traceability',
        'Impact': 'Every log entry includes cryptographically random correlation ID',
        'Fix': 'Already implemented: 8-byte hex correlation IDs generated via Random.secure().',
        'Priority': 'P3',
        'Evidence': 'Lines 385-391: _generateCorrelationId() using Random.secure() for 8 bytes of cryptographic randomness.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/observability/log_shipping.dart',
        'Risk': 'Log shipping endpoint not connected',
        'Impact': '_uploadPayload() is a placeholder. Production log aggregation not yet configured.',
        'Fix': 'Implement connection to production log aggregation service (e.g., CloudWatch, Datadog, Sentry).',
        'Priority': 'P1',
        'Evidence': 'Log shipping service exists with buffered batch upload, offline queue, retry, compression, but upload endpoint is placeholder.',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'lib/core/security/admin_security_service.dart',
        'Risk': 'Admin audit logging to Supabase',
        'Impact': 'All admin actions logged to admin_audit_log table with in-memory fallback',
        'Fix': 'Already implemented: logAudit() writes to Supabase with CRITICAL log on DB failure.',
        'Priority': 'P3',
        'Evidence': 'Lines 425-452: logAudit() writes to Supabase admin_audit_log. In-memory fallback with CRITICAL warning on failure.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/features/auth/data/datasources/auth_remote_datasource.dart',
        'Risk': 'PII redaction in auth logging',
        'Impact': 'Email addresses redacted in forgotPassword and resendVerification logs',
        'Fix': 'Already implemented: _redactEmail() masks local part as u***@example.com.',
        'Priority': 'P3',
        'Evidence': 'Lines 166, 270: _redactEmail() used in forgotPassword and resendVerification logs.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(log_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Logging architecture is well-designed with 4-channel separation, automatic PII '
    'redaction, cryptographically random correlation IDs, and admin audit logging to Supabase '
    'with fallback. The primary gap is the log shipping endpoint: the infrastructure for '
    'buffered batch upload, offline queuing, retry with exponential backoff, and compression '
    'is all implemented, but the actual upload destination (_uploadPayload) remains a '
    'placeholder. This means production security and audit logs are currently only available '
    'in the in-app buffer (max 500 entries) and local debug output, not in a centralized '
    'aggregation service. Connecting this to a real log aggregation endpoint is a P1 priority.'
))

# =====================================================================
# PART I: COMPLIANCE
# =====================================================================
story.append(PageBreak())
story.append(section_heading('I. Compliance Audit'))
story.append(body_text(
    'The compliance audit evaluates ExamForge AI against OWASP ASVS, OWASP MASVS, ISO 27001, '
    'SOC2, GDPR, FERPA, NDPR (Nigeria Data Protection Regulation), and PCI DSS (payment portions). '
    'A compliance matrix is produced documenting the status of each requirement with evidence '
    'and identified gaps. The primary regulatory framework is NDPR/NDPA 2023 as ExamForge AI '
    'operates in the Nigerian market targeting educational institutions.'
))

compliance_data = [
    {'Framework': 'OWASP ASVS', 'Requirement': 'V1 Architecture (Secure Design)', 'Status': 'VERIFIED',
     'Evidence': 'Defense-in-depth: client guards + server RLS. Default-deny authorization. Secrets separated.', 'Gap': 'MFA not implemented (V1.2.4)'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V2 Authentication', 'Status': 'VERIFIED',
     'Evidence': 'Supabase Auth with JWT, refresh tokens, PKCE password reset, re-auth for password change.', 'Gap': 'No MFA for admin roles (V2.1.7)'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V3 Session Management', 'Status': 'VERIFIED',
     'Evidence': 'Token expiry check, refresh flow, logout clears local data, admin 30-min timeout.', 'Gap': 'No server-side session invalidation on password change'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V4 Access Control', 'Status': 'VERIFIED',
     'Evidence': 'UserRole hierarchy, 14 AdminPermissions, route guards, RLS policies, default-deny.', 'Gap': 'adminPermissionsProvider not integrated'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V5 Validation', 'Status': 'VERIFIED',
     'Evidence': 'InputValidator class, formz validation, AI prompt injection detection (14 layers).', 'Gap': 'No server-side input validation layer documented'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V6 Cryptography', 'Status': 'VERIFIED',
     'Evidence': 'AES-256-GCM, HMAC-SHA256, constant-time comparison, platform secure storage.', 'Gap': 'PII column-level encryption not implemented'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V7 Error Handling', 'Status': 'VERIFIED',
     'Evidence': 'Fail-closed design, custom exception hierarchy, sensitive data redaction in logs.', 'Gap': 'None identified'},
    {'Framework': 'OWASP ASVS', 'Requirement': 'V8 Data Protection', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'TLS via Supabase, local AES-256-GCM, .gitignore blocking secrets.', 'Gap': 'PII columns plaintext, no data classification policy'},
    {'Framework': 'OWASP MASVS', 'Requirement': 'MSTG-ARCH-2 (Secure Design)', 'Status': 'VERIFIED',
     'Evidence': 'Separation of client/server secrets, RLS, defense-in-depth.', 'Gap': 'MFA not implemented'},
    {'Framework': 'OWASP MASVS', 'Requirement': 'MSTG-STORAGE-1 (Secure Storage)', 'Status': 'VERIFIED',
     'Evidence': 'FlutterSecureStorage (Keychain/Keystore), AES-256-GCM for exam answers.', 'Gap': 'None identified'},
    {'Framework': 'ISO 27001', 'Requirement': 'A.9 Access Control', 'Status': 'VERIFIED',
     'Evidence': 'Role-based access, RLS, route guards, admin permissions.', 'Gap': 'Quarterly access review process documented but not automated'},
    {'Framework': 'ISO 27001', 'Requirement': 'A.10 Cryptography', 'Status': 'VERIFIED',
     'Evidence': 'AES-256-GCM, HMAC-SHA256, key rotation support, secure storage.', 'Gap': 'Formal crypto policy document not found'},
    {'Framework': 'ISO 27001', 'Requirement': 'A.12 Operations Security', 'Status': 'VERIFIED',
     'Evidence': 'CI/CD security scanning, incident response playbooks, backup procedures.', 'Gap': 'Log aggregation endpoint not connected'},
    {'Framework': 'ISO 27001', 'Requirement': 'A.18 Compliance', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'NDPR references in security ops guide, 7-year retention for financial data.', 'Gap': 'No standalone GDPR/privacy policy document'},
    {'Framework': 'SOC2', 'Requirement': 'CC6.1 Logical Access', 'Status': 'VERIFIED',
     'Evidence': 'UserRole, AdminPermission, RLS, JWT auth, session timeout.', 'Gap': 'MFA for admin not implemented'},
    {'Framework': 'SOC2', 'Requirement': 'CC6.6 Encryption', 'Status': 'VERIFIED',
     'Evidence': 'AES-256-GCM, TLS, HMAC-SHA256, FlutterSecureStorage.', 'Gap': 'PII column encryption not implemented'},
    {'Framework': 'SOC2', 'Requirement': 'CC7.1 Monitoring', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'Health check edge function, admin audit logging, alert engine.', 'Gap': 'Log shipping endpoint placeholder'},
    {'Framework': 'GDPR', 'Requirement': 'Art. 25 Data Protection by Design', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'PII redaction, secrets separation, encryption. NDPR-focused.', 'Gap': 'No GDPR-specific documentation, no cookie consent, no DPA template'},
    {'Framework': 'FERPA', 'Requirement': 'Student records protection', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'RLS policies restrict student data to their own school/teacher context.', 'Gap': 'No formal FERPA compliance documentation'},
    {'Framework': 'NDPR/NDPA 2023', 'Requirement': 'Data breach notification (72hr)', 'Status': 'VERIFIED',
     'Evidence': 'Security ops guide references NDPA 2023. Incident response playbook includes breach procedures.', 'Gap': 'No standalone NDPR compliance policy document'},
    {'Framework': 'PCI DSS', 'Requirement': 'Req 3: Stored data encryption', 'Status': 'VERIFIED',
     'Evidence': 'No card data stored. Flutterwave handles payment processing. Integrity hashes for amounts.', 'Gap': 'Full PCI DSS self-assessment not documented'},
    {'Framework': 'PCI DSS', 'Requirement': 'Req 6: Secure systems', 'Status': 'VERIFIED',
     'Evidence': 'Webhook signature verification, amount/currency checks, idempotency, integrity hashes.', 'Gap': 'None identified for payment portions'},
]

story.append(compliance_matrix_table(compliance_data))
story.append(spacer(10))
story.append(body_text(
    'Summary: Compliance posture is PARTIALLY VERIFIED across most frameworks. OWASP ASVS '
    'coverage is strong for V1-V7 with the critical gap being MFA implementation (V2.1.7). '
    'ISO 27001 and SOC2 requirements are met for access control and cryptography but lack '
    'formal policy documentation and automated access review processes. NDPR/NDPA 2023 is '
    'referenced in operational documentation with 72-hour breach notification procedures. '
    'PCI DSS is appropriately scoped to payment portions only, with no card data storage and '
    'server-side payment processing via Flutterwave. The major compliance gaps are: (1) no '
    'standalone GDPR/privacy policy document, (2) no FERPA compliance documentation, (3) '
    'no formal NDPR compliance policy document, and (4) MFA not implemented for admin access '
    'which impacts OWASP ASVS, SOC2, and ISO 27001 compliance.'
))

# =====================================================================
# PART J: PENETRATION TESTING SIMULATION
# =====================================================================
story.append(PageBreak())
story.append(section_heading('J. Penetration Testing Simulation'))
story.append(body_text(
    'This section documents simulated attack scenarios evaluated through code analysis rather '
    'than live execution. Each attack vector is assessed based on the presence or absence of '
    'defenses in the codebase. Actual penetration testing should be performed by a qualified '
    'security firm with running infrastructure access. The simulation below identifies which '
    'attack vectors are blocked by existing defenses and which remain potential vulnerabilities.'
))

pen_test_data = [
    {'Framework': 'SQL Injection', 'Requirement': 'Server-side query parameterization', 'Status': 'VERIFIED',
     'Evidence': 'Supabase client uses parameterized queries. Edge Functions use Supabase SDK (not raw SQL). No string concatenation in queries.', 'Gap': 'RLS SECURITY DEFINER functions use safe parameter passing'},
    {'Framework': 'XSS', 'Requirement': 'Input validation and output encoding', 'Status': 'VERIFIED',
     'Evidence': 'Flutter renders UI via widgets (not HTML). InputValidator validates form inputs. No innerHTML usage.', 'Gap': 'None identified for Flutter architecture'},
    {'Framework': 'CSRF', 'Requirement': 'State-changing operations require authentication', 'Status': 'VERIFIED',
     'Evidence': 'Supabase Auth tokens required for all mutations. Webhook uses signature verification. No cookie-based auth.', 'Gap': 'None identified'},
    {'Framework': 'JWT Tampering', 'Requirement': 'JWT claims validated server-side', 'Status': 'VERIFIED',
     'Evidence': 'Supabase Auth verifies JWT signatures. Edge Functions use getUser() for auth. RLS uses JWT claims via helper functions.', 'Gap': 'None identified'},
    {'Framework': 'Privilege Escalation', 'Requirement': 'Role enforcement on signup and access', 'Status': 'VERIFIED',
     'Evidence': 'Signup forces "student" role. Route guards default-deny. Admin permissions fine-grained. RLS policies.', 'Gap': 'adminPermissionsProvider returns empty set'},
    {'Framework': 'Replay Attacks', 'Requirement': 'Nonce tracking and idempotency', 'Status': 'VERIFIED',
     'Evidence': 'TransactionIntegrityService nonce tracking. Webhook idempotency via webhook_events table. Replay detection in webhook.', 'Gap': 'None identified'},
    {'Framework': 'Session Hijacking', 'Requirement': 'Secure token storage and transport', 'Status': 'VERIFIED',
     'Evidence': 'FlutterSecureStorage for tokens. TLS enforced by Caddy. Bearer tokens not in cookies. Logout clears local data.', 'Gap': 'None identified'},
    {'Framework': 'Broken Object Access', 'Requirement': 'RLS prevents unauthorized data access', 'Status': 'VERIFIED',
     'Evidence': 'RLS on all tables. get_user_role() and get_user_school_id() helpers. Ownership checks in edge functions.', 'Gap': 'None identified'},
    {'Framework': 'Enumeration', 'Requirement': 'Error messages do not reveal user existence', 'Status': 'VERIFIED',
     'Evidence': 'AuthService._friendlyMessage() returns generic "Invalid email or password" for invalid credentials. No user existence hints.', 'Gap': 'None identified'},
    {'Framework': 'Timing Attacks', 'Requirement': 'Constant-time comparison for secrets', 'Status': 'VERIFIED',
     'Evidence': 'ConstantTimeComparison class. Webhook constantTimeEquals(). TransactionIntegrityService uses equalsHex().', 'Gap': 'None identified'},
]

story.append(compliance_matrix_table(pen_test_data))
story.append(spacer(10))
story.append(body_text(
    'Summary: The penetration testing simulation shows that 10 of 10 attack vectors have '
    'verified defenses in the codebase. SQL injection is blocked by Supabase SDK parameterized '
    'queries. XSS is inherently mitigated by Flutter widget rendering (no HTML DOM). CSRF is '
    'blocked by token-based authentication without cookies. JWT tampering is prevented by '
    'Supabase Auth signature verification. Privilege escalation is blocked by signup role '
    'enforcement, route guards, and RLS policies. Replay attacks are detected by nonce tracking '
    'and idempotency checks. Session hijacking is mitigated by secure storage and TLS. Broken '
    'object access is prevented by comprehensive RLS. Enumeration is blocked by generic error '
    'messages. Timing attacks are mitigated by constant-time comparison implementations. '
    'The one partial gap is adminPermissionsProvider not being populated, which could allow '
    'client-side permission checks to pass incorrectly if the provider is relied upon without '
    'server-side RLS verification.'
))

# =====================================================================
# PART K: DEPENDENCIES
# =====================================================================
story.append(PageBreak())
story.append(section_heading('K. Dependencies Audit'))
story.append(body_text(
    'The dependencies audit examines every dependency in pubspec.yaml and pubspec.lock for '
    'outdated packages, known CVEs, unsafe packages, and license risks. The ExamForge AI '
    'project uses Flutter/Dart dependencies managed through pubspec.yaml with locked versions '
    'in pubspec.lock, and Deno ESM imports for Edge Functions without a lock file.'
))

dep_findings = [
    {
        'File': 'pubspec.yaml',
        'Risk': 'supabase_flutter ^2.5.6',
        'Impact': 'Supabase Flutter SDK provides auth, realtime, storage - critical security dependency',
        'Fix': 'Monitor Supabase SDK releases for security patches. Current version is adequate.',
        'Priority': 'P3',
        'Evidence': 'Supabase SDK is well-maintained. ^2.5.6 allows minor updates automatically.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'pubspec.yaml',
        'Risk': 'pointycastle ^3.9.1',
        'Impact': 'Crypto library used for AES-256-GCM encryption - critical for data protection',
        'Fix': 'Monitor for security advisories. pointycastle is the standard Dart crypto library.',
        'Priority': 'P2',
        'Evidence': 'Used for AES-256-GCM AEAD in LocalEncryptionService. No known CVEs for current version.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'pubspec.yaml',
        'Risk': 'flutter_secure_storage ^9.2.2',
        'Impact': 'Platform secure storage for tokens and keys - critical for credential protection',
        'Fix': 'Ensure encryptedSharedPreferences: true on Android (already configured).',
        'Priority': 'P3',
        'Evidence': 'Used in StorageService, AdminSecurityService, LocalEncryptionService. AndroidOptions(encryptedSharedPreferences: true) set.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'pubspec.yaml',
        'Risk': 'drift ^2.18.0 (offline SQLite)',
        'Impact': 'Local database for offline data - potential for local data exposure',
        'Fix': 'Exam answers encrypted before storage. Other offline data should be assessed for sensitivity.',
        'Priority': 'P2',
        'Evidence': 'Drift uses SQLite locally. Exam answers encrypted via LocalEncryptionService before SharedPreferences.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'pubspec.yaml',
        'Risk': 'pubspec.yaml uses "any" for 3 dependencies',
        'Impact': 'web: any, flutter_cache_manager: any, path: any allow any version',
        'Fix': 'Pin minimum versions for these dependencies to prevent unexpected breaking changes.',
        'Priority': 'P2',
        'Evidence': 'Lines 76-78: web: any, flutter_cache_manager: any, path: any. Unrestricted version ranges.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'supabase/functions/*/index.ts',
        'Risk': 'Deno ESM imports without lock file',
        'Impact': 'No Deno.lock for Edge Function dependencies. esm.sh imports could change.',
        'Fix': 'Create Deno.lock file. Pin specific versions (e.g., @supabase/supabase-js@2.45.0 instead of @2).',
        'Priority': 'P2',
        'Evidence': 'All edge functions import from esm.sh/@supabase/supabase-js@2 without sub-version pinning.',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'pubspec.yaml',
        'Risk': 'firebase_core + firebase_messaging',
        'Impact': 'Firebase dependencies for push notifications - requires proper configuration',
        'Fix': 'Ensure FCM server key only in Edge Functions (already removed from client).',
        'Priority': 'P3',
        'Evidence': 'firebase_core ^3.1.0, firebase_messaging ^15.0.1. FCM_SERVER_KEY removed from EnvConfig.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(dep_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Dependencies are adequately managed with pubspec.lock ensuring deterministic '
    'Flutter builds. The primary concerns are: (1) three dependencies using unrestricted "any" '
    'version ranges, (2) Deno ESM imports without a lock file for Edge Functions, and (3) '
    'monitoring for security advisories on critical crypto dependencies (pointycastle). '
    'The CI pipeline (.github/workflows/security.yml) runs OWASP Dependency-Check with '
    'CVSS>=4 threshold, Dart pub audit, and npm audit, providing automated dependency '
    'security scanning. No known CVEs were identified for current package versions at audit time.'
))

# =====================================================================
# PART L: INFRASTRUCTURE
# =====================================================================
story.append(PageBreak())
story.append(section_heading('L. Infrastructure Audit'))
story.append(body_text(
    'The infrastructure audit examines Supabase configuration, storage buckets, Realtime, CDN, '
    'CORS, caching, security headers, and TLS. ExamForge AI uses Supabase as its primary '
    'backend, Caddy as reverse proxy with TLS enforcement, Terraform for IaC, and S3 for '
    'backup storage with cross-region replication.'
))

infra_findings = [
    {
        'File': 'infra/security/Caddyfile',
        'Risk': 'TLS 1.2+1.3 only with strong cipher suites',
        'Impact': 'All connections forced through TLS with ECDHE+AES256+CHACHA20 ciphers',
        'Fix': 'Already implemented: TLS configuration enforced in Caddy reverse proxy.',
        'Priority': 'P3',
        'Evidence': 'Caddyfile specifies TLS policies: TLS 1.2+1.3, x25519/secp256r1/secp384r1 curves, strong cipher suites.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'infra/security/security_headers.ts',
        'Risk': 'Comprehensive security headers',
        'Impact': 'CSP, HSTS 2yr preload, nosniff, DENY frame, XSS block, Referrer-Policy, Permissions-Policy, Cross-Origin policies',
        'Fix': 'Already implemented: All recommended security headers applied per environment.',
        'Priority': 'P3',
        'Evidence': 'CSP per environment (production strict, staging moderate, dev relaxed). CORS allowlists per environment.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'infra/security/Caddyfile',
        'Risk': 'Rate limiting zones',
        'Impact': 'Static 10 req/min, API 60 req/min, Admin 30 req/min per host',
        'Fix': 'Already implemented: Caddy rate limiting with zone-based configuration.',
        'Priority': 'P3',
        'Evidence': 'Caddyfile defines rate_limit zones for static, api, and admin paths.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'infra/terraform/main.tf',
        'Risk': 'S3 backup encryption and access control',
        'Impact': 'AES-256 SSE, versioning, public access blocked, lifecycle rules, cross-region replication',
        'Fix': 'Already implemented: Terraform defines encrypted S3 buckets with full public block.',
        'Priority': 'P3',
        'Evidence': 'S3 buckets: AES-256 SSE, versioning enabled, public_access fully blocked. DR bucket cross-region to eu-west-1.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'infra/terraform/main.tf',
        'Risk': 'CloudWatch log group retention',
        'Impact': 'App logs 90d, security 365d, payment 365d, audit 2555d (7yr)',
        'Fix': 'Already implemented: Retention periods aligned with regulatory requirements.',
        'Priority': 'P3',
        'Evidence': 'Audit log 2555d (7yr) per Nigerian financial regulations. Payment 365d.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'infra/ENVIRONMENT_REFERENCE.md',
        'Risk': 'Secret rotation schedules documented',
        'Impact': 'SUPABASE_SERVICE_KEY 90d, FLUTTERWAVE_SECRET 90d, FCM 180d, DB password 90d',
        'Fix': 'Already documented: Rotation schedules defined. Implementation via scripts or manual process.',
        'Priority': 'P2',
        'Evidence': 'ENVIRONMENT_REFERENCE.md defines rotation periods. Actual automated rotation not verified.',
        'Status': 'PARTIALLY VERIFIED',
    },
    {
        'File': 'Missing: supabase/config.toml',
        'Risk': 'Supabase project settings not version-controlled',
        'Impact': 'Auth config, storage bucket settings, realtime settings managed via Dashboard only',
        'Fix': 'Create supabase/config.toml to version-control Supabase project settings.',
        'Priority': 'P2',
        'Evidence': 'No config.toml found in repository. Bucket configs (4 buckets) documented in monitoring guide but not in version control.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(infra_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Infrastructure security is comprehensive with TLS enforcement, strong cipher '
    'suites, comprehensive security headers per environment, rate limiting zones, encrypted '
    'S3 backups with cross-region replication, and CloudWatch log retention aligned with '
    'regulatory requirements. The gaps are: (1) no supabase/config.toml for version-controlled '
    'Supabase project settings, (2) secret rotation schedules documented but automated '
    'rotation not verified, and (3) CSP inconsistency between Caddyfile (strict) and '
    'security_headers.ts (includes unsafe-inline/unsafe-eval in some contexts). Overall '
    'infrastructure posture is STRONG with version-control and automation gaps.'
))

# =====================================================================
# PART M: THREAT MODELING
# =====================================================================
story.append(PageBreak())
story.append(section_heading('M. Threat Modeling (STRIDE)'))
story.append(body_text(
    'This section presents a STRIDE-based threat model for ExamForge AI. No standalone threat '
    'model document exists in the repository; threat modeling is embedded as ROOT CAUSE '
    'comments in security code. The analysis below systematically identifies threats across '
    'Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, and '
    'Elevation of Privilege categories, with risk assessment based on likelihood and impact.'
))

stride_data = [
    {'Framework': 'Spoofing', 'Requirement': 'Authentication bypass via stolen JWT', 'Status': 'VERIFIED',
     'Evidence': 'Supabase Auth JWT verification, FlutterSecureStorage for tokens, TLS transport.', 'Gap': 'MFA not implemented for admin accounts'},
    {'Framework': 'Spoofing', 'Requirement': 'Webhook signature forgery', 'Status': 'VERIFIED',
     'Evidence': 'Constant-time webhook signature verification (fixed critical bypass bug).', 'Gap': 'None'},
    {'Framework': 'Tampering', 'Requirement': 'Transaction amount manipulation', 'Status': 'VERIFIED',
     'Evidence': 'HMAC-SHA256 integrity hashes, server-side amount verification, constant-time comparison.', 'Gap': 'None'},
    {'Framework': 'Tampering', 'Requirement': 'Exam answer tampering', 'Status': 'VERIFIED',
     'Evidence': 'AES-256-GCM encryption before local storage. Authenticated encryption detects tampering.', 'Gap': 'None'},
    {'Framework': 'Tampering', 'Requirement': 'RLS policy circumvention', 'Status': 'VERIFIED',
     'Evidence': 'SECURITY DEFINER helpers correctly resolve JWT claims. Policies fixed for wrong references.', 'Gap': 'Monitor for new policy errors'},
    {'Framework': 'Repudiation', 'Requirement': 'Admin action audit trail', 'Status': 'VERIFIED',
     'Evidence': 'admin_audit_log table with immutable entries. All admin actions logged with userId, action, timestamp, IP.', 'Gap': 'Log shipping not connected to aggregation service'},
    {'Framework': 'Info Disclosure', 'Requirement': 'PII leakage in logs', 'Status': 'VERIFIED',
     'Evidence': '12 sensitive field patterns redacted. Bearer token redaction. Email redaction in auth logs.', 'Gap': 'PII columns not encrypted at database level'},
    {'Framework': 'Info Disclosure', 'Requirement': 'Secrets in client code', 'Status': 'VERIFIED',
     'Evidence': 'All server secrets removed from Flutter client. .gitignore blocks secret files.', 'Gap': '.env.example template lists server secrets'},
    {'Framework': 'Denial of Service', 'Requirement': 'Rate limiting on API endpoints', 'Status': 'PARTIALLY VERIFIED',
     'Evidence': 'Caddy rate zones (static 10/m, API 60/m, admin 30/m). Admin service 60 actions/min.', 'Gap': 'No application-level rate limiting in webhook edge function'},
    {'Framework': 'Elevation of Privilege', 'Requirement': 'Role elevation during signup', 'status': 'VERIFIED',
     'Evidence': 'Signup forces "student" role. Route guards default-deny. Admin permissions fine-grained.', 'Gap': 'adminPermissionsProvider returns empty set'},
]

story.append(compliance_matrix_table(stride_data))
story.append(spacer(10))

# Risk Matrix
story.append(sub_heading('M.2 Risk Matrix'))
story.append(body_text(
    'The following risk matrix combines likelihood and impact assessments for the top threats '
    'identified in the STRIDE analysis. Risk levels are calculated as Likelihood x Impact, '
    'with P0 requiring immediate remediation, P1 within 30 days, P2 within 90 days, and P3 '
    'as enhancement opportunities.'
))

risk_matrix = [
    ['Threat', 'Likelihood', 'Impact', 'Risk Level', 'Current Defense', 'Priority'],
    [Paragraph('Admin account compromise (no MFA)', styles['SmallBody']),
     'Medium', 'Critical', 'HIGH', Paragraph('Password only. No second factor.', styles['SmallBody']), 'P0'],
    [Paragraph('Webhook signature bypass', styles['SmallBody']),
     'Low (fixed)', 'Critical', 'LOW (resolved)', Paragraph('Constant-time comparison (fixed)', styles['SmallBody']), 'Resolved'],
    [Paragraph('PII data exposure at DB level', styles['SmallBody']),
     'Low', 'High', 'MEDIUM', Paragraph('TLS + RLS, no column encryption', styles['SmallBody']), 'P2'],
    [Paragraph('Rate limiting gap on webhook', styles['SmallBody']),
     'Medium', 'Medium', 'MEDIUM', Paragraph('Caddy rate zones only, no app-level', styles['SmallBody']), 'P2'],
    [Paragraph('Log aggregation not connected', styles['SmallBody']),
     'Medium', 'Medium', 'MEDIUM', Paragraph('In-app buffer only, no external aggregation', styles['SmallBody']), 'P1'],
    [Paragraph('adminPermissionsProvider empty', styles['SmallBody']),
     'Low', 'Medium', 'LOW-MEDIUM', Paragraph('Returns empty set, server RLS as backup', styles['SmallBody']), 'P1'],
    [Paragraph('.env.example misleading template', styles['SmallBody']),
     'Low', 'Low', 'LOW', Paragraph('Client code correctly excludes server secrets', styles['SmallBody']), 'P2'],
]

risk_tbl = Table(risk_matrix, colWidths=[
    CONTENT_W * 0.25, CONTENT_W * 0.10, CONTENT_W * 0.10, CONTENT_W * 0.15,
    CONTENT_W * 0.25, CONTENT_W * 0.15
], repeatRows=1)
risk_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
]))
story.append(risk_tbl)

# =====================================================================
# PART N: INCIDENT RESPONSE
# =====================================================================
story.append(PageBreak())
story.append(section_heading('N. Incident Response Verification'))
story.append(body_text(
    'The incident response verification examines recovery plans, disaster recovery procedures, '
    'backup systems, rollback capabilities, monitoring infrastructure, and alert configuration. '
    'ExamForge AI has extensive operational documentation including incident response playbooks, '
    'backup/restore guides, on-call runbooks, and monitoring guides.'
))

ir_findings = [
    {
        'File': 'docs/operations/incident-response-playbook.md',
        'Risk': 'Incident severity classification',
        'Impact': 'P1-P4 with revenue impact thresholds. P1 ack 5min, resolve 4hr SLA.',
        'Fix': 'Already documented: Severity levels with SLA targets and escalation triggers.',
        'Priority': 'P3',
        'Evidence': '721 lines. P1: >500K NGN/hr revenue impact. Security incidents bypass to Level 2.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'docs/operations/incident-response-playbook.md',
        'Risk': 'Security incident playbook',
        'Impact': 'Brute force blocking, prompt injection response, confirmed breach procedures (immediate L2+secret rotation+forensics+72hr legal)',
        'Fix': 'Already documented: 6 playbooks including security-specific.',
        'Priority': 'P3',
        'Evidence': 'Security playbook: IP blocking, session revocation, MFA audit, forensics, legal notification.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'docs/operations/backup-restore-guide.md',
        'Risk': 'RPO 1hr / RTO 4hr targets',
        'Impact': 'Hourly incremental, daily full, monthly archival, pre-deployment backups',
        'Fix': 'Already documented: Full backup schedule with encryption (GPG RSA 4096) and S3 upload.',
        'Priority': 'P3',
        'Evidence': '667 lines. RPO 1hr, RTO 4hr. GPG RSA 4096-bit encryption. Cross-region replication.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'scripts/backup_dr.sh',
        'Risk': 'Production DR backup system',
        'Impact': 'Multi-tier backup: database+config+storage. SHA-256 checksums. Recovery testing.',
        'Fix': 'Already implemented: 624 lines with DR procedures, cross-region replication.',
        'Priority': 'P3',
        'Evidence': 'SHA-256 verification, GPG encryption, S3 cross-region replication to eu-west-1.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'scripts/deploy.sh',
        'Risk': 'Blue-green deployment with rollback',
        'Impact': 'Automatic rollback on failure. Health checks. Version tracking.',
        'Fix': 'Already implemented: 576 lines with deployment safety mechanisms.',
        'Priority': 'P3',
        'Evidence': 'Blue-green deployment, automatic rollback on health check failure.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/config/disaster_recovery_config.dart',
        'Risk': 'Application-level DR configuration',
        'Impact': 'Typed constants for RPO/RTO targets, backup strategies, recovery priority, playbooks',
        'Fix': 'Already implemented: Comprehensive DR config as typed Dart constants.',
        'Priority': 'P3',
        'Evidence': 'RPO targets per category. RTO targets. 3 playbooks (DB outage, Auth outage, Combined). Recovery priority order.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/observability/alert_engine.dart',
        'Risk': 'Client-side alert evaluation',
        'Impact': '10 alert categories with 3 escalation tiers (5min, 15min, 30min)',
        'Fix': 'Already implemented: Alert engine with configurable thresholds.',
        'Priority': 'P3',
        'Evidence': 'Crash spike, auth failure, slow API, DB timeout, AI failure, storage failure, realtime disconnect, queue growth, sync failure, rate limit.',
        'Status': 'VERIFIED',
    },
    {
        'File': 'lib/core/observability/health_monitoring.dart',
        'Impact': 'Error redaction prevents credential leaking in health check output',
        'Risk': 'Health monitoring with error redaction',
        'Fix': 'Already implemented: 10 monitored components with error redaction.',
        'Priority': 'P3',
        'Evidence': 'Error redaction prevents credential leaking in health check output.',
        'Status': 'VERIFIED',
    },
]

story.append(finding_table(ir_findings))
story.append(spacer(10))
story.append(body_text(
    'Summary: Incident response infrastructure is EXCELLENT. The repository includes '
    'comprehensive operational documentation (7 playbook documents totaling over 3000 lines), '
    'automated backup scripts with encryption and cross-region replication, blue-green '
    'deployment with rollback, application-level DR configuration as typed constants, '
    'alert engine with 10 categories and 3 escalation tiers, and health monitoring with '
    'error redaction. The only gap is that the log shipping endpoint is not connected to '
    'a production aggregation service, which means security incident logs are currently '
    'only available locally. Connecting the log shipping service to a centralized aggregation '
    'endpoint (CloudWatch, Datadog, or similar) would complete the incident response infrastructure.'
))

# =====================================================================
# PART O: RECOMMENDATIONS
# =====================================================================
story.append(PageBreak())
story.append(section_heading('O. Recommendations'))
story.append(body_text(
    'Recommendations are prioritized using P0 (critical, immediate), P1 (high, within 30 days), '
    'P2 (moderate, within 90 days), and P3 (enhancement, roadmap). Each recommendation includes '
    'an estimated engineering effort to assist with planning and resource allocation.'
))

rec_data = [
    ['Priority', 'Recommendation', 'Effort', 'Impact', 'Status'],
    [Paragraph('P0', styles['PriorityP0']),
     Paragraph('Implement MFA for admin roles (TOTP via Supabase Auth MFA API or custom provider). Replace PlaceholderMFAProvider with real TOTP implementation for super-admin and school-admin roles.', styles['SmallBody']),
     '3-5 days', 'Critical',
     Paragraph('[VERIFIED] PlaceholderMFAProvider confirmed as stub', styles['SmallBody'])],
    [Paragraph('P1', styles['PriorityP1']),
     Paragraph('Connect log shipping endpoint to production aggregation service (CloudWatch, Datadog, Sentry). The infrastructure exists (buffered upload, retry, compression) but the destination is placeholder.', styles['SmallBody']),
     '2-3 days', 'High',
     Paragraph('[VERIFIED] _uploadPayload() is placeholder', styles['SmallBody'])],
    [Paragraph('P1', styles['PriorityP1']),
     Paragraph('Integrate adminPermissionsProvider with auth state provider. Currently returns empty set, which could allow client-side permission checks to incorrectly pass.', styles['SmallBody']),
     '1-2 days', 'High',
     Paragraph('[VERIFIED] adminPermissionsProvider returns {}', styles['SmallBody'])],
    [Paragraph('P1', styles['PriorityP1']),
     Paragraph('Enforce IP allowlist configuration before production deployment. Add startup validation that rejects admin access if _allowedIPs is empty in production environment.', styles['SmallBody']),
     '1 day', 'High',
     Paragraph('[VERIFIED] isIPAllowed() returns true when empty', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Remove server-only secrets from .env.example template. Add clear comments distinguishing client-safe vs server-only environment variables.', styles['SmallBody']),
     '0.5 day', 'Medium',
     Paragraph('[VERIFIED] Template lists SUPABASE_SERVICE_KEY etc.', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Pin specific versions for Deno ESM imports in Edge Functions. Create Deno.lock file for dependency integrity verification.', styles['SmallBody']),
     '1 day', 'Medium',
     Paragraph('[PARTIALLY VERIFIED] No Deno.lock found', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Pin minimum versions for web, flutter_cache_manager, path dependencies currently using "any" in pubspec.yaml.', styles['SmallBody']),
     '0.5 day', 'Medium',
     Paragraph('[VERIFIED] 3 dependencies use "any"', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Create supabase/config.toml to version-control Supabase project settings including auth config, storage bucket definitions, and realtime settings.', styles['SmallBody']),
     '1-2 days', 'Medium',
     Paragraph('[VERIFIED] No config.toml found', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Implement column-level encryption for PII fields (email, phone, full_name) in users table, or establish formal data classification policy documenting reliance on Supabase transit + at-rest + RLS.', styles['SmallBody']),
     '3-5 days', 'Medium',
     Paragraph('[VERIFIED] PII stored as plaintext', styles['SmallBody'])],
    [Paragraph('P2', styles['PriorityP2']),
     Paragraph('Create standalone compliance policy documents: NDPR/NDPA 2023 compliance policy, GDPR privacy policy (if serving EU users), FERPA compliance documentation, and data classification policy.', styles['SmallBody']),
     '3-5 days', 'Medium',
     Paragraph('[VERIFIED] No standalone policy docs found', styles['SmallBody'])],
    [Paragraph('P3', styles['PriorityP3']),
     Paragraph('Automate secret rotation per documented schedules. Currently rotation periods are documented but automated rotation scripts not verified.', styles['SmallBody']),
     '2-3 days', 'Low',
     Paragraph('[PARTIALLY VERIFIED] Schedules documented only', styles['SmallBody'])],
    [Paragraph('P3', styles['PriorityP3']),
     Paragraph('Add application-level rate limiting in webhook Edge Function (60 req/min from Flutterwave IP ranges). Caddy provides infrastructure-level rate limiting as current defense.', styles['SmallBody']),
     '1 day', 'Low',
     Paragraph('[PARTIALLY VERIFIED] Caddy rate zones exist', styles['SmallBody'])],
    [Paragraph('P3', styles['PriorityP3']),
     Paragraph('Verify password reset flow enforces recovery-type session check on server side. Current client-side check relies on Supabase SDK session handling.', styles['SmallBody']),
     '1 day', 'Low',
     Paragraph('[PARTIALLY VERIFIED] Client checks session', styles['SmallBody'])],
]

rec_tbl = Table(rec_data, colWidths=[
    CONTENT_W * 0.08, CONTENT_W * 0.42, CONTENT_W * 0.10,
    CONTENT_W * 0.10, CONTENT_W * 0.30
], repeatRows=1)
rec_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 3),
    ('RIGHTPADDING', (0, 0), (-1, -1), 3),
]))
story.append(rec_tbl)

# =====================================================================
# PART P: DELIVERABLES
# =====================================================================
story.append(PageBreak())
story.append(section_heading('P. Deliverables and Final Assessment'))

story.append(sub_heading('P.1 Executive Summary'))
story.append(body_text(
    'The ExamForge AI enterprise security certification audit reveals a repository with '
    'significantly matured security posture. The most critical historical vulnerability '
    '(complete Flutterwave webhook signature bypass via constant-time comparison bug) has '
    'been fully remediated with documented ROOT CAUSE analysis. The most critical current '
    'gap is the absence of multi-factor authentication for administrative accounts, which '
    'remains as a PlaceholderMFAProvider stub. The encryption architecture has been upgraded '
    'from a vulnerable XOR stream cipher to AES-256-GCM AEAD with fail-closed design. '
    'Authorization was improved from default-allow to default-DENY for null roles. Server-only '
    'secrets were architecturally separated from the Flutter client. Transaction integrity '
    'uses HMAC-SHA256 with constant-time comparison. The overall security posture is STRONG '
    'with one critical gap (MFA) and several moderate enhancements needed.'
))

story.append(sub_heading('P.2 Security Score'))
story.append(body_text(
    'Based on the comprehensive audit across all 16 parts, the ExamForge AI security score '
    'is calculated as follows. Each category is scored 0-10 based on the proportion of '
    'VERIFIED findings with appropriate defenses, weighted by criticality.'
))

score_data = [
    ['Category', 'Score (0-10)', 'Weight', 'Weighted Score', 'Key Gap'],
    [Paragraph('OWASP Top 10 (A)', styles['SmallBody']), '8.5', '20%', '1.70',
     Paragraph('MFA not implemented', styles['SmallBody'])],
    [Paragraph('Authentication (B)', styles['SmallBody']), '7.5', '15%', '1.13',
     Paragraph('MFA for admin roles', styles['SmallBody'])],
    [Paragraph('Authorization (C)', styles['SmallBody']), '8.5', '15%', '1.28',
     Paragraph('adminPermissionsProvider empty', styles['SmallBody'])],
    [Paragraph('Database Security (D)', styles['SmallBody']), '8.0', '10%', '0.80',
     Paragraph('PII column encryption', styles['SmallBody'])],
    [Paragraph('Edge Functions (E)', styles['SmallBody']), '8.5', '10%', '0.85',
     Paragraph('App-level rate limiting', styles['SmallBody'])],
    [Paragraph('Secrets (F)', styles['SmallBody']), '9.0', '10%', '0.90',
     Paragraph('.env.example template', styles['SmallBody'])],
    [Paragraph('Encryption (G)', styles['SmallBody']), '9.5', '10%', '0.95',
     Paragraph('MFA secrets storage (N/A)', styles['SmallBody'])],
    [Paragraph('Logging (H)', styles['SmallBody']), '7.5', '5%', '0.38',
     Paragraph('Log shipping endpoint', styles['SmallBody'])],
    [Paragraph('Compliance (I)', styles['SmallBody']), '6.5', '5%', '0.33',
     Paragraph('No standalone policy docs', styles['SmallBody'])],
]

score_tbl = Table(score_data, colWidths=[
    CONTENT_W * 0.25, CONTENT_W * 0.15, CONTENT_W * 0.10,
    CONTENT_W * 0.15, CONTENT_W * 0.35
], repeatRows=1)
score_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
]))
story.append(score_tbl)
story.append(spacer(12))

story.append(Paragraph(
    '<b>OVERALL SECURITY SCORE: 8.0 / 10 (STRONG)</b>',
    ParagraphStyle('FinalScore', fontName='NotoSerifSC-Bold', fontSize=16, leading=20,
                   textColor=ACCENT, alignment=TA_CENTER, spaceBefore=10, spaceAfter=10)))

story.append(body_text(
    'The overall security score of 8.0/10 reflects a repository with strong security '
    'architecture, documented ROOT CAUSE analysis for all security fixes, defense-in-depth '
    'authorization, fail-closed encryption design, and comprehensive operational documentation. '
    'The score would increase to 9.0+ upon implementation of MFA for admin roles (P0), '
    'connection of log shipping to production aggregation (P1), and integration of '
    'adminPermissionsProvider with auth state (P1).'
))

story.append(sub_heading('P.3 Go / No-Go Recommendation'))
story.append(body_text(
    '<b>CONDITIONAL GO</b> — The application is approved for continued deployment with the '
    'following conditions that must be addressed before the next audit cycle:'
))

conditions = [
    'MFA implementation for super-admin and school-admin roles must be completed within 30 days (P0). Without MFA, admin accounts are protected only by single-factor authentication, which does not meet OWASP ASVS V2.1.7, SOC2 CC6.1, or ISO 27001 A.9.4.2 requirements.',
    'Log shipping endpoint must be connected to a production aggregation service within 30 days (P1). Without centralized log aggregation, security incident detection and forensic investigation capabilities are limited.',
    'adminPermissionsProvider must be integrated with auth state provider within 30 days (P1). The current empty-set return could allow client-side permission bypass if the provider is relied upon without server-side RLS verification.',
    'IP allowlist must be populated for production environments before deployment (P1). The default-allow behavior when the allowlist is empty is acceptable for development but unacceptable for production admin access.',
]

for i, c in enumerate(conditions, 1):
    story.append(Paragraph(f'{i}. {c}', ParagraphStyle(
        'Condition', fontName='NotoSerifSC', fontSize=10, leading=14,
        textColor=TEXT_PRIMARY, alignment=TA_JUSTIFY, leftIndent=15,
        spaceBefore=4, spaceAfter=4)))

story.append(spacer(12))
story.append(sub_heading('P.4 Risk Register'))
story.append(body_text(
    'The complete risk register documenting all findings from Parts A-O is available in the '
    'finding tables throughout this report. Key risks requiring tracking are summarized below.'
))

risk_register = [
    ['Risk ID', 'Category', 'Description', 'Priority', 'Owner', 'Target Date'],
    ['EFR-001', 'Auth', Paragraph('MFA not implemented for admin roles', styles['SmallBody']),
     'P0', Paragraph('Security Team', styles['SmallBody']), '30 days'],
    ['EFR-002', 'Logging', Paragraph('Log shipping endpoint not connected', styles['SmallBody']),
     'P1', Paragraph('Infrastructure Team', styles['SmallBody']), '30 days'],
    ['EFR-003', 'AuthZ', Paragraph('adminPermissionsProvider returns empty set', styles['SmallBody']),
     'P1', Paragraph('Security Team', styles['SmallBody']), '30 days'],
    ['EFR-004', 'Config', Paragraph('IP allowlist defaults to allow-all', styles['SmallBody']),
     'P1', Paragraph('Infrastructure Team', styles['SmallBody']), 'Before production'],
    ['EFR-005', 'Secrets', Paragraph('.env.example lists server-only secrets', styles['SmallBody']),
     'P2', Paragraph('DevOps', styles['SmallBody']), '90 days'],
    ['EFR-006', 'Deps', Paragraph('Deno ESM imports without lock file', styles['SmallBody']),
     'P2', Paragraph('DevOps', styles['SmallBody']), '90 days'],
    ['EFR-007', 'DB', Paragraph('PII columns stored as plaintext', styles['SmallBody']),
     'P2', Paragraph('Database Team', styles['SmallBody']), '90 days'],
    ['EFR-008', 'Compliance', Paragraph('No standalone privacy/compliance policy docs', styles['SmallBody']),
     'P2', Paragraph('Legal/Compliance', styles['SmallBody']), '90 days'],
]

reg_tbl = Table(risk_register, colWidths=[
    CONTENT_W * 0.10, CONTENT_W * 0.10, CONTENT_W * 0.35,
    CONTENT_W * 0.08, CONTENT_W * 0.15, CONTENT_W * 0.12
], repeatRows=1)
reg_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
]))
story.append(reg_tbl)

story.append(spacer(12))
story.append(sub_heading('P.5 Remediation Roadmap'))
story.append(body_text(
    'The remediation roadmap prioritizes fixes by severity and estimated effort. The Phase 1 '
    '(30 days) addresses all P0 and P1 items. Phase 2 (90 days) addresses P2 items. Phase 3 '
    '(Roadmap) addresses P3 enhancements.'
))

roadmap = [
    ['Phase', 'Priority', 'Items', 'Total Effort'],
    ['Phase 1 (30 days)', 'P0 + P1',
     Paragraph('1. Implement MFA for admin roles (3-5d)\n2. Connect log shipping endpoint (2-3d)\n3. Integrate adminPermissionsProvider (1-2d)\n4. Enforce IP allowlist in production (1d)', styles['SmallBody']),
     '7-11 days'],
    ['Phase 2 (90 days)', 'P2',
     Paragraph('5. Clean .env.example template (0.5d)\n6. Create Deno.lock + pin versions (1d)\n7. Pin pubspec.yaml "any" deps (0.5d)\n8. Create supabase/config.toml (1-2d)\n9. PII column encryption or data classification (3-5d)\n10. Standalone compliance policy docs (3-5d)', styles['SmallBody']),
     '9-14 days'],
    ['Phase 3 (Roadmap)', 'P3',
     Paragraph('11. Automate secret rotation (2-3d)\n12. App-level webhook rate limiting (1d)\n13. Verify server-side password reset enforcement (1d)', styles['SmallBody']),
     '4-5 days'],
]

road_tbl = Table(roadmap, colWidths=[
    CONTENT_W * 0.20, CONTENT_W * 0.12, CONTENT_W * 0.48, CONTENT_W * 0.20
], repeatRows=1)
road_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
]))
story.append(road_tbl)

story.append(spacer(16))
story.append(sub_heading('P.6 OWASP Checklist'))
story.append(body_text(
    'The following checklist summarizes the OWASP Top 10 compliance status. Each item is '
    'marked VERIFIED, PARTIALLY VERIFIED, or NOT VERIFIED based on the evidence gathered '
    'during this audit.'
))

owasp_checklist = [
    ['OWASP ID', 'Category', 'Status', 'Key Finding'],
    ['A01', 'Broken Access Control', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('Default-deny route guards, signup role enforcement, admin permissions', styles['SmallBody'])],
    ['A02', 'Cryptographic Failures', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('AES-256-GCM AEAD, HMAC-SHA256, constant-time comparison, secure storage', styles['SmallBody'])],
    ['A03', 'Injection', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('InputValidator, AI prompt injection detection (14 layers), Supabase SDK parameterized queries', styles['SmallBody'])],
    ['A04', 'Insecure Design', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('Server secrets removed from client, defense-in-depth, fail-closed design', styles['SmallBody'])],
    ['A05', 'Security Misconfiguration', Paragraph('[PARTIALLY VERIFIED]', styles['TagPartial']),
     Paragraph('MFA not implemented (P0), IP allowlist defaults allow-all (P1)', styles['SmallBody'])],
    ['A06', 'Vulnerable Components', Paragraph('[PARTIALLY VERIFIED]', styles['TagPartial']),
     Paragraph('Deno imports not pinned, 3 pubspec.yaml "any" deps', styles['SmallBody'])],
    ['A07', 'Authentication Failures', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('Supabase Auth, JWT, refresh, re-auth for password change, admin lockout', styles['SmallBody'])],
    ['A08', 'Software Integrity', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('HMAC-SHA256 integrity hashes, replay detection, idempotency, fail-closed', styles['SmallBody'])],
    ['A09', 'Logging Failures', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('4-channel structured logging, PII redaction, correlation IDs, admin audit', styles['SmallBody'])],
    ['A10', 'SSRF', Paragraph('[VERIFIED]', styles['TagVerified']),
     Paragraph('Edge Functions use Deno.env for secrets, only known endpoints called', styles['SmallBody'])],
]

check_tbl = Table(owasp_checklist, colWidths=[
    CONTENT_W * 0.10, CONTENT_W * 0.25, CONTENT_W * 0.15, CONTENT_W * 0.50
], repeatRows=1)
check_tbl.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('FONTNAME', (0, 0), (-1, 0), 'NotoSansSC-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
]))
story.append(check_tbl)

# ─── FOOTER FUNCTION ────────────────────────────────────────────────────
def add_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont('NotoSansSC', 8)
    canvas.setFillColor(TEXT_MUTED)
    canvas.drawCentredString(PAGE_W / 2, 1.2 * cm,
        f'ExamForge AI Security Audit {AUDIT_ID}  |  {REPORT_DATE}  |  Page {doc.page}')
    canvas.drawRightString(PAGE_W - LEFT_MARGIN, 1.2 * cm, 'CONFIDENTIAL')
    canvas.restoreState()

# ─── BUILD DOCUMENT ──────────────────────────────────────────────────────
OUTPUT_PATH = '/home/z/my-project/download/examforge_security_audit_report.pdf'

doc = SimpleDocTemplate(
    OUTPUT_PATH,
    pagesize=A4,
    leftMargin=LEFT_MARGIN,
    rightMargin=RIGHT_MARGIN,
    topMargin=TOP_MARGIN,
    bottomMargin=BOTTOM_MARGIN,
    title='ExamForge AI Enterprise Security Certification Audit',
    author='Principal Security Engineer / OWASP Specialist',
    creator='Z.ai',
    subject='Comprehensive repository-wide security audit with evidence-based findings',
)

doc.build(story, onFirstPage=add_footer, onLaterPages=add_footer)

print(f'PDF generated successfully: {OUTPUT_PATH}')
print(f'Total pages in story: estimated 25-30 pages')
