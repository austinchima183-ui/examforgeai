import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_coach_entities.dart';
import '../providers/ai_coach_provider.dart';
import '../widgets/ai_coach_widgets.dart';
import 'coach_chat_page.dart';
import 'weak_topics_page.dart';

/// AI Coach dashboard page.
///
/// Features:
/// - Readiness prediction ring with score
/// - Active recommendations cards
/// - Weak topics summary
/// - Quick actions (new session, generate plan, detect weak topics)
/// - Motivational message banner
/// - Recent coaching sessions list
class AiCoachDashboardPage extends ConsumerStatefulWidget {
  const AiCoachDashboardPage({super.key});

  @override
  ConsumerState<AiCoachDashboardPage> createState() =>
      _AiCoachDashboardPageState();
}

class _AiCoachDashboardPageState
    extends ConsumerState<AiCoachDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiCoachProvider.notifier).loadSessions();
      ref.read(aiCoachProvider.notifier).loadRecommendations();
      ref.read(aiCoachProvider.notifier).loadMotivationalMessage();
      ref.read(aiCoachProvider.notifier).predictReadiness();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _generateStudyPlan(context),
            tooltip: 'Generate Study Plan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(aiCoachProvider.notifier).loadSessions(),
            ref.read(aiCoachProvider.notifier).loadRecommendations(),
            ref.read(aiCoachProvider.notifier).predictReadiness(),
            ref.read(aiCoachProvider.notifier).loadMotivationalMessage(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // ─── Motivational Message ───────────────────────────────────
            if (state.motivationalMessage != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.motivationalMessage!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Readiness Score ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ReadinessCard(
                  prediction: state.readinessPrediction,
                  isLoading: state.isPredictingReadiness,
                ),
              ),
            ),

            // ─── Quick Actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.chat_outlined,
                            label: 'New Session',
                            color: AppColors.primary,
                            onTap: () => _startNewSession(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.auto_awesome,
                            label: 'Study Plan',
                            color: AppColors.success,
                            onTap: () => _generateStudyPlan(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.trending_down,
                            label: 'Weak Topics',
                            color: AppColors.warning,
                            onTap: () => _navigateToWeakTopics(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Recommendations ────────────────────────────────────────
            if (state.recommendations.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommendations',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${state.activeRecommendationCount} active',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.recommendations
                        .where((r) => r.isActive)
                        .length,
                    itemBuilder: (context, index) {
                      final activeRecs = state.recommendations
                          .where((r) => r.isActive)
                          .toList();
                      return RecommendationCard(
                        recommendation: activeRecs[index],
                        onDismiss: () => ref
                            .read(aiCoachProvider.notifier)
                            .dismissRecommendation(activeRecs[index].id),
                        onTap: () => _handleRecommendationAction(
                          context,
                          activeRecs[index],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ─── Milestone Tracker ──────────────────────────────────────
            if (state.generatedStudyPlan != null &&
                state.generatedStudyPlan!.milestones.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Study Milestones',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      MilestoneTracker(
                        milestones:
                            state.generatedStudyPlan!.milestones,
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Recent Sessions ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _navigateToChat(context),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            if (state.isLoading && state.sessions.isEmpty)
              const SliverFillRemaining(
                child: Center(child: AppLoadingSpinner()),
              )
            else if (state.sessions.isEmpty)
              const SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.psychology_outlined,
                  title: 'No Sessions Yet',
                  subtitle:
                      'Start a coaching session to get personalized guidance.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.sessions.length) return null;
                      final session = state.sessions[index];
                      return _SessionTile(
                        session: session,
                        onTap: () {
                          ref
                              .read(aiCoachProvider.notifier)
                              .selectSession(session);
                          _navigateToChat(context);
                        },
                      );
                    },
                    childCount: state.sessions.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNewSession(context),
        icon: const Icon(Icons.chat_outlined),
        label: const Text('New Session'),
      ),
    );
  }

  void _startNewSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CoachChatPage(),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CoachChatPage(),
      ),
    );
  }

  void _navigateToWeakTopics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WeakTopicsPage(),
      ),
    );
  }

  void _generateStudyPlan(BuildContext context) {
    ref.read(aiCoachProvider.notifier).generateStudyPlan();
  }

  void _handleRecommendationAction(
    BuildContext context,
    AiCoachRecommendation recommendation,
  ) {
    final actionType = recommendation.actionType;
    if (actionType == null) return;

    switch (actionType) {
      case RecommendationActionType.studyTopic:
      case RecommendationActionType.reviewMaterial:
        _navigateToWeakTopics(context);
        break;
      case RecommendationActionType.practiceQuestion:
      case RecommendationActionType.takeTest:
        // Navigate to practice/exam
        break;
      case RecommendationActionType.adjustPlan:
        _generateStudyPlan(context);
        break;
      case RecommendationActionType.motivationalBoost:
        ref.read(aiCoachProvider.notifier).loadMotivationalMessage();
        break;
    }
  }
}

/// Readiness prediction card with score ring.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.prediction,
    required this.isLoading,
  });

  final ReadinessPrediction? prediction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: AppLoadingSpinner()),
        ),
      );
    }

    if (prediction == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.psychology_outlined,
                  size: 48, color: context.colorScheme.onSurfaceVariant,),
              const SizedBox(height: 12),
              Text(
                'Readiness prediction not available',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () {
                  // Trigger prediction
                },
                child: const Text('Calculate Readiness'),
              ),
            ],
          ),
        ),
      );
    }

    final score = prediction!.overallScore;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Score ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        backgroundColor:
                            context.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        color: scoreColor,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${score.toInt()}',
                              style: context.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                            Text(
                              '%',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exam Readiness',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(prediction!.confidence * 100).toInt()}%',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (prediction!.predictedGrade != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Predicted Grade: ${prediction!.predictedGrade}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                          ),
                        ),
                      ],
                      if (prediction!.recommendedStudyHours > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '~${prediction!.recommendedStudyHours}h study recommended',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Strengths and weaknesses
            if (prediction!.strengths.isNotEmpty ||
                prediction!.improvementAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Strengths
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strengths',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...prediction!.strengths.take(3).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 14, color: AppColors.success,),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(s,
                                          style:
                                              context.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Improvement areas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Needs Work',
                          style: context.textTheme.labelLarge?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...prediction!.improvementAreas.take(3).map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.trending_up,
                                        size: 14, color: AppColors.warning,),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(s,
                                          style:
                                              context.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick action button widget.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
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
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Session tile widget for the sessions list.
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
  });

  final AiCoachSession session;
  final VoidCallback onTap;

  IconData _sessionIcon() {
    switch (session.sessionType) {
      case CoachSessionType.general:
        return Icons.psychology_outlined;
      case CoachSessionType.studyPlan:
        return Icons.event_note_outlined;
      case CoachSessionType.weakTopics:
        return Icons.trending_down;
      case CoachSessionType.examPrep:
        return Icons.quiz_outlined;
      case CoachSessionType.motivation:
        return Icons.favorite_outline;
      case CoachSessionType.careerGuidance:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _sessionIcon(),
          color: AppColors.primary,
        ),
        title: Text(
          session.sessionType.label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: session.lastMessage != null
            ? Text(
                session.lastMessage!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall,
              )
            : Text(
                '${session.messageCount} messages',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: Text(
          _formatDate(session.updatedAt),
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
