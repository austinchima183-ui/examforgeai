import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';

// ─── Onboarding Data Model ───────────────────────────────────────────────────

/// Data model for a single onboarding slide.
class OnboardingData {
  const OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  /// The main icon for the slide.
  final IconData icon;

  /// The slide title.
  final String title;

  /// The slide description.
  final String description;

  /// Background gradient for the illustration area.
  final LinearGradient gradient;
}

// ─── Onboarding Slide Widget ─────────────────────────────────────────────────

/// An individual onboarding slide widget with an animated entrance,
/// gradient illustration area, icon, title, and description.
///
/// ```dart
/// OnboardingSlide(
///   data: OnboardingData(
///     icon: Icons.auto_awesome,
///     title: 'AI-Powered',
///     description: 'Create questions with AI',
///     gradient: AppColors.brandGradient,
///   ),
///   isActive: true,
/// )
/// ```
class OnboardingSlide extends StatefulWidget {
  const OnboardingSlide({
    super.key,
    required this.data,
    this.isActive = false,
  });

  /// The onboarding data to display.
  final OnboardingData data;

  /// Whether this slide is currently active / visible.
  final bool isActive;

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
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

    // Responsive illustration size
    final illustrationSize = isMobile ? 200.0 : 260.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Illustration Area ────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: illustrationSize,
                  height: illustrationSize,
                  decoration: BoxDecoration(
                    gradient: widget.data.gradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.data.gradient.colors.first
                            .withOpacity(0.3),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: illustrationSize * 0.65,
                      height: illustrationSize * 0.65,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.data.icon,
                        size: illustrationSize * 0.35,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: Spacings.xxxl),

              // ── Title ────────────────────────────────────────────────
              Text(
                widget.data.title,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Spacings.md),

              // ── Description ──────────────────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 300 : 400,
                ),
                child: Text(
                  widget.data.description,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
