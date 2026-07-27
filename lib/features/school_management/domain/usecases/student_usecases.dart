import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE STUDENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class CreateStudentProfileParams {
  const CreateStudentProfileParams({required this.profile});
  final StudentProfileEntity profile;
}

/// Use case that creates a new student profile.
///
/// Validates that [StudentProfileEntity.userId], [StudentProfileEntity.schoolId],
/// and [StudentProfileEntity.admissionNumber] are present, then delegates to
/// [SchoolManagementRepository.createStudentProfile].
class CreateStudentProfileUseCase {
  CreateStudentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<StudentProfileEntity>> call(
    CreateStudentProfileParams params,
  ) async {
    // ── Validate userId ──────────────────────────────────────────────────
    if (params.profile.userId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'User ID is required',
          fieldErrors: {'userId': 'Please provide a user ID'},
        ),
      );
    }

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.profile.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school'},
        ),
      );
    }

    // ── Validate admissionNumber ─────────────────────────────────────────
    if (params.profile.admissionNumber.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Admission number is required',
          fieldErrors: {'admissionNumber': 'Please provide an admission number'},
        ),
      );
    }

    return _repository.createStudentProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE STUDENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class UpdateStudentProfileParams {
  const UpdateStudentProfileParams({required this.profile});
  final StudentProfileEntity profile;
}

/// Use case that updates an existing student profile.
///
/// Delegates to [SchoolManagementRepository.updateStudentProfile].
class UpdateStudentProfileUseCase {
  UpdateStudentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<StudentProfileEntity>> call(
    UpdateStudentProfileParams params,
  ) async {
    return _repository.updateStudentProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET STUDENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class GetStudentProfileParams {
  const GetStudentProfileParams({required this.userId});
  final String userId;
}

/// Use case that retrieves a single student profile by user ID.
///
/// Delegates to [SchoolManagementRepository.getStudentProfile].
class GetStudentProfileUseCase {
  GetStudentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<StudentProfileEntity>> call(
    GetStudentProfileParams params,
  ) async {
    return _repository.getStudentProfile(params.userId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET STUDENT PROFILES
// ═══════════════════════════════════════════════════════════════════════

class GetStudentProfilesParams {
  const GetStudentProfilesParams({
    required this.schoolId,
    this.classId,
    this.isActive,
    this.isGraduated,
    this.searchQuery,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final String? classId;
  final bool? isActive;
  final bool? isGraduated;
  final String? searchQuery;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of student profiles.
///
/// Delegates to [SchoolManagementRepository.getStudentProfiles].
class GetStudentProfilesUseCase {
  GetStudentProfilesUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<StudentProfileEntity>>> call(
    GetStudentProfilesParams params,
  ) async {
    return _repository.getStudentProfiles(
      schoolId: params.schoolId,
      classId: params.classId,
      isActive: params.isActive,
      isGraduated: params.isGraduated,
      searchQuery: params.searchQuery,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROMOTE STUDENT
// ═══════════════════════════════════════════════════════════════════════

class PromoteStudentParams {
  const PromoteStudentParams({
    required this.studentId,
    required this.schoolId,
    required this.toClassId,
    required this.promotionStatus,
    this.fromClassId,
    this.academicSessionId,
    this.averageScore,
    this.comment,
  });

  final String studentId;
  final String schoolId;
  final String toClassId;
  final PromotionStatus promotionStatus;
  final String? fromClassId;
  final String? academicSessionId;
  final double? averageScore;
  final String? comment;
}

/// Use case that promotes a student to a new class.
///
/// Validates that [PromoteStudentParams.studentId] and
/// [PromoteStudentParams.toClassId] are present, then delegates to
/// [SchoolManagementRepository.promoteStudent].
class PromoteStudentUseCase {
  PromoteStudentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(PromoteStudentParams params) async {
    // ── Validate studentId ───────────────────────────────────────────────
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Student ID is required',
          fieldErrors: {'studentId': 'Please provide a student ID'},
        ),
      );
    }

    // ── Validate toClassId ───────────────────────────────────────────────
    if (params.toClassId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Destination class is required',
          fieldErrors: {'toClassId': 'Please select a class to promote to'},
        ),
      );
    }

    return _repository.promoteStudent(
      studentId: params.studentId,
      schoolId: params.schoolId,
      toClassId: params.toClassId,
      promotionStatus: params.promotionStatus,
      fromClassId: params.fromClassId,
      academicSessionId: params.academicSessionId,
      averageScore: params.averageScore,
      comment: params.comment,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GRADUATE STUDENT
// ═══════════════════════════════════════════════════════════════════════

class GraduateStudentParams {
  const GraduateStudentParams({
    required this.studentId,
    required this.schoolId,
  });

  final String studentId;
  final String schoolId;
}

/// Use case that graduates a student.
///
/// Delegates to [SchoolManagementRepository.graduateStudent].
class GraduateStudentUseCase {
  GraduateStudentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(GraduateStudentParams params) async {
    return _repository.graduateStudent(params.studentId, params.schoolId);
  }
}
