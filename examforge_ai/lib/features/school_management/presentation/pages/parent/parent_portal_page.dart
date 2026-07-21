import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/parent_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../features/school_management/domain/entities/school_management_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// PARENT PORTAL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Parent's portal view showing their children overview, announcements,
/// and quick links to Results, Attendance, Homework, and Messages.
class ParentPortalPage extends ConsumerStatefulWidget {
  const ParentPortalPage({super.key});

  @override
  ConsumerState<ParentPortalPage> createState() => _ParentPortalPageState();
}

class _ParentPortalPageState extends ConsumerState<ParentPortalPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(parentListProvider.notifier).loadParents('current-school');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(parentListProvider);

    // For demo, use the first parent. In production, get current user's parent profile.
    final parent = state.parents.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Parent Portal',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to notifications
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: Spacings.xlIcon,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: Spacings.md),
                      Text(
                        state.error!,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacings.md),
                      AppButton(
                        label: 'Retry',
                        onPressed: () => ref
                            .read(parentListProvider.notifier)
                            .loadParents('current-school'),
                        variant: AppButtonVariant.tonal,
                      ),
                    ],
                  ),
                )
              : parent == null
                  ? const AppEmptyState(
                      icon: Icons.family_restroom_outlined,
                      title: 'No Parent Profile',
                      subtitle:
                          'Your parent profile has not been set up yet. Contact the school admin.',
                    )
                  : _buildPortalContent(context, parent),
    );
  }

  Widget _buildPortalContent(BuildContext context, ParentProfileEntity parent) {
    return RefreshIndicator(
      onRefresh: () => ref.read(parentListProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Welcome Section ────────────────────────────────────
            Text(
              'Welcome, ${parent.fullName?.split(' ').firstOrNull ?? 'Parent'}',
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              '${parent.children.length} ${parent.children.length == 1 ? 'child' : 'children'} enrolled',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: Spacings.xxl),

            // ─── Quick Links ────────────────────────────────────────
            Text(
              'Quick Links',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.assessment_outlined,
                    label: 'Results',
                    color: AppColors.info,
                    onTap: () {
                      // Navigate to results
                    },
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.event_available_outlined,
                    label: 'Attendance',
                    color: AppColors.success,
                    onTap: () {
                      // Navigate to attendance
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.assignment_outlined,
                    label: 'Homework',
                    color: AppColors.warning,
                    onTap: () {
                      // Navigate to homework
                    },
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: _QuickLinkCard(
                    icon: Icons.chat_outlined,
                    label: 'Messages',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      // Navigate to messages
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacings.xxl),

            // ─── Children Overview ──────────────────────────────────
            Text(
              'My Children',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: Spacings.md),

            if (parent.children.isEmpty)
              const AppEmptyState(
                icon: Icons.child_care_outlined,
                title: 'No Children Linked',
                subtitle: 'No children are linked to your profile yet.',
              )
            else
              ...parent.children.map((link) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _ChildOverviewCard(
                      link: link,
                      onTap: () {
                        // Navigate to child detail
                      },
                    ),
                  )),

            const SizedBox(height: Spacings.xxl),

            // ─── Announcements ──────────────────────────────────────
            Text(
              'Announcements',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: Spacings.md),
            _AnnouncementCard(
              title: 'Mid-Term Break',
              subtitle: 'School will be closed from March 15-19 for mid-term break.',
              date: 'Mar 10, 2026',
              type: AnnouncementType.holiday,
            ),
            const SizedBox(height: Spacings.md),
            _AnnouncementCard(
              title: 'Parent-Teacher Conference',
              subtitle: 'Scheduled for March 22, 2026. Please attend.',
              date: 'Mar 8, 2026',
              type: AnnouncementType.parentTeacherConference,
            ),
            const SizedBox(height: Spacings.md),
            _AnnouncementCard(
              title: 'Exam Period Starts',
              subtitle: 'End-of-term exams begin April 1, 2026.',
              date: 'Mar 5, 2026',
              type: AnnouncementType.notice,
            ),

            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK LINK CARD
// ═══════════════════════════════════════════════════════════════════════

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(icon, size: Spacings.lgIcon, color: color),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD OVERVIEW CARD
// ═══════════════════════════════════════════════════════════════════════

class _ChildOverviewCard extends StatelessWidget {
  const _ChildOverviewCard({
    required this.link,
    this.onTap,
  });

  final ParentStudentLinkEntity link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: cs.primary,
              size: Spacings.lgIcon,
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.studentName ?? 'Unknown Student',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    if (link.studentAdmissionNumber != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          link.studentAdmissionNumber!,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Placeholder stats
                    _MiniStat(
                      icon: Icons.event_available_rounded,
                      value: '95%',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: Spacings.md),
                    _MiniStat(
                      icon: Icons.quiz_outlined,
                      value: '2',
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                // Upcoming items preview
                Row(
                  children: [
                    Icon(
                      Icons.upcoming_outlined,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Expanded(
                      child: Text(
                        'Math test on Apr 2',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
            size: Spacings.mdIcon,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MINI STAT WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          value,
          style: tt.labelSmall?.copyWith(
            color: color,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT CARD
// ═══════════════════════════════════════════════════════════════════════

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String date;
  final AnnouncementType type;

  Color _typeColor() {
    switch (type) {
      case AnnouncementType.holiday:
        return AppColors.error;
      case AnnouncementType.event:
        return AppColors.info;
      case AnnouncementType.circular:
        return AppColors.warning;
      case AnnouncementType.emergency:
        return AppColors.error;
      case AnnouncementType.notice:
        return AppColors.info;
    }
  }

  IconData _typeIcon() {
    switch (type) {
      case AnnouncementType.holiday:
        return Icons.beach_access_outlined;
      case AnnouncementType.event:
        return Icons.event_outlined;
      case AnnouncementType.circular:
        return Icons.description_outlined;
      case AnnouncementType.emergency:
        return Icons.warning_amber_rounded;
      case AnnouncementType.notice:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = _typeColor();

    return AppCard(
      onTap: () {
        // View announcement detail
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(_typeIcon(), size: Spacings.mdIcon, color: color),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  date,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
