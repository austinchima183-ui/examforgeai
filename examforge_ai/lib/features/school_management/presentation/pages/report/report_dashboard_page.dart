import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/school_management_entities.dart';
import '../providers/report_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// REPORT DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School overview dashboard displaying key statistics and quick-access
/// report cards for Students, Teachers, Attendance, and Academics.
class ReportDashboardPage extends ConsumerStatefulWidget {
  const ReportDashboardPage({super.key});

  @override
  ConsumerState<ReportDashboardPage> createState() =>
      _ReportDashboardPageState();
}

class _ReportDashboardPageState extends ConsumerState<ReportDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportProvider.notifier).loadSchoolOverview('current-school');
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reports',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ReportState state) {
    if (state.isLoading && !state.hasOverview) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && !state.hasOverview) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(reportProvider.notifier).loadSchoolOverview('current-school'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(reportProvider.notifier).loadSchoolOverview('current-school'),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Overview Header ────────────────────────────────────
            Text(
              'School Overview',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.lg),

            // ─── Stats Grid ────────────────────────────────────────
            _buildStatsGrid(context, state),
            const SizedBox(height: Spacings.xxl),

            // ─── Quick Access Reports ──────────────────────────────
            Text(
              'Quick Access Reports',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.lg),
            _buildQuickAccessCards(context),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Stats Grid ────────────────────────────────────────────────────

  Widget _buildStatsGrid(BuildContext context, ReportState state) {
    final overview = state.overview ?? {};

    final stats = <_StatItem>[
      _StatItem(
        title: 'Total Students',
        value: '${overview['totalStudents'] ?? 0}',
        icon: Icons.school_rounded,
        color: AppColors.seed,
      ),
      _StatItem(
        title: 'Total Teachers',
        value: '${overview['totalTeachers'] ?? 0}',
        icon: Icons.person_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _StatItem(
        title: 'Total Classes',
        value: '${overview['totalClasses'] ?? 0}',
        icon: Icons.class_rounded,
        color: AppColors.info,
      ),
      _StatItem(
        title: 'Total Subjects',
        value: '${overview['totalSubjects'] ?? 0}',
        icon: Icons.book_rounded,
        color: const Color(0xFF06B6D4),
      ),
      _StatItem(
        title: 'Active Exams',
        value: '${overview['activeExams'] ?? 0}',
        icon: Icons.quiz_rounded,
        color: AppColors.warning,
      ),
      _StatItem(
        title: 'Attendance Rate',
        value: '${overview['attendanceRate'] ?? '0'}%',
        icon: Icons.how_to_reg_rounded,
        color: AppColors.success,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacings.md,
        crossAxisSpacing: Spacings.md,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return _OverviewStatCard(stat: s);
      },
    );
  }

  // ─── Quick Access Cards ────────────────────────────────────────────

  Widget _buildQuickAccessCards(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final reports = <_QuickAccessItem>[
      _QuickAccessItem(
        title: 'Student List Report',
        subtitle: 'View all students with class, attendance, and scores',
        icon: Icons.people_outline_rounded,
        color: AppColors.seed,
        onTap: () {
          // Navigate to student report page
        },
      ),
      _QuickAccessItem(
        title: 'Teacher List Report',
        subtitle: 'View all teachers, subjects, and class assignments',
        icon: Icons.person_outline_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          // Navigate to teacher report page
        },
      ),
      _QuickAccessItem(
        title: 'Attendance Report',
        subtitle: 'Class-by-class attendance breakdown and trends',
        icon: Icons.calendar_month_outlined,
        color: AppColors.success,
        onTap: () {
          // Navigate to attendance report page
        },
      ),
      _QuickAccessItem(
        title: 'Academic Report',
        subtitle: 'Subject performance, grade distribution, and rankings',
        icon: Icons.bar_chart_rounded,
        color: AppColors.info,
        onTap: () {
          // Navigate to academic report page
        },
      ),
    ];

    return Column(
      children: reports.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: AppCard(
              onTap: r.onTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacings.md),
                    decoration: BoxDecoration(
                      color: r.color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    ),
                    child: Icon(r.icon, size: Spacings.lgIcon, color: r.color),
                  ),
                  const SizedBox(width: Spacings.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          r.subtitle,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          )).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

// ═══════════════════════════════════════════════════════════════════════
// OVERVIEW STAT CARD
// ═══════════════════════════════════════════════════════════════════════

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({required this.stat});

  final _StatItem stat;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(stat.icon, size: Spacings.mdIcon, color: stat.color),
          ),
          // Value
          Text(
            stat.value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          // Title
          Text(
            stat.title,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
