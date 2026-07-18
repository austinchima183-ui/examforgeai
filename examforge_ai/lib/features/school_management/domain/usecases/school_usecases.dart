import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE SCHOOL
// ═══════════════════════════════════════════════════════════════════════

class CreateSchoolParams {
  const CreateSchoolParams({required this.school});
  final SchoolEntity school;
}

/// Use case that creates a new school.
///
/// Validates that [SchoolEntity.name] and [SchoolEntity.code] are present,
/// then delegates to [SchoolManagementRepository.createSchool].
class CreateSchoolUseCase {
  CreateSchoolUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<SchoolEntity>> call(CreateSchoolParams params) async {
    // ── Validate name ────────────────────────────────────────────────────
    if (params.school.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School name is required',
          fieldErrors: {'name': 'Please provide a school name'},
        ),
      );
    }

    // ── Validate code ────────────────────────────────────────────────────
    if (params.school.code.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School code is required',
          fieldErrors: {'code': 'Please provide a school code'},
        ),
      );
    }

    return _repository.createSchool(params.school);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE SCHOOL
// ═══════════════════════════════════════════════════════════════════════

class UpdateSchoolParams {
  const UpdateSchoolParams({required this.school});
  final SchoolEntity school;
}

/// Use case that updates an existing school.
///
/// Delegates to [SchoolManagementRepository.updateSchool].
class UpdateSchoolUseCase {
  UpdateSchoolUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<SchoolEntity>> call(UpdateSchoolParams params) async {
    return _repository.updateSchool(params.school);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET SCHOOL
// ═══════════════════════════════════════════════════════════════════════

class GetSchoolParams {
  const GetSchoolParams({required this.schoolId});
  final String schoolId;
}

/// Use case that retrieves a single school by ID.
///
/// Delegates to [SchoolManagementRepository.getSchool].
class GetSchoolUseCase {
  GetSchoolUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<SchoolEntity>> call(GetSchoolParams params) async {
    return _repository.getSchool(params.schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET SCHOOLS
// ═══════════════════════════════════════════════════════════════════════

class GetSchoolsParams {
  const GetSchoolsParams({this.isActive, this.page = 1, this.perPage = 20});
  final bool? isActive;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of schools.
///
/// Delegates to [SchoolManagementRepository.getSchools].
class GetSchoolsUseCase {
  GetSchoolsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<SchoolEntity>>> call(GetSchoolsParams params) async {
    return _repository.getSchools(
      isActive: params.isActive,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE BRANCH
// ═══════════════════════════════════════════════════════════════════════

class CreateBranchParams {
  const CreateBranchParams({required this.branch});
  final SchoolBranchEntity branch;
}

/// Use case that creates a new school branch.
///
/// Validates that [SchoolBranchEntity.name], [SchoolBranchEntity.code],
/// and [SchoolBranchEntity.schoolId] are present, then delegates to
/// [SchoolManagementRepository.createBranch].
class CreateBranchUseCase {
  CreateBranchUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<SchoolBranchEntity>> call(CreateBranchParams params) async {
    // ── Validate name ────────────────────────────────────────────────────
    if (params.branch.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Branch name is required',
          fieldErrors: {'name': 'Please provide a branch name'},
        ),
      );
    }

    // ── Validate code ────────────────────────────────────────────────────
    if (params.branch.code.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Branch code is required',
          fieldErrors: {'code': 'Please provide a branch code'},
        ),
      );
    }

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.branch.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school for this branch'},
        ),
      );
    }

    return _repository.createBranch(params.branch);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE BRANCH
// ═══════════════════════════════════════════════════════════════════════

class UpdateBranchParams {
  const UpdateBranchParams({required this.branch});
  final SchoolBranchEntity branch;
}

/// Use case that updates an existing school branch.
///
/// Delegates to [SchoolManagementRepository.updateBranch].
class UpdateBranchUseCase {
  UpdateBranchUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<SchoolBranchEntity>> call(UpdateBranchParams params) async {
    return _repository.updateBranch(params.branch);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE DEPARTMENT
// ═══════════════════════════════════════════════════════════════════════

class CreateDepartmentParams {
  const CreateDepartmentParams({required this.department});
  final DepartmentEntity department;
}

/// Use case that creates a new department.
///
/// Validates that [DepartmentEntity.name], [DepartmentEntity.code],
/// and [DepartmentEntity.schoolId] are present, then delegates to
/// [SchoolManagementRepository.createDepartment].
class CreateDepartmentUseCase {
  CreateDepartmentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<DepartmentEntity>> call(CreateDepartmentParams params) async {
    // ── Validate name ────────────────────────────────────────────────────
    if (params.department.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Department name is required',
          fieldErrors: {'name': 'Please provide a department name'},
        ),
      );
    }

    // ── Validate code ────────────────────────────────────────────────────
    if (params.department.code.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Department code is required',
          fieldErrors: {'code': 'Please provide a department code'},
        ),
      );
    }

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.department.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school for this department'},
        ),
      );
    }

    return _repository.createDepartment(params.department);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE DEPARTMENT
// ═══════════════════════════════════════════════════════════════════════

class UpdateDepartmentParams {
  const UpdateDepartmentParams({required this.department});
  final DepartmentEntity department;
}

/// Use case that updates an existing department.
///
/// Delegates to [SchoolManagementRepository.updateDepartment].
class UpdateDepartmentUseCase {
  UpdateDepartmentUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<DepartmentEntity>> call(UpdateDepartmentParams params) async {
    return _repository.updateDepartment(params.department);
  }
}
