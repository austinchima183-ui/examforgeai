import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';

// ═══════════════════════════════════════════════════════════════════════
// LEARNING STREAK BADGE
// ═══════════════════════════════════════════════════════════════════════

/// A circular badge showing the student's current learning streak.
///
/// Displays a fire icon with the streak count. High streaks (>7 days)
/// get an animated glow effect. Active streaks use an orange/red gradient;
/// zero streaks show gray.
///
/// ```dart
/// LearningStreakBadge(streak: 12)
/// LearningStreakBadge(streak: 0)
/// ```
class LearningStreakBadge extends StatefulWidget {
  const LearningStreakBadge({
    super.key,
    required this.streak,
    this.size = 64.0,
  });

  /// Current streak count in days.
  final int streak;

  /// Diameter of the circular badge.
  final double size;

  @override
  State<LearningStreakBadge> createState() => _LearningStreakBadgeState();
}

class _LearningStreakBadgeState extends State<LearningStreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _updateGlow();
  }

  @override
  void didUpdateWidget(covariant LearningStreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateGlow();
  }

  void _updateGlow() {
    if (widget.streak > 7) {
      _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
      _glowController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  bool get _isActive => widget.streak > 0;
  bool get _isHighStreak => widget.streak > 7;

  Color _streakColor() {
    if (!_isActive) return Colors.grey;
    if (widget.streak > 14) return const Color(0xFFDC2626); // Red
    if (widget.streak > 7) return const Color(0xFFEA580C); // Deep orange
    return const Color(0xFFF97316); // Orange
  }

  List<Color> _gradientColors() {
    if (!_isActive) return [Colors.grey.shade400, Colors.grey.shade600];
    return [const Color(0xFFF97316), const Color(0xFFDC2626)]; // Orange→Red
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final size = widget.size;
    final streakColor = _streakColor();
    final gradientColors = _gradientColors();

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowRadius = _isHighStreak
            ? 8.0 + 6.0 * math.sin(_glowController.value * math.pi)
            : 0.0;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                : null,
            color: _isActive ? null : Colors.grey.shade300,
            boxShadow: _isHighStreak
                ? [
                    BoxShadow(
                      color: streakColor.withValues(alpha: 0.4 + 0.3 * _glowController.value),
                      blurRadius: glowRadius,
                      spreadRadius: 2.0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: size * 0.30,
                color: _isActive ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(height: 1),
              Text(
                '${widget.streak}',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: _isActive ? Colors.white : Colors.grey.shade600,
                  fontSize: size * 0.19,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
