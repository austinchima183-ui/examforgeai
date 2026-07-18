import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDY PROGRESS RING
// ═══════════════════════════════════════════════════════════════════════

/// Circular progress ring for study plan/goal progress.
///
/// Displays an animated circular progress indicator with a percentage in
/// the center and a label below. The color changes based on progress:
/// - Red when progress < 30%
/// - Amber when progress < 70%
/// - Green when progress >= 70%
///
/// ```dart
/// StudyProgressRing(progress: 75.0, label: 'Weekly Goal')
/// StudyProgressRing(progress: 20.0, label: 'Study Plan')
/// ```
class StudyProgressRing extends StatefulWidget {
  const StudyProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 120.0,
    this.strokeWidth = 10.0,
  });

  /// Progress value from 0 to 100.
  final double progress;

  /// Descriptive label shown below the ring.
  final String label;

  /// Diameter of the ring.
  final double size;

  /// Thickness of the progress ring stroke.
  final double strokeWidth;

  @override
  State<StudyProgressRing> createState() => _StudyProgressRingState();
}

class _StudyProgressRingState extends State<StudyProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant StudyProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
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

  Color _progressColor(double value) {
    if (value < 30) return AppColors.error;
    if (value < 70) return AppColors.warning;
    return AppColors.success;
  }

  Color _progressBgColor(BuildContext context, Color fgColor) {
    return fgColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              final currentValue = _progressAnimation.value;
              final fgColor = _progressColor(currentValue);
              final bgColor = _progressBgColor(context, fgColor);

              return CustomPaint(
                painter: _ProgressRingPainter(
                  progress: currentValue / 100.0,
                  foregroundColor: fgColor,
                  backgroundColor: bgColor,
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Text(
                    '${currentValue.round()}%',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: fgColor,
                      height: 1.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          widget.label,
          style: tt.labelMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROGRESS RING PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
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
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
