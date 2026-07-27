import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../providers/student_portal_providers.dart';

/// Practice quiz interface page with three screens:
/// - Setup: Subject/Topic/Difficulty selectors, Mode toggle, Question count, Start
/// - Session: Question display, Answer input, Navigator, Timer, Progress, Submit
/// - Results: Score display, Question review, Time per question, Retake
class PracticeModePage extends ConsumerStatefulWidget {
  const PracticeModePage({super.key});

  @override
  ConsumerState<PracticeModePage> createState() => _PracticeModePageState();
}

class _PracticeModePageState extends ConsumerState<PracticeModePage> {
  // Setup state
  String? _selectedSubject;
  String? _selectedTopic;
  String _selectedDifficulty = 'medium';
  PracticeMode _selectedMode = PracticeMode.untimed;
  double _questionCount = 10;
  int _timeLimitMin = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceProvider.notifier).loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(practiceProvider);

    // Determine which screen to show
    if (practiceState.currentSession != null &&
        practiceState.currentSession!.status ==
            PracticeSessionStatus.completed) {
      return _buildResultsScreen(context, practiceState);
    }

    if (practiceState.currentSession != null &&
        practiceState.currentSession!.status ==
            PracticeSessionStatus.inProgress) {
      return _buildSessionScreen(context, practiceState);
    }

    return _buildSetupScreen(context, practiceState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SETUP SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSetupScreen(BuildContext context, PracticeState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Mode')),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Spacings.xl),
              decoration: BoxDecoration(
                gradient: AppColors.coolGradient,
                borderRadius: BorderRadius.circular(Spacings.lgRadius),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    size: Spacings.xlIcon,
                    color: Colors.white,
                  ),
                  const SizedBox(width: Spacings.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice Session',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          'Configure your practice session below',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Spacings.sectionGap,

            // Subject selector
            _buildSectionTitle(context, 'Subject'),
            const SizedBox(height: Spacings.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(
                hintText: 'Select a subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'mathematics', child: Text('Mathematics')),
                DropdownMenuItem(value: 'english', child: Text('English')),
                DropdownMenuItem(value: 'biology', child: Text('Biology')),
                DropdownMenuItem(value: 'physics', child: Text('Physics')),
                DropdownMenuItem(value: 'chemistry', child: Text('Chemistry')),
              ],
              onChanged: (value) {
                setState(() => _selectedSubject = value);
              },
            ),
            Spacings.sectionGap,

            // Topic selector
            _buildSectionTitle(context, 'Topic'),
            const SizedBox(height: Spacings.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedTopic,
              decoration: const InputDecoration(
                hintText: 'Select a topic (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'algebra', child: Text('Algebra')),
                DropdownMenuItem(value: 'geometry', child: Text('Geometry')),
                DropdownMenuItem(value: 'calculus', child: Text('Calculus')),
              ],
              onChanged: (value) {
                setState(() => _selectedTopic = value);
              },
            ),
            Spacings.sectionGap,

            // Difficulty selector
            _buildSectionTitle(context, 'Difficulty'),
            const SizedBox(height: Spacings.sm),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'easy', label: Text('Easy')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'hard', label: Text('Hard')),
              ],
              selected: {_selectedDifficulty},
              onSelectionChanged: (selection) {
                setState(() => _selectedDifficulty = selection.first);
              },
            ),
            Spacings.sectionGap,

            // Mode toggle
            _buildSectionTitle(context, 'Mode'),
            const SizedBox(height: Spacings.sm),
            SegmentedButton<PracticeMode>(
              segments: const [
                ButtonSegment(
                  value: PracticeMode.untimed,
                  label: Text('Untimed'),
                  icon: Icon(Icons.timer_off_outlined, size: 18),
                ),
                ButtonSegment(
                  value: PracticeMode.timed,
                  label: Text('Timed'),
                  icon: Icon(Icons.timer_outlined, size: 18),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (selection) {
                setState(() => _selectedMode = selection.first);
              },
            ),
            if (_selectedMode == PracticeMode.timed) ...[
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Slider(
                      value: _timeLimitMin.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_timeLimitMin min',
                      onChanged: (value) {
                        setState(() => _timeLimitMin = value.toInt());
                      },
                    ),
                  ),
                  Text(
                    '$_timeLimitMin min',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
            ],
            Spacings.sectionGap,

            // Question count
            _buildSectionTitle(context, 'Number of Questions'),
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _questionCount,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${_questionCount.toInt()}',
                    onChanged: (value) {
                      setState(() => _questionCount = value);
                    },
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Text(
                  '${_questionCount.toInt()}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ],
            ),
            Spacings.sectionGap,

            // Start button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isLoading
                    ? null
                    : _startSession,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Practice'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: Spacings.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SESSION SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSessionScreen(BuildContext context, PracticeState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final session = state.currentSession!;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.subjectName ?? 'Practice'),
        actions: [
          // Timer display for timed mode
          if (state.isTimedMode && state.remainingTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: state.remainingTime!.inMinutes < 5
                        ? AppColors.error.withValues(alpha: 0.1)
                        : cs.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: state.remainingTime!.inMinutes < 5
                            ? AppColors.error
                            : cs.primary,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        _formatDuration(state.remainingTime!),
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: state.remainingTime!.inMinutes < 5
                              ? AppColors.error
                              : cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showAbandonDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: state.totalQuestions > 0
                ? (state.currentQuestionIndex + 1) / state.totalQuestions
                : 0,
          ),

          // Question navigator dots
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  state.totalQuestions,
                  (index) {
                    final isAnswered = index < state.answeredCount;
                    final isCurrent =
                        index == state.currentQuestionIndex;
                    return GestureDetector(
                      onTap: () {
                        // Navigate to question
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(
                          horizontal: Spacings.xs,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? cs.primary
                              : isAnswered
                                  ? AppColors.success
                                  : cs.surfaceContainerHighest,
                          border: isCurrent
                              ? null
                              : Border.all(
                                  color: cs.outlineVariant,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: tt.labelSmall?.copyWith(
                              color: isCurrent
                                  ? cs.onPrimary
                                  : isAnswered
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Question content area
          Expanded(
            child: SingleChildScrollView(
              padding: Spacings.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${state.currentQuestionIndex + 1} of ${state.totalQuestions}',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacings.lg),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(Spacings.lgRadius),
                    ),
                    child: Text(
                      'This is a sample question for the practice session. The actual question content would be loaded from the backend based on the selected subject and topic.',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Spacings.sectionGap,

                  // Answer area (multiple choice example)
                  _buildSectionTitle(context, 'Your Answer'),
                  const SizedBox(height: Spacings.sm),
                  ...['Option A', 'Option B', 'Option C', 'Option D']
                      .map((option) => _AnswerOption(
                            label: option,
                            isSelected: false,
                            onTap: () {},
                          ),),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isFirstQuestion
                          ? null
                          : () => ref
                              .read(practiceProvider.notifier)
                              .previousQuestion(),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.isLastQuestion
                          ? () => _completeSession()
                          : () => ref
                              .read(practiceProvider.notifier)
                              .nextQuestion(),
                      child: Text(
                        state.isLastQuestion ? 'Finish' : 'Next',
                      ),
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

  // ═══════════════════════════════════════════════════════════════════════
  // RESULTS SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResultsScreen(BuildContext context, PracticeState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final session = state.currentSession!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score display
            Center(
              child: Column(
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: session.scorePct >= 70
                          ? AppColors.coolGradient
                          : AppColors.warmGradient,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${session.scorePct.toStringAsFixed(0)}%',
                            style: tt.displaySmall?.copyWith(
                              fontWeight: AppTypography.wBold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Score',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                  Text(
                    session.scorePct >= 70
                        ? 'Great Job! 🎉'
                        : session.scorePct >= 50
                            ? 'Good Effort! 💪'
                            : 'Keep Practicing! 📚',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Spacings.sectionGap,

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _ResultStatCard(
                    label: 'Correct',
                    value: '${session.correctCount}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: _ResultStatCard(
                    label: 'Wrong',
                    value:
                        '${session.totalQuestions - session.correctCount}',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: _ResultStatCard(
                    label: 'Total',
                    value: '${session.totalQuestions}',
                    icon: Icons.quiz_outlined,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            Spacings.sectionGap,

            // Question review
            _buildSectionTitle(context, 'Question Review'),
            const SizedBox(height: Spacings.sm),
            ...state.currentAnswers.map(
              (answer) => _QuestionReviewCard(answer: answer),
            ),
            Spacings.sectionGap,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(practiceProvider.notifier).abandonSession();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(practiceProvider.notifier).abandonSession();
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  void _startSession() {
    ref.read(practiceProvider.notifier).createSession(
      subjectId: _selectedSubject,
      topicId: _selectedTopic,
      difficulty: _selectedDifficulty,
      mode: _selectedMode,
      timeLimitSec: _selectedMode == PracticeMode.timed
          ? _timeLimitMin * 60
          : null,
      questionCount: _questionCount.toInt(),
    );
  }

  void _completeSession() {
    ref.read(practiceProvider.notifier).completeSession();
  }

  void _showAbandonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Session?'),
        content: const Text(
          'Are you sure you want to abandon this practice session? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(practiceProvider.notifier).abandonSession();
            },
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        child: Container(
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            color: isSelected
                ? cs.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  label,
                  style: tt.bodyMedium?.copyWith(
                    color: isSelected ? cs.primary : cs.onSurface,
                    fontWeight: isSelected
                        ? AppTypography.wSemiBold
                        : AppTypography.wRegular,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStatCard extends StatelessWidget {
  const _ResultStatCard({
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
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: Spacings.lgIcon, color: color),
          const SizedBox(height: Spacings.sm),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.answer});

  final PracticeAnswerEntity answer;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isCorrect = answer.isCorrect == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCorrect ? Icons.check_rounded : Icons.close_rounded,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: Spacings.mdIcon,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer.questionText ?? 'Question ${answer.questionId}',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (answer.explanation != null) ...[
                    const SizedBox(height: Spacings.xs),
                    Text(
                      answer.explanation!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${answer.timeSpentSec}s',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
