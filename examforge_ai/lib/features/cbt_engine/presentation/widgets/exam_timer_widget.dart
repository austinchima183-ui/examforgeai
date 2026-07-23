import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TIMER WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// A countdown timer display for exam-taking with warning states, pulsing
/// animation when critical, compact/full modes, and paused indicator.
///
/// **Warning zone**: < 5 minutes → amber.
/// **Critical zone**: < 1 minute → red with pulsing animation.
class ExamTimerWidget extends StatefulWidget {
  const ExamTimerWidget({
    super.key,
    required this.timeRemaining,
    this.totalDuration = Duration.zero,
    this.isPaused = false,
    this.compact = false,
    this.onTap,
  });

  /// Time remaining in the exam.
  final Duration timeRemaining;

  /// Total duration of the exam (for progress bar in full mode).
  final Duration totalDuration;

  /// Whether the exam is currently paused.
  final bool isPaused;

  /// When true, shows only the countdown text (no progress bar).
  final bool compact;

  /// Optional tap handler (e.g., to show time details).
  final VoidCallback? onTap;

  @override
  State<ExamTimerWidget> createState() => _ExamTimerWidgetState();
}

class _ExamTimerWidgetState extends State<ExamTimerWidget>
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
  void didUpdateWidget(covariant ExamTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    if (_isCritical && !widget.isPaused) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  bool get _isWarning =>
      widget.timeRemaining.inMinutes <= 5 &&
      widget.timeRemaining.inSeconds > 0;

  bool get _isCritical =>
      widget.timeRemaining.inMinutes < 1 &&
      widget.timeRemaining.inSeconds > 0;

  bool get _isTimeUp => widget.timeRemaining.inSeconds <= 0;

  Color _timerColor(BuildContext context) {
    if (_isTimeUp) return AppColors.errorOf(context.colorScheme.brightness);
    if (_isCritical) return AppColors.errorOf(context.colorScheme.brightness);
    if (_isWarning) return AppColors.warningOf(context.colorScheme.brightness);
    return context.colorScheme.onSurface;
  }

  Color _timerBgColor(BuildContext context) {
    if (_isTimeUp) {
      return AppColors.errorOf(context.colorScheme.brightness)
          .withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
    }
    if (_isCritical) {
      return AppColors.errorOf(context.colorScheme.brightness)
          .withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
    }
    if (_isWarning) {
      return AppColors.warningOf(context.colorScheme.brightness)
          .withValues(alpha: context.isDarkMode ? 0.20 : 0.10);
    }
    return context.colorScheme.surfaceContainerHighest;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  double get _progress {
    if (widget.totalDuration.inSeconds <= 0) return 0.0;
    final remaining = widget.timeRemaining.inSeconds;
    final total = widget.totalDuration.inSeconds;
    return (remaining / total).clamp(0.0, 1.0);
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
    final bgColor = _timerBgColor(context);

    if (widget.compact) {
      return _buildCompact(context, tt, timerColor, bgColor);
    }
    return _buildFull(context, cs, tt, timerColor, bgColor);
  }

  Widget _buildCompact(
    BuildContext context,
    TextTheme tt,
    Color timerColor,
    Color bgColor,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = _isCritical && !widget.isPaused
            ? 1.0 + 0.05 * math.sin(_pulseController.value * math.pi)
            : 1.0;
        final opacity =
            _isCritical && !widget.isPaused ? 0.7 + 0.3 * _pulseController.value : 1.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isTimeUp
                          ? Icons.timer_off_rounded
                          : widget.isPaused
                              ? Icons.pause_circle_rounded
                              : Icons.timer_rounded,
                      size: Spacings.mdIcon,
                      color: timerColor,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      _isTimeUp ? '00:00:00' : _formatDuration(widget.timeRemaining),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        fontFamily: 'monospace',
                        color: timerColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFull(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Color timerColor,
    Color bgColor,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = _isCritical && !widget.isPaused
            ? 1.0 + 0.03 * math.sin(_pulseController.value * math.pi)
            : 1.0;
        final opacity =
            _isCritical && !widget.isPaused ? 0.7 + 0.3 * _pulseController.value : 1.0;

        return GestureDetector(
          onTap: widget.onTap,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(Spacings.mdRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Paused indicator
                    if (widget.isPaused) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pause_circle_rounded,
                            size: Spacings.smIcon,
                            color: AppColors.warningOf(cs.brightness),
                          ),
                          const SizedBox(width: Spacings.xs),
                          Text(
                            'PAUSED',
                            style: tt.labelSmall?.copyWith(
                              fontWeight: AppTypography.wBold,
                              color: AppColors.warningOf(cs.brightness),
                              letterSpacing: AppTypography.lsLabel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                    ],

                    // Timer icon
                    Icon(
                      _isTimeUp
                          ? Icons.timer_off_rounded
                          : Icons.timer_rounded,
                      size: Spacings.lgIcon,
                      color: timerColor,
                    ),
                    const SizedBox(height: Spacings.sm),

                    // Large countdown text
                    Text(
                      _isTimeUp ? '00:00:00' : _formatDuration(widget.timeRemaining),
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        fontFamily: 'monospace',
                        color: timerColor,
                        letterSpacing: 2.0,
                      ),
                    ),

                    // Progress bar
                    if (widget.totalDuration > Duration.zero) ...[
                      const SizedBox(height: Spacings.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 4.0,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: timerColor,
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                      ),
                    ],

                    // Warning labels
                    if (_isCritical && !widget.isPaused) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'LESS THAN 1 MINUTE',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: timerColor,
                          letterSpacing: AppTypography.lsLabel,
                        ),
                      ),
                    ] else if (_isWarning && !widget.isPaused) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'LESS THAN 5 MINUTES',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: timerColor,
                          letterSpacing: AppTypography.lsLabel,
                        ),
                      ),
                    ] else if (_isTimeUp) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'TIME IS UP',
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
          ),
        );
      },
    );
  }
}
