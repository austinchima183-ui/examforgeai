import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_coach_entities.dart';
import '../providers/ai_coach_provider.dart';

/// Weak topics page showing areas where the student needs improvement.
///
/// Features:
/// - Weak topics list sorted by severity
/// - Accuracy percentage per topic
/// - Subject grouping
/// - Severity badges (critical, high, medium, low)
/// - Quick action buttons (practice, review)
/// - Refresh to re-detect weak topics
class WeakTopicsPage extends ConsumerStatefulWidget {
  const WeakTopicsPage({super.key});

  @override
  ConsumerState<WeakTopicsPage> createState() => _WeakTopicsPageState();
}

class _WeakTopicsPageState extends ConsumerState<WeakTopicsPage> {
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiCoachProvider.notifier).detectWeakTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);

    // Group topics by subject
    final Map<String, List<WeakTopic>> groupedTopics = {};
    for (final topic in state.weakTopics) {
      groupedTopics.putIfAbsent(topic.subjectName, () => []).add(topic);
    }

    // Sort by severity
    final sortedSubjects = groupedTopics.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weak Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(aiCoachProvider.notifier)
                .detectWeakTopics(subjectId: _selectedSubject),
            tooltip: 'Re-analyze',
          ),
        ],
      ),
      body: state.isDetectingWeakTopics
          ? const Center(child: AppLoadingSpinner())
          : state.weakTopics.isEmpty
              ? const AppEmptyState(
                  icon: Icons.trending_up,
                  title: 'No Weak Topics Detected',
                  subtitle:
                      'Great job! We couldn\'t find any significantly weak areas. '
                      'Keep practicing to maintain your strengths.',
                )
              : Column(
                  children: [
                    // ─── Summary Banner ───────────────────────────────────
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_down,
                              color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.weakTopics.length} Weak Areas Found',
                                  style:
                                      context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Focus on these topics to improve your overall performance.',
                                  style:
                                      context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Severity Distribution ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _SeverityBadge(
                            label: 'Critical',
                            count: state.weakTopics
                                .where((t) => t.severity == 'critical')
                                .length,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          _SeverityBadge(
                            label: 'High',
                            count: state.weakTopics
                                .where((t) => t.severity == 'high')
                                .length,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _SeverityBadge(
                            label: 'Medium',
                            count: state.weakTopics
                                .where((t) => t.severity == 'medium')
                                .length,
                            color: AppColors.info,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Topics List ──────────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sortedSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = sortedSubjects[index];
                          final topics = groupedTopics[subject]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  subject,
                                  style:
                                      context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                              // Topic cards
                              ...topics.map((topic) => _WeakTopicCard(
                                    topic: topic,
                                    onPractice: () =>
                                        _practiceTopic(topic),
                                    onReview: () => _reviewTopic(topic),
                                  )),

                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _practiceTopic(WeakTopic topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting practice for ${topic.topicName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Navigate to practice session for this topic
  }

  void _reviewTopic(WeakTopic topic) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening review material for ${topic.topicName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Navigate to review material for this topic
  }
}

/// Severity badge widget.
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Weak topic card widget.
class _WeakTopicCard extends StatelessWidget {
  const _WeakTopicCard({
    required this.topic,
    required this.onPractice,
    required this.onReview,
  });

  final WeakTopic topic;
  final VoidCallback onPractice;
  final VoidCallback onReview;

  Color _severityColor() {
    switch (topic.severity) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.topicName,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Severity badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    topic.severity.toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Accuracy bar
            Row(
              children: [
                Text(
                  'Accuracy',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: topic.accuracy / 100,
                      backgroundColor:
                          context.colorScheme.outlineVariant.withOpacity(0.3),
                      color: severityColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${topic.accuracy.toInt()}%',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Stats
            Text(
              '${topic.correctCount}/${topic.attemptsCount} correct answers',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),

            // Recommendations
            if (topic.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...topic.recommendations.take(2).map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 14, color: AppColors.info),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rec,
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPractice,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Practice'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
