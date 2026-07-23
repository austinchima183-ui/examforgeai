import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/cbt/anti_cheat_service.dart';
import '../../../../services/cbt/auto_save_service.dart';
import '../../../../services/cbt/exam_timer_service.dart';
import '../../../../services/cbt/session_recovery_service.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';
import '../../domain/usecases/save_answer_usecase.dart';
import '../../domain/usecases/start_exam_attempt_usecase.dart';
import '../../domain/usecases/submit_exam_attempt_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TAKER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student exam-taking feature.
///
/// This is the most critical state in the CBT engine. It tracks the
/// exam being taken, the current attempt, all answers, flagged questions,
/// timer state, connection status, and violation tracking.
class ExamTakerState {
  const ExamTakerState({
    this.exam,
    this.attempt,
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.flaggedQuestions = const {},
    this.timeRemaining = Duration.zero,
    this.isSubmitting = false,
    this.isPaused = false,
    this.connectionStatus = 'connected',
    this.error,
    this.isAutoSaving = false,
    this.lastAutoSaveTime,
    this.violationCount = 0,
    this.isDisqualified = false,
    this.showSubmitConfirmation = false,
  });

  /// The exam being taken.
  final ExamEntity? exam;

  /// The current attempt.
  final ExamAttemptEntity? attempt;

  /// Index of the currently viewed question.
  final int currentQuestionIndex;

  /// Map of questionId → answer data.
  final Map<String, Map<String, dynamic>> answers;

  /// Map of questionId → isFlagged.
  final Map<String, bool> flaggedQuestions;

  /// Time remaining in the exam.
  final Duration timeRemaining;

  /// Whether a submit operation is in progress.
  final bool isSubmitting;

  /// Whether the exam is currently paused.
  final bool isPaused;

  /// Connection status: 'connected', 'disconnected', 'reconnecting'.
  final String connectionStatus;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether an auto-save is in progress.
  final bool isAutoSaving;

  /// Time of the last successful auto-save.
  final DateTime? lastAutoSaveTime;

  /// Number of monitoring violations detected.
  final int violationCount;

  /// Whether the student has been disqualified.
  final bool isDisqualified;

  /// Whether the submit confirmation dialog is visible.
  final bool showSubmitConfirmation;

  // ── Convenience getters ──────────────────────────────────────────────

  /// Total number of questions in the exam.
  int get totalQuestions => exam?.questions.length ?? 0;

  /// Number of questions with non-empty answers.
  int get answeredCount =>
      answers.values.where((a) => a.isNotEmpty).length;

  /// Number of flagged questions.
  int get flaggedCount =>
      flaggedQuestions.values.where((f) => f).length;

  /// Progress as a percentage (0.0 to 1.0).
  double get progressPercentage =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  /// The currently viewed question entity.
  ExamQuestionEntity? get currentQuestion {
    if (exam == null) return null;
    if (currentQuestionIndex < 0 ||
        currentQuestionIndex >= exam!.questions.length) {
      return null;
    }
    return exam!.questions[currentQuestionIndex];
  }

  /// Whether this is the first question.
  bool get isFirstQuestion => currentQuestionIndex == 0;

  /// Whether this is the last question.
  bool get isLastQuestion =>
      totalQuestions > 0 && currentQuestionIndex >= totalQuestions - 1;

  /// The answer for the current question, or `null`.
  Map<String, dynamic>? get currentAnswer =>
      answers[currentQuestion?.questionId];

  /// Whether the current question is flagged.
  bool get isCurrentFlagged =>
      flaggedQuestions[currentQuestion?.questionId] ?? false;

  /// Whether the exam is actively being taken.
  bool get isExamActive =>
      exam != null &&
      attempt != null &&
      attempt!.status == AttemptStatus.inProgress &&
      !isDisqualified;

  /// Whether the exam has been completed (submitted or timed out).
  bool get isExamCompleted =>
      attempt != null && attempt!.status.isTerminal;

  /// Whether the timer is in the warning zone (5 minutes or less).
  bool get isTimeWarning =>
      timeRemaining.inMinutes <= 5 && timeRemaining.inSeconds > 0;

  /// Whether the time has expired.
  bool get isTimeUp => timeRemaining.inSeconds <= 0;

  /// The attempt ID, or `null`.
  String? get attemptId => attempt?.id;

  /// The exam ID, or `null`.
  String? get examId => exam?.id;

  // ── copyWith ─────────────────────────────────────────────────────────

  ExamTakerState copyWith({
    ExamEntity? exam,
    ExamAttemptEntity? attempt,
    int? currentQuestionIndex,
    Map<String, Map<String, dynamic>>? answers,
    Map<String, bool>? flaggedQuestions,
    Duration? timeRemaining,
    bool? isSubmitting,
    bool? isPaused,
    String? connectionStatus,
    String? error,
    bool? isAutoSaving,
    DateTime? lastAutoSaveTime,
    int? violationCount,
    bool? isDisqualified,
    bool? showSubmitConfirmation,
  }) {
    return ExamTakerState(
      exam: exam ?? this.exam,
      attempt: attempt ?? this.attempt,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      flaggedQuestions: flaggedQuestions ?? this.flaggedQuestions,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isPaused: isPaused ?? this.isPaused,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      error: error,
      isAutoSaving: isAutoSaving ?? this.isAutoSaving,
      lastAutoSaveTime: lastAutoSaveTime ?? this.lastAutoSaveTime,
      violationCount: violationCount ?? this.violationCount,
      isDisqualified: isDisqualified ?? this.isDisqualified,
      showSubmitConfirmation:
          showSubmitConfirmation ?? this.showSubmitConfirmation,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EXAM TAKER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student exam-taking state.
///
/// This is the most critical notifier in the CBT engine. It orchestrates
/// exam start, navigation, answer saving, flagging, timer management,
/// auto-save, anti-cheat monitoring, and exam submission.
class ExamTakerNotifier extends StateNotifier<ExamTakerState> {
  ExamTakerNotifier({
    required StartExamAttemptUseCase startExamAttemptUseCase,
    required SaveAnswerUseCase saveAnswerUseCase,
    required SubmitExamAttemptUseCase submitExamAttemptUseCase,
    required CbtRepository cbtRepository,
    required AutoSaveService autoSaveService,
    required ExamTimerService examTimerService,
    required SessionRecoveryService sessionRecoveryService,
    required AntiCheatService antiCheatService,
  })  : _startExamAttemptUseCase = startExamAttemptUseCase,
        _saveAnswerUseCase = saveAnswerUseCase,
        _submitExamAttemptUseCase = submitExamAttemptUseCase,
        _cbtRepository = cbtRepository,
        _autoSaveService = autoSaveService,
        _examTimerService = examTimerService,
        _sessionRecoveryService = sessionRecoveryService,
        _antiCheatService = antiCheatService,
        super(const ExamTakerState());

  final StartExamAttemptUseCase _startExamAttemptUseCase;
  final SaveAnswerUseCase _saveAnswerUseCase;
  final SubmitExamAttemptUseCase _submitExamAttemptUseCase;
  final CbtRepository _cbtRepository;
  final AutoSaveService _autoSaveService;
  final ExamTimerService _examTimerService;
  final SessionRecoveryService _sessionRecoveryService;
  final AntiCheatService _antiCheatService;

  StreamSubscription? _sessionSubscription;

  // ═══════════════════════════════════════════════════════════════════════
  // START EXAM
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts an exam attempt for the given [examId].
  ///
  /// Validates that the exam is available, creates an attempt record,
  /// loads the exam with details, starts the timer, and enables
  /// auto-save.
  Future<void> startExam(String examId) async {
    state = state.copyWith(
      isSubmitting: false,
      error: null,
    );

    // Start the attempt
    final attemptResult = await _startExamAttemptUseCase(
      StartAttemptParams(examId: examId),
    );

    attemptResult.fold(
      onSuccess: (attempt) async {
        // Load the full exam details
        final examResult =
            await _cbtRepository.getExamWithDetails(examId);

        examResult.fold(
          onSuccess: (exam) {
            state = state.copyWith(
              exam: exam,
              attempt: attempt,
              currentQuestionIndex: 0,
              timeRemaining: Duration(minutes: exam.timeLimitMinutes),
              connectionStatus: 'connected',
              error: null,
            );

            // Start the exam timer
            _startTimer();

            // Start auto-save
            _startAutoSave(attempt.id);

            // Save initial session state for recovery
            _saveSessionState();

            AppLogger.info(
              'Exam started: ${exam.id}, attempt: ${attempt.id}',
            );
          },
          onFailure: (failure) {
            state = state.copyWith(
              error: _mapFailureToMessage(failure),
            );
            AppLogger.warning(
              'Failed to load exam details: $failure',
            );
          },
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to start exam: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Navigates to a specific question by [index].
  void goToQuestion(int index) {
    if (index < 0 || index >= state.totalQuestions) return;
    state = state.copyWith(currentQuestionIndex: index);
    _saveSessionState();
  }

  /// Navigates to the next question.
  void nextQuestion() {
    if (!state.isLastQuestion) {
      goToQuestion(state.currentQuestionIndex + 1);
    }
  }

  /// Navigates to the previous question.
  void previousQuestion() {
    if (!state.isFirstQuestion) {
      goToQuestion(state.currentQuestionIndex - 1);
    }
  }

  /// Jumps to the next flagged question.
  void goToFlaggedQuestion() {
    final flaggedIds = state.flaggedQuestions.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (flaggedIds.isEmpty) return;

    // Find the next flagged question after the current one
    final currentId = state.currentQuestion?.questionId;
    var startIndex = 0;

    if (currentId != null) {
      final currentIndex =
          flaggedIds.indexOf(currentId);
      if (currentIndex >= 0 && currentIndex < flaggedIds.length - 1) {
        startIndex = currentIndex + 1;
      }
    }

    // Find the question index in the exam
    final targetId = flaggedIds[startIndex];
    final targetIndex = state.exam?.questions
            .indexWhere((q) => q.questionId == targetId) ??
        -1;

    if (targetIndex >= 0) {
      goToQuestion(targetIndex);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANSWER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Saves the current answer locally and remotely.
  void saveCurrentAnswer(Map<String, dynamic> answerData) {
    final questionId = state.currentQuestion?.questionId;
    if (questionId == null || state.attemptId == null) return;

    // Save locally immediately
    final updatedAnswers =
        Map<String, Map<String, dynamic>>.from(state.answers);
    updatedAnswers[questionId] = answerData;
    state = state.copyWith(answers: updatedAnswers);

    // Save remotely (fire-and-forget for responsiveness)
    _saveAnswerRemotely(questionId, answerData);

    _saveSessionState();
  }

  Future<void> _saveAnswerRemotely(
    String questionId,
    Map<String, dynamic> answerData,
  ) async {
    if (state.attemptId == null) return;

    final result = await _saveAnswerUseCase(
      SaveAnswerParams(
        attemptId: state.attemptId!,
        questionId: questionId,
        answerData: answerData,
      ),
    );

    result.fold(
      onSuccess: (_) {
        AppLogger.debug('Answer saved: $questionId');
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to save answer: $failure');
        // Answer is still saved locally; remote save will be retried
        // by auto-save.
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FLAGGING
  // ═══════════════════════════════════════════════════════════════════════

  /// Toggles the flag status of the current question.
  void flagCurrentQuestion(bool isFlagged) {
    final questionId = state.currentQuestion?.questionId;
    if (questionId == null || state.attemptId == null) return;

    final updatedFlags = Map<String, bool>.from(state.flaggedQuestions);
    updatedFlags[questionId] = isFlagged;
    state = state.copyWith(flaggedQuestions: updatedFlags);

    // Save flag remotely
    _cbtRepository.flagQuestion(
      state.attemptId!,
      questionId,
      isFlagged,
    );

    _saveSessionState();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBMIT EXAM
  // ═══════════════════════════════════════════════════════════════════════

  /// Shows the submit confirmation dialog.
  void showSubmitDialog() {
    state = state.copyWith(showSubmitConfirmation: true);
  }

  /// Hides the submit confirmation dialog.
  void hideSubmitDialog() {
    state = state.copyWith(showSubmitConfirmation: false);
  }

  /// Submits the exam with confirmation.
  Future<void> submitExam() async {
    if (state.isSubmitting || state.attemptId == null) return;

    state = state.copyWith(
      isSubmitting: true,
      showSubmitConfirmation: false,
      error: null,
    );

    // Force save any pending answers before submitting
    await _autoSaveService.forceSave();

    final result = await _submitExamAttemptUseCase(
      SubmitAttemptParams(
        attemptId: state.attemptId!,
        submissionType: SubmissionType.manual,
      ),
    );

    result.fold(
      onSuccess: (examResult) {
        _cleanupAfterSubmit();
        state = state.copyWith(
          isSubmitting: false,
          attempt: state.attempt?.copyWith(
            status: AttemptStatus.submitted,
            submittedAt: DateTime.now(),
            submissionType: SubmissionType.manual,
          ),
          timeRemaining: Duration.zero,
          error: null,
        );
        AppLogger.info('Exam submitted: ${state.attemptId}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to submit exam: $failure');
      },
    );
  }

  /// Auto-submits the exam when time expires.
  Future<void> autoSubmit() async {
    if (state.attemptId == null) return;

    state = state.copyWith(isSubmitting: true, error: null);

    await _autoSaveService.forceSave();

    final result = await _submitExamAttemptUseCase(
      SubmitAttemptParams(
        attemptId: state.attemptId!,
        submissionType: SubmissionType.autoSubmit,
      ),
    );

    result.fold(
      onSuccess: (_) {
        _cleanupAfterSubmit();
        state = state.copyWith(
          isSubmitting: false,
          attempt: state.attempt?.copyWith(
            status: AttemptStatus.autoSubmitted,
            submittedAt: DateTime.now(),
            submissionType: SubmissionType.autoSubmit,
          ),
          timeRemaining: Duration.zero,
        );
        AppLogger.info('Exam auto-submitted: ${state.attemptId}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to auto-submit: $failure');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TIMER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Updates the time remaining (called by the timer service).
  void updateTimer(Duration remaining) {
    state = state.copyWith(timeRemaining: remaining);
  }

  void _startTimer() {
    _examTimerService.start(
      duration: state.timeRemaining,
      onTick: () {
        updateTimer(_examTimerService.remaining);
      },
      onTimeUp: () {
        updateTimer(Duration.zero);
        autoSubmit();
      },
      onWarning: () {
        AppLogger.info('Exam time warning: 5 minutes remaining');
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONNECTION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Handles a change in connection status.
  void handleConnectionChange(String status) {
    state = state.copyWith(connectionStatus: status);

    if (status == 'disconnected') {
      AppLogger.warning('Connection lost during exam');
    } else if (status == 'reconnecting') {
      AppLogger.info('Reconnecting...');
    } else if (status == 'connected') {
      AppLogger.info('Connection restored');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VIOLATION / ANTI-CHEAT HANDLING
  // ═══════════════════════════════════════════════════════════════════════

  /// Handles a monitoring event (violation).
  void handleViolation(MonitoringLogEntity event) {
    final newCount = state.violationCount + 1;
    state = state.copyWith(violationCount: newCount);

    // Check if disqualification is warranted
    if (event.severity == 'critical') {
      final shouldDq = _antiCheatService.shouldDisqualify(
        newCount, // approximate tab switches
        0, // focus lost
        newCount, // approximate copy attempts
      );

      if (shouldDq) {
        state = state.copyWith(isDisqualified: true);
        AppLogger.warning(
          'Student disqualified after $newCount violations',
        );
      }
    }

    // Log the event to the backend
    _cbtRepository.logMonitoringEvent(event);

    AppLogger.warning(
      'Violation detected: ${event.eventType.label} '
      '(severity: ${event.severity})',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SESSION RECOVERY
  // ═══════════════════════════════════════════════════════════════════════

  /// Recovers an interrupted session.
  Future<void> recoverSession() async {
    if (state.attemptId == null) return;

    final sessionState =
        await _sessionRecoveryService.recoverSession(state.attemptId!);

    if (sessionState != null) {
      state = state.copyWith(
        currentQuestionIndex: sessionState.currentQuestionIndex,
        answers: sessionState.answers
            .map((key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map))),
        timeRemaining: sessionState.remainingTime,
      );

      // Update the timer with recovered remaining time
      _examTimerService.setRemaining(sessionState.remainingTime);

      AppLogger.info(
        'Session recovered: question ${sessionState.currentQuestionIndex}, '
        '${sessionState.remainingTime.inSeconds}s remaining',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAUSE / RESUME
  // ═══════════════════════════════════════════════════════════════════════

  /// Pauses the exam (if allowed by exam settings).
  Future<void> pauseExam() async {
    if (state.exam?.allowResume != true) return;

    _examTimerService.pause();
    _autoSaveService.stopAutoSave();
    state = state.copyWith(isPaused: true);
    _saveSessionState();

    AppLogger.info('Exam paused');
  }

  /// Resumes the exam after a pause.
  Future<void> resumeExam() async {
    if (!state.isPaused) return;

    _examTimerService.resume();
    if (state.attemptId != null) {
      _startAutoSave(state.attemptId!);
    }
    state = state.copyWith(isPaused: false);

    AppLogger.info('Exam resumed');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLEAR ERROR
  // ═══════════════════════════════════════════════════════════════════════

  /// Clears the current error message.
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISPOSE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _examTimerService.dispose();
    _autoSaveService.dispose();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Starts the auto-save service for the given attempt.
  void _startAutoSave(String attemptId) {
    _autoSaveService.startAutoSave(
      attemptId: attemptId,
      interval: const Duration(seconds: 30),
      onSave: (id, data) async {
        state = state.copyWith(isAutoSaving: true);
        final result = await _cbtRepository.autoSave(id, data);
        result.fold(
          onSuccess: (_) {
            state = state.copyWith(
              isAutoSaving: false,
              lastAutoSaveTime: DateTime.now(),
            );
          },
          onFailure: (_) {
            state = state.copyWith(isAutoSaving: false);
          },
        );
      },
      getData: () => {
        'answers': state.answers,
        'current_question_index': state.currentQuestionIndex,
        'flagged_questions': state.flaggedQuestions,
        'time_remaining_seconds': state.timeRemaining.inSeconds,
      },
    );
  }

  /// Saves the current session state for crash recovery.
  Future<void> _saveSessionState() async {
    if (state.attemptId == null || state.examId == null) return;

    await _sessionRecoveryService.saveSessionState(
      attemptId: state.attemptId!,
      examId: state.examId!,
      currentQuestionIndex: state.currentQuestionIndex,
      answers: {
        for (final entry in state.answers.entries)
          entry.key: entry.value,
      },
      remainingTime: state.timeRemaining,
    );
  }

  /// Cleans up services after exam submission.
  void _cleanupAfterSubmit() {
    _examTimerService.stop();
    _autoSaveService.stopAutoSave();
    if (state.attemptId != null) {
      _sessionRecoveryService.clearSession(state.attemptId!);
    }
  }

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}
