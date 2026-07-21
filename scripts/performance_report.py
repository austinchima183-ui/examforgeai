#!/usr/bin/env python3
"""
ExamForge AI — Comprehensive Performance Certification Report
12-Phase Performance Optimization & Scalability Audit

Generates a professional PDF report covering all phases of the performance audit.
"""

import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm, cm, inch
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, Image
)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

# ─── Font Registration ───────────────────────────────────────────────────────
FONT_DIR = '/usr/share/fonts'
pdfmetrics.registerFont(TTFont('Inter', f'{FONT_DIR}/truetype/english/Carlito-Regular.ttf'))
pdfmetrics.registerFont(TTFont('Inter-Bold', f'{FONT_DIR}/truetype/english/Carlito-Bold.ttf'))
pdfmetrics.registerFont(TTFont('NotoSerifSC', f'{FONT_DIR}/truetype/noto-serif-sc/NotoSerifSC-Regular.ttf'))
pdfmetrics.registerFont(TTFont('NotoSerifSC-Bold', f'{FONT_DIR}/truetype/noto-serif-sc/NotoSerifSC-Bold.ttf'))
registerFontFamily('Inter', normal='Inter', bold='Inter-Bold')
registerFontFamily('NotoSerifSC', normal='NotoSerifSC', bold='NotoSerifSC-Bold')

# ─── Cascade Palette ─────────────────────────────────────────────────────────
PAGE_BG       = colors.HexColor('#f1f2f3')
SECTION_BG    = colors.HexColor('#f0f1f2')
CARD_BG       = colors.HexColor('#eaeced')
TABLE_STRIPE  = colors.HexColor('#e9eced')
HEADER_FILL   = colors.HexColor('#3a4951')
COVER_BLOCK   = colors.HexColor('#50656f')
BORDER        = colors.HexColor('#b3c5ce')
ICON          = colors.HexColor('#4e86a3')
ACCENT        = colors.HexColor('#2981ae')
ACCENT_2      = colors.HexColor('#ca6b4b')
TEXT_PRIMARY   = colors.HexColor('#17191a')
TEXT_MUTED     = colors.HexColor('#6f7578')
SEM_SUCCESS   = colors.HexColor('#3e7952')
SEM_WARNING   = colors.HexColor('#9e824a')
SEM_ERROR     = colors.HexColor('#8f4640')
SEM_INFO      = colors.HexColor('#5179a1')

# ─── Page Setup ──────────────────────────────────────────────────────────────
PAGE_W, PAGE_H = A4
LEFT_MARGIN = 20*mm
RIGHT_MARGIN = 20*mm
TOP_MARGIN = 20*mm
BOTTOM_MARGIN = 20*mm
CONTENT_W = PAGE_W - LEFT_MARGIN - RIGHT_MARGIN

OUTPUT_PATH = '/home/z/my-project/download/ExamForge_AI_Performance_Certification_Report.pdf'

# ─── Styles ──────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

s_title = ParagraphStyle('Title', parent=styles['Title'],
    fontName='Inter-Bold', fontSize=24, textColor=TEXT_PRIMARY,
    spaceAfter=6*mm, spaceBefore=0, leading=28)

s_h1 = ParagraphStyle('H1', parent=styles['Heading1'],
    fontName='Inter-Bold', fontSize=18, textColor=HEADER_FILL,
    spaceBefore=10*mm, spaceAfter=4*mm, leading=22,
    borderWidth=0, borderPadding=0)

s_h2 = ParagraphStyle('H2', parent=styles['Heading2'],
    fontName='Inter-Bold', fontSize=14, textColor=COVER_BLOCK,
    spaceBefore=6*mm, spaceAfter=3*mm, leading=18)

s_h3 = ParagraphStyle('H3', parent=styles['Heading3'],
    fontName='Inter-Bold', fontSize=11, textColor=ICON,
    spaceBefore=4*mm, spaceAfter=2*mm, leading=14)

s_body = ParagraphStyle('Body', parent=styles['Normal'],
    fontName='Inter', fontSize=9.5, textColor=TEXT_PRIMARY,
    spaceBefore=1*mm, spaceAfter=2*mm, leading=14,
    alignment=TA_JUSTIFY)

s_body_small = ParagraphStyle('BodySmall', parent=s_body,
    fontSize=8.5, leading=12)

s_bullet = ParagraphStyle('Bullet', parent=s_body,
    leftIndent=12, bulletIndent=0, spaceBefore=0.5*mm, spaceAfter=0.5*mm)

s_table_header = ParagraphStyle('TableHeader',
    fontName='Inter-Bold', fontSize=8, textColor=colors.white,
    leading=11, alignment=TA_LEFT)

s_table_cell = ParagraphStyle('TableCell',
    fontName='Inter', fontSize=8, textColor=TEXT_PRIMARY,
    leading=11, alignment=TA_LEFT)

s_table_cell_center = ParagraphStyle('TableCellCenter',
    fontName='Inter', fontSize=8, textColor=TEXT_PRIMARY,
    leading=11, alignment=TA_CENTER)

s_crit = ParagraphStyle('Critical', parent=s_body,
    textColor=SEM_ERROR, fontName='Inter-Bold')

s_warn = ParagraphStyle('Warning', parent=s_body,
    textColor=SEM_WARNING, fontName='Inter-Bold')

s_good = ParagraphStyle('Good', parent=s_body,
    textColor=SEM_SUCCESS, fontName='Inter-Bold')

s_caption = ParagraphStyle('Caption',
    fontName='Inter', fontSize=7.5, textColor=TEXT_MUTED,
    spaceBefore=1*mm, spaceAfter=3*mm, alignment=TA_LEFT)

s_footer = ParagraphStyle('Footer',
    fontName='Inter', fontSize=7, textColor=TEXT_MUTED,
    alignment=TA_CENTER)

# ─── Helper Functions ────────────────────────────────────────────────────────
def make_table(headers, rows, col_widths=None):
    """Create a styled table with header row."""
    header_row = [Paragraph(h, s_table_header) for h in headers]
    data = [header_row]
    for row in rows:
        data.append([Paragraph(str(c), s_table_cell) for c in row])
    
    if col_widths is None:
        col_widths = [CONTENT_W / len(headers)] * len(headers)
    
    t = Table(data, colWidths=col_widths, repeatRows=1)
    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Inter-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 8),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 5),
        ('TOPPADDING', (0, 0), (-1, 0), 5),
        ('FONTNAME', (0, 1), (-1, -1), 'Inter'),
        ('FONTSIZE', (0, 1), (-1, -1), 8),
        ('TOPPADDING', (0, 1), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t

def make_score_table(scores):
    """Create a performance score table."""
    headers = ['Dimension', 'Score', 'Grade', 'Status']
    rows = []
    for dim, score, grade, status in scores:
        rows.append([dim, str(score), grade, status])
    return make_table(headers, rows, [CONTENT_W*0.40, CONTENT_W*0.15, CONTENT_W*0.15, CONTENT_W*0.30])

def hr():
    return HRFlowable(width="100%", thickness=0.5, color=BORDER, spaceBefore=2*mm, spaceAfter=2*mm)

def bullet(text):
    return Paragraph(f"<bullet>&bull;</bullet> {text}", s_bullet)

# ─── Document Builder ────────────────────────────────────────────────────────
def build_report():
    doc = SimpleDocTemplate(
        OUTPUT_PATH,
        pagesize=A4,
        leftMargin=LEFT_MARGIN,
        rightMargin=RIGHT_MARGIN,
        topMargin=TOP_MARGIN,
        bottomMargin=BOTTOM_MARGIN,
        title='ExamForge AI Performance Certification Report',
        author='Z.ai Performance Engineering Team',
        subject='12-Phase Performance Optimization and Scalability Audit',
    )

    story = []

    # ═══════════════════════════════════════════════════════════════════════
    # COVER PAGE
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 30*mm))
    story.append(Paragraph("EXAMFORGE AI", ParagraphStyle('CoverBrand',
        fontName='Inter-Bold', fontSize=12, textColor=ACCENT,
        spaceAfter=4*mm, letterSpacing=3)))
    story.append(Paragraph("Performance Certification Report", s_title))
    story.append(Paragraph("12-Phase Performance Optimization &amp; Scalability Audit",
        ParagraphStyle('CoverSub', fontName='Inter', fontSize=14,
            textColor=TEXT_MUTED, spaceAfter=8*mm)))
    story.append(hr())
    story.append(Spacer(1, 8*mm))

    cover_meta = [
        ['Platform', 'ExamForge AI — Nigerian Educational SaaS'],
        ['Stack', 'Flutter + Supabase + Clean Architecture + Riverpod'],
        ['Architecture', 'Multi-tenant (school_id isolation), 6 user roles'],
        ['Codebase Scale', '1,007 Dart files, 27 SQL migrations, 4 Edge Functions'],
        ['Analysis Date', 'July 2026'],
        ['Classification', 'Static Code Analysis + Engineering Estimates'],
        ['Assessment Type', 'Performance, Scalability &amp; Operational Readiness'],
    ]
    t = Table(cover_meta, colWidths=[CONTENT_W*0.25, CONTENT_W*0.75])
    t.setStyle(TableStyle([
        ('FONTNAME', (0, 0), (0, -1), 'Inter-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Inter'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('TEXTCOLOR', (0, 0), (0, -1), COVER_BLOCK),
        ('TEXTCOLOR', (1, 0), (1, -1), TEXT_PRIMARY),
        ('LINEBELOW', (0, 0), (-1, -2), 0.3, BORDER),
    ]))
    story.append(t)
    story.append(Spacer(1, 15*mm))

    story.append(Paragraph(
        "<b>Important Disclaimer:</b> This report is based on static code analysis and engineering estimates. "
        "No live performance measurements were taken. Results are marked as either "
        "<b>Static Analysis (SA)</b>, <b>Engineering Estimate (EE)</b>, or <b>Code Review Finding (CRF)</b>. "
        "Live benchmarking is recommended before production deployment.",
        ParagraphStyle('Disclaimer', parent=s_body, fontSize=8, textColor=SEM_WARNING,
            borderWidth=1, borderColor=SEM_WARNING, borderPadding=6, backColor=colors.HexColor('#fef9ef'))
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # EXECUTIVE SUMMARY
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Executive Summary", s_h1))
    story.append(Paragraph(
        "ExamForge AI is a comprehensive Nigerian educational SaaS platform built with Flutter, Supabase, "
        "and Clean Architecture. The platform serves 6 user roles (superAdmin, schoolAdmin, teacher, student, parent) "
        "across 28 feature modules including CBT examination engine, AI question generation, marketplace, CCMS, "
        "and Flutterwave billing. This 12-phase performance audit analyzed the entire platform from Flutter widget "
        "rendering to PostgreSQL query execution, identifying 47 performance findings across 4 severity levels.",
        s_body
    ))
    story.append(Paragraph(
        "The audit reveals a platform with strong architectural foundations but significant gaps between "
        "performance infrastructure that exists and infrastructure that is actually wired into the application. "
        "A comprehensive 1,220-line PerformanceManager exists in the codebase but is consumed by zero feature "
        "modules. DatabasePoolManager provides query monitoring but no datasource routes queries through it. "
        "The most impactful issues are: (1) zero AutoDispose usage on 248 StateNotifierProviders causing progressive "
        "memory leaks, (2) unbounded Supabase queries without pagination on 527 of 610 select() calls, "
        "(3) RLS policies executing millions of redundant subqueries per day via get_user_role(), "
        "(4) AI service using GPT-4o by default at 25-30x the cost of GPT-4o-mini for question generation, "
        "and (5) a critical race condition in the refund processing edge function that could enable over-refunding.",
        s_body
    ))

    # Overall scores
    story.append(Paragraph("Performance Readiness Scores", s_h2))
    scores = [
        ('Flutter Performance', 35, 'F', 'Critical — Memory leaks, no selective rebuilds, no auto-dispose'),
        ('Backend Performance', 40, 'D', 'Critical — Unbounded queries, no retry, no caching wired in'),
        ('Database Performance', 30, 'F', 'Critical — RLS subquery overhead, missing indexes, no pagination'),
        ('AI Performance', 25, 'F', 'Critical — No caching, GPT-4o default, no fallback, no retry'),
        ('Infrastructure Scalability', 45, 'D', 'Poor — No connection pooling, no rate limiting, no partitioning'),
        ('Load Handling', 20, 'F', 'Critical — Unvalidated at scale, known bottlenecks unaddressed'),
        ('Monitoring', 50, 'D', 'Poor — Infrastructure exists but is not wired into application'),
        ('Overall Performance', 32, 'F', 'Critical — Not production-ready for any scale without fixes'),
    ]
    story.append(make_score_table(scores))
    story.append(Paragraph(
        "<i>Scoring methodology: 90-100 = A (Excellent), 70-89 = B (Good), 50-69 = C (Adequate), "
        "30-49 = D (Poor), 0-29 = F (Critical). Scores are engineering estimates based on static code analysis.</i>",
        s_caption
    ))

    # Launch readiness
    story.append(Paragraph("Launch Readiness Summary", s_h2))
    launch_data = [
        ['Scale', 'Ready?', 'Key Blockers', 'Risk Level'],
        ['10 schools', 'No', 'Memory leaks, unbounded queries, AI cost', 'High'],
        ['100 schools', 'No', 'All above + RLS subquery overload, no rate limiting', 'Critical'],
        ['1,000 schools', 'No', 'All above + connection exhaustion, DB partitioning', 'Critical'],
        ['10,000 schools', 'No', 'Full architecture redesign required', 'Critical'],
    ]
    t = Table(launch_data, colWidths=[CONTENT_W*0.12, CONTENT_W*0.10, CONTENT_W*0.55, CONTENT_W*0.23])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Inter-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('FONTNAME', (0, 1), (-1, -1), 'Inter'),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
        ('TEXTCOLOR', (2, 1), (2, 1), SEM_ERROR),
        ('TEXTCOLOR', (2, 2), (2, 2), SEM_ERROR),
        ('TEXTCOLOR', (2, 3), (2, 3), SEM_ERROR),
        ('TEXTCOLOR', (2, 4), (2, 4), SEM_ERROR),
        ('TEXTCOLOR', (3, 1), (3, 1), SEM_WARNING),
        ('TEXTCOLOR', (3, 2), (3, 4), SEM_ERROR),
    ]))
    story.append(t)

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 1 — PERFORMANCE AUDIT
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 1 — Performance Audit", s_h1))
    story.append(Paragraph(
        "A comprehensive performance audit was conducted across all platform layers: Flutter presentation, "
        "network/API, database, Edge Functions, AI services, file upload, search, dashboard, CBT engine, "
        "and marketplace. The audit methodology combined static code analysis of all 1,007 Dart source files, "
        "27 SQL migration files, and 4 Edge Functions with engineering estimation of runtime behavior. "
        "Each subsystem was evaluated for latency characteristics, resource utilization patterns, caching "
        "effectiveness, and scalability limits.",
        s_body
    ))

    story.append(Paragraph("1.1 Flutter Performance Baseline", s_h2))
    story.append(Paragraph(
        "The Flutter layer contains 248 StateNotifierProvider instances across 107 provider files, 28 feature "
        "modules, and approximately 815 setState() calls across 189 ConsumerStatefulWidget pages. The most "
        "critical finding is the complete absence of AutoDispose across all providers, meaning every provider "
        "created during a user session remains in memory indefinitely. Combined with zero usage of selective "
        "rebuilds via ref.watch().select(), this creates a situation where navigating between features causes "
        "progressive memory accumulation without any release mechanism.",
        s_body
    ))
    story.append(Paragraph(
        "Widget tree analysis reveals that large build() methods (200-400+ lines) are common in page widgets "
        "like document_upload_page.dart (280 lines), create_product_page.dart (25 setState calls), and "
        "content_editor_page.dart (20 setState calls). These monolithic build methods mean any setState call "
        "rebuilds the entire page widget tree. No RepaintBoundary widgets exist anywhere in the codebase, "
        "meaning animations, scrolling, or state changes cause full-screen repaints rather than localized updates.",
        s_body
    ))

    fl_metrics = [
        ['Metric', 'Current Value', 'Target', 'Gap'],
        ['AutoDispose usage', '0/248 providers (0%)', '100%', 'Critical'],
        ['Selective rebuilds (select)', '0 instances', '50+ instances', 'Critical'],
        ['setState calls', '815 across 189 files', '< 100', 'High'],
        ['RepaintBoundary usage', '0 instances', '10+ in animation containers', 'Medium'],
        ['Deferred imports', '0 (all features loaded at startup)', 'Per-feature lazy loading', 'Medium'],
        ['Const constructor usage', 'Partial (root widget only)', 'All stateless widgets', 'Low'],
        ['PerformanceManager wired', '0 consumers', 'All datasources', 'Critical'],
    ]
    t = Table(fl_metrics, colWidths=[CONTENT_W*0.28, CONTENT_W*0.28, CONTENT_W*0.22, CONTENT_W*0.22])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_FILL),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Inter-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('FONTNAME', (0, 1), (-1, -1), 'Inter'),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, TABLE_STRIPE]),
        ('TEXTCOLOR', (3, 1), (3, 3), SEM_ERROR),
        ('TEXTCOLOR', (3, 7), (3, 7), SEM_ERROR),
    ]))
    story.append(t)

    story.append(Paragraph("1.2 API &amp; Network Performance Baseline", s_h2))
    story.append(Paragraph(
        "The API layer uses a Dio-based ApiClient with 15-second timeouts in production, automatic auth "
        "token injection via StorageService, and token refresh on 401 responses. However, the API client "
        "lacks retry logic for transient failures, response caching via ETag/If-None-Match, gzip compression "
        "configuration, and a mutex to prevent concurrent token refresh race conditions. The token refresh "
        "mechanism in api_client.dart (lines 252-273) has a known race condition: if two requests fail with "
        "401 simultaneously, both independently attempt token refresh, potentially invalidating each other's "
        "tokens when the refresh token is single-use.",
        s_body
    ))
    story.append(Paragraph(
        "Supabase queries present the most significant API-level concern. Of 610 .select() calls across all "
        "datasource files, only 83 (13.6%) use .range() for pagination and only 75 (12.3%) use .limit(). "
        "This means 527 queries (86.4%) will return unbounded result sets. For tables like content_items, "
        "audit_entries, student_answers, and exam_attempts that can contain thousands to millions of rows, "
        "these unbounded queries will cause out-of-memory crashes on mobile devices and multi-second latency "
        "on even moderate data volumes. Additionally, 610 .select() calls fetch all columns (select-star) "
        "rather than specifying only needed columns, transferring potentially large JSONB columns unnecessarily.",
        s_body
    ))

    story.append(Paragraph("1.3 Database Performance Baseline", s_h2))
    story.append(Paragraph(
        "The database layer is the most critical performance concern. The multi-tenant architecture relies "
        "on Row Level Security (RLS) with 858 policies across all tables. The RLS helper function "
        "get_user_role() (defined in schema.sql:332 and rls_role_fix.sql:43) executes a subquery against "
        "the users table for every row evaluated by RLS policies. With most tables having get_user_role() "
        "checks and many also calling get_user_school_id() or performing additional correlated subqueries, "
        "a single SELECT on the exams table with 1,000 rows triggers 1,000+ subqueries to the users table. "
        "This is the single most impactful database performance issue in the platform.",
        s_body
    ))
    story.append(Paragraph(
        "Further analysis reveals that the audit_log RLS policy (schema.sql:797-803) uses an unbounded IN "
        "subquery that materializes all user IDs in a school for every audit_log row evaluated. For a school "
        "with 5,000 students, this creates a materialized set of 5,000 UUIDs checked per row. As the audit_log "
        "grows to millions of rows, this becomes catastrophically slow. The N+1 query pattern in "
        "getQuestionWithDetails() (question_bank_remote_datasource.dart:294-358) makes 7 separate HTTP "
        "requests for a single question where a single Supabase join query or RPC call would suffice. "
        "A server-side get_question_with_details() function already exists in question_bank_schema.sql:908 "
        "but is not called from the Dart code.",
        s_body
    ))

    db_metrics = [
        ['Metric', 'Value', 'Assessment'],
        ['Total RLS policies', '858', 'High per-row evaluation cost'],
        ['Total indexes', '~1,266', 'Present but gaps in RLS hot paths'],
        ['Total FK references', '~721', 'Adequate referential integrity'],
        ['Database functions', '90+', 'Includes redundant duplicates'],
        ['Materialized views', '3', 'None auto-refreshed via pg_cron'],
        ['Select-star queries', '610 (86.4%)', 'Critical — no column selection'],
        ['Unbounded queries', '527 (86.4%)', 'Critical — no pagination'],
        ['Paginated queries', '83 (13.6%)', 'Severely insufficient'],
        ['RPC calls', '75', 'Underutilized vs direct queries'],
        ['Connection pooling', 'None configured', 'Critical for multi-tenant SaaS'],
        ['Table partitioning', 'None', 'Critical for audit/metrics tables'],
    ]
    story.append(make_table(['Metric', 'Value', 'Assessment'], db_metrics[1:],
        [CONTENT_W*0.35, CONTENT_W*0.20, CONTENT_W*0.45]))

    story.append(Paragraph("1.4 AI Performance Baseline", s_h2))
    story.append(Paragraph(
        "The AI service layer comprises ai_service.dart (997 lines), openai_provider.dart (407 lines), "
        "prompt_engine.dart (843 lines), and ai_security_service.dart (35.9KB). The default AI model is "
        "GPT-4o at $0.005/1K input + $0.015/1K output tokens. For question generation tasks where "
        "GPT-4o-mini ($0.00015/1K input + $0.0006/1K output) would produce comparable quality, this "
        "represents a 25-30x cost multiplier. At 1,000 question generations per day with an average of "
        "4K input + 2K output tokens, the current configuration costs approximately $60/day ($1,800/month) "
        "versus $2.40/day ($72/month) with GPT-4o-mini — a potential 96% cost reduction.",
        s_body
    ))
    story.append(Paragraph(
        "The AI service has no response caching mechanism, meaning identical generation requests (same topic, "
        "difficulty, question type) produce redundant API calls. There is no retry or exponential backoff on "
        "AI provider calls; a single 429 (rate limit) or 502/503 (server error) causes complete generation "
        "failure. Validation after generation is sequential (ai_service.dart:377-386), processing questions "
        "one at a time in a loop rather than in parallel via Future.wait(). Document processing truncates "
        "at 8,000 characters (ai_service.dart:825), losing significant content from longer documents. "
        "There is no provider fallback chain — if OpenAI is unavailable, all AI features fail even if Gemini "
        "is configured and available in the providers registry.",
        s_body
    ))

    ai_costs = [
        ['Scenario', 'Daily Cost', 'Monthly Cost', 'Notes'],
        ['Current (GPT-4o, no cache)', '$60', '$1,800', 'Default configuration'],
        ['+ Caching (30% hit rate)', '$42', '$1,260', 'Deterministic cache keys'],
        ['+ GPT-4o-mini for question gen', '$2.40', '$72', '25-30x cost reduction'],
        ['+ RequestBatcher (10% dedup)', '$2.16', '$65', 'Deduplicate concurrent requests'],
        ['Fully Optimized', '$2.16', '$65', '96% cost reduction potential'],
    ]
    story.append(make_table(['Scenario', 'Daily Cost', 'Monthly Cost', 'Notes'], ai_costs[1:],
        [CONTENT_W*0.30, CONTENT_W*0.15, CONTENT_W*0.17, CONTENT_W*0.38]))

    story.append(Paragraph("1.5 Edge Function Performance Baseline", s_h2))
    story.append(Paragraph(
        "Four Edge Functions were analyzed: health-check (190 lines), flutterwave-webhook (375 lines), "
        "process-refund (448 lines), and marketplace-download (204 lines). Common patterns include CDN import "
        "of Supabase client (cold start penalty of 200-500ms per function), new client creation per request "
        "(no connection reuse), no request timeout on external API calls, and no structured logging. "
        "The process-refund edge function has a critical race condition on refund amount validation "
        "(lines 278-402): two concurrent refund requests can both read the same alreadyRefunded value and "
        "both pass validation, resulting in over-refunding. This requires immediate remediation with "
        "SELECT FOR UPDATE or a serializable transaction.",
        s_body
    ))
    story.append(Paragraph(
        "The health-check function performs up to 24 sequential database operations per invocation (4 parallel "
        "health checks + up to 20 sequential alert evaluation operations). It also calls the Flutterwave API "
        "on every invocation without caching or timeout. For a cron job hitting this endpoint every 30 seconds, "
        "this generates approximately 9,600 database writes per day just for health monitoring. The "
        "flutterwave-webhook function has a time-of-check-to-time-of-use (TOCTOU) race condition in its "
        "idempotency check (lines 166-199) where concurrent webhooks with the same event can both pass the "
        "initial check before either completes the upsert operation.",
        s_body
    ))

    edge_metrics = [
        ['Function', 'Min DB Ops', 'Max DB Ops', 'External API', 'Expected Latency', 'Critical Issue'],
        ['health-check', '4', '24', 'Yes (Flutterwave)', '500ms-5s', 'No timeout, sequential alerts'],
        ['flutterwave-webhook', '3', '7', 'No', '100-500ms', 'TOCTOU race condition'],
        ['process-refund', '5', '8', 'Yes (Flutterwave)', '300ms-2s+', 'Refund over-payment race'],
        ['marketplace-download', '3', '4', 'No', '200-800ms', 'Token/URL expiry mismatch'],
    ]
    story.append(make_table(
        ['Function', 'Min DB Ops', 'Max DB Ops', 'External API', 'Latency', 'Critical Issue'],
        edge_metrics[1:],
        [CONTENT_W*0.18, CONTENT_W*0.10, CONTENT_W*0.10, CONTENT_W*0.12, CONTENT_W*0.14, CONTENT_W*0.36]
    ))

    story.append(Paragraph("1.6 Dashboard &amp; CBT Loading Performance", s_h2))
    story.append(Paragraph(
        "Dashboard loading performance is impacted by the school_management_remote_datasource.dart "
        "(lines 3454-3488) pattern of using 6 parallel .select('id') calls to count entities. For a school "
        "with 5,000 students, this transfers 5,000 UUIDs (160KB+) over the network just to compute count=5000. "
        "Supabase's built-in count functionality or server-side RPC would reduce this to a single integer "
        "response. The CBT engine's exam loading follows similar patterns with unbounded queries for questions, "
        "answer options, and exam metadata. The marketplace module is the most complex with 50+ use cases and "
        "15 pages, all using unbounded queries without pagination.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 2 — DATABASE OPTIMIZATION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 2 — Database Optimization", s_h1))
    story.append(Paragraph(
        "Database optimization represents the highest-impact improvement area for ExamForge AI. The PostgreSQL "
        "database serves as the foundation for all platform operations, and current query patterns, index "
        "coverage, and RLS policy implementation create severe performance bottlenecks that will worsen "
        "exponentially as data volume and concurrent users increase. This phase addresses every SQL query "
        "pattern, index usage, query plan optimization, join efficiency, foreign key impact, materialized "
        "view strategy, and caching opportunities across the entire schema.",
        s_body
    ))

    story.append(Paragraph("2.1 RLS Policy Optimization — Highest Priority", s_h2))
    story.append(Paragraph(
        "The get_user_role() function is called by the majority of 858 RLS policies, executing a subquery "
        "against the users table for every candidate row during policy evaluation. The STABLE annotation helps "
        "PostgreSQL cache the result within a single query execution, but this caching does not extend across "
        "rows when RLS evaluates per-row. The recommended replacement is reading the role directly from the "
        "JWT token via current_setting('request.jwt.claims', true)::json->>'role', which eliminates all "
        "database lookups for role determination. Similarly, get_user_school_id() should be replaced with "
        "current_setting('request.jwt.claims', true)::json->>'school_id'. This single change is estimated "
        "to reduce database query load by 40-60% under typical multi-tenant workloads.",
        s_body
    ))

    rls_opt = [
        ['Finding', 'Current', 'Optimized', 'Impact'],
        ['get_user_role() calls', 'Subquery to users table per row', 'JWT claim read (zero DB hit)', '40-60% query load reduction'],
        ['get_user_school_id() calls', 'Subquery to users table per row', 'JWT claim read (zero DB hit)', 'Eliminates redundant lookups'],
        ['audit_log RLS', 'IN (SELECT id FROM users...) with 5K UUIDs', 'school_id column on audit_log + equality check', '99% RLS evaluation cost reduction'],
        ['Nested RLS subqueries', 'get_user_role() + separate school_id subquery', 'JWT claims for both', 'Eliminates double subquery per row'],
        ['Redundant helper functions', '7+ duplicate definitions across migrations', 'Single utility_functions.sql', 'Prevents divergent implementations'],
    ]
    story.append(make_table(['Finding', 'Current', 'Optimized', 'Impact'], rls_opt[1:],
        [CONTENT_W*0.18, CONTENT_W*0.27, CONTENT_W*0.27, CONTENT_W*0.28]))

    story.append(Paragraph("2.2 Missing Indexes — Critical Paths", s_h2))
    story.append(Paragraph(
        "Index analysis reveals critical gaps on frequently queried columns that are used in RLS policy "
        "evaluation, WHERE clauses, and JOIN conditions. The users table lacks a composite index on "
        "(id, role, school_id) that would allow index-only scans for the most common RLS helper queries. "
        "The notifications table lacks an index on (user_id, is_read, created_at DESC) for the most common "
        "query pattern — fetching unread notifications. The class_students table lacks (student_id, is_active) "
        "for active enrollment lookups. These missing indexes force sequential scans on tables with thousands "
        "to millions of rows, degrading performance by 10-100x compared to indexed access.",
        s_body
    ))

    missing_idx = [
        ['Table', 'Missing Index', 'Query Pattern', 'Est. Impact'],
        ['users', '(id, role, school_id)', 'RLS helper function lookups', 'Index-only scans for RLS'],
        ['notifications', '(user_id, is_read, created_at DESC)', 'Unread notification list', '10-100x faster notification fetch'],
        ['audit_log', '(resource_type, resource_id)', 'Resource audit trail lookup', 'Sequential scan elimination'],
        ['audit_log', '(action, created_at DESC)', 'Action-type audit queries', 'Time-range scan optimization'],
        ['class_students', '(student_id, is_active)', 'Active student enrollments', 'Enrollment verification speedup'],
        ['student_answers', '(attempt_id, question_id)', 'Answer lookup during grading', 'CBT grading speedup'],
        ['ai_tutor_messages', '(conversation_id, created_at)', 'Message history pagination', 'Chat history load time'],
        ['content_items', '(school_id, content_type, status)', 'CCMS content filtering', 'CCMS query optimization'],
    ]
    story.append(make_table(['Table', 'Missing Index', 'Query Pattern', 'Est. Impact'], missing_idx[1:],
        [CONTENT_W*0.17, CONTENT_W*0.30, CONTENT_W*0.28, CONTENT_W*0.25]))

    story.append(Paragraph("2.3 Query Pattern Optimization", s_h2))
    story.append(Paragraph(
        "Beyond RLS and indexing, several query patterns create significant performance overhead. The N+1 "
        "pattern in getQuestionWithDetails() makes 7 separate HTTP requests for a single question; using "
        "Supabase's join syntax or the existing get_question_with_details() RPC would reduce this to 1. "
        "The count-via-select('id') pattern in school_management_remote_datasource.dart transfers entire "
        "ID arrays to the client just to count them; using Supabase's count functionality would reduce "
        "data transfer by 99%. The 610 select-star queries fetch all columns including large JSONB payloads; "
        "specifying only needed columns for list views would reduce data transfer by 50-80%. Sequential "
        "draft syncing in offline_remote_datasource.dart sends one HTTP request per draft instead of using "
        "Supabase's batch upsert; syncing 100 drafts currently requires 100 sequential HTTP requests.",
        s_body
    ))

    story.append(Paragraph("2.4 Table Partitioning Strategy", s_h2))
    story.append(Paragraph(
        "Multiple tables will grow to millions of rows and require partitioning for sustained performance. "
        "The audit_log, api_latency_metrics, ai_service_metrics, auth_metrics, payment_metrics, "
        "server_resource_metrics, performance_logs, sync_queue, student_answers, and exam_attempts tables "
        "all lack partitioning. Range partitioning by created_at (monthly) is recommended for all metrics "
        "and log tables, with pg_partman for automatic partition management. The CCMS schema includes a "
        "create_audit_partition_if_not_exists() function at ccms_enterprise_schema.sql:2050, but this is "
        "the only partitioning mechanism in the codebase and has no automation to call it. Without "
        "partitioning, queries with time-range filters on these tables will degrade significantly as they "
        "grow, and vacuum operations will become increasingly expensive.",
        s_body
    ))

    story.append(Paragraph("2.5 Materialized View Refresh", s_h2))
    story.append(Paragraph(
        "Three materialized views exist — mv_marketplace_trending_products (marketplace_schema.sql:2025), "
        "parent_engagement_summary (parent_portal_schema.sql:301), and teacher_statistics "
        "(teacher_workspace_expansion_schema.sql:463) — but none have scheduled refresh via pg_cron. "
        "Each has a refresh function but no automation calls it. Dashboards relying on these views display "
        "stale data immediately after creation. Adding pg_cron entries with 15-minute refresh intervals "
        "would ensure dashboard accuracy while maintaining acceptable database load.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 3 — API OPTIMIZATION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 3 — API Optimization", s_h1))
    story.append(Paragraph(
        "API optimization focuses on reducing request/response sizes, implementing pagination, enabling "
        "compression, adding caching headers, improving serialization, ensuring connection reuse, "
        "configuring appropriate timeouts, and adding retry logic with exponential backoff. The current "
        "API layer provides a solid foundation with proper auth token injection and 401 retry, but lacks "
        "several critical production features for a high-traffic SaaS platform.",
        s_body
    ))

    story.append(Paragraph("3.1 Request/Response Size Optimization", s_h2))
    story.append(Paragraph(
        "The most impactful API optimization is adding column selection to Supabase queries. Currently, "
        "610 .select() calls fetch all columns (select-star) including potentially large JSONB columns like "
        "settings, metadata, payload, details, tags, content_json, and explanation. For list views that "
        "only need id, name, status, and created_at, this transfers 5-20x more data than necessary. "
        "For example, a question list view currently fetches content_json (10KB+ per question) and "
        "explanation text that are only needed in detail views. By specifying .select('id, title, difficulty, "
        "subject_id, created_at') for list queries and reserving full .select() for detail views, estimated "
        "data transfer reduction is 50-80% for the most common API calls.",
        s_body
    ))

    story.append(Paragraph("3.2 Pagination Implementation", s_h2))
    story.append(Paragraph(
        "Of 610 .select() calls, only 83 (13.6%) use .range() for pagination. This is the most critical "
        "API-level performance gap. Unbounded queries on tables with thousands of rows cause OOM crashes on "
        "mobile devices and multi-second latency even on moderate data volumes. The recommended approach is "
        "to enforce a default page size of 20-50 rows for all list queries, with explicit pagination "
        "parameters (offset/limit or cursor-based) exposed in repository interfaces. The PerformanceManager's "
        "LazyLoadController already implements scroll-based pagination but is not consumed by any feature.",
        s_body
    ))

    api_opt = [
        ['Optimization', 'Current', 'Target', 'Est. Improvement'],
        ['Column selection', '610 select-star queries', 'All list queries specify columns', '50-80% data transfer reduction'],
        ['Pagination', '83/610 queries paginated (13.6%)', '100% list queries paginated', 'Eliminates OOM risk'],
        ['Gzip compression', 'Not configured', 'Accept-Encoding: gzip header', '60-80% JSON response reduction'],
        ['Response caching (ETag)', 'None', 'Dio cache interceptor', '30-50% request elimination'],
        ['Retry with backoff', 'None', '3 retries, 1s/2s/4s backoff', 'Eliminates transient failures'],
        ['Token refresh mutex', 'Race condition', 'Completer-based mutex', 'Prevents duplicate refresh calls'],
        ['Request batching', 'None', 'PerformanceManager.RequestBatcher', '30-50% duplicate call reduction'],
        ['Count optimization', 'select("id") + count in Dart', 'Supabase count option', '99% data transfer for counts'],
    ]
    story.append(make_table(['Optimization', 'Current', 'Target', 'Est. Improvement'], api_opt[1:],
        [CONTENT_W*0.22, CONTENT_W*0.25, CONTENT_W*0.25, CONTENT_W*0.28]))

    story.append(Paragraph("3.3 Connection Reuse &amp; Timeout Configuration", s_h2))
    story.append(Paragraph(
        "Current timeout configuration sets 15 seconds for connect, receive, and send timeouts in production. "
        "While adequate for standard CRUD operations, AI generation calls use a separate Dio instance with "
        "30-second connect and 120-second receive timeouts (openai_provider.dart:38). No retry logic exists "
        "for any API call, meaning a single network timeout results in a user-facing error. The recommended "
        "configuration adds an exponential backoff retry interceptor for idempotent methods (GET, PUT, DELETE), "
        "with 3 retries at 1s, 2s, and 4s delays. This would eliminate 90%+ of transient failure errors "
        "while respecting server-side rate limits through progressive delay.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 4 — FLUTTER OPTIMIZATION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 4 — Flutter Optimization", s_h1))
    story.append(Paragraph(
        "Flutter optimization addresses widget rebuild efficiency, memory management, image loading strategy, "
        "lazy loading implementation, navigation performance, state management architecture, animation "
        "performance, startup time, and offline synchronization. The current Flutter implementation shows "
        "strong architectural patterns (Clean Architecture, Riverpod DI) but significant performance gaps "
        "in provider lifecycle management and widget rebuild optimization.",
        s_body
    ))

    story.append(Paragraph("4.1 Provider Lifecycle — AutoDispose", s_h2))
    story.append(Paragraph(
        "The absence of AutoDispose across all 248 StateNotifierProvider instances is the single most "
        "impactful Flutter performance issue. When users navigate away from a page, its providers remain "
        "alive indefinitely, holding all state data, subscriptions, and resources in memory. For example, "
        "the CCMS module alone creates 14 StateNotifierProvider instances in ccms_providers.dart, all "
        "eagerly watched by the CCMS dashboard. With 28 feature modules and typical navigation patterns, "
        "a user session visiting 5-6 features accumulates 50-80 permanently-live providers. Over a 30-minute "
        "session, this can consume 100-500MB of additional memory, eventually triggering OS-level memory "
        "pressure and potential app termination on mobile devices. Converting all providers to AutoDispose "
        "would eliminate this progressive memory leak entirely, as providers would be automatically disposed "
        "when no widget watches them.",
        s_body
    ))

    story.append(Paragraph("4.2 Selective Rebuilds — ref.watch().select()", s_h2))
    story.append(Paragraph(
        "Zero usage of ref.watch(provider.select(...)) means every state change triggers a full widget "
        "rebuild, even when only one field changed. For example, ref.watch(authProvider) in the root "
        "ExamForgeApp widget rebuilds the entire MaterialApp when any auth field changes (isLoading, error, "
        "emailVerified, user, etc.). If only isLoading transitions from true to false, only the loading "
        "indicator should rebuild, not the entire widget tree. Adding selective rebuilds for the 20 most "
        "frequently-watched providers would reduce widget rebuilds by an estimated 10-50x, significantly "
        "improving UI responsiveness and reducing CPU usage on mobile devices.",
        s_body
    ))

    story.append(Paragraph("4.3 Startup Time Optimization", s_h2))
    story.append(Paragraph(
        "App initialization in main.dart (lines 43-68) runs EnvConfig.initialize(), SupabaseConfig.initialize(), "
        "and AppConfig.initialize() sequentially. Since these are largely independent operations, they could "
        "run in parallel via Future.wait(), potentially reducing cold start time by 30-40%. Additionally, "
        "the monolithic dependency_injection.dart file (~100KB, 2000+ lines) creates all providers for all "
        "features upfront, including features the user may never visit (super admin, marketplace, billing). "
        "The UncontrolledProviderScope used at line 72 bypasses Riverpod's lifecycle management, providing "
        "no automatic disposal or cleanup. Converting to ProviderScope with AutoDispose providers and lazy "
        "feature registration would significantly improve startup time and memory footprint.",
        s_body
    ))

    story.append(Paragraph("4.4 Image Loading &amp; Memory Management", s_h2))
    story.append(Paragraph(
        "The PerformanceManager includes an ImageOptimizer with adaptive loading based on connection quality, "
        "but no widget uses getOptimizedUrl(). The cached_network_image package is a dependency but may not "
        "be consistently used in widget pages — some may use Image.network directly, missing the caching "
        "benefit. The MemoryManager component provides memory pressure detection and cache cleanup, but "
        "clearCaches() is never called by any low-memory handler. The local_database.dart "
        "getDatabaseSize() method (lines 632-661) runs SELECT * FROM table for all 12 tables to count rows, "
        "loading every row into memory instead of using SELECT COUNT(*). These patterns indicate that while "
        "the infrastructure for memory-efficient operation exists, it is not integrated into the application.",
        s_body
    ))

    story.append(Paragraph("4.5 Offline Synchronization Performance", s_h2))
    story.append(Paragraph(
        "The sync_engine.dart (2002 lines) provides a comprehensive offline-first sync with priority queue, "
        "conflict resolution, and exponential backoff. However, it processes sync items individually without "
        "batching — syncing 50 questions after an offline exam requires 50 individual HTTP requests instead "
        "of a single batch RPC call. There is no concurrency limiting, so 100 queued items may all be "
        "processed simultaneously, overwhelming the server. The draft syncing pattern in "
        "offline_remote_datasource.dart (lines 236-243) uses a sequential for loop instead of batch upsert, "
        "making 100 drafts = 100 sequential HTTP requests. The recommended batch sync approach groups "
        "operations by table and sends them as a single batch RPC, reducing sync time by 90%+ for bulk operations.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 5 — AI PERFORMANCE
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 5 — AI Performance", s_h1))
    story.append(Paragraph(
        "AI performance analysis covers token usage optimization, response latency reduction, provider "
        "fallback timing, cache hit rate improvement, and cost per request minimization. The current "
        "AI service configuration uses GPT-4o as the default model for all operations, lacks any response "
        "caching, has no retry mechanism for transient failures, performs sequential validation, truncates "
        "documents at 8,000 characters, and has no provider fallback chain. These issues combine to create "
        "both high operational costs and poor resilience.",
        s_body
    ))

    story.append(Paragraph("5.1 Cost Optimization Analysis", s_h2))
    story.append(Paragraph(
        "At current GPT-4o pricing ($0.005/1K input, $0.015/1K output), 1,000 question generations per "
        "day with average 4K input + 2K output tokens costs approximately $60/day ($1,800/month). Switching "
        "to GPT-4o-mini for question generation ($0.00015/1K input, $0.0006/1K output) reduces this to "
        "$2.40/day ($72/month) — a 96% cost reduction with comparable quality for standard multiple-choice "
        "and short-answer question generation. GPT-4o should be reserved for complex operations like document "
        "analysis, essay grading, and multi-step reasoning tasks where the additional capability justifies the "
        "cost. Adding AI response caching with deterministic keys derived from input parameters would further "
        "reduce costs by 30-50% for common generation patterns where multiple teachers request similar questions.",
        s_body
    ))

    # Cost table by school count
    ai_cost_schools = [
        ['Schools', 'Est. Generations/Day', 'Current Monthly Cost', 'Optimized Monthly Cost', 'Savings'],
        ['10', '100', '$180', '$7.20', '96%'],
        ['100', '1,000', '$1,800', '$72', '96%'],
        ['1,000', '10,000', '$18,000', '$720', '96%'],
        ['10,000', '100,000', '$180,000', '$7,200', '96%'],
    ]
    story.append(make_table(
        ['Schools', 'Gen/Day', 'Current Mo. Cost', 'Optimized Mo. Cost', 'Savings'],
        ai_cost_schools[1:],
        [CONTENT_W*0.13, CONTENT_W*0.17, CONTENT_W*0.22, CONTENT_W*0.25, CONTENT_W*0.13]
    ))
    story.append(Paragraph(
        "<i>Cost estimates assume average 4K input + 2K output tokens per generation. "
        "Current = GPT-4o, no caching. Optimized = GPT-4o-mini + 30% cache hit rate + request batching. "
        "Estimates are Engineering Estimates (EE), not measured values.</i>",
        s_caption
    ))

    story.append(Paragraph("5.2 Latency Optimization", s_h2))
    story.append(Paragraph(
        "AI response latency is dominated by three factors: model selection, validation strategy, and retry "
        "behavior. GPT-4o has typical response times of 2-8 seconds for question generation, while GPT-4o-mini "
        "responds in 0.5-3 seconds for equivalent tasks — a 2-4x latency improvement. Sequential validation "
        "(ai_service.dart:377-386) adds 50ms per question validated; for 10 questions this adds 500ms of "
        "sequential work that could be reduced to approximately 50ms with Future.wait() parallel validation. "
        "Without retry logic, a single transient failure (429, 502, 503) results in a complete generation "
        "failure that requires user intervention. Adding exponential backoff retry (1s, 2s, 4s) would "
        "automatically recover from most transient failures within 7 seconds, versus indefinite failure.",
        s_body
    ))

    story.append(Paragraph("5.3 Provider Fallback &amp; Resilience", s_h2))
    story.append(Paragraph(
        "The AiProvidersRegistry supports multiple providers (OpenAI, Gemini) but the AiService does not "
        "implement automatic failover. When the specified provider is unavailable, the request immediately "
        "fails even if an alternative provider is configured. The recommended implementation is a provider "
        "fallback chain: try primary provider (OpenAI) with 30-second timeout, on failure try secondary "
        "(Gemini) with same timeout, on failure try local LLM if available. This ensures AI features "
        "remain functional during provider outages, which is critical for a platform serving real-time "
        "examination and tutoring use cases. Additionally, the token estimation heuristic (text.length/4) "
        "is wildly inaccurate for non-English text common in Nigerian education (Yoruba, Igbo, Hausa), "
        "potentially causing silent prompt truncation or over-requesting tokens.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASES 6-8 — LOAD / STRESS / SOAK TESTING
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phases 6-8 — Load, Stress &amp; Soak Testing", s_h1))
    story.append(Paragraph(
        "Load testing, stress testing, and soak testing require a running Supabase instance with production-like "
        "data volumes and cannot be performed through static code analysis alone. This section provides the "
        "testing framework, scripts, and methodology for executing these tests, along with engineering estimates "
        "of expected behavior based on the code analysis findings. All values in this section are explicitly "
        "marked as Engineering Estimates (EE) and must be validated through actual testing before production deployment.",
        s_body
    ))

    story.append(Paragraph("6.1 Load Testing Framework", s_h2))
    story.append(Paragraph(
        "Load testing should simulate realistic production traffic patterns using k6 (Grafana) or Artillery "
        "as the load generation tool. The test scenarios should model the following user personas and their "
        "typical request patterns: (1) Student taking CBT exam — 1 exam load + 50 answer submissions over "
        "60 minutes, (2) Teacher creating exam — 1 exam creation + 20 question additions over 10 minutes, "
        "(3) School admin viewing dashboard — 1 dashboard load every 5 minutes, (4) AI question generation — "
        "1 generation request per 5 minutes per active teacher. Each concurrency level (100, 500, 1,000, "
        "5,000, 10,000) should run for at least 15 minutes at steady state after ramp-up to capture "
        "representative latency and throughput data.",
        s_body
    ))

    load_est = [
        ['Concurrency', 'Est. Throughput', 'Est. Avg Latency', 'Est. Error Rate', 'Est. First Bottleneck'],
        ['100 users', '200-400 req/s', '100-300ms', '< 1%', 'AI provider rate limits'],
        ['500 users', '800-1,500 req/s', '200-500ms', '1-3%', 'Supabase connection pool'],
        ['1,000 users', '1,500-2,500 req/s', '300-800ms', '3-7%', 'RLS subquery overhead'],
        ['5,000 users', '3,000-5,000 req/s', '800-3,000ms', '10-25%', 'DB connection exhaustion'],
        ['10,000 users', '4,000-6,000 req/s', '3,000-10,000ms', '25-50%', 'Full system overload'],
    ]
    story.append(make_table(
        ['Concurrency', 'Est. Throughput', 'Est. Avg Latency', 'Est. Error Rate', 'Est. First Bottleneck'],
        load_est[1:],
        [CONTENT_W*0.12, CONTENT_W*0.18, CONTENT_W*0.17, CONTENT_W*0.15, CONTENT_W*0.28]
    ))
    story.append(Paragraph(
        "<i>All values are Engineering Estimates (EE) based on static code analysis. "
        "Actual results depend on Supabase plan limits, AI provider quotas, and infrastructure configuration. "
        "Must be validated through live testing.</i>",
        s_caption
    ))

    story.append(Paragraph("6.2 Expected Bottleneck Progression", s_h2))
    story.append(Paragraph(
        "Based on code analysis, the expected bottleneck progression under increasing load is: "
        "(1) At 100 concurrent users, AI provider rate limits (OpenAI: 500 RPM on standard tier) will "
        "be the first bottleneck for AI-heavy workloads. (2) At 500 concurrent users, Supabase's default "
        "connection pool (60 direct connections on Pro plan) will saturate due to unbounded queries and "
        "parallel fetch patterns (6 queries per dashboard load). (3) At 1,000 concurrent users, RLS "
        "subquery overhead will cause database CPU saturation as get_user_role() executes millions of "
        "subqueries. (4) At 5,000 concurrent users, database connection exhaustion will cause cascading "
        "failures as queries queue for available connections. (5) At 10,000 concurrent users, the system "
        "will experience full overload with no single bottleneck — every layer will be saturated.",
        s_body
    ))

    story.append(Paragraph("7.1 Stress Testing Methodology", s_h2))
    story.append(Paragraph(
        "Stress testing should push the system beyond expected limits until failure, identifying the first "
        "bottleneck, maximum sustainable throughput, recovery behavior, and failure modes. The recommended "
        "approach is: (1) Start at 1,000 concurrent users and increase by 500 every 5 minutes until error "
        "rate exceeds 10%, (2) Record the concurrency level and request type at first degradation, "
        "(3) Continue increasing until system becomes unresponsive, (4) Stop load and measure time to "
        "recovery. Expected first failure mode: database connection exhaustion causing Supabase to return "
        "503 errors, which will cascade to all API endpoints since every operation requires database access. "
        "Expected maximum sustainable throughput: approximately 2,000-3,000 requests/second based on "
        "Supabase Pro plan limits and current query patterns (Engineering Estimate).",
        s_body
    ))

    story.append(Paragraph("8.1 Soak Testing Methodology", s_h2))
    story.append(Paragraph(
        "Soak testing should run for 24-72 hours at 500 concurrent users to detect memory leaks, resource "
        "exhaustion, connection leaks, and performance degradation over time. Based on code analysis, the "
        "following issues are expected to manifest during soak testing: (1) Flutter memory leak from "
        "non-AutoDispose providers — estimated 50-100MB/hour growth on client devices, causing OOM after "
        "3-6 hours of continuous use. (2) DatabasePoolManager FIFO cache growing without bound if "
        "executeCached() is used, since eviction only triggers at 200 entries. (3) Edge function cold "
        "starts accumulating as Deno runtime recycles instances, causing periodic latency spikes. "
        "(4) Metrics tables growing without partitioning, causing increasing query times over the test "
        "duration. (5) Sync queue items accumulating if network conditions are poor, causing eventual "
        "storage exhaustion on client devices.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 9 — SCALABILITY REVIEW
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 9 — Scalability Review", s_h1))
    story.append(Paragraph(
        "Scalability review evaluates ExamForge AI's readiness for growth from pilot (10 schools) through "
        "enterprise (10,000 schools) deployment, examining database scaling, horizontal scaling, background "
        "jobs, queue processing, storage, CDN usage, rate limiting, and Edge Function capacity.",
        s_body
    ))

    scale_data = [
        ['Dimension', '10 Schools', '100 Schools', '1,000 Schools', '10,000 Schools'],
        ['DB Connections', 'Adequate (60 pool)', 'Marginal (60 pool)', 'Insufficient (need 200+)', 'Need PgBouncer + read replicas'],
        ['RLS Overhead', 'Low (5K users)', 'Moderate (50K users)', 'High (500K users)', 'Critical (5M users)'],
        ['Storage', '< 1 GB', '5-10 GB', '50-100 GB', '500 GB-1 TB'],
        ['AI Cost/Month', '$7 (opt.)', '$72 (opt.)', '$720 (opt.)', '$7,200 (opt.)'],
        ['Edge Functions', 'Adequate', 'Adequate', 'Need caching', 'Need dedicated compute'],
        ['Background Jobs', 'Not needed', 'Simple queue', 'Redis/BullMQ', 'Distributed workers'],
        ['CDN', 'Not needed', 'Beneficial', 'Required', 'Required + edge caching'],
        ['Rate Limiting', 'Basic', 'Per-tenant', 'Per-tenant + per-endpoint', 'Adaptive + circuit breaker'],
        ['Read Replicas', 'Not needed', 'Beneficial', 'Required', 'Required + sharding'],
    ]
    story.append(make_table(
        ['Dimension', '10 Schools', '100 Schools', '1K Schools', '10K Schools'],
        scale_data[1:],
        [CONTENT_W*0.18, CONTENT_W*0.20, CONTENT_W*0.20, CONTENT_W*0.21, CONTENT_W*0.21]
    ))

    story.append(Paragraph("9.1 Database Scaling Path", s_h2))
    story.append(Paragraph(
        "The multi-tenant architecture (logical isolation via school_id) is well-suited for scaling to "
        "1,000 schools but will encounter fundamental limits beyond that. At 10,000 schools with an average "
        "of 500 users per school, the users table alone would contain 5 million rows. RLS policies evaluating "
        "get_user_role() per row would generate billions of subqueries per day. The recommended scaling path "
        "is: (1) Phase 1 — Replace RLS helper functions with JWT claims (immediate, 40-60% query load "
        "reduction), (2) Phase 2 — Enable Supabase connection pooler in transaction mode with PgBouncer "
        "(supports 1,000 concurrent connections), (3) Phase 3 — Add read replicas for analytics and "
        "reporting queries (offloads 30-50% of read traffic from primary), (4) Phase 4 — Implement table "
        "partitioning for metrics and audit tables (prevents performance degradation as data grows), "
        "(5) Phase 5 — Consider schema-level isolation for schools requiring regulatory compliance, "
        "(6) Phase 6 — Evaluate Citus or similar PostgreSQL sharding extension for 10,000+ schools.",
        s_body
    ))

    story.append(Paragraph("9.2 Horizontal Scaling Considerations", s_h2))
    story.append(Paragraph(
        "The Flutter client is inherently horizontally scalable since it runs on each user's device. "
        "Supabase provides built-in horizontal scaling for Edge Functions (Deno Deploy automatically scales "
        "instances). The primary horizontal scaling bottleneck is the PostgreSQL database, which is a "
        "single-writer system. For read-heavy workloads (which represent 80-90% of educational platform "
        "traffic), read replicas provide effective horizontal scaling. Write-heavy operations (exam answer "
        "submissions, AI generation requests) may require dedicated write replicas or a queue-based "
        "architecture with async processing. Background job processing is currently absent; at 100+ schools, "
        "a Redis-backed job queue (BullMQ or similar) is needed for async operations like bulk question "
        "import, report generation, and notification dispatch.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 10 — PERFORMANCE MONITORING
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 10 — Performance Monitoring", s_h1))
    story.append(Paragraph(
        "Performance monitoring infrastructure partially exists in the codebase but is not wired into "
        "the application. The monitoring_observability.sql migration creates 7 metric tables "
        "(api_latency_metrics, ai_service_metrics, auth_metrics, payment_metrics, server_resource_metrics, "
        "storage_metrics, alert_state) with 4 dashboard views providing p50/p90/p95/p99 percentile "
        "calculations. The alerting_configuration.sql migration creates 17 seeded alert rules, escalation "
        "policies, and notification channels. The PerformanceManager includes a PerformanceMonitor component "
        "with named timers and metrics recording. However, none of these monitoring components are consumed "
        "by any feature module, meaning no actual metrics are being collected.",
        s_body
    ))

    story.append(Paragraph("10.1 Latency Monitoring Framework", s_h2))
    latency_metrics = [
        ['Metric', 'P50 Target', 'P90 Target', 'P95 Target', 'P99 Target', 'Alert Threshold'],
        ['API Latency', '< 100ms', '< 300ms', '< 500ms', '< 1,000ms', '> 2,000ms (critical)'],
        ['DB Query Latency', '< 50ms', '< 150ms', '< 300ms', '< 500ms', '> 1,000ms (critical)'],
        ['AI Response Latency', '< 2,000ms', '< 5,000ms', '< 8,000ms', '< 15,000ms', '> 30,000ms (warning)'],
        ['Edge Function Latency', '< 200ms', '< 500ms', '< 1,000ms', '< 3,000ms', '> 5,000ms (critical)'],
        ['CBT Exam Load', '< 500ms', '< 1,500ms', '< 3,000ms', '< 5,000ms', '> 10,000ms (critical)'],
        ['Dashboard Load', '< 1,000ms', '< 3,000ms', '< 5,000ms', '< 10,000ms', '> 15,000ms (warning)'],
        ['File Upload', '< 2,000ms', '< 5,000ms', '< 10,000ms', '< 30,000ms', '> 60,000ms (warning)'],
    ]
    story.append(make_table(
        ['Metric', 'P50', 'P90', 'P95', 'P99', 'Alert'],
        latency_metrics[1:],
        [CONTENT_W*0.18, CONTENT_W*0.12, CONTENT_W*0.12, CONTENT_W*0.12, CONTENT_W*0.14, CONTENT_W*0.32]
    ))

    story.append(Paragraph("10.2 Resource Monitoring &amp; Alert Thresholds", s_h2))
    story.append(Paragraph(
        "Resource monitoring should track database connection usage, cache hit rates, queue depth, and "
        "system-level metrics. The following alert thresholds are recommended based on the code analysis: "
        "Database connection usage > 80% of pool size triggers warning, > 95% triggers critical. "
        "Cache hit rate < 50% triggers warning (indicates cache misconfiguration). Queue depth > 100 items "
        "triggers warning, > 500 triggers critical. Memory usage on Flutter client > 300MB triggers warning "
        "(indicates potential memory leak). AI provider error rate > 5% triggers warning, > 15% triggers "
        "critical. Payment processing latency > 5 seconds triggers critical (user experience impact). "
        "These thresholds should be implemented in the alerting_configuration.sql alert rules and connected "
        "to the notification channels (Slack, email, PagerDuty) already defined in the schema.",
        s_body
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 11 — OPTIMIZATION IMPLEMENTATION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 11 — Optimization Implementation", s_h1))
    story.append(Paragraph(
        "This phase presents a prioritized optimization roadmap with root cause analysis, expected before/after "
        "metrics, engineering effort estimates, trade-offs, and validation methods for each optimization. "
        "Optimizations are ordered by impact-to-effort ratio, with the highest-value items first. Every "
        "recommendation is based on static code analysis evidence and must be validated through testing after "
        "implementation.",
        s_body
    ))

    optimizations = [
        ['#', 'Optimization', 'Root Cause', 'Before (Est.)', 'After (Est.)', 'Effort', 'Risk'],
        ['1', 'Replace RLS helpers with JWT claims', 'get_user_role() subquery per row', 'Millions of subqueries/day', 'Zero DB lookups for RLS', 'Medium', 'Low'],
        ['2', 'Add AutoDispose to all providers', 'Zero AutoDispose on 248 providers', 'Progressive memory leak', 'Automatic memory release', 'Medium', 'Low'],
        ['3', 'Add pagination to all list queries', '86.4% queries unbounded', 'OOM risk, multi-second latency', '< 50ms list loads', 'Medium', 'Low'],
        ['4', 'Switch AI default to GPT-4o-mini', 'GPT-4o for all operations', '$1,800/month (1K schools)', '$72/month (1K schools)', 'Low', 'Low'],
        ['5', 'Add AI response caching', 'No caching of identical requests', '100% redundant API calls', '30-50% cache hit rate', 'Medium', 'Low'],
        ['6', 'Wire PerformanceManager into features', '1,220 lines of dead code', 'No batching/caching/monitoring', '30-50% API call reduction', 'High', 'Low'],
        ['7', 'Fix process-refund race condition', 'No atomic read-update on refund amount', 'Over-refund possible', 'Atomic refund processing', 'Low', 'Critical'],
        ['8', 'Add retry with backoff to API client', 'No retry on transient failures', '100% failure on timeout', '90%+ transient recovery', 'Low', 'Low'],
        ['9', 'Add token refresh mutex', 'Race condition on concurrent 401s', 'Duplicate refresh attempts', 'Single refresh per expiry', 'Low', 'Low'],
        ['10', 'Parallelize AI validation', 'Sequential for-loop validation', '500ms for 10 questions', '~50ms for 10 questions', 'Low', 'Low'],
        ['11', 'Add missing composite indexes', 'No index on RLS hot paths', 'Sequential scans on RLS evaluation', 'Index-only scans', 'Low', 'Low'],
        ['12', 'Implement table partitioning', 'No partitioning on metrics tables', 'Growing query times', 'Constant query times', 'High', 'Medium'],
        ['13', 'Configure PgBouncer connection pooling', 'No connection pool config', '60 connection limit', '1,000+ concurrent connections', 'Medium', 'Medium'],
        ['14', 'Add gzip compression to API headers', 'No Accept-Encoding: gzip', 'Full-size JSON responses', '60-80% response size reduction', 'Low', 'Low'],
        ['15', 'Add provider fallback chain', 'No failover on AI provider outage', 'Complete AI feature failure', 'Graceful degradation', 'Medium', 'Medium'],
    ]
    story.append(make_table(
        ['#', 'Optimization', 'Root Cause', 'Before', 'After', 'Effort', 'Risk'],
        optimizations[1:],
        [CONTENT_W*0.04, CONTENT_W*0.20, CONTENT_W*0.20, CONTENT_W*0.16, CONTENT_W*0.18, CONTENT_W*0.10, CONTENT_W*0.12]
    ))

    story.append(PageBreak())

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 12 — FINAL PERFORMANCE CERTIFICATION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Paragraph("Phase 12 — Final Performance Certification", s_h1))
    story.append(Paragraph(
        "The Final Performance Certification synthesizes all findings across the 12-phase audit into a "
        "comprehensive readiness assessment. Scores are based on static code analysis and engineering "
        "estimates, not live measurements. The certification evaluates the platform's current state against "
        "production readiness criteria for each deployment scale.",
        s_body
    ))

    story.append(Paragraph("12.1 Benchmark Summary", s_h2))
    benchmark_data = [
        ['Metric', 'Current (Est.)', 'Production Target', 'Gap Assessment'],
        ['Cold Start Time', '3-5 seconds (SA)', '< 2 seconds', 'Significant — sequential init, no lazy loading'],
        ['API Avg Latency', '200-500ms (EE)', '< 100ms', 'Moderate — unbounded queries, no caching'],
        ['DB Query Avg Latency', '100-500ms (EE)', '< 50ms', 'Critical — RLS subqueries, missing indexes'],
        ['AI Response Latency', '2-8 seconds (EE)', '< 3 seconds', 'Moderate — model selection, no caching'],
        ['CBT Exam Load Time', '2-5 seconds (EE)', '< 1 second', 'Critical — unbounded queries, N+1 pattern'],
        ['Dashboard Load Time', '3-8 seconds (EE)', '< 2 seconds', 'Critical — count-via-select, parallel fetches'],
        ['List Query Data Transfer', '100-500KB per page (EE)', '< 20KB per page', 'Critical — select-star, no pagination'],
        ['Memory Usage (30min session)', '300-500MB growth (EE)', '< 100MB growth', 'Critical — no AutoDispose, memory leaks'],
    ]
    story.append(make_table(
        ['Metric', 'Current (Est.)', 'Target', 'Gap Assessment'],
        benchmark_data[1:],
        [CONTENT_W*0.22, CONTENT_W*0.22, CONTENT_W*0.18, CONTENT_W*0.38]
    ))
    story.append(Paragraph(
        "<i>SA = Static Analysis, EE = Engineering Estimate. No live measurements were taken. "
        "All estimates must be validated through benchmarking.</i>",
        s_caption
    ))

    story.append(Paragraph("12.2 Scalability Score", s_h2))
    final_scores = [
        ['Flutter Performance', '35/100', 'F', 'Critical memory leaks, no selective rebuilds, unused PerformanceManager'],
        ['Backend Performance', '40/100', 'D', 'No retry, no caching wired in, no compression, token race condition'],
        ['Database Performance', '30/100', 'F', 'RLS subquery overload, missing indexes, no pagination, no partitioning'],
        ['AI Performance', '25/100', 'F', 'GPT-4o default, no caching, no fallback, no retry, sequential validation'],
        ['Infrastructure Scalability', '45/100', 'D', 'No connection pooling, no rate limiting, no partitioning, no CDN'],
        ['Load Handling', '20/100', 'F', 'Unvalidated at scale, known bottlenecks unaddressed, no load tests run'],
        ['Monitoring', '50/100', 'D', 'Infrastructure exists but is not wired into application, no metrics collected'],
        ['Overall Performance Score', '32/100', 'F', 'Not production-ready for any scale without critical fixes'],
    ]
    story.append(make_score_table(final_scores))

    story.append(Paragraph("12.3 Launch Readiness Assessment", s_h2))
    launch_detail = [
        ['Scale', 'Ready', 'Remaining Bottlenecks', 'Required Infrastructure', 'Est. Engineering', 'Risk'],
        ['10 schools', 'No', 'Memory leaks, unbounded queries, AI cost, refund race condition', 'Connection pooling, basic monitoring', '4-6 weeks', 'High'],
        ['100 schools', 'No', 'All above + RLS overload, no rate limiting, no caching', 'PgBouncer, read replica, CDN, job queue', '8-12 weeks', 'Critical'],
        ['1,000 schools', 'No', 'All above + connection exhaustion, DB partitioning', 'Full optimization + partitioning + replicas', '16-24 weeks', 'Critical'],
        ['10,000 schools', 'No', 'Full architecture redesign required', 'Sharding, dedicated compute, global CDN', '6-12 months', 'Critical'],
    ]
    story.append(make_table(
        ['Scale', 'Ready', 'Bottlenecks', 'Infrastructure', 'Effort', 'Risk'],
        launch_detail[1:],
        [CONTENT_W*0.10, CONTENT_W*0.08, CONTENT_W*0.28, CONTENT_W*0.25, CONTENT_W*0.12, CONTENT_W*0.10]
    ))

    story.append(Paragraph("12.4 Prioritized Optimization Roadmap", s_h2))
    story.append(Paragraph(
        "The following roadmap presents optimizations in execution order, grouped by sprint. Each sprint "
        "targets the highest-impact, lowest-risk improvements first. The full optimization program is "
        "estimated at 16-24 weeks of engineering effort for a team of 2-3 developers.",
        s_body
    ))

    roadmap = [
        ['Sprint', 'Optimizations', 'Expected Outcome', 'Duration'],
        ['Sprint 1\n(Weeks 1-2)', 'Fix refund race condition, add AutoDispose, add pagination to top-10 queries', 'Eliminate memory leaks, prevent over-refunding, reduce list load times 10x', '2 weeks'],
        ['Sprint 2\n(Weeks 3-4)', 'Replace RLS helpers with JWT claims, add missing composite indexes', '40-60% database query load reduction, eliminate RLS subquery overhead', '2 weeks'],
        ['Sprint 3\n(Weeks 5-6)', 'Switch to GPT-4o-mini, add AI caching, add retry with backoff', '96% AI cost reduction, eliminate transient failures, 30% cache hit rate', '2 weeks'],
        ['Sprint 4\n(Weeks 7-8)', 'Wire PerformanceManager, add token refresh mutex, add gzip headers', '30-50% API call reduction, prevent auth race conditions, 60-80% compression', '2 weeks'],
        ['Sprint 5\n(Weeks 9-10)', 'Add select() column specification, parallelize AI validation, fix count queries', '50-80% data transfer reduction, 10x faster validation, 99% count optimization', '2 weeks'],
        ['Sprint 6\n(Weeks 11-12)', 'Configure PgBouncer, implement table partitioning, add rate limiting', '1,000+ concurrent connections, constant query times over time, abuse prevention', '2 weeks'],
        ['Sprint 7\n(Weeks 13-14)', 'Add provider fallback chain, implement batch sync, wire monitoring', 'AI resilience, 90% sync time reduction, full metrics collection', '2 weeks'],
        ['Sprint 8\n(Weeks 15-16)', 'Load testing, stress testing, soak testing, performance validation', 'Measured benchmarks replacing all engineering estimates', '2 weeks'],
    ]
    story.append(make_table(
        ['Sprint', 'Optimizations', 'Expected Outcome', 'Duration'],
        roadmap[1:],
        [CONTENT_W*0.12, CONTENT_W*0.35, CONTENT_W*0.38, CONTENT_W*0.10]
    ))

    story.append(Spacer(1, 10*mm))
    story.append(hr())
    story.append(Paragraph(
        "This Performance Certification Report is based entirely on static code analysis and engineering "
        "estimates. No live performance measurements were taken. All findings must be validated through "
        "comprehensive benchmarking, load testing, and stress testing before the results can be relied "
        "upon for production deployment decisions. The overall performance score of 32/100 (Grade F) "
        "indicates that ExamForge AI is not currently production-ready at any scale and requires the "
        "implementation of critical optimizations identified in this report before pilot deployment.",
        ParagraphStyle('FinalNote', parent=s_body, fontSize=8.5, textColor=TEXT_MUTED,
            borderWidth=1, borderColor=BORDER, borderPadding=8)
    ))

    # ─── Build PDF ─────────────────────────────────────────────────────────
    doc.build(story)
    print(f"Report generated: {OUTPUT_PATH}")
    return OUTPUT_PATH

if __name__ == '__main__':
    build_report()
