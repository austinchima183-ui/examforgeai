import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/results_entities.dart';
import '../../domain/usecases/results_usecases.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// RESULTS ENGINE — PRESENTATION PROVIDERS
// ═══════════════════════════════════════════════════════════════════════
// All StateNotifiers and their corresponding state classes for the
// Results Engine feature. Each notifier encapsulates a single area of
// the results domain (grading, analytics, export, management, etc.).
// ═══════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════
// 1. RESULTS DASHBOARD STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the results dashboard.
///
/// Tracks grade scales, class performance, and school performance
/// for the main dashboard view.
class ResultsDashboardState {
  const ResultsDashboardState({
    this.gradeScales = const [],
    this.classPerformance,
    this.schoolPerformance,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  /// Grade scales available for the school.
  final List<GradeScaleEntity> gradeScales;

  /// Class-level performance summary.
  final ClassPerformanceEntity? classPerformance;

  /// School-level performance summary.
  final SchoolPerformanceEntity? schoolPerformance;

  /// Whether data is being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Whether dashboard data has been loaded at least once.
  bool get hasData =>
      gradeScales.isNotEmpty ||
      classPerformance != null ||
      schoolPerformance != null;

  ResultsDashboardState copyWith({
    List<GradeScaleEntity>? gradeScales,
    ClassPerformanceEntity? classPerformance,
    SchoolPerformanceEntity? schoolPerformance,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ResultsDashboardState(
      gradeScales: gradeScales ?? this.gradeScales,
      classPerformance: classPerformance ?? this.classPerformance,
      schoolPerformance: schoolPerformance ?? this.schoolPerformance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static ResultsDashboardState initial() => const ResultsDashboardState();

  /// Clears the current error message.
  ResultsDashboardState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ResultsDashboardState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages the results dashboard state.
///
/// Loads grade scales, class performance, and school performance
/// for the main dashboard landing page.
class ResultsDashboardNotifier extends StateNotifier<ResultsDashboardState> {
  ResultsDashboardNotifier({
    required GetGradeScalesUseCase getGradeScalesUseCase,
    required GetClassPerformanceUseCase getClassPerformanceUseCase,
    required GetSchoolPerformanceUseCase getSchoolPerformanceUseCase,
  })  : _getGradeScalesUseCase = getGradeScalesUseCase,
        _getClassPerformanceUseCase = getClassPerformanceUseCase,
        _getSchoolPerformanceUseCase = getSchoolPerformanceUseCase,
        super(ResultsDashboardState.initial());

  final GetGradeScalesUseCase _getGradeScalesUseCase;
  final GetClassPerformanceUseCase _getClassPerformanceUseCase;
  final GetSchoolPerformanceUseCase _getSchoolPerformanceUseCase;

  // ─── Load Dashboard ────────────────────────────────────────────────

  /// Loads all dashboard data for the given school and session.
  Future<void> loadDashboard({
    required String schoolId,
    required String classId,
    required String academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Load grade scales
    final scalesResult = await _getGradeScalesUseCase(schoolId, isActive: true);

    scalesResult.fold(
      onSuccess: (scales) {
        state = state.copyWith(gradeScales: scales);
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load grade scales: $failure');
      },
    );

    // Load class performance
    final classResult = await _getClassPerformanceUseCase(
      classId: classId,
      academicSessionId: academicSessionId,
    );

    classResult.fold(
      onSuccess: (performance) {
        state = state.copyWith(classPerformance: performance);
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load class performance: $failure');
      },
    );

    // Load school performance
    final schoolResult = await _getSchoolPerformanceUseCase(
      schoolId: schoolId,
      academicSessionId: academicSessionId,
    );

    schoolResult.fold(
      onSuccess: (performance) {
        state = state.copyWith(
          schoolPerformance: performance,
          isLoading: false,
          error: null,
        );
        AppLogger.info('Dashboard data loaded successfully');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load school performance: $failure');
      },
    );
  }

  // ─── Load Grade Scales ─────────────────────────────────────────────

  /// Loads grade scales for the school.
  Future<void> loadGradeScales(
    String schoolId, {
    bool? isActive,
    GradeType? gradeType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getGradeScalesUseCase(
      schoolId,
      isActive: isActive,
      gradeType: gradeType,
    );

    result.fold(
      onSuccess: (scales) {
        state = state.copyWith(
          isLoading: false,
          gradeScales: scales,
          error: null,
        );
        AppLogger.info('Loaded ${scales.length} grade scales');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load grade scales: $failure');
      },
    );
  }

  // ─── Load Class Performance ────────────────────────────────────────

  /// Loads class performance for the dashboard.
  Future<void> loadClassPerformance({
    required String classId,
    required String academicSessionId,
    String? subjectId,
  }) async {
    final result = await _getClassPerformanceUseCase(
      classId: classId,
      subjectId: subjectId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (performance) {
        state = state.copyWith(classPerformance: performance);
        AppLogger.info('Class performance loaded for class: $classId');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to load class performance: $failure');
      },
    );
  }

  // ─── Load School Performance ───────────────────────────────────────

  /// Loads school performance for the dashboard.
  Future<void> loadSchoolPerformance({
    required String schoolId,
    required String academicSessionId,
  }) async {
    final result = await _getSchoolPerformanceUseCase(
      schoolId: schoolId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (performance) {
        state = state.copyWith(schoolPerformance: performance);
        AppLogger.info('School performance loaded for school: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailureToMessage(failure));
        AppLogger.warning('Failed to load school performance: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 2. GRADE SCALE STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for grade scale management.
///
/// Tracks the list of grade scales, the currently applied scale entry,
/// and CRUD operation status.
class GradeScaleState {
  const GradeScaleState({
    this.gradeScales = const [],
    this.appliedEntry,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  /// The list of grade scales for the school.
  final List<GradeScaleEntity> gradeScales;

  /// The result of applying a grade scale to a percentage.
  final GradeScaleEntryEntity? appliedEntry;

  /// Whether an operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of grade scales loaded.
  int get scaleCount => gradeScales.length;

  /// The default (active) grade scale, if any.
  GradeScaleEntity? get defaultScale =>
      gradeScales.where((s) => s.isDefault).firstOrNull ??
      gradeScales.where((s) => s.isActive).firstOrNull;

  GradeScaleState copyWith({
    List<GradeScaleEntity>? gradeScales,
    GradeScaleEntryEntity? appliedEntry,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return GradeScaleState(
      gradeScales: gradeScales ?? this.gradeScales,
      appliedEntry: appliedEntry ?? this.appliedEntry,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static GradeScaleState initial() => const GradeScaleState();

  /// Clears the current error message.
  GradeScaleState clearError() => copyWith(error: null);

  /// Clears the current success message.
  GradeScaleState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages grade scale CRUD operations.
///
/// Provides methods for loading, creating, updating, deleting, and
/// applying grade scales.
class GradeScaleNotifier extends StateNotifier<GradeScaleState> {
  GradeScaleNotifier({
    required GetGradeScalesUseCase getGradeScalesUseCase,
    required CreateGradeScaleUseCase createGradeScaleUseCase,
    required UpdateGradeScaleUseCase updateGradeScaleUseCase,
    required ApplyGradeScaleUseCase applyGradeScaleUseCase,
  })  : _getGradeScalesUseCase = getGradeScalesUseCase,
        _createGradeScaleUseCase = createGradeScaleUseCase,
        _updateGradeScaleUseCase = updateGradeScaleUseCase,
        _applyGradeScaleUseCase = applyGradeScaleUseCase,
        super(GradeScaleState.initial());

  final GetGradeScalesUseCase _getGradeScalesUseCase;
  final CreateGradeScaleUseCase _createGradeScaleUseCase;
  final UpdateGradeScaleUseCase _updateGradeScaleUseCase;
  final ApplyGradeScaleUseCase _applyGradeScaleUseCase;

  // ─── Load Grade Scales ─────────────────────────────────────────────

  /// Loads grade scales for the given school.
  Future<void> loadGradeScales(
    String schoolId, {
    bool? isActive,
    GradeType? gradeType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getGradeScalesUseCase(
      schoolId,
      isActive: isActive,
      gradeType: gradeType,
    );

    result.fold(
      onSuccess: (scales) {
        state = state.copyWith(
          isLoading: false,
          gradeScales: scales,
          error: null,
        );
        AppLogger.info('Loaded ${scales.length} grade scales');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load grade scales: $failure');
      },
    );
  }

  // ─── Create Grade Scale ────────────────────────────────────────────

  /// Creates a new grade scale.
  Future<void> createGradeScale(GradeScaleEntity scale) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createGradeScaleUseCase(scale);

    result.fold(
      onSuccess: (createdScale) {
        state = state.copyWith(
          isLoading: false,
          gradeScales: [...state.gradeScales, createdScale],
          successMessage: 'Grade scale "${createdScale.name}" created successfully',
          error: null,
        );
        AppLogger.info('Grade scale created: ${createdScale.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create grade scale: $failure');
      },
    );
  }

  // ─── Update Grade Scale ────────────────────────────────────────────

  /// Updates an existing grade scale.
  Future<void> updateGradeScale(GradeScaleEntity scale) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateGradeScaleUseCase(scale);

    result.fold(
      onSuccess: (updatedScale) {
        final updatedList = state.gradeScales
            .map((s) => s.id == updatedScale.id ? updatedScale : s)
            .toList();
        state = state.copyWith(
          isLoading: false,
          gradeScales: updatedList,
          successMessage: 'Grade scale "${updatedScale.name}" updated successfully',
          error: null,
        );
        AppLogger.info('Grade scale updated: ${updatedScale.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update grade scale: $failure');
      },
    );
  }

  // ─── Delete Grade Scale ────────────────────────────────────────────

  /// Deletes a grade scale by its ID.
  ///
  /// Removes the scale from the local state after a successful delete
  /// on the repository.
  Future<void> deleteGradeScale(
    String scaleId, {
    required Future<Result<void>> Function(String) deleteRemote,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await deleteRemote(scaleId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.gradeScales.where((s) => s.id != scaleId).toList();
        state = state.copyWith(
          isLoading: false,
          gradeScales: updatedList,
          successMessage: 'Grade scale deleted successfully',
          error: null,
        );
        AppLogger.info('Grade scale deleted: $scaleId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete grade scale: $failure');
      },
    );
  }

  // ─── Apply Grade Scale ─────────────────────────────────────────────

  /// Applies a grade scale to a percentage score and returns the
  /// matching grade entry.
  Future<void> applyGradeScale(double percentage, String scaleId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _applyGradeScaleUseCase(percentage, scaleId);

    result.fold(
      onSuccess: (entry) {
        state = state.copyWith(
          isLoading: false,
          appliedEntry: entry,
          successMessage: entry != null
              ? 'Grade: ${entry.grade} (${entry.minPercentage}%–${entry.maxPercentage}%)'
              : 'No matching grade found for $percentage%',
          error: null,
        );
        AppLogger.info(
          'Grade scale applied: $percentage% → ${entry?.grade ?? "no match"}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to apply grade scale: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 3. AI GRADING STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI grading workflow.
///
/// Tracks AI grading results, pending gradings, and the current
/// grading operation status.
class AiGradingState {
  const AiGradingState({
    this.gradingResults = const [],
    this.pendingGradings = const [],
    this.isLoading = false,
    this.isGrading = false,
    this.error,
    this.successMessage,
  });

  /// List of AI grading results.
  final List<AiGradingResultEntity> gradingResults;

  /// List of pending AI grading results awaiting teacher review.
  final List<AiGradingResultEntity> pendingGradings;

  /// Whether grading data is being loaded.
  final bool isLoading;

  /// Whether an AI grading operation is currently in progress.
  final bool isGrading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of pending gradings awaiting review.
  int get pendingCount => pendingGradings.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isGrading;

  /// Number of completed grading results.
  int get completedCount =>
      gradingResults.where((r) => r.status.isTerminal).length;

  AiGradingState copyWith({
    List<AiGradingResultEntity>? gradingResults,
    List<AiGradingResultEntity>? pendingGradings,
    bool? isLoading,
    bool? isGrading,
    String? error,
    String? successMessage,
  }) {
    return AiGradingState(
      gradingResults: gradingResults ?? this.gradingResults,
      pendingGradings: pendingGradings ?? this.pendingGradings,
      isLoading: isLoading ?? this.isLoading,
      isGrading: isGrading ?? this.isGrading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static AiGradingState initial() => const AiGradingState();

  /// Clears the current error message.
  AiGradingState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AiGradingState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages the AI grading workflow.
///
/// Provides methods for requesting AI grading, reviewing results,
/// batch-grading exams, and loading pending gradings.
class AiGradingNotifier extends StateNotifier<AiGradingState> {
  AiGradingNotifier({
    required RequestAiGradingUseCase requestAiGradingUseCase,
    required ReviewAiGradingUseCase reviewAiGradingUseCase,
    required BatchAiGradingUseCase batchAiGradingUseCase,
    required GetPendingAiGradingsUseCase getPendingAiGradingsUseCase,
  })  : _requestAiGradingUseCase = requestAiGradingUseCase,
        _reviewAiGradingUseCase = reviewAiGradingUseCase,
        _batchAiGradingUseCase = batchAiGradingUseCase,
        _getPendingAiGradingsUseCase = getPendingAiGradingsUseCase,
        super(AiGradingState.initial());

  final RequestAiGradingUseCase _requestAiGradingUseCase;
  final ReviewAiGradingUseCase _reviewAiGradingUseCase;
  final BatchAiGradingUseCase _batchAiGradingUseCase;
  final GetPendingAiGradingsUseCase _getPendingAiGradingsUseCase;

  // ─── Request AI Grading ────────────────────────────────────────────

  /// Requests AI grading for a single subjective answer.
  Future<void> requestGrading({
    required String answerId,
    required String examId,
    required String studentId,
    required String questionContent,
    required String studentAnswer,
    required String markingScheme,
    required double maxPossible,
    String? aiProvider,
  }) async {
    state = state.copyWith(isGrading: true, error: null);

    final result = await _requestAiGradingUseCase(
      answerId: answerId,
      examId: examId,
      studentId: studentId,
      questionContent: questionContent,
      studentAnswer: studentAnswer,
      markingScheme: markingScheme,
      maxPossible: maxPossible,
      aiProvider: aiProvider,
    );

    result.fold(
      onSuccess: (gradingResult) {
        state = state.copyWith(
          isGrading: false,
          gradingResults: [...state.gradingResults, gradingResult],
          successMessage: 'AI grading completed: ${gradingResult.suggestedScore}/${gradingResult.maxPossible}',
          error: null,
        );
        AppLogger.info('AI grading completed for answer: $answerId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGrading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to request AI grading: $failure');
      },
    );
  }

  // ─── Review AI Grading ─────────────────────────────────────────────

  /// Reviews an AI grading result (teacher accepts, overrides, or rejects).
  Future<void> reviewGrading({
    required String aiGradingId,
    required double finalScore,
    required bool isAccepted,
    String? reviewComment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _reviewAiGradingUseCase(
      aiGradingId: aiGradingId,
      finalScore: finalScore,
      isAccepted: isAccepted,
      reviewComment: reviewComment,
    );

    result.fold(
      onSuccess: (reviewedResult) {
        // Update the result in both lists
        final updatedResults = state.gradingResults
            .map((r) => r.id == aiGradingId ? reviewedResult : r)
            .toList();
        final updatedPending = state.pendingGradings
            .where((r) => r.id != aiGradingId)
            .toList();

        state = state.copyWith(
          isLoading: false,
          gradingResults: updatedResults,
          pendingGradings: updatedPending,
          successMessage: isAccepted
              ? 'AI grading accepted'
              : 'AI grading overridden with score: $finalScore',
          error: null,
        );
        AppLogger.info(
          'AI grading reviewed: $aiGradingId (accepted: $isAccepted)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to review AI grading: $failure');
      },
    );
  }

  // ─── Batch Grade Exam ──────────────────────────────────────────────

  /// Batch-requests AI grading for all subjective answers in an exam.
  Future<void> batchGradeExam(String examId) async {
    state = state.copyWith(isGrading: true, error: null);

    final result = await _batchAiGradingUseCase(examId);

    result.fold(
      onSuccess: (results) {
        state = state.copyWith(
          isGrading: false,
          gradingResults: [...state.gradingResults, ...results],
          successMessage: 'Batch AI grading completed: ${results.length} answers graded',
          error: null,
        );
        AppLogger.info(
          'Batch AI grading completed for exam $examId: ${results.length} results',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGrading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to batch grade exam: $failure');
      },
    );
  }

  // ─── Load Pending Gradings ─────────────────────────────────────────

  /// Loads pending AI grading results for an exam.
  Future<void> loadPendingGradings(String examId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getPendingAiGradingsUseCase(examId);

    result.fold(
      onSuccess: (pending) {
        state = state.copyWith(
          isLoading: false,
          pendingGradings: pending,
          error: null,
        );
        AppLogger.info(
          'Loaded ${pending.length} pending AI gradings for exam: $examId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load pending gradings: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 4. TEACHER GRADING STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for teacher manual grading.
///
/// Tracks feedback list, the current answer being graded, and
/// saving status.
class TeacherGradingState {
  const TeacherGradingState({
    this.feedbackList = const [],
    this.currentFeedback,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  /// List of teacher feedback entries for the current exam.
  final List<TeacherFeedbackEntity> feedbackList;

  /// The feedback currently being composed or edited.
  final TeacherFeedbackEntity? currentFeedback;

  /// Whether feedback data is being loaded.
  final bool isLoading;

  /// Whether a feedback save operation is in progress.
  final bool isSaving;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isSaving;

  /// Number of feedback entries graded.
  int get gradedCount => feedbackList.length;

  TeacherGradingState copyWith({
    List<TeacherFeedbackEntity>? feedbackList,
    TeacherFeedbackEntity? currentFeedback,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return TeacherGradingState(
      feedbackList: feedbackList ?? this.feedbackList,
      currentFeedback: currentFeedback ?? this.currentFeedback,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static TeacherGradingState initial() => const TeacherGradingState();

  /// Clears the current error message.
  TeacherGradingState clearError() => copyWith(error: null);

  /// Clears the current success message.
  TeacherGradingState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages teacher manual grading.
///
/// Provides methods for saving feedback, loading exam feedback,
/// and reviewing AI grading results from the teacher's perspective.
class TeacherGradingNotifier extends StateNotifier<TeacherGradingState> {
  TeacherGradingNotifier({
    required SaveTeacherFeedbackUseCase saveTeacherFeedbackUseCase,
    required GetTeacherFeedbackUseCase getTeacherFeedbackUseCase,
    required ReviewAiGradingUseCase reviewAiGradingUseCase,
  })  : _saveTeacherFeedbackUseCase = saveTeacherFeedbackUseCase,
        _getTeacherFeedbackUseCase = getTeacherFeedbackUseCase,
        _reviewAiGradingUseCase = reviewAiGradingUseCase,
        super(TeacherGradingState.initial());

  final SaveTeacherFeedbackUseCase _saveTeacherFeedbackUseCase;
  final GetTeacherFeedbackUseCase _getTeacherFeedbackUseCase;
  final ReviewAiGradingUseCase _reviewAiGradingUseCase;

  // ─── Save Feedback ─────────────────────────────────────────────────

  /// Saves teacher feedback (grading + comments) for a student answer.
  Future<void> saveFeedback(TeacherFeedbackEntity feedback) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _saveTeacherFeedbackUseCase(feedback);

    result.fold(
      onSuccess: (savedFeedback) {
        // Update or append the feedback in the list
        final existingIndex =
            state.feedbackList.indexWhere((f) => f.id == savedFeedback.id);
        final updatedList = existingIndex >= 0
            ? state.feedbackList
                .map((f) => f.id == savedFeedback.id ? savedFeedback : f)
                .toList()
            : [...state.feedbackList, savedFeedback];

        state = state.copyWith(
          isSaving: false,
          feedbackList: updatedList,
          currentFeedback: savedFeedback,
          successMessage: 'Feedback saved successfully',
          error: null,
        );
        AppLogger.info('Teacher feedback saved: ${savedFeedback.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to save feedback: $failure');
      },
    );
  }

  // ─── Load Exam Feedback ────────────────────────────────────────────

  /// Loads all teacher feedback for a specific exam.
  Future<void> loadExamFeedback({
    required String examId,
    required String teacherId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getTeacherFeedbackUseCase(
      examId: examId,
      teacherId: teacherId,
    );

    result.fold(
      onSuccess: (feedbackList) {
        state = state.copyWith(
          isLoading: false,
          feedbackList: feedbackList,
          error: null,
        );
        AppLogger.info(
          'Loaded ${feedbackList.length} feedback entries for exam: $examId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load exam feedback: $failure');
      },
    );
  }

  // ─── Review AI Grading ─────────────────────────────────────────────

  /// Reviews an AI grading result from the teacher's perspective,
  /// optionally accepting or overriding the AI's suggested score.
  Future<void> reviewAiGrading({
    required String aiGradingId,
    required double finalScore,
    required bool isAccepted,
    String? reviewComment,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _reviewAiGradingUseCase(
      aiGradingId: aiGradingId,
      finalScore: finalScore,
      isAccepted: isAccepted,
      reviewComment: reviewComment,
    );

    result.fold(
      onSuccess: (reviewedResult) {
        state = state.copyWith(
          isSaving: false,
          successMessage: isAccepted
              ? 'AI grading accepted'
              : 'AI grading overridden with score: $finalScore',
          error: null,
        );
        AppLogger.info(
          'AI grading reviewed by teacher: $aiGradingId (accepted: $isAccepted)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSaving: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to review AI grading: $failure');
      },
    );
  }

  // ─── Set Current Feedback ──────────────────────────────────────────

  /// Sets the current feedback being edited/graded.
  void setCurrentFeedback(TeacherFeedbackEntity? feedback) {
    state = state.copyWith(currentFeedback: feedback);
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 5. STUDENT RESULTS STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for student result viewing.
///
/// Tracks subject results, overall result, and topic mastery for
/// the student's perspective.
class StudentResultsState {
  const StudentResultsState({
    this.subjectResults = const [],
    this.overallResult,
    this.topicMastery = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  /// Student's results broken down by subject.
  final List<StudentSubjectResultEntity> subjectResults;

  /// Student's overall aggregated result.
  final StudentOverallResultEntity? overallResult;

  /// Student's topic mastery data.
  final List<TopicMasteryEntity> topicMastery;

  /// Whether data is being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Number of subjects with results.
  int get subjectCount => subjectResults.length;

  /// Number of subjects passed.
  int get passedSubjectCount =>
      subjectResults.where((s) => s.isPassed).length;

  /// Number of topics tracked.
  int get topicCount => topicMastery.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  StudentResultsState copyWith({
    List<StudentSubjectResultEntity>? subjectResults,
    StudentOverallResultEntity? overallResult,
    List<TopicMasteryEntity>? topicMastery,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return StudentResultsState(
      subjectResults: subjectResults ?? this.subjectResults,
      overallResult: overallResult ?? this.overallResult,
      topicMastery: topicMastery ?? this.topicMastery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static StudentResultsState initial() => const StudentResultsState();

  /// Clears the current error message.
  StudentResultsState clearError() => copyWith(error: null);

  /// Clears the current success message.
  StudentResultsState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages student result viewing.
///
/// Provides methods for loading subject results, overall result,
/// and topic mastery data for a student.
class StudentResultsNotifier extends StateNotifier<StudentResultsState> {
  StudentResultsNotifier({
    required GetStudentSubjectResultsUseCase getStudentSubjectResultsUseCase,
    required GetStudentOverallResultUseCase getStudentOverallResultUseCase,
    required GetStudentTopicMasteryUseCase getStudentTopicMasteryUseCase,
  })  : _getStudentSubjectResultsUseCase = getStudentSubjectResultsUseCase,
        _getStudentOverallResultUseCase = getStudentOverallResultUseCase,
        _getStudentTopicMasteryUseCase = getStudentTopicMasteryUseCase,
        super(StudentResultsState.initial());

  final GetStudentSubjectResultsUseCase _getStudentSubjectResultsUseCase;
  final GetStudentOverallResultUseCase _getStudentOverallResultUseCase;
  final GetStudentTopicMasteryUseCase _getStudentTopicMasteryUseCase;

  // ─── Load Subject Results ──────────────────────────────────────────

  /// Loads a student's subject-by-subject results for a session.
  Future<void> loadSubjectResults({
    required String studentId,
    required String academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getStudentSubjectResultsUseCase(
      studentId: studentId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (results) {
        state = state.copyWith(
          isLoading: false,
          subjectResults: results,
          error: null,
        );
        AppLogger.info(
          'Loaded ${results.length} subject results for student: $studentId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load subject results: $failure');
      },
    );
  }

  // ─── Load Overall Result ───────────────────────────────────────────

  /// Loads a student's overall aggregated result for a session.
  Future<void> loadOverallResult({
    required String studentId,
    required String classId,
    required String academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getStudentOverallResultUseCase(
      studentId: studentId,
      classId: classId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (overallResult) {
        state = state.copyWith(
          isLoading: false,
          overallResult: overallResult,
          error: null,
        );
        AppLogger.info(
          'Overall result loaded for student: $studentId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load overall result: $failure');
      },
    );
  }

  // ─── Load Topic Mastery ────────────────────────────────────────────

  /// Loads a student's topic mastery data for a subject.
  Future<void> loadTopicMastery({
    required String studentId,
    required String subjectId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getStudentTopicMasteryUseCase(
      studentId: studentId,
      subjectId: subjectId,
    );

    result.fold(
      onSuccess: (mastery) {
        state = state.copyWith(
          isLoading: false,
          topicMastery: mastery,
          error: null,
        );
        AppLogger.info(
          'Loaded ${mastery.length} topic mastery entries for student: $studentId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load topic mastery: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 6. ANALYTICS STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the analytics dashboard.
///
/// Tracks class/school performance, analytics snapshots, and
/// dashboard configuration.
class AnalyticsState {
  const AnalyticsState({
    this.classPerformance,
    this.schoolPerformance,
    this.snapshot,
    this.dashboardConfig,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  /// Class-level performance summary.
  final ClassPerformanceEntity? classPerformance;

  /// School-level performance summary.
  final SchoolPerformanceEntity? schoolPerformance;

  /// Pre-computed analytics snapshot.
  final AnalyticsSnapshotEntity? snapshot;

  /// Dashboard configuration for the current role.
  final DashboardConfigurationEntity? dashboardConfig;

  /// Whether data is being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Whether analytics data has been loaded at least once.
  bool get hasData =>
      classPerformance != null ||
      schoolPerformance != null ||
      snapshot != null ||
      dashboardConfig != null;

  AnalyticsState copyWith({
    ClassPerformanceEntity? classPerformance,
    SchoolPerformanceEntity? schoolPerformance,
    AnalyticsSnapshotEntity? snapshot,
    DashboardConfigurationEntity? dashboardConfig,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AnalyticsState(
      classPerformance: classPerformance ?? this.classPerformance,
      schoolPerformance: schoolPerformance ?? this.schoolPerformance,
      snapshot: snapshot ?? this.snapshot,
      dashboardConfig: dashboardConfig ?? this.dashboardConfig,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static AnalyticsState initial() => const AnalyticsState();

  /// Clears the current error message.
  AnalyticsState clearError() => copyWith(error: null);

  /// Clears the current success message.
  AnalyticsState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages analytics data loading
/// and dashboard configuration.
///
/// Provides methods for loading class/school performance,
/// analytics snapshots, and managing dashboard widget configurations.
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required GetClassPerformanceUseCase getClassPerformanceUseCase,
    required GetSchoolPerformanceUseCase getSchoolPerformanceUseCase,
    required GetAnalyticsSnapshotUseCase getAnalyticsSnapshotUseCase,
    required GetDashboardConfigurationUseCase getDashboardConfigurationUseCase,
    required SaveDashboardConfigurationUseCase saveDashboardConfigurationUseCase,
  })  : _getClassPerformanceUseCase = getClassPerformanceUseCase,
        _getSchoolPerformanceUseCase = getSchoolPerformanceUseCase,
        _getAnalyticsSnapshotUseCase = getAnalyticsSnapshotUseCase,
        _getDashboardConfigurationUseCase = getDashboardConfigurationUseCase,
        _saveDashboardConfigurationUseCase = saveDashboardConfigurationUseCase,
        super(AnalyticsState.initial());

  final GetClassPerformanceUseCase _getClassPerformanceUseCase;
  final GetSchoolPerformanceUseCase _getSchoolPerformanceUseCase;
  final GetAnalyticsSnapshotUseCase _getAnalyticsSnapshotUseCase;
  final GetDashboardConfigurationUseCase _getDashboardConfigurationUseCase;
  final SaveDashboardConfigurationUseCase _saveDashboardConfigurationUseCase;

  // ─── Load Class Performance ────────────────────────────────────────

  /// Loads class-level performance analytics.
  Future<void> loadClassPerformance({
    required String classId,
    required String academicSessionId,
    String? subjectId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getClassPerformanceUseCase(
      classId: classId,
      subjectId: subjectId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (performance) {
        state = state.copyWith(
          isLoading: false,
          classPerformance: performance,
          error: null,
        );
        AppLogger.info('Class performance loaded for class: $classId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load class performance: $failure');
      },
    );
  }

  // ─── Load School Performance ───────────────────────────────────────

  /// Loads school-level performance analytics.
  Future<void> loadSchoolPerformance({
    required String schoolId,
    required String academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSchoolPerformanceUseCase(
      schoolId: schoolId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (performance) {
        state = state.copyWith(
          isLoading: false,
          schoolPerformance: performance,
          error: null,
        );
        AppLogger.info('School performance loaded for school: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load school performance: $failure');
      },
    );
  }

  // ─── Load Dashboard ────────────────────────────────────────────────

  /// Loads the dashboard configuration and analytics snapshot
  /// for a given school and role.
  Future<void> loadDashboard({
    required String schoolId,
    required String role,
    required String academicSessionId,
    String? entityId,
    String? snapshotType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // Load dashboard configuration
    final configResult = await _getDashboardConfigurationUseCase(
      schoolId: schoolId,
      role: role,
    );

    configResult.fold(
      onSuccess: (config) {
        state = state.copyWith(dashboardConfig: config);
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load dashboard config: $failure');
      },
    );

    // Load analytics snapshot
    if (snapshotType != null) {
      final snapshotResult = await _getAnalyticsSnapshotUseCase(
        schoolId: schoolId,
        snapshotType: snapshotType,
        entityId: entityId,
        academicSessionId: academicSessionId,
      );

      snapshotResult.fold(
        onSuccess: (snapshot) {
          state = state.copyWith(snapshot: snapshot);
        },
        onFailure: (failure) {
          AppLogger.warning('Failed to load analytics snapshot: $failure');
        },
      );
    }

    state = state.copyWith(isLoading: false, error: null);
    AppLogger.info('Dashboard loaded for school: $schoolId, role: $role');
  }

  // ─── Update Dashboard Widgets ──────────────────────────────────────

  /// Saves an updated dashboard configuration (e.g., after widget
  /// rearrangement or visibility toggle).
  Future<void> updateDashboardWidgets(
    DashboardConfigurationEntity config,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _saveDashboardConfigurationUseCase(config);

    result.fold(
      onSuccess: (savedConfig) {
        state = state.copyWith(
          isLoading: false,
          dashboardConfig: savedConfig,
          successMessage: 'Dashboard layout saved',
          error: null,
        );
        AppLogger.info('Dashboard configuration updated: ${savedConfig.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update dashboard widgets: $failure');
      },
    );
  }

  // ─── Load Analytics Snapshot ───────────────────────────────────────

  /// Loads a specific analytics snapshot.
  Future<void> loadSnapshot({
    required String schoolId,
    required String snapshotType,
    String? entityId,
    String? academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAnalyticsSnapshotUseCase(
      schoolId: schoolId,
      snapshotType: snapshotType,
      entityId: entityId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (snapshot) {
        state = state.copyWith(
          isLoading: false,
          snapshot: snapshot,
          error: null,
        );
        AppLogger.info('Analytics snapshot loaded: $snapshotType');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load analytics snapshot: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 7. REPORT EXPORT STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for report creation and export.
///
/// Tracks the list of report exports, the current export being
/// generated, and generation status.
class ReportExportState {
  const ReportExportState({
    this.reports = const [],
    this.currentExport,
    this.downloadUrl,
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.successMessage,
  });

  /// List of report export records.
  final List<ReportExportEntity> reports;

  /// The report export currently being generated or viewed.
  final ReportExportEntity? currentExport;

  /// The download URL for the most recently completed export.
  final String? downloadUrl;

  /// Whether report data is being loaded.
  final bool isLoading;

  /// Whether a report is currently being generated.
  final bool isGenerating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isGenerating;

  /// Number of report exports loaded.
  int get reportCount => reports.length;

  ReportExportState copyWith({
    List<ReportExportEntity>? reports,
    ReportExportEntity? currentExport,
    String? downloadUrl,
    bool? isLoading,
    bool? isGenerating,
    String? error,
    String? successMessage,
  }) {
    return ReportExportState(
      reports: reports ?? this.reports,
      currentExport: currentExport ?? this.currentExport,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static ReportExportState initial() => const ReportExportState();

  /// Clears the current error message.
  ReportExportState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ReportExportState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages report creation and export.
///
/// Provides methods for creating reports, loading report history,
/// and downloading exported reports.
class ReportExportNotifier extends StateNotifier<ReportExportState> {
  ReportExportNotifier({
    required CreateReportExportUseCase createReportExportUseCase,
    required GetReportExportsUseCase getReportExportsUseCase,
    required DownloadReportUseCase downloadReportUseCase,
  })  : _createReportExportUseCase = createReportExportUseCase,
        _getReportExportsUseCase = getReportExportsUseCase,
        _downloadReportUseCase = downloadReportUseCase,
        super(ReportExportState.initial());

  final CreateReportExportUseCase _createReportExportUseCase;
  final GetReportExportsUseCase _getReportExportsUseCase;
  final DownloadReportUseCase _downloadReportUseCase;

  // ─── Create Report ─────────────────────────────────────────────────

  /// Creates a new report export request.
  Future<void> createReport({
    required String schoolId,
    required String requestedBy,
    required ReportType reportType,
    required ReportFormat reportFormat,
    required String title,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? filters,
  }) async {
    state = state.copyWith(isGenerating: true, error: null);

    final result = await _createReportExportUseCase(
      schoolId: schoolId,
      requestedBy: requestedBy,
      reportType: reportType,
      reportFormat: reportFormat,
      title: title,
      parameters: parameters,
      filters: filters,
    );

    result.fold(
      onSuccess: (reportExport) {
        state = state.copyWith(
          isGenerating: false,
          currentExport: reportExport,
          reports: [reportExport, ...state.reports],
          successMessage: 'Report "${reportExport.title}" created successfully',
          error: null,
        );
        AppLogger.info('Report export created: ${reportExport.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create report: $failure');
      },
    );
  }

  // ─── Load Reports ──────────────────────────────────────────────────

  /// Loads report export history for a school/user.
  Future<void> loadReports({
    String? schoolId,
    String? requestedBy,
    ReportStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getReportExportsUseCase(
      schoolId: schoolId,
      requestedBy: requestedBy,
      status: status,
      page: page,
      perPage: perPage,
    );

    result.fold(
      onSuccess: (reports) {
        state = state.copyWith(
          isLoading: false,
          reports: reports,
          error: null,
        );
        AppLogger.info('Loaded ${reports.length} report exports');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load reports: $failure');
      },
    );
  }

  // ─── Download Report ───────────────────────────────────────────────

  /// Downloads a report export by its ID, returning the download URL.
  Future<void> downloadReport(String exportId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _downloadReportUseCase(exportId);

    result.fold(
      onSuccess: (downloadUrl) {
        // Update the report in the list to mark it as downloaded
        final updatedReports = state.reports.map((r) {
          if (r.id == exportId) {
            return r.copyWith(downloadedAt: DateTime.now());
          }
          return r;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          downloadUrl: downloadUrl,
          reports: updatedReports,
          successMessage: 'Report download ready',
          error: null,
        );
        AppLogger.info('Report download ready: $exportId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to download report: $failure');
      },
    );
  }

  // ─── Set Current Export ────────────────────────────────────────────

  /// Sets the current export being viewed in detail.
  void setCurrentExport(ReportExportEntity? export) {
    state = state.copyWith(currentExport: export);
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 8. RESULT MANAGEMENT STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for result management operations.
///
/// Tracks lock status, publishing state, and recomputation status
/// for exam results.
class ResultManagementState {
  const ResultManagementState({
    this.lockStatus,
    this.isResultLocked = false,
    this.isLoading = false,
    this.isPublishing = false,
    this.error,
    this.successMessage,
  });

  /// The current lock status for the exam results.
  final ResultLockEntity? lockStatus;

  /// Whether the results are currently locked.
  final bool isResultLocked;

  /// whether data is being loaded.
  final bool isLoading;

  /// Whether a publish/unpublish operation is in progress.
  final bool isPublishing;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading || isPublishing;

  ResultManagementState copyWith({
    ResultLockEntity? lockStatus,
    bool? isResultLocked,
    bool? isLoading,
    bool? isPublishing,
    String? error,
    String? successMessage,
  }) {
    return ResultManagementState(
      lockStatus: lockStatus ?? this.lockStatus,
      isResultLocked: isResultLocked ?? this.isResultLocked,
      isLoading: isLoading ?? this.isLoading,
      isPublishing: isPublishing ?? this.isPublishing,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Creates the initial empty state.
  static ResultManagementState initial() => const ResultManagementState();

  /// Clears the current error message.
  ResultManagementState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ResultManagementState clearSuccessMessage() => copyWith(successMessage: null);
}

/// Riverpod [StateNotifier] that manages result locking, publishing,
/// withholding, and recomputation.
///
/// Provides methods for locking/unlocking results, publishing or
/// withholding results from students, and recomputing class results.
class ResultManagementNotifier extends StateNotifier<ResultManagementState> {
  ResultManagementNotifier({
    required LockResultsUseCase lockResultsUseCase,
    required PublishResultsUseCase publishResultsUseCase,
    required RecomputeResultsUseCase recomputeResultsUseCase,
  })  : _lockResultsUseCase = lockResultsUseCase,
        _publishResultsUseCase = publishResultsUseCase,
        _recomputeResultsUseCase = recomputeResultsUseCase,
        super(ResultManagementState.initial());

  final LockResultsUseCase _lockResultsUseCase;
  final PublishResultsUseCase _publishResultsUseCase;
  final RecomputeResultsUseCase _recomputeResultsUseCase;

  // ─── Lock Results ──────────────────────────────────────────────────

  /// Locks results for an exam, preventing modifications.
  Future<void> lockResults({
    required String examId,
    required String schoolId,
    required String lockedBy,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _lockResultsUseCase(
      examId: examId,
      schoolId: schoolId,
      lockedBy: lockedBy,
      reason: reason,
    );

    result.fold(
      onSuccess: (lock) {
        state = state.copyWith(
          isLoading: false,
          lockStatus: lock,
          isResultLocked: true,
          successMessage: 'Results locked successfully',
          error: null,
        );
        AppLogger.info('Results locked for exam: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to lock results: $failure');
      },
    );
  }

  // ─── Unlock Results ────────────────────────────────────────────────

  /// Unlocks results for an exam, allowing modifications again.
  Future<void> unlockResults({
    required String examId,
    required String unlockedBy,
    required Future<Result<ResultLockEntity>> Function({
      required String examId,
      required String unlockedBy,
    }) unlockRemote,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await unlockRemote(
      examId: examId,
      unlockedBy: unlockedBy,
    );

    result.fold(
      onSuccess: (lock) {
        state = state.copyWith(
          isLoading: false,
          lockStatus: lock,
          isResultLocked: false,
          successMessage: 'Results unlocked successfully',
          error: null,
        );
        AppLogger.info('Results unlocked for exam: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to unlock results: $failure');
      },
    );
  }

  // ─── Publish Results ───────────────────────────────────────────────

  /// Publishes results for an exam, making them visible to students.
  Future<void> publishResults(String examId) async {
    state = state.copyWith(isPublishing: true, error: null);

    final result = await _publishResultsUseCase(examId);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isPublishing: false,
          successMessage: 'Results published successfully',
          error: null,
        );
        AppLogger.info('Results published for exam: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isPublishing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish results: $failure');
      },
    );
  }

  // ─── Withhold Results ──────────────────────────────────────────────

  /// Withholds results for an exam, hiding them from students.
  Future<void> withholdResults(
    String examId, {
    required Future<Result<void>> Function(String) withholdRemote,
  }) async {
    state = state.copyWith(isPublishing: true, error: null);

    final result = await withholdRemote(examId);

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isPublishing: false,
          successMessage: 'Results withheld successfully',
          error: null,
        );
        AppLogger.info('Results withheld for exam: $examId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isPublishing: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to withhold results: $failure');
      },
    );
  }

  // ─── Recompute Results ─────────────────────────────────────────────

  /// Recomputes all subject and overall results for a class/session.
  Future<void> recomputeResults({
    required String classId,
    required String academicSessionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _recomputeResultsUseCase(
      classId: classId,
      academicSessionId: academicSessionId,
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Results recomputed successfully',
          error: null,
        );
        AppLogger.info(
          'Results recomputed for class: $classId, session: $academicSessionId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to recompute results: $failure');
      },
    );
  }

  // ─── Clear Messages ────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    state = state.clearError();
  }

  /// Clears the current success message.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// 9. RIVERPOD PROVIDER DECLARATIONS
// ═══════════════════════════════════════════════════════════════════════
// These StateNotifierProvider instances expose the notifiers to the
// widget tree. They are declared here with TODO placeholders for use
// case dependencies that need to be wired up in dependency_injection.dart.
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [ResultsDashboardNotifier] for results dashboard state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final resultsDashboardProvider =
    StateNotifierProvider<ResultsDashboardNotifier, ResultsDashboardState>(
  (ref) {
    return ResultsDashboardNotifier(
      getGradeScalesUseCase: ref.watch(getGradeScalesUseCaseProvider),
      getClassPerformanceUseCase: ref.watch(getClassPerformanceUseCaseProvider),
      getSchoolPerformanceUseCase: ref.watch(getSchoolPerformanceUseCaseProvider),
    );
  },
);

/// Provides the [GradeScaleNotifier] for grade scale CRUD state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final gradeScaleProvider =
    StateNotifierProvider<GradeScaleNotifier, GradeScaleState>(
  (ref) {
    return GradeScaleNotifier(
      getGradeScalesUseCase: ref.watch(getGradeScalesUseCaseProvider),
      createGradeScaleUseCase: ref.watch(createGradeScaleUseCaseProvider),
      updateGradeScaleUseCase: ref.watch(updateGradeScaleUseCaseProvider),
      applyGradeScaleUseCase: ref.watch(applyGradeScaleUseCaseProvider),
    );
  },
);

/// Provides the [AiGradingNotifier] for AI grading workflow state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final aiGradingProvider =
    StateNotifierProvider<AiGradingNotifier, AiGradingState>(
  (ref) {
    return AiGradingNotifier(
      requestAiGradingUseCase: ref.watch(requestAiGradingUseCaseProvider),
      reviewAiGradingUseCase: ref.watch(reviewAiGradingUseCaseProvider),
      batchAiGradingUseCase: ref.watch(batchAiGradingUseCaseProvider),
      getPendingAiGradingsUseCase: ref.watch(getPendingAiGradingsUseCaseProvider),
    );
  },
);

/// Provides the [TeacherGradingNotifier] for teacher manual grading state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final teacherGradingProvider =
    StateNotifierProvider<TeacherGradingNotifier, TeacherGradingState>(
  (ref) {
    return TeacherGradingNotifier(
      saveTeacherFeedbackUseCase: ref.watch(saveTeacherFeedbackUseCaseProvider),
      getTeacherFeedbackUseCase: ref.watch(getTeacherFeedbackUseCaseProvider),
      reviewAiGradingUseCase: ref.watch(reviewAiGradingUseCaseProvider),
    );
  },
);

/// Provides the [ReportExportNotifier] for report export state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final reportExportProvider =
    StateNotifierProvider<ReportExportNotifier, ReportExportState>(
  (ref) {
    return ReportExportNotifier(
      createReportExportUseCase: ref.watch(createReportExportUseCaseProvider),
      getReportExportsUseCase: ref.watch(getReportExportsUseCaseProvider),
      downloadReportUseCase: ref.watch(resultsDownloadReportUseCaseProvider),
    );
  },
);

/// Provides the [ResultManagementNotifier] for result management state.
///
/// TODO: Wire up use case dependencies in dependency_injection.dart.
final resultManagementProvider =
    StateNotifierProvider<ResultManagementNotifier, ResultManagementState>(
  (ref) {
    return ResultManagementNotifier(
      lockResultsUseCase: ref.watch(lockResultsUseCaseProvider),
      publishResultsUseCase: ref.watch(publishResultsUseCaseProvider),
      recomputeResultsUseCase: ref.watch(recomputeResultsUseCaseProvider),
    );
  },
);
