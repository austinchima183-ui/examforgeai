import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Practice feature.
///
/// Tracks practice sessions, the currently active session with its
/// answers, navigation state, loading flags, and timer state for
/// timed practice mode.
class PracticeState {
  const PracticeState({
    this.sessions = const [],
    this.currentSession,
    this.currentAnswers = const [],
    this.currentQuestionIndex = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.hasMore = true,
    this.remainingTime,
    this.currentPage = 1,
  });

  /// All practice sessions for the current student.
  final List<PracticeSessionEntity> sessions;

  /// The currently selected/active practice session.
  final PracticeSessionEntity? currentSession;

  /// Answers for the current practice session.
  final List<PracticeAnswerEntity> currentAnswers;

  /// The index of the currently displayed question (0-based).
  final int currentQuestionIndex;

  /// Whether the initial session list load is in progress.
  final bool isLoading;

  /// Whether an answer submission is in progress.
  final bool isSubmitting;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether there are more session pages to load.
  final bool hasMore;

  /// Remaining time for timed practice sessions, or `null` for untimed.
  final Duration? remainingTime;

  /// Current page number for session pagination (1-based).
  // ignore: unused_field
  final int currentPage;

  /// Current page number for session pagination.

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSubmitting;

  /// Whether the current session is in timed mode.
  bool get isTimedMode =>
      currentSession?.mode == PracticeMode.timed;

  /// Whether the timer has expired.
  bool get isTimeUp =>
      isTimedMode && remainingTime != null && remainingTime!.inSeconds <= 0;

  /// Total number of questions in the current session.
  int get totalQuestions => currentSession?.totalQuestions ?? 0;

  /// Whether the student is on the first question.
  bool get isFirstQuestion => currentQuestionIndex == 0;

  /// Whether the student is on the last question.
  bool get isLastQuestion =>
      totalQuestions > 0 && currentQuestionIndex >= totalQuestions - 1;

  /// Number of answered questions.
  int get answeredCount => currentAnswers.length;

  /// Number of sessions loaded.
  int get sessionCount => sessions.length;

  /// Creates a copy of this state with the given fields replaced.
  PracticeState copyWith({
    List<PracticeSessionEntity>? sessions,
    PracticeSessionEntity? currentSession,
    List<PracticeAnswerEntity>? currentAnswers,
    int? currentQuestionIndex,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool? hasMore,
    Duration? remainingTime,
    int? currentPage,
    bool clearCurrentSession = false,
    bool clearRemainingTime = false,
  }) {
    return PracticeState(
      sessions: sessions ?? this.sessions,
      currentSession: clearCurrentSession
          ? null
          : (currentSession ?? this.currentSession),
      currentAnswers: currentAnswers ?? this.currentAnswers,
      currentQuestionIndex:
          currentQuestionIndex ?? this.currentQuestionIndex,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      remainingTime: clearRemainingTime ? null : (remainingTime ?? this.remainingTime),
      currentPage: currentPage ?? this.currentPage,
    );
  }

  /// Clears the current error message.
  PracticeState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Practice feature's state.
///
/// All practice session operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the session list, answers, navigation, and timer on success
/// 4. Sets [error] on failure
class PracticeNotifier extends StateNotifier<PracticeState> {
  PracticeNotifier({
    required CreatePracticeSessionUseCase createPracticeSession,
    required GetPracticeSessionsUseCase getPracticeSessions,
    required GetPracticeSessionDetailUseCase getPracticeSessionDetail,
    required SubmitPracticeAnswerUseCase submitPracticeAnswer,
    required CompletePracticeSessionUseCase completePracticeSession,
    required String? studentId,
  })  : _createPracticeSession = createPracticeSession,
        _getPracticeSessions = getPracticeSessions,
        _getPracticeSessionDetail = getPracticeSessionDetail,
        _submitPracticeAnswer = submitPracticeAnswer,
        _completePracticeSession = completePracticeSession,
        _studentId = studentId,
        super(const PracticeState());

  final CreatePracticeSessionUseCase _createPracticeSession;
  final GetPracticeSessionsUseCase _getPracticeSessions;
  final GetPracticeSessionDetailUseCase _getPracticeSessionDetail;
  final SubmitPracticeAnswerUseCase _submitPracticeAnswer;
  final CompletePracticeSessionUseCase _completePracticeSession;
  final String? _studentId;

  static const int _pageSize = 20;
  Timer? _timer;

  // ─── Load Sessions (first page) ────────────────────────────────────

  /// Loads the first page of practice sessions for the current student.
  Future<void> loadSessions() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getPracticeSessions(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (sessions) {
        state = state.copyWith(
          isLoading: false,
          sessions: sessions,
          currentPage: 1,
          hasMore: sessions.length >= _pageSize,
          error: null,
        );
        AppLogger.info(
          'Loaded ${sessions.length} practice sessions (page 1)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load practice sessions: $failure');
      },
    );
  }

  // ─── Load More Sessions ────────────────────────────────────────────

  /// Loads the next page of practice sessions and appends to the list.
  Future<void> loadMoreSessions() async {
    if (_studentId == null || !state.hasMore) return;

    final nextPage = state.currentPage + 1;

    final result = await _getPracticeSessions(
      studentId: _studentId!,
      page: nextPage,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (newSessions) {
        final allSessions = [...state.sessions, ...newSessions];
        state = state.copyWith(
          sessions: allSessions,
          currentPage: nextPage,
          hasMore: newSessions.length >= _pageSize,
        );
        AppLogger.info(
          'Loaded ${newSessions.length} more practice sessions (page $nextPage)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load more practice sessions: $failure',
        );
      },
    );
  }

  // ─── Create Session ────────────────────────────────────────────────

  /// Creates a new practice session with the given parameters.
  Future<void> createSession({
    String? subjectId,
    String? topicId,
    String difficulty = 'medium',
    PracticeMode mode = PracticeMode.untimed,
    int? timeLimitSec,
    int questionCount = 10,
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createPracticeSession(
      studentId: _studentId!,
      subjectId: subjectId,
      topicId: topicId,
      difficulty: difficulty,
      mode: mode,
      timeLimitSec: timeLimitSec,
      questionCount: questionCount,
    );

    result.fold(
      onSuccess: (session) {
        final updatedList = [session, ...state.sessions];
        state = state.copyWith(
          isLoading: false,
          sessions: updatedList,
          currentSession: session,
          currentAnswers: session.answers,
          currentQuestionIndex: 0,
          remainingTime: mode == PracticeMode.timed && timeLimitSec != null
              ? Duration(seconds: timeLimitSec)
              : null,
          error: null,
        );

        // Start timer if timed mode.
        if (mode == PracticeMode.timed && timeLimitSec != null) {
          startTimer();
        }

        AppLogger.info('Created practice session: ${session.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to create practice session: $failure',
        );
      },
    );
  }

  // ─── Open Session ──────────────────────────────────────────────────

  /// Opens a practice session by ID, loading its details and answers.
  Future<void> openSession(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getPracticeSessionDetail(
      sessionId: sessionId,
    );

    result.fold(
      onSuccess: (session) {
        state = state.copyWith(
          isLoading: false,
          currentSession: session,
          currentAnswers: session.answers,
          currentQuestionIndex: session.answers.length,
          remainingTime: session.mode == PracticeMode.timed &&
                  session.timeLimitSec != null &&
                  session.status == PracticeSessionStatus.inProgress
              ? Duration(seconds: session.timeLimitSec!)
              : null,
          error: null,
        );
        AppLogger.info(
          'Opened practice session: $sessionId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to open practice session: $failure',
        );
      },
    );
  }

  // ─── Submit Answer ─────────────────────────────────────────────────

  /// Submits an answer for the current question in the active session.
  Future<void> submitAnswer(
    String questionId,
    Map<String, dynamic> answer,
    int timeSpentSec,
  ) async {
    final session = state.currentSession;
    if (session == null) return;

    state = state.copyWith(isSubmitting: true, error: null);

    final result = await _submitPracticeAnswer(
      sessionId: session.id,
      questionId: questionId,
      studentAnswer: answer,
      timeSpentSec: timeSpentSec,
    );

    result.fold(
      onSuccess: (practiceAnswer) {
        final updatedAnswers = [...state.currentAnswers, practiceAnswer];

        // Update session with new answer count and score.
        final correctCount = updatedAnswers
            .where((a) => a.isCorrect == true)
            .length;
        final scorePct = updatedAnswers.isEmpty
            ? 0.0
            : (correctCount / updatedAnswers.length) * 100;

        final updatedSession = session.copyWith(
          correctCount: correctCount,
          scorePct: scorePct,
          answers: updatedAnswers,
        );

        state = state.copyWith(
          isSubmitting: false,
          currentAnswers: updatedAnswers,
          currentSession: updatedSession,
          error: null,
        );
        AppLogger.info(
          'Answer submitted for question $questionId in session ${session.id}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to submit answer: $failure');
      },
    );
  }

  // ─── Navigation ────────────────────────────────────────────────────

  /// Moves to the next question in the current session.
  void nextQuestion() {
    if (state.isLastQuestion) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  /// Moves to the previous question in the current session.
  void previousQuestion() {
    if (state.isFirstQuestion) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  // ─── Complete Session ──────────────────────────────────────────────

  /// Completes the current practice session and calculates the final score.
  Future<void> completeSession() async {
    final session = state.currentSession;
    if (session == null) return;

    stopTimer();
    state = state.copyWith(isLoading: true, error: null);

    final result = await _completePracticeSession(
      sessionId: session.id,
    );

    result.fold(
      onSuccess: (completedSession) {
        // Update session in the list.
        final updatedList = state.sessions
            .map((s) => s.id == completedSession.id ? completedSession : s)
            .toList();

        state = state.copyWith(
          isLoading: false,
          currentSession: completedSession,
          sessions: updatedList,
          clearRemainingTime: true,
          error: null,
        );
        AppLogger.info(
          'Completed practice session: ${completedSession.id} '
          '(score: ${completedSession.scorePct}%)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to complete practice session: $failure',
        );
      },
    );
  }

  // ─── Abandon Session ───────────────────────────────────────────────

  /// Abandons the current practice session without completing it.
  void abandonSession() {
    stopTimer();
    state = state.copyWith(
      clearCurrentSession: true,
      currentAnswers: const [],
      currentQuestionIndex: 0,
      clearRemainingTime: true,
    );
    AppLogger.info('Abandoned current practice session');
  }

  // ─── Timer (for timed mode) ────────────────────────────────────────

  /// Starts the countdown timer for a timed practice session.
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingTime;
      if (remaining == null || remaining.inSeconds <= 0) {
        _timer?.cancel();
        // Auto-complete when time is up.
        if (state.currentSession != null &&
            state.currentSession!.status ==
                PracticeSessionStatus.inProgress) {
          completeSession();
        }
        return;
      }
      state = state.copyWith(
        remainingTime: Duration(seconds: remaining.inSeconds - 1),
      );
    });
  }

  /// Stops the countdown timer.
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════
// PRACTICE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [PracticeNotifier] with all required use cases.
final practiceProvider =
    StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier(
    createPracticeSession: ref.watch(createPracticeSessionUseCaseProvider),
    getPracticeSessions: ref.watch(getPracticeSessionsUseCaseProvider),
    getPracticeSessionDetail:
        ref.watch(getPracticeSessionDetailUseCaseProvider),
    submitPracticeAnswer: ref.watch(submitPracticeAnswerUseCaseProvider),
    completePracticeSession:
        ref.watch(completePracticeSessionUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
  );
});
