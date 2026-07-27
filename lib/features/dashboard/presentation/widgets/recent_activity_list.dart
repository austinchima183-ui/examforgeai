import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../providers/dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// RECENT ACTIVITY LIST
// ═══════════════════════════════════════════════════════════════════════

/// A list of recent activity items with relative timestamps, animated
/// entrance, and a "View all" link.
///
/// ```dart
/// RecentActivityList(
///   activities: dashboardState.recentActivity,
///   onViewAll: () => context.go('/activity'),
/// )
/// ```
class RecentActivityList extends StatefulWidget {
  const RecentActivityList({
    required this.activities,
    this.onViewAll,
    this.maxVisible = 5,
    super.key,
  });

  /// List of activity items to display.
  final List<ActivityItem> activities;

  /// Callback for "View all" link.
  final VoidCallback? onViewAll;

  /// Maximum number of items to show before truncating.
  final int maxVisible;

  @override
  State<RecentActivityList> createState() => _RecentActivityListState();
}

class _RecentActivityListState extends State<RecentActivityList>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  final List<Animation<double>> _itemAnimations = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final visibleCount = widget.activities.length.clamp(0, widget.maxVisible);
    for (int i = 0; i < visibleCount; i++) {
      _itemAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              (i * 0.08).clamp(0.0, 0.7),
              ((i * 0.08) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
    }

    _staggerController.forward();
  }

  @override
  void didUpdateWidget(covariant RecentActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities.length != widget.activities.length) {
      _rebuildAnimations();
    }
  }

  void _rebuildAnimations() {
    _itemAnimations.clear();
    final visibleCount = widget.activities.length.clamp(0, widget.maxVisible);
    for (int i = 0; i < visibleCount; i++) {
      _itemAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              (i * 0.08).clamp(0.0, 0.7),
              ((i * 0.08) + 0.3).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
      );
    }
    _staggerController.reset();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final visible = widget.activities.take(widget.maxVisible).toList();

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
        child: Center(
          child: Text(
            'No recent activity',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Activity Items ──────────────────────────────────────────
        for (int i = 0; i < visible.length; i++)
          _AnimatedActivityTile(
            item: visible[i],
            animation: i < _itemAnimations.length
                ? _itemAnimations[i]
                : const AlwaysStoppedAnimation(1.0),
          ),

        // ── View All Link ──────────────────────────────────────────
        if (widget.onViewAll != null &&
            widget.activities.length > widget.maxVisible)
          Padding(
            padding: const EdgeInsets.only(top: Spacings.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onViewAll,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  'View All',
                  style: tt.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ANIMATED ACTIVITY TILE (private)
// ═══════════════════════════════════════════════════════════════════════

class _AnimatedActivityTile extends StatelessWidget {
  const _AnimatedActivityTile({
    required this.item,
    required this.animation,
  });

  final ActivityItem item;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: _ActivityTile(item: item),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACTIVITY TILE (private)
// ═══════════════════════════════════════════════════════════════════════

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final accentColor = item.color ?? cs.primary;
    final iconBgColor =
        accentColor.withValues(alpha: isDark ? 0.20 : 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs),
      child: ListTile(
        leading: item.icon != null
            ? Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius:
                      BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  item.icon,
                  size: Spacings.mdIcon,
                  color: accentColor,
                ),
              )
            : null,
        title: Text(
          item.title,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: AppTypography.wMedium,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          item.timestamp.timeAgo,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
      ),
    );
  }
}
