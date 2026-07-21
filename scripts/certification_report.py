#!/usr/bin/env python3
"""
ExamForge AI — Final Enterprise Certification Report
Independent Production Readiness Assessment
Generated via ReportLab
"""

import os
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm, inch
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, Image
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# ─── FONT REGISTRATION ─────────────────────────────────────────────────
FONT_DIR = '/usr/share/fonts'
pdfmetrics.registerFont(TTFont('Inter', f'{FONT_DIR}/truetype/dejavu/DejaVuSans.ttf'))
pdfmetrics.registerFont(TTFont('Inter-Bold', f'{FONT_DIR}/truetype/dejavu/DejaVuSans-Bold.ttf'))
# No Oblique available - use Mono Oblique as italic fallback
pdfmetrics.registerFont(TTFont('Inter-Italic', f'{FONT_DIR}/truetype/dejavu/DejaVuSansMono-Oblique.ttf'))
registerFontFamily('Inter', normal='Inter', bold='Inter-Bold', italic='Inter-Italic')

# NotoSansSC is a variable font - skip CJK registration for this report
# registerFontFamily('SansSC', normal='SansSC', bold='SansSC-Bold')

# ─── PALETTE (Cascade-generated) ────────────────────────────────────────
PAGE_BG       = colors.HexColor('#f4f5f5')
SECTION_BG    = colors.HexColor('#e7e9ea')
CARD_BG       = colors.HexColor('#eaeeef')
TABLE_STRIPE  = colors.HexColor('#f0f2f3')
HEADER_FILL   = colors.HexColor('#3d5561')
COVER_BLOCK   = colors.HexColor('#4d616a')
BORDER        = colors.HexColor('#b0bec5')
ICON          = colors.HexColor('#3f6679')
ACCENT        = colors.HexColor('#28698a')
ACCENT_2      = colors.HexColor('#c8785d')
TEXT_PRIMARY   = colors.HexColor('#222426')
TEXT_MUTED     = colors.HexColor('#848a8e')
SEM_SUCCESS   = colors.HexColor('#479862')
SEM_WARNING   = colors.HexColor('#967d4d')
SEM_ERROR     = colors.HexColor('#ac574f')
SEM_INFO      = colors.HexColor('#557ca2')

# ─── PAGE SETUP ────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
LEFT_MARGIN = 2.2 * cm
RIGHT_MARGIN = 2.2 * cm
TOP_MARGIN = 2.5 * cm
BOTTOM_MARGIN = 2.5 * cm
CONTENT_W = PAGE_W - LEFT_MARGIN - RIGHT_MARGIN

# ─── STYLES ─────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

s_title = ParagraphStyle('Title', fontName='Inter-Bold', fontSize=22, leading=28,
                          textColor=TEXT_PRIMARY, spaceAfter=6, alignment=TA_LEFT)
s_h1 = ParagraphStyle('H1', fontName='Inter-Bold', fontSize=17, leading=22,
                       textColor=ACCENT, spaceBefore=18, spaceAfter=8)
s_h2 = ParagraphStyle('H2', fontName='Inter-Bold', fontSize=13, leading=17,
                       textColor=HEADER_FILL, spaceBefore=14, spaceAfter=6)
s_h3 = ParagraphStyle('H3', fontName='Inter-Bold', fontSize=11, leading=14,
                       textColor=ICON, spaceBefore=10, spaceAfter=4)
s_body = ParagraphStyle('Body', fontName='Inter', fontSize=9.5, leading=14,
                         textColor=TEXT_PRIMARY, spaceAfter=6, alignment=TA_JUSTIFY)
s_body_sm = ParagraphStyle('BodySm', fontName='Inter', fontSize=8.5, leading=12,
                            textColor=TEXT_PRIMARY, spaceAfter=4, alignment=TA_JUSTIFY)
s_caption = ParagraphStyle('Caption', fontName='Inter-Italic', fontSize=8, leading=11,
                            textColor=TEXT_MUTED, spaceAfter=4)
s_label = ParagraphStyle('Label', fontName='Inter-Bold', fontSize=9, leading=12,
                          textColor=TEXT_PRIMARY, spaceAfter=2)
s_score = ParagraphStyle('Score', fontName='Inter-Bold', fontSize=28, leading=32,
                          textColor=ACCENT, alignment=TA_CENTER)
s_score_label = ParagraphStyle('ScoreLabel', fontName='Inter', fontSize=9, leading=12,
                                textColor=TEXT_MUTED, alignment=TA_CENTER)
s_bullet = ParagraphStyle('Bullet', fontName='Inter', fontSize=9.5, leading=14,
                           textColor=TEXT_PRIMARY, spaceAfter=3, leftIndent=16,
                           bulletIndent=4, alignment=TA_LEFT)
s_critical = ParagraphStyle('Critical', fontName='Inter-Bold', fontSize=9.5, leading=14,
                             textColor=SEM_ERROR, spaceAfter=3)
s_warning = ParagraphStyle('Warning', fontName='Inter-Bold', fontSize=9.5, leading=14,
                            textColor=SEM_WARNING, spaceAfter=3)
s_success = ParagraphStyle('Success', fontName='Inter-Bold', fontSize=9.5, leading=14,
                            textColor=SEM_SUCCESS, spaceAfter=3)
s_toc = ParagraphStyle('TOC', fontName='Inter', fontSize=10, leading=16,
                        textColor=TEXT_PRIMARY, spaceAfter=2)
s_toc_h = ParagraphStyle('TOCH', fontName='Inter-Bold', fontSize=10, leading=16,
                          textColor=ACCENT, spaceAfter=2)

# ─── HELPER FUNCTIONS ───────────────────────────────────────────────────
def hr():
    return HRFlowable(width="100%", thickness=0.5, color=BORDER, spaceAfter=8, spaceBefore=4)

def sp(h=6):
    return Spacer(1, h)

def p(text, style=s_body):
    return Paragraph(text, style)

def bullet(text):
    return Paragraph(f"<bullet>&bull;</bullet> {text}", s_bullet)

def make_score_card(title, score, max_score=100, width=None):
    """Create a score card table."""
    w = width or CONTENT_W / 3 - 8
    pct = score / max_score
    if pct >= 0.75:
        bar_color = SEM_SUCCESS
        verdict = "Strong"
    elif pct >= 0.50:
        bar_color = SEM_WARNING
        verdict = "Adequate"
    elif pct >= 0.30:
        bar_color = colors.HexColor('#d48a3c')
        verdict = "Weak"
    else:
        bar_color = SEM_ERROR
        verdict = "Critical"

    data = [
        [Paragraph(f"<b>{title}</b>", ParagraphStyle('sc_title', fontName='Inter-Bold',
                  fontSize=9, leading=12, textColor=TEXT_PRIMARY, alignment=TA_CENTER))],
        [Paragraph(f"{score}", ParagraphStyle('sc_num', fontName='Inter-Bold',
                  fontSize=24, leading=28, textColor=bar_color, alignment=TA_CENTER))],
        [Paragraph(f"/ {max_score} — {verdict}", ParagraphStyle('sc_ver', fontName='Inter',
                  fontSize=8, leading=10, textColor=TEXT_MUTED, alignment=TA_CENTER))],
    ]
    t = Table(data, colWidths=[w])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, 0), CARD_BG),
        ('BACKGROUND', (0, 1), (0, 2), colors.white),
        ('BOX', (0, 0), (-1, -1), 0.5, BORDER),
        ('TOPPADDING', (0, 0), (0, 0), 6),
        ('BOTTOMPADDING', (0, 0), (0, 0), 4),
        ('TOPPADDING', (0, 1), (0, 1), 8),
        ('BOTTOMPADDING', (0, 1), (0, 1), 2),
        ('TOPPADDING', (0, 2), (0, 2), 2),
        ('BOTTOMPADDING', (0, 2), (0, 2), 6),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ]))
    return t

def make_risk_table(risks, col_widths=None):
    """Create a risk register table."""
    cw = col_widths or [1.8*cm, 3.5*cm, 5.5*cm, 1.5*cm, 1.5*cm, 3.2*cm]
    header = [
        Paragraph("<b>ID</b>", s_label),
        Paragraph("<b>Issue</b>", s_label),
        Paragraph("<b>Impact</b>", s_label),
        Paragraph("<b>Severity</b>", s_label),
        Paragraph("<b>Likelihood</b>", s_label),
        Paragraph("<b>Mitigation</b>", s_label),
    ]
    data = [header]
    for r in risks:
        sev_style = s_critical if r[3] in ('Critical', 'High') else (s_warning if r[3] == 'Medium' else s_body_sm)
        row = [
            Paragraph(r[0], s_body_sm),
            Paragraph(r[1], s_body_sm),
            Paragraph(r[2], s_body_sm),
            Paragraph(f"<b>{r[3]}</b>", sev_style),
            Paragraph(r[4], s_body_sm),
            Paragraph(r[5], s_body_sm),
        ]
        data.append(row)

    t = Table(data, colWidths=cw, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Inter-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, 0), 4),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 4),
        ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 1), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            style_cmds.append(('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE))
    t.setStyle(TableStyle(style_cmds))
    return t

# ─── BUILD DOCUMENT ────────────────────────────────────────────────────
OUTPUT_PATH = '/home/z/my-project/download/ExamForge_AI_Enterprise_Certification_Report.pdf'

def add_page_number(canvas, doc):
    """Add page number to each page."""
    page_num = canvas.getPageNumber()
    if page_num > 1:  # Skip cover page
        text = f"ExamForge AI Certification Report — Page {page_num}"
        canvas.saveState()
        canvas.setFont('Inter', 7.5)
        canvas.setFillColor(TEXT_MUTED)
        canvas.drawCentredString(PAGE_W / 2, 1.5 * cm, text)
        canvas.restoreState()

doc = SimpleDocTemplate(
    OUTPUT_PATH,
    pagesize=A4,
    leftMargin=LEFT_MARGIN,
    rightMargin=RIGHT_MARGIN,
    topMargin=TOP_MARGIN,
    bottomMargin=BOTTOM_MARGIN,
    title='ExamForge AI — Final Enterprise Certification Report',
    author='Independent Review Board',
    subject='Production Readiness Certification',
)

story = []

# ═══════════════════════════════════════════════════════════════════════
# COVER PAGE
# ═══════════════════════════════════════════════════════════════════════
story.append(Spacer(1, 3*cm))

# Cover block
cover_data = [
    [Paragraph("INDEPENDENT PRODUCTION READINESS CERTIFICATION", ParagraphStyle(
        'cover_kick', fontName='Inter-Bold', fontSize=10, leading=13,
        textColor=TEXT_MUTED, letterSpacing=2, alignment=TA_CENTER))],
    [Spacer(1, 12)],
    [Paragraph("ExamForge AI", ParagraphStyle(
        'cover_hero', fontName='Inter-Bold', fontSize=38, leading=44,
        textColor=ACCENT, alignment=TA_CENTER))],
    [Paragraph("Final Enterprise Certification Report", ParagraphStyle(
        'cover_sub', fontName='Inter-Bold', fontSize=16, leading=20,
        textColor=HEADER_FILL, alignment=TA_CENTER))],
    [Spacer(1, 20)],
    [hr()],
    [Spacer(1, 10)],
    [Paragraph("Assessment Date: July 2026", ParagraphStyle(
        'cover_meta', fontName='Inter', fontSize=10, leading=14,
        textColor=TEXT_MUTED, alignment=TA_CENTER))],
    [Paragraph("Review Board: Chief Software Architect, Principal Security Engineer,<br/>"
               "Principal Performance Engineer, Principal Flutter Engineer,<br/>"
               "Accessibility Specialist, Principal DevSecOps Engineer,<br/>"
               "QA Director, AI Safety Engineer, Database Architect,<br/>"
               "Product Quality Auditor", ParagraphStyle(
        'cover_board', fontName='Inter', fontSize=9, leading=13,
        textColor=TEXT_MUTED, alignment=TA_CENTER))],
    [Spacer(1, 16)],
    [Paragraph("CONFIDENTIAL — FOR INTERNAL AND INVESTOR REVIEW ONLY", ParagraphStyle(
        'cover_conf', fontName='Inter-Bold', fontSize=8, leading=10,
        textColor=SEM_ERROR, alignment=TA_CENTER))],
]
cover_t = Table(cover_data, colWidths=[CONTENT_W])
cover_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, -1), colors.white),
    ('BOX', (0, 0), (-1, -1), 1, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 0),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ('LEFTPADDING', (0, 0), (-1, -1), 20),
    ('RIGHTPADDING', (0, 0), (-1, -1), 20),
    ('TOPPADDING', (0, 0), (0, 0), 24),
    ('BOTTOMPADDING', (0, -1), (-1, -1), 24),
]))
story.append(cover_t)
story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# TABLE OF CONTENTS
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("Table of Contents", s_title))
story.append(sp(8))
toc_items = [
    ("1", "Executive Summary"),
    ("2", "Category Scores"),
    ("3", "Architecture Review"),
    ("4", "Security Review"),
    ("5", "Performance Review"),
    ("6", "Accessibility and UX Review"),
    ("7", "Infrastructure Review"),
    ("8", "AI Quality Review"),
    ("9", "Code Quality Review"),
    ("10", "Business Readiness Review"),
    ("11", "Documentation Review"),
    ("12", "Production Risk Assessment"),
    ("13", "Launch Strategy"),
    ("14", "Final Certification Decision"),
    ("A", "Risk Register"),
    ("B", "Production Readiness Checklist"),
    ("C", "Technical Debt Register"),
    ("D", "Post-Launch Monitoring Plan"),
]
for num, title in toc_items:
    if num.isdigit():
        story.append(Paragraph(f"<b>{num}.</b>&nbsp;&nbsp;&nbsp;{title}", s_toc_h))
    else:
        story.append(Paragraph(f"&nbsp;&nbsp;&nbsp;&nbsp;<b>Appendix {num}:</b>&nbsp;&nbsp;{title}", s_toc))
story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 1. EXECUTIVE SUMMARY
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("1. Executive Summary", s_title))
story.append(hr())

story.append(p(
    "An independent review board of ten domain experts conducted a comprehensive 12-phase production readiness "
    "assessment of ExamForge AI between June and July 2026. This certification evaluates whether the platform "
    "is genuinely ready for production deployment at scale, based on verified evidence from source code review, "
    "static analysis, and engineering estimation. No benchmark data from live environments was available; all "
    "performance conclusions are based on static code analysis and should be validated with load testing before "
    "deployment decisions are finalized."
))
story.append(p(
    "ExamForge AI is a Nigerian educational SaaS platform built with Flutter + Supabase + Clean Architecture. "
    "It comprises 28 feature modules, approximately 1,100 source files, and supports 6 user roles across "
    "the Nigerian education system from Nursery through University level. The platform is architecturally "
    "well-structured with clear layering, consistent patterns, and thoughtful infrastructure including CI/CD, "
    "Terraform-managed AWS resources, hardened Caddy reverse proxy, and comprehensive operational documentation."
))
story.append(p(
    "The review identified significant strengths: the Clean Architecture pattern is consistently applied, "
    "the Material 3 design system with WCAG-aware color tokens is mature, the security model for payments "
    "(webhook verification, amount validation, refund processing) is robust after recent hardening, and the "
    "operational documentation suite (runbooks, incident playbooks, backup/DR) is remarkably thorough for a "
    "project at this stage. The encryption service has been upgraded from vulnerable XOR to AES-256-GCM, and "
    "the constant-time comparison implementation is now cryptographically sound."
))
story.append(p(
    "However, critical gaps remain. Test coverage is deeply inadequate — only 10 test files exist for a "
    "codebase of 1,100+ source files, and most tests are contract stubs that verify Dart language semantics "
    "rather than actual service behavior. Accessibility is essentially unimplemented at the presentation layer: "
    "zero Semantics widgets exist across all 12+ screen files audited. Internationalization has not been started "
    "despite being critical for a Nigerian market with diverse languages. The admin portal is publicly reachable "
    "without IP allowlisting. Load testing uses only anonymous access, meaning RLS policies are never validated "
    "under load. Several infrastructure scripts contain SQL injection vulnerabilities."
))
story.append(p(
    "<b>Overall Production Readiness Score: 41/100</b>. The platform demonstrates strong architectural foundations "
    "and security hardening progress, but cannot be certified as production-ready until critical gaps in testing, "
    "accessibility, and operational security are resolved."
))

story.append(sp(12))
# Quick score summary table
score_data = [
    [Paragraph("<b>Category</b>", s_label), Paragraph("<b>Score</b>", s_label), Paragraph("<b>Verdict</b>", s_label)],
    [Paragraph("Architecture", s_body_sm), Paragraph("68/100", s_body_sm), Paragraph("Adequate", s_success)],
    [Paragraph("Security", s_body_sm), Paragraph("52/100", s_body_sm), Paragraph("Weak", s_warning)],
    [Paragraph("Performance", s_body_sm), Paragraph("45/100", s_body_sm), Paragraph("Weak", s_warning)],
    [Paragraph("Accessibility", s_body_sm), Paragraph("15/100", s_body_sm), Paragraph("Critical", s_critical)],
    [Paragraph("Infrastructure", s_body_sm), Paragraph("55/100", s_body_sm), Paragraph("Adequate", s_warning)],
    [Paragraph("AI Quality", s_body_sm), Paragraph("50/100", s_body_sm), Paragraph("Weak", s_warning)],
    [Paragraph("Code Quality", s_body_sm), Paragraph("48/100", s_body_sm), Paragraph("Weak", s_warning)],
    [Paragraph("Documentation", s_body_sm), Paragraph("62/100", s_body_sm), Paragraph("Adequate", s_success)],
    [Paragraph("Operational Readiness", s_body_sm), Paragraph("38/100", s_body_sm), Paragraph("Weak", s_critical)],
    [Paragraph("<b>Overall Production Readiness</b>", s_label), Paragraph("<b>41/100</b>", ParagraphStyle('bs', fontName='Inter-Bold', fontSize=9.5, leading=12, textColor=SEM_WARNING)), Paragraph("<b>Not Approved</b>", s_critical)],
]
score_t = Table(score_data, colWidths=[6*cm, 3*cm, 3*cm])
score_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#fff3f0')),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(score_data), 2)]))
story.append(score_t)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 2. CATEGORY SCORES (DETAILED)
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("2. Category Scores", s_title))
story.append(hr())
story.append(p(
    "Each category is scored on a 0-100 scale based on verified findings from source code review. "
    "Scores reflect the gap between the current implementation and production-grade requirements. "
    "The overall score is a weighted average: Security (20%), Architecture (10%), Performance (15%), "
    "Accessibility (10%), Infrastructure (10%), AI Quality (10%), Code Quality (10%), Documentation (5%), "
    "Operational Readiness (10%)."
))

cards = [
    make_score_card("Architecture", 68),
    make_score_card("Security", 52),
    make_score_card("Performance", 45),
]
story.append(sp(8))
card_row = Table([cards], colWidths=[CONTENT_W/3]*3)
card_row.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP')]))
story.append(card_row)

cards2 = [
    make_score_card("Accessibility", 15),
    make_score_card("Infrastructure", 55),
    make_score_card("AI Quality", 50),
]
story.append(sp(6))
card_row2 = Table([cards2], colWidths=[CONTENT_W/3]*3)
card_row2.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP')]))
story.append(card_row2)

cards3 = [
    make_score_card("Code Quality", 48),
    make_score_card("Documentation", 62),
    make_score_card("Operations", 38),
]
story.append(sp(6))
card_row3 = Table([cards3], colWidths=[CONTENT_W/3]*3)
card_row3.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP')]))
story.append(card_row3)

# Overall
story.append(sp(12))
overall_card = make_score_card("OVERALL PRODUCTION READINESS", 41, width=CONTENT_W/2)
overall_row = Table([[overall_card]], colWidths=[CONTENT_W])
overall_row.setStyle(TableStyle([('ALIGN', (0, 0), (-1, -1), 'CENTER')]))
story.append(overall_row)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 3. ARCHITECTURE REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("3. Architecture Review", s_title))
story.append(hr())

story.append(Paragraph("3.1 Score Justification: 68/100", s_h2))
story.append(p(
    "The architecture is the strongest aspect of the ExamForge AI platform. Clean Architecture is consistently "
    "applied across all 28 feature modules, with every module following the data/domain/presentation layer "
    "separation. The domain layer defines abstract repository contracts and single-responsibility use cases, "
    "while the data layer implements concrete repositories, DTOs, and datasources. This separation ensures "
    "business logic is isolated from infrastructure concerns, making the codebase testable in principle "
    "(though not in practice due to the test coverage gap)."
))
story.append(p(
    "The dependency injection system in dependency_injection.dart wires approximately 88 Riverpod providers "
    "for the main app plus 88 additional providers for CCMS, creating a comprehensive but potentially "
    "unwieldy dependency graph. Each provider follows a consistent pattern: datasource, repository "
    "implementation, use cases, and presentation providers. The GoRouter-based navigation system implements "
    "a three-tier guard pipeline (auth, onboarding, role-based) that is well-structured and correct."
))

story.append(Paragraph("3.2 Strengths", s_h2))
story.append(bullet("Consistent Clean Architecture across all 28 feature modules with no layer violations detected"))
story.append(bullet("Well-designed route guard system with proper priority ordering (auth before onboarding before RBAC)"))
story.append(bullet("Result type pattern forces compile-time error handling at domain boundaries"))
story.append(bullet("Feature-first module organization enables independent team development"))
story.append(bullet("Shared widget library (13 components in lib/shared/widgets/) reduces duplication"))

story.append(Paragraph("3.3 Risks", s_h2))
story.append(bullet("<b>Provider lifecycle:</b> ~176 Riverpod providers are all eagerly accessible. No provider "
    "is marked as auto-dispose for memory-intensive resources (AI services, large caches). At 1,000+ schools, "
    "this could cause significant memory pressure on client devices."))
story.append(bullet("<b>Monolithic DI file:</b> dependency_injection.dart is 2,000+ lines. Any modification risks "
    "breaking unrelated features. This should be split into per-feature DI modules."))
story.append(bullet("<b>Role-based routing gaps:</b> The _roleRestrictedRoutes map only restricts dashboard routes. "
    "Feature routes (e.g., /billing, /marketplace) have no role restrictions, meaning any authenticated user "
    "could navigate directly to admin-only screens if they know the URL."))
story.append(bullet("<b>Missing parent role:</b> The UserRole enum defines teacher, student, schoolAdmin, superAdmin "
    "but the database schema supports a parent role. Route guards do not handle parent navigation."))
story.append(bullet("<b>Theme rebuild gap:</b> When a custom seed color is set, ThemeState._rebuildWithSeed() creates "
    "a minimal ThemeData without component themes, breaking the carefully constructed AppTheme styling."))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 4. SECURITY REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("4. Security Review", s_title))
story.append(hr())

story.append(Paragraph("4.1 Score Justification: 52/100", s_h2))
story.append(p(
    "Security has seen significant hardening since the initial audit that scored 18/100. The webhook "
    "signature bypass has been fixed with a proper constant-time comparison implementation that uses "
    "0xFF padding for out-of-bounds indices. The encryption service has been upgraded from XOR to "
    "AES-256-GCM with platform-backed secure key storage. The refund processing edge function implements "
    "comprehensive validation including amount verification, duplicate detection, and authorization checks. "
    "However, several critical gaps remain, and the test coverage for security paths is dangerously thin."
))

story.append(Paragraph("4.2 Verified Findings", s_h2))
story.append(Paragraph("4.2.1 Webhook Security — FIXED", s_h3))
story.append(p(
    "The Flutterwave webhook handler now correctly implements constant-time comparison. The original bug "
    "where variable b was reassigned to a when lengths differed (causing always-true comparison) has been "
    "fixed. The new implementation captures length match before processing, iterates over max length with "
    "0xFF padding, and returns accumulator==0 AND lengthsMatch. The Dart-side ConstantTimeComparison class "
    "in the Flutter app mirrors this logic. Comprehensive tests (237 lines, 20 test cases including timing "
    "analysis) provide high confidence in this fix."
))

story.append(Paragraph("4.2.2 Encryption — UPGRADED", s_h3))
story.append(p(
    "Local data encryption has been upgraded from XOR stream cipher to AES-256-GCM AEAD. The key is "
    "generated using FortunaRandom seeded with platform secure random, stored in platform-backed secure "
    "storage (iOS Keychain, Android Keystore), and a unique nonce is generated per encryption operation. "
    "Encryption failure throws EncryptionFailedException (never stores plaintext). Decryption failure "
    "throws DecryptionFailedException (never returns raw ciphertext). Legacy XOR migration is supported. "
    "However, the encryption service tests (206 lines) contain NO actual encrypt-then-decrypt round-trip "
    "tests, and key rotation is completely untested. The mock secure storage is declared but never used."
))

story.append(Paragraph("4.2.3 Refund Processing — HARDENED", s_h3))
story.append(p(
    "The process-refund edge function implements server-side validation: authentication, authorization "
    "(super_admin or school_admin only), transaction existence verification, amount validation (positive, "
    "not exceeding original, with 10M NGN cap), duplicate refund detection, school-scoped access for "
    "school_admin, and atomic processing via process_refund_atomic() with SELECT FOR UPDATE row locking. "
    "Every refund attempt is audit-logged. However, the payment_security_test.dart (189 lines) contains "
    "only contract stubs that verify Dart language semantics, not actual service behavior. Zero integration "
    "tests exist for the refund flow."
))

story.append(Paragraph("4.3 Remaining Critical Issues", s_h2))
story.append(p("<b>CRITICAL-SEC-1: Integrity hash bypass.</b> The verify_transaction_integrity() function "
    "returns TRUE when p_stored_hash IS NULL. An attacker who nullifies the amount_integrity_hash column "
    "on a transaction bypasses the integrity check entirely. This should return FALSE for any transaction "
    "created after the hardening migration.", s_critical))
story.append(p("<b>CRITICAL-SEC-2: Admin portal publicly reachable.</b> The Caddyfile defines an "
    "admin.examforge.ai server block with no IP allowlist. The admin portal is accessible from any "
    "IP address. While authentication is required, this exposes the admin interface to credential "
    "stuffing and brute-force attacks.", s_critical))
story.append(p("<b>HIGH-SEC-3: SQL injection in deploy.sh.</b> The migration tracking uses direct string "
    "interpolation: WHERE migration_name='${migration_name}'. A crafted migration name could execute "
    "arbitrary SQL on the production database during deployment.", s_warning))
story.append(p("<b>HIGH-SEC-4: POST request retry in API client.</b> The api_client.dart _guard method "
    "retries ALL HTTP methods including POST, despite a comment claiming it only retries idempotent "
    "methods. This could cause duplicate payment transactions or duplicate exam submissions.", s_warning))
story.append(p("<b>HIGH-SEC-5: PII in unencrypted in-memory cache.</b> The DatabasePoolManager caches "
    "raw query results including user data and payment info in an unencrypted in-memory LRU cache for "
    "up to 5 minutes. On a shared or compromised device, this data is accessible.", s_warning))
story.append(p("<b>HIGH-SEC-6: JWT staleness window.</b> Role changes in the database do not take effect "
    "until the user re-authenticates. A demoted user retains elevated access within their session TTL, "
    "which could be hours. The JWT claims are read at login time only.", s_warning))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 5. PERFORMANCE REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("5. Performance Review", s_title))
story.append(hr())

story.append(Paragraph("5.1 Score Justification: 45/100", s_h2))
story.append(p(
    "<b>Disclaimer:</b> No benchmark data from live or staging environments was available for this review. "
    "All performance conclusions are based on static code analysis and engineering estimation. Measured "
    "performance may differ significantly from these estimates. The k6 load testing suite exists but has "
    "not been executed against an actual deployment, and it tests only unauthenticated access."
))

story.append(Paragraph("5.2 Database Performance", s_h2))
story.append(p(
    "The RLS optimization migration (performance_rls_jwt_optimization.sql) addresses the critical N+1 "
    "query problem by replacing subquery-based role/school lookups with JWT claim reads. This is expected "
    "to reduce database load by 40-60% for RLS-heavy queries. Ten composite indexes were added for hot "
    "paths (notifications, audit_log, class_students, student_answers, exam_attempts). The audit_log RLS "
    "policy was rewritten from an unbounded IN subquery to a simple school_id equality check. The "
    "process_refund_atomic() function uses SELECT FOR UPDATE to prevent concurrent refund race conditions."
))
story.append(p(
    "However, several performance concerns remain. The DatabasePoolManager is a singleton with static "
    "mutable state, making it untestable. Its LRU eviction is O(n) linear scan when it should use "
    "LinkedHashMap for O(1). Health check queries reference the webhook_events table which may not "
    "exist in all environments. The pg_cron scheduled jobs for materialized view refreshes (15-minute "
    "intervals for marketplace trending) could cause load spikes at scale."
))

story.append(Paragraph("5.3 Flutter Performance", s_h2))
story.append(p(
    "The PerformanceManager (48.5KB, approximately 1,200 lines) provides a comprehensive optimization "
    "layer: lazy loading with SliverLazyLoader, image optimization via CachedNetworkImage, request batching "
    "with deduplication, memory management with pressure callbacks, data compression, and performance "
    "monitoring. The AI cache service implements LRU eviction, request deduplication within a 5-second "
    "window, token budget enforcement per school, and prompt token optimization. However, the performance "
    "manager is defined but its integration into actual feature modules is unclear from static analysis. "
    "Several large page widgets (billing_dashboard at 1,238 lines, student_portal at 937 lines) may cause "
    "frame drops due to excessive rebuilds."
))

story.append(Paragraph("5.4 AI Performance", s_h2))
story.append(p(
    "The AiCacheService provides intelligent caching with configurable TTL per content type, LRU eviction "
    "at 500 entries, request deduplication, and token budget enforcement ($50/school/month). The "
    "PromptTokenOptimizer reduces prompt size by removing redundant context and excessive examples. The "
    "AiCostEstimator projects costs: at 1,000 schools with 70% cache hit rate, estimated monthly cost is "
    "approximately $40-60 for Gemini Flash. These are estimates only, not measured data. The dual-provider "
    "fallback (Gemini then OpenAI) adds resilience but the fallback latency is unmeasured."
))

story.append(Paragraph("5.5 Offline Sync", s_h2))
story.append(p(
    "The SyncEngine (75KB, approximately 2,000 lines) implements a comprehensive offline-first architecture "
    "with persistent operation queue, priority-based processing, connectivity quality awareness, conflict "
    "detection and resolution, and an OfflineAwareRepository mixin for transparent fallback. This is "
    "architecturally sophisticated but has not been tested under real-world conditions. Conflict resolution "
    "strategies (last-write-wins, merge) need validation with actual concurrent editing scenarios."
))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 6. ACCESSIBILITY AND UX REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("6. Accessibility and UX Review", s_title))
story.append(hr())

story.append(Paragraph("6.1 Score Justification: 15/100", s_h2))
story.append(p(
    "This is the lowest-scoring category and represents a critical gap. While the core infrastructure "
    "exists — an AccessibilityFramework (36KB, with ColorblindMode, AccessibleText, AccessibleButton, "
    "HighContrastTheme, ScreenReaderHelper, FocusTraversalHelper) and a ResponsiveFramework (39KB, with "
    "ScreenBreakpoint, AdaptiveScaffold, AdaptiveGrid, ResponsiveValue) — these are library-level "
    "abstractions that are NOT used in any production screen. Every single presentation file audited "
    "(12+ screens across auth, CBT, billing, student portal, super admin) uses raw Flutter widgets "
    "without the accessible alternatives."
))

story.append(Paragraph("6.2 Verified WCAG 2.2 AA Violations", s_h2))
story.append(p("<b>CRITICAL-A11Y-1: Zero Semantics widgets.</b> No screen file uses Semantics wrappers. "
    "Interactive elements (buttons, checkboxes, icons), informational displays (scores, timers, badges), "
    "and status indicators (connection status, auto-save) are all invisible to screen readers.", s_critical))
story.append(p("<b>CRITICAL-A11Y-2: Touch targets below WCAG minimum.</b> Checkbox widgets use 24x24 "
    "tap targets (WCAG 2.5.8 requires minimum 44x44 CSS pixels). Auth buttons use "
    "MaterialTapTargetSize.shrinkWrap, further reducing tap area. This fails WCAG 2.5.5 (Target Size).", s_critical))
story.append(p("<b>CRITICAL-A11Y-3: No keyboard navigation support.</b> The exam-taking page has no keyboard "
    "shortcuts for question navigation (Previous/Next). The OTP verification page lacks "
    "autofillHints for one-time codes. No focus indicators are visible on interactive elements.", s_critical))
story.append(p("<b>HIGH-A11Y-4: No internationalization.</b> Every string across all 12+ screen files is "
    "hardcoded English. No .arb files, no AppLocalizations, no intl package usage for dates, numbers, or "
    "currency. The Nigerian market includes Yoruba, Hausa, Igbo, and Pidgin speakers. This also fails "
    "WCAG 3.1.1 (Language of Page).", s_warning))
story.append(p("<b>HIGH-A11Y-5: Inconsistent responsive layouts.</b> Auth pages and super admin use responsive "
    "breakpoints. Billing dashboard (1,238 lines) and exam result page use single-column only with no "
    "tablet or desktop adaptation. This fails WCAG 1.4.10 (Reflow) for wide viewports.", s_warning))

story.append(Paragraph("6.3 UX Issues", s_h2))
story.append(bullet("Terms of Service and Privacy Policy links in register_page.dart are styled as links but not clickable"))
story.append(bullet("Social login buttons show 'coming soon' SnackBar instead of being visually disabled or hidden"))
story.append(bullet("Exam take page: onClearAnswer creates updatedAnswers but never uses it (dead code bug)"))
story.append(bullet("Checkout page opens external browser for Flutterwave payment with no guaranteed return"))
story.append(bullet("Question breakdown in exam results is a placeholder: 'Detailed breakdown will be available when results are fully graded and released'"))
story.append(bullet("Student portal quick actions navigate to RouteNames.dashboard for all items (placeholder routing)"))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 7. INFRASTRUCTURE REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("7. Infrastructure Review", s_title))
story.append(hr())

story.append(Paragraph("7.1 Score Justification: 55/100", s_h2))
story.append(p(
    "The infrastructure layer demonstrates significant effort. CI/CD pipelines (ci.yml, deploy.yml, "
    "security-scan.yml, security.yml) implement a 6-stage build process with linting, testing, SCA (Trivy), "
    "secret scanning (Gitleaks), SAST (CodeQL + custom Dart checks), and artifact verification. The deploy "
    "pipeline supports blue-green deployment with manual approval gates for production. Terraform manages "
    "S3 backup buckets with cross-region DR. The Caddyfile implements comprehensive security headers "
    "including CSP, HSTS (2-year + preload), and TLS 1.2-1.3."
))
story.append(p(
    "However, several gaps reduce the score. The Terraform configuration is incomplete: it defines S3 "
    "buckets and CloudWatch log groups but does not manage compute, CDN, DNS, or Supabase resources. "
    "The IAM configuration uses a user with long-lived credentials instead of a role with temporary "
    "credentials. CloudWatch log groups are only created for production (staging gets no centralized "
    "logging). The backup script claims incremental support but actually performs full pg_dump every time "
    "(misleading naming). GPG verification is broken (encrypted-without-signature files cannot be verified "
    "with --verify). The k6 load test suite does not authenticate, meaning RLS policies are never tested "
    "under load."
))

story.append(Paragraph("7.2 Key Findings", s_h2))
story.append(bullet("<b>CI/CD:</b> Comprehensive 6-stage pipeline. Secret scanning and SAST are properly configured. "
    "Coverage threshold is set at only 20% — far below industry standard of 80%."))
story.append(bullet("<b>Terraform:</b> Partial — covers storage and logging but missing compute/CDN/DNS/Supabase. "
    "IAM user (not role) with static keys is a security anti-pattern."))
story.append(bullet("<b>Backup:</b> Comprehensive but broken — 'incremental' is actually full, GPG verify is "
    "non-functional, S3 STANDARD_IA has retrieval delays unsuitable for emergency restore."))
story.append(bullet("<b>Caddy:</b> Well-configured security headers. Admin portal lacks IP allowlist. API subdomain "
    "has no CSP header. Staging has minimal security headers."))
story.append(bullet("<b>Monitoring:</b> pg_cron jobs for materialized view refresh and metrics retention. "
    "No application-level APM, no distributed tracing, no real-time alerting integration."))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 8. AI QUALITY REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("8. AI Quality Review", s_title))
story.append(hr())

story.append(Paragraph("8.1 Score Justification: 50/100", s_h2))
story.append(p(
    "The AI subsystem is architecturally well-designed with defense-in-depth security. The AiSecurityService "
    "(36KB) implements 14 categories of protection: prompt injection detection with extended patterns, "
    "Unicode obfuscation detection, Base64-encoded injection detection, nested injection detection, "
    "Markdown/JSON injection detection, role override detection, system prompt extraction detection, "
    "context leakage detection, output validation, audit logging, rate limiting, content safety filtering, "
    "and token usage tracking. The dual-provider architecture (Gemini primary, OpenAI fallback) provides "
    "resilience, and the AiCacheService implements intelligent caching with cost optimization."
))
story.append(p(
    "However, several concerns remain. The prompt injection patterns are regex-based and can be bypassed "
    "by novel attack vectors (e.g., image-based prompt injection, multi-modal attacks, adversarial "
    "Unicode normalization). The AI output validation engine checks structure and safety but does not "
    "verify factual accuracy or educational quality of generated questions. Hallucination mitigation "
    "relies on output validation rules rather than grounding techniques (retrieval-augmented generation, "
    "citation verification). The token budget of $50/school/month is not enforced server-side — a "
    "compromised client could bypass this limit. Cost estimates are theoretical (not measured), and "
    "the actual cost per school could be significantly higher under heavy usage."
))

story.append(Paragraph("8.2 Key Risks", s_h2))
story.append(bullet("Prompt injection defense is pattern-based, not semantic — novel attack vectors will bypass it"))
story.append(bullet("No hallucination detection: generated questions may contain factually incorrect educational content"))
story.append(bullet("Token budget enforcement is client-side only — not server-authoritative"))
story.append(bullet("No A/B testing framework for prompt quality — prompt changes affect all users immediately"))
story.append(bullet("AI failure handling falls back to cached response or generic error — no graceful degradation for partial results"))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 9. CODE QUALITY REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("9. Code Quality Review", s_title))
story.append(hr())

story.append(Paragraph("9.1 Score Justification: 48/100", s_h2))
story.append(p(
    "Code quality is undermined primarily by the severe test coverage gap and the presence of several "
    "large monolithic files that should be decomposed. The analysis_options.yaml defines 36 linter rules "
    "in strict mode, which is good. The codebase follows consistent naming conventions and documentation "
    "patterns. However, only 10 test files exist for a codebase of 1,100+ source files, and most of "
    "these are contract stubs rather than behavioral tests. Several presentation files exceed 800 lines, "
    "with the billing dashboard reaching 1,238 lines."
))

story.append(Paragraph("9.2 Test Coverage Assessment", s_h2))
story.append(p(
    "The CI pipeline's coverage threshold is set at 20%, already far below industry standards. The actual "
    "coverage is likely well below even this threshold. The test files break down as follows:"
))
test_data = [
    [Paragraph("<b>Test File</b>", s_label), Paragraph("<b>Lines</b>", s_label), Paragraph("<b>Quality</b>", s_label), Paragraph("<b>Verdict</b>", s_label)],
    [Paragraph("constant_time_comparison_test.dart", s_body_sm), Paragraph("237", s_body_sm), Paragraph("Comprehensive", s_success), Paragraph("Gold standard", s_success)],
    [Paragraph("encryption_service_test.dart", s_body_sm), Paragraph("206", s_body_sm), Paragraph("Partial", s_warning), Paragraph("No round-trip tests", s_warning)],
    [Paragraph("payment_security_test.dart", s_body_sm), Paragraph("189", s_body_sm), Paragraph("Contract stubs", s_critical), Paragraph("Zero real tests", s_critical)],
    [Paragraph("auth_security_test.dart", s_body_sm), Paragraph("90", s_body_sm), Paragraph("Minimal", s_critical), Paragraph("Tests Dart, not app", s_critical)],
    [Paragraph("ai_security_service_test.dart", s_body_sm), Paragraph("~150", s_body_sm), Paragraph("Partial", s_warning), Paragraph("Pattern tests only", s_warning)],
    [Paragraph("database_security_test.dart", s_body_sm), Paragraph("~80", s_body_sm), Paragraph("Minimal", s_critical), Paragraph("Contract stubs", s_critical)],
    [Paragraph("session_recovery_test.dart", s_body_sm), Paragraph("~100", s_body_sm), Paragraph("Partial", s_warning), Paragraph("Basic scenarios", s_warning)],
]
test_t = Table(test_data, colWidths=[5.5*cm, 1.5*cm, 2.5*cm, 4*cm])
test_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(test_data), 2)]))
story.append(test_t)

story.append(Paragraph("9.3 Large Files Needing Decomposition", s_h2))
story.append(bullet("billing_dashboard_page.dart — 1,238 lines (should be 5+ sub-widgets)"))
story.append(bullet("student_portal_dashboard_page.dart — 937 lines (should be 4+ sub-widgets)"))
story.append(bullet("exam_take_page.dart — 803 lines (should be 5+ sub-widgets)"))
story.append(bullet("dependency_injection.dart — 2,000+ lines (should be per-feature DI modules)"))
story.append(bullet("ccms_di_registration.dart — 470 lines (should be split by CCMS sub-domain)"))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 10. BUSINESS READINESS REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("10. Business Readiness Review", s_title))
story.append(hr())

story.append(Paragraph("10.1 Subscription and Payment Flow", s_h2))
story.append(p(
    "The billing module (40 files) implements a comprehensive subscription system with Flutterwave "
    "integration, credit-based pricing, coupon codes, license keys, referral programs, and school-level "
    "billing. The checkout page redirects to Flutterwave's hosted payment page, which is the recommended "
    "approach for PCI compliance. However, the checkout flow opens an external browser without guaranteed "
    "return to the application. The transaction reference generation uses DateTime timestamps which could "
    "collide under race conditions. Price validation is absent — a negative total could theoretically be "
    "generated if discount exceeds base price."
))

story.append(Paragraph("10.2 Teacher Workflows", s_h2))
story.append(p(
    "The teacher_workspace module (121 files, the largest in the codebase) provides comprehensive tools: "
    "lesson plans, assignments, worksheets, presentations, rubrics, oral questions, practical assessments, "
    "schemes of work, report comments, resources, tasks, calendar, AI content assistant, and collaboration. "
    "The AI Question Bank (ai_generator module, 33 files) supports document upload, prompt-based generation, "
    "review workflows, and validation. These workflows are architecturally complete but have not been "
    "validated through end-to-end user testing."
))

story.append(Paragraph("10.3 Student Workflows", s_h2))
story.append(p(
    "The CBT exam engine (51 files) provides exam building, templates, timed exams, anti-cheat detection, "
    "session recovery, and auto-save. The student portal (46 files) includes an AI tutor, flashcards, "
    "practice mode, study planner, progress tracking, and document chat. Key gap: the exam results "
    "question breakdown is a placeholder. Quick action routes navigate to a generic dashboard. "
    "Session recovery is implemented in the service layer but the exam_take_page.dart does not show "
    "a visible 'resume after disconnect' dialog."
))

story.append(Paragraph("10.4 Admin Workflows", s_h2))
story.append(p(
    "The super_admin module (20 files) provides dashboards, AI management, billing oversight, "
    "infrastructure monitoring, marketplace management, security center, school/user management, and "
    "support center. The school_management module (76 files) handles CRUD operations for schools, classes, "
    "subjects, students, teachers, parents, attendance, homework, announcements, documents, timetables, "
    "academic sessions, and promotions. These are architecturally complete. However, no end-to-end "
    "workflow testing has been performed, and several admin features may have placeholder implementations "
    "that need verification."
))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 11. DOCUMENTATION REVIEW
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("11. Documentation Review", s_title))
story.append(hr())

story.append(Paragraph("11.1 Score Justification: 62/100", s_h2))
story.append(p(
    "The documentation suite is remarkably thorough for a project at this stage. Eight user-facing guides "
    "cover all major roles (administrator, teacher, student, parent). Seven operations documents cover "
    "deployment, backup/restore, incident response, on-call procedures, monitoring, security operations, "
    "and environment configuration. The API documentation covers 20+ RPC functions, table CRUD operations, "
    "and webhook patterns."
))

story.append(Paragraph("11.2 Documentation Quality Matrix", s_h2))
doc_data = [
    [Paragraph("<b>Document</b>", s_label), Paragraph("<b>Quality</b>", s_label), Paragraph("<b>Gap</b>", s_label)],
    [Paragraph("API Documentation", s_body_sm), Paragraph("Comprehensive", s_success), Paragraph("No realtime/SDK docs; no key rotation docs")],
    [Paragraph("Deployment Guide", s_body_sm), Paragraph("Comprehensive", s_success), Paragraph("Invalid psql --dry-run; incomplete CI/CD section")],
    [Paragraph("On-Call Runbook", s_body_sm), Paragraph("Comprehensive", s_success), Paragraph("Destructive SQL without auth gates")],
    [Paragraph("Incident Response", s_body_sm), Paragraph("Comprehensive", s_success), Paragraph("NDPR timeline incorrect (72h vs 48h)")],
    [Paragraph("Backup/Restore Guide", s_body_sm), Paragraph("Partial", s_warning), Paragraph("No PITR testing; no restore SLA")],
    [Paragraph("Developer Guide", s_body_sm), Paragraph("Partial", s_warning), Paragraph("No onboarding tutorial; no architecture diagram")],
    [Paragraph("Security Operations", s_body_sm), Paragraph("Partial", s_warning), Paragraph("No forensics protocol; incomplete secret list")],
]
doc_t = Table(doc_data, colWidths=[4*cm, 3*cm, 7*cm])
doc_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(doc_data), 2)]))
story.append(doc_t)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 12. PRODUCTION RISK ASSESSMENT
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("12. Production Risk Assessment", s_title))
story.append(hr())

story.append(p(
    "All remaining issues are ranked by severity. For each issue, the impact describes the potential "
    "damage, the likelihood estimates how probable it is in production, and the mitigation describes "
    "the recommended fix with estimated engineering effort."
))

risks = [
    ("R-01", "Integrity hash NULL bypass", "Payment fraud: attacker bypasses amount verification", "Critical", "Medium", "Return FALSE for NULL hashes; backfill existing NULLs"),
    ("R-02", "Zero accessibility compliance", "Legal liability under disability discrimination laws", "Critical", "High", "Implement Semantics, fix touch targets (4-6 weeks)"),
    ("R-03", "No i18n/localization", "Excludes non-English Nigerian users; legal compliance risk", "Critical", "High", "Implement flutter_localizations + .arb files (6-8 weeks)"),
    ("R-04", "Admin portal publicly exposed", "Brute-force and credential stuffing attacks", "Critical", "Medium", "Add IP allowlist in Caddyfile; add WAF rules (2-3 days)"),
    ("R-05", "SQL injection in deploy.sh", "Arbitrary SQL execution during deployment", "Critical", "Low", "Use parameterized queries in migration tracking (1 day)"),
    ("R-06", "POST request retry in API client", "Duplicate payment transactions and exam submissions", "High", "Medium", "Make _guard method-aware; skip POST retries (1 day)"),
    ("R-07", "PII in unencrypted cache", "Data exposure on shared/compromised devices", "High", "Low", "Add cache encryption or exclude PII tables (3-5 days)"),
    ("R-08", "Test coverage near zero", "Unknown bugs in production; no regression safety net", "High", "High", "Achieve 50% coverage on critical paths (8-12 weeks)"),
    ("R-09", "JWT staleness window", "Demoted users retain elevated access for session duration", "High", "Low", "Implement short-lived JWTs + token revocation (5-7 days)"),
    ("R-10", "No RLS load testing", "RLS policies may fail under concurrent load", "High", "Medium", "Add authenticated flows to k6 tests (3-5 days)"),
    ("R-11", "Placeholder UI features", "Broken quick actions, question breakdown, social login", "Medium", "High", "Complete or remove placeholder features (2-3 weeks)"),
    ("R-12", "Large widget files", "Maintenance difficulty; increased rebuild cost", "Medium", "High", "Decompose 800+ line files into sub-widgets (2-3 weeks)"),
    ("R-13", "Incomplete Terraform", "No IaC for compute/CDN/DNS; manual configuration drift", "Medium", "Medium", "Complete Terraform coverage (3-4 weeks)"),
    ("R-14", "Backup verification broken", "Cannot verify backup integrity before restore", "Medium", "Medium", "Fix GPG verification; add SHA256 checksums (2-3 days)"),
    ("R-15", "No application-level APM", "Cannot diagnose production performance issues", "Medium", "Medium", "Integrate OpenTelemetry or similar APM (2-3 weeks)"),
]
story.append(make_risk_table(risks))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 13. LAUNCH STRATEGY
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("13. Launch Strategy", s_title))
story.append(hr())

story.append(p(
    "Based on the evidence-based findings of this review, we recommend a staged rollout plan with "
    "explicit success metrics and rollback criteria at each stage. The plan assumes that Critical "
    "and High-severity blockers (R-01 through R-05) are resolved before Stage 2, and High-severity "
    "issues (R-06 through R-10) are resolved before Stage 4."
))

stages_data = [
    [Paragraph("<b>Stage</b>", s_label), Paragraph("<b>Scope</b>", s_label), Paragraph("<b>Duration</b>", s_label),
     Paragraph("<b>Success Metrics</b>", s_label), Paragraph("<b>Rollback Criteria</b>", s_label)],
    [Paragraph("1. Internal Testing", s_body_sm), Paragraph("Dev team + QA only", s_body_sm), Paragraph("4 weeks", s_body_sm),
     Paragraph("All critical paths tested; 0 P1 bugs; 95% test pass rate", s_body_sm),
     Paragraph("Any P1 bug in payment/auth/encryption", s_body_sm)],
    [Paragraph("2. Pilot (2 Schools)", s_body_sm), Paragraph("2 schools, ~200 users", s_body_sm), Paragraph("6 weeks", s_body_sm),
     Paragraph("NPS > 30; <2% error rate; <5s AI response time; successful payment flow", s_body_sm),
     Paragraph("Any data loss; payment failure >5%; NPS < 0", s_body_sm)],
    [Paragraph("3. Early Adopter (10 Schools)", s_body_sm), Paragraph("10 schools, ~2,000 users", s_body_sm), Paragraph("8 weeks", s_body_sm),
     Paragraph("99% uptime; <3s page load; 70% DAU; 0 security incidents", s_body_sm),
     Paragraph("Uptime <95%; any security breach; >10% payment failures", s_body_sm)],
    [Paragraph("4. Growth (50 Schools)", s_body_sm), Paragraph("50 schools, ~10,000 users", s_body_sm), Paragraph("8 weeks", s_body_sm),
     Paragraph("p95 API <1.5s; <1% error rate; AI cost < $0.05/school/month", s_body_sm),
     Paragraph("p95 API >3s; error rate >5%; cost overrun >2x estimate", s_body_sm)],
    [Paragraph("5. Scale (100 Schools)", s_body_sm), Paragraph("100 schools, ~25,000 users", s_body_sm), Paragraph("12 weeks", s_body_sm),
     Paragraph("All SLOs met; positive unit economics; <3 support tickets/school/month", s_body_sm),
     Paragraph("Any SLO breach sustained >1 week; negative unit economics", s_body_sm)],
    [Paragraph("6. Regional Rollout", s_body_sm), Paragraph("1,000+ schools", s_body_sm), Paragraph("Ongoing", s_body_sm),
     Paragraph("Multi-region deployment; 99.9% uptime; profitable", s_body_sm),
     Paragraph("Major incident affecting >5% of schools", s_body_sm)],
]
stages_t = Table(stages_data, colWidths=[2.5*cm, 2.5*cm, 1.8*cm, 4.5*cm, 4*cm])
stages_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 4),
    ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(stages_data), 2)]))
story.append(stages_t)

story.append(sp(12))
story.append(Paragraph("13.1 Prerequisites Before Any External Launch", s_h2))
story.append(bullet("Fix R-01 (integrity hash NULL bypass) — 1 day"))
story.append(bullet("Fix R-04 (admin portal IP allowlist) — 2-3 days"))
story.append(bullet("Fix R-05 (SQL injection in deploy.sh) — 1 day"))
story.append(bullet("Fix R-06 (POST retry bug) — 1 day"))
story.append(bullet("Achieve minimum 30% test coverage on critical paths (auth, billing, CBT, encryption) — 4 weeks"))
story.append(bullet("Execute authenticated k6 load test suite with at least 100 concurrent users — 3-5 days"))
story.append(bullet("Verify end-to-end payment flow with real Flutterwave sandbox transactions — 3-5 days"))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# 14. FINAL CERTIFICATION DECISION
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("14. Final Certification Decision", s_title))
story.append(hr())

story.append(Paragraph("14.1 Launch Decision by Scale", s_h2))

decision_data = [
    [Paragraph("<b>Scale Target</b>", s_label), Paragraph("<b>Decision</b>", s_label), Paragraph("<b>Evidence</b>", s_label)],
    [Paragraph("10 Schools", s_body_sm),
     Paragraph("<b>Approved with Conditions</b>", s_warning),
     Paragraph("Feasible after resolving R-01 through R-06. Limited scale reduces risk. "
               "Must have: integrity hash fix, admin IP allowlist, POST retry fix, SQL injection fix, "
               "30% test coverage on critical paths, and one successful authenticated load test.", s_body_sm)],
    [Paragraph("100 Schools", s_body_sm),
     Paragraph("<b>Not Approved</b>", s_critical),
     Paragraph("Requires: 50%+ test coverage, complete accessibility compliance (WCAG 2.2 AA), "
               "i18n for major Nigerian languages, application-level APM, completed Terraform IaC, "
               "verified backup restore, and successful 50-school pilot.", s_body_sm)],
    [Paragraph("1,000 Schools", s_body_sm),
     Paragraph("<b>Not Approved</b>", s_critical),
     Paragraph("Requires all 100-school requirements plus: 80%+ test coverage, connection pooling "
               "verification at scale, CDN deployment, multi-region DR testing, automated incident "
               "response, and proven unit economics from 100-school stage.", s_body_sm)],
    [Paragraph("10,000 Schools", s_body_sm),
     Paragraph("<b>Not Approved</b>", s_critical),
     Paragraph("Requires 1,000-school certification plus: horizontal scaling verification, "
               "database sharding/partitioning, multi-tenant isolation verification, regulatory "
               "compliance certification (NDPR/NITDA), and 12 months of operational history.", s_body_sm)],
]
decision_t = Table(decision_data, colWidths=[2.5*cm, 3.5*cm, 9*cm])
decision_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('BACKGROUND', (0, 1), (-1, 1), colors.HexColor('#fff8e1')),
    ('BACKGROUND', (0, 2), (-1, -1), colors.HexColor('#fff3f0')),
    ('TOPPADDING', (0, 0), (-1, -1), 4),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
]))
story.append(decision_t)

story.append(sp(16))
story.append(Paragraph("14.2 Final Recommendation", s_h2))
story.append(sp(4))

# Final verdict box
verdict_data = [
    [Paragraph("<b>APPROVED WITH CONDITIONS</b>", ParagraphStyle('verdict', fontName='Inter-Bold',
              fontSize=16, leading=20, textColor=SEM_WARNING, alignment=TA_CENTER))],
    [Spacer(1, 6)],
    [Paragraph("ExamForge AI may proceed to internal testing and a 2-school pilot AFTER resolving "
               "the five critical blockers identified in this report (R-01 through R-05) and achieving "
               "minimum 30% test coverage on critical paths. The platform demonstrates strong architectural "
               "foundations and meaningful security hardening, but production deployment at scale requires "
               "significant additional investment in testing, accessibility, and operational readiness.", s_body)],
]
verdict_t = Table(verdict_data, colWidths=[CONTENT_W - 20])
verdict_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#fff8e1')),
    ('BOX', (0, 0), (-1, -1), 1.5, SEM_WARNING),
    ('TOPPADDING', (0, 0), (0, 0), 16),
    ('BOTTOMPADDING', (0, -1), (-1, -1), 16),
    ('LEFTPADDING', (0, 0), (-1, -1), 16),
    ('RIGHTPADDING', (0, 0), (-1, -1), 16),
]))
story.append(verdict_t)

story.append(sp(12))
story.append(Paragraph("14.3 Conditions for Approval", s_h2))
story.append(p("The following conditions MUST be met before the 2-school pilot can proceed:"))
story.append(bullet("<b>C-1:</b> Fix integrity hash NULL bypass (R-01) — verify_transaction_integrity() must return FALSE for NULL hashes on post-migration transactions. Estimated effort: 1 day."))
story.append(bullet("<b>C-2:</b> Implement IP allowlist on admin.examforge.ai (R-04) — restrict to known office IPs plus VPN ranges. Estimated effort: 2-3 days."))
story.append(bullet("<b>C-3:</b> Fix SQL injection in deploy.sh migration tracking (R-05) — use parameterized queries. Estimated effort: 1 day."))
story.append(bullet("<b>C-4:</b> Fix POST retry in API client (R-06) — make _guard method-aware and skip POST retries. Estimated effort: 1 day."))
story.append(bullet("<b>C-5:</b> Achieve minimum 30% line coverage on critical paths (auth, billing, CBT, encryption, AI security). Estimated effort: 4 weeks."))
story.append(bullet("<b>C-6:</b> Execute authenticated k6 load test with at least 100 concurrent users and validate RLS policies under load. Estimated effort: 3-5 days."))
story.append(bullet("<b>C-7:</b> Verify end-to-end payment flow with Flutterwave sandbox (real API calls, not mocked). Estimated effort: 3-5 days."))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# APPENDIX A: RISK REGISTER
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("Appendix A: Risk Register", s_title))
story.append(hr())

story.append(p(
    "Complete risk register with all identified issues, categorized by severity, with impact, likelihood, "
    "mitigation strategy, and estimated engineering effort."
))

all_risks = [
    ("R-01", "Integrity hash NULL bypass", "Payment fraud", "Critical", "Medium", "Return FALSE for NULL; backfill", "1 day"),
    ("R-02", "Zero accessibility compliance", "Legal liability", "Critical", "High", "Implement Semantics + touch targets", "4-6 weeks"),
    ("R-03", "No i18n/localization", "Market exclusion", "Critical", "High", "flutter_localizations + .arb", "6-8 weeks"),
    ("R-04", "Admin portal exposed", "Brute-force attacks", "Critical", "Medium", "IP allowlist + WAF", "2-3 days"),
    ("R-05", "SQL injection in deploy.sh", "Arbitrary SQL execution", "Critical", "Low", "Parameterized queries", "1 day"),
    ("R-06", "POST retry bug", "Duplicate transactions", "High", "Medium", "Method-aware retry logic", "1 day"),
    ("R-07", "PII in unencrypted cache", "Data exposure", "High", "Low", "Cache encryption or PII exclusion", "3-5 days"),
    ("R-08", "Test coverage near zero", "Unknown production bugs", "High", "High", "Target 50% on critical paths", "8-12 weeks"),
    ("R-09", "JWT staleness window", "Privilege escalation", "High", "Low", "Short-lived JWTs + revocation", "5-7 days"),
    ("R-10", "No RLS load testing", "RLS failure under load", "High", "Medium", "Authenticated k6 tests", "3-5 days"),
    ("R-11", "Placeholder UI features", "Broken user experience", "Medium", "High", "Complete or remove", "2-3 weeks"),
    ("R-12", "Large widget files", "Maintenance difficulty", "Medium", "High", "Decompose 800+ line files", "2-3 weeks"),
    ("R-13", "Incomplete Terraform", "Configuration drift", "Medium", "Medium", "Complete IaC coverage", "3-4 weeks"),
    ("R-14", "Backup verification broken", "Unreliable restores", "Medium", "Medium", "Fix GPG; add SHA256", "2-3 days"),
    ("R-15", "No application-level APM", "Cannot diagnose perf issues", "Medium", "Medium", "Integrate OpenTelemetry", "2-3 weeks"),
    ("R-16", "CORS allowlist fallback", "Origin header spoofing", "Low", "Low", "Return 403 for unknown origins", "1 day"),
    ("R-17", "Theme rebuild gap", "Broken styling on custom seed", "Low", "Low", "Delegate to AppTheme builder", "2-3 days"),
    ("R-18", "Missing parent role routing", "Parent cannot navigate", "Low", "Medium", "Add parent to UserRole + routes", "3-5 days"),
    ("R-19", "NDPR timeline in docs", "Regulatory non-compliance", "Low", "Medium", "Fix 72h to 48h in playbook", "1 hour"),
    ("R-20", "No feature flag system", "Cannot toggle features per school", "Low", "Medium", "Implement feature flags", "2-3 weeks"),
]

reg_data = [
    [Paragraph("<b>ID</b>", s_label), Paragraph("<b>Issue</b>", s_label), Paragraph("<b>Impact</b>", s_label),
     Paragraph("<b>Sev</b>", s_label), Paragraph("<b>Lik</b>", s_label),
     Paragraph("<b>Mitigation</b>", s_label), Paragraph("<b>Effort</b>", s_label)],
]
for r in all_risks:
    sev_s = s_critical if r[3] == 'Critical' else (s_warning if r[3] in ('High',) else s_body_sm)
    reg_data.append([
        Paragraph(r[0], s_body_sm), Paragraph(r[1], s_body_sm), Paragraph(r[2], s_body_sm),
        Paragraph(f"<b>{r[3]}</b>", sev_s), Paragraph(r[4], s_body_sm),
        Paragraph(r[5], s_body_sm), Paragraph(r[6], s_body_sm),
    ])
reg_t = Table(reg_data, colWidths=[1.2*cm, 3*cm, 2.5*cm, 1.2*cm, 1.2*cm, 4*cm, 1.5*cm])
reg_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 2),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ('LEFTPADDING', (0, 0), (-1, -1), 3),
    ('RIGHTPADDING', (0, 0), (-1, -1), 3),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('FONTSIZE', (0, 0), (-1, -1), 7),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(reg_data), 2)]))
story.append(reg_t)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# APPENDIX B: PRODUCTION READINESS CHECKLIST
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("Appendix B: Production Readiness Checklist", s_title))
story.append(hr())

checklist = [
    ("Security", [
        ("Webhook signature verification", True, "Fixed and tested"),
        ("AES-256-GCM encryption", True, "Implemented but untested round-trip"),
        ("Refund validation", True, "Comprehensive edge function"),
        ("Constant-time comparison", True, "Gold standard tests"),
        ("Integrity hash NULL bypass", False, "Returns TRUE for NULL hashes"),
        ("Admin portal IP allowlist", False, "Publicly reachable"),
        ("SQL injection in deploy.sh", False, "String interpolation in SQL"),
        ("POST retry bug", False, "All methods retried"),
        ("PII in unencrypted cache", False, "In-memory LRU stores raw data"),
        ("JWT staleness window", False, "Role changes not reflected until re-auth"),
    ]),
    ("Testing", [
        ("Unit test coverage > 30%", False, "Only 10 test files for 1,100+ source files"),
        ("Security path testing", False, "Most tests are contract stubs"),
        ("Encryption round-trip tests", False, "No encrypt-decrypt verification"),
        ("Refund integration tests", False, "No real service instantiation"),
        ("Load testing (authenticated)", False, "k6 tests use ANON_KEY only"),
        ("End-to-end payment test", False, "No Flutterwave sandbox verification"),
    ]),
    ("Accessibility", [
        ("WCAG 2.2 AA compliance", False, "Zero Semantics widgets"),
        ("Touch target sizes >= 44px", False, "24x24 checkboxes, shrinkWrap buttons"),
        ("Screen reader support", False, "No semantic labels on any screen"),
        ("Keyboard navigation", False, "No shortcuts in exam-taking"),
        ("i18n/localization", False, "All strings hardcoded English"),
    ]),
    ("Infrastructure", [
        ("CI/CD pipeline", True, "6-stage pipeline with security gates"),
        ("Blue-green deployment", True, "Implemented in deploy.sh"),
        ("Backup and DR", True, "Cross-region S3 with GPG encryption"),
        ("Security headers (Caddy)", True, "CSP, HSTS, TLS 1.2+"),
        ("Terraform IaC completeness", False, "Only storage/logging; no compute/CDN"),
        ("Application-level APM", False, "No distributed tracing or metrics export"),
        ("Backup verification", False, "GPG verify is broken"),
    ]),
    ("Operations", [
        ("On-call runbook", True, "Comprehensive with 10 common issues"),
        ("Incident response playbook", True, "P1-P4 severity classification"),
        ("Deployment guide", True, "13 sections covering all environments"),
        ("Post-launch monitoring plan", False, "No alerting configuration"),
        ("Feature flag system", False, "Cannot toggle features per school"),
    ]),
]

for category, items in checklist:
    story.append(Paragraph(f"<b>{category}</b>", s_h2))
    for item_name, status, note in items:
        mark = "PASS" if status else "FAIL"
        mark_style = s_success if status else s_critical
        story.append(Paragraph(
            f"<b>[{mark}]</b> {item_name} — {note}", s_body_sm
        ))
    story.append(sp(4))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# APPENDIX C: TECHNICAL DEBT REGISTER
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("Appendix C: Technical Debt Register", s_title))
story.append(hr())

debt_items = [
    ("TD-01", "Monolithic DI file (2,000+ lines)", "Medium", "Split into per-feature DI modules", "2-3 days"),
    ("TD-02", "Large presentation files (800-1,238 lines)", "Medium", "Extract sub-widgets from 5 files", "2-3 weeks"),
    ("TD-03", "Theme rebuild gap on custom seed color", "Low", "Delegate to AppTheme builder", "2-3 days"),
    ("TD-04", "Dual validation in auth (inline + Formz)", "Low", "Remove unused Formz validation", "1 day"),
    ("TD-05", "Placeholder UI features (social login, quick actions)", "Medium", "Complete or remove", "2-3 weeks"),
    ("TD-06", "O(n) LRU eviction in DatabasePoolManager", "Low", "Replace with LinkedHashMap", "1 day"),
    ("TD-07", "Provider lifecycle not managed (no auto-dispose)", "Medium", "Audit and add auto-dispose", "3-5 days"),
    ("TD-08", "Missing parent role in routing", "Medium", "Add parent to UserRole + routes", "3-5 days"),
    ("TD-09", "Hardcoded currency/number formatting", "Low", "Use intl package everywhere", "1-2 weeks"),
    ("TD-10", "Dead code (onClearAnswer unused variable)", "Low", "Fix exam_take_page.dart", "1 hour"),
    ("TD-11", "Non-functional GPG verification in backup", "Medium", "Implement proper signing + verify", "2-3 days"),
    ("TD-12", "CloudWatch only for production", "Low", "Add staging log groups", "1 day"),
    ("TD-13", "IAM user instead of role for backup service", "Medium", "Migrate to IAM role + temp creds", "2-3 days"),
    ("TD-14", "Missing CORS error response for unknown origins", "Low", "Return 403 instead of fallback", "1 day"),
    ("TD-15", "k6 CCMS and health check flows defined but not called", "Low", "Add to distribution or remove", "1 day"),
]

debt_data = [
    [Paragraph("<b>ID</b>", s_label), Paragraph("<b>Description</b>", s_label),
     Paragraph("<b>Priority</b>", s_label), Paragraph("<b>Remediation</b>", s_label),
     Paragraph("<b>Effort</b>", s_label)],
]
for d in debt_items:
    debt_data.append([
        Paragraph(d[0], s_body_sm), Paragraph(d[1], s_body_sm),
        Paragraph(d[2], s_body_sm), Paragraph(d[3], s_body_sm),
        Paragraph(d[4], s_body_sm),
    ])
debt_t = Table(debt_data, colWidths=[1.2*cm, 5*cm, 1.5*cm, 4.5*cm, 1.5*cm])
debt_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 2),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
    ('LEFTPADDING', (0, 0), (-1, -1), 3),
    ('RIGHTPADDING', (0, 0), (-1, -1), 3),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(debt_data), 2)]))
story.append(debt_t)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════
# APPENDIX D: POST-LAUNCH MONITORING PLAN
# ═══════════════════════════════════════════════════════════════════════
story.append(Paragraph("Appendix D: Post-Launch Monitoring Plan", s_title))
story.append(hr())

story.append(Paragraph("D.1 Critical Metrics (First 30 Days)", s_h2))

metrics_data = [
    [Paragraph("<b>Metric</b>", s_label), Paragraph("<b>Target</b>", s_label),
     Paragraph("<b>Alert Threshold</b>", s_label), Paragraph("<b>Escalation</b>", s_label)],
    [Paragraph("API Response Time (p95)", s_body_sm), Paragraph("< 1.5s", s_body_sm),
     Paragraph("> 3s for 5 min", s_body_sm), Paragraph("Page on-call engineer", s_body_sm)],
    [Paragraph("Error Rate", s_body_sm), Paragraph("< 1%", s_body_sm),
     Paragraph("> 5% for 5 min", s_body_sm), Paragraph("Page on-call + notify CTO", s_body_sm)],
    [Paragraph("Payment Success Rate", s_body_sm), Paragraph("> 98%", s_body_sm),
     Paragraph("< 95% for 15 min", s_body_sm), Paragraph("Page on-call + finance team", s_body_sm)],
    [Paragraph("AI Response Time (p95)", s_body_sm), Paragraph("< 8s", s_body_sm),
     Paragraph("> 15s for 5 min", s_body_sm), Paragraph("Page on-call + product team", s_body_sm)],
    [Paragraph("Database Connection Pool", s_body_sm), Paragraph("< 70% utilization", s_body_sm),
     Paragraph("> 90% for 5 min", s_body_sm), Paragraph("Page on-call + DBA", s_body_sm)],
    [Paragraph("Uptime", s_body_sm), Paragraph("99.5%", s_body_sm),
     Paragraph("< 99% for 1 hour", s_body_sm), Paragraph("Incident declared", s_body_sm)],
    [Paragraph("Webhook Processing", s_body_sm), Paragraph("< 5s latency", s_body_sm),
     Paragraph("> 30s or queue > 100", s_body_sm), Paragraph("Page on-call", s_body_sm)],
    [Paragraph("Active Users (DAU)", s_body_sm), Paragraph("Track baseline", s_body_sm),
     Paragraph("< 50% of registered", s_body_sm), Paragraph("Product team review", s_body_sm)],
]
metrics_t = Table(metrics_data, colWidths=[4*cm, 2.5*cm, 3.5*cm, 4.5*cm])
metrics_t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
    ('GRID', (0, 0), (-1, -1), 0.3, BORDER),
    ('TOPPADDING', (0, 0), (-1, -1), 3),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ('LEFTPADDING', (0, 0), (-1, -1), 4),
    ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
] + [('BACKGROUND', (0, i), (-1, i), TABLE_STRIPE) for i in range(2, len(metrics_data), 2)]))
story.append(metrics_t)

story.append(sp(12))
story.append(Paragraph("D.2 Monitoring Stack (Recommended)", s_h2))
story.append(bullet("<b>APM:</b> OpenTelemetry + Jaeger for distributed tracing; Grafana for dashboards"))
story.append(bullet("<b>Logging:</b> Structured JSON logs via AppLogger; CloudWatch Logs for aggregation"))
story.append(bullet("<b>Alerting:</b> CloudWatch Alarms + SNS for PagerDuty/Opsgenie integration"))
story.append(bullet("<b>Synthetic Monitoring:</b> Automated health check endpoints; k6 scheduled tests every 15 min"))
story.append(bullet("<b>Error Tracking:</b> Sentry or equivalent for Flutter error reporting with source maps"))
story.append(bullet("<b>Cost Monitoring:</b> AI token usage tracking via AiCacheService; monthly budget alerts per school"))

story.append(sp(12))
story.append(Paragraph("D.3 Post-Incident Review Template", s_h2))
story.append(p("Every P1/P2 incident must have a post-incident review within 48 hours covering: timeline of events, "
    "root cause analysis, impact assessment (users affected, revenue impact, data integrity), what went well, "
    "what needs improvement, action items with owners and deadlines, and preventive measures. Reviews must be "
    "documented in the incident-response repository and shared with engineering leadership."))

story.append(sp(16))
story.append(hr())
story.append(Paragraph(
    "This report was prepared by an independent review board acting in the capacity of external auditors. "
    "All findings are based on source code review and static analysis conducted in July 2026. No live "
    "environment testing was performed. Conclusions should be validated with measured data before making "
    "final deployment decisions.",
    s_caption
))

# ─── BUILD PDF ──────────────────────────────────────────────────────────
doc.build(story, onFirstPage=add_page_number, onLaterPages=add_page_number)
print(f"Report generated: {OUTPUT_PATH}")
print(f"File size: {os.path.getsize(OUTPUT_PATH) / 1024:.1f} KB")
