import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCORE CIRCLE
// ═══════════════════════════════════════════════════════════════════════

/// Large score display circle with animated progress.
///
/// Shows a score as a percentage or fraction inside an animated circular
/// indicator. Color is based on score:
/// - Red when score < 40%
/// - Amber when score < 70%
/// - Green when score >= 70%
///
/// ```dart
/// ScoreCircle(score: 85.0, maxScore: 100.0)
/// ScoreCircle(score: 45.0)
/// ```
class ScoreCircle extends StatefulWidget {
  const ScoreCircle({
    super.key,
    required this.score,
    this.maxScore,
    this.size = 160.0,
    this.strokeWidth = 14.0,
    this.subtitle,
  });

  /// The achieved score (0-100 when [maxScore] is null, or raw score otherwise).
  final double score;

  /// Optional maximum score. When provided, displays as fraction "score/maxScore".
  final double? maxScore;

  /// Diameter of the score circle.
  final double size;

  /// Thickness of the progress stroke.
  final double strokeWidth;

  /// Optional subtitle text below the score.
  final String? subtitle;

  @override
  State<ScoreCircle> createState() => _ScoreCircleState();
}

class _ScoreCircleState extends State<ScoreCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;

  double get _percentage {
    if (widget.maxScore != null && widget.maxScore! > 0) {
      return (widget.score / widget.maxScore!) * 100;
    }
    return widget.score.clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: _percentage).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant ScoreCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPct = _percentage;
    final oldPct = oldWidget.maxScore != null && oldWidget.maxScore! > 0
        ? (oldWidget.score / oldWidget.maxScore!) * 100
        : oldWidget.score.clamp(0.0, 100.0);
    if (oldPct != newPct) {
      _scoreAnimation = Tween<double>(begin: oldPct, end: newPct).animate(
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

  Color _scoreColor(double pct) {
    if (pct < 40) return AppColors.error;
    if (pct < 70) return AppColors.warning;
    return AppColors.success;
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
            animation: _scoreAnimation,
            builder: (context, _) {
              final currentPct = _scoreAnimation.value;
              final fgColor = _scoreColor(currentPct);

              return CustomPaint(
                painter: _ScoreRingPainter(
                  progress: currentPct / 100.0,
                  foregroundColor: fgColor,
                  backgroundColor: fgColor.withOpacity(context.isDarkMode ? 0.15 : 0.08,
                  ),
                  strokeWidth: widget.strokeWidth,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.maxScore != null)
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${widget.score.round()}',
                                style: tt.headlineMedium?.copyWith(
                                  fontWeight: AppTypography.wBold,
                                  color: fgColor,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: '/${widget.maxScore!.round()}',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: cs.onSurfaceVariant,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          '${currentPct.round()}%',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: fgColor,
                            height: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: Spacings.sm),
          Text(
            widget.subtitle!,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: AppTypography.wMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SCORE RING PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
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

      const startAngle = -math.pi / 2;
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
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
