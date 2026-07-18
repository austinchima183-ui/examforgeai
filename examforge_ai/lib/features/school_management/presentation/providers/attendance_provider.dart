import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the attendance recording feature.
class AttendanceState {
  const AttendanceState({
    this.record,
    this.isLoading = false,
    this.error,
    this.selectedDate,
  });

  /// The attendance record for the selected class/date, or `null`.
  final AttendanceRecordEntity? record;

  /// Whether the record is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected date for attendance.
  final DateTime? selectedDate;

  /// Whether the record has been loaded.
  bool get isLoaded => record != null;

  /// The attendance entries for the loaded record.
  List<AttendanceEntryEntity> get entries => record?.entries ?? [];

  /// Creates a copy of this state with the given fields replaced.
  AttendanceState copyWith({
    AttendanceRecordEntity? record,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return AttendanceState(
      record: record ?? this.record,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  /// Clears the current error message.
  AttendanceState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the attendance recording feature's state.
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const AttendanceState());

  final SchoolManagementRepository _repository;

  // ─── Load Record ───────────────────────────────────────────────────

  /// Loads the attendance record for a class on a given date.
  Future<void> loadRecord({
    required String classId,
    required String termId,
    required DateTime date,
    String attendanceType = 'student',
  }) async {
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);

    final result = await _repository.getAttendanceRecord(
      classId: classId,
      termId: termId,
      date: date,
      attendanceType: attendanceType,
    );

    result.fold(
      onSuccess: (record) {
        state = state.copyWith(
          isLoading: false,
          record: record,
          error: null,
        );
        AppLogger.info(
          'Loaded attendance record for class $classId on $date',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load attendance record: $failure');
      },
    );
  }

  // ─── Create Record ─────────────────────────────────────────────────

  /// Creates a new attendance record.
  Future<void> createRecord(AttendanceRecordEntity record) async {
    final result = await _repository.createAttendanceRecord(record);

    result.fold(
      onSuccess: (createdRecord) {
        state = state.copyWith(record: createdRecord, error: null);
        AppLogger.info('Attendance record created: ${createdRecord.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create attendance record: $failure');
      },
    );
  }

  // ─── Mark Attendance ───────────────────────────────────────────────

  /// Marks attendance for all entries in the current record.
  Future<void> markAttendance(List<AttendanceEntryEntity> entries) async {
    if (state.record == null) return;

    final result = await _repository.markAttendance(
      recordId: state.record!.id,
      entries: entries,
    );

    result.fold(
      onSuccess: (_) {
        // Update the record with the new entries
        final updatedRecord = state.record!.copyWith(entries: entries);
        state = state.copyWith(record: updatedRecord, error: null);
        AppLogger.info('Attendance marked for record: ${state.record!.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to mark attendance: $failure');
      },
    );
  }

  // ─── Update Entry ──────────────────────────────────────────────────

  /// Updates a single attendance entry in the current record.
  Future<void> updateEntry(AttendanceEntryEntity updatedEntry) async {
    if (state.record == null) return;

    final updatedEntries = state.record!.entries
        .map((e) => e.id == updatedEntry.id ? updatedEntry : e)
        .toList();
    final updatedRecord = state.record!.copyWith(entries: updatedEntries);

    // Persist via updateAttendanceRecord
    final result = await _repository.updateAttendanceRecord(updatedRecord);

    result.fold(
      onSuccess: (savedRecord) {
        state = state.copyWith(record: savedRecord, error: null);
        AppLogger.info('Attendance entry updated: ${updatedEntry.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update attendance entry: $failure');
      },
    );
  }

  // ─── Set Selected Date ─────────────────────────────────────────────

  /// Sets the selected date for attendance viewing.
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
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
// ATTENDANCE REPORT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the attendance report feature.
class AttendanceReportState {
  const AttendanceReportState({
    this.records = const [],
    this.summary,
    this.isLoading = false,
    this.error,
  });

  /// The list of attendance records for the report.
  final List<AttendanceRecordEntity> records;

  /// The attendance summary, or `null`.
  final AttendanceSummaryEntity? summary;

  /// Whether the report is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  AttendanceReportState copyWith({
    List<AttendanceRecordEntity>? records,
    AttendanceSummaryEntity? summary,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceReportState(
      records: records ?? this.records,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  AttendanceReportState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE REPORT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the attendance report feature's state.
class AttendanceReportNotifier extends StateNotifier<AttendanceReportState> {
  AttendanceReportNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const AttendanceReportState());

  final SchoolManagementRepository _repository;

  // ─── Load Records ──────────────────────────────────────────────────

  /// Loads attendance records for a report.
  Future<void> loadRecords({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getAttendanceRecords(
      schoolId: schoolId,
      termId: termId,
      classId: classId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      perPage: perPage,
    );

    result.fold(
      onSuccess: (records) {
        state = state.copyWith(
          isLoading: false,
          records: records,
          error: null,
        );
        AppLogger.info('Loaded ${records.length} attendance records');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load attendance records: $failure');
      },
    );
  }

  // ─── Load Summary ──────────────────────────────────────────────────

  /// Loads the attendance summary for a class and term.
  Future<void> loadSummary({
    required String classId,
    required String termId,
  }) async {
    final result = await _repository.getAttendanceSummary(
      classId: classId,
      termId: termId,
    );

    result.fold(
      onSuccess: (summary) {
        state = state.copyWith(summary: summary, error: null);
        AppLogger.info('Loaded attendance summary for class $classId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load attendance summary: $failure');
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

/// Provides the [AttendanceNotifier] and its [AttendanceState].
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [AttendanceReportNotifier] and its [AttendanceReportState].
final attendanceReportProvider =
    StateNotifierProvider<AttendanceReportNotifier, AttendanceReportState>(
        (ref) {
  return AttendanceReportNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
