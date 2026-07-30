#!/usr/bin/env python3
"""
ExamForge AI — Production Certification Audit Report
Comprehensive 13-phase audit with runtime evidence
"""
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.colors import HexColor

# ── Palette ──
PAGE_BG       = HexColor('#f0f2f2')
HEADER_FILL   = HexColor('#466371')
ACCENT        = HexColor('#246a8e')
ACCENT_2      = HexColor('#b5654a')
TEXT_PRIMARY   = HexColor('#222425')
TEXT_MUTED     = HexColor('#71787b')
SEM_SUCCESS   = HexColor('#4a9763')
SEM_WARNING   = HexColor('#9f8249')
SEM_ERROR     = HexColor('#a9564e')
SEM_INFO      = HexColor('#46719d')
BORDER        = HexColor('#c5ced2')

OUTPUT_PATH = '/home/z/my-project/download/examforge_ai_audit_report.pdf'

doc = SimpleDocTemplate(
    OUTPUT_PATH,
    pagesize=A4,
    topMargin=2*cm,
    bottomMargin=2*cm,
    leftMargin=2.2*cm,
    rightMargin=2.2*cm,
    title='ExamForge AI — Production Certification Audit Report',
    author='Z.ai',
    subject='Final Enterprise Remediation and Production Certification Audit',
)

# ── Styles ──
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(
    'CoverTitle', parent=styles['Title'],
    fontSize=28, leading=34, textColor=HexColor('#1a1a2e'),
    spaceAfter=6, alignment=TA_CENTER, fontName='Helvetica-Bold',
))
styles.add(ParagraphStyle(
    'CoverSubtitle', parent=styles['Normal'],
    fontSize=14, leading=18, textColor=ACCENT,
    spaceAfter=4, alignment=TA_CENTER, fontName='Helvetica',
))
styles.add(ParagraphStyle(
    'SectionTitle', parent=styles['Heading1'],
    fontSize=18, leading=22, textColor=HEADER_FILL,
    spaceBefore=16, spaceAfter=8, fontName='Helvetica-Bold',
    borderWidth=0, borderPadding=0,
))
styles.add(ParagraphStyle(
    'SubSection', parent=styles['Heading2'],
    fontSize=14, leading=18, textColor=ACCENT,
    spaceBefore=10, spaceAfter=6, fontName='Helvetica-Bold',
))
styles.add(ParagraphStyle(
    'BodyText2', parent=styles['Normal'],
    fontSize=10, leading=14, textColor=TEXT_PRIMARY,
    spaceAfter=6, alignment=TA_JUSTIFY, fontName='Helvetica',
))
styles.add(ParagraphStyle(
    'CodeBlock', parent=styles['Code'],
    fontSize=8, leading=10, textColor=HexColor('#2d2d2d'),
    backColor=HexColor('#f5f5f5'), fontName='Courier',
    borderWidth=0.5, borderColor=BORDER, borderPadding=4,
    spaceAfter=6, spaceBefore=4,
))
styles.add(ParagraphStyle(
    'StatusPass', parent=styles['Normal'],
    fontSize=10, leading=14, textColor=SEM_SUCCESS,
    fontName='Helvetica-Bold', spaceAfter=4,
))
styles.add(ParagraphStyle(
    'StatusFail', parent=styles['Normal'],
    fontSize=10, leading=14, textColor=SEM_ERROR,
    fontName='Helvetica-Bold', spaceAfter=4,
))
styles.add(ParagraphStyle(
    'StatusBlock', parent=styles['Normal'],
    fontSize=10, leading=14, textColor=SEM_WARNING,
    fontName='Helvetica-Bold', spaceAfter=4,
))
styles.add(ParagraphStyle(
    'TableHeader', parent=styles['Normal'],
    fontSize=9, leading=12, textColor=colors.white,
    fontName='Helvetica-Bold', alignment=TA_CENTER,
))
styles.add(ParagraphStyle(
    'TableCell', parent=styles['Normal'],
    fontSize=8, leading=11, textColor=TEXT_PRIMARY,
    fontName='Helvetica',
))

story = []

# ── Cover Page ──
story.append(Spacer(1, 4*cm))
story.append(Paragraph('ExamForge AI', styles['CoverTitle']))
story.append(Spacer(1, 0.3*cm))
story.append(Paragraph('Production Certification Audit Report', styles['CoverSubtitle']))
story.append(Spacer(1, 0.5*cm))
story.append(HRFlowable(width='60%', thickness=2, color=ACCENT, spaceAfter=12, spaceBefore=12))
story.append(Paragraph('Final Enterprise Remediation & Production Certification', ParagraphStyle(
    'coverdesc', parent=styles['Normal'], fontSize=11, leading=15,
    textColor=TEXT_MUTED, alignment=TA_CENTER, fontName='Helvetica',
)))
story.append(Spacer(1, 1.5*cm))
cover_info = [
    ['Project:', 'ExamForge AI (Flutter Web + Supabase)'],
    ['Supabase Ref:', 'pzfnptrrnxkgodclyhft'],
    ['Region:', 'eu-north-1'],
    ['Repository:', 'austreinrchima183-ui/examforgeai'],
    ['Date:', '2026-07-30'],
    ['Status:', 'AUDIT IN PROGRESS'],
]
cover_table = Table(cover_info, colWidths=[4*cm, 10*cm])
cover_table.setStyle(TableStyle([
    ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
    ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
    ('FONTSIZE', (0, 0), (-1, -1), 10),
    ('TEXTCOLOR', (0, 0), (0, -1), HEADER_FILL),
    ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
    ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
    ('ALIGN', (1, 0), (1, -1), 'LEFT'),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ('TOPPADDING', (0, 0), (-1, -1), 6),
]))
story.append(cover_table)
story.append(PageBreak())

# ── Section 1: Executive Summary ──
story.append(Paragraph('1. Executive Summary', styles['SectionTitle']))
story.append(Paragraph(
    'This report presents the findings of a comprehensive 13-phase production certification audit for the '
    'ExamForge AI platform, built on Flutter Web and Supabase. The audit was conducted on 2026-07-30 with '
    'the cardinal rule of reporting only verified facts backed by runtime evidence. The platform comprises '
    'a Flutter Web frontend, 13 Supabase Edge Functions, 25+ SQL migration files defining approximately '
    '250 database tables, 177 RPC functions, 1,245 indexes, 191 triggers, and 832 RLS policies. The '
    'Flutter codebase passes all three critical gates: flutter analyze with zero issues, flutter test with '
    '144 out of 144 tests passing, and flutter build web --release succeeding. However, several critical '
    'blockers prevent production certification at this time, most notably the inability to connect to the '
    'live Supabase project to verify migrations, RLS enforcement, Edge Function deployment, and Flutterwave '
    'environment variable configuration.',
    styles['BodyText2']
))
story.append(Paragraph(
    'The most significant finding is that 97 references to raw_user_meta_data remain in the original '
    'migration files, creating a client-spoofable RLS vulnerability. While the rls_raw_meta_fix.sql file '
    'is designed to remediate this by replacing all references with the server-authoritative get_user_role() '
    'function, the fix cannot be verified as applied without live database access. Additionally, the '
    'FLUTTERWAVE_WEBHOOK_SECRET_HASH environment variable has not been configured in the Supabase Edge '
    'Function environment, which would cause webhook signature verification to fail in production.',
    styles['BodyText2']
))

# ── Section 2: Flutter Verification ──
story.append(Paragraph('2. Flutter Verification (Runtime Evidence)', styles['SectionTitle']))
story.append(Paragraph('Phase 0 — Flutter Build Quality Gates', styles['SubSection']))

flutter_data = [
    [Paragraph('Check', styles['TableHeader']),
     Paragraph('Result', styles['TableHeader']),
     Paragraph('Evidence', styles['TableHeader'])],
    [Paragraph('flutter analyze', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('No issues found! (ran in 7.4s)', styles['TableCell'])],
    [Paragraph('flutter test', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('144/144 All tests passed!', styles['TableCell'])],
    [Paragraph('flutter build web --release', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('Built build/web (65.3s compile)', styles['TableCell'])],
]
ft = Table(flutter_data, colWidths=[5*cm, 2.5*cm, 8*cm])
ft.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('BACKGROUND', (1, 1), (1, 1), HexColor('#e8f5e9')),
    ('BACKGROUND', (1, 2), (1, 2), HexColor('#e8f5e9')),
    ('BACKGROUND', (1, 3), (1, 3), HexColor('#e8f5e9')),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('ALIGN', (1, 0), (1, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 4),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
]))
story.append(ft)
story.append(Spacer(1, 0.3*cm))
story.append(Paragraph(
    'All three Flutter quality gates pass with runtime evidence. The test suite includes 144 tests covering '
    'core security features including constant-time comparison, SQL injection prevention, XSS prevention, '
    'path traversal prevention, CORS configuration, security headers, RLS policy verification, audit logging, '
    'and rate limiting. The build produces a production-ready web bundle with icon tree-shaking reducing '
    'MaterialIcons from 1.6MB to 112KB (93.2% reduction).',
    styles['BodyText2']
))

# ── Section 3: Database Schema Inventory ──
story.append(Paragraph('3. Database Schema Inventory (Local Code Analysis)', styles['SectionTitle']))
story.append(Paragraph('Phase 1 — Supabase Verification (Partial — Local Only)', styles['SubSection']))
story.append(Paragraph(
    'The following inventory was compiled from local SQL migration file analysis. Live database verification '
    'requires a Supabase access token (sbp_... format), which was not available during this audit session. '
    'The GitHub PAT provided (ghp_...) is for repository access only and cannot authenticate with the '
    'Supabase Management API.',
    styles['BodyText2']
))

db_data = [
    [Paragraph('Metric', styles['TableHeader']),
     Paragraph('Count', styles['TableHeader']),
     Paragraph('Source', styles['TableHeader'])],
    [Paragraph('SQL Migration Files', styles['TableCell']),
     Paragraph('25', styles['TableCell']),
     Paragraph('supabase/migrations/', styles['TableCell'])],
    [Paragraph('Unique Tables', styles['TableCell']),
     Paragraph('~250+', styles['TableCell']),
     Paragraph('CREATE TABLE IF NOT EXISTS', styles['TableCell'])],
    [Paragraph('Indexes', styles['TableCell']),
     Paragraph('1,245', styles['TableCell']),
     Paragraph('CREATE INDEX statements', styles['TableCell'])],
    [Paragraph('Triggers', styles['TableCell']),
     Paragraph('191', styles['TableCell']),
     Paragraph('CREATE TRIGGER statements', styles['TableCell'])],
    [Paragraph('Trigger Functions', styles['TableCell']),
     Paragraph('57', styles['TableCell']),
     Paragraph('RETURNS TRIGGER functions', styles['TableCell'])],
    [Paragraph('RPC Functions', styles['TableCell']),
     Paragraph('177', styles['TableCell']),
     Paragraph('CREATE OR REPLACE FUNCTION', styles['TableCell'])],
    [Paragraph('Enum Types', styles['TableCell']),
     Paragraph('140+', styles['TableCell']),
     Paragraph('CREATE TYPE AS ENUM', styles['TableCell'])],
    [Paragraph('FK Constraints', styles['TableCell']),
     Paragraph('674', styles['TableCell']),
     Paragraph('REFERENCES statements', styles['TableCell'])],
    [Paragraph('Unique Constraints', styles['TableCell']),
     Paragraph('129', styles['TableCell']),
     Paragraph('UNIQUE statements', styles['TableCell'])],
    [Paragraph('RLS Enabled', styles['TableCell']),
     Paragraph('432', styles['TableCell']),
     Paragraph('ENABLE ROW LEVEL SECURITY', styles['TableCell'])],
    [Paragraph('RLS Policies', styles['TableCell']),
     Paragraph('832', styles['TableCell']),
     Paragraph('CREATE POLICY statements', styles['TableCell'])],
    [Paragraph('Realtime Publication Tables', styles['TableCell']),
     Paragraph('18', styles['TableCell']),
     Paragraph('ALTER PUBLICATION supabase_realtime', styles['TableCell'])],
]
dt = Table(db_data, colWidths=[5*cm, 2.5*cm, 8*cm])
dt.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('ALIGN', (1, 0), (1, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, HexColor('#f8f9fa')]),
]))
story.append(dt)

# ── Duplicate Tables ──
story.append(Paragraph('3.1 Duplicate Table Definitions (Potential Conflicts)', styles['SubSection']))
story.append(Paragraph(
    'The following tables are defined in multiple migration files, which could cause conflicts if the '
    'migrations are not applied in the correct order or if the CREATE TABLE IF NOT EXISTS clause does not '
    'properly handle schema evolution. These duplicates need to be verified against the live database to '
    'ensure no data loss or constraint violations occur during migration application.',
    styles['BodyText2']
))

dup_data = [
    [Paragraph('Table', styles['TableHeader']),
     Paragraph('Files', styles['TableHeader'])],
    [Paragraph('feature_flags', styles['TableCell']),
     Paragraph('infrastructure_monitoring.sql, super_admin_schema.sql', styles['TableCell'])],
    [Paragraph('subtopics', styles['TableCell']),
     Paragraph('ccms_enterprise_schema.sql, question_bank_schema.sql', styles['TableCell'])],
    [Paragraph('webhook_events', styles['TableCell']),
     Paragraph('billing_schema.sql, payment_security_hardening.sql', styles['TableCell'])],
    [Paragraph('topics', styles['TableCell']),
     Paragraph('ccms_enterprise_schema.sql, question_bank_schema.sql', styles['TableCell'])],
    [Paragraph('exam_notifications', styles['TableCell']),
     Paragraph('cbt_engine_enhancements_schema.sql, cbt_engine_schema.sql', styles['TableCell'])],
    [Paragraph('grade_scales', styles['TableCell']),
     Paragraph('cbt_engine_schema.sql, results_analytics_schema.sql', styles['TableCell'])],
    [Paragraph('marketplace_commission_rates', styles['TableCell']),
     Paragraph('marketplace_schema.sql, payment_security_hardening.sql', styles['TableCell'])],
    [Paragraph('academic_sessions', styles['TableCell']),
     Paragraph('question_bank_schema.sql, school_management_schema.sql', styles['TableCell'])],
    [Paragraph('study_plans', styles['TableCell']),
     Paragraph('final_production_schema.sql, student_portal_schema.sql', styles['TableCell'])],
]
dupt = Table(dup_data, colWidths=[5*cm, 10.5*cm])
dupt.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, HexColor('#f8f9fa')]),
]))
story.append(dupt)

# ── Section 4: RLS Security ──
story.append(Paragraph('4. RLS Security Analysis (Phase 3)', styles['SectionTitle']))
story.append(Paragraph('4.1 Critical Vulnerability: raw_user_meta_data in RLS Policies', styles['SubSection']))
story.append(Paragraph(
    'A critical security vulnerability exists in the RLS policies: 97 references to raw_user_meta_data '
    'across 5 original migration files use the client-spoofable pattern raw_user_meta_data->>\'role\'. '
    'This pattern is insecure because auth.users metadata can be set by the client during signup, allowing '
    'any user to claim any role (including super_admin) by simply setting their metadata. The vulnerability '
    'affects RLS policies across the CCMS, marketplace, super admin, and final production schemas.',
    styles['BodyText2']
))

rls_data = [
    [Paragraph('Migration File', styles['TableHeader']),
     Paragraph('References', styles['TableHeader']),
     Paragraph('Severity', styles['TableHeader'])],
    [Paragraph('ccms_enterprise_schema.sql', styles['TableCell']),
     Paragraph('61', styles['TableCell']),
     Paragraph('CRITICAL', styles['TableCell'])],
    [Paragraph('super_admin_schema.sql', styles['TableCell']),
     Paragraph('17', styles['TableCell']),
     Paragraph('CRITICAL', styles['TableCell'])],
    [Paragraph('final_production_schema.sql', styles['TableCell']),
     Paragraph('14', styles['TableCell']),
     Paragraph('CRITICAL', styles['TableCell'])],
    [Paragraph('marketplace_schema.sql', styles['TableCell']),
     Paragraph('2', styles['TableCell']),
     Paragraph('HIGH', styles['TableCell'])],
    [Paragraph('enterprise_security_hardening.sql', styles['TableCell']),
     Paragraph('3', styles['TableCell']),
     Paragraph('LOW (in comments/fix)', styles['TableCell'])],
]
rlst = Table(rls_data, colWidths=[7*cm, 2.5*cm, 6*cm])
rlst.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 8),
    ('ALIGN', (1, 0), (2, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('BACKGROUND', (2, 1), (2, 3), HexColor('#ffebee')),
    ('BACKGROUND', (2, 4), (2, 4), HexColor('#fff3e0')),
    ('BACKGROUND', (2, 5), (2, 5), HexColor('#e8f5e9')),
]))
story.append(rlst)

story.append(Paragraph('4.2 Remediation: rls_raw_meta_fix.sql', styles['SubSection']))
story.append(Paragraph(
    'The rls_raw_meta_fix.sql file (714 lines) is designed to remediate this vulnerability by: (1) ensuring '
    'the get_user_role() and get_user_school_id() SECURITY DEFINER functions exist, which read from the '
    'server-authoritative public.users table instead of client-spoofable metadata; (2) enabling ROW LEVEL '
    'SECURITY on 91 tables that have policies but lack RLS enforcement; (3) dropping and recreating 108 '
    'policies that use raw_user_meta_data with get_user_role() instead; and (4) including a verification '
    'query to confirm no raw_user_meta_data references remain. Additionally, the rls_role_fix.sql file '
    '(263 lines) adds the missing parent role to the user_role enum and creates 18 corrected policies. '
    'The enterprise_security_hardening.sql file also provides the process_refund_atomic() function for '
    'race-condition-safe refund processing with SELECT FOR UPDATE row locking.',
    styles['BodyText2']
))

story.append(Paragraph(
    'STATUS: These fix files exist in the local codebase but have NOT been verified as applied to the live '
    'database. This is a BLOCKER for production certification.',
    styles['StatusBlock']
))

# ── Section 5: Edge Functions ──
story.append(Paragraph('5. Edge Functions Audit (Phase 4)', styles['SectionTitle']))
story.append(Paragraph('5.1 Shared Utility Integration', styles['SubSection']))
story.append(Paragraph(
    'All 13 Edge Functions import from the shared utilities (_shared/cors.ts, _shared/security_headers.ts, '
    '_shared/rate_limiter.ts). The _shared/auth.ts module providing validateAuth(), hasRole(), isSuperAdmin(), '
    'and isAdmin() is imported by 9 of the 13 functions. The remaining 4 functions use appropriate alternative '
    'authentication mechanisms: ai-complete and ai-stream use inline JWT validation via Supabase getUser(); '
    'flutterwave-webhook uses constant-time signature verification (correct for webhooks); and health-check '
    'uses optional authentication with service-role bypass for internal monitoring.',
    styles['BodyText2']
))

ef_data = [
    [Paragraph('Function', styles['TableHeader']),
     Paragraph('Auth', styles['TableHeader']),
     Paragraph('CORS', styles['TableHeader']),
     Paragraph('SecHdr', styles['TableHeader']),
     Paragraph('RateLmt', styles['TableHeader']),
     Paragraph('Notes', styles['TableHeader'])],
    [Paragraph('ai-complete', styles['TableCell']),
     Paragraph('inline', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('JWT + model allow-list', styles['TableCell'])],
    [Paragraph('ai-stream', styles['TableCell']),
     Paragraph('inline', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('JWT + streaming', styles['TableCell'])],
    [Paragraph('exam-timing', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('', styles['TableCell'])],
    [Paragraph('flutterwave-checkout', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Payment initiation', styles['TableCell'])],
    [Paragraph('flutterwave-verify', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Transaction verification', styles['TableCell'])],
    [Paragraph('flutterwave-webhook', styles['TableCell']),
     Paragraph('sig', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Constant-time sig verify', styles['TableCell'])],
    [Paragraph('health-check', styles['TableCell']),
     Paragraph('opt', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Service-role bypass', styles['TableCell'])],
    [Paragraph('marketplace-download', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('', styles['TableCell'])],
    [Paragraph('payment-operations', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('', styles['TableCell'])],
    [Paragraph('process-refund', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Atomic refund', styles['TableCell'])],
    [Paragraph('flutterwave-create-plan', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Subscription plan', styles['TableCell'])],
    [Paragraph('flutterwave-subscribe-plan', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Subscription', styles['TableCell'])],
    [Paragraph('flutterwave-transaction-fee', styles['TableCell']),
     Paragraph('shared', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Y', styles['TableCell']),
     Paragraph('Fee calculation', styles['TableCell'])],
]
eft = Table(ef_data, colWidths=[3.5*cm, 1.5*cm, 1.2*cm, 1.2*cm, 1.2*cm, 7*cm])
eft.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 7),
    ('ALIGN', (1, 0), (4, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 2),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, HexColor('#f8f9fa')]),
]))
story.append(eft)

story.append(Paragraph('5.2 Webhook Security Fix (Critical)', styles['SubSection']))
story.append(Paragraph(
    'The flutterwave-webhook function contains a critical security fix for the constantTimeEquals() function. '
    'The original implementation had a critical bug: when a.length !== b.length, it reassigned b = a, making '
    'the comparison a-vs-a (always true) AND making the final length check always true since b was overwritten. '
    'This allowed ANY webhook with a hash of different length than the secret to ALWAYS pass signature '
    'verification, constituting a complete bypass. The fix captures the length-match result BEFORE any '
    'processing and uses 0xFF padding for out-of-bounds indices to ensure different-length inputs always '
    'produce a non-zero XOR accumulator. The webhook function also implements idempotency checking, amount '
    'verification, currency verification, integrity hash verification, and replay detection.',
    styles['BodyText2']
))

# ── Section 6: Flutterwave ──
story.append(Paragraph('6. Flutterwave Payment Integration (Phase 5)', styles['SectionTitle']))
story.append(Paragraph(
    'The Flutterwave payment integration is implemented across 6 Edge Functions: flutterwave-checkout, '
    'flutterwave-verify, flutterwave-webhook, flutterwave-create-plan, flutterwave-subscribe-plan, and '
    'flutterwave-transaction-fee. The FLUTTERWAVE_SECRET_KEY has been provided and configured. However, '
    'the FLUTTERWAVE_WEBHOOK_SECRET_HASH has NOT been configured in the Supabase Edge Function environment '
    'variables. Without this secret, the webhook function will return a 500 Server Misconfigured error when '
    'receiving webhook events from Flutterwave, as it explicitly checks for the presence of this environment '
    'variable and fails if it is not set.',
    styles['BodyText2']
))
story.append(Paragraph(
    'BLOCKER: FLUTTERWAVE_WEBHOOK_SECRET_HASH not configured. This must be set in the Supabase Dashboard '
    'under Edge Functions environment variables before production deployment.',
    styles['StatusFail']
))

# ── Section 7: Critical Blockers ──
story.append(Paragraph('7. Critical Blockers for Production Certification', styles['SectionTitle']))

blocker_data = [
    [Paragraph('#', styles['TableHeader']),
     Paragraph('Blocker', styles['TableHeader']),
     Paragraph('Impact', styles['TableHeader']),
     Paragraph('Resolution', styles['TableHeader'])],
    [Paragraph('1', styles['TableCell']),
     Paragraph('No Supabase access token (sbp_...)', styles['TableCell']),
     Paragraph('Cannot verify migrations, RLS, Edge Functions, Storage, or deploy', styles['TableCell']),
     Paragraph('Generate token at supabase.com/dashboard/account/tokens', styles['TableCell'])],
    [Paragraph('2', styles['TableCell']),
     Paragraph('FLUTTERWAVE_WEBHOOK_SECRET_HASH not configured', styles['TableCell']),
     Paragraph('Webhook verification fails in production', styles['TableCell']),
     Paragraph('Set in Supabase Dashboard Edge Functions env vars', styles['TableCell'])],
    [Paragraph('3', styles['TableCell']),
     Paragraph('rls_raw_meta_fix.sql not verified as applied', styles['TableCell']),
     Paragraph('97 RLS policies use client-spoofable raw_user_meta_data', styles['TableCell']),
     Paragraph('Apply migration to live database and verify', styles['TableCell'])],
    [Paragraph('4', styles['TableCell']),
     Paragraph('rls_role_fix.sql not verified as applied', styles['TableCell']),
     Paragraph('Missing parent role, incorrect policies', styles['TableCell']),
     Paragraph('Apply migration to live database and verify', styles['TableCell'])],
    [Paragraph('5', styles['TableCell']),
     Paragraph('Edge Functions not verified as deployed', styles['TableCell']),
     Paragraph('Cannot test endpoints in production', styles['TableCell']),
     Paragraph('Deploy via supabase functions deploy', styles['TableCell'])],
    [Paragraph('6', styles['TableCell']),
     Paragraph('Storage buckets not verified', styles['TableCell']),
     Paragraph('Cannot verify upload/download/permissions', styles['TableCell']),
     Paragraph('Verify via Supabase Dashboard or CLI', styles['TableCell'])],
    [Paragraph('7', styles['TableCell']),
     Paragraph('No Android APK/App Bundle build', styles['TableCell']),
     Paragraph('Certification condition 14-15 unmet', styles['TableCell']),
     Paragraph('Build with flutter build apk/appbundle', styles['TableCell'])],
]
bt = Table(blocker_data, colWidths=[0.8*cm, 5*cm, 4.5*cm, 5.2*cm])
bt.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 7),
    ('ALIGN', (0, 0), (0, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, HexColor('#f8f9fa')]),
]))
story.append(bt)

# ── Section 8: Certification Status ──
story.append(Paragraph('8. Production Certification Status (Phase 13)', styles['SectionTitle']))
story.append(Paragraph(
    'The following table presents the status of each of the 15 certification conditions required for '
    'PRODUCTION READY status. A condition can only be marked as PASS if backed by runtime evidence from '
    'the live Supabase environment. Conditions marked as BLOCKED require live database access or '
    'environment configuration that cannot be performed from this audit session.',
    styles['BodyText2']
))

cert_data = [
    [Paragraph('#', styles['TableHeader']),
     Paragraph('Condition', styles['TableHeader']),
     Paragraph('Status', styles['TableHeader']),
     Paragraph('Evidence', styles['TableHeader'])],
    [Paragraph('1', styles['TableCell']),
     Paragraph('SQL Migrations Applied', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('No Supabase access token', styles['TableCell'])],
    [Paragraph('2', styles['TableCell']),
     Paragraph('RLS Enabled on All Tables', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot verify live DB', styles['TableCell'])],
    [Paragraph('3', styles['TableCell']),
     Paragraph('No raw_user_meta_data in RLS', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Fix file exists, not verified applied', styles['TableCell'])],
    [Paragraph('4', styles['TableCell']),
     Paragraph('Edge Functions Deployed', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot deploy without access token', styles['TableCell'])],
    [Paragraph('5', styles['TableCell']),
     Paragraph('Security Headers on All Endpoints', styles['TableCell']),
     Paragraph('PASS (code)', styles['TableCell']),
     Paragraph('All 13 functions import security_headers.ts', styles['TableCell'])],
    [Paragraph('6', styles['TableCell']),
     Paragraph('Rate Limiting on All Endpoints', styles['TableCell']),
     Paragraph('PASS (code)', styles['TableCell']),
     Paragraph('All 13 functions import rate_limiter.ts', styles['TableCell'])],
    [Paragraph('7', styles['TableCell']),
     Paragraph('Flutterwave Webhook Verification', styles['TableCell']),
     Paragraph('FAIL', styles['TableCell']),
     Paragraph('WEBHOOK_SECRET_HASH not configured', styles['TableCell'])],
    [Paragraph('8', styles['TableCell']),
     Paragraph('Live Payment Test', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot test without deployment', styles['TableCell'])],
    [Paragraph('9', styles['TableCell']),
     Paragraph('Storage Verification', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot verify buckets/policies', styles['TableCell'])],
    [Paragraph('10', styles['TableCell']),
     Paragraph('Realtime Verification', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot verify channels/presence', styles['TableCell'])],
    [Paragraph('11', styles['TableCell']),
     Paragraph('Notifications Verification', styles['TableCell']),
     Paragraph('BLOCKED', styles['TableCell']),
     Paragraph('Cannot verify notification delivery', styles['TableCell'])],
    [Paragraph('12', styles['TableCell']),
     Paragraph('flutter analyze = 0 issues', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('No issues found! (ran in 7.4s)', styles['TableCell'])],
    [Paragraph('13', styles['TableCell']),
     Paragraph('flutter test = 100%', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('144/144 All tests passed!', styles['TableCell'])],
    [Paragraph('14', styles['TableCell']),
     Paragraph('flutter build web --release', styles['TableCell']),
     Paragraph('PASS', styles['TableCell']),
     Paragraph('Built build/web (65.3s)', styles['TableCell'])],
    [Paragraph('15', styles['TableCell']),
     Paragraph('No Critical Vulnerabilities', styles['TableCell']),
     Paragraph('FAIL', styles['TableCell']),
     Paragraph('97 raw_user_meta_data refs; webhook secret missing', styles['TableCell'])],
]
ct = Table(cert_data, colWidths=[0.8*cm, 5*cm, 2*cm, 7.7*cm])
ct.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
    ('FONTSIZE', (0, 0), (-1, -1), 7),
    ('ALIGN', (0, 0), (0, -1), 'CENTER'),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    # PASS rows - green
    ('BACKGROUND', (2, 5), (2, 5), HexColor('#e8f5e9')),
    ('BACKGROUND', (2, 6), (2, 6), HexColor('#e8f5e9')),
    ('BACKGROUND', (2, 12), (2, 12), HexColor('#e8f5e9')),
    ('BACKGROUND', (2, 13), (2, 13), HexColor('#e8f5e9')),
    ('BACKGROUND', (2, 14), (2, 14), HexColor('#e8f5e9')),
    # FAIL rows - red
    ('BACKGROUND', (2, 7), (2, 7), HexColor('#ffebee')),
    ('BACKGROUND', (2, 15), (2, 15), HexColor('#ffebee')),
    # BLOCKED rows - yellow
    ('BACKGROUND', (2, 1), (2, 4), HexColor('#fff8e1')),
    ('BACKGROUND', (2, 8), (2, 11), HexColor('#fff8e1')),
]))
story.append(ct)

story.append(Spacer(1, 0.5*cm))
story.append(Paragraph(
    'CERTIFICATION RESULT: NOT PRODUCTION READY. Of the 15 certification conditions, 4 pass with runtime '
    'evidence (flutter analyze, flutter test, flutter build web, security headers/rate limiting in code), '
    '2 fail (Flutterwave webhook secret not configured, critical vulnerabilities in RLS), and 9 are blocked '
    'by the inability to connect to the live Supabase project. Production certification requires resolution '
    'of all 7 blockers listed in Section 7, followed by a complete re-audit with live database access.',
    styles['StatusFail']
))

# ── Section 9: Recommendations ──
story.append(Paragraph('9. Immediate Action Items', styles['SectionTitle']))
story.append(Paragraph(
    'The following actions are required in priority order to advance toward production certification. '
    'Each action item includes a specific resolution path and the expected outcome once completed.',
    styles['BodyText2']
))

recs = [
    ('1. Provide Supabase Access Token', 
     'Generate a Supabase access token at https://supabase.com/dashboard/account/tokens. This token '
     '(format: sbp_...) is required for the Supabase CLI to connect to the live project, deploy Edge '
     'Functions, run migrations, and verify RLS policies. Without this token, Phases 1-12 cannot be '
     'completed. The GitHub PAT (ghp_...) provided earlier is for repository access only and cannot '
     'authenticate with the Supabase Management API.'),
    ('2. Configure FLUTTERWAVE_WEBHOOK_SECRET_HASH',
     'Log into the Flutterwave Dashboard, navigate to Settings then Webhooks, and copy the Secret Hash. '
     'Then add it as an environment variable in the Supabase Dashboard under Edge Functions settings with '
     'the key FLUTTERWAVE_WEBHOOK_SECRET_HASH. This is required for the webhook function to verify '
     'incoming webhook events from Flutterwave. Without it, the function returns a 500 error on every '
     'webhook call.'),
    ('3. Apply rls_raw_meta_fix.sql and rls_role_fix.sql',
     'Execute both migration files against the live Supabase database. The rls_raw_meta_fix.sql file '
     'enables RLS on 91 tables and replaces 108 policies that use the client-spoofable '
     'raw_user_meta_data pattern with the server-authoritative get_user_role() function. The '
     'rls_role_fix.sql file adds the missing parent role to the user_role enum and creates 18 '
     'corrected policies. After application, run the verification query in the fix file to confirm '
     'zero raw_user_meta_data references remain in RLS policies.'),
    ('4. Deploy All 13 Edge Functions',
     'Deploy all Edge Functions using the Supabase CLI: supabase functions deploy <function-name> for '
     'each function. Verify deployment by checking the Supabase Dashboard and testing each endpoint '
     'with authenticated requests. The ai-complete and ai-stream functions require OPENAI_API_KEY and '
     'GEMINI_API_KEY environment variables respectively.'),
    ('5. Verify Storage Buckets and Policies',
     'Verify that all required storage buckets exist (exam-papers, avatars, school-logos, marketplace-content, '
     'etc.) and that bucket policies and object policies are correctly configured. Test upload, download, '
     'signed URL generation, and deletion with both authenticated and unauthenticated requests.'),
    ('6. Build Android APK and App Bundle',
     'Run flutter build apk and flutter build appbundle to generate Android builds. These are required '
     'for certification conditions 14 and 15. The Flutter SDK is available at /home/z/flutter/bin/flutter.'),
]
for title, desc in recs:
    story.append(Paragraph(title, styles['SubSection']))
    story.append(Paragraph(desc, styles['BodyText2']))

# ── Build ──
doc.build(story)
print(f'PDF generated: {OUTPUT_PATH}')
print(f'File size: {os.path.getsize(OUTPUT_PATH):,} bytes')
