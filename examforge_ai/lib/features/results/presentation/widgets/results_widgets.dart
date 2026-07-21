// ═══════════════════════════════════════════════════════════════════════
// RESULTS ENGINE — PRESENTATION WIDGETS
// ═══════════════════════════════════════════════════════════════════════
// Reusable Material 3 widgets for the Results Engine feature.
//
// All widgets follow these conventions:
//   • ConsumerWidget where Riverpod state is needed
//   • Theme.of(context) for all styling (light + dark theme support)
//   • Indigo (#4F46E5) as the primary accent colour
//   • dartdoc on every public widget and callback
//
// Import this single file to access every results widget:
//   import 'package:examforge_ai/features/results/presentation/widgets/results_widgets.dart';
// ═══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/results_entities.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/results/domain/entities/results_entities.dart';
import '../../../../features/student_portal/domain/entities/student_portal_entities.dart';




// ═══════════════════════════════════════════════════════════════════════
// COLOUR HELPERS
// ═══════════════════════════════════════════════════════════════════════

/// Primary Indigo accent used across all results widgets.
const kIndigo = Color(0xFF4F46E5);

/// Parses a hex colour string (e.g. '#22C55E') into a [Color].
/// Falls back to [fallback] when [hex] is null or invalid.
Color parseHexColor(String? hex, {Color fallback = kIndigo}) {
  if (hex == null || hex.isEmpty) return fallback;
  final sanitized = hex.replaceFirst('#', '');
  if (sanitized.length == 6) {
    return Color(int.parse('FF$sanitized', radix: 16));
  }
  if (sanitized.length == 8) {
    return Color(int.parse(sanitized, radix: 16));
  }
  return fallback;
}

/// Returns an ordinal suffix for [n] (1st, 2nd, 3rd, 4th, …).
String ordinalSuffix(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 1. GRADE BADGE
// ═══════════════════════════════════════════════════════════════════════

/// A small coloured badge showing a letter grade (A1, B2, C6, F9, etc.).
///
/// Colours are derived automatically:
///   - **Green** for passing grades (`isPassing == true`)
///   - **Red** for failing grades (`isPassing == false`)
///   - **Amber** for borderline grades (percentage 40–49.9)
///
/// ```dart
/// GradeBadge(grade: 'A1', isPassing: true)
/// ```
class GradeBadge extends StatelessWidget {
  /// Creates a [GradeBadge].
  const GradeBadge({
    super.key,
    required this.grade,
    required this.isPassing,
    this.percentage,
    this.fontSize = 12,
  });

  /// The letter grade text (e.g. "A1", "B3", "F9").
  final String grade;

  /// Whether this grade is a passing grade.
  final bool isPassing;

  /// Optional percentage used to detect borderline (40–49.9).
  final double? percentage;

  /// Font size for the grade text.
  final double fontSize;

  bool get _isBorderline =>
      percentage != null && percentage! >= 40 && percentage! < 50;

  Color get _backgroundColor {
    if (_isBorderline) return Colors.amber.shade700;
    return isPassing ? Colors.green.shade600 : Colors.red.shade600;
  }

  Color get _foregroundColor {
    if (_isBorderline) return Colors.white;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: _foregroundColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 2. MASTERY LEVEL BADGE
// ═══════════════════════════════════════════════════════════════════════

/// A coloured chip showing a mastery level.
///
/// Colour is derived from the [MasteryLevel] enum's [color] property.
///
/// ```dart
/// MasteryLevelBadge(level: MasteryLevel.advanced)
/// ```
class MasteryLevelBadge extends StatelessWidget {
  /// Creates a [MasteryLevelBadge].
  const MasteryLevelBadge({
    super.key,
    required this.level,
    this.showPercentage = false,
  });

  /// The mastery level to display.
  final MasteryLevel level;

  /// Whether to also show the percentage indicator.
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(level.color, fallback: Colors.grey);

    return Chip(
      avatar: showPercentage
          ? CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                '${level.percentage}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            )
          : null,
      label: Text(level.label),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. PERFORMANCE TREND INDICATOR
// ═══════════════════════════════════════════════════════════════════════

/// A row showing a trend icon + label + colour.
///
/// ```dart
/// PerformanceTrendIndicator(trend: PerformanceTrend.improving)
/// ```
class PerformanceTrendIndicator extends StatelessWidget {
  /// Creates a [PerformanceTrendIndicator].
  const PerformanceTrendIndicator({
    super.key,
    required this.trend,
    this.showLabel = true,
    this.iconSize = 18,
    this.fontSize = 12,
  });

  /// The performance trend to visualise.
  final PerformanceTrend trend;

  /// Whether to show the text label next to the icon.
  final bool showLabel;

  /// Size of the trend icon.
  final double iconSize;

  /// Font size of the label text.
  final double fontSize;

  IconData get _icon {
    switch (trend) {
      case PerformanceTrend.improving:
        return Icons.trending_up;
      case PerformanceTrend.stable:
        return Icons.trending_flat;
      case PerformanceTrend.declining:
        return Icons.trending_down;
    }
  }

  Color get _color => parseHexColor(trend.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: iconSize, color: _color),
        if (showLabel) ...[
          const Gap(4),
          Text(
            trend.label,
            style: TextStyle(
              color: _color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 4. SCORE CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card showing a score with percentage, grade badge, and pass/fail indicator.
///
/// Layout:
/// ```
/// ┌──────────────────────────┐
/// │ Mathematics    A1  85.3% │
/// │ ████████████░░░░ 85/100  │
/// │ Position: 5th of 30      │
/// │ ↑ Improving              │
/// └──────────────────────────┘
/// ```
///
/// ```dart
/// ScoreCard(
///   subjectName: 'Mathematics',
///   percentage: 85.3,
///   marksObtained: 85,
///   marksPossible: 100,
///   grade: 'A1',
///   isPassing: true,
///   classPosition: 5,
///   classSize: 30,
///   trend: PerformanceTrend.improving,
/// )
/// ```
class ScoreCard extends StatelessWidget {
  /// Creates a [ScoreCard].
  const ScoreCard({
    super.key,
    required this.subjectName,
    required this.percentage,
    required this.marksObtained,
    required this.marksPossible,
    this.grade,
    this.isPassing = true,
    this.classPosition,
    this.classSize,
    this.trend,
    this.onTap,
  });

  /// Display name of the subject.
  final String subjectName;

  /// Score as a percentage (0–100).
  final double percentage;

  /// Raw marks obtained.
  final double marksObtained;

  /// Maximum marks possible.
  final double marksPossible;

  /// Letter grade (e.g. "A1"). If null, no badge is shown.
  final String? grade;

  /// Whether the score is a passing score.
  final bool isPassing;

  /// Student's position in the class (1-based).
  final int? classPosition;

  /// Total number of students in the class.
  final int? classSize;

  /// Performance trend for this subject.
  final PerformanceTrend? trend;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Subject · Grade badge · Percentage ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subjectName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (grade != null) ...[
                    GradeBadge(grade: grade!, isPassing: isPassing, percentage: percentage),
                    const Gap(8),
                  ],
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPassing ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // ── Row 2: Progress bar + fraction ──
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPassing ? Colors.green.shade500 : Colors.red.shade400,
                        ),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    '${marksObtained.toInt()}/${marksPossible.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // ── Row 3: Position ──
              if (classPosition != null && classSize != null)
                Text(
                  'Position: ${ordinalSuffix(classPosition!)} of $classSize',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

              // ── Row 4: Trend ──
              if (trend != null) ...[
                const Gap(4),
                PerformanceTrendIndicator(trend: trend!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 5. SUBJECT RESULT CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card showing a single subject result with deviation from average.
///
/// Displays: subject name, score, grade, position, class average, deviation.
///
/// ```dart
/// SubjectResultCard(result: mySubjectResult, subjectName: 'Physics')
/// ```
class SubjectResultCard extends StatelessWidget {
  /// Creates a [SubjectResultCard].
  const SubjectResultCard({
    super.key,
    required this.result,
    required this.subjectName,
    this.onTap,
  });

  /// The subject result entity.
  final StudentSubjectResultEntity result;

  /// Display name of the subject.
  final String subjectName;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deviation = result.deviationFromClassAverage;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Subject name + position ──
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Position: ${result.positionLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Score ──
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: result.isPassed
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    if (result.grade != null)
                      GradeBadge(
                        grade: result.grade!,
                        isPassing: result.isPassed,
                        percentage: result.percentage,
                      ),
                  ],
                ),
              ),

              // ── Class average + deviation ──
              if (result.classAverage != null) ...[
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Avg: ${result.classAverage!.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (deviation != null)
                        Text(
                          '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: deviation >= 0
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // ── Trend icon ──
              if (result.performanceTrend != PerformanceTrend.stable) ...[
                const Gap(8),
                PerformanceTrendIndicator(
                  trend: result.performanceTrend,
                  showLabel: false,
                  iconSize: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 6. STUDENT RANKING TABLE
// ═══════════════════════════════════════════════════════════════════════

/// A data row for [StudentRankingTable].
class StudentRankingEntry {
  /// Creates a [StudentRankingEntry].
  const StudentRankingEntry({
    required this.position,
    required this.name,
    required this.score,
    required this.grade,
    required this.isPassing,
  });

  /// 1-based position.
  final int position;

  /// Student display name.
  final String name;

  /// Score as a percentage.
  final double score;

  /// Letter grade.
  final String grade;

  /// Whether the student is passing.
  final bool isPassing;
}

/// A [DataTable] showing student rankings with colour-coded rows.
///
/// The top 3 students are highlighted with gold / silver / bronze tints.
///
/// ```dart
/// StudentRankingTable(
///   entries: [
///     StudentRankingEntry(position: 1, name: 'Alice', score: 95.2, grade: 'A1', isPassing: true),
///     StudentRankingEntry(position: 2, name: 'Bob', score: 88.0, grade: 'B2', isPassing: true),
///   ],
/// )
/// ```
class StudentRankingTable extends StatelessWidget {
  /// Creates a [StudentRankingTable].
  const StudentRankingTable({
    super.key,
    required this.entries,
    this.onRowTap,
    this.showStatus = true,
  });

  /// The ranked list of students.
  final List<StudentRankingEntry> entries;

  /// Optional callback when a row is tapped; receives the entry index.
  final void Function(int index)? onRowTap;

  /// Whether to show the Pass/Fail status column.
  final bool showStatus;

  /// Medal colours for positions 1–3.
  static const _medalColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFC0C0C0), // Silver
    Color(0xFFCD7F32), // Bronze
  ];

  Color? _rowColor(int position, Brightness brightness) {
    if (position >= 1 && position <= 3) {
      final medal = _medalColors[position - 1];
      return brightness == Brightness.light
          ? medal.withOpacity(0.12)
          : medal.withOpacity(0.18);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: kIndigo,
        ),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columns: [
          const DataColumn(label: Text('Position')),
          const DataColumn(label: Text('Name')),
          const DataColumn(label: Text('Score'), numeric: true),
          const DataColumn(label: Text('Grade')),
          if (showStatus) const DataColumn(label: Text('Status')),
        ],
        rows: entries.map((entry) {
          final rowColor = _rowColor(entry.position, brightness);
          return DataRow(
            color: rowColor != null
                ? MaterialStatePropertyAll(rowColor)
                : null,
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.position <= 3)
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: _medalColors[entry.position - 1],
                      )
                    else
                      const SizedBox(width: 16),
                    const Gap(4),
                    Text(ordinalSuffix(entry.position)),
                  ],
                ),
              ),
              DataCell(Text(entry.name)),
              DataCell(Text('${entry.score.toStringAsFixed(1)}%')),
              DataCell(
                GradeBadge(
                  grade: entry.grade,
                  isPassing: entry.isPassing,
                  fontSize: 11,
                ),
              ),
              if (showStatus)
                DataCell(
                  Text(
                    entry.isPassing ? 'Pass' : 'Fail',
                    style: TextStyle(
                      color: entry.isPassing ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            onSelectChanged: onRowTap != null
                ? (_) => onRowTap!(entry.position - 1)
                : null,
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 7. AI GRADING CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card showing an AI grading suggestion for teacher review.
///
/// Features:
///   - Truncated question text and student answer
///   - AI suggested score with confidence
///   - Accept / Override / Reject action buttons
///   - Expandable explanation section
///
/// ```dart
/// AiGradingCard(
///   result: aiResult,
///   questionText: 'Explain photosynthesis...',
///   studentAnswer: 'Photosynthesis is the process...',
///   onAccept: () => ...,
///   onOverride: (newScore) => ...,
///   onReject: () => ...,
/// )
/// ```
class AiGradingCard extends StatefulWidget {
  /// Creates an [AiGradingCard].
  const AiGradingCard({
    super.key,
    required this.result,
    required this.questionText,
    required this.studentAnswer,
    this.onAccept,
    this.onOverride,
    this.onReject,
    this.maxLinesQuestion = 2,
    this.maxLinesAnswer = 3,
  });

  /// The AI grading result entity.
  final AiGradingResultEntity result;

  /// The question text to display (will be truncated).
  final String questionText;

  /// The student's answer text (will be truncated).
  final String studentAnswer;

  /// Called when the teacher accepts the AI suggestion.
  final VoidCallback? onAccept;

  /// Called when the teacher overrides with a new score.
  final void Function(double newScore)? onOverride;

  /// Called when the teacher rejects the AI suggestion.
  final VoidCallback? onReject;

  /// Maximum visible lines for question text before truncation.
  final int maxLinesQuestion;

  /// Maximum visible lines for answer text before truncation.
  final int maxLinesAnswer;

  @override
  State<AiGradingCard> createState() => _AiGradingCardState();
}

class _AiGradingCardState extends State<AiGradingCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = widget.result;
    final isReviewed = result.status.isTerminal;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isReviewed
              ? colorScheme.outlineVariant
              : kIndigo.withOpacity(0.4),
          width: isReviewed ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: AI provider + status ──
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: kIndigo),
                const Gap(6),
                Text(
                  'AI Grading — ${result.aiProvider}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: kIndigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _AiGradingStatusChip(status: result.status),
              ],
            ),
            const Divider(height: 20),

            // ── Question ──
            Text(
              'Question',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(2),
            Text(
              widget.questionText,
              maxLines: widget.maxLinesQuestion,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(10),

            // ── Student Answer ──
            Text(
              'Student Answer',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(2),
            Text(
              widget.studentAnswer,
              maxLines: widget.maxLinesAnswer,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const Gap(12),

            // ── Score + confidence ──
            Row(
              children: [
                Text(
                  'Suggested: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${result.suggestedScore.toStringAsFixed(1)} / ${result.maxPossible.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),
                Text(
                  'Confidence: ${result.confidenceLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: result.confidenceScore != null && result.confidenceScore! >= 0.8
                        ? Colors.green.shade700
                        : Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(12),

            // ── Action buttons (only if not yet reviewed) ──
            if (!isReviewed) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAccept,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onOverride != null
                          ? () => _showOverrideDialog(context)
                          : null,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Override'),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
            ],

            // ── Expandable explanation ──
            if (result.explanation != null &&
                result.explanation!.isNotEmpty) ...[
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: kIndigo,
                    ),
                    const Gap(4),
                    Text(
                      'AI Explanation',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: kIndigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
                const Gap(8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kIndigo.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.explanation!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showOverrideDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: widget.result.suggestedScore.toStringAsFixed(1),
    );
    final newScore = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override Score'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'New Score (max ${widget.result.maxPossible})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) Navigator.pop(ctx, val);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (newScore != null && widget.onOverride != null) {
      widget.onOverride!(newScore);
    }
  }
}

/// Small status chip used inside [AiGradingCard].
class _AiGradingStatusChip extends StatelessWidget {
  const _AiGradingStatusChip({required this.status});

  final AiGradingStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case AiGradingStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade800;
        break;
      case AiGradingStatus.processing:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      case AiGradingStatus.completed:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      case AiGradingStatus.failed:
        bg = Colors.red.shade100;
        fg = Colors.red.shade800;
        break;
      case AiGradingStatus.overridden:
        bg = Colors.purple.shade100;
        fg = Colors.purple.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 8. GRADE SCALE EDITOR
// ═══════════════════════════════════════════════════════════════════════

/// A form widget for editing grade scale entries.
///
/// Features:
///   - List of entries with grade, min%, max%, GPA value
///   - Add / remove entry buttons
///   - Drag handle for reordering
///
/// ```dart
/// GradeScaleEditor(
///   entries: myEntries,
///   onChanged: (updatedEntries) { ... },
/// )
/// ```
class GradeScaleEditor extends StatefulWidget {
  /// Creates a [GradeScaleEditor].
  const GradeScaleEditor({
    super.key,
    required this.entries,
    this.onChanged,
    this.showGpaField = true,
  });

  /// The current list of grade scale entries.
  final List<GradeScaleEntryEntity> entries;

  /// Called when entries are added, removed, reordered, or modified.
  final ValueChanged<List<GradeScaleEntryEntity>>? onChanged;

  /// Whether to show the GPA value field.
  final bool showGpaField;

  @override
  State<GradeScaleEditor> createState() => _GradeScaleEditorState();
}

class _GradeScaleEditorState extends State<GradeScaleEditor> {
  late List<GradeScaleEntryEntity> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.entries);
  }

  @override
  void didUpdateWidget(covariant GradeScaleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = List.from(widget.entries);
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(List.from(_entries));
  }

  void _addEntry() {
    setState(() {
      _entries.add(GradeScaleEntryEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        grade: 'New',
        minPercentage: 0,
        maxPercentage: 0,
        gpaValue: 0,
        isPassing: true,
        sortOrder: _entries.length,
      ));
    });
    _notifyChanged();
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _notifyChanged();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, item);
      // Update sort orders
      for (var i = 0; i < _entries.length; i++) {
        _entries[i] = _entries[i].copyWith(sortOrder: i);
      }
    });
    _notifyChanged();
  }

  void _updateEntry(int index, GradeScaleEntryEntity updated) {
    setState(() => _entries[index] = updated);
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text('Grade', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 70,
                child: Text('Min %', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 70,
                child: Text('Max %', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (widget.showGpaField)
                SizedBox(
                  width: 60,
                  child: Text('GPA', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
              SizedBox(
                width: 60,
                child: Text('Pass', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const Gap(4),

        // ── Reorderable list ──
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _entries.length,
          onReorder: _reorder,
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return _GradeScaleEntryRow(
              key: ValueKey(entry.id),
              entry: entry,
              showGpaField: widget.showGpaField,
              onChanged: (updated) => _updateEntry(index, updated),
              onRemove: () => _removeEntry(index),
            );
          },
        ),

        const Gap(8),

        // ── Add button ──
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Entry'),
            style: OutlinedButton.styleFrom(foregroundColor: kIndigo),
          ),
        ),
      ],
    );
  }
}

/// A single row inside the [GradeScaleEditor].
class _GradeScaleEntryRow extends StatelessWidget {
  const _GradeScaleEntryRow({
    super.key,
    required this.entry,
    required this.showGpaField,
    this.onChanged,
    this.onRemove,
  });

  final GradeScaleEntryEntity entry;
  final bool showGpaField;
  final ValueChanged<GradeScaleEntryEntity>? onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Drag handle
        ReorderableDragStartListener(
          index: 0, // placeholder; ReorderableListView handles the real index
          child: Icon(
            Icons.drag_handle,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(4),

        // Grade
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: entry.grade,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => onChanged?.call(entry.copyWith(grade: v)),
          ),
        ),
        const Gap(4),

        // Min %
        SizedBox(
          width: 70,
          child: TextFormField(
            initialValue: entry.minPercentage.toStringAsFixed(0),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) onChanged?.call(entry.copyWith(minPercentage: val));
            },
          ),
        ),
        const Gap(4),

        // Max %
        SizedBox(
          width: 70,
          child: TextFormField(
            initialValue: entry.maxPercentage.toStringAsFixed(0),
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) onChanged?.call(entry.copyWith(maxPercentage: val));
            },
          ),
        ),
        const Gap(4),

        // GPA
        if (showGpaField)
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: entry.gpaValue?.toStringAsFixed(1) ?? '0.0',
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null) onChanged?.call(entry.copyWith(gpaValue: val));
              },
            ),
          ),
        if (showGpaField) const Gap(4),

        // Pass toggle
        SizedBox(
          width: 60,
          child: Switch(
            value: entry.isPassing,
            onChanged: (v) => onChanged?.call(entry.copyWith(isPassing: v)),
            activeColor: Colors.green,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),

        // Remove
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
          onPressed: onRemove,
          tooltip: 'Remove entry',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 9. STAT CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card showing a single statistic with a large number, label, and
/// optional icon and trend indicator.
///
/// ```dart
/// StatCard(
///   value: '85.3%',
///   label: 'Average Score',
///   icon: Icons.school,
///   trend: PerformanceTrend.improving,
/// )
/// ```
class StatCard extends StatelessWidget {
  /// Creates a [StatCard].
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.trend,
    this.iconColor,
    this.onTap,
  });

  /// The large display value (e.g. "85.3%").
  final String value;

  /// Descriptive label below the value.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trend indicator.
  final PerformanceTrend? trend;

  /// Colour for the leading icon (defaults to Indigo).
  final Color? iconColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon row ──
              if (icon != null)
                Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? kIndigo,
                ),
              if (icon != null) const Gap(12),

              // ── Value ──
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Gap(4),

              // ── Label ──
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              // ── Trend ──
              if (trend != null) ...[
                const Gap(8),
                PerformanceTrendIndicator(trend: trend!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 10. SCORE DISTRIBUTION CHART
// ═══════════════════════════════════════════════════════════════════════

/// A single bucket in the score distribution.
class ScoreBucket {
  /// Creates a [ScoreBucket].
  const ScoreBucket({
    required this.label,
    required this.count,
    required this.totalStudents,
  });

  /// Label for the bucket (e.g. "0–10", "10–20").
  final String label;

  /// Number of students in this bucket.
  final int count;

  /// Total number of students across all buckets (for percentage).
  final int totalStudents;

  /// Percentage of total students in this bucket.
  double get percentage =>
      totalStudents > 0 ? (count / totalStudents) * 100 : 0;
}

/// A placeholder widget showing score distribution as horizontal bars.
///
/// Each bar represents a score bucket (0–10, 10–20, …, 90–100) with count
/// and percentage labels.
///
/// ```dart
/// ScoreDistributionChart(buckets: myBuckets)
/// ```
class ScoreDistributionChart extends StatelessWidget {
  /// Creates a [ScoreDistributionChart].
  const ScoreDistributionChart({
    super.key,
    required this.buckets,
    this.barColor,
    this.maxBarWidth = 200,
  });

  /// The score buckets to display.
  final List<ScoreBucket> buckets;

  /// Colour for the bars (defaults to Indigo).
  final Color? barColor;

  /// Maximum width for a 100% bar.
  final double maxBarWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final barFill = barColor ?? kIndigo;
    final maxCount = buckets.fold<int>(0, (max, b) => b.count > max ? b.count : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buckets.map((bucket) {
        final fraction = maxCount > 0 ? bucket.count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              // Label
              SizedBox(
                width: 52,
                child: Text(
                  bucket.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxBarWidth),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 14,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(barFill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(8),

              // Count + percentage
              SizedBox(
                width: 72,
                child: Text(
                  '${bucket.count} (${bucket.percentage.toStringAsFixed(0)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Convenience factory that generates default 0–100 buckets in steps of 10.
  factory ScoreDistributionChart.fromCounts({
    Key? key,
    required List<int> counts,
    Color? barColor,
    double maxBarWidth = 200,
  }) {
    final total = counts.fold<int>(0, (sum, c) => sum + c);
    final buckets = <ScoreBucket>[];
    for (var i = 0; i < counts.length && i < 10; i++) {
      final low = i * 10;
      final high = low + 10;
      buckets.add(ScoreBucket(
        label: '$low–$high',
        count: counts[i],
        totalStudents: total,
      ));
    }
    return ScoreDistributionChart(
      key: key,
      buckets: buckets,
      barColor: barColor,
      maxBarWidth: maxBarWidth,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 11. DASHBOARD WIDGET CARD
// ═══════════════════════════════════════════════════════════════════════

/// A configurable card that renders different content based on
/// [DashboardWidgetType].
///
/// Shows a title, optional refresh indicator, and delegates to the
/// appropriate sub-widget based on [widgetType].
///
/// ```dart
/// DashboardWidgetCard(
///   config: DashboardWidgetConfigEntity(...),
///   onRefresh: () async { ... },
///   child: MyCustomWidget(),
/// )
/// ```
class DashboardWidgetCard extends ConsumerWidget {
  /// Creates a [DashboardWidgetCard].
  const DashboardWidgetCard({
    super.key,
    required this.config,
    this.child,
    this.onRefresh,
    this.isLoading = false,
  });

  /// The dashboard widget configuration.
  final DashboardWidgetConfigEntity config;

  /// The content widget rendered inside this card.
  /// If null, a placeholder is shown based on [DashboardWidgetType].
  final Widget? child;

  /// Optional refresh callback.
  final Future<void> Function()? onRefresh;

  /// Whether data is currently loading.
  final bool isLoading;

  IconData get _typeIcon {
    switch (config.widgetType) {
      case DashboardWidgetType.passRate:
        return Icons.percent;
      case DashboardWidgetType.scoreDistribution:
        return Icons.bar_chart;
      case DashboardWidgetType.subjectComparison:
        return Icons.compare;
      case DashboardWidgetType.topPerformers:
        return Icons.emoji_events;
      case DashboardWidgetType.difficultTopics:
        return Icons.warning_amber;
      case DashboardWidgetType.gradeDistribution:
        return Icons.pie_chart;
      case DashboardWidgetType.attendanceVsPerformance:
        return Icons.people;
      case DashboardWidgetType.historicalTrend:
        return Icons.trending_up;
      case DashboardWidgetType.classRanking:
        return Icons.leaderboard;
      case DashboardWidgetType.examParticipation:
        return Icons.how_to_reg;
      case DashboardWidgetType.gpaDistribution:
        return Icons.school;
      case DashboardWidgetType.improvementTracking:
        return Icons.speed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Icon(_typeIcon, size: 18, color: kIndigo),
                const Gap(8),
                Expanded(
                  child: Text(
                    config.title.isNotEmpty ? config.title : config.widgetType.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kIndigo,
                    ),
                  ),
                if (onRefresh != null && !isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: onRefresh != null ? () => onRefresh!() : null,
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                  ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child ?? _buildPlaceholder(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon, size: 48, color: kIndigo.withOpacity(0.3)),
          const Gap(8),
          Text(
            config.widgetType.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 12. REPORT EXPORT CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card showing a report export entry with status, format, and download.
///
/// ```dart
/// ReportExportCard(
///   report: myReportEntity,
///   onDownload: () { ... },
/// )
/// ```
class ReportExportCard extends StatelessWidget {
  /// Creates a [ReportExportCard].
  const ReportExportCard({
    super.key,
    required this.report,
    this.onDownload,
    this.onRetry,
  });

  /// The report export entity.
  final ReportExportEntity report;

  /// Called when the download button is tapped.
  final VoidCallback? onDownload;

  /// Called when the retry button is tapped (for failed reports).
  final VoidCallback? onRetry;

  String get _formattedDate => DateFormat.yMMMd().format(report.createdAt);

  Color _statusColor() {
    switch (report.status) {
      case ReportStatus.pending:
        return Colors.amber.shade700;
      case ReportStatus.processing:
        return Colors.blue.shade700;
      case ReportStatus.completed:
        return Colors.green.shade700;
      case ReportStatus.failed:
        return Colors.red.shade700;
    }
  }

  IconData _statusIcon() {
    switch (report.status) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.processing:
        return Icons.sync;
      case ReportStatus.completed:
        return Icons.check_circle;
      case ReportStatus.failed:
        return Icons.error;
    }
  }

  IconData _formatIcon() {
    switch (report.reportFormat) {
      case ReportFormat.pdf:
        return Icons.picture_as_pdf;
      case ReportFormat.excel:
        return Icons.table_chart;
      case ReportFormat.csv:
        return Icons.data_object;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Format icon ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kIndigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_formatIcon(), size: 24, color: kIndigo),
            ),
            const Gap(12),

            // ── Info column ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.reportType.label,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Gap(6),
                      // Format badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.reportFormat.label,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Gap(6),
                      // Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(), size: 14, color: _statusColor()),
                          const Gap(3),
                          Text(
                            report.status.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _statusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    _formattedDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ──
            if (report.status == ReportStatus.completed)
              IconButton(
                onPressed: onDownload,
                icon: const Icon(Icons.download),
                tooltip: 'Download',
                color: kIndigo,
              ),
            if (report.status == ReportStatus.failed)
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                tooltip: 'Retry',
                color: Colors.red.shade400,
              ),
            if (report.status == ReportStatus.processing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kIndigo.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 13. RESULT STATUS CHIP
// ═══════════════════════════════════════════════════════════════════════

/// Status values for [ResultStatusChip].
enum ResultStatus {
  /// Results are published and visible.
  published(label: 'Published', icon: Icons.publish, color: '#22C55E'),

  /// Results are withheld / on hold.
  withheld(label: 'Withheld', icon: Icons.pause_circle, color: '#F97316'),

  /// Results are locked by admin.
  locked(label: 'Locked', icon: Icons.lock, color: '#EF4444'),

  /// Results are in draft state.
  draft(label: 'Draft', icon: Icons.edit_note, color: '#9CA3AF');

  const ResultStatus({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final String color;
}

/// A chip showing result status (Published, Withheld, Locked, Draft).
///
/// ```dart
/// ResultStatusChip(status: ResultStatus.published)
/// ```
class ResultStatusChip extends StatelessWidget {
  /// Creates a [ResultStatusChip].
  const ResultStatusChip({
    super.key,
    required this.status,
    this.onTap,
  });

  /// The result status to display.
  final ResultStatus status;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(status.color);

    return ActionChip(
      onPressed: onTap,
      avatar: Icon(status.icon, size: 16, color: color),
      label: Text(status.label),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 14. BONUS — STUDENT OVERALL RESULT SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════

/// A summary card for a student's overall result across all subjects.
///
/// Shows overall percentage, grade, position, pass/fail breakdown,
/// and promotion status.
///
/// ```dart
/// StudentOverallResultCard(
///   result: overallResult,
///   studentName: 'Alice Johnson',
/// )
/// ```
class StudentOverallResultCard extends StatelessWidget {
  /// Creates a [StudentOverallResultCard].
  const StudentOverallResultCard({
    super.key,
    required this.result,
    required this.studentName,
    this.onTap,
  });

  /// The overall result entity.
  final StudentOverallResultEntity result;

  /// Display name of the student.
  final String studentName;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (result.isPromoted ?? false)
              ? Colors.green.shade400
              : colorScheme.outlineVariant,
          width: (result.isPromoted ?? false) ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Student name + Grade + Trend ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      studentName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (result.overallGrade != null)
                    GradeBadge(
                      grade: result.overallGrade!,
                      isPassing: result.subjectsFailed == 0,
                    ),
                  const Gap(8),
                  PerformanceTrendIndicator(trend: result.performanceTrend, showLabel: false),
                ],
              ),
              const Gap(12),

              // ── Big percentage ──
              Text(
                '${result.overallPercentage.toStringAsFixed(1)}%',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: result.subjectsFailed == 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              const Gap(4),

              // ── Position ──
              Text(
                'Position: ${result.positionLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(8),

              // ── Pass/Fail breakdown ──
              Row(
                children: [
                  _PassFailDot(color: Colors.green, count: result.subjectsPassed, label: 'Passed'),
                  const Gap(16),
                  _PassFailDot(color: Colors.red, count: result.subjectsFailed, label: 'Failed'),
                ],
              ),

              // ── Promotion badge ──
              if (result.isPromoted != null) ...[
                const Gap(10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isPromoted!
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: result.isPromoted!
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    result.isPromoted! ? 'Promoted' : 'Not Promoted',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: result.isPromoted!
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PassFailDot extends StatelessWidget {
  const _PassFailDot({
    required this.color,
    required this.count,
    required this.label,
  });

  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 15. BONUS — GRADE DISTRIBUTION PIE CHART PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════

/// A single segment for [GradeDistributionBar].
class GradeSegment {
  /// Creates a [GradeSegment].
  const GradeSegment({
    required this.grade,
    required this.count,
    required this.color,
  });

  /// The grade label.
  final String grade;

  /// Number of students with this grade.
  final int count;

  /// Segment colour.
  final Color color;
}

/// A horizontal stacked bar showing grade distribution.
///
/// ```dart
/// GradeDistributionBar(
///   segments: [
///     GradeSegment(grade: 'A', count: 5, color: Colors.green),
///     GradeSegment(grade: 'B', count: 10, color: Colors.teal),
///     GradeSegment(grade: 'C', count: 8, color: Colors.amber),
///     GradeSegment(grade: 'F', count: 2, color: Colors.red),
///   ],
/// )
/// ```
class GradeDistributionBar extends StatelessWidget {
  /// Creates a [GradeDistributionBar].
  const GradeDistributionBar({
    super.key,
    required this.segments,
    this.height = 24,
    this.borderRadius = 6,
  });

  /// The grade segments to display.
  final List<GradeSegment> segments;

  /// Height of the bar.
  final double height;

  /// Border radius of the bar.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.count);

    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
    }

    return Column(
      children: [
        // ── Stacked bar ──
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            height: height,
            child: Row(
              children: segments.map((seg) {
                final fraction = seg.count / total;
                return Expanded(
                  flex: (fraction * 1000).round().clamp(1, 1000),
                  child: Container(color: seg.color),
                );
              }).toList(),
            ),
          ),
        ),

        const Gap(8),

        // ── Legend ──
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: segments.map((seg) {
            final pct = total > 0 ? (seg.count / total * 100).toStringAsFixed(0) : '0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(4),
                Text(
                  '${seg.grade}: ${seg.count} ($pct%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
