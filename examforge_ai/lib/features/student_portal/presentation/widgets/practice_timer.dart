import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE TIMER
// ═══════════════════════════════════════════════════════════════════════

/// Timer display widget for timed practice sessions.
///
/// Shows remaining time in MM:SS format with animated countdown. Color
/// changes from green → amber → red as time decreases. A pulsing animation
/// triggers when less than 60 seconds remain.
///
/// ```dart
/// PracticeTimer(remaining: Duration(minutes: 5), isActive: true)
/// PracticeTimer(remaining: Duration(seconds: 30), isActive: true)
/// ```
class PracticeTimer extends StatefulWidget {
  const PracticeTimer({
    super.key,
    required this.remaining,
    this.isActive = true,
  });

  /// Remaining time in the practice session.
  final Duration remaining;

  /// Whether the timer is actively counting down.
  final bool isActive;

  @override
  State<PracticeTimer> createState() => _PracticeTimerState();
}

class _PracticeTimerState extends State<PracticeTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant PracticeTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    if (_isUrgent && widget.isActive) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  bool get _isUrgent =>
      widget.remaining.inSeconds < 60 && widget.remaining.inSeconds > 0;

  bool get _isWarning =>
      widget.remaining.inMinutes < 5 &&
      widget.remaining.inSeconds >= 60;

  bool get _isTimeUp => widget.remaining.inSeconds <= 0;

  Color _timerColor(BuildContext context) {
    if (_isTimeUp) return AppColors.errorOf(context.colorScheme.brightness);
    if (_isUrgent) return AppColors.errorOf(context.colorScheme.brightness);
    if (_isWarning) return AppColors.warningOf(context.colorScheme.brightness);
    return AppColors.successOf(context.colorScheme.brightness);
  }

  Color _bgColor(BuildContext context) {
    final color = _timerColor(context);
    return color.withOpacity(context.isDarkMode ? 0.20 : 0.10);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final timerColor = _timerColor(context);
    final bgColor = _bgColor(context);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = _isUrgent && widget.isActive
            ? 1.0 + 0.04 * math.sin(_pulseController.value * math.pi)
            : 1.0;
        final opacity = _isUrgent && widget.isActive
            ? 0.7 + 0.3 * _pulseController.value
            : 1.0;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isTimeUp
                        ? Icons.timer_off_rounded
                        : !widget.isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.timer_rounded,
                    size: Spacings.lgIcon,
                    color: timerColor,
                  ),
                  const SizedBox(width: Spacings.md),
                  Text(
                    _isTimeUp ? '00:00' : _formatDuration(widget.remaining),
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      fontFamily: 'monospace',
                      color: timerColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if (!widget.isActive && !_isTimeUp) ...[
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningOf(cs.brightness)
                            .withOpacity(context.isDarkMode ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        'PAUSED',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: AppColors.warningOf(cs.brightness),
                          letterSpacing: AppTypography.lsLabel,
                        ),
                      ),
                    ),
                  ],
                  if (_isUrgent && widget.isActive) ...[
                    const SizedBox(width: Spacings.sm),
                    Text(
                      'HURRY!',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: timerColor,
                        letterSpacing: AppTypography.lsLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
