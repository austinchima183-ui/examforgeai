import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE ATTENDANCE RECORD
// ═══════════════════════════════════════════════════════════════════════

class CreateAttendanceRecordParams {
  const CreateAttendanceRecordParams({required this.record});
  final AttendanceRecordEntity record;
}

/// Use case that creates a new attendance record.
///
/// Delegates to [SchoolManagementRepository.createAttendanceRecord].
class CreateAttendanceRecordUseCase {
  CreateAttendanceRecordUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AttendanceRecordEntity>> call(
    CreateAttendanceRecordParams params,
  ) async {
    return _repository.createAttendanceRecord(params.record);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE ATTENDANCE RECORD
// ═══════════════════════════════════════════════════════════════════════

class UpdateAttendanceRecordParams {
  const UpdateAttendanceRecordParams({required this.record});
  final AttendanceRecordEntity record;
}

/// Use case that updates an existing attendance record.
///
/// Delegates to [SchoolManagementRepository.updateAttendanceRecord].
class UpdateAttendanceRecordUseCase {
  UpdateAttendanceRecordUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AttendanceRecordEntity>> call(
    UpdateAttendanceRecordParams params,
  ) async {
    return _repository.updateAttendanceRecord(params.record);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET ATTENDANCE RECORD
// ═══════════════════════════════════════════════════════════════════════

class GetAttendanceRecordParams {
  const GetAttendanceRecordParams({
    required this.classId,
    required this.termId,
    required this.date,
    this.attendanceType = 'student',
  });

  final String classId;
  final String termId;
  final DateTime date;
  final String attendanceType;
}

/// Use case that retrieves a single attendance record.
///
/// Delegates to [SchoolManagementRepository.getAttendanceRecord].
class GetAttendanceRecordUseCase {
  GetAttendanceRecordUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AttendanceRecordEntity>> call(
    GetAttendanceRecordParams params,
  ) async {
    return _repository.getAttendanceRecord(
      classId: params.classId,
      termId: params.termId,
      date: params.date,
      attendanceType: params.attendanceType,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET ATTENDANCE RECORDS
// ═══════════════════════════════════════════════════════════════════════

class GetAttendanceRecordsParams {
  const GetAttendanceRecordsParams({
    required this.schoolId,
    required this.termId,
    this.classId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final String termId;
  final String? classId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of attendance records.
///
/// Delegates to [SchoolManagementRepository.getAttendanceRecords].
class GetAttendanceRecordsUseCase {
  GetAttendanceRecordsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<AttendanceRecordEntity>>> call(
    GetAttendanceRecordsParams params,
  ) async {
    return _repository.getAttendanceRecords(
      schoolId: params.schoolId,
      termId: params.termId,
      classId: params.classId,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MARK ATTENDANCE
// ═══════════════════════════════════════════════════════════════════════

class MarkAttendanceParams {
  const MarkAttendanceParams({
    required this.recordId,
    required this.entries,
  });

  final String recordId;
  final List<AttendanceEntryEntity> entries;
}

/// Use case that marks attendance for a set of students or teachers.
///
/// Validates that [MarkAttendanceParams.recordId] is present and that
/// [MarkAttendanceParams.entries] is not empty, then delegates to
/// [SchoolManagementRepository.markAttendance].
class MarkAttendanceUseCase {
  MarkAttendanceUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(MarkAttendanceParams params) async {
    // ── Validate recordId ────────────────────────────────────────────────
    if (params.recordId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Record ID is required',
          fieldErrors: {'recordId': 'Please provide a record ID'},
        ),
      );
    }

    // ── Validate entries not empty ───────────────────────────────────────
    if (params.entries.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'At least one attendance entry is required',
          fieldErrors: {'entries': 'Please provide attendance entries'},
        ),
      );
    }

    return _repository.markAttendance(
      recordId: params.recordId,
      entries: params.entries,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET ATTENDANCE SUMMARY
// ═══════════════════════════════════════════════════════════════════════

class GetAttendanceSummaryParams {
  const GetAttendanceSummaryParams({
    required this.classId,
    required this.termId,
  });

  final String classId;
  final String termId;
}

/// Use case that retrieves an attendance summary for a class and term.
///
/// Delegates to [SchoolManagementRepository.getAttendanceSummary].
class GetAttendanceSummaryUseCase {
  GetAttendanceSummaryUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AttendanceSummaryEntity>> call(
    GetAttendanceSummaryParams params,
  ) async {
    return _repository.getAttendanceSummary(
      classId: params.classId,
      termId: params.termId,
    );
  }
}
