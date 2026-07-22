import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../providers/ai_generator_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI HISTORY PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Generation History page with search/filter bar, list of generation
/// requests, usage stats summary, and pagination.
///
/// ```dart
/// AiHistoryPage()
/// ```
class AiHistoryPage extends ConsumerStatefulWidget {
  const AiHistoryPage({super.key});

  @override
  ConsumerState<AiHistoryPage> createState() => _AiHistoryPageState();
}

class _AiHistoryPageState extends ConsumerState<AiHistoryPage> {
  final _searchController = TextEditingController();
  AiProvider? _filterProvider;
  GenerationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiGeneratorProvider.notifier).loadGenerationHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGeneratorProvider);
    final notifier = ref.read(aiGeneratorProvider.notifier);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Generation History',
      ),
      body: Column(
        children: [
          // ── Usage Stats Summary ──────────────────────────────────
          _buildUsageSummary(state),

          // ── Search & Filter Bar ───────────────────────────────────
          _buildSearchFilterBar(),

          // ── History List ─────────────────────────────────────────
          Expanded(
            child: _buildHistoryList(state, notifier),
          ),
        ],
      ),
    );
  }

  // ── Usage Stats Summary ────────────────────────────────────────────

  Widget _buildUsageSummary(AiGeneratorState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final history = state.generationHistory;

    final totalRequests = history.length;
    final totalCost = history
        .map((r) => r.totalCost ?? 0.0)
        .fold(0.0, (a, b) => a + b);
    final totalQuestions = history
        .map((r) => (r.processedResponse?['question_count'] as int?) ?? 0)
        .fold(0, (a, b) => a + b);
    final avgTime = history.isEmpty
        ? 0.0
        : history
                .map((r) => r.generationTimeMs ?? 0)
                .fold(0, (a, b) => a + b) /
            history.length;

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      color: cs.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        children: [
          _SummaryStat(
            label: 'Requests',
            value: '$totalRequests',
            icon: Icons.list_alt_rounded,
            color: cs.primary,
          ),
          const SizedBox(width: Spacings.lg),
          _SummaryStat(
            label: 'Questions',
            value: '$totalQuestions',
            icon: Icons.quiz_outlined,
            color: AppColors.successOf(cs.brightness),
          ),
          if (!context.isMobile) ...[
            const SizedBox(width: Spacings.lg),
            _SummaryStat(
              label: 'Cost',
              value: '\$${totalCost.toStringAsFixed(2)}',
              icon: Icons.attach_money_rounded,
              color: AppColors.warningOf(cs.brightness),
            ),
            const SizedBox(width: Spacings.lg),
            _SummaryStat(
              label: 'Avg Time',
              value: _formatDuration(avgTime),
              icon: Icons.timer_outlined,
              color: AppColors.infoOf(cs.brightness),
            ),
          ],
        ],
      ),
    );
  }

  // ── Search & Filter Bar ────────────────────────────────────────────

  Widget _buildSearchFilterBar() {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg, Spacings.md, Spacings.lg, Spacings.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search generations…',
              onChanged: (query) {
                // Filter by search
              },
            ),
          ),
          const SizedBox(width: Spacings.sm),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
            onSelected: (value) {
              if (value == 'all') {
                setState(() {
                  _filterProvider = null;
                  _filterStatus = null;
                });
              } else if (value.startsWith('provider_')) {
                final providerStr = value.replaceFirst('provider_', '');
                setState(() {
                  _filterProvider = AiProvider.fromString(providerStr);
                });
              } else if (value.startsWith('status_')) {
                final statusStr = value.replaceFirst('status_', '');
                setState(() {
                  _filterStatus = GenerationStatus.fromString(statusStr);
                });
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuDivider(),
              ...AiProvider.values.map((p) => PopupMenuItem(
                    value: 'provider_${p.value}',
                    child: Text(p.displayName),
                  )),
              const PopupMenuDivider(),
              ...GenerationStatus.values.map((s) => PopupMenuItem(
                    value: 'status_${s.value}',
                    child: Text(s.label),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ── History List ────────────────────────────────────────────────────

  Widget _buildHistoryList(
    AiGeneratorState state,
    AiGeneratorNotifier notifier,
  ) {
    if (state.isLoadingHistory && state.generationHistory.isEmpty) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.generationHistory.isEmpty) {
      return AppErrorState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load history',
        message: state.error,
        onRetry: () => notifier.loadGenerationHistory(),
      );
    }

    var history = state.generationHistory;

    // Apply filters
    if (_filterProvider != null) {
      history = history
          .where((r) => r.provider == _filterProvider)
          .toList();
    }
    if (_filterStatus != null) {
      history = history
          .where((r) => r.status == _filterStatus)
          .toList();
    }

    if (history.isEmpty) {
      return AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No Generation History',
        subtitle: 'Start generating questions to see your history here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadGenerationHistory(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          Spacings.lg, Spacings.sm, Spacings.lg, Spacings.xxl,
        ),
        itemCount: history.length + (state.hasMoreHistory ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (context, index) {
          // Load more indicator
          if (index == history.length) {
            // Trigger loading more
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (state.hasMoreHistory && !state.isLoadingHistory) {
                notifier.loadGenerationHistory(
                  page: state.historyPage + 1,
                );
              }
            });
            return const Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small)),
            );
          }

          final request = history[index];
          return _buildHistoryItem(request);
        },
      ),
    );
  }

  // ── History Item ───────────────────────────────────────────────────

  Widget _buildHistoryItem(GenerationRequestEntity request) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = switch (request.status) {
      GenerationStatus.completed => AppColors.successOf(cs.brightness),
      GenerationStatus.failed => AppColors.errorOf(cs.brightness),
      GenerationStatus.cancelled => AppColors.warningOf(cs.brightness),
      GenerationStatus.pending => AppColors.infoOf(cs.brightness),
      GenerationStatus.processing => AppColors.infoOf(cs.brightness),
    };

    final statusIcon = switch (request.status) {
      GenerationStatus.completed => Icons.check_circle_rounded,
      GenerationStatus.failed => Icons.error_rounded,
      GenerationStatus.cancelled => Icons.cancel_rounded,
      GenerationStatus.pending => Icons.schedule_rounded,
      GenerationStatus.processing => Icons.sync_rounded,
    };

    return AppCard(
      onTap: () {
        // Navigate to generation detail
      },
      child: Row(
        children: [
          // Status icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(statusIcon, size: Spacings.mdIcon, color: statusColor),
          ),
          const SizedBox(width: Spacings.md),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.provider.displayName,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (request.totalCost != null)
                      Text(
                        '\$${request.totalCost!.toStringAsFixed(3)}',
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Text(
                      request.generationType.label,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    if (request.generationTimeMs != null)
                      Text(
                        _formatDuration(request.generationTimeMs!.toDouble()),
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: Spacings.md),
                    Text(
                      _formatDate(request.createdAt),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (request.errorMessage != null) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    request.errorMessage!,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.errorOf(cs.brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: Spacings.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatDuration(double ms) {
    if (ms < 1000) return '${ms.toStringAsFixed(0)}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)}m';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: Spacings.mdIcon, color: color),
          const SizedBox(height: Spacings.xs),
          Text(
            value,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: context.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
