import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Streak tracking badge with fire icon.
///
/// Displays a circular badge with a fire icon and streak count.
/// The badge animates with a glow effect for high streaks (>7 days).
///
/// Visual states:
/// - Zero streak: Gray badge
/// - 1-7 day streak: Orange gradient, no glow
/// - 8-14 day streak: Deep orange gradient, animated glow
/// - 15+ day streak: Red gradient, intense animated glow
///
/// ```dart
/// StudyStreakBadge(streak: 12, label: 'Current Streak')
/// StudyStreakBadge(streak: 0, size: 48)
/// ```
class StudyStreakBadge extends StatefulWidget {
  const StudyStreakBadge({
    super.key,
    required this.streak,
    this.label,
    this.size = 72.0,
  });

  /// Current streak count in days.
  final int streak;

  /// Optional label below the badge.
  final String? label;

  /// Diameter of the circular badge.
  final double size;

  @override
  State<StudyStreakBadge> createState() => _StudyStreakBadgeState();
}

class _StudyStreakBadgeState extends State<StudyStreakBadge>
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
  void didUpdateWidget(covariant StudyStreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streak != widget.streak) {
      _updateGlow();
    }
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
  bool get _isExtremeStreak => widget.streak > 14;

  Color _streakColor() {
    if (!_isActive) return Colors.grey;
    if (_isExtremeStreak) return const Color(0xFFDC2626); // Red
    if (_isHighStreak) return const Color(0xFFEA580C); // Deep orange
    return const Color(0xFFF97316); // Orange
  }

  List<Color> _gradientColors() {
    if (!_isActive) return [Colors.grey.shade400, Colors.grey.shade600];
    if (_isExtremeStreak) {
      return [const Color(0xFFEF4444), const Color(0xFF991B1B)]; // Red→Dark red
    }
    if (_isHighStreak) {
      return [const Color(0xFFF97316), const Color(0xFFDC2626)]; // Orange→Red
    }
    return [const Color(0xFFFBBF24), const Color(0xFFF97316)]; // Amber→Orange
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final size = widget.size;
    final streakColor = _streakColor();
    final gradientColors = _gradientColors();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
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
                          color: streakColor.withOpacity(0.4 + 0.3 * _glowController.value,
                          ),
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
                    size: size * 0.28,
                    color: _isActive ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.streak}',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: _isActive ? Colors.white : Colors.grey.shade600,
                      fontSize: size * 0.17,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: Spacings.xs),
          Text(
            widget.label!,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wMedium,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
