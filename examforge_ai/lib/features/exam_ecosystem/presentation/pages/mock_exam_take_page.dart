import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';

/// CBT-style mock exam taking page with timer and question navigator.
///
/// Features:
/// - Countdown timer with visual indicator
/// - Question display with answer options
/// - Question navigator sidebar/drawer
/// - Answer tracking (answered, flagged, current)
/// - Submit confirmation dialog
/// - Auto-submit when time runs out
class MockExamTakePage extends ConsumerStatefulWidget {
  const MockExamTakePage({
    super.key,
    this.mockExam,
    this.attempt,
    this.examId,
  });

  /// Full mock exam object. If null, will be loaded from [examId].
  final MockExam? mockExam;

  /// Full attempt object. If null, will be loaded from [examId].
  final MockExamAttempt? attempt;

  /// Exam ID used to load mock exam and attempt when the full objects are not provided.
  final String? examId;

  @override
  ConsumerState<MockExamTakePage> createState() => _MockExamTakePageState();
}

class _MockExamTakePageState extends ConsumerState<MockExamTakePage> {
  late Timer _timer;
  late int _remainingSeconds;
  int _currentQuestionIndex = 0;
  final Map<int, String> _answers = {};
  final Set<int> _flaggedQuestions = {};

  // Simulated question list for the mock exam
  late List<_MockQuestion> _questions;

  /// The resolved mock exam, either from widget or loaded from provider.
  MockExam? _loadedMockExam;
  MockExamAttempt? _loadedAttempt;

  /// Get the effective mock exam.
  MockExam get _effectiveMockExam => widget.mockExam ?? _loadedMockExam!;
  MockExamAttempt get _effectiveAttempt => widget.attempt ?? _loadedAttempt!;

  @override
  void initState() {
    super.initState();
    if (widget.mockExam != null && widget.attempt != null) {
      _remainingSeconds = _effectiveMockExam.durationMinutes * 60;
      _questions = _generateQuestions(_effectiveMockExam.totalQuestions);
      _startTimer();
    } else if (widget.examId != null) {
      // Load the exam data from the provider using examId.
      Future.microtask(() {
        ref.read(examEcosystemProvider.notifier).loadAll();
      });
    }
  }

  List<_MockQuestion> _generateQuestions(int count) {
    return List.generate(count, (index) {
      return _MockQuestion(
        number: index + 1,
        text: 'Question ${index + 1}: This is a sample question for the ${_effectiveMockExam.title} exam. Select the correct answer from the options below.',
        options: [
          'Option A - First possible answer',
          'Option B - Second possible answer',
          'Option C - Third possible answer',
          'Option D - Fourth possible answer',
        ],
        marksAllocated: (_effectiveMockExam.totalMarks / count).round(),
      );
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer.cancel();
        _autoSubmit();
      }
    });
  }

  void _autoSubmit() {
    _submitExam(isTimedOut: true);
  }

  Future<void> _submitExam({bool isTimedOut = false}) async {
    _timer.cancel();

    final shouldSubmit = isTimedOut ||
        (await _showSubmitConfirmation(isTimedOut: isTimedOut) ?? false);

    if (shouldSubmit == true) {
      final timeTaken =
          _effectiveMockExam.durationMinutes * 60 - _remainingSeconds;

      final repository = ref.read(examEcosystemRepositoryProvider);
      final result = await repository.submitMockExamAttempt(
        attemptId: _effectiveAttempt.id,
        answers: _answers.map((k, v) => MapEntry(k.toString(), v)),
        timeTakenSeconds: timeTaken,
      );

      if (mounted) {
        result.fold(
          onSuccess: (attempt) {
            Navigator.of(context).pop(attempt);
          },
          onFailure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit exam')),
            );
          },
        );
      }
    }
  }

  Future<bool?> _showSubmitConfirmation({required bool isTimedOut}) {
    final answeredCount = _answers.length;
    final totalCount = _questions.length;
    final unansweredCount = totalCount - answeredCount;

    return showDialog<bool>(
      context: context,
      barrierDismissible: !isTimedOut,
      builder: (context) {
        return AlertDialog(
          title: Text(isTimedOut ? 'Time is Up!' : 'Submit Exam?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTimedOut)
                const Text('Your time has run out. Your answers will be '
                    'automatically submitted.')
              else
                const Text('Are you sure you want to submit?'),
              const SizedBox(height: Spacings.md),
              _StatRow(
                label: 'Answered',
                value: '$answeredCount / $totalCount',
                color: AppColors.success,
              ),
              if (unansweredCount > 0)
                _StatRow(
                  label: 'Unanswered',
                  value: '$unansweredCount',
                  color: AppColors.error,
                ),
              if (_flaggedQuestions.isNotEmpty)
                _StatRow(
                  label: 'Flagged',
                  value: '${_flaggedQuestions.length}',
                  color: AppColors.warning,
                ),
            ],
          ),
          actions: [
            if (!isTimedOut)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue Exam'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final currentQuestion = _questions[_currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _showLeaveConfirmation(context);
        if (shouldLeave == true && mounted) {
          _timer.cancel();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_effectiveMockExam.title),
          centerTitle: true,
          actions: [
            // Question navigator toggle
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () => _showQuestionNavigator(context),
              tooltip: 'Question Navigator',
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── Timer Bar ────────────────────────────────────────────
            _buildTimerBar(context),

            // ─── Progress Bar ─────────────────────────────────────────
            LinearProgressIndicator(
              value: _answers.length / _questions.length,
              backgroundColor: cs.surfaceContainerHighest,
              minHeight: 3,
            ),

            // ─── Question Content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: Spacings.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question header
                    Row(
                      children: [
                        Text(
                          'Question ${currentQuestion.number}',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: AppColors.info,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _flaggedQuestions.contains(_currentQuestionIndex)
                                ? Icons.flag_rounded
                                : Icons.flag_outlined,
                            color: _flaggedQuestions
                                    .contains(_currentQuestionIndex)
                                ? AppColors.warning
                                : cs.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_flaggedQuestions
                                  .contains(_currentQuestionIndex)) {
                                _flaggedQuestions.remove(_currentQuestionIndex);
                              } else {
                                _flaggedQuestions.add(_currentQuestionIndex);
                              }
                            });
                          },
                          tooltip: 'Flag question',
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.sm),

                    // Question text
                    Container(
                      width: double.infinity,
                      padding: Spacings.paddingCard,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                      child: Text(
                        currentQuestion.text,
                        style: tt.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: Spacings.lg),

                    // Answer options
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      final optionIndex = entry.key;
                      final optionText = entry.value;
                      final optionLetter =
                          String.fromCharCode(65 + optionIndex);
                      final isSelected =
                          _answers[_currentQuestionIndex] == optionLetter;

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: Spacings.md),
                        child: Material(
                          color: isSelected
                              ? AppColors.info.withValues(alpha: 0.1)
                              : cs.surfaceContainerLow,
                          borderRadius: Spacings.borderRadiusMd,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _answers[_currentQuestionIndex] = optionLetter;
                              });
                            },
                            borderRadius: Spacings.borderRadiusMd,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(Spacings.md),
                              decoration: BoxDecoration(
                                borderRadius: Spacings.borderRadiusMd,
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.info,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: cs.outline.withValues(alpha: 0.3,
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.info
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.info
                                            : cs.outline,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        optionLetter,
                                        style: tt.labelMedium?.copyWith(
                                          fontWeight: AppTypography.wBold,
                                          color: isSelected
                                              ? Colors.white
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: Spacings.md),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: tt.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? AppColors.info
                                            : cs.onSurface,
                                        fontWeight: isSelected
                                            ? AppTypography.wMedium
                                            : AppTypography.wRegular,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ─── Bottom Navigation ────────────────────────────────────
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isLow = _remainingSeconds < 300; // < 5 min
    final isCritical = _remainingSeconds < 60; // < 1 min

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.error.withValues(alpha: 0.1)
            : isLow
                ? AppColors.warning.withValues(alpha: 0.1)
                : cs.surfaceContainerLow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCritical
                ? Icons.timer_off_rounded
                : isLow
                    ? Icons.timer_rounded
                    : Icons.schedule_rounded,
            size: 18,
            color: isCritical
                ? AppColors.error
                : isLow
                    ? AppColors.warning
                    : cs.onSurfaceVariant,
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: isCritical
                  ? AppColors.error
                  : isLow
                      ? AppColors.warning
                      : cs.onSurface,
            ),
          ),
          const SizedBox(width: Spacings.md),
          Text(
            '${_answers.length}/${_questions.length} answered',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _currentQuestionIndex > 0
                    ? () {
                        setState(() => _currentQuestionIndex--);
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(width: Spacings.sm),

            // Submit button (only on last question)
            if (_currentQuestionIndex == _questions.length - 1)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _submitExam(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Submit'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              )
            else
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _currentQuestionIndex++);
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Next'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuestionNavigator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: Spacings.paddingCard,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question Navigator',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.wBold,
                            ),
                      ),
                      Row(
                        children: [
                          const _LegendDot(color: AppColors.success, label: 'Answered'),
                          const SizedBox(width: Spacings.sm),
                          const _LegendDot(color: AppColors.warning, label: 'Flagged'),
                          const SizedBox(width: Spacings.sm),
                          _LegendDot(
                            color: Theme.of(context).colorScheme.outline,
                            label: 'Unanswered',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: Spacings.paddingCard,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: Spacings.sm,
                      crossAxisSpacing: Spacings.sm,
                    ),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final isAnswered = _answers.containsKey(index);
                      final isFlagged = _flaggedQuestions.contains(index);
                      final isCurrent = index == _currentQuestionIndex;

                      Color bgColor;
                      Color textColor;
                      if (isCurrent) {
                        bgColor = AppColors.info;
                        textColor = Colors.white;
                      } else if (isFlagged) {
                        bgColor = AppColors.warning.withValues(alpha: 0.2);
                        textColor = AppColors.warning;
                      } else if (isAnswered) {
                        bgColor = AppColors.success.withValues(alpha: 0.2);
                        textColor = AppColors.success;
                      } else {
                        bgColor = Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest;
                        textColor =
                            Theme.of(context).colorScheme.onSurfaceVariant;
                      }

                      return InkWell(
                        onTap: () {
                          setState(() => _currentQuestionIndex = index);
                          Navigator.of(context).pop();
                        },
                        borderRadius: Spacings.borderRadiusMd,
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: Spacings.borderRadiusMd,
                            border: isCurrent
                                ? Border.all(color: AppColors.info, width: 2)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: AppTypography.wSemiBold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              if (isFlagged && !isCurrent)
                                const Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Icon(
                                    Icons.flag_rounded,
                                    size: 10,
                                    color: AppColors.warning,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showLeaveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Exam?'),
          content: const Text(
            'Your progress will be saved, but the timer will '
            'continue running. Are you sure you want to leave?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Helper Classes ────────────────────────────────────────────────

class _MockQuestion {
  const _MockQuestion({
    required this.number,
    required this.text,
    required this.options,
    required this.marksAllocated,
  });

  final int number;
  final String text;
  final List<String> options;
  final int marksAllocated;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: AppTypography.wSemiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
