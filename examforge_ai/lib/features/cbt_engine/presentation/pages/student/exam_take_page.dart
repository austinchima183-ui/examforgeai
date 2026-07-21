import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../providers/exam_taker_provider.dart';
import '../widgets/exam_timer_widget.dart';
import '../widgets/question_navigator.dart';
import '../widgets/question_display_widget.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// EXAM TAKE PAGE (Student) - THE CRITICAL EXAM-TAKING INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Full-screen focused exam-taking interface for students.
///
/// Features:
/// - Top bar: Exam title, Timer, Connection status
/// - Left sidebar (desktop): QuestionNavigator
/// - Center: QuestionDisplayWidget
/// - Bottom bar: Previous, Next, Flag, Submit
/// - Mobile: Question navigator as bottom sheet
/// - Auto-save indicator
/// - Submit confirmation dialog
/// - Warning when time is running low
/// - Resume after disconnect dialog
/// - Anti-cheat event handlers
class ExamTakePage extends ConsumerStatefulWidget {
  const ExamTakePage({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<ExamTakePage> createState() => _ExamTakePageState();
}

class _ExamTakePageState extends ConsumerState<ExamTakePage>
    with WidgetsBindingObserver {
  bool _showNavigatorSheet = false;
  bool _hasShownTimeWarning = false;
  bool _hasShownCriticalWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start the exam
    Future.microtask(() {
      ref.read(examTakerProvider.notifier).startExam(widget.examId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anti-cheat: detect when app goes to background
    if (state == AppLifecycleState.paused) {
      final takerState = ref.read(examTakerProvider);
      if (takerState.isExamActive) {
        ref.read(examTakerProvider.notifier).handleViolation(
          MonitoringLogEntity(
            id: '',
            attemptId: takerState.attemptId ?? '',
            examId: takerState.examId ?? '',
            studentId: '',
            eventType: MonitoringEventType.tabSwitch,
            severity: 'warning',
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examTakerProvider);
    final exam = state.exam;
    final currentQuestion = state.currentQuestion;

    // Show time warning dialogs
    _checkTimeWarnings(state);

    // Handle exam completion
    if (state.isExamCompleted) {
      return _buildExamCompletedScreen(context, state);
    }

    // Handle disqualification
    if (state.isDisqualified) {
      return _buildDisqualifiedScreen(context, state);
    }

    // Loading state
    if (exam == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Spacings.lg),
              Text(
                'Loading exam…',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (state.error != null) ...[
                const SizedBox(height: Spacings.md),
                Text(
                  state.error!,
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ────────────────────────────────────────────────
            _buildTopBar(context, state, exam),

            // ── Main Content Area ──────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left sidebar: Question Navigator (desktop only)
                  if (context.isDesktop)
                    Padding(
                      padding: const EdgeInsets.all(Spacings.md),
                      child: QuestionNavigator(
                        totalQuestions: state.totalQuestions,
                        currentIndex: state.currentQuestionIndex,
                        answeredIndices: state.answers.entries
                            .where((e) => e.value.isNotEmpty)
                            .map((e) {
                          final idx = exam.questions
                              .indexWhere((q) => q.questionId == e.key);
                          return idx;
                        }).where((i) => i >= 0).toSet(),
                        flaggedIndices: state.flaggedQuestions.entries
                            .where((e) => e.value)
                            .map((e) {
                          final idx = exam.questions
                              .indexWhere((q) => q.questionId == e.key);
                          return idx;
                        }).where((i) => i >= 0).toSet(),
                        onQuestionTap: (index) {
                          ref.read(examTakerProvider.notifier).goToQuestion(index);
                        },
                        isDesktop: true,
                      ),
                    ),

                  // Center: Current question display
                  Expanded(
                    child: currentQuestion != null
                        ? QuestionDisplayWidget(
                            examQuestion: currentQuestion,
                            questionIndex: state.currentQuestionIndex,
                            totalQuestions: state.totalQuestions,
                            currentAnswer: state.currentAnswer,
                            isFlagged: state.isCurrentFlagged,
                            isEnabled: state.isExamActive,
                            onAnswerChanged: (data) {
                              ref.read(examTakerProvider.notifier).saveCurrentAnswer(data);
                            },
                            onFlagToggle: (isFlagged) {
                              ref.read(examTakerProvider.notifier).flagCurrentQuestion(isFlagged);
                            },
                            onClearAnswer: () {
                              final questionId = currentQuestion.questionId;
                              final updatedAnswers =
                                  Map<String, Map<String, dynamic>>.from(state.answers);
                              updatedAnswers.remove(questionId);
                              // Force rebuild with empty answer
                              ref.read(examTakerProvider.notifier).saveCurrentAnswer({});
                            },
                            onPrevious: () {
                              ref.read(examTakerProvider.notifier).previousQuestion();
                            },
                            onNext: () {
                              ref.read(examTakerProvider.notifier).nextQuestion();
                            },
                            isFirst: state.isFirstQuestion,
                            isLast: state.isLastQuestion,
                          )
                        : Center(
                            child: Text(
                              'No question to display',
                              style: tt.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // ── Bottom Bar ─────────────────────────────────────────────
            _buildBottomBar(context, state, exam),
          ],
        ),
      ),

      // ── Mobile: Question Navigator Bottom Sheet ─────────────────────
      bottomSheet: _showNavigatorSheet && context.isMobile
          ? QuestionNavigator(
              totalQuestions: state.totalQuestions,
              currentIndex: state.currentQuestionIndex,
              answeredIndices: state.answers.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((e) {
                final idx = exam?.questions
                        .indexWhere((q) => q.questionId == e.key) ??
                    -1;
                return idx;
              }).where((i) => i >= 0).toSet(),
              flaggedIndices: state.flaggedQuestions.entries
                  .where((e) => e.value)
                  .map((e) {
                final idx = exam?.questions
                        .indexWhere((q) => q.questionId == e.key) ??
                    -1;
                return idx;
              }).where((i) => i >= 0).toSet(),
              onQuestionTap: (index) {
                ref.read(examTakerProvider.notifier).goToQuestion(index);
                setState(() => _showNavigatorSheet = false);
              },
              isDesktop: false,
            )
          : null,
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, ExamTakerState state, ExamEntity exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Exam title (truncated on mobile)
          Expanded(
            child: Text(
              exam.title,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Auto-save indicator
          if (state.isAutoSaving)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'Saving…',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else if (state.lastAutoSaveTime != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: Text(
                'Saved',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.successOf(cs.brightness),
                ),
              ),
            ),

          // Timer
          ExamTimerWidget(
            timeRemaining: state.timeRemaining,
            totalDuration: Duration(minutes: exam.timeLimitMinutes),
            isPaused: state.isPaused,
            compact: true,
          ),

          const SizedBox(width: Spacings.sm),

          // Connection status
          _buildConnectionIndicator(context, state.connectionStatus),

          // Mobile: Navigator toggle button
          if (context.isMobile) ...[
            const SizedBox(width: Spacings.sm),
            IconButton(
              onPressed: () {
                setState(() => _showNavigatorSheet = !_showNavigatorSheet);
              },
              icon: Icon(
                Icons.grid_view_rounded,
                color: cs.onSurfaceVariant,
              ),
              tooltip: 'Question Navigator',
              style: IconButton.styleFrom(
                backgroundColor: _showNavigatorSheet
                    ? cs.primary.withValues(alpha: 0.1)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(BuildContext context, String status) {
    final cs = context.colorScheme;
    final color = switch (status) {
      'connected' => AppColors.successOf(cs.brightness),
      'disconnected' => AppColors.errorOf(cs.brightness),
      'reconnecting' => AppColors.warningOf(cs.brightness),
      _ => cs.onSurfaceVariant,
    };

    final label = switch (status) {
      'connected' => 'Connected',
      'disconnected' => 'Offline',
      'reconnecting' => 'Reconnecting…',
      _ => status,
    };

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
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
            if (!context.isMobile) ...[
              const SizedBox(width: Spacings.xs),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, ExamTakerState state, ExamEntity exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous
          OutlinedButton.icon(
            onPressed: state.isFirstQuestion ? null : () {
              ref.read(examTakerProvider.notifier).previousQuestion();
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
            ),
          ),

          const SizedBox(width: Spacings.sm),

          // Flag toggle
          IconButton.outlined(
            onPressed: () {
              ref.read(examTakerProvider.notifier).flagCurrentQuestion(!state.isCurrentFlagged);
            },
            icon: Icon(
              state.isCurrentFlagged
                  ? Icons.flag_rounded
                  : Icons.flag_outlined,
              color: state.isCurrentFlagged
                  ? AppColors.warningOf(cs.brightness)
                  : cs.onSurfaceVariant,
            ),
            tooltip: state.isCurrentFlagged ? 'Unflag' : 'Flag for Review',
          ),

          const Spacer(),

          // Question counter
          Text(
            '${state.currentQuestionIndex + 1} / ${state.totalQuestions}',
            style: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),

          const Spacer(),

          // Next
          FilledButton.icon(
            onPressed: state.isLastQuestion ? null : () {
              ref.read(examTakerProvider.notifier).nextQuestion();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Next'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.sm,
              ),
            ),
          ),

          const SizedBox(width: Spacings.sm),

          // Submit button
          AppButton(
            label: 'Submit',
            onPressed: () => _showSubmitConfirmation(context, state),
            variant: AppButtonVariant.elevated,
            size: AppButtonSize.small,
            icon: Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  // ── Submit Confirmation ───────────────────────────────────────────────

  Future<void> _showSubmitConfirmation(
    BuildContext context,
    ExamTakerState state,
  ) async {
    final unansweredCount =
        state.totalQuestions - state.answeredCount;
    final flaggedCount = state.flaggedCount;

    final confirmed = await AppDialog.showCustom<bool>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.send_rounded,
            size: Spacings.xlIcon,
            color: ctx.colorScheme.primary,
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            'Submit Exam?',
            style: ctx.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: ctx.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Are you sure you want to submit your exam? This action cannot be undone.',
            style: ctx.textTheme.bodyMedium?.copyWith(
              color: ctx.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.md),
          // Warnings
          if (unansweredCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: AppColors.warningOf(ctx.colorScheme.brightness)
                    .withValues(alpha: ctx.isDarkMode ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18,
                      color: AppColors.warningOf(ctx.colorScheme.brightness)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '$unansweredCount question${unansweredCount > 1 ? 's' : ''} unanswered',
                    style: ctx.textTheme.bodySmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: AppColors.warningOf(ctx.colorScheme.brightness),
                    ),
                  ),
                ],
              ),
            ),
          if (flaggedCount > 0) ...[
            const SizedBox(height: Spacings.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: AppColors.warningOf(ctx.colorScheme.brightness)
                    .withValues(alpha: ctx.isDarkMode ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded,
                      size: 18,
                      color: AppColors.warningOf(ctx.colorScheme.brightness)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '$flaggedCount question${flaggedCount > 1 ? 's' : ''} flagged for review',
                    style: ctx.textTheme.bodySmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: AppColors.warningOf(ctx.colorScheme.brightness),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacings.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(ctx).pop(false),
                variant: AppButtonVariant.text,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Submit Exam',
                onPressed: () => Navigator.of(ctx).pop(true),
                variant: AppButtonVariant.elevated,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(examTakerProvider.notifier).submitExam();
    }
  }

  // ── Time Warnings ─────────────────────────────────────────────────────

  void _checkTimeWarnings(ExamTakerState state) {
    if (state.timeRemaining.inMinutes == 5 &&
        !_hasShownTimeWarning &&
        state.timeRemaining.inSeconds > 0) {
      _hasShownTimeWarning = true;
      Future.microtask(() {
        if (mounted) {
          AppDialog.showInfo(
            context: context,
            title: 'Time Warning',
            message: 'You have less than 5 minutes remaining. Please review your answers.',
            dismissText: 'Continue',
          );
        }
      });
    }

    if (state.timeRemaining.inMinutes == 0 &&
        state.timeRemaining.inSeconds > 30 &&
        !_hasShownCriticalWarning) {
      _hasShownCriticalWarning = true;
      Future.microtask(() {
        if (mounted) {
          AppDialog.showInfo(
            context: context,
            title: 'Less Than 1 Minute!',
            message: 'Your exam will be auto-submitted when time runs out. Please save your current answer.',
            dismissText: 'OK',
          );
        }
      });
    }
  }

  // ── Exam Completed Screen ─────────────────────────────────────────────

  Widget _buildExamCompletedScreen(BuildContext context, ExamTakerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.successOf(cs.brightness)
                        .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: Spacings.xlIcon,
                    color: AppColors.successOf(cs.brightness),
                  ),
                ),
                const SizedBox(height: Spacings.xl),
                Text(
                  'Exam Submitted!',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  state.attempt?.submissionType?.label ?? 'Your exam has been submitted successfully.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.xl),
                AppButton(
                  label: 'View Results',
                  onPressed: () {
                    // Navigate to result view
                  },
                  variant: AppButtonVariant.elevated,
                  icon: Icons.bar_chart_rounded,
                ),
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Back to Exams',
                  onPressed: () => Navigator.of(context).pop(),
                  variant: AppButtonVariant.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Disqualified Screen ───────────────────────────────────────────────

  Widget _buildDisqualifiedScreen(BuildContext context, ExamTakerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.errorOf(cs.brightness)
                        .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.gpp_bad_rounded,
                    size: Spacings.xlIcon,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                ),
                const SizedBox(height: Spacings.xl),
                Text(
                  'Exam Disqualified',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  'Your exam has been disqualified due to suspicious activity. ${state.violationCount} violations were detected.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.xl),
                AppButton(
                  label: 'Contact Support',
                  onPressed: () {},
                  variant: AppButtonVariant.tonal,
                  icon: Icons.support_agent_rounded,
                ),
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Back to Exams',
                  onPressed: () => Navigator.of(context).pop(),
                  variant: AppButtonVariant.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
