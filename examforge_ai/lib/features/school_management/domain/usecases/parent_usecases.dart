import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE PARENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class CreateParentProfileParams {
  const CreateParentProfileParams({required this.profile});
  final ParentProfileEntity profile;
}

/// Use case that creates a new parent profile.
///
/// Delegates to [SchoolManagementRepository.createParentProfile].
class CreateParentProfileUseCase {
  CreateParentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<ParentProfileEntity>> call(
    CreateParentProfileParams params,
  ) async {
    return _repository.createParentProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE PARENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class UpdateParentProfileParams {
  const UpdateParentProfileParams({required this.profile});
  final ParentProfileEntity profile;
}

/// Use case that updates an existing parent profile.
///
/// Delegates to [SchoolManagementRepository.updateParentProfile].
class UpdateParentProfileUseCase {
  UpdateParentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<ParentProfileEntity>> call(
    UpdateParentProfileParams params,
  ) async {
    return _repository.updateParentProfile(params.profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET PARENT PROFILE
// ═══════════════════════════════════════════════════════════════════════

class GetParentProfileParams {
  const GetParentProfileParams({required this.userId});
  final String userId;
}

/// Use case that retrieves a single parent profile by user ID.
///
/// Delegates to [SchoolManagementRepository.getParentProfile].
class GetParentProfileUseCase {
  GetParentProfileUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<ParentProfileEntity>> call(
    GetParentProfileParams params,
  ) async {
    return _repository.getParentProfile(params.userId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET PARENT PROFILES
// ═══════════════════════════════════════════════════════════════════════

class GetParentProfilesParams {
  const GetParentProfilesParams({
    required this.schoolId,
    this.searchQuery,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final String? searchQuery;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of parent profiles.
///
/// Delegates to [SchoolManagementRepository.getParentProfiles].
class GetParentProfilesUseCase {
  GetParentProfilesUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<ParentProfileEntity>>> call(
    GetParentProfilesParams params,
  ) async {
    return _repository.getParentProfiles(
      schoolId: params.schoolId,
      searchQuery: params.searchQuery,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LINK PARENT TO STUDENT
// ═══════════════════════════════════════════════════════════════════════

class LinkParentToStudentParams {
  const LinkParentToStudentParams({
    required this.parentId,
    required this.studentId,
    required this.relationship,
    this.isPrimaryContact = false,
  });

  final String parentId;
  final String studentId;
  final String relationship;
  final bool isPrimaryContact;
}

/// Use case that links a parent to a student.
///
/// Validates that [LinkParentToStudentParams.parentId],
/// [LinkParentToStudentParams.studentId], and
/// [LinkParentToStudentParams.relationship] are present, then delegates to
/// [SchoolManagementRepository.linkParentToStudent].
class LinkParentToStudentUseCase {
  LinkParentToStudentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(LinkParentToStudentParams params) async {
    // ── Validate parentId ────────────────────────────────────────────────
    if (params.parentId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Parent ID is required',
          fieldErrors: {'parentId': 'Please provide a parent ID'},
        ),
      );
    }

    // ── Validate studentId ───────────────────────────────────────────────
    if (params.studentId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Student ID is required',
          fieldErrors: {'studentId': 'Please provide a student ID'},
        ),
      );
    }

    // ── Validate relationship ────────────────────────────────────────────
    if (params.relationship.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Relationship is required',
          fieldErrors: {'relationship': 'Please specify the relationship'},
        ),
      );
    }

    return _repository.linkParentToStudent(
      parentId: params.parentId,
      studentId: params.studentId,
      relationship: params.relationship,
      isPrimaryContact: params.isPrimaryContact,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UNLINK PARENT FROM STUDENT
// ═══════════════════════════════════════════════════════════════════════

class UnlinkParentFromStudentParams {
  const UnlinkParentFromStudentParams({required this.linkId});
  final String linkId;
}

/// Use case that unlinks a parent from a student.
///
/// Delegates to [SchoolManagementRepository.unlinkParentFromStudent].
class UnlinkParentFromStudentUseCase {
  UnlinkParentFromStudentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(UnlinkParentFromStudentParams params) async {
    return _repository.unlinkParentFromStudent(params.linkId);
  }
}
