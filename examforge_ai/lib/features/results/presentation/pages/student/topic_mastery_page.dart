import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../../providers/results_providers.dart';
import '../../providers/results_page_providers.dart';
import '../../../../../features/student_portal/domain/entities/student_portal_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// TOPIC MASTERY PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Student's topic mastery view showing per-topic progress, mastery levels,
/// accuracy, and practice history for a given subject.
class TopicMasteryPage extends ConsumerStatefulWidget {
  const TopicMasteryPage({
    super.key,
    required this.studentId,
    required this.subjectId,
  });

  final String studentId;
  final String subjectId;

  @override
  ConsumerState<TopicMasteryPage> createState() => _TopicMasteryPageState();
}

class _TopicMasteryPageState extends ConsumerState<TopicMasteryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMastery();
    });
  }

  void _loadMastery() {
    ref.read(studentResultsProvider.notifier).loadTopicMastery(
          studentId: widget.studentId,
          subjectId: widget.subjectId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentResultsProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Topic Mastery',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: state.error,
                    actionLabel: 'Retry',
                    onAction: _loadMastery,
                  ),
                )
              : _buildContent(context, state),
    );
  }

  // ─── Main Content ────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, StudentResultsState state) {
    final topics = state.topicMastery;

    if (topics.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.school_outlined,
          title: 'No Topic Data',
          subtitle:
              'Topic mastery data will appear as you practise more questions.',
          actionLabel: 'Refresh',
          onAction: _loadMastery,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Stats ─────────────────────────────────────
              _buildMasterySummary(context, topics),
              const SizedBox(height: Spacings.xl),

              // ── Subject Filter (placeholder) ──────────────────────
              _buildSubjectFilter(context),
              const SizedBox(height: Spacings.lg),

              // ── Topic Mastery Grid ────────────────────────────────
              _buildTopicGrid(context, topics),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mastery Summary ─────────────────────────────────────────────────

  Widget _buildMasterySummary(
      BuildContext context, List<TopicMasteryEntity> topics) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final expertCount =
        topics.where((t) => t.masteryLevel == MasteryLevel.expert).length;
    final advancedCount =
        topics.where((t) => t.masteryLevel == MasteryLevel.advanced).length;
    final proficientCount =
        topics.where((t) => t.masteryLevel == MasteryLevel.proficient).length;
    final needsWorkCount = topics
        .where((t) =>
            t.masteryLevel == MasteryLevel.beginner ||
            t.masteryLevel == MasteryLevel.developing ||
            t.masteryLevel == MasteryLevel.notStarted)
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryChip(
            context,
            label: 'Expert',
            count: expertCount,
            color: AppColors.successOf(cs.brightness),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: _summaryChip(
            context,
            label: 'Advanced',
            count: advancedCount,
            color: const Color(0xFF84CC16),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: _summaryChip(
            context,
            label: 'Proficient',
            count: proficientCount,
            color: const Color(0xFFFACC15),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: _summaryChip(
            context,
            label: 'Needs Work',
            count: needsWorkCount,
            color: AppColors.errorOf(cs.brightness),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Subject Filter ──────────────────────────────────────────────────

  Widget _buildSubjectFilter(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(Icons.filter_list_rounded,
            size: Spacings.mdIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.sm),
        Text(
          'Subject: ',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: widget.subjectId,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(
                  color: cs.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                borderSide: BorderSide(
                  color: cs.outlineVariant,
                ),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: widget.subjectId,
                child: Text(
                  widget.subjectId, // Placeholder: replace with subject name
                  style: tt.bodyMedium,
                ),
              ),
            ],
            onChanged: (value) {
              // TODO: Navigate to different subject's topic mastery
            },
          ),
        ),
      ],
    );
  }

  // ─── Topic Mastery Grid ──────────────────────────────────────────────

  Widget _buildTopicGrid(
      BuildContext context, List<TopicMasteryEntity> topics) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: Spacings.md,
          runSpacing: Spacings.md,
          children: topics
              .map((topic) => SizedBox(
                    width: (constraints.maxWidth -
                            Spacings.md * (crossAxisCount - 1)) /
                        crossAxisCount,
                    child: _buildTopicCard(context, topic),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTopicCard(BuildContext context, TopicMasteryEntity topic) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final masteryColor = _masteryLevelColor(topic.masteryLevel, cs.brightness);
    final masteryLabel = topic.masteryLevel.label;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic name + mastery badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  topic.metadata['topicName'] as String? ?? topic.topicId,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              // Mastery level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: masteryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  border: Border.all(
                    color: masteryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  masteryLabel,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: masteryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Accuracy with progress indicator
          Row(
            children: [
              Text(
                'Accuracy',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${topic.accuracyPercentage.toStringAsFixed(0)}%',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: topic.accuracyPercentage / 100,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: masteryColor,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
          const SizedBox(height: Spacings.md),

          // Questions attempted / correct
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(
                context,
                label: 'Attempted',
                value: '${topic.questionsAttempted}',
              ),
              _buildMiniStat(
                context,
                label: 'Correct',
                value: '${topic.questionsCorrect}',
              ),
              if (topic.lastPracticedAt != null)
                _buildMiniStat(
                  context,
                  label: 'Last Practice',
                  value: _formatDate(topic.lastPracticedAt!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: tt.bodySmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Color _masteryLevelColor(MasteryLevel level, Brightness brightness) {
    return switch (level) {
      MasteryLevel.notStarted => const Color(0xFF9CA3AF), // grey
      MasteryLevel.beginner => const Color(0xFFEF4444), // red
      MasteryLevel.developing => const Color(0xFFF97316), // orange
      MasteryLevel.proficient => const Color(0xFFFACC15), // yellow
      MasteryLevel.advanced => const Color(0xFF84CC16), // lime
      MasteryLevel.expert => const Color(0xFF22C55E), // green
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
