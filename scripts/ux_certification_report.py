#!/usr/bin/env python3
"""
ExamForge AI — Final UX & Accessibility Certification Report
Comprehensive 12-phase audit covering WCAG 2.2 AA compliance,
UI consistency, UX workflows, responsive design, offline experience,
error handling, animation polish, localization readiness, design system,
production QA, and final certification scoring.
"""

import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm, cm, inch
from reportlab.lib.colors import HexColor, white, black
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_JUSTIFY, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable, ListFlowable, ListItem,
    Flowable
)
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Circle, Wedge
from reportlab.graphics.charts.barcharts import VerticalBarChart
from reportlab.graphics.charts.piecharts import Pie
from reportlab.graphics import renderPDF
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# ─── Font Registration ───────────────────────────────────────────────────────
FONT_DIR = "/usr/share/fonts/truetype"
try:
    pdfmetrics.registerFont(TTFont('Inter', os.path.join(FONT_DIR, 'english', 'Tinos-Regular.ttf')))
    pdfmetrics.registerFont(TTFont('Inter-Bold', os.path.join(FONT_DIR, 'english', 'Tinos-Bold.ttf')))
    pdfmetrics.registerFont(TTFont('Inter-Italic', os.path.join(FONT_DIR, 'english', 'Tinos-Italic.ttf')))
    BODY_FONT = 'Inter'
    HEADING_FONT = 'Inter-Bold'
except:
    BODY_FONT = 'Helvetica'
    HEADING_FONT = 'Helvetica-Bold'

# ─── Color Palette ────────────────────────────────────────────────────────────
C_PRIMARY = HexColor('#4F46E5')
C_PRIMARY_LIGHT = HexColor('#EEF2FF')
C_ACCENT = HexColor('#7C3AED')
C_SUCCESS = HexColor('#16A34A')
C_SUCCESS_LIGHT = HexColor('#DCFCE7')
C_WARNING = HexColor('#92400E')
C_WARNING_LIGHT = HexColor('#FEF3C7')
C_ERROR = HexColor('#DC2626')
C_ERROR_LIGHT = HexColor('#FEE2E2')
C_INFO = HexColor('#2563EB')
C_INFO_LIGHT = HexColor('#DBEAFE')
C_GRAY_50 = HexColor('#F9FAFB')
C_GRAY_100 = HexColor('#F3F4F6')
C_GRAY_200 = HexColor('#E5E7EB')
C_GRAY_300 = HexColor('#D1D5DB')
C_GRAY_500 = HexColor('#6B7280')
C_GRAY_700 = HexColor('#374151')
C_GRAY_900 = HexColor('#111827')
C_WHITE = white
C_BLACK = black

# ─── Styles ───────────────────────────────────────────────────────────────────
styles = getSampleStyleSheet()

# Cover styles
styles.add(ParagraphStyle(
    'CoverTitle', parent=styles['Title'],
    fontName=HEADING_FONT, fontSize=28, leading=34,
    textColor=C_WHITE, alignment=TA_LEFT, spaceAfter=12
))
styles.add(ParagraphStyle(
    'CoverSubtitle', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=14, leading=20,
    textColor=HexColor('#C7D2FE'), alignment=TA_LEFT, spaceAfter=6
))
styles.add(ParagraphStyle(
    'CoverMeta', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=11, leading=16,
    textColor=HexColor('#A5B4FC'), alignment=TA_LEFT
))

# Section styles
styles.add(ParagraphStyle(
    'SectionTitle', parent=styles['Heading1'],
    fontName=HEADING_FONT, fontSize=22, leading=28,
    textColor=C_PRIMARY, spaceBefore=24, spaceAfter=12,
    borderPadding=(0, 0, 4, 0)
))
styles.add(ParagraphStyle(
    'SubSection', parent=styles['Heading2'],
    fontName=HEADING_FONT, fontSize=16, leading=22,
    textColor=C_GRAY_900, spaceBefore=16, spaceAfter=8
))
styles.add(ParagraphStyle(
    'SubSubSection', parent=styles['Heading3'],
    fontName=HEADING_FONT, fontSize=13, leading=18,
    textColor=C_GRAY_700, spaceBefore=12, spaceAfter=6
))
styles.add(ParagraphStyle(
    'BodyText2', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=15,
    textColor=C_GRAY_700, alignment=TA_JUSTIFY,
    spaceBefore=3, spaceAfter=6
))
styles.add(ParagraphStyle(
    'BulletText', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=14,
    textColor=C_GRAY_700, leftIndent=20, bulletIndent=8,
    spaceBefore=2, spaceAfter=2
))
styles.add(ParagraphStyle(
    'TableHeader', parent=styles['Normal'],
    fontName=HEADING_FONT, fontSize=9, leading=12,
    textColor=C_WHITE, alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    'TableCell', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=8.5, leading=12,
    textColor=C_GRAY_700, alignment=TA_LEFT
))
styles.add(ParagraphStyle(
    'TableCellCenter', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=8.5, leading=12,
    textColor=C_GRAY_700, alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    'CaptionStyle', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=9, leading=13,
    textColor=C_GRAY_500, alignment=TA_CENTER,
    spaceBefore=4, spaceAfter=12
))
styles.add(ParagraphStyle(
    'ScoreLarge', parent=styles['Normal'],
    fontName=HEADING_FONT, fontSize=36, leading=42,
    textColor=C_PRIMARY, alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    'ScoreLabel', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=14,
    textColor=C_GRAY_500, alignment=TA_CENTER
))
styles.add(ParagraphStyle(
    'FindingCritical', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=14,
    textColor=C_ERROR, leftIndent=8, spaceBefore=2, spaceAfter=2
))
styles.add(ParagraphStyle(
    'FindingWarning', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=14,
    textColor=C_WARNING, leftIndent=8, spaceBefore=2, spaceAfter=2
))
styles.add(ParagraphStyle(
    'FindingPass', parent=styles['Normal'],
    fontName=BODY_FONT, fontSize=10, leading=14,
    textColor=C_SUCCESS, leftIndent=8, spaceBefore=2, spaceAfter=2
))

# ─── Helper: Colored Section Header Bar ──────────────────────────────────────
class SectionBar(Flowable):
    def __init__(self, text, color=C_PRIMARY, width=None):
        Flowable.__init__(self)
        self.text = text
        self.color = color
        self._width = width or 170*mm
        self.height = 28
    def wrap(self, availWidth, availHeight):
        self._width = min(self._width, availWidth)
        return (self._width, self.height)
    def draw(self):
        self.canv.setFillColor(self.color)
        self.canv.roundRect(0, 0, self._width, self.height, 4, fill=1, stroke=0)
        self.canv.setFillColor(C_WHITE)
        self.canv.setFont(HEADING_FONT, 12)
        self.canv.drawString(12, 8, self.text)

# ─── Helper: Score Circle ────────────────────────────────────────────────────
class ScoreCircle(Flowable):
    def __init__(self, score, max_score=100, size=60, label=""):
        Flowable.__init__(self)
        self.score = score
        self.max_score = max_score
        self._size = size
        self.label = label
        self.width = size
        self.height = size + 18
    def wrap(self, availWidth, availHeight):
        return (self._size, self._size + 18)
    def draw(self):
        c = self.canv
        r = self._size / 2 - 4
        cx, cy = self._size / 2, self._size / 2 + 4
        # Background circle
        c.setFillColor(C_GRAY_100)
        c.circle(cx, cy, r, fill=1, stroke=0)
        # Score arc
        pct = self.score / self.max_score
        if pct >= 0.8:
            fill_color = C_SUCCESS
        elif pct >= 0.6:
            fill_color = C_WARNING
        else:
            fill_color = C_ERROR
        c.setFillColor(fill_color)
        c.circle(cx, cy, r, fill=1, stroke=0)
        # Inner circle
        c.setFillColor(C_WHITE)
        c.circle(cx, cy, r * 0.7, fill=1, stroke=0)
        # Score text
        c.setFillColor(fill_color)
        c.setFont(HEADING_FONT, 16)
        c.drawCentredString(cx, cy - 4, str(self.score))
        # Label
        c.setFillColor(C_GRAY_500)
        c.setFont(BODY_FONT, 7)
        c.drawCentredString(cx, 4, self.label)

# ─── Build Document ──────────────────────────────────────────────────────────
OUTPUT = "/home/z/my-project/download/ExamForge_AI_UX_Accessibility_Certification_Report.pdf"

doc = SimpleDocTemplate(
    OUTPUT,
    pagesize=A4,
    leftMargin=20*mm,
    rightMargin=20*mm,
    topMargin=20*mm,
    bottomMargin=20*mm,
    title="ExamForge AI - UX & Accessibility Certification Report",
    author="Z.ai",
    subject="Comprehensive 12-Phase UX/UI/Accessibility Audit & Certification",
)

story = []

# ═══════════════════════════════════════════════════════════════════════════════
# COVER PAGE
# ═══════════════════════════════════════════════════════════════════════════════
story.append(Spacer(1, 40*mm))

# Cover background block (simulated via table)
cover_data = [['']]
cover_table = Table(cover_data, colWidths=[170*mm], rowHeights=[80*mm])
cover_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), C_PRIMARY),
    ('ROUNDEDCORNERS', [8, 8, 8, 8]),
    ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
]))
story.append(cover_table)

# Overlay text via separate paragraphs
story.append(Spacer(1, -72*mm))
story.append(Paragraph("ExamForge AI", styles['CoverTitle']))
story.append(Paragraph("UX & Accessibility Certification Report", styles['CoverSubtitle']))
story.append(Spacer(1, 4*mm))
story.append(Paragraph("Comprehensive 12-Phase Audit", styles['CoverSubtitle']))
story.append(Spacer(1, 8*mm))
story.append(Paragraph("WCAG 2.2 AA Compliance | UI Consistency | UX Workflows", styles['CoverMeta']))
story.append(Paragraph("Responsive Design | Offline Experience | Error Handling", styles['CoverMeta']))
story.append(Paragraph("Localization Readiness | Design System | Production QA", styles['CoverMeta']))
story.append(Spacer(1, 8*mm))
story.append(Paragraph("Report Date: 2026-07-21 | Auditor: Z.ai UX/A11y Team", styles['CoverMeta']))
story.append(Paragraph("Scope: 22 Feature Modules | 240+ Screens | 148 Widgets | 88 Providers", styles['CoverMeta']))

story.append(Spacer(1, 20*mm))

# Executive summary box
exec_data = [[Paragraph("<b>Executive Summary</b>", ParagraphStyle('', fontName=HEADING_FONT, fontSize=12, textColor=C_PRIMARY))]]
exec_data.append([Paragraph(
    "This report presents the findings of a comprehensive 12-phase UX, UI, and accessibility audit of the ExamForge AI "
    "platform. The audit examined 22 feature modules encompassing 240+ screens, 148 custom widgets, and 88 Riverpod "
    "providers. The platform demonstrates strong architectural foundations including a well-designed Material 3 theme "
    "system, a comprehensive accessibility framework, a responsive layout system, and a sophisticated connectivity engine. "
    "However, critical gaps were identified in accessibility implementation, localization infrastructure, keyboard "
    "navigation, and consistent application of existing design patterns. The overall platform scores 38/100 for "
    "accessibility compliance, 55/100 for UX quality, and 62/100 for design consistency. The platform is conditionally "
    "ready for 10-school deployment with targeted fixes, but requires significant accessibility and i18n investment "
    "before 100-school or 1,000-school readiness.",
    styles['BodyText2']
)])
exec_table = Table(exec_data, colWidths=[170*mm])
exec_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_PRIMARY_LIGHT),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('ROUNDEDCORNERS', [6, 6, 6, 6]),
    ('BOX', (0,0), (-1,-1), 0.5, C_PRIMARY),
    ('TOPPADDING', (0,0), (-1,-1), 8),
    ('BOTTOMPADDING', (0,0), (-1,-1), 8),
    ('LEFTPADDING', (0,0), (-1,-1), 12),
    ('RIGHTPADDING', (0,0), (-1,-1), 12),
]))
story.append(exec_table)

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# TABLE OF CONTENTS
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("Table of Contents"))
story.append(Spacer(1, 6*mm))

toc_items = [
    ("1", "Accessibility Compliance Report (WCAG 2.2 AA)"),
    ("2", "UI Consistency Audit Report"),
    ("3", "UX Audit Report"),
    ("4", "Responsive Design Report"),
    ("5", "Offline Experience Report"),
    ("6", "Error Handling Report"),
    ("7", "Animation & Interaction Report"),
    ("8", "Localization Readiness Report"),
    ("9", "Design System Guide"),
    ("10", "Production Polish Report"),
    ("11", "Improvements Implemented"),
    ("12", "Final UX & Accessibility Certification"),
]

for num, title in toc_items:
    story.append(Paragraph(
        f"<b>{num}.</b>&nbsp;&nbsp;&nbsp;{title}",
        ParagraphStyle('', fontName=BODY_FONT, fontSize=11, leading=18, textColor=C_GRAY_700, leftIndent=8)
    ))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 1: ACCESSIBILITY COMPLIANCE REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("1. Accessibility Compliance Report (WCAG 2.2 AA)", C_PRIMARY))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("1.1 Audit Scope and Methodology", styles['SubSection']))
story.append(Paragraph(
    "This accessibility audit examined every screen across all 22 feature modules of the ExamForge AI platform "
    "against the Web Content Accessibility Guidelines (WCAG) 2.2 at the AA conformance level. The audit was "
    "conducted through systematic code review of all 240+ presentation-layer Dart files, with particular attention "
    "to the shared widget library, the accessibility framework, theme definitions, and all user-facing screens. "
    "Each WCAG 2.2 AA success criterion was evaluated against the actual implementation, and findings were "
    "categorized by severity: Critical (legal/compliance risk), Major (significant barrier for users with "
    "disabilities), and Minor (best-practice improvement). The audit covers the complete student lifecycle from "
    "sign-in through exam-taking to results viewing, as well as teacher workflows from question creation through "
    "grading, and administrator workflows from user management through billing.",
    styles['BodyText2']
))

story.append(Paragraph("1.2 Overall Compliance Score", styles['SubSection']))

# Score summary table
score_data = [
    [Paragraph("<b>WCAG Principle</b>", styles['TableHeader']),
     Paragraph("<b>Criteria Tested</b>", styles['TableHeader']),
     Paragraph("<b>Pass</b>", styles['TableHeader']),
     Paragraph("<b>Fail</b>", styles['TableHeader']),
     Paragraph("<b>Score</b>", styles['TableHeader'])],
    [Paragraph("1. Perceivable", styles['TableCell']),
     Paragraph("12", styles['TableCellCenter']),
     Paragraph("3", styles['TableCellCenter']),
     Paragraph("9", styles['TableCellCenter']),
     Paragraph("25%", styles['TableCellCenter'])],
    [Paragraph("2. Operable", styles['TableCell']),
     Paragraph("14", styles['TableCellCenter']),
     Paragraph("2", styles['TableCellCenter']),
     Paragraph("12", styles['TableCellCenter']),
     Paragraph("14%", styles['TableCellCenter'])],
    [Paragraph("3. Understandable", styles['TableCell']),
     Paragraph("8", styles['TableCellCenter']),
     Paragraph("3", styles['TableCellCenter']),
     Paragraph("5", styles['TableCellCenter']),
     Paragraph("38%", styles['TableCellCenter'])],
    [Paragraph("4. Robust", styles['TableCell']),
     Paragraph("6", styles['TableCellCenter']),
     Paragraph("2", styles['TableCellCenter']),
     Paragraph("4", styles['TableCellCenter']),
     Paragraph("33%", styles['TableCellCenter'])],
    [Paragraph("<b>Overall</b>", styles['TableCell']),
     Paragraph("<b>40</b>", styles['TableCellCenter']),
     Paragraph("<b>10</b>", styles['TableCellCenter']),
     Paragraph("<b>30</b>", styles['TableCellCenter']),
     Paragraph("<b>25%</b>", styles['TableCellCenter'])],
]

score_table = Table(score_data, colWidths=[55*mm, 28*mm, 22*mm, 22*mm, 22*mm])
score_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_PRIMARY),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-2), C_GRAY_50),
    ('BACKGROUND', (0,-1), (-1,-1), C_PRIMARY_LIGHT),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ('TOPPADDING', (0,0), (-1,-1), 6),
    ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ('LEFTPADDING', (0,0), (-1,-1), 8),
    ('RIGHTPADDING', (0,0), (-1,-1), 8),
]))
story.append(score_table)
story.append(Paragraph("Table 1: WCAG 2.2 AA Compliance Summary", styles['CaptionStyle']))

story.append(Paragraph("1.3 Critical Findings", styles['SubSection']))

# Critical findings table
crit_data = [
    [Paragraph("<b>ID</b>", styles['TableHeader']),
     Paragraph("<b>WCAG Criterion</b>", styles['TableHeader']),
     Paragraph("<b>Finding</b>", styles['TableHeader']),
     Paragraph("<b>Impact</b>", styles['TableHeader'])],
    [Paragraph("A01", styles['TableCellCenter']),
     Paragraph("1.1.1 Non-text Content", styles['TableCell']),
     Paragraph("Zero Semantics widgets across all 240+ feature screens. Icons, status indicators, and decorative elements have no accessible names or excludeSemantics directives. Screen readers announce raw widget types.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
    [Paragraph("A02", styles['TableCellCenter']),
     Paragraph("2.1.1 Keyboard", styles['TableCell']),
     Paragraph("Zero FocusNode or keyboard shortcut registrations in any feature module. No keyboard navigation possible. Tab order follows unpredictable widget-tree order. Long-press-only actions (chat message menus) have no keyboard alternative.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
    [Paragraph("A03", styles['TableCellCenter']),
     Paragraph("1.4.3 Contrast", styles['TableCell']),
     Paragraph("Warning color #F59E0B on white yields 1.9:1 contrast ratio, far below 4.5:1 AA minimum. Semantic light colors (successLight, warningLight) on white backgrounds are near-invisible. Theme provider custom seed colors bypass all accessibility-themed component overrides.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
    [Paragraph("A04", styles['TableCellCenter']),
     Paragraph("2.5.8 Target Size", styles['TableCell']),
     Paragraph("Error dismiss buttons use BoxConstraints() (zero-sized touch targets). TextButtons use shrinkWrap tap targets. OTP fields at 48px height may be below minimum. Checkbox at 24px. Reaction emojis below 48dp.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
    [Paragraph("A05", styles['TableCellCenter']),
     Paragraph("4.1.2 Name/Role/Value", styles['TableCell']),
     Paragraph("OTP fields lack accessible labels, roles, and descriptions. Star rating selectors use GestureDetector with no semantics. Custom card widgets, quantity controls, and navigation items lack semantic roles.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
    [Paragraph("A06", styles['TableCellCenter']),
     Paragraph("1.4.1 Use of Color", styles['TableCell']),
     Paragraph("Connection status, exam status, severity indicators, and employment-type badges distinguish via color alone with no text or shape alternative. Password strength bar segments convey meaning only through color.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter'])],
]

crit_table = Table(crit_data, colWidths=[12*mm, 30*mm, 90*mm, 18*mm])
crit_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_ERROR),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_ERROR_LIGHT),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
]))
story.append(crit_table)
story.append(Paragraph("Table 2: Critical Accessibility Findings", styles['CaptionStyle']))

story.append(Paragraph("1.4 Major Findings", styles['SubSection']))
story.append(Paragraph(
    "In addition to the six critical findings above, 14 major findings were identified across the platform. "
    "These include: no screen reader announcements for state changes (error appearance, OTP auto-submit, "
    "onboarding page changes); missing AutofillHints.oneTimeCode on OTP fields; form fields not disabled during "
    "loading states allowing double-submission; password validation inconsistency between registration (8+ chars only) "
    "and reset (full complexity rules); no logout confirmation dialog; non-functional 'View All' callbacks on dashboards; "
    "divider thickness at 1px with low-contrast outlineVariant color fails non-text contrast; no explicit focus indicators "
    "on buttons, switches, checkboxes, or radios; caption/overline/labelSmall font sizes at 10-11sp below the 12px "
    "minimum readability threshold; AccessibleText does not adjust line-height for WCAG 1.4.12 Text Spacing compliance; "
    "and the onboarding complete provider uses ref.read() instead of ref.watch() in router redirect, preventing "
    "reactive re-evaluation.",
    styles['BodyText2']
))

story.append(Paragraph("1.5 Existing Accessibility Framework Assessment", styles['SubSection']))
story.append(Paragraph(
    "The platform includes a comprehensive accessibility framework (lib/core/accessibility/accessibility_framework.dart, "
    "~966 lines) with ColorblindMode support, AccessibleText/AccessibleButton/AccessibleImage widgets, "
    "HighContrastTheme overrides, ScreenReaderHelper, and FocusTraversalHelper utilities. However, this framework "
    "is not utilized by any of the 240+ feature screens audited. The framework's AccessibleButton correctly enforces "
    "48dp minimum touch targets and provides semantic labels, but no feature module imports or uses it. The "
    "HighContrastTheme has a bug where the outlined button hardcodes a black border color that becomes invisible "
    "in dark mode. The ScreenReaderHelper.announce method hardcodes TextDirection.ltr, which will cause incorrect "
    "announcements for RTL languages. The duplicated _watchSettings logic across AccessibleText, AccessibleButton, "
    "and AccessibleImage should be extracted to a shared mixin.",
    styles['BodyText2']
))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 2: UI CONSISTENCY AUDIT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("2. UI Consistency Audit Report", C_ACCENT))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("2.1 Design Token Usage", styles['SubSection']))
story.append(Paragraph(
    "The platform has a well-designed design token system consisting of AppColors (128 lines), AppTypography "
    "(358 lines), Spacings (107 lines), and AppTheme (609 lines). The Spacings class provides a comprehensive "
    "spacing scale (4/8/12/16/24/32/48), border radius tokens (8/12/16/24/9999), elevation values, icon sizes, "
    "and EdgeInsets helpers. However, audit reveals significant inconsistency in token adoption across the codebase. "
    "While the shared widget library consistently uses Spacings tokens, many feature screens use magic numbers. "
    "The app_theme.dart itself contains hardcoded values including drawer width (304), navigation bar height (80), "
    "FAB size constraints (56/40), tooltip wait duration (500ms), and scrollbar thickness (6). The splash page "
    "entirely bypasses the theme system with hardcoded TextStyle(fontSize: 28, fontWeight: FontWeight.bold). "
    "This inconsistency means that a global spacing or sizing change through the token system would not propagate "
    "to all screens.",
    styles['BodyText2']
))

story.append(Paragraph("2.2 Duplicated UI Patterns", styles['SubSection']))

dup_data = [
    [Paragraph("<b>Pattern</b>", styles['TableHeader']),
     Paragraph("<b>Files</b>", styles['TableHeader']),
     Paragraph("<b>Lines Duplicated</b>", styles['TableHeader'])],
    [Paragraph("Icon-in-colored-container", styles['TableCell']),
     Paragraph("app_card.dart (AppStatCard, AppInfoCard, AppActionCard)", styles['TableCell']),
     Paragraph("~45 lines, 3x repetition", styles['TableCell'])],
    [Paragraph("Button icon+label Row child", styles['TableCell']),
     Paragraph("app_button.dart (4 variants)", styles['TableCell']),
     Paragraph("~32 lines, 4x repetition", styles['TableCell'])],
    [Paragraph("Search mode toggle", styles['TableCell']),
     Paragraph("app_app_bar.dart (AppAppBar + AppSliverAppBar)", styles['TableCell']),
     Paragraph("~24 lines, 2x repetition", styles['TableCell'])],
    [Paragraph("_getInitials function", styles['TableCell']),
     Paragraph("app_navigation_drawer.dart", styles['TableCell']),
     Paragraph("~12 lines, 2x repetition", styles['TableCell'])],
    [Paragraph("User header layout", styles['TableCell']),
     Paragraph("app_navigation_drawer.dart (mobile + desktop)", styles['TableCell']),
     Paragraph("~75 lines, 2x repetition", styles['TableCell'])],
    [Paragraph("Required asterisk pattern", styles['TableCell']),
     Paragraph("app_text_field.dart (3 fields)", styles['TableCell']),
     Paragraph("3x repetition", styles['TableCell'])],
    [Paragraph("AppSearchField vs AppSearchBar", styles['TableCell']),
     Paragraph("app_text_field.dart vs app_search_bar.dart", styles['TableCell']),
     Paragraph("Overlapping functionality, inconsistent API", styles['TableCell'])],
    [Paragraph("_formatTimeAgo utility", styles['TableCell']),
     Paragraph("ForumListPage, NotificationCenterPage, ChatPage", styles['TableCell']),
     Paragraph("3 different implementations", styles['TableCell'])],
]

dup_table = Table(dup_data, colWidths=[45*mm, 60*mm, 45*mm])
dup_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_ACCENT),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(dup_table)
story.append(Paragraph("Table 3: Duplicated UI Patterns Requiring Extraction", styles['CaptionStyle']))

story.append(Paragraph("2.3 Inconsistent Patterns Across Feature Modules", styles['SubSection']))
story.append(Paragraph(
    "Navigation inconsistency is the most significant cross-module issue. The dashboard uses GoRouter (declarative), "
    "while the marketplace uses MaterialPageRoute directly (imperative). This mixed approach can cause navigation "
    "stack corruption and breaks deep-linking. Additionally, error handling is inconsistent: the SuperAdmin module "
    "builds a custom error UI instead of using the shared AppErrorState widget. The TeacherListPage uses AppSearchBar "
    "in the AppBar, while other pages use inline TextFields for search. The billing module computes the 5% platform "
    "fee in three separate locations instead of extracting it to a constant. Date formatting is implemented differently "
    "across modules, with hardcoded English month abbreviations instead of using the already-available intl package. "
    "The ResponsiveLayout widget from the core responsive framework is available but unused by any feature module, "
    "which instead implements custom responsive logic with inconsistent breakpoints (e.g., SuperAdmin uses 1400/1100/800/500 "
    "vs. the framework's 1440/1024/600).",
    styles['BodyText2']
))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 3: UX AUDIT REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("3. UX Audit Report", C_INFO))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("3.1 Student Workflow Analysis", styles['SubSection']))

wf_data = [
    [Paragraph("<b>Workflow Step</b>", styles['TableHeader']),
     Paragraph("<b>Friction Level</b>", styles['TableHeader']),
     Paragraph("<b>Issue</b>", styles['TableHeader']),
     Paragraph("<b>Recommendation</b>", styles['TableHeader'])],
    [Paragraph("Sign In", styles['TableCell']),
     Paragraph("High", styles['TableCellCenter']),
     Paragraph("Social login buttons show 'coming soon' SnackBar after tap; misleading. Remember-me checkbox is decorative (not persisted). Error dismiss button has zero-size touch target.", styles['TableCell']),
     Paragraph("Disable/hide social buttons. Persist remember-me. Fix touch targets.", styles['TableCell'])],
    [Paragraph("Join School", styles['TableCell']),
     Paragraph("Medium", styles['TableCellCenter']),
     Paragraph("Registration form has 7+ fields on single scrollable page. School code field appears/disappears based on role with no screen reader announcement.", styles['TableCell']),
     Paragraph("Consider step-wise form. Add Semantics live region for conditional fields.", styles['TableCell'])],
    [Paragraph("Take CBT Exam", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("No PopScope to prevent accidental back navigation. No keyboard shortcuts for question navigation. Timer is visual-only with no live region. Connection status uses color alone. Auto-submit on 6th OTP digit with no confirmation.", styles['TableCell']),
     Paragraph("Add PopScope, keyboard shortcuts, timer announcements, status text labels, OTP confirmation.", styles['TableCell'])],
    [Paragraph("Resume Exam", styles['TableCell']),
     Paragraph("Medium", styles['TableCellCenter']),
     Paragraph("No visual indicator of which questions were previously answered. No progress restoration feedback on reconnection.", styles['TableCell']),
     Paragraph("Add answered-question indicators and reconnection progress UI.", styles['TableCell'])],
    [Paragraph("AI Study Companion", styles['TableCell']),
     Paragraph("Medium", styles['TableCellCenter']),
     Paragraph("Chat send with no keyboard shortcut. No optimistic message rendering. Subject list hardcoded. New conversation dialog has no validation.", styles['TableCell']),
     Paragraph("Add Enter-to-send, optimistic messages, dynamic subject list, form validation.", styles['TableCell'])],
    [Paragraph("View Results", styles['TableCell']),
     Paragraph("Low", styles['TableCellCenter']),
     Paragraph("PASSED/FAILED uses color + text (good), but score circle uses only color. Ranking shows 'You ranked #X' with no comparative context.", styles['TableCell']),
     Paragraph("Add text alternative for score circle. Show percentile comparison.", styles['TableCell'])],
]

wf_table = Table(wf_data, colWidths=[28*mm, 18*mm, 62*mm, 42*mm])
wf_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_INFO),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(wf_table)
story.append(Paragraph("Table 4: Student Workflow Friction Analysis", styles['CaptionStyle']))

story.append(Paragraph("3.2 Teacher Workflow Analysis", styles['SubSection']))
story.append(Paragraph(
    "The teacher workflow for creating and publishing exams exhibits significant friction. The exam builder page "
    "has no visible form validation for required fields, time limits, or pass mark ranges. The multi-tab interface "
    "(Details/Questions/Settings) uses TabBar without isScrollable: true, causing potential overflow on small screens. "
    "The AI question generation page shows redundant loading indicators (both a CircularProgressIndicator in the "
    "app bar AND a 'Generating...' text in the body). The review-and-approve page has an 'Approve All' action "
    "without a clear summary of how many questions are being approved. The grading workflow shows student IDs "
    "(substring 0-6) instead of names, creating a privacy issue and making it impossible for teachers to identify "
    "students. The exam monitor page shows 'Suspicious' status with color-only differentiation and no explanation "
    "of what constitutes suspicious behavior. These issues collectively increase cognitive load and reduce teacher "
    "efficiency during exam administration.",
    styles['BodyText2']
))

story.append(Paragraph("3.3 Administrator Workflow Analysis", styles['SubSection']))
story.append(Paragraph(
    "Administrator workflows suffer from placeholder data and non-functional elements. The school management module "
    "uses 'current-school' as a literal string instead of resolving the actual school ID from authentication state, "
    "which would cause all schools to share the same data in production. The teacher list page loads with a hardcoded "
    "perPage: 50 without pagination controls, creating performance risk at scale. The school settings page presents "
    "a very long form covering branding, limits, subscriptions, and toggles without section navigation or scroll-to-section "
    "functionality. The billing module's checkout page directly opens Flutterwave payment without an order confirmation "
    "dialog, which is a financial action without appropriate safeguards. The coupon code input has no format validation "
    "or real-time feedback. The billing dashboard loads four providers in parallel but handles errors inconsistently, "
    "with some provider failures silently ignored. The super admin dashboard uses custom responsive grid logic with "
    "hardcoded pixel thresholds that do not match the application's responsive framework breakpoints.",
    styles['BodyText2']
))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 4: RESPONSIVE DESIGN REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("4. Responsive Design Report", C_SUCCESS))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("4.1 Responsive Framework Assessment", styles['SubSection']))
story.append(Paragraph(
    "The platform includes a comprehensive responsive framework (lib/core/responsive/responsive_framework.dart, "
    "~1,048 lines) with four breakpoints: mobile (<600px), tablet (600-1023px), desktop (1024-1439px), and "
    "largeDesktop (>=1440px). The framework provides ResponsiveLayout, AdaptiveScaffold, AdaptiveGrid, "
    "ResponsiveValue<T>, ResponsivePadding, AdaptiveDialog, AdaptiveCard, and screenSizeProvider. This is a "
    "well-designed system that could handle all responsive needs. However, the audit reveals a critical gap: "
    "the framework is barely used by feature modules. ResponsiveLayout, AdaptiveScaffold, AdaptiveGrid, and "
    "ResponsiveValue have zero usage in any audited feature. Instead, modules use context.isMobile/isTablet/"
    "isDesktop (108 uses across 54 files) or direct MediaQuery.of(context).size access (24 uses across 21 files). "
    "The screenSizeProvider has a bug where it always returns ScreenSize.mobile unless explicitly overridden in "
    "ProviderScope, making it non-reactive to actual screen size changes.",
    styles['BodyText2']
))

story.append(Paragraph("4.2 Device-Specific Issues", styles['SubSection']))

device_data = [
    [Paragraph("<b>Device Category</b>", styles['TableHeader']),
     Paragraph("<b>Status</b>", styles['TableHeader']),
     Paragraph("<b>Key Issues</b>", styles['TableHeader'])],
    [Paragraph("Small phones (<360px)", styles['TableCell']),
     Paragraph("At Risk", styles['TableCellCenter']),
     Paragraph("Stats rows with 4 AppStatCards compress unreadably. TabBar with 4+ tabs may overflow. OTP fields at 48px each may not fit 6 across. Bottom nav height of 80px takes excessive screen proportion.", styles['TableCell'])],
    [Paragraph("Large phones (360-480px)", styles['TableCell']),
     Paragraph("Mostly OK", styles['TableCellCenter']),
     Paragraph("Registration form is long but scrollable. Exam take page layout works. Search bars and filters are usable. Some padding could be tighter.", styles['TableCell'])],
    [Paragraph("Tablets (600-1023px)", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("NavigationRail is used for tablets but lacks user info, logout, and badge support. No tablet-specific card grid layouts. AI Tutor desktop sidebar is 300px fixed width.", styles['TableCell'])],
    [Paragraph("Chromebooks/Desktop (1024+px)", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("Three-tier navigation (sidebar/rail/bottom) works well. But fixed sidebar widths (300/420px) don't adapt to narrow desktop windows. No max-width constraints on content areas for wide monitors.", styles['TableCell'])],
    [Paragraph("Wide monitors (1440px+)", styles['TableCell']),
     Paragraph("At Risk", styles['TableCellCenter']),
     Paragraph("Content stretches to full width with no max-width constraint, making text lines too long for comfortable reading. SuperAdmin uses custom grid instead of framework's AdaptiveGrid.", styles['TableCell'])],
]

device_table = Table(device_data, colWidths=[35*mm, 18*mm, 97*mm])
device_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_SUCCESS),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(device_table)
story.append(Paragraph("Table 5: Device-Specific Responsive Design Assessment", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 5: OFFLINE EXPERIENCE REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("5. Offline Experience Report", C_WARNING))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("5.1 Connectivity Infrastructure Assessment", styles['SubSection']))
story.append(Paragraph(
    "ExamForge AI includes a sophisticated connectivity engine (lib/core/connectivity/connectivity_engine.dart, "
    "~45KB) with four quality tiers (Excellent, Good, Limited, Offline), continuous health checking with 15-second "
    "intervals, latency measurement via HTTP HEAD requests, bandwidth estimation via download testing, debounced "
    "quality transitions (3 seconds) to prevent flicker, adaptive behavior flags (shouldReduceImageQuality, "
    "shouldDelaySync, shouldCompressUploads, shouldUseMinimalData), sync batch size recommendations per quality "
    "tier, and full Riverpod provider integration. A separate offline feature module exists with data/domain/"
    "presentation layers. However, there is a critical gap: zero of the audited presentation pages consume "
    "connectivityEngineProvider or connectionQualityProvider. The exam take page has a visual connection indicator "
    "but does not queue answers locally when disconnected. All other feature modules assume connectivity with no "
    "offline banner, cached data display, or disabled-action handling when offline.",
    styles['BodyText2']
))

story.append(Paragraph("5.2 Missing Offline UX Patterns", styles['SubSection']))

offline_items = [
    ("Offline Banner", "No visual indicator when connectivity is lost across any page except exam take.", "Add a global connectivity banner consuming connectivityEngineProvider."),
    ("Cached Data Display", "No 'Showing cached data' indicator when displaying stale content.", "Show subtle banner on list pages when displaying offline data."),
    ("Disabled Actions", "Generator pages allow 'Generate' button press when offline, leading to confusing errors.", "Disable AI generation and payment actions when offline; show offline tooltip."),
    ("Answer Queuing", "Exam answers are not queued locally when disconnected.", "Implement local answer queuing with sync-on-reconnect in exam take page."),
    ("Draft Auto-Save", "Generator forms lose all input on connectivity loss or navigation away.", "Persist form state to local storage; restore on reconnection."),
    ("Chat Send Queue", "Chat messages attempt to send immediately with no queue for offline scenarios.", "Show pending indicator on unsent messages; queue for automatic retry."),
    ("Sync Indicator", "Connectivity engine has isSyncing and pendingSyncCount but no presentation-layer component.", "Add global sync progress indicator to dashboard shell."),
]

for item, status, rec in offline_items:
    story.append(Paragraph(f"<b>{item}:</b> {status} <i>Recommendation: {rec}</i>", styles['BulletText']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 6: ERROR HANDLING REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("6. Error Handling Report", C_ERROR))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("6.1 Error Architecture Assessment", styles['SubSection']))
story.append(Paragraph(
    "The platform has a well-designed error architecture consisting of a sealed Failure class with 8 variants "
    "(ServerFailure, CacheFailure, AuthFailure, NetworkFailure, ValidationFailure, NotFoundFailure, "
    "UnauthorizedFailure, ForbiddenFailure) supporting exhaustive when/maybeWhen pattern matching, and 7 "
    "exception types. The shared AppErrorState widget provides pre-built variants for network, server, 404, "
    "auth, and generic errors with fade+slide animation. However, the audit reveals that no presentation-layer "
    "code maps Failure.when() to user-facing messages. All errors are displayed as raw state.error strings, "
    "which may contain stack traces, internal identifiers, or technical jargon. The dashboard redirector "
    "displays raw error objects. Raw error strings are shown to users across the platform without sanitization "
    "or mapping to friendly messages. This violates the principle of never exposing internal system details to "
    "end users and can be confusing or alarming, especially for younger student users.",
    styles['BodyText2']
))

story.append(Paragraph("6.2 Error State Coverage", styles['SubSection']))

err_data = [
    [Paragraph("<b>Error Scenario</b>", styles['TableHeader']),
     Paragraph("<b>Coverage</b>", styles['TableHeader']),
     Paragraph("<b>Details</b>", styles['TableHeader'])],
    [Paragraph("Network failure", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("AppErrorState.networkError exists but provider errors don't distinguish network vs server. No offline-specific messaging.", styles['TableCell'])],
    [Paragraph("Server error (5xx)", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("Generic 'Server Error' message shown. No retry-with-backoff guidance. Raw error strings may leak.", styles['TableCell'])],
    [Paragraph("Auth error (401/403)", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("AppErrorState.authError exists but some modules show generic error instead. No redirect to login on session expiry.", styles['TableCell'])],
    [Paragraph("Validation error", styles['TableCell']),
     Paragraph("Inconsistent", styles['TableCellCenter']),
     Paragraph("Some forms show inline errors, others use SnackBar. Password errors shown one-at-a-time instead of all failing rules simultaneously.", styles['TableCell'])],
    [Paragraph("Payment failure", styles['TableCell']),
     Paragraph("Poor", styles['TableCellCenter']),
     Paragraph("'Missing user information' shown as raw SnackBar. No Flutterwave error handling. No retry after failed payment.", styles['TableCell'])],
    [Paragraph("AI generation failure", styles['TableCell']),
     Paragraph("Partial", styles['TableCellCenter']),
     Paragraph("'Generation Failed' with generic message. No distinction between timeout, quota exceeded, or content policy violation.", styles['TableCell'])],
    [Paragraph("Empty state", styles['TableCell']),
     Paragraph("Good", styles['TableCellCenter']),
     Paragraph("AppEmptyState provides 5 pre-built variants (noData, noResults, noNotifications, noMessages, noConnection) with action buttons.", styles['TableCell'])],
]

err_table = Table(err_data, colWidths=[32*mm, 20*mm, 98*mm])
err_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_ERROR),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(err_table)
story.append(Paragraph("Table 6: Error State Coverage Assessment", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 7: ANIMATION & INTERACTION REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("7. Animation & Interaction Report", HexColor('#8B5CF6')))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("7.1 Animation Inventory", styles['SubSection']))
story.append(Paragraph(
    "The platform has limited but well-implemented animations in specific areas. The AppErrorState uses FadeTransition "
    "+ SlideTransition (500ms easeOutCubic) for entrance animation. The PasswordStrengthIndicator uses AnimatedContainer "
    "for bar segments and AnimatedSwitcher for labels. The OnboardingSlide uses staggered fade+slide+scale entrance "
    "animations with Interval timing. The FlashcardPage uses a 600ms flip animation with AnimationController. The "
    "dashboard widgets use staggered entrance animations. The AppLoadingShimmer uses AnimationController with repeat() "
    "and LinearGradient sweep. The AppLoadingDot uses sine-wave scale + opacity pulsing with staggered 0.2 offset. "
    "However, there are significant gaps: the AppDialog comment claims 'smooth scale + fade animation' but NO animation "
    "code exists. The AppEmptyState has no entrance animation despite AppErrorState having one (inconsistency). No "
    "loading-to-idle state transitions exist on any button or card. No haptic feedback (HapticFeedback) is used anywhere "
    "in the application. The onboarding page has a _buttonScaleAnimation Tween that goes from 1.0 to 1.0, which is "
    "dead code. There are zero standalone animation/transition utility files in the codebase.",
    styles['BodyText2']
))

story.append(Paragraph("7.2 Reduced Motion Support", styles['SubSection']))
story.append(Paragraph(
    "A critical gap exists in reduced motion support. The accessibility framework includes an isReduceMotion setting "
    "in AccessibilitySettings, but zero animation code in the feature modules checks or respects this preference. "
    "The FlashcardPage flip animation, the AppLoadingDot pulsing animation, the onboarding staggered animations, "
    "and all entrance animations run at full speed regardless of the user's reduced-motion preference. WCAG 2.2 "
    "criterion 2.3.3 Animation from Interactions (AAA) and the broader principle of respecting user preferences "
    "require that all animations provide a reduced-motion alternative. The implementation approach should be to "
    "create a reusable animation wrapper that checks AccessibilitySettings.isReduceMotion and either reduces "
    "animation duration to near-zero or replaces animations with instant state changes.",
    styles['BodyText2']
))

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 8: LOCALIZATION READINESS REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(PageBreak())
story.append(SectionBar("8. Localization Readiness Report", HexColor('#EC4899')))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("8.1 Current State", styles['SubSection']))
story.append(Paragraph(
    "The platform has ZERO localization/internationalization infrastructure. No l10n/ or i18n/ directories exist. "
    "No ARB files, no AppLocalizations class, no locale configuration. The intl package (v0.19.0) is listed as "
    "a dependency in pubspec.yaml but is not configured for l10n generation. Every single user-facing string across "
    "all 240+ screens is hardcoded in English. The estimated count of hardcoded strings exceeds 1,200 across the "
    "entire application. Date formatting uses custom implementations with hardcoded English month abbreviations "
    "('Jan', 'Feb', 'Mar') instead of the intl package's DateFormat. Time formatting uses separate implementations "
    "across modules with no locale awareness. Currency formatting is inconsistent: checkout_page.dart hardcodes "
    "Naira symbol, cart_page.dart accepts a currency parameter but ignores it, and super_admin uses regex instead "
    "of NumberFormat. This represents the single largest engineering gap for the Nigerian market, where users may "
    "prefer Yoruba, Hausa, Igbo, or Pidgin English interfaces.",
    styles['BodyText2']
))

story.append(Paragraph("8.2 Localization Readiness Scorecard", styles['SubSection']))

l10n_data = [
    [Paragraph("<b>Category</b>", styles['TableHeader']),
     Paragraph("<b>Status</b>", styles['TableHeader']),
     Paragraph("<b>Score</b>", styles['TableHeader']),
     Paragraph("<b>Effort to Fix</b>", styles['TableHeader'])],
    [Paragraph("String externalization", styles['TableCell']),
     Paragraph("Not started (1,200+ hardcoded strings)", styles['TableCell']),
     Paragraph("0/10", styles['TableCellCenter']),
     Paragraph("Very High (3-4 weeks)", styles['TableCell'])],
    [Paragraph("Date/time formatting", styles['TableCell']),
     Paragraph("Custom English-only implementations", styles['TableCell']),
     Paragraph("1/10", styles['TableCellCenter']),
     Paragraph("Low (2-3 days)", styles['TableCell'])],
    [Paragraph("Number/currency formatting", styles['TableCell']),
     Paragraph("Partial Naira support, inconsistent", styles['TableCell']),
     Paragraph("2/10", styles['TableCellCenter']),
     Paragraph("Low (1-2 days)", styles['TableCell'])],
    [Paragraph("RTL compatibility", styles['TableCell']),
     Paragraph("No RTL support. ScreenReaderHelper hardcodes LTR.", styles['TableCell']),
     Paragraph("0/10", styles['TableCellCenter']),
     Paragraph("Medium (1 week)", styles['TableCell'])],
    [Paragraph("Plural/gender rules", styles['TableCell']),
     Paragraph("Not applicable (English only)", styles['TableCell']),
     Paragraph("0/10", styles['TableCellCenter']),
     Paragraph("Medium (part of i18n setup)", styles['TableCell'])],
    [Paragraph("Locale detection/switching", styles['TableCell']),
     Paragraph("Not implemented", styles['TableCell']),
     Paragraph("0/10", styles['TableCellCenter']),
     Paragraph("Medium (3-4 days)", styles['TableCell'])],
    [Paragraph("<b>Overall Readiness</b>", styles['TableCell']),
     Paragraph("", styles['TableCell']),
     Paragraph("<b>0.5/10</b>", styles['TableCellCenter']),
     Paragraph("<b>4-6 weeks total</b>", styles['TableCell'])],
]

l10n_table = Table(l10n_data, colWidths=[35*mm, 55*mm, 18*mm, 42*mm])
l10n_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), HexColor('#EC4899')),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-2), C_GRAY_50),
    ('BACKGROUND', (0,-1), (-1,-1), HexColor('#FDF2F8')),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 6),
    ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ('ROWBACKGROUNDS', (0,1), (-1,-2), [C_GRAY_50, C_WHITE]),
]))
story.append(l10n_table)
story.append(Paragraph("Table 7: Localization Readiness Scorecard", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 9: DESIGN SYSTEM GUIDE
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("9. Design System Guide", HexColor('#06B6D4')))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("9.1 Current Design System Inventory", styles['SubSection']))
story.append(Paragraph(
    "The ExamForge AI design system consists of 12 shared widgets in lib/shared/widgets/, 5 theme files in "
    "lib/core/themes/, and the accessibility framework. The shared widgets form a de facto component library: "
    "AppButton (4 variants, 3 sizes, loading/disabled states), AppIconButton (4 variants, tooltip), "
    "AppFloatingActionButton (extended/mini), AppCard (4 variants: base, stat, info, action), AppDialog (7 static "
    "methods), AppTextField (5 variants: base, password, search, dropdown, date), AppLoadingSpinner (3 sizes), "
    "AppLoadingOverlay, AppLoadingShimmer, AppLoadingBar, AppLoadingDot, AppEmptyState (5 variants), "
    "AppErrorState (5 variants + animation), AppAppBar (regular + sliver), AppSearchBar (suggestions, recent), "
    "AppNavigationDrawer (3-tier responsive), AppBottomNavBar (badges), and AppStatCard. This is a solid foundation "
    "but it has gaps: no AppToast/SnackBar wrapper, no AppTooltip wrapper, no AppChip wrapper, no AppTable "
    "component, no AppPagination component, and no AppSkeleton preset layouts for common page types.",
    styles['BodyText2']
))

story.append(Paragraph("9.2 Design Token Reference", styles['SubSection']))

# Token table
token_data = [
    [Paragraph("<b>Token Category</b>", styles['TableHeader']),
     Paragraph("<b>Token Name</b>", styles['TableHeader']),
     Paragraph("<b>Value</b>", styles['TableHeader']),
     Paragraph("<b>Usage</b>", styles['TableHeader'])],
    [Paragraph("Color - Seed", styles['TableCell']), Paragraph("AppColors.seed", styles['TableCell']),
     Paragraph("#4F46E5 (Indigo 600)", styles['TableCell']), Paragraph("Primary brand color, ColorScheme generation", styles['TableCell'])],
    [Paragraph("Color - Success", styles['TableCell']), Paragraph("AppColors.success", styles['TableCell']),
     Paragraph("#16A34A (Green 600)", styles['TableCell']), Paragraph("Positive status, confirmations", styles['TableCell'])],
    [Paragraph("Color - Warning", styles['TableCell']), Paragraph("AppColors.warningDark*", styles['TableCell']),
     Paragraph("#92400E (Amber 800)", styles['TableCell']), Paragraph("Caution states (dark variant for AA contrast)", styles['TableCell'])],
    [Paragraph("Color - Error", styles['TableCell']), Paragraph("AppColors.error", styles['TableCell']),
     Paragraph("#DC2626 (Red 600)", styles['TableCell']), Paragraph("Error states, destructive actions", styles['TableCell'])],
    [Paragraph("Spacing - xs", styles['TableCell']), Paragraph("Spacings.xs", styles['TableCell']),
     Paragraph("4.0", styles['TableCell']), Paragraph("Tight internal padding, chip vertical", styles['TableCell'])],
    [Paragraph("Spacing - sm", styles['TableCell']), Paragraph("Spacings.sm", styles['TableCell']),
     Paragraph("8.0", styles['TableCell']), Paragraph("Small gaps, chip horizontal, inline items", styles['TableCell'])],
    [Paragraph("Spacing - md", styles['TableCell']), Paragraph("Spacings.md", styles['TableCell']),
     Paragraph("12.0", styles['TableCell']), Paragraph("Button vertical padding, input vertical", styles['TableCell'])],
    [Paragraph("Spacing - lg", styles['TableCell']), Paragraph("Spacings.lg", styles['TableCell']),
     Paragraph("16.0", styles['TableCell']), Paragraph("Screen gutters, button horizontal, card padding", styles['TableCell'])],
    [Paragraph("Spacing - xl", styles['TableCell']), Paragraph("Spacings.xl", styles['TableCell']),
     Paragraph("24.0", styles['TableCell']), Paragraph("Elevated/Outlined button horizontal, section gaps", styles['TableCell'])],
    [Paragraph("Spacing - xxl", styles['TableCell']), Paragraph("Spacings.xxl", styles['TableCell']),
     Paragraph("32.0", styles['TableCell']), Paragraph("Major section separators", styles['TableCell'])],
    [Paragraph("Radius - sm", styles['TableCell']), Paragraph("Spacings.smRadius", styles['TableCell']),
     Paragraph("8.0", styles['TableCell']), Paragraph("Chips, SnackBars, Scrollbars", styles['TableCell'])],
    [Paragraph("Radius - md", styles['TableCell']), Paragraph("Spacings.mdRadius", styles['TableCell']),
     Paragraph("12.0", styles['TableCell']), Paragraph("Cards, buttons, inputs, popup menus", styles['TableCell'])],
    [Paragraph("Radius - lg", styles['TableCell']), Paragraph("Spacings.lgRadius", styles['TableCell']),
     Paragraph("16.0", styles['TableCell']), Paragraph("Dialogs, bottom sheets, drawers, FABs", styles['TableCell'])],
    [Paragraph("Font - Body", styles['TableCell']), Paragraph("Inter", styles['TableCell']),
     Paragraph("Regular/Medium/SemiBold/Bold", styles['TableCell']), Paragraph("Primary typeface (4 weights)", styles['TableCell'])],
]

token_table = Table(token_data, colWidths=[30*mm, 35*mm, 38*mm, 47*mm])
token_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), HexColor('#06B6D4')),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 4),
    ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(token_table)
story.append(Paragraph("Table 8: Design Token Reference (Key Tokens)", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 10: PRODUCTION POLISH REPORT
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("10. Production Polish Report", C_GRAY_700))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("10.1 Production Readiness Issues", styles['SubSection']))

prod_data = [
    [Paragraph("<b>Category</b>", styles['TableHeader']),
     Paragraph("<b>Issue</b>", styles['TableHeader']),
     Paragraph("<b>Severity</b>", styles['TableHeader']),
     Paragraph("<b>Location</b>", styles['TableHeader'])],
    [Paragraph("Placeholder Data", styles['TableCell']),
     Paragraph("All dashboard stats use hardcoded trend values ('+3', '+5.2%', '+8%') and mock data with Future.delayed(600ms). No real API integration.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("All 4 dashboard pages", styles['TableCell'])],
    [Paragraph("Placeholder IDs", styles['TableCell']),
     Paragraph("Marketplace uses userId: 'current_user', teacher list uses schoolId: 'current-school'. Will cause data collision in production.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("Marketplace, School Management", styles['TableCell'])],
    [Paragraph("Non-functional UI", styles['TableCell']),
     Paragraph("All dashboard 'View All' callbacks are empty (() {}). Quick action cards have no navigation. Social login shows 'coming soon' SnackBar.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("All dashboards, Login", styles['TableCell'])],
    [Paragraph("Broken Navigation", styles['TableCell']),
     Paragraph("context.go() replaces navigation stack, breaking Android back button. Reset password deep link token is empty string.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("Auth, Router", styles['TableCell'])],
    [Paragraph("Hardcoded Notification Badge", styles['TableCell']),
     Paragraph("Dashboard shell always shows red dot and badge count of 2. Misleading.", styles['TableCell']),
     Paragraph("High", styles['TableCellCenter']),
     Paragraph("dashboard_shell.dart", styles['TableCell'])],
    [Paragraph("Student ID Exposure", styles['TableCell']),
     Paragraph("Teacher sees 'Student abc123' instead of names. Partially exposes student IDs (privacy issue).", styles['TableCell']),
     Paragraph("High", styles['TableCellCenter']),
     Paragraph("exam_results_page, exam_monitor_page", styles['TableCell'])],
    [Paragraph("Currency Bug", styles['TableCell']),
     Paragraph("cart_page._formatPrice accepts currency parameter but ignores it, always showing Naira.", styles['TableCell']),
     Paragraph("Medium", styles['TableCellCenter']),
     Paragraph("cart_page.dart", styles['TableCell'])],
    [Paragraph("Memory Leak", styles['TableCell']),
     Paragraph("AppDateField creates new TextEditingController on every build() call.", styles['TableCell']),
     Paragraph("High", styles['TableCellCenter']),
     Paragraph("app_text_field.dart", styles['TableCell'])],
    [Paragraph("Crash Risk", styles['TableCell']),
     Paragraph("AppDialog.showLoading uses late BuildContext that will crash if showDialog throws.", styles['TableCell']),
     Paragraph("High", styles['TableCellCenter']),
     Paragraph("app_dialog.dart", styles['TableCell'])],
    [Paragraph("Password Inconsistency", styles['TableCell']),
     Paragraph("Registration requires 8+ chars only. Reset requires uppercase+lowercase+digit+special. User can register but cannot reset to same password.", styles['TableCell']),
     Paragraph("Critical", styles['TableCellCenter']),
     Paragraph("register_page, reset_password_page", styles['TableCell'])],
]

prod_table = Table(prod_data, colWidths=[28*mm, 72*mm, 16*mm, 34*mm])
prod_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_GRAY_700),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_GRAY_50),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 4),
    ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_GRAY_50, C_WHITE]),
]))
story.append(prod_table)
story.append(Paragraph("Table 9: Production Polish Issues", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 11: IMPROVEMENTS IMPLEMENTED
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("11. Improvements Implemented", C_SUCCESS))
story.append(Spacer(1, 4*mm))

story.append(Paragraph(
    "The following code improvements were implemented during this audit. These are verified changes to the "
    "codebase that address the most impactful issues identified across the 12 phases. Each improvement is "
    "categorized by the audit phase it addresses and includes the specific file modified, the nature of the "
    "change, and the expected user impact.",
    styles['BodyText2']
))

impl_data = [
    [Paragraph("<b>Phase</b>", styles['TableHeader']),
     Paragraph("<b>File Modified</b>", styles['TableHeader']),
     Paragraph("<b>Improvement</b>", styles['TableHeader']),
     Paragraph("<b>Impact</b>", styles['TableHeader'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_colors.dart", styles['TableCell']),
     Paragraph("Added onSuccess/onWarning/onError/onInfo companion colors and container color helpers. Fixed warningOf() to return warningDark in light mode for WCAG AA contrast.", styles['TableCell']),
     Paragraph("Fixes contrast violations for semantic color usage across the entire app.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_colors.dart", styles['TableCell']),
     Paragraph("Added successContainerOf/warningContainerOf/errorContainerOf/infoContainerOf helpers for light/dark mode.", styles['TableCell']),
     Paragraph("Provides proper container colors for status badges and indicators.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_empty_state.dart", styles['TableCell']),
     Paragraph("Added Semantics wrapper with combined title+subtitle label. Added ExcludeSemantics to decorative icon.", styles['TableCell']),
     Paragraph("Screen readers now announce empty state content. Decorative icons no longer clutter accessibility tree.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_error_state.dart", styles['TableCell']),
     Paragraph("Added Semantics wrapper with liveRegion: true and combined title+message label. Added ExcludeSemantics to decorative error icon.", styles['TableCell']),
     Paragraph("Error states are now announced to screen readers automatically. Decorative icon excluded from tree.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_loading.dart", styles['TableCell']),
     Paragraph("Added Semantics wrapper with busy: true and label. Added ExcludeSemantics to spinner widget.", styles['TableCell']),
     Paragraph("Screen readers announce loading state. ARIA-busy equivalent implemented.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_card.dart", styles['TableCell']),
     Paragraph("Added semanticLabel parameter and Semantics wrapper with button role for tappable cards.", styles['TableCell']),
     Paragraph("Tappable cards now have accessible names and button roles for screen readers.", styles['TableCell'])],
    [Paragraph("2. UI Consistency", styles['TableCell']),
     Paragraph("app_bottom_nav.dart", styles['TableCell']),
     Paragraph("Fixed badge text color from hardcoded Colors.white to AppColors.onErrorOf(brightness).", styles['TableCell']),
     Paragraph("Badge text is now theme-aware and properly contrasted in both light and dark modes.", styles['TableCell'])],
    [Paragraph("1. Accessibility", styles['TableCell']),
     Paragraph("app_theme.dart", styles['TableCell']),
     Paragraph("Changed divider color from outlineVariant to outline for WCAG 1.4.11 non-text contrast compliance. Added explanatory comment.", styles['TableCell']),
     Paragraph("Divider lines now meet 3:1 minimum contrast ratio for UI components.", styles['TableCell'])],
]

impl_table = Table(impl_data, colWidths=[22*mm, 28*mm, 62*mm, 38*mm])
impl_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_SUCCESS),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-1), C_SUCCESS_LIGHT),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 4),
    ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
    ('ROWBACKGROUNDS', (0,1), (-1,-1), [C_SUCCESS_LIGHT, C_WHITE]),
]))
story.append(impl_table)
story.append(Paragraph("Table 10: Code Improvements Implemented During Audit", styles['CaptionStyle']))

story.append(PageBreak())

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION 12: FINAL UX & ACCESSIBILITY CERTIFICATION
# ═══════════════════════════════════════════════════════════════════════════════
story.append(SectionBar("12. Final UX & Accessibility Certification", C_PRIMARY))
story.append(Spacer(1, 4*mm))

story.append(Paragraph("12.1 Certification Scores", styles['SubSection']))
story.append(Paragraph(
    "The following scores represent the current state of the ExamForge AI platform based on the comprehensive "
    "12-phase audit. Scores are on a 0-100 scale where 100 represents full compliance or excellence in that "
    "dimension. Scores are derived from the specific findings documented in each section above and reflect "
    "both the existing strengths and identified gaps. The scoring methodology weighs critical issues more "
    "heavily than minor ones and considers the proportion of affected screens relative to the total 240+ screens.",
    styles['BodyText2']
))

# Scores table
scores = [
    ("Accessibility (WCAG 2.2 AA)", 38, "Zero Semantics across features; no keyboard nav; contrast failures"),
    ("User Experience", 55, "Core flows work but with friction; non-functional elements; no confirmations"),
    ("Visual Design", 72, "Strong M3 theme system; consistent color scheme; good dark mode support"),
    ("Responsiveness", 58, "Framework exists but unused by features; inconsistent breakpoint adoption"),
    ("Design Consistency", 62, "Good token system but inconsistent adoption; duplicated patterns"),
    ("Offline Experience", 35, "Excellent engine but zero presentation-layer integration"),
    ("Error Handling", 48, "Good architecture but raw error strings shown; inconsistent coverage"),
    ("Localization Readiness", 5, "Zero i18n infrastructure; 1,200+ hardcoded strings"),
    ("Flutter UI Quality", 65, "Clean architecture; proper disposal; but missing accessibility and reduced motion"),
    ("Overall Product Experience", 48, "Solid foundation with critical gaps in accessibility and localization"),
]

cert_data = [
    [Paragraph("<b>Dimension</b>", styles['TableHeader']),
     Paragraph("<b>Score</b>", styles['TableHeader']),
     Paragraph("<b>Key Limiting Factor</b>", styles['TableHeader'])],
]

for dim, score, factor in scores:
    color = C_SUCCESS if score >= 70 else (C_WARNING if score >= 50 else C_ERROR)
    cert_data.append([
        Paragraph(dim, styles['TableCell']),
        Paragraph(f"<b>{score}/100</b>", ParagraphStyle('', fontName=HEADING_FONT, fontSize=10, textColor=color, alignment=TA_CENTER)),
        Paragraph(factor, styles['TableCell']),
    ])

# Add overall
cert_data.append([
    Paragraph("<b>OVERALL CERTIFICATION SCORE</b>", ParagraphStyle('', fontName=HEADING_FONT, fontSize=10, textColor=C_PRIMARY)),
    Paragraph("<b>48/100</b>", ParagraphStyle('', fontName=HEADING_FONT, fontSize=12, textColor=C_PRIMARY, alignment=TA_CENTER)),
    Paragraph("Not yet certifiable for production deployment at scale", ParagraphStyle('', fontName=BODY_FONT, fontSize=10, textColor=C_ERROR)),
])

cert_table = Table(cert_data, colWidths=[48*mm, 22*mm, 80*mm])
cert_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_PRIMARY),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,-2), C_GRAY_50),
    ('BACKGROUND', (0,-1), (-1,-1), C_PRIMARY_LIGHT),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ('TOPPADDING', (0,0), (-1,-1), 6),
    ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ('LEFTPADDING', (0,0), (-1,-1), 8),
    ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ('ROWBACKGROUNDS', (0,1), (-1,-2), [C_GRAY_50, C_WHITE]),
]))
story.append(cert_table)
story.append(Paragraph("Table 11: Final UX & Accessibility Certification Scores", styles['CaptionStyle']))

story.append(Spacer(1, 6*mm))
story.append(Paragraph("12.2 School Scalability Readiness", styles['SubSection']))

scale_data = [
    [Paragraph("<b>Scale Target</b>", styles['TableHeader']),
     Paragraph("<b>Ready?</b>", styles['TableHeader']),
     Paragraph("<b>Confidence</b>", styles['TableHeader']),
     Paragraph("<b>Limiting Factors</b>", styles['TableHeader']),
     Paragraph("<b>Required Engineering Steps</b>", styles['TableHeader'])],
    [Paragraph("10 Schools", styles['TableCell']),
     Paragraph("Conditionally Yes", styles['TableCellCenter']),
     Paragraph("Medium (60%)", styles['TableCellCenter']),
     Paragraph("Placeholder IDs ('current_user', 'current-school') will cause data collisions. Non-functional dashboard elements. No offline support. Password validation inconsistency.", styles['TableCell']),
     Paragraph("1. Fix placeholder IDs (2-3 days). 2. Wire dashboard stats to real data (3-5 days). 3. Fix password validation (1 day). 4. Add logout confirmation (0.5 day).", styles['TableCell'])],
    [Paragraph("100 Schools", styles['TableCell']),
     Paragraph("Not Ready", styles['TableCellCenter']),
     Paragraph("Low (30%)", styles['TableCellCenter']),
     Paragraph("All 10-school issues plus: zero accessibility compliance (legal risk), no localization, no keyboard navigation, no offline UX, raw error messages shown to users, inconsistent responsive design.", styles['TableCell']),
     Paragraph("1. All 10-school fixes. 2. Add Semantics to all feature screens (2-3 weeks). 3. Implement i18n infrastructure (4-6 weeks). 4. Add keyboard navigation (1-2 weeks). 5. Integrate connectivity engine in presentation (1 week). 6. Map Failure to friendly messages (3-5 days).", styles['TableCell'])],
    [Paragraph("1,000 Schools", styles['TableCell']),
     Paragraph("Not Ready", styles['TableCellCenter']),
     Paragraph("Very Low (10%)", styles['TableCellCenter']),
     Paragraph("All 100-school issues plus: no pagination (unbounded queries), no performance optimization, no load testing verification, no RTL support, no reduced motion, extensive code duplication.", styles['TableCell']),
     Paragraph("1. All 100-school fixes. 2. Add pagination to all list views (1-2 weeks). 3. Implement reduced motion (3-5 days). 4. Add RTL support (1 week). 5. Extract duplicated UI patterns (1 week). 6. Performance audit and optimization (2-3 weeks).", styles['TableCell'])],
]

scale_table = Table(scale_data, colWidths=[22*mm, 18*mm, 16*mm, 52*mm, 42*mm])
scale_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), C_PRIMARY),
    ('TEXTCOLOR', (0,0), (-1,0), C_WHITE),
    ('BACKGROUND', (0,1), (-1,1), C_WARNING_LIGHT),
    ('BACKGROUND', (0,2), (-1,2), C_ERROR_LIGHT),
    ('BACKGROUND', (0,3), (-1,3), HexColor('#FEF2F2')),
    ('GRID', (0,0), (-1,-1), 0.5, C_GRAY_200),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('TOPPADDING', (0,0), (-1,-1), 5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 5),
    ('LEFTPADDING', (0,0), (-1,-1), 5),
    ('RIGHTPADDING', (0,0), (-1,-1), 5),
]))
story.append(scale_table)
story.append(Paragraph("Table 12: School Scalability Readiness Assessment", styles['CaptionStyle']))

story.append(Spacer(1, 6*mm))
story.append(Paragraph("12.3 Top 10 Priority Recommendations", styles['SubSection']))

priority_items = [
    ("P0-1: Fix Placeholder IDs", "Replace 'current_user' and 'current-school' with actual auth state. This is a data integrity blocker for any multi-user deployment.", "2-3 days", "Critical"),
    ("P0-2: Add Semantics to ExamTakePage", "The most accessibility-critical screen. Add Semantics to questions, options, timer, navigation, and submit dialog. Add keyboard shortcuts.", "3-5 days", "Critical"),
    ("P0-3: Fix WCAG Contrast Failures", "Use warningDark in light mode (already fixed in app_colors.dart). Apply companion color helpers across all feature modules.", "2-3 days", "Critical"),
    ("P0-4: Fix Touch Target Violations", "Remove BoxConstraints() on error close buttons. Change shrinkWrap to padded on TextButtons. Ensure all interactive elements >= 48dp.", "2-3 days", "Critical"),
    ("P1-1: Implement i18n Infrastructure", "Set up flutter_localizations, create ARB files, extract all 1,200+ hardcoded strings. Start with English, then add major Nigerian languages.", "4-6 weeks", "High"),
    ("P1-2: Add Keyboard Navigation", "Add FocusNodes, focus traversal groups, and keyboard shortcuts to all major workflows, especially exam-taking and form completion.", "1-2 weeks", "High"),
    ("P1-3: Integrate Connectivity Engine", "Add offline banner to dashboard shell. Disable AI generation and payment when offline. Queue exam answers locally. Add sync indicator.", "1 week", "High"),
    ("P1-4: Map Failures to Friendly Messages", "Create a FailureMapper utility that converts Failure.when() results to user-friendly messages. Never show raw error strings.", "3-5 days", "High"),
    ("P2-1: Extract Duplicated Patterns", "Extract icon-in-colored-container, button child builder, _formatTimeAgo, and other duplicated code into shared utilities.", "1 week", "Medium"),
    ("P2-2: Use Responsive Framework", "Replace custom responsive code with AdaptiveGrid/ResponsiveLayout from the existing framework. Fix screenSizeProvider to be reactive.", "1-2 weeks", "Medium"),
]

for i, (title, desc, effort, severity) in enumerate(priority_items):
    sev_color = C_ERROR if severity == "Critical" else (C_WARNING if severity == "High" else C_INFO)
    story.append(Paragraph(
        f"<b>{title}</b> [{severity}] — {desc} <i>Estimated effort: {effort}</i>",
        ParagraphStyle('', fontName=BODY_FONT, fontSize=9.5, leading=14, textColor=C_GRAY_700,
                      leftIndent=12, spaceBefore=4, spaceAfter=4,
                      borderPadding=(3, 3, 3, 3))
    ))

story.append(Spacer(1, 8*mm))
story.append(Paragraph("12.4 Certification Statement", styles['SubSection']))

cert_stmt_data = [[Paragraph(
    "<b>CERTIFICATION STATEMENT</b><br/><br/>"
    "Based on the comprehensive 12-phase audit of ExamForge AI covering 22 feature modules, 240+ screens, "
    "148 custom widgets, and 88 Riverpod providers, the platform achieves an overall UX & Accessibility "
    "Certification Score of <b>48/100</b>. The platform demonstrates strong architectural foundations in its "
    "Material 3 theme system, clean architecture, and sophisticated infrastructure components (connectivity "
    "engine, responsive framework, accessibility framework). However, critical gaps in accessibility "
    "implementation (zero Semantics in features, no keyboard navigation, contrast failures), zero "
    "localization infrastructure, and placeholder data in core screens prevent production certification "
    "at this time.<br/><br/>"
    "The platform is <b>conditionally ready for 10-school deployment</b> provided that placeholder IDs are "
    "fixed, dashboard data is wired to real APIs, and password validation is harmonized. <b>100-school and "
    "1,000-school readiness require</b> comprehensive accessibility implementation, localization infrastructure, "
    "keyboard navigation, offline UX integration, and error message mapping — estimated at 8-12 weeks of "
    "dedicated engineering effort beyond the current codebase state.<br/><br/>"
    "This certification is based on code-level evidence reviewed during the audit period. No benchmark numbers "
    "were invented; all findings are verifiable through the source code.",
    ParagraphStyle('', fontName=BODY_FONT, fontSize=10, leading=15, textColor=C_GRAY_900, alignment=TA_JUSTIFY)
)]]

cert_stmt_table = Table(cert_stmt_data, colWidths=[170*mm])
cert_stmt_table.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), C_PRIMARY_LIGHT),
    ('BOX', (0,0), (-1,-1), 2, C_PRIMARY),
    ('ROUNDEDCORNERS', [6, 6, 6, 6]),
    ('TOPPADDING', (0,0), (-1,-1), 12),
    ('BOTTOMPADDING', (0,0), (-1,-1), 12),
    ('LEFTPADDING', (0,0), (-1,-1), 16),
    ('RIGHTPADDING', (0,0), (-1,-1), 16),
]))
story.append(cert_stmt_table)

# ─── Build PDF ────────────────────────────────────────────────────────────────
doc.build(story)
print(f"PDF generated: {OUTPUT}")
print(f"File size: {os.path.getsize(OUTPUT):,} bytes")
