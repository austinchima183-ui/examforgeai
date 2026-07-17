import 'package:flutter/material.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════

/// A single quick-action item displayed in the [QuickActionsGrid].
class QuickAction {
  const QuickAction({
    required this.title,
    this.subtitle,
    required this.icon,
    this.route,
    this.onTap,
    this.color,
  });

  /// Primary title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Leading icon.
  final IconData icon;

  /// Navigation route (used when [onTap] is not provided).
  final String? route;

  /// Tap handler. Overrides [route] navigation when provided.
  final VoidCallback? onTap;

  /// Optional accent colour applied to icon and background tint.
  final Color? color;
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK ACTIONS GRID
// ═══════════════════════════════════════════════════════════════════════

/// A responsive grid of quick-action cards using [AppActionCard].
///
/// - **Mobile** (< 600 px): 1 column (full-width list layout)
/// - **Tablet** (600–1023 px): 2 columns
/// - **Desktop** (≥ 1024 px): 4 columns
///
/// ```dart
/// QuickActionsGrid(
///   actions: [
///     QuickAction(title: 'Create Exam', icon: Icons.add, route: '/exams/create'),
///     QuickAction(title: 'Grade', icon: Icons.grading, route: '/grading'),
///   ],
/// )
/// ```
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({required this.actions, super.key});

  /// List of quick actions to display.
  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final crossCount = _crossAxisCount(context);

    return Wrap(
      spacing: Spacings.md,
      runSpacing: Spacings.md,
      children: actions.map((action) {
        final width = _cardWidth(context, crossCount);
        return SizedBox(
          width: width,
          child: _AnimatedActionCard(action: action),
        );
      }).toList(),
    );
  }

  int _crossAxisCount(BuildContext context) {
    if (context.isDesktop) return 4;
    if (context.isTablet) return 2;
    return 1;
  }

  double _cardWidth(BuildContext context, int crossCount) {
    if (crossCount == 1) return double.infinity;
    final availableWidth = context.width - (Spacings.lg * 2);
    final totalSpacing = Spacings.md * (crossCount - 1);
    return (availableWidth - totalSpacing) / crossCount;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ANIMATED ACTION CARD (private)
// ═══════════════════════════════════════════════════════════════════════

/// Wraps [AppActionCard] with a staggered fade + scale entrance animation.
class _AnimatedActionCard extends StatefulWidget {
  const _AnimatedActionCard({required this.action});

  final QuickAction action;

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

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

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.action.onTap != null) {
      widget.action.onTap!();
    }
    // If only a route is provided, we rely on the parent to handle
    // navigation. The action card itself just fires onTap.
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AppActionCard(
          title: widget.action.title,
          subtitle: widget.action.subtitle,
          icon: widget.action.icon,
          color: widget.action.color,
          onTap: _handleTap,
        ),
      ),
    );
  }
}
