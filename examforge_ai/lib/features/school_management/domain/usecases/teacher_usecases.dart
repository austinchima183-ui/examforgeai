import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE TEACHER PROFILE
// ═══════════════════════════════════════════════════════════════════════

class CreateTeacherProfileParams {
  const CreateTeacherProfileParams({required this.profile});
  final TeacherProfileEntity profile;
}

/// Use case that creates a new teacher profile.
///
/// Validates that [TeacherProfileEntity.userId], [TeacherProfileEntity.schoolId],
/// and [TeacherProfileEntity.employeeId] are present, then delegates to
/// [SchoolManagementRepository.createTeacherProfile].
class CreateTeacherProfileUseCase {
  CreateTeacherProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TeacherProfileEntity>> call(
    CreateTeacherProfileParams params,
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

    // ── Validate employeeId ──────────────────────────────────────────────
    if (params.profile.employeeId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Employee ID is required',
          fieldErrors: {'employeeId': 'Please provide an employee ID'},
        ),
      );
    }

    return _repository.createTeacherProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE TEACHER PROFILE
// ═══════════════════════════════════════════════════════════════════════

class UpdateTeacherProfileParams {
  const UpdateTeacherProfileParams({required this.profile});
  final TeacherProfileEntity profile;
}

/// Use case that updates an existing teacher profile.
///
/// Delegates to [SchoolManagementRepository.updateTeacherProfile].
class UpdateTeacherProfileUseCase {
  UpdateTeacherProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TeacherProfileEntity>> call(
    UpdateTeacherProfileParams params,
  ) async {
    return _repository.updateTeacherProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET TEACHER PROFILE
// ═══════════════════════════════════════════════════════════════════════

class GetTeacherProfileParams {
  const GetTeacherProfileParams({required this.userId});
  final String userId;
}

/// Use case that retrieves a single teacher profile by user ID.
///
/// Delegates to [SchoolManagementRepository.getTeacherProfile].
class GetTeacherProfileUseCase {
  GetTeacherProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TeacherProfileEntity>> call(
    GetTeacherProfileParams params,
  ) async {
    return _repository.getTeacherProfile(params.userId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET TEACHER PROFILES
// ═══════════════════════════════════════════════════════════════════════

class GetTeacherProfilesParams {
  const GetTeacherProfilesParams({
    required this.schoolId,
    this.departmentId,
    this.isActive,
    this.searchQuery,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final String? departmentId;
  final bool? isActive;
  final String? searchQuery;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of teacher profiles.
///
/// Delegates to [SchoolManagementRepository.getTeacherProfiles].
class GetTeacherProfilesUseCase {
  GetTeacherProfilesUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<TeacherProfileEntity>>> call(
    GetTeacherProfilesParams params,
  ) async {
    return _repository.getTeacherProfiles(
      schoolId: params.schoolId,
      departmentId: params.departmentId,
      isActive: params.isActive,
      searchQuery: params.searchQuery,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
