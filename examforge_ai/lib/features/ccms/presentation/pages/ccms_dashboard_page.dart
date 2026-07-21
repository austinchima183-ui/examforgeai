import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class CcmsDashboardPage extends ConsumerStatefulWidget {
  const CcmsDashboardPage({super.key});

  @override
  ConsumerState<CcmsDashboardPage> createState() => _CcmsDashboardPageState();
}

class _CcmsDashboardPageState extends ConsumerState<CcmsDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitoringProvider.notifier).loadCcmsStats();
      ref.read(contentProvider.notifier).loadContentItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitoringState = ref.watch(monitoringProvider);
    final contentState = ref.watch(contentProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppAppBar(title: 'Curriculum Management'),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Overview ──────────────────────────────────────────
            Text(
              'Overview',
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            if (monitoringState.isLoading && monitoringState.ccmsStats == null)
              const Center(child: AppLoadingSpinner())
            else if (monitoringState.error != null)
              AppErrorState(
                message: monitoringState.error,
                onRetry: () =>
                    ref.read(monitoringProvider.notifier).loadCcmsStats(),
              )
            else ...[
              _buildStatsGrid(monitoringState.ccmsStats, isDesktop, isTablet),
              Spacings.sectionGap,
            ],

            // ── Quick Actions ───────────────────────────────────────────
            Text(
              'Quick Actions',
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            _buildQuickActions(isDesktop, isTablet),
            Spacings.sectionGap,

            // ── Recent Content ──────────────────────────────────────────
            Text(
              'Recent Content',
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            if (contentState.isLoading)
              const Center(child: AppLoadingSpinner())
            else if (contentState.contentItems.isEmpty)
              AppEmptyState.noData(subtitle: 'No content items yet')
            else
              ...contentState.contentItems.take(5).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.sm),
                      child: ContentItemCard(
                        content: item,
                        onTap: () {},
                        onEdit: () {},
                        onPublish: () => ref
                            .read(contentProvider.notifier)
                            .publishContent(item.id),
                        onArchive: () => ref
                            .read(contentProvider.notifier)
                            .archiveContent(item.id),
                        onAddToCollection: () {},
                      ),
                    ),
                  ),

            Spacings.sectionGap,

            // ── Content Analytics (Horizontal Bar Chart Area) ──────────
            Text(
              'Content Analytics',
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHorizontalBarChartArea(
                          'Content by Type',
                          Icons.bar_chart_rounded,
                          monitoringState.ccmsStats,
                        ),
                      ),
                      const SizedBox(width: Spacings.lg),
                      Expanded(
                        child: _buildChartPlaceholder(
                          'Content by Difficulty',
                          Icons.pie_chart_outline_rounded,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildHorizontalBarChartArea(
                        'Content by Type',
                        Icons.bar_chart_rounded,
                        monitoringState.ccmsStats,
                      ),
                      const SizedBox(height: Spacings.lg),
                      _buildChartPlaceholder(
                        'Content by Difficulty',
                        Icons.pie_chart_outline_rounded,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      CcmsStats? stats, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 3 : 2);
    final statCards = [
      StatOverviewCard(
        title: 'Total Subjects',
        value: '${stats?.totalSubjects ?? 0}',
        icon: Icons.menu_book_rounded,
        color: AppColors.info,
      ),
      StatOverviewCard(
        title: 'Total Topics',
        value: '${stats?.totalTopics ?? 0}',
        icon: Icons.topic_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      StatOverviewCard(
        title: 'Total Content',
        value: '${stats?.totalContent ?? 0}',
        icon: Icons.article_rounded,
        color: AppColors.success,
      ),
      StatOverviewCard(
        title: 'Published',
        value: '${stats?.publishedContent ?? 0}',
        icon: Icons.publish_rounded,
        color: const Color(0xFF059669),
      ),
      StatOverviewCard(
        title: 'Draft',
        value: '${stats?.draftContent ?? 0}',
        icon: Icons.edit_note_rounded,
        color: AppColors.warning,
      ),
      StatOverviewCard(
        title: 'AI Generated',
        value: '${stats?.aiGeneratedContent ?? 0}',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF7C3AED),
      ),
      StatOverviewCard(
        title: 'Past Questions',
        value: '${stats?.pastQuestions ?? 0}',
        icon: Icons.history_edu_rounded,
        color: const Color(0xFF0891B2),
      ),
      StatOverviewCard(
        title: 'Avg Quality',
        value: stats?.averageQualityScore.toStringAsFixed(1) ?? '0.0',
        icon: Icons.star_rounded,
        color: const Color(0xFFF59E0B),
      ),
      StatOverviewCard(
        title: 'Pending Reviews',
        value: '${stats?.pendingReviews ?? 0}',
        icon: Icons.rate_review_rounded,
        color: const Color(0xFFEC4899),
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: isDesktop ? 1.8 : 1.4,
      children: statCards,
    );
  }

  Widget _buildQuickActions(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 6 : (isTablet ? 4 : 3);
    final actions = [
      _QuickAction(
        icon: Icons.school_rounded,
        label: 'Manage Levels',
        color: AppColors.info,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: 'Manage Subjects',
        color: const Color(0xFF8B5CF6),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.library_books_rounded,
        label: 'Content Library',
        color: AppColors.success,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: 'AI Engine',
        color: const Color(0xFF7C3AED),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.upload_file_rounded,
        label: 'Import',
        color: const Color(0xFF0891B2),
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.collections_bookmark_rounded,
        label: 'Collections',
        color: const Color(0xFFEC4899),
        onTap: () {},
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: 1.2,
      children: actions,
    );
  }

  Widget _buildHorizontalBarChartArea(
    String title,
    IconData icon,
    CcmsStats? stats,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final contentTypes = [
      ('Questions', stats?.totalContent ?? 0, AppColors.info),
      ('Published', stats?.publishedContent ?? 0, AppColors.success),
      ('Draft', stats?.draftContent ?? 0, AppColors.warning),
      ('AI Generated', stats?.aiGeneratedContent ?? 0, const Color(0xFF7C3AED)),
      ('Past Questions', stats?.pastQuestions ?? 0, const Color(0xFF0891B2)),
    ];
    final maxVal = contentTypes.map((e) => e.$2).reduce((a, b) => a > b ? a : b).toDouble().clamp(1, double.infinity);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          ...contentTypes.map((entry) {
            final fraction = maxVal > 0 ? entry.$2 / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.$1,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                      Text(
                        '${entry.$2}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  ClipRRect(
                    borderRadius: Spacings.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: entry.$3,
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, IconData icon) {
    final cs = context.colorScheme;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xl),
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: cs.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Chart will render here',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: Icon(icon, size: Spacings.lgIcon, color: color),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: AppTypography.wMedium,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
