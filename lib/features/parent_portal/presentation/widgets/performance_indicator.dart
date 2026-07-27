import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════════
// PERFORMANCE INDICATOR
// ═══════════════════════════════════════════════════════════════════════

/// Circular progress indicator showing academic performance.
///
/// Renders a 270° arc whose colour depends on the score:
/// - Green for scores > 70
/// - Amber for scores 50–70
/// - Red for scores < 50
///
/// The score is displayed as large bold text in the centre, with an
/// optional [label] beneath it. If [classAverage] is provided, a small
/// indicator mark is drawn on the arc at the corresponding position.
///
/// ```dart
/// PerformanceIndicator(score: 82.5, classAverage: 65.0)
/// PerformanceIndicator(score: 45.0, label: 'Maths')
/// ```
class PerformanceIndicator extends StatelessWidget {
  const PerformanceIndicator({
    super.key,
    required this.score,
    this.classAverage,
    this.size = 120.0,
    this.label,
  });

  /// Score value (0–100).
  final double score;

  /// Optional class average to show as a marker on the arc.
  final double? classAverage;

  /// Diameter of the indicator.
  final double size;

  /// Optional label text below the score.
  final String? label;

  // ─── Score → Colour ───────────────────────────────────────────────

  Color _scoreColor(double s) {
    if (s > 70) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final fgColor = _scoreColor(score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PerformanceArcPainter(
              progress: score.clamp(0.0, 100.0) / 100.0,
              foregroundColor: fgColor,
              backgroundColor: fgColor.withValues(alpha: isDark ? 0.15 : 0.10,
              ),
              classAverageProgress: classAverage != null
                  ? (classAverage!.clamp(0.0, 100.0) / 100.0)
                  : null,
              classAverageColor: cs.onSurfaceVariant,
              strokeWidth: size * 0.09,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.round()}',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: fgColor,
                      height: 1.0,
                    ),
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      label!,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: AppTypography.wMedium,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PERFORMANCE ARC PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _PerformanceArcPainter extends CustomPainter {
  _PerformanceArcPainter({
    required this.progress,
    required this.foregroundColor,
    required this.backgroundColor,
    this.classAverageProgress,
    this.classAverageColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color foregroundColor;
  final Color backgroundColor;
  final double? classAverageProgress;
  final Color? classAverageColor;
  final double strokeWidth;

  /// The arc spans 270 degrees (¾ of a circle), leaving a 90° gap at the
  /// bottom. Start angle is 135° (bottom-left), sweeping clockwise.
  static const double _startAngle = 135.0 * math.pi / 180.0;
  static const double _sweepAngle = 270.0 * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Background Arc ─────────────────────────────────────────────
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, bgPaint);

    // ── Foreground Arc (progress) ──────────────────────────────────
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final progressSweep = _sweepAngle * progress.clamp(0.0, 1.0);
      canvas.drawArc(rect, _startAngle, progressSweep, false, fgPaint);
    }

    // ── Class Average Marker ───────────────────────────────────────
    if (classAverageProgress != null && classAverageColor != null) {
      final markerAngle =
          _startAngle + _sweepAngle * classAverageProgress!.clamp(0.0, 1.0);
      final markerX = center.dx + radius * math.cos(markerAngle);
      final markerY = center.dy + radius * math.sin(markerAngle);
      final markerCenter = Offset(markerX, markerY);

      // Outer ring
      final markerPaint = Paint()
        ..color = classAverageColor!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(markerCenter, strokeWidth * 0.55, markerPaint);

      // Inner white dot
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(markerCenter, strokeWidth * 0.25, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PerformanceArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.classAverageProgress != classAverageProgress;
  }
}
