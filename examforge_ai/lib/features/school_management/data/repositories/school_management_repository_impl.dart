import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';
import '../datasources/school_management_remote_datasource.dart';
import '../models/school_management_models.dart';

/// Concrete implementation of [SchoolManagementRepository] that delegates
/// all operations to [SchoolManagementRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class SchoolManagementRepositoryImpl implements SchoolManagementRepository {
  SchoolManagementRepositoryImpl({
    required SchoolManagementRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SchoolManagementRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Convert exceptions to Failures
  // ═══════════════════════════════════════════════════════════════════════

  Failure _mapExceptionToFailure(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      );
    } else if (e is CacheException) {
      return Failure.cache(message: e.message);
    } else if (e is NetworkException) {
      return Failure.network(message: e.message);
    } else if (e is ValidationException) {
      return Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      );
    } else if (e is NotFoundException) {
      return Failure.notFound(message: e.message);
    } else if (e is UnauthorizedException) {
      return Failure.unauthorized(message: e.message);
    } else if (e is ForbiddenException) {
      return Failure.forbidden(message: e.message);
    } else {
      AppLogger.error(
        'Unexpected exception in SchoolManagementRepositoryImpl',
        error: e,
      );
      return Failure.server(
        message: 'An unexpected error occurred: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL CRUD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SchoolEntity>> createSchool(SchoolEntity school) async {
    try {
      final model = SchoolModel.fromEntity(school);
      final created = await _remoteDataSource.createSchool(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchoolEntity>> updateSchool(SchoolEntity school) async {
    try {
      final model = SchoolModel.fromEntity(school);
      final updated = await _remoteDataSource.updateSchool(
        school.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteSchool(String schoolId) async {
    try {
      await _remoteDataSource.deleteSchool(schoolId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchoolEntity>> getSchool(String schoolId) async {
    try {
      final model = await _remoteDataSource.getSchool(schoolId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SchoolEntity>>> getSchools({
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (isActive != null) filters['is_active'] = isActive;

      final models = await _remoteDataSource.getSchools(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL BRANCHES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SchoolBranchEntity>> createBranch(
    SchoolBranchEntity branch,
  ) async {
    try {
      final model = SchoolBranchModel.fromEntity(branch);
      final created = await _remoteDataSource.createBranch(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchoolBranchEntity>> updateBranch(
    SchoolBranchEntity branch,
  ) async {
    try {
      final model = SchoolBranchModel.fromEntity(branch);
      final updated = await _remoteDataSource.updateBranch(
        branch.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteBranch(String branchId) async {
    try {
      await _remoteDataSource.deleteBranch(branchId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SchoolBranchEntity>>> getBranches(String schoolId) async {
    try {
      final models = await _remoteDataSource.getBranches(schoolId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DEPARTMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DepartmentEntity>> createDepartment(
    DepartmentEntity department,
  ) async {
    try {
      final model = DepartmentModel.fromEntity(department);
      final created =
          await _remoteDataSource.createDepartment(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DepartmentEntity>> updateDepartment(
    DepartmentEntity department,
  ) async {
    try {
      final model = DepartmentModel.fromEntity(department);
      final updated = await _remoteDataSource.updateDepartment(
        department.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteDepartment(String departmentId) async {
    try {
      await _remoteDataSource.deleteDepartment(departmentId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<DepartmentEntity>>> getDepartments(
    String schoolId,
  ) async {
    try {
      final models = await _remoteDataSource.getDepartments(schoolId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<StudentProfileEntity>> createStudentProfile(
    StudentProfileEntity profile,
  ) async {
    try {
      final model = StudentProfileModel.fromEntity(profile);
      final created =
          await _remoteDataSource.createStudentProfile(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<StudentProfileEntity>> updateStudentProfile(
    StudentProfileEntity profile,
  ) async {
    try {
      final model = StudentProfileModel.fromEntity(profile);
      final updated = await _remoteDataSource.updateStudentProfile(
        profile.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<StudentProfileEntity>> getStudentProfile(String userId) async {
    try {
      final model = await _remoteDataSource.getStudentProfile(userId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<StudentProfileEntity>>> getStudentProfiles({
    required String schoolId,
    String? classId,
    bool? isActive,
    bool? isGraduated,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getStudentProfiles(
        schoolId: schoolId,
        classId: classId,
        isActive: isActive,
        isGraduated: isGraduated,
        searchQuery: searchQuery,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> promoteStudent({
    required String studentId,
    required String schoolId,
    required String toClassId,
    required PromotionStatus promotionStatus,
    String? fromClassId,
    String? academicSessionId,
    double? averageScore,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{
        'student_id': studentId,
        'school_id': schoolId,
        'to_class_id': toClassId,
        'promotion_status': promotionStatus.value,
      };
      if (fromClassId != null) data['from_class_id'] = fromClassId;
      if (academicSessionId != null) {
        data['academic_session_id'] = academicSessionId;
      }
      if (averageScore != null) data['average_score'] = averageScore;
      if (comment != null) data['comment'] = comment;

      await _remoteDataSource.promoteStudent(data);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> graduateStudent(
    String studentId,
    String schoolId,
  ) async {
    try {
      await _remoteDataSource.graduateStudent(studentId, schoolId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<PromotionHistoryEntity>>> getPromotionHistory(
    String studentId,
  ) async {
    try {
      final models = await _remoteDataSource.getPromotionHistory(studentId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHER PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TeacherProfileEntity>> createTeacherProfile(
    TeacherProfileEntity profile,
  ) async {
    try {
      final model = TeacherProfileModel.fromEntity(profile);
      final created =
          await _remoteDataSource.createTeacherProfile(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeacherProfileEntity>> updateTeacherProfile(
    TeacherProfileEntity profile,
  ) async {
    try {
      final model = TeacherProfileModel.fromEntity(profile);
      final updated = await _remoteDataSource.updateTeacherProfile(
        profile.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeacherProfileEntity>> getTeacherProfile(String userId) async {
    try {
      final model = await _remoteDataSource.getTeacherProfile(userId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TeacherProfileEntity>>> getTeacherProfiles({
    required String schoolId,
    String? departmentId,
    bool? isActive,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getTeacherProfiles(
        schoolId: schoolId,
        departmentId: departmentId,
        isActive: isActive,
        searchQuery: searchQuery,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARENT PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ParentProfileEntity>> createParentProfile(
    ParentProfileEntity profile,
  ) async {
    try {
      final model = ParentProfileModel.fromEntity(profile);
      final created =
          await _remoteDataSource.createParentProfile(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ParentProfileEntity>> updateParentProfile(
    ParentProfileEntity profile,
  ) async {
    try {
      final model = ParentProfileModel.fromEntity(profile);
      final updated = await _remoteDataSource.updateParentProfile(
        profile.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ParentProfileEntity>> getParentProfile(String userId) async {
    try {
      final model = await _remoteDataSource.getParentProfile(userId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ParentProfileEntity>>> getParentProfiles({
    required String schoolId,
    String? searchQuery,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getParentProfiles(
        schoolId: schoolId,
        searchQuery: searchQuery,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> linkParentToStudent({
    required String parentId,
    required String studentId,
    required String relationship,
    bool isPrimaryContact = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'parent_id': parentId,
        'student_id': studentId,
        'relationship': relationship,
        'is_primary_contact': isPrimaryContact,
      };
      await _remoteDataSource.linkParentToStudent(data);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> unlinkParentFromStudent(String linkId) async {
    try {
      await _remoteDataSource.unlinkParentFromStudent(linkId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ParentStudentLinkEntity>>> getParentStudentLinks(
    String studentId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getParentStudentLinks(studentId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACADEMIC SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AcademicSessionEntity>> createSession(
    AcademicSessionEntity session,
  ) async {
    try {
      final model = AcademicSessionModel.fromEntity(session);
      final created =
          await _remoteDataSource.createSession(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AcademicSessionEntity>> updateSession(
    AcademicSessionEntity session,
  ) async {
    try {
      final model = AcademicSessionModel.fromEntity(session);
      final updated = await _remoteDataSource.updateSession(
        session.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteSession(String sessionId) async {
    try {
      await _remoteDataSource.deleteSession(sessionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AcademicSessionEntity>> getSession(String sessionId) async {
    try {
      final model = await _remoteDataSource.getSession(sessionId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AcademicSessionEntity>>> getSessions(
    String schoolId,
  ) async {
    try {
      final models = await _remoteDataSource.getSessions(schoolId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AcademicSessionEntity>> getCurrentSession(
    String schoolId,
  ) async {
    try {
      final model = await _remoteDataSource.getCurrentSession(schoolId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> setCurrentSession(String sessionId) async {
    try {
      await _remoteDataSource.setCurrentSession(sessionId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TERMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TermEntity>> createTerm(TermEntity term) async {
    try {
      final model = TermModel.fromEntity(term);
      final created = await _remoteDataSource.createTerm(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TermEntity>> updateTerm(TermEntity term) async {
    try {
      final model = TermModel.fromEntity(term);
      final updated = await _remoteDataSource.updateTerm(
        term.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTerm(String termId) async {
    try {
      await _remoteDataSource.deleteTerm(termId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TermEntity>>> getTerms(String academicSessionId) async {
    try {
      final models = await _remoteDataSource.getTerms(academicSessionId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TermEntity>> getCurrentTerm(String schoolId) async {
    try {
      final model = await _remoteDataSource.getCurrentTerm(schoolId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> setCurrentTerm(String termId) async {
    try {
      await _remoteDataSource.setCurrentTerm(termId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOOL CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CalendarEventEntity>> createCalendarEvent(
    CalendarEventEntity event,
  ) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final created =
          await _remoteDataSource.createCalendarEvent(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CalendarEventEntity>> updateCalendarEvent(
    CalendarEventEntity event,
  ) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final updated = await _remoteDataSource.updateCalendarEvent(
        event.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteCalendarEvent(String eventId) async {
    try {
      await _remoteDataSource.deleteCalendarEvent(eventId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CalendarEventEntity>>> getCalendarEvents({
    required String schoolId,
    String? termId,
    DateTime? startDate,
    DateTime? endDate,
    CalendarEventType? eventType,
  }) async {
    try {
      final models = await _remoteDataSource.getCalendarEvents(
        schoolId: schoolId,
        termId: termId,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        eventType: eventType?.value,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TIMETABLES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TimetableEntity>> createTimetable(
    TimetableEntity timetable,
  ) async {
    try {
      final model = TimetableModel.fromEntity(timetable);
      final created =
          await _remoteDataSource.createTimetable(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TimetableEntity>> updateTimetable(
    TimetableEntity timetable,
  ) async {
    try {
      final model = TimetableModel.fromEntity(timetable);
      final updated = await _remoteDataSource.updateTimetable(
        timetable.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTimetable(String timetableId) async {
    try {
      await _remoteDataSource.deleteTimetable(timetableId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TimetableEntity>> getTimetable(String timetableId) async {
    try {
      final model = await _remoteDataSource.getTimetable(timetableId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TimetableEntity>>> getTimetables({
    required String schoolId,
    String? termId,
    String? classId,
  }) async {
    try {
      final models = await _remoteDataSource.getTimetables(
        schoolId: schoolId,
        termId: termId,
        classId: classId,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TimetableSlotEntity>> addTimetableSlot(
    TimetableSlotEntity slot,
  ) async {
    try {
      final model = TimetableSlotModel.fromEntity(slot);
      final created =
          await _remoteDataSource.addTimetableSlot(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TimetableSlotEntity>> updateTimetableSlot(
    TimetableSlotEntity slot,
  ) async {
    try {
      final model = TimetableSlotModel.fromEntity(slot);
      final updated = await _remoteDataSource.updateTimetableSlot(
        slot.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTimetableSlot(String slotId) async {
    try {
      await _remoteDataSource.deleteTimetableSlot(slotId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishTimetable(String timetableId) async {
    try {
      await _remoteDataSource.publishTimetable(timetableId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TimetableSlotEntity>>> checkSlotConflicts(
    TimetableSlotEntity slot,
  ) async {
    try {
      final conflicts = await _remoteDataSource.checkSlotConflicts(
        teacherId: slot.teacherId,
        classId: slot.classId,
        dayOfWeek: slot.dayOfWeek.value,
        periodNumber: slot.periodNumber,
        excludeSlotId: slot.id.isNotEmpty ? slot.id : null,
      );
      // Convert conflict maps to TimetableSlotEntity objects
      final entities = conflicts
          .map((map) => TimetableSlotModel.fromJson(map).toEntity())
          .toList();
      return Success(entities);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AttendanceRecordEntity>> createAttendanceRecord(
    AttendanceRecordEntity record,
  ) async {
    try {
      final model = AttendanceRecordModel.fromEntity(record);
      final created =
          await _remoteDataSource.createAttendanceRecord(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AttendanceRecordEntity>> updateAttendanceRecord(
    AttendanceRecordEntity record,
  ) async {
    try {
      final model = AttendanceRecordModel.fromEntity(record);
      final updated = await _remoteDataSource.updateAttendanceRecord(
        record.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AttendanceRecordEntity>> getAttendanceRecord({
    required String classId,
    required String termId,
    required DateTime date,
    String attendanceType = 'student',
  }) async {
    try {
      final model = await _remoteDataSource.getAttendanceRecord(
        classId: classId,
        termId: termId,
        date: date.toIso8601String(),
        type: attendanceType,
      );
      if (model == null) {
        return FailureResult(Failure.notFound(
          message: 'Attendance record not found for the specified criteria',
        ));
      }
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AttendanceRecordEntity>>> getAttendanceRecords({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getAttendanceRecords(
        schoolId: schoolId,
        termId: termId,
        classId: classId,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AttendanceSummaryEntity>> getAttendanceSummary({
    required String classId,
    required String termId,
  }) async {
    try {
      final data = await _remoteDataSource.getAttendanceSummary(
        classId,
        termId,
      );
      return Success(AttendanceSummaryEntity(
        classId: data['class_id'] as String? ?? classId,
        termId: data['term_id'] as String? ?? termId,
        className: data['class_name'] as String?,
        totalStudents: data['total_students'] as int? ?? 0,
        totalDays: data['total_days'] as int? ?? 0,
        presentCount: data['present_count'] as int? ?? 0,
        absentCount: data['absent_count'] as int? ?? 0,
        lateCount: data['late_count'] as int? ?? 0,
        excusedCount: data['excused_count'] as int? ?? 0,
        averageAttendanceRate:
            (data['average_attendance_rate'] as num?)?.toDouble() ?? 0.0,
        topAttendees: _parseStudentAttendanceDetails(
          data['top_attendees'] as List<dynamic>? ?? [],
        ),
        lowAttendees: _parseStudentAttendanceDetails(
          data['low_attendees'] as List<dynamic>? ?? [],
        ),
      ));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAttendance({
    required String recordId,
    required List<AttendanceEntryEntity> entries,
  }) async {
    try {
      final entryMaps = entries
          .map((entry) => AttendanceEntryModel.fromEntity(entry).toJson())
          .toList();
      await _remoteDataSource.markAttendance(recordId, entryMaps);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HOMEWORK
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<HomeworkEntity>> createHomework(
    HomeworkEntity homework,
  ) async {
    try {
      final model = HomeworkModel.fromEntity(homework);
      final created =
          await _remoteDataSource.createHomework(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<HomeworkEntity>> updateHomework(
    HomeworkEntity homework,
  ) async {
    try {
      final model = HomeworkModel.fromEntity(homework);
      final updated = await _remoteDataSource.updateHomework(
        homework.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteHomework(String homeworkId) async {
    try {
      await _remoteDataSource.deleteHomework(homeworkId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<HomeworkEntity>> getHomework(String homeworkId) async {
    try {
      final model = await _remoteDataSource.getHomework(homeworkId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<HomeworkEntity>>> getHomeworkList({
    required String schoolId,
    String? classId,
    String? subjectId,
    String? teacherId,
    HomeworkStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getHomeworkList(
        schoolId: schoolId,
        classId: classId,
        subjectId: subjectId,
        teacherId: teacherId,
        status: status?.value,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishHomework(String homeworkId) async {
    try {
      await _remoteDataSource.publishHomework(homeworkId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<HomeworkSubmissionEntity>> submitHomework(
    HomeworkSubmissionEntity submission,
  ) async {
    try {
      final model = HomeworkSubmissionModel.fromEntity(submission);
      final created =
          await _remoteDataSource.submitHomework(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<HomeworkSubmissionEntity>> gradeSubmission(
    HomeworkSubmissionEntity submission,
  ) async {
    try {
      final model = HomeworkSubmissionModel.fromEntity(submission);
      final graded =
          await _remoteDataSource.gradeSubmission(model.toJson());
      return Success(graded.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<HomeworkSubmissionEntity>>> getHomeworkSubmissions(
    String homeworkId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getHomeworkSubmissions(homeworkId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AnnouncementEntity>> createAnnouncement(
    AnnouncementEntity announcement,
  ) async {
    try {
      final model = AnnouncementModel.fromEntity(announcement);
      final created =
          await _remoteDataSource.createAnnouncement(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AnnouncementEntity>> updateAnnouncement(
    AnnouncementEntity announcement,
  ) async {
    try {
      final model = AnnouncementModel.fromEntity(announcement);
      final updated = await _remoteDataSource.updateAnnouncement(
        announcement.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteAnnouncement(String announcementId) async {
    try {
      await _remoteDataSource.deleteAnnouncement(announcementId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AnnouncementEntity>>> getAnnouncements({
    required String schoolId,
    AnnouncementType? type,
    bool? isPublished,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getAnnouncements(
        schoolId: schoolId,
        type: type?.value,
        isPublished: isPublished,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishAnnouncement(String announcementId) async {
    try {
      await _remoteDataSource.publishAnnouncement(announcementId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DocumentEntity>> createDocument(
    DocumentEntity document,
  ) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final created =
          await _remoteDataSource.createDocument(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<DocumentEntity>> updateDocument(
    DocumentEntity document,
  ) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final updated = await _remoteDataSource.updateDocument(
        document.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteDocument(String documentId) async {
    try {
      await _remoteDataSource.deleteDocument(documentId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<DocumentEntity>>> getDocuments({
    required String schoolId,
    DocumentType? documentType,
    String? category,
    String? searchQuery,
    bool? isPublic,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getDocuments(
        schoolId: schoolId,
        documentType: documentType?.value,
        category: category,
        searchQuery: searchQuery,
        isPublic: isPublic,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> incrementDownloadCount(String documentId) async {
    try {
      await _remoteDataSource.incrementDownloadCount(documentId);
      return const Success(null);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CLASSES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ClassEntity>> getClass(String classId) async {
    try {
      final model = await _remoteDataSource.getClass(classId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ClassEntity>>> getClasses({
    required String schoolId,
    String? academicYear,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final models = await _remoteDataSource.getClasses(
        schoolId: schoolId,
        academicYear: academicYear,
        isActive: isActive,
        page: page,
        perPage: perPage,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ClassEntity>> createClass(ClassEntity classEntity) async {
    try {
      final model = ClassModel.fromEntity(classEntity);
      final created = await _remoteDataSource.createClass(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ClassEntity>> updateClass(ClassEntity classEntity) async {
    try {
      final model = ClassModel.fromEntity(classEntity);
      final updated = await _remoteDataSource.updateClass(
        classEntity.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> assignStudentsToClass(
    String classId,
    List<String> studentIds,
  ) async {
    try {
      await _remoteDataSource.assignStudentsToClass(classId, studentIds);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> removeStudentFromClass(
    String classId,
    String studentId,
  ) async {
    try {
      await _remoteDataSource.removeStudentFromClass(classId, studentId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBJECTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SubjectEntity>> getSubject(String subjectId) async {
    try {
      final model = await _remoteDataSource.getSubject(subjectId);
      return Success(model.toEntity());
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SubjectEntity>>> getSubjects({
    String? schoolId,
    String? category,
    bool? isActive,
  }) async {
    try {
      final models = await _remoteDataSource.getSubjects(
        schoolId: schoolId ?? '',
        category: category,
        isActive: isActive,
      );
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SubjectEntity>> createSubject(SubjectEntity subject) async {
    try {
      final model = SubjectModel.fromEntity(subject);
      final created =
          await _remoteDataSource.createSubject(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SubjectEntity>> updateSubject(SubjectEntity subject) async {
    try {
      final model = SubjectModel.fromEntity(subject);
      final updated = await _remoteDataSource.updateSubject(
        subject.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> assignTeacherToSubject({
    required String classId,
    required String subjectId,
    required String teacherId,
  }) async {
    try {
      final data = <String, dynamic>{
        'class_id': classId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
      };
      await _remoteDataSource.assignTeacherToSubject(data);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<Map<String, dynamic>>> getSchoolOverview(
    String schoolId,
  ) async {
    try {
      final data = await _remoteDataSource.getSchoolOverview(schoolId);
      return Success(data);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getStudentListReport({
    required String schoolId,
    String? classId,
  }) async {
    try {
      final models =
          await _remoteDataSource.getStudentListReport(schoolId, classId);
      return Success(models.map((m) => m.toJson()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getTeacherListReport(
    String schoolId,
  ) async {
    try {
      final models =
          await _remoteDataSource.getTeacherListReport(schoolId);
      return Success(models.map((m) => m.toJson()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getAttendanceReport({
    required String schoolId,
    required String termId,
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _remoteDataSource.getAttendanceReport(
        schoolId: schoolId,
        termId: termId,
        classId: classId,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
      );
      // The datasource returns a Map<String, dynamic> which may contain
      // a list under a 'records' or 'data' key, or is itself summary data.
      final records = data['records'] ?? data['data'] ?? [data];
      if (records is List) {
        return Success(
          records.cast<Map<String, dynamic>>(),
        );
      }
      return Success([data]);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Parses a list of dynamic maps into [StudentAttendanceDetail] objects.
  List<StudentAttendanceDetail> _parseStudentAttendanceDetails(
    List<dynamic> list,
  ) {
    return list.map((item) {
      final map = item as Map<String, dynamic>;
      return StudentAttendanceDetail(
        studentId: map['student_id'] as String? ?? '',
        studentName: map['student_name'] as String?,
        admissionNumber: map['admission_number'] as String?,
        presentDays: map['present_days'] as int? ?? 0,
        absentDays: map['absent_days'] as int? ?? 0,
        lateDays: map['late_days'] as int? ?? 0,
        excusedDays: map['excused_days'] as int? ?? 0,
        attendanceRate:
            (map['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
