import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';
import 'app_button.dart';

// ─── AppErrorState ────────────────────────────────────────────────────────────

/// A reusable error-state widget displaying an icon, title, message, and
/// optional retry button. Pre-built variants are provided for common error
/// scenarios.
///
/// Includes a subtle fade + slide animation on appearance.
///
/// ```dart
/// AppErrorState(
///   icon: Icons.cloud_off_rounded,
///   title: 'Server Error',
///   message: 'Something went wrong on our end.',
///   onRetry: () => refetch(),
/// )
/// ```
class AppErrorState extends StatefulWidget {
  const AppErrorState({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.onRetry,
    this.showRetry = true,
  });

  /// Leading icon displayed above the title.
  final IconData? icon;

  /// Primary title text.
  final String? title;

  /// Detailed error message.
  final String? message;

  /// Retry callback. When provided and [showRetry] is `true`, a retry button
  /// is displayed.
  final VoidCallback? onRetry;

  /// Whether to show the retry button when [onRetry] is provided.
  final bool showRetry;

  // ─── Pre-built Variants ─────────────────────────────────────────────

  /// Network / connectivity error.
  static AppErrorState networkError({VoidCallback? onRetry}) {
    return AppErrorState(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      message: 'Please check your network settings and try again.',
      onRetry: onRetry,
    );
  }

  /// Server-side error (5xx).
  static AppErrorState serverError({VoidCallback? onRetry}) {
    return AppErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Server Error',
      message: 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }

  /// 404 / not-found error.
  static AppErrorState notFoundError({VoidCallback? onRetry}) {
    return AppErrorState(
      icon: Icons.error_outline_rounded,
      title: 'Not Found',
      message: 'The resource you are looking for does not exist.',
      onRetry: onRetry,
    );
  }

  /// Authentication / authorisation error.
  static AppErrorState authError({VoidCallback? onRetry}) {
    return AppErrorState(
      icon: Icons.lock_outline_rounded,
      title: 'Access Denied',
      message: 'You do not have permission to view this content.',
      onRetry: onRetry,
    );
  }

  /// Generic / unknown error.
  static AppErrorState genericError({
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorState(
      icon: Icons.error_outline_rounded,
      title: 'Something Went Wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      onRetry: onRetry,
    );
  }

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ),);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;
    final iconSize = isMobile ? Spacings.xlIcon : 64.0;

    return Semantics(
      liveRegion: true,
      label: '${widget.title ?? 'Error'}${widget.message != null ? '. ${widget.message}' : ''}',
      child: FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.xl,
            vertical: Spacings.xxl,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon (decorative — excluded from semantics)
                if (widget.icon != null)
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(Spacings.lg),
                      decoration: BoxDecoration(
                        color: AppColors.errorOf(cs.brightness).withValues(alpha: context.isDarkMode ? 0.20 : 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: iconSize * 0.6,
                        color: AppColors.errorOf(cs.brightness),
                      ),
                    ),
                  ),

                const SizedBox(height: Spacings.xl),

                // Title
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),

                // Message
                if (widget.message != null) ...[
                  const SizedBox(height: Spacings.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      widget.message!,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Retry button
                if (widget.showRetry && widget.onRetry != null) ...[
                  const SizedBox(height: Spacings.xl),
                  AppButton(
                    label: 'Try Again',
                    onPressed: widget.onRetry,
                    variant: AppButtonVariant.tonal,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
