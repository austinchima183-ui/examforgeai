import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../providers/ai_stats_provider.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Dashboard page with stats cards, quick actions, recent generations,
/// usage chart, and provider status indicators.
///
/// ```dart
/// AiDashboardPage()
/// ```
class AiDashboardPage extends ConsumerStatefulWidget {
  const AiDashboardPage({super.key});

  @override
  ConsumerState<AiDashboardPage> createState() => _AiDashboardPageState();
}

class _AiDashboardPageState extends ConsumerState<AiDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load stats on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiStatsProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(aiStatsProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Generator',
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            onPressed: () =>
                ref.read(aiStatsProvider.notifier).refreshStats(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(aiStatsProvider.notifier).refreshStats(),
        child: _buildBody(
          context: context,
          state: statsState,
          isDesktop: isDesktop,
          isMobile: isMobile,
          cs: cs,
          tt: tt,
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AiStatsState state,
    required bool isDesktop,
    required bool isMobile,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && !state.hasData) {
      return AppErrorState(
        icon: Icons.cloud_off_rounded,
        title: 'Failed to load dashboard',
        message: state.error,
        onRetry: () => ref.read(aiStatsProvider.notifier).refreshStats(),
      );
    }

    final stats = state.stats;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats Cards ──────────────────────────────────────────
          _buildStatsGrid(
            context: context,
            stats: stats,
            isDesktop: isDesktop,
            isMobile: isMobile,
          ),

          Spacings.sectionGap,

          // ── Quick Actions ────────────────────────────────────────
          Text(
            'Quick Actions',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _buildQuickActions(context, isMobile),

          Spacings.sectionGap,

          // ── Provider Status ─────────────────────────────────────
          Text(
            'Provider Status',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _buildProviderStatus(context, stats),

          Spacings.sectionGap,

          // ── Usage Chart (Cost by Provider) ──────────────────────
          Text(
            'Cost by Provider',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _buildCostByProviderChart(context, stats),

          Spacings.sectionGap,

          // ── Recent Generations ──────────────────────────────────
          Text(
            'Recent Generations',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _buildRecentGenerations(context, stats),
        ],
      ),
    );
  }

  // ── Stats Grid ─────────────────────────────────────────────────────

  Widget _buildStatsGrid({
    required BuildContext context,
    required AiDashboardStatsEntity? stats,
    required bool isDesktop,
    required bool isMobile,
  }) {
    final statCards = [
      AppStatCard(
        title: 'Total Generated',
        value: '${stats?.totalGenerated ?? 0}',
        icon: Icons.auto_awesome_rounded,
        color: context.colorScheme.primary,
      ),
      AppStatCard(
        title: 'Approved',
        value: '${stats?.totalApproved ?? 0}',
        icon: Icons.check_circle_rounded,
        color: AppColors.successOf(context.colorScheme.brightness),
      ),
      AppStatCard(
        title: 'Pending Review',
        value: '${stats?.pendingReview ?? 0}',
        icon: Icons.schedule_rounded,
        color: AppColors.warningOf(context.colorScheme.brightness),
      ),
      AppStatCard(
        title: 'Total Cost',
        value: '\$${(stats?.totalCost ?? 0.0).toStringAsFixed(2)}',
        icon: Icons.attach_money_rounded,
        color: AppColors.infoOf(context.colorScheme.brightness),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: statCards
            .map((card) => Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: Spacings.md),
                  child: card,
                )))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: isMobile ? 1.1 : 1.4,
      children: statCards,
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    final cs = context.colorScheme;

    final actions = [
      AppActionCard(
        title: 'Generate Questions',
        subtitle: 'Create questions with AI',
        icon: Icons.auto_awesome_rounded,
        color: cs.primary,
        onTap: () {
          // Navigate to generate page
        },
      ),
      AppActionCard(
        title: 'Review Pending',
        subtitle: 'Review generated questions',
        icon: Icons.rate_review_rounded,
        color: AppColors.warningOf(cs.brightness),
        onTap: () {
          // Navigate to review page
        },
      ),
      AppActionCard(
        title: 'Upload Document',
        subtitle: 'Generate from documents',
        icon: Icons.upload_file_rounded,
        color: AppColors.infoOf(cs.brightness),
        onTap: () {
          // Navigate to document page
        },
      ),
      AppActionCard(
        title: 'Manage Prompts',
        subtitle: 'Edit prompt templates',
        icon: Icons.description_outlined,
        color: cs.tertiary,
        onTap: () {
          // Navigate to prompts page
        },
      ),
    ];

    if (isMobile) {
      return Column(
        children: actions
            .map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: a,
                ))
            .toList(),
      );
    }

    return Row(
      children: actions
          .map((a) => Expanded(child: Padding(
                padding: const EdgeInsets.only(right: Spacings.md),
                child: a,
              )))
          .toList(),
    );
  }

  // ── Provider Status ────────────────────────────────────────────────

  Widget _buildProviderStatus(
    BuildContext context,
    AiDashboardStatsEntity? stats,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        children: AiProvider.values.map((provider) {
          final hasUsage = stats?.costByProvider.containsKey(provider.value) ?? false;
          final cost = stats?.costByProvider[provider.value] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasUsage
                        ? AppColors.successOf(cs.brightness)
                        : cs.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Icon(
                  Icons.smart_toy_outlined,
                  size: Spacings.mdIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    provider.displayName,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ),
                Text(
                  hasUsage ? '\$${cost.toStringAsFixed(2)}' : 'No usage',
                  style: tt.bodySmall?.copyWith(
                    color: hasUsage ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (hasUsage
                            ? AppColors.successOf(cs.brightness)
                            : cs.onSurfaceVariant)
                        .withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    hasUsage ? 'Active' : 'Inactive',
                    style: tt.labelSmall?.copyWith(
                      color: hasUsage
                          ? AppColors.successOf(cs.brightness)
                          : cs.onSurfaceVariant,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Cost by Provider Chart ─────────────────────────────────────────

  Widget _buildCostByProviderChart(
    BuildContext context,
    AiDashboardStatsEntity? stats,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final costByProvider = stats?.costByProvider ?? {};

    if (costByProvider.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.bar_chart_rounded,
          title: 'No Usage Data',
          subtitle: 'Generate questions to see cost breakdown by provider.',
        ),
      );
    }

    final totalCost = costByProvider.values.fold(0.0, (a, b) => a + b);

    // Assign colors to providers
    final providerColors = <String, Color>{
      'openai': const Color(0xFF10A37F),
      'gemini': const Color(0xFF4285F4),
      'claude': const Color(0xFFD4A574),
      'deepseek': const Color(0xFF4A90D9),
      'grok': const Color(0xFF1DA1F2),
      'local_llm': const Color(0xFF8B5CF6),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar chart representation
          ...costByProvider.entries.map((entry) {
            final providerName = AiProvider.fromString(entry.key)?.displayName ?? entry.key;
            final color = providerColors[entry.key] ?? cs.primary;
            final percent = totalCost > 0 ? entry.value / totalCost : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Text(
                          providerName,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)} (${(percent * 100).toStringAsFixed(0)}%)',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.xs),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: color,
                      borderRadius: BorderRadius.circular(Spacings.xs),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total: \$${totalCost.toStringAsFixed(2)}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Generations ─────────────────────────────────────────────

  Widget _buildRecentGenerations(
    BuildContext context,
    AiDashboardStatsEntity? stats,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final recent = stats?.recentGenerations ?? [];

    if (recent.isEmpty) {
      return AppCard(
        child: AppEmptyState(
          icon: Icons.history_rounded,
          title: 'No Recent Generations',
          subtitle: 'Start generating questions to see them here.',
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: recent.take(5).map((gen) {
          final statusColor = switch (gen.status) {
            GenerationStatus.completed => AppColors.successOf(cs.brightness),
            GenerationStatus.failed => AppColors.errorOf(cs.brightness),
            GenerationStatus.cancelled => AppColors.warningOf(cs.brightness),
            _ => AppColors.infoOf(cs.brightness),
          };

          return Column(
            children: [
              InkWell(
                onTap: () {
                  // Navigate to generation detail
                },
                child: Padding(
                  padding: const EdgeInsets.all(Spacings.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gen.provider.displayName,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: AppTypography.wMedium,
                              ),
                            ),
                            Text(
                              gen.generationType.label,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (gen.totalCost != null)
                            Text(
                              '\$${gen.totalCost!.toStringAsFixed(3)}',
                              style: tt.labelMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                          Text(
                            _formatDate(gen.createdAt),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: Spacings.sm),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (gen != recent.last)
                const Divider(height: 1, indent: Spacings.xxl),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
