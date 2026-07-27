import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/repositories/student_portal_repository.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROGRESS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Progress & Analytics feature.
///
/// Tracks progress history, the latest snapshot, daily activity data,
/// loading flags, selected period/subject, and errors.
class ProgressState {
  const ProgressState({
    this.progressHistory = const [],
    this.latestProgress,
    this.dailyActivity = const [],
    this.isLoading = false,
    this.error,
    this.selectedPeriod = ProgressPeriod.weekly,
    this.selectedSubjectId,
  });

  /// Progress snapshots for the selected period.
  final List<StudentProgressEntity> progressHistory;

  /// The most recent overall progress snapshot.
  final StudentProgressEntity? latestProgress;

  /// Daily activity records for a date range.
  final List<StudentDailyActivityEntity> dailyActivity;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected time period for progress display.
  final ProgressPeriod selectedPeriod;

  /// Optional subject filter for progress data.
  final String? selectedSubjectId;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Average score across all progress snapshots.
  double get averageScore {
    if (progressHistory.isEmpty) return 0;
    final scores = progressHistory
        .where((p) => p.avgScore != null)
        .map((p) => p.avgScore!);
    return scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Total study time across all progress snapshots (in minutes).
  int get totalStudyTime =>
      progressHistory.fold(0, (sum, p) => sum + p.studyTimeMin);

  /// Total questions attempted across all snapshots.
  int get totalQuestionsAttempted =>
      progressHistory.fold(0, (sum, p) => sum + p.questionsAttempted);

  /// Overall accuracy percentage.
  double get overallAccuracy {
    final attempted = totalQuestionsAttempted;
    if (attempted == 0) return 0;
    final correct =
        progressHistory.fold(0, (sum, p) => sum + p.questionsCorrect);
    return (correct / attempted) * 100;
  }

  /// Current learning streak from the latest progress.
  int get learningStreak => latestProgress?.learningStreak ?? 0;

  /// Creates a copy of this state with the given fields replaced.
  ProgressState copyWith({
    List<StudentProgressEntity>? progressHistory,
    StudentProgressEntity? latestProgress,
    List<StudentDailyActivityEntity>? dailyActivity,
    bool? isLoading,
    String? error,
    ProgressPeriod? selectedPeriod,
    String? selectedSubjectId,
    bool clearLatestProgress = false,
    bool clearSelectedSubjectId = false,
  }) {
    return ProgressState(
      progressHistory: progressHistory ?? this.progressHistory,
      latestProgress: clearLatestProgress
          ? null
          : (latestProgress ?? this.latestProgress),
      dailyActivity: dailyActivity ?? this.dailyActivity,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedSubjectId: clearSelectedSubjectId
          ? null
          : (selectedSubjectId ?? this.selectedSubjectId),
    );
  }

  /// Clears the current error message.
  ProgressState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PROGRESS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Progress & Analytics
/// feature's state.
///
/// All progress operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates progress history, latest snapshot, and daily activity on success
/// 4. Sets [error] on failure
class ProgressNotifier extends StateNotifier<ProgressState> {
  ProgressNotifier({
    required GetProgressUseCase getProgress,
    required GetLatestProgressUseCase getLatestProgress,
    required StudentPortalRepository repository,
    required String? studentId,
  })  : _getProgress = getProgress,
        _getLatestProgress = getLatestProgress,
        _repository = repository,
        _studentId = studentId,
        super(const ProgressState());

  final GetProgressUseCase _getProgress;
  final GetLatestProgressUseCase _getLatestProgress;
  final StudentPortalRepository _repository;
  final String? _studentId;

  // ─── Load Progress ─────────────────────────────────────────────────

  /// Loads progress history for the given period and optional subject,
  /// along with the latest overall progress snapshot.
  Future<void> loadProgress({
    ProgressPeriod? period,
    String? subjectId,
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: period ?? state.selectedPeriod,
      selectedSubjectId: subjectId,
    );

    // Load both progress history and latest snapshot in parallel.
    final results = await Future.wait([
      _getProgress(
        studentId: _studentId,
        period: state.selectedPeriod,
        subjectId: state.selectedSubjectId,
      ),
      _getLatestProgress(studentId: _studentId),
    ]);

    final historyResult =
        results[0] as Result<List<StudentProgressEntity>>;
    final latestResult =
        results[1] as Result<StudentProgressEntity>;

    historyResult.fold(
      onSuccess: (history) {
        final latest = latestResult.getOrElse(
          history.isNotEmpty ? history.last : StudentProgressEntity(
            id: '',
            studentId: '',
            periodStart: DateTime.now(),
            periodEnd: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        state = state.copyWith(
          isLoading: false,
          progressHistory: history,
          latestProgress: latest,
          error: null,
        );
        AppLogger.info(
          'Loaded ${history.length} progress snapshots '
          '(${state.selectedPeriod.label})',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load progress: $failure');
      },
    );
  }

  // ─── Load Daily Activity ───────────────────────────────────────────

  /// Loads daily activity data for the given date range.
  Future<void> loadDailyActivity(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getDailyActivity(
      studentId: _studentId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      onSuccess: (activity) {
        state = state.copyWith(
          isLoading: false,
          dailyActivity: activity,
          error: null,
        );
        AppLogger.info(
          'Loaded ${activity.length} daily activity records',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load daily activity: $failure',
        );
      },
    );
  }

  // ─── Select Period ─────────────────────────────────────────────────

  /// Changes the selected period and reloads progress data.
  Future<void> selectPeriod(ProgressPeriod period) async {
    state = state.copyWith(selectedPeriod: period);
    await loadProgress();
  }

  // ─── Select Subject ────────────────────────────────────────────────

  /// Changes the selected subject filter and reloads progress data.
  /// Pass `null` to clear the subject filter.
  Future<void> selectSubject(String? subjectId) async {
    state = subjectId == null
        ? state.copyWith(clearSelectedSubjectId: true)
        : state.copyWith(selectedSubjectId: subjectId);
    await loadProgress();
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// PROGRESS PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [ProgressNotifier] with all required use cases.
final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(
    getProgress: ref.watch(getProgressUseCaseProvider),
    getLatestProgress: ref.watch(getLatestProgressUseCaseProvider),
    repository: ref.watch(studentPortalRepositoryProvider),
    studentId: ref.watch(currentStudentIdProvider),
  );
});
