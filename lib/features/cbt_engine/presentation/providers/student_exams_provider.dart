import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/cbt_entities.dart';
import '../../domain/repositories/cbt_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// STUDENT EXAMS STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student's exam list view.
///
/// Categorizes exams into upcoming, active, and completed buckets
/// for easy browsing by the student.
class StudentExamsState {
  const StudentExamsState({
    this.upcomingExams = const [],
    this.activeExams = const [],
    this.completedExams = const [],
    this.isLoading = false,
    this.error,
  });

  /// Exams that have not yet started (future start time).
  final List<ExamEntity> upcomingExams;

  /// Exams that are currently within their active time window.
  final List<ExamEntity> activeExams;

  /// Exams that the student has already completed.
  final List<ExamEntity> completedExams;

  /// Whether the exam list is being loaded.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Total number of exams across all categories.
  int get totalExams =>
      upcomingExams.length + activeExams.length + completedExams.length;

  /// Whether there are any exams at all.
  bool get hasExams => totalExams > 0;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  StudentExamsState copyWith({
    List<ExamEntity>? upcomingExams,
    List<ExamEntity>? activeExams,
    List<ExamEntity>? completedExams,
    bool? isLoading,
    String? error,
  }) {
    return StudentExamsState(
      upcomingExams: upcomingExams ?? this.upcomingExams,
      activeExams: activeExams ?? this.activeExams,
      completedExams: completedExams ?? this.completedExams,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  StudentExamsState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT EXAMS NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student's exam list state.
///
/// Loads all exams assigned to the student and categorizes them
/// into upcoming, active, and completed buckets based on timing
/// and attempt status.
class StudentExamsNotifier extends StateNotifier<StudentExamsState> {
  StudentExamsNotifier({
    required CbtRepository cbtRepository,
  })  : _cbtRepository = cbtRepository,
        super(const StudentExamsState());

  final CbtRepository _cbtRepository;

  // ─── Load Exams ─────────────────────────────────────────────────────

  /// Loads all exams assigned to the current student.
  ///
  /// Categorizes exams into:
  /// - **upcoming**: Published but not yet within the time window
  /// - **active**: Currently within the time window
  /// - **completed**: Past the time window
  Future<void> loadExams() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _cbtRepository.getExams(
      status: ExamStatus.published,
      page: 1,
      perPage: 100,
    );

    result.fold(
      onSuccess: (exams) async {
        final now = DateTime.now();

        final upcoming = <ExamEntity>[];
        final active = <ExamEntity>[];
        final completed = <ExamEntity>[];

        for (final exam in exams) {
          if (now.isBefore(exam.startTime)) {
            upcoming.add(exam);
          } else if (now.isAfter(exam.endTime)) {
            completed.add(exam);
          } else {
            active.add(exam);
          }
        }

        // Also include active-status exams
        final activeResult = await _cbtRepository.getExams(
          status: ExamStatus.active,
          page: 1,
          perPage: 100,
        );

        activeResult.fold(
          onSuccess: (activeExams) {
            for (final exam in activeExams) {
              if (now.isBefore(exam.startTime)) {
                if (!upcoming.any((e) => e.id == exam.id)) {
                  upcoming.add(exam);
                }
              } else if (now.isAfter(exam.endTime)) {
                if (!completed.any((e) => e.id == exam.id)) {
                  completed.add(exam);
                }
              } else {
                if (!active.any((e) => e.id == exam.id)) {
                  active.add(exam);
                }
              }
            }

            state = state.copyWith(
              isLoading: false,
              upcomingExams: upcoming,
              activeExams: active,
              completedExams: completed,
              error: null,
            );
            AppLogger.info(
              'Student exams loaded: ${upcoming.length} upcoming, '
              '${active.length} active, ${completed.length} completed',
            );
          },
          onFailure: (failure) {
            // Still update with published exams even if active fails
            state = state.copyWith(
              isLoading: false,
              upcomingExams: upcoming,
              activeExams: active,
              completedExams: completed,
              error: null,
            );
            AppLogger.info(
              'Student exams loaded (partial): ${upcoming.length} upcoming, '
              '${active.length} active, ${completed.length} completed',
            );
          },
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load student exams: $failure');
      },
    );
  }

  // ─── Refresh Exams ──────────────────────────────────────────────────

  /// Refreshes the student's exam list.
  Future<void> refreshExams() async {
    await loadExams();
  }

  // ─── Clear Error ────────────────────────────────────────────────────

  /// Clears the current error message.
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
