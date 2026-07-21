import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';

// ─── AppLoadingSpinner ────────────────────────────────────────────────────────

/// A circular progress indicator with configurable size and colour.
///
/// ```dart
/// AppLoadingSpinner(size: AppLoadingSpinnerSize.large)
/// ```
class AppLoadingSpinner extends StatelessWidget {
  const AppLoadingSpinner({
    super.key,
    this.size = AppLoadingSpinnerSize.medium,
    this.color,
    this.strokeWidth,
  });

  /// Predefined size presets.
  final AppLoadingSpinnerSize size;

  /// Optional colour override.
  final Color? color;

  /// Optional stroke width override.
  final double? strokeWidth;

  double _dimension() {
    switch (size) {
      case AppLoadingSpinnerSize.small:
        return 20.0;
      case AppLoadingSpinnerSize.medium:
        return 36.0;
      case AppLoadingSpinnerSize.large:
        return 56.0;
    }
  }

  double _stroke() {
    if (strokeWidth != null) return strokeWidth!;
    switch (size) {
      case AppLoadingSpinnerSize.small:
        return 2.0;
      case AppLoadingSpinnerSize.medium:
        return 3.0;
      case AppLoadingSpinnerSize.large:
        return 4.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dimension(),
      height: _dimension(),
      child: CircularProgressIndicator(
        strokeWidth: _stroke(),
        color: color ?? context.colorScheme.primary,
      ),
    );
  }
}

/// Size presets for [AppLoadingSpinner].
enum AppLoadingSpinnerSize { small, medium, large }

// ─── AppLoadingOverlay ────────────────────────────────────────────────────────

/// A full-screen semi-transparent loading overlay with an optional message.
///
/// ```dart
/// Stack(
///   children: [
///     MyContent(),
///     if (isLoading) AppLoadingOverlay(message: 'Saving…'),
///   ],
/// )
/// ```
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.isDismissible = false,
    this.onDismiss,
  });

  /// Optional message displayed below the spinner.
  final String? message;

  /// Whether tapping the overlay dismisses it.
  final bool isDismissible;

  /// Callback when the overlay is dismissed by tap.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Semantics(
      label: message ?? 'Loading',
      busy: true,
      child: GestureDetector(
      onTap: isDismissible ? onDismiss : null,
      child: Container(
        constraints: const BoxConstraints.expand(),
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Card(
            elevation: Spacings.elevationLg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.xl,
                vertical: Spacings.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: AppLoadingSpinner(
                      size: AppLoadingSpinnerSize.large,
                      color: cs.primary,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: Spacings.lg),
                    Text(
                      message!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ─── AppLoadingShimmer ────────────────────────────────────────────────────────

/// A shimmer loading effect that animates a highlight sweep across its child
/// or a default placeholder box.
///
/// ```dart
/// AppLoadingShimmer(
///   child: Row(
///     children: [
///       AppLoadingShimmer.box(width: 48, height: 48, shape: BoxShape.circle),
///       SizedBox(width: 12),
///       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
///         AppLoadingShimmer.box(width: 160, height: 14),
///         SizedBox(height: 8),
///         AppLoadingShimmer.box(width: 120, height: 12),
///       ]),
///     ],
///   ),
/// )
/// ```
class AppLoadingShimmer extends StatefulWidget {
  const AppLoadingShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  })  : _isBox = false,
        width = double.infinity,
        height = 16.0,
        shape = BoxShape.rectangle,
        borderRadius = null;

  /// Convenience constructor for a single shimmer placeholder box.
  const AppLoadingShimmer.box({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  })  : child = const SizedBox.shrink(),
        _isBox = true;

  /// The widget tree to apply the shimmer effect to.
  final Widget child;

  /// Base (background) colour of the shimmer.
  final Color? baseColor;

  /// Highlight sweep colour.
  final Color? highlightColor;

  /// Animation cycle duration.
  final Duration duration;

  /// Box-mode properties
  final double width;
  final double height;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final bool _isBox;

  @override
  State<AppLoadingShimmer> createState() => _AppLoadingShimmerState();
}

class _AppLoadingShimmerState extends State<AppLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AppLoadingShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _buildGradient(Color base, Color highlight) {
    final slidePercent = _controller.value;
    return LinearGradient(
      colors: [base, highlight, base],
      stops: const [0.0, 0.5, 1.0],
      begin: Alignment(-1.0 + (slidePercent * 3.0), 0),
      end: Alignment(1.0 + (slidePercent * 3.0), 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF303030) : const Color(0xFFE0E0E0));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF424242) : const Color(0xFFF5F5F5));

    if (widget._isBox) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: _buildGradient(base, highlight),
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.rectangle
                  ? widget.borderRadius ?? Spacings.borderRadiusSm
                  : null,
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return _buildGradient(base, highlight).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// ─── AppLoadingBar ────────────────────────────────────────────────────────────

/// A linear progress bar with optional indeterminate mode and value display.
///
/// ```dart
/// AppLoadingBar(value: 0.6)   // determinate
/// AppLoadingBar()              // indeterminate
/// ```
class AppLoadingBar extends StatelessWidget {
  const AppLoadingBar({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.borderRadius,
  });

  /// Progress value `0.0`–`1.0`. `null` → indeterminate.
  final double? value;

  /// Bar colour override.
  final Color? color;

  /// Background track colour override.
  final Color? backgroundColor;

  /// Height of the bar.
  final double height;

  /// Border radius of the bar.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final br = borderRadius ?? Spacings.smRadius;

    if (value != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(br),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: backgroundColor ?? cs.surfaceContainerHighest,
          color: color ?? cs.primary,
          borderRadius: BorderRadius.circular(br),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(br),
      child: LinearProgressIndicator(
        minHeight: height,
        backgroundColor: backgroundColor ?? cs.surfaceContainerHighest,
        color: color ?? cs.primary,
        borderRadius: BorderRadius.circular(br),
      ),
    );
  }
}

// ─── AppLoadingDot ────────────────────────────────────────────────────────────

/// An animated dot loading indicator with three pulsing dots.
///
/// ```dart
/// AppLoadingDot()
/// ```
class AppLoadingDot extends StatefulWidget {
  const AppLoadingDot({
    super.key,
    this.color,
    this.size = 8.0,
    this.spacing = 6.0,
    this.duration = const Duration(milliseconds: 1200),
  });

  /// Dot colour override.
  final Color? color;

  /// Diameter of each dot.
  final double size;

  /// Space between dots.
  final double spacing;

  /// Full animation cycle duration.
  final Duration duration;

  @override
  State<AppLoadingDot> createState() => _AppLoadingDotState();
}

class _AppLoadingDotState extends State<AppLoadingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? context.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Stagger each dot's animation by 0.2 offset
            final rawValue = (_controller.value - index * 0.2) % 1.0;
            // Sine wave for smooth pulse: scale 0.5 → 1.0
            final scale = 0.5 + 0.5 * (0.5 + 0.5 * math.sin(rawValue * 2 * math.pi));
            final opacity = 0.4 + 0.6 * scale;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
