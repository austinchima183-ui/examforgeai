import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// GET SCHOOL OVERVIEW
// ═══════════════════════════════════════════════════════════════════════

class GetSchoolOverviewParams {
  const GetSchoolOverviewParams({required this.schoolId});
  final String schoolId;
}

/// Use case that retrieves a high-level overview/dashboard for a school.
///
/// Returns aggregate statistics such as total students, teachers, classes,
/// and attendance rates. Delegates to
/// [SchoolManagementRepository.getSchoolOverview].
class GetSchoolOverviewUseCase {
  GetSchoolOverviewUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<Map<String, dynamic>>> call(
    GetSchoolOverviewParams params,
  ) async {
    return _repository.getSchoolOverview(params.schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET STUDENT LIST REPORT
// ═══════════════════════════════════════════════════════════════════════

class GetStudentListReportParams {
  const GetStudentListReportParams({
    required this.schoolId,
    this.classId,
  });

  final String schoolId;
  final String? classId;
}

/// Use case that generates a student list report.
///
/// Delegates to [SchoolManagementRepository.getStudentListReport].
class GetStudentListReportUseCase {
  GetStudentListReportUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call(
    GetStudentListReportParams params,
  ) async {
    return _repository.getStudentListReport(
      schoolId: params.schoolId,
      classId: params.classId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET TEACHER LIST REPORT
// ═══════════════════════════════════════════════════════════════════════

class GetTeacherListReportParams {
  const GetTeacherListReportParams({required this.schoolId});
  final String schoolId;
}

/// Use case that generates a teacher list report.
///
/// Delegates to [SchoolManagementRepository.getTeacherListReport].
class GetTeacherListReportUseCase {
  GetTeacherListReportUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call(
    GetTeacherListReportParams params,
  ) async {
    return _repository.getTeacherListReport(params.schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET ATTENDANCE REPORT
// ═══════════════════════════════════════════════════════════════════════

class GetAttendanceReportParams {
  const GetAttendanceReportParams({
    required this.schoolId,
    required this.termId,
    this.classId,
    this.startDate,
    this.endDate,
  });

  final String schoolId;
  final String termId;
  final String? classId;
  final DateTime? startDate;
  final DateTime? endDate;
}

/// Use case that generates an attendance report.
///
/// Delegates to [SchoolManagementRepository.getAttendanceReport].
class GetAttendanceReportUseCase {
  GetAttendanceReportUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<Map<String, dynamic>>>> call(
    GetAttendanceReportParams params,
  ) async {
    return _repository.getAttendanceReport(
      schoolId: params.schoolId,
      termId: params.termId,
      classId: params.classId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET DOCUMENT CENTER
// ═══════════════════════════════════════════════════════════════════════

class GetDocumentCenterParams {
  const GetDocumentCenterParams({
    required this.schoolId,
    this.documentType,
    this.category,
    this.searchQuery,
    this.isPublic,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final DocumentType? documentType;
  final String? category;
  final String? searchQuery;
  final bool? isPublic;
  final int page;
  final int perPage;
}

/// Use case that retrieves documents from the school document center.
///
/// Delegates to [SchoolManagementRepository.getDocuments].
class GetDocumentCenterUseCase {
  GetDocumentCenterUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<DocumentEntity>>> call(
    GetDocumentCenterParams params,
  ) async {
    return _repository.getDocuments(
      schoolId: params.schoolId,
      documentType: params.documentType,
      category: params.category,
      searchQuery: params.searchQuery,
      isPublic: params.isPublic,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
