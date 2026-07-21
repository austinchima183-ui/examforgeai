import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_insights_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT INSIGHTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Insights page showing all generated insights for a parent.
///
/// Displays a filterable list of insight cards with severity colour bars,
/// type badges, recommendations, and dismiss actions. Supports child and
/// read-status filtering, pull-to-refresh, and tap-to-mark-read.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentInsightsPage extends ConsumerStatefulWidget {
  const ParentInsightsPage({super.key});

  @override
  ConsumerState<ParentInsightsPage> createState() => _State();
}

class _State extends ConsumerState<ParentInsightsPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// The selected child filter, or `null` for all children.
  String? _selectedChildId;

  /// The active read-status filter: null=all, false=unread, true=read.
  bool? _readFilter;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentInsightsProvider.notifier).loadInsights();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final insightsState = ref.watch(parentInsightsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Insights',
      ),
      body: _buildBody(context, insightsState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(BuildContext context, ParentInsightsState state) {
    // Loading state
    if (state.isLoading && state.insights.isEmpty) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.insights.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(parentInsightsProvider.notifier).loadInsights(),
      );
    }

    // Filter insights
    final insights = _filterInsights(state.insights);

    return Column(
      children: [
        // ─── Filter Row ──────────────────────────────────────────
        _buildFilterRow(context),

        // ─── Insights List ───────────────────────────────────────
        Expanded(
          child: insights.isEmpty
              ? AppEmptyState.noData(
                  title: 'No Insights',
                  subtitle:
                      'No insights at this time. Check back later for AI-generated observations about your child\'s academic journey.',
                  icon: Icons.auto_awesome_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(parentInsightsProvider.notifier)
                      .loadInsights(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacings.xxl),
                    itemCount: insights.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.sm),
                    itemBuilder: (_, index) =>
                        _buildInsightCard(context, insights[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFilterRow(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          // Child filter dropdown
          Expanded(
            child: DropdownButton<String>(
              value: _selectedChildId,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: cs.onSurface,
                size: Spacings.mdIcon,
              ),
              underline: const SizedBox.shrink(),
              hint: Text(
                'All Children',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
              style: tt.labelMedium?.copyWith(color: cs.onSurface),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'All Children',
                    style: tt.labelMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                // TODO: Populate with actual children
              ],
              onChanged: (value) {
                setState(() => _selectedChildId = value);
                ref
                    .read(parentInsightsProvider.notifier)
                    .loadInsights(studentId: value);
              },
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Read status filter
          DropdownButton<bool?>(
            value: _readFilter,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: cs.onSurface,
              size: Spacings.mdIcon,
            ),
            underline: const SizedBox.shrink(),
            style: tt.labelMedium?.copyWith(color: cs.onSurface),
            items: const [
              DropdownMenuItem<bool?>(
                value: null,
                child: Text('All'),
              ),
              DropdownMenuItem<bool?>(
                value: false,
                child: Text('Unread'),
              ),
              DropdownMenuItem<bool?>(
                value: true,
                child: Text('Read'),
              ),
            ],
            onChanged: (value) {
              setState(() => _readFilter = value);
              ref
                  .read(parentInsightsProvider.notifier)
                  .loadInsights(isRead: value);
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INSIGHT CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInsightCard(
    BuildContext context,
    ParentAiInsightEntity insight,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final severityColor = _severityColor(insight.severity, cs.brightness);
    final isUnread = !insight.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: isUnread
            ? cs.primaryContainer.withOpacity(0.08)
            : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: InkWell(
          onTap: () {
            // Mark as read on tap
            if (isUnread) {
              // TODO: Call mark as read when the use case is available
            }
          },
          borderRadius: Spacings.borderRadiusMd,
          child: ClipRRect(
            borderRadius: Spacings.borderRadiusMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Severity colour bar
                Container(
                  width: 4,
                  height: double.infinity,
                  color: severityColor,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: Spacings.paddingCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: type badge + dismiss button
                        Row(
                          children: [
                            // Insight type badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.12),
                                borderRadius: Spacings.borderRadiusSm,
                              ),
                              child: Text(
                                insight.insightType.label,
                                style: tt.labelSmall?.copyWith(
                                  color: severityColor,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Dismiss button
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: Spacings.smIcon,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  _confirmDismiss(context, insight.id),
                              tooltip: 'Dismiss',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacings.sm),

                        // Title
                        Text(
                          insight.title,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? AppTypography.wBold
                                : AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacings.xs),

                        // Description
                        Text(
                          insight.description,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Recommendations
                        if (insight.recommendations.isNotEmpty) ...[
                          const SizedBox(height: Spacings.md),
                          Text(
                            'Recommendations',
                            style: tt.labelMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacings.xs),
                          ...insight.recommendations.asMap().entries.map(
                            (entry) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacings.xs,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: Spacings.smIcon,
                                      color: AppColors.warningOf(
                                        cs.brightness,
                                      ),
                                    ),
                                    const SizedBox(width: Spacings.xs),
                                    Expanded(
                                      child: Text(
                                        '${entry.key + 1}. ${entry.value}',
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: Spacings.sm),

                        // Created date
                        Text(
                          _formatDate(insight.createdAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONFIRM DISMISS DIALOG
  // ═══════════════════════════════════════════════════════════════════════

  void _confirmDismiss(BuildContext context, String insightId) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Dismiss Insight',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        content: Text(
          'Are you sure you want to dismiss this insight? This action cannot be undone.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(parentInsightsProvider.notifier)
                  .dismissInsight(insightId);
            },
            child: Text(
              'Dismiss',
              style: tt.labelMedium?.copyWith(
                color: AppColors.errorOf(cs.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: AppLoadingShimmer.box(
                  height: 120,
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTERING
  // ═══════════════════════════════════════════════════════════════════════

  /// Filters insights by read status (client-side).
  List<ParentAiInsightEntity> _filterInsights(
    List<ParentAiInsightEntity> insights,
  ) {
    return insights.where((insight) {
      if (_readFilter != null && insight.isRead != _readFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the colour for an insight severity.
  Color _severityColor(InsightSeverity severity, Brightness brightness) {
    switch (severity) {
      case InsightSeverity.info:
        return AppColors.infoOf(brightness);
      case InsightSeverity.warning:
        return AppColors.warningOf(brightness);
      case InsightSeverity.concern:
        return AppColors.errorOf(brightness);
      case InsightSeverity.positive:
        return AppColors.successOf(brightness);
    }
  }

  /// Formats a [DateTime] as a short date string.
  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}
