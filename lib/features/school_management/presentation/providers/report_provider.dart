import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/school_management_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// REPORT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the school reports feature.
///
/// Holds multiple report types as separate fields so that the UI can
/// display each one independently without re-fetching the others.
class ReportState {
  const ReportState({
    this.overview,
    this.studentReport = const [],
    this.teacherReport = const [],
    this.attendanceReport = const [],
    this.isLoading = false,
    this.error,
  });

  /// School overview data (key-value pairs like total students, teachers, etc.)
  final Map<String, dynamic>? overview;

  /// Student list report data.
  final List<Map<String, dynamic>> studentReport;

  /// Teacher list report data.
  final List<Map<String, dynamic>> teacherReport;

  /// Attendance report data.
  final List<Map<String, dynamic>> attendanceReport;

  /// Whether a report is currently loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the overview has been loaded.
  bool get hasOverview => overview != null;

  /// Whether the student report has been loaded.
  bool get hasStudentReport => studentReport.isNotEmpty;

  /// Whether the teacher report has been loaded.
  bool get hasTeacherReport => teacherReport.isNotEmpty;

  /// Whether the attendance report has been loaded.
  bool get hasAttendanceReport => attendanceReport.isNotEmpty;

  /// Creates a copy of this state with the given fields replaced.
  ReportState copyWith({
    Map<String, dynamic>? overview,
    List<Map<String, dynamic>>? studentReport,
    List<Map<String, dynamic>>? teacherReport,
    List<Map<String, dynamic>>? attendanceReport,
    bool? isLoading,
    String? error,
  }) {
    return ReportState(
      overview: overview ?? this.overview,
      studentReport: studentReport ?? this.studentReport,
      teacherReport: teacherReport ?? this.teacherReport,
      attendanceReport: attendanceReport ?? this.attendanceReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ReportState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// REPORT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the school reports feature's state.
class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const ReportState());

  final SchoolManagementRepository _repository;

  // ─── Load School Overview ──────────────────────────────────────────

  /// Loads the school overview report (summary statistics).
  Future<void> loadSchoolOverview(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSchoolOverview(schoolId);

    result.fold(
      onSuccess: (overview) {
        state = state.copyWith(
          isLoading: false,
          overview: overview,
          error: null,
        );
        AppLogger.info('Loaded school overview for: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load school overview: $failure');
      },
    );
  }

  // ─── Load Student Report ───────────────────────────────────────────

  /// Loads the student list report for a school.
  Future<void> loadStudentReport({
    required String schoolId,
    String? classId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getStudentListReport(
      schoolId: schoolId,
      classId: classId,
    );

    result.fold(
      onSuccess: (report) {
        state = state.copyWith(
          isLoading: false,
          studentReport: report,
          error: null,
        );
        AppLogger.info('Loaded student report: ${report.length} entries');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load student report: $failure');
      },
    );
  }

  // ─── Load Teacher Report ───────────────────────────────────────────

  /// Loads the teacher list report for a school.
  Future<void> loadTeacherReport(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTeacherListReport(schoolId);

    result.fold(
      onSuccess: (report) {
        state = state.copyWith(
          isLoading: false,
          teacherReport: report,
          error: null,
        );
        AppLogger.info('Loaded teacher report: ${report.length} entries');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load teacher report: $failure');
      },
    );
  }

  // ─── Load Attendance Report ────────────────────────────────────────

  /// Loads the attendance report for a school and term.
  Future<void> loadAttendanceReport({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getAttendanceReport(
      schoolId: schoolId,
      termId: termId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      onSuccess: (report) {
        state = state.copyWith(
          isLoading: false,
          attendanceReport: report,
          error: null,
        );
        AppLogger.info('Loaded attendance report: ${report.length} entries');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load attendance report: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [ReportNotifier] and its [ReportState].
final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  return ReportNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
