import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';

/// Circular progress indicator for readiness score.
///
/// Displays an animated circular progress ring with the readiness score
/// percentage in the center, the readiness level label below, and
/// color-coding based on the readiness level.
///
/// Color mapping:
/// - Exam Ready (≥90): Green
/// - Advanced (≥75): Blue
/// - Proficient (≥60): Cyan
/// - Developing (≥40): Amber/Warning
/// - Beginning (≥20): Orange
/// - Not Started (<20): Red
///
/// ```dart
/// ReadinessScoreRing(score: 72.5, level: ReadinessLevel.proficient)
/// ReadinessScoreRing(score: 95.0, level: ReadinessLevel.examReady, size: 160)
/// ```
class ReadinessScoreRing extends StatefulWidget {
  const ReadinessScoreRing({
    super.key,
    required this.score,
    required this.level,
    this.size = 120.0,
    this.strokeWidth = 10.0,
    this.label,
  });

  /// Readiness score from 0 to 100.
  final double score;

  /// The readiness level for color coding and labeling.
  final ReadinessLevel level;

  /// Diameter of the ring.
  final double size;

  /// Thickness of the progress ring stroke.
  final double strokeWidth;

  /// Optional custom label below the ring. If null, the level label is used.
  final String? label;

  @override
  State<ReadinessScoreRing> createState() => _ReadinessScoreRingState();
}

class _ReadinessScoreRingState extends State<ReadinessScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant ReadinessScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score ||
        oldWidget.level != widget.level) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _levelColor() {
    switch (widget.level) {
      case ReadinessLevel.examReady:
        return AppColors.success;
      case ReadinessLevel.advanced:
        return AppColors.info;
      case ReadinessLevel.proficient:
        return const Color(0xFF06B6D4); // Cyan
      case ReadinessLevel.developing:
        return AppColors.warning;
      case ReadinessLevel.beginning:
        return const Color(0xFFEA580C); // Deep orange
      case ReadinessLevel.notStarted:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final fgColor = _levelColor();
    final bgColor = fgColor.withOpacity(context.isDarkMode ? 0.20 : 0.10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, _) {
              final currentValue = _scoreAnimation.value;

              return CustomPaint(
                painter: _ReadinessRingPainter(
                  progress: currentValue / 100.0,
                  foregroundColor: fgColor,
                  backgroundColor: bgColor,
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${currentValue.round()}%',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: fgColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.level.label,
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: fgColor.withOpacity(0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: Spacings.sm),
          Text(
            widget.label!,
            style: tt.labelMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// READINESS RING PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _ReadinessRingPainter extends CustomPainter {
  _ReadinessRingPainter({
    required this.progress,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color foregroundColor;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = foregroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReadinessRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
