#!/usr/bin/env python3
"""
ExamForge AI — Production Hardening Deliverables Generator
Generates all remaining PDF deliverables.
"""

import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor, black, white
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable
)
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY

OUTPUT_DIR = "/home/z/my-project/download"
os.makedirs(OUTPUT_DIR, exist_ok=True)

PRIMARY = HexColor("#1E3A5F")
ACCENT = HexColor("#2563EB")
SUCCESS = HexColor("#059669")
WARNING = HexColor("#D97706")
DANGER = HexColor("#DC2626")
BORDER = HexColor("#E2E8F0")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='CT', fontName='Helvetica-Bold', fontSize=24, leading=30, textColor=PRIMARY, alignment=TA_CENTER, spaceAfter=12))
styles.add(ParagraphStyle(name='CS', fontName='Helvetica', fontSize=12, leading=16, textColor=HexColor("#64748B"), alignment=TA_CENTER, spaceAfter=8))
styles.add(ParagraphStyle(name='ST', fontName='Helvetica-Bold', fontSize=16, leading=22, textColor=PRIMARY, spaceBefore=16, spaceAfter=8))
styles.add(ParagraphStyle(name='SST', fontName='Helvetica-Bold', fontSize=12, leading=16, textColor=ACCENT, spaceBefore=10, spaceAfter=4))
styles.add(ParagraphStyle(name='BT', fontName='Helvetica', fontSize=10, leading=14, textColor=HexColor("#334155"), alignment=TA_JUSTIFY, spaceAfter=6))
styles.add(ParagraphStyle(name='BL', fontName='Helvetica', fontSize=10, leading=14, textColor=HexColor("#334155"), leftIndent=20, spaceAfter=3))

def st(t): return Paragraph(t, styles['ST'])
def sst(t): return Paragraph(t, styles['SST'])
def bt(t): return Paragraph(t, styles['BT'])
def bl(t): return Paragraph(f"\u2022 {t}", styles['BL'])
def hr(): return HRFlowable(width="100%", thickness=1, color=BORDER, spaceAfter=8, spaceBefore=8)
def sp(h=6): return Spacer(1, h*mm)

def make_doc(filename, title, subtitle_text, build_func):
    filepath = os.path.join(OUTPUT_DIR, filename)
    doc = SimpleDocTemplate(filepath, pagesize=A4, leftMargin=2*cm, rightMargin=2*cm, topMargin=2*cm, bottomMargin=2*cm)
    story = []
    story.append(Spacer(1, 60))
    story.append(Paragraph("ExamForge AI", styles['CT']))
    story.append(Paragraph(title, styles['CT']))
    story.append(Spacer(1, 16))
    story.append(Paragraph(subtitle_text, styles['CS']))
    story.append(Paragraph("August 2, 2026", styles['CS']))
    story.append(Spacer(1, 40))
    story.append(hr())
    story.append(PageBreak())
    build_func(story)
    doc.build(story)
    print(f"Generated: {filepath}")

# ── Production Checklist ────────────────────────────────────
def build_checklist(story):
    story.append(st("Production Readiness Checklist"))
    story.append(bt("This checklist verifies every critical production requirement. Each item is marked as DONE, PARTIAL, or NOT VERIFIED based on the evidence from the hardening phase."))
    story.append(sp(10))

    items = [
        ("Authentication & Authorization", [
            ("Centralized auth helper (requireAuth)", "DONE"),
            ("Middleware RBAC enforcement", "DONE"),
            ("Role-based route protection", "DONE"),
            ("Server action auth verification", "DONE"),
            ("API route auth verification", "DONE"),
            ("Signup forces student role", "DONE"),
            ("Deactivated user redirect", "DONE"),
        ]),
        ("Data Isolation", [
            ("School-scoped queries", "DONE"),
            ("Teacher-scoped queries", "DONE"),
            ("Student-scoped queries (own data only)", "DONE"),
            ("No cross-school data leakage", "DONE"),
            ("Notification ownership verification", "DONE"),
            ("School ownership verification", "DONE"),
        ]),
        ("Security Headers", [
            ("Content-Security-Policy", "DONE"),
            ("X-Frame-Options: DENY", "DONE"),
            ("X-Content-Type-Options: nosniff", "DONE"),
            ("Referrer-Policy", "DONE"),
            ("Permissions-Policy", "DONE"),
            ("Strict-Transport-Security", "DONE"),
            ("X-XSS-Protection", "DONE"),
        ]),
        ("Environment & Secrets", [
            (".env.example created", "DONE"),
            (".gitignore excludes .env*", "DONE"),
            ("No secrets in source code", "DONE"),
            ("NEXT_PUBLIC_ vars properly used", "DONE"),
        ]),
        ("Performance", [
            ("N+1 queries removed", "DONE"),
            ("Parallel queries via Promise.all", "DONE"),
            ("Batch aggregate queries", "DONE"),
            ("Query scoping by role", "DONE"),
        ]),
        ("Error Handling", [
            ("Global error boundary", "DONE"),
            ("Loading states on all pages", "DONE"),
            ("Empty states on data tables", "DONE"),
            ("Error states with retry", "DONE"),
            ("Structured API error responses", "DONE"),
        ]),
        ("Build & Lint", [
            ("Production build passes", "DONE"),
            ("0 TypeScript errors", "DONE"),
            ("0 ESLint errors", "DONE"),
            ("Standalone output configured", "DONE"),
        ]),
        ("Infrastructure (NOT VERIFIED)", [
            ("Supabase RLS policies configured", "NOT VERIFIED"),
            ("Supabase Storage access policies", "NOT VERIFIED"),
            ("Rate limiting at CDN/proxy level", "NOT VERIFIED"),
            ("Flutterwave webhook HMAC verification", "NOT VERIFIED"),
            ("Sentry/observability connected", "NOT VERIFIED"),
            ("End-to-end tests", "NOT VERIFIED"),
            ("Load testing", "NOT VERIFIED"),
        ]),
    ]

    for category, checks in items:
        story.append(sst(category))
        data = [["Item", "Status"]]
        for item, status in checks:
            data.append([item, status])
        t = Table(data, colWidths=[350, 100])
        color = SUCCESS if "NOT VERIFIED" not in category else WARNING
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
            ('TEXTCOLOR', (0, 0), (-1, 0), white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 9),
            ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [white, HexColor("#F8FAFC")]),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ]))
        story.append(t)
        story.append(sp(8))

# ── Architecture Status ────────────────────────────────────
def build_architecture(story):
    story.append(st("Architecture Status Report"))
    story.append(bt("The ExamForge AI architecture remains unchanged from the original design. The hardening phase focused on improving the quality of the existing architecture without introducing new patterns or replacing existing components."))
    story.append(sp(8))

    story.append(sst("Technology Stack (Unchanged)"))
    stack = [
        ["Layer", "Technology", "Status"],
        ["Framework", "Next.js 16 App Router", "Production Ready"],
        ["Runtime", "React 19 Server Components", "Production Ready"],
        ["Styling", "Tailwind CSS v4 + shadcn/ui", "Production Ready"],
        ["State", "Zustand + TanStack Query", "Production Ready"],
        ["Auth", "Supabase Auth (cookie-based)", "Production Ready"],
        ["Database", "Supabase PostgreSQL", "Production Ready"],
        ["Realtime", "Supabase Realtime", "Production Ready"],
        ["Validation", "Zod 4", "Production Ready"],
        ["Build", "Next.js Standalone Output", "Production Ready"],
    ]
    t = Table(stack, colWidths=[120, 200, 120])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [white, HexColor("#F8FAFC")]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(sp(8))

    story.append(sst("New Components Added"))
    story.append(bl("src/lib/auth/require-auth.ts — Centralized auth helper with requireAuth(), requireRole(), requireAnyRole(), getAuthUser(), canAccessResource()"))
    story.append(bl("src/lib/utils/logger.ts — Enterprise logger with structured logging, sanitization, and security-aware logging"))
    story.append(bl(".env.example — Documented environment variables with no actual secrets"))

    story.append(sst("Modified Components"))
    story.append(bl("src/middleware.ts — Complete rewrite with RBAC route mapping and role-based redirect"))
    story.append(bl("next.config.ts — Added 7 security headers (CSP, HSTS, X-Frame-Options, etc.)"))
    story.append(bl("src/lib/types.ts — Added 'parent' to UserRole type"))
    story.append(bl("src/lib/constants/routes.ts — Added parent role to ROLE_ROUTE_ACCESS"))
    story.append(bl("All dashboard pages — Use requireAuth/requireAnyRole instead of manual auth checks"))
    story.append(bl("All services — Scoped queries by role and school_id"))
    story.append(bl("All server actions — Verify auth, role, and ownership before mutations"))
    story.append(bl("All API routes — Use getAuthUser() with proper error responses"))

# ── Technical Debt Report ──────────────────────────────────
def build_debt(story):
    story.append(st("Technical Debt Report"))
    story.append(bt("This report documents the remaining technical debt after the production hardening phase. Items are categorized by severity and impact."))
    story.append(sp(8))

    story.append(sst("Resolved Debt (This Phase)"))
    resolved = [
        ["Item", "Resolution", "Impact"],
        ["Fragmented RBAC logic", "Centralized in requireAuth helper", "Critical"],
        ["N+1 queries in analytics", "Replaced with batch aggregate queries", "High"],
        ["N+1 queries in reports", "Replaced with batch queries", "High"],
        ["No security headers", "Added 7 security headers", "Critical"],
        ["Unverified server actions", "Added auth/role/ownership checks", "Critical"],
        ["Cross-school data leakage", "Scoped all queries by role/school", "Critical"],
        ["No notification ownership check", "Added user_id verification", "Critical"],
        ["No school ownership check", "Added school_id verification", "Critical"],
        ["console.error in error boundary", "Replaced with enterprise logger", "Medium"],
        ["Missing 'parent' role", "Added to UserRole and route maps", "Medium"],
        ["No .env.example", "Created with documented variables", "Low"],
        ["Broken utils barrel export", "Fixed Logger export reference", "Low"],
    ]
    t = Table(resolved, colWidths=[180, 180, 80])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 0.5, BORDER),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [white, HexColor("#F8FAFC")]),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(sp(8))

    story.append(sst("Remaining Debt"))
    story.append(bl("CSP 'unsafe-inline' and 'unsafe-eval' — Required for Next.js/shadcn/ui; should be tightened for production"))
    story.append(bl("Prisma/SQLite db.ts — Unused in production (all services use Supabase); should be removed in future cleanup"))
    story.append(bl("next-auth in package.json — Unused dependency; should be removed"))
    story.append(bl("console.warn in realtime provider — Should use enterprise logger"))
    story.append(bl("console.warn in supabase server client — Should use enterprise logger"))
    story.append(bl("No rate limiting — Should be implemented at infrastructure level"))
    story.append(bl("No CSRF tokens — Relies on Supabase cookie auth; additional tokens recommended"))
    story.append(bl("ESLint rules nearly all disabled — Should be re-enabled progressively"))
    story.append(bl("No end-to-end tests — Testing infrastructure needs to be built"))
    story.append(bl("No load testing — Performance under load is unknown"))

# ── Deployment Guide ──────────────────────────────────────
def build_deployment(story):
    story.append(st("Deployment Guide"))
    story.append(bt("This guide provides step-by-step instructions for deploying ExamForge AI to production."))
    story.append(sp(8))

    story.append(sst("1. Prerequisites"))
    story.append(bl("Node.js 20+ and npm/bun"))
    story.append(bl("Supabase project with RLS policies configured"))
    story.append(bl("Flutterwave account for billing integration"))
    story.append(bl("Domain with SSL certificate"))
    story.append(bl("CDN/reverse proxy (Caddy, Nginx, or Cloudflare) for rate limiting"))

    story.append(sst("2. Environment Variables"))
    story.append(bl("Copy .env.example to .env.local and fill in all required values"))
    story.append(bl("NEXT_PUBLIC_SUPABASE_URL — Your Supabase project URL"))
    story.append(bl("NEXT_PUBLIC_SUPABASE_ANON_KEY — Your Supabase anon key"))
    story.append(bl("SUPABASE_SERVICE_ROLE_KEY — Required for webhook processing"))
    story.append(bl("FLUTTERWAVE_PUBLIC_KEY — Your Flutterwave public key"))
    story.append(bl("FLUTTERWAVE_SECRET_KEY — Your Flutterwave secret key"))
    story.append(bl("FLUTTERWAVE_WEBHOOK_SECRET — Your webhook secret hash"))
    story.append(bl("NEXT_PUBLIC_APP_URL — Your production domain URL"))

    story.append(sst("3. Supabase Configuration"))
    story.append(bl("Enable Row Level Security (RLS) on all tables"))
    story.append(bl("Configure RLS policies: profiles scoped by school_id, exams scoped by school_id/created_by"))
    story.append(bl("Configure Storage policies: avatars readable by authenticated users, writable by owner only"))
    story.append(bl("Enable Realtime for notifications table"))
    story.append(bl("Deploy Edge Functions: ai-complete, ai-stream, flutterwave-checkout, process-refund, marketplace-download"))

    story.append(sst("4. Build and Deploy"))
    story.append(bl("Run: npm run build"))
    story.append(bl("Verify: 0 build errors, 0 TypeScript errors"))
    story.append(bl("Deploy: Use standalone output with Docker or PM2"))
    story.append(bl("Configure reverse proxy with HTTPS (required for HSTS)"))
    story.append(bl("Set up rate limiting at CDN/proxy level"))

    story.append(sst("5. Post-Deployment Verification"))
    story.append(bl("Verify all 5 roles can log in and access their dashboards"))
    story.append(bl("Verify data isolation: school_admin cannot see other schools' data"))
    story.append(bl("Verify security headers are present (check with browser dev tools)"))
    story.append(bl("Verify CSP is not blocking legitimate resources"))
    story.append(bl("Test all API routes return proper error responses"))
    story.append(bl("Test webhook endpoint with Flutterwave test events"))

    story.append(sst("6. Monitoring"))
    story.append(bl("Connect Sentry for error tracking (set SENTRY_DSN)"))
    story.append(bl("Connect OpenTelemetry for observability"))
    story.append(bl("Set up uptime monitoring"))
    story.append(bl("Configure log aggregation (enterprise logger outputs structured JSON)"))

# Generate all PDFs
make_doc("Production_Checklist.pdf", "Production Readiness Checklist", "Phase 6 — Verification Checklist", build_checklist)
make_doc("Architecture_Status.pdf", "Architecture Status Report", "Phase 6 — Architecture Verification", build_architecture)
make_doc("Technical_Debt_Report.pdf", "Technical Debt Report", "Phase 6 — Debt Assessment", build_debt)
make_doc("Deployment_Guide.pdf", "Deployment Guide", "Phase 6 — Production Deployment", build_deployment)
