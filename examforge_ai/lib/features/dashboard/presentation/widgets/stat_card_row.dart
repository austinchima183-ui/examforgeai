import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../features/analytics_dashboard/domain/entities/analytics_dashboard_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════

/// A single statistic to display in the [StatCardRow].
class StatItem {
  const StatItem({
    required this.title,
    required this.value,
    this.icon,
    this.trend = TrendDirection.neutral,
    this.trendValue,
    this.color,
    this.onTap,
  });

  /// Short descriptive label (e.g. "Total Students").
  final String title;

  /// The primary numeric or text value (e.g. "156").
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Trend direction.
  final TrendDirection trend;

  /// Trend text (e.g. "+12.5%").
  final String? trendValue;

  /// Optional accent colour for icon and trend.
  final Color? color;

  /// Optional tap handler.
  final VoidCallback? onTap;
}

// ═══════════════════════════════════════════════════════════════════════
// STAT CARD ROW
// ═══════════════════════════════════════════════════════════════════════

/// A responsive row of [AppStatCard] widgets with animated count-up
/// numbers and role-aware accent colours.
///
/// - **Mobile** (< 600 px): 2 columns
/// - **Desktop** (≥ 1024 px): 4 columns
/// - **Tablet**: 3 columns
///
/// ```dart
/// StatCardRow(
///   items: [
///     StatItem(title: 'Students', value: '156', icon: Icons.people),
///     StatItem(title: 'Exams', value: '24', icon: Icons.quiz),
///   ],
/// )
/// ```
class StatCardRow extends StatelessWidget {
  const StatCardRow({required this.items, super.key});

  /// List of statistics to display.
  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final crossCount = _crossAxisCount(context);

    return Wrap(
      spacing: Spacings.md,
      runSpacing: Spacings.md,
      children: items.map((item) {
        final width = _cardWidth(context, crossCount);
        return SizedBox(
          width: width,
          child: _AnimatedStatCard(item: item),
        );
      }).toList(),
    );
  }

  int _crossAxisCount(BuildContext context) {
    if (context.isDesktop) return 4;
    if (context.isTablet) return 3;
    return 2;
  }

  double _cardWidth(BuildContext context, int crossCount) {
    final availableWidth = context.width - (Spacings.lg * 2); // screen padding
    final totalSpacing = Spacings.md * (crossCount - 1);
    return (availableWidth - totalSpacing) / crossCount;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ANIMATED STAT CARD (private)
// ═══════════════════════════════════════════════════════════════════════

/// Wraps [AppStatCard] with a fade + slide entrance animation and an
/// optional count-up number animation for numeric values.
class _AnimatedStatCard extends StatefulWidget {
  const _AnimatedStatCard({required this.item});

  final StatItem item;

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _countAnimation = Tween<double>(
      begin: 0,
      end: _parseNumericValue(widget.item.value),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _parseNumericValue(String value) {
    // Strip commas, currency symbols, percent signs, etc.
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  bool _isNumericValue(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) != null;
  }

  String _formatCount(double count) {
    final original = widget.item.value;
    // Preserve formatting style from original value.
    if (original.contains('%')) {
      return '${count.toStringAsFixed(1)}%';
    }
    if (original.contains('\$')) {
      return '\$${_formatNumber(count)}';
    }
    if (original.contains('.')) {
      return count.toStringAsFixed(1);
    }
    return _formatNumber(count);
  }

  String _formatNumber(double n) {
    if (n >= 1000) {
      return n.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AppStatCard(
          title: widget.item.title,
          value: _isNumericValue(widget.item.value)
              ? _formatCount(_countAnimation.value)
              : widget.item.value,
          icon: widget.item.icon,
          trend: widget.item.trend,
          trendValue: widget.item.trendValue,
          color: widget.item.color,
          onTap: widget.item.onTap,
        ),
      ),
    );
  }
}
