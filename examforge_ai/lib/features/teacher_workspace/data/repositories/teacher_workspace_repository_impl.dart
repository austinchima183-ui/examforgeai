import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/repositories/teacher_workspace_repository.dart';
import '../datasources/teacher_workspace_remote_datasource.dart';
import '../models/teacher_workspace_models.dart';

class TeacherWorkspaceRepositoryImpl implements TeacherWorkspaceRepository {
  TeacherWorkspaceRepositoryImpl({
    required TeacherWorkspaceRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final TeacherWorkspaceRemoteDataSource _remoteDataSource;

  /// Helper: Convert exceptions to Failures
  Failure _mapExceptionToFailure(Object e) {
    if (e is AuthException) {
      return Failure.auth(message: e.message, code: e.code);
    } else if (e is ServerException) {
      return Failure.server(message: e.message, statusCode: e.statusCode, data: e.data);
    } else if (e is CacheException) {
      return Failure.cache(message: e.message);
    } else if (e is NetworkException) {
      return Failure.network(message: e.message);
    } else if (e is ValidationException) {
      return Failure.validation(message: e.message, fieldErrors: e.fieldErrors);
    } else if (e is NotFoundException) {
      return Failure.notFound(message: e.message);
    } else if (e is UnauthorizedException) {
      return Failure.unauthorized(message: e.message);
    } else if (e is ForbiddenException) {
      return Failure.forbidden(message: e.message);
    } else {
      AppLogger.error('Unexpected exception in TeacherWorkspaceRepositoryImpl', error: e);
      return Failure.server(message: 'An unexpected error occurred: $e', statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<WorkspaceDashboardEntity>> getDashboardSummary() async {
    try {
      final model = await _remoteDataSource.getDashboardSummary();
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LESSON PLANS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<LessonPlanEntity>> createLessonPlan(LessonPlanEntity plan) async {
    try {
      final model = LessonPlanModel.fromEntity(plan);
      final created = await _remoteDataSource.createLessonPlan(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LessonPlanEntity>> updateLessonPlan(LessonPlanEntity plan) async {
    try {
      final model = LessonPlanModel.fromEntity(plan);
      final updated = await _remoteDataSource.updateLessonPlan(plan.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteLessonPlan(String planId) async {
    try {
      await _remoteDataSource.deleteLessonPlan(planId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LessonPlanEntity>> getLessonPlan(String planId) async {
    try {
      final model = await _remoteDataSource.getLessonPlan(planId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<LessonPlanEntity>>> getLessonPlans(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getLessonPlans(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LessonPlanEntity>> generateLessonPlan(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createLessonPlan({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishLessonPlan(String planId) async {
    try {
      await _remoteDataSource.updateLessonPlan(planId, {'is_published': true});
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> archiveLessonPlan(String planId) async {
    try {
      await _remoteDataSource.updateLessonPlan(planId, {'is_archived': true});
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LessonPlanEntity>> duplicateLessonPlan(String planId) async {
    try {
      final model = await _remoteDataSource.duplicateLessonPlan(planId);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHEMES OF WORK (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SchemeOfWorkEntity>> createSchemeOfWork(SchemeOfWorkEntity scheme) async {
    try {
      final model = SchemeOfWorkModel.fromEntity(scheme);
      final created = await _remoteDataSource.createSchemeOfWork(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchemeOfWorkEntity>> updateSchemeOfWork(SchemeOfWorkEntity scheme) async {
    try {
      final model = SchemeOfWorkModel.fromEntity(scheme);
      final updated = await _remoteDataSource.updateSchemeOfWork(scheme.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteSchemeOfWork(String schemeId) async {
    try {
      await _remoteDataSource.deleteSchemeOfWork(schemeId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchemeOfWorkEntity>> getSchemeOfWork(String schemeId) async {
    try {
      final model = await _remoteDataSource.getSchemeOfWork(schemeId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SchemeOfWorkEntity>>> getSchemesOfWork(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getSchemesOfWork(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<SchemeOfWorkEntity>> generateSchemeOfWork(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createSchemeOfWork({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WORKSHEETS (CRUD + AI + Export)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<WorksheetEntity>> createWorksheet(WorksheetEntity worksheet) async {
    try {
      final model = WorksheetModel.fromEntity(worksheet);
      final created = await _remoteDataSource.createWorksheet(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorksheetEntity>> updateWorksheet(WorksheetEntity worksheet) async {
    try {
      final model = WorksheetModel.fromEntity(worksheet);
      final updated = await _remoteDataSource.updateWorksheet(worksheet.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteWorksheet(String worksheetId) async {
    try {
      await _remoteDataSource.deleteWorksheet(worksheetId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorksheetEntity>> getWorksheet(String worksheetId) async {
    try {
      final model = await _remoteDataSource.getWorksheet(worksheetId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<WorksheetEntity>>> getWorksheets(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getWorksheets(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorksheetEntity>> generateWorksheet(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createWorksheet({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> exportWorksheet(String worksheetId, String format) async {
    try {
      final url = await _remoteDataSource.exportWorksheet(worksheetId, format);
      return Success(url);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENTS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<WorkspaceAssignmentEntity>> createAssignment(WorkspaceAssignmentEntity assignment) async {
    try {
      final model = WorkspaceAssignmentModel.fromEntity(assignment);
      final created = await _remoteDataSource.createAssignment(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorkspaceAssignmentEntity>> updateAssignment(WorkspaceAssignmentEntity assignment) async {
    try {
      final model = WorkspaceAssignmentModel.fromEntity(assignment);
      final updated = await _remoteDataSource.updateAssignment(assignment.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteAssignment(String assignmentId) async {
    try {
      await _remoteDataSource.deleteAssignment(assignmentId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorkspaceAssignmentEntity>> getAssignment(String assignmentId) async {
    try {
      final model = await _remoteDataSource.getAssignment(assignmentId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<WorkspaceAssignmentEntity>>> getAssignments(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getAssignments(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorkspaceAssignmentEntity>> generateAssignment(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createAssignment({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishAssignment(String assignmentId) async {
    try {
      await _remoteDataSource.updateAssignment(assignmentId, {'is_published': true});
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORT COMMENTS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ReportCommentEntity>> createReportComment(ReportCommentEntity comment) async {
    try {
      final model = ReportCommentModel.fromEntity(comment);
      final created = await _remoteDataSource.createReportComment(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ReportCommentEntity>> updateReportComment(ReportCommentEntity comment) async {
    try {
      final model = ReportCommentModel.fromEntity(comment);
      final updated = await _remoteDataSource.updateReportComment(comment.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteReportComment(String commentId) async {
    try {
      await _remoteDataSource.deleteReportComment(commentId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ReportCommentEntity>>> getReportComments(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getReportComments(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ReportCommentEntity>>> generateReportComments(Map<String, dynamic> params) async {
    try {
      final models = await _remoteDataSource.generateReportComments({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> publishReportComment(String commentId) async {
    try {
      await _remoteDataSource.updateReportComment(commentId, {'is_published': true});
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHING RESOURCES (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TeachingResourceEntity>> createResource(TeachingResourceEntity resource) async {
    try {
      final model = TeachingResourceModel.fromEntity(resource);
      final created = await _remoteDataSource.createResource(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeachingResourceEntity>> updateResource(TeachingResourceEntity resource) async {
    try {
      final model = TeachingResourceModel.fromEntity(resource);
      final updated = await _remoteDataSource.updateResource(resource.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteResource(String resourceId) async {
    try {
      await _remoteDataSource.deleteResource(resourceId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeachingResourceEntity>> getResource(String resourceId) async {
    try {
      final model = await _remoteDataSource.getResource(resourceId);
      return Success(model.toEntity());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TeachingResourceEntity>>> getResources(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.subjectId != null) filters['subject_id'] = filter.subjectId;
      if (filter.classId != null) filters['class_id'] = filter.classId;
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;
      if (filter.isPublished != null) filters['is_published'] = filter.isPublished;
      filters['is_archived'] = filter.isArchived;
      if (filter.tags.isNotEmpty) filters['tags'] = filter.tags;

      final models = await _remoteDataSource.getResources(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TeachingResourceEntity>> generateResource(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createResource({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String resourceId) async {
    try {
      final resource = await _remoteDataSource.getResource(resourceId);
      await _remoteDataSource.updateResource(resourceId, {
        'is_favorite': !resource.isFavorite,
      });
      return const Success(null);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESOURCE FOLDERS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<ResourceFolderEntity>> createFolder(ResourceFolderEntity folder) async {
    try {
      final model = ResourceFolderModel.fromEntity(folder);
      final created = await _remoteDataSource.createFolder(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ResourceFolderEntity>> updateFolder(ResourceFolderEntity folder) async {
    try {
      final model = ResourceFolderModel.fromEntity(folder);
      final updated = await _remoteDataSource.updateFolder(folder.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    try {
      await _remoteDataSource.deleteFolder(folderId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<ResourceFolderEntity>>> getFolders(String? parentFolderId) async {
    try {
      final filters = <String, dynamic>{};
      if (parentFolderId != null) filters['parent_folder_id'] = parentFolderId;

      final models = await _remoteDataSource.getFolders(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI CONTENT ASSISTANT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<AiContentHistoryEntity>> generateContent(
    ContentAction action,
    String sourceContent,
    Map<String, dynamic>? params,
  ) async {
    try {
      final requestParams = <String, dynamic>{
        'action': action.value,
        'source_content': sourceContent,
        if (params != null) ...params,
      };
      final model = await _remoteDataSource.generateContent(requestParams);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<AiContentHistoryEntity>>> getContentHistory(WorkspaceFilterEntity filter) async {
    try {
      final filters = <String, dynamic>{
        'page': filter.page,
        'perPage': filter.perPage,
      };
      if (filter.searchQuery != null) filters['searchQuery'] = filter.searchQuery;

      final models = await _remoteDataSource.getContentHistory(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<AiContentHistoryEntity>> saveContentAs(
    AiContentHistoryEntity history,
    String targetType,
  ) async {
    try {
      final model = AiContentHistoryModel.fromEntity(history);
      final saved = await _remoteDataSource.saveContentAs(model.toJson(), targetType);
      return Success(saved.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR & PLANNER
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CalendarEventEntity>> createEvent(CalendarEventEntity event) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final created = await _remoteDataSource.createEvent(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CalendarEventEntity>> updateEvent(CalendarEventEntity event) async {
    try {
      final model = CalendarEventModel.fromEntity(event);
      final updated = await _remoteDataSource.updateEvent(event.id, model.toJson());
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    try {
      await _remoteDataSource.deleteEvent(eventId);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CalendarEventEntity>>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (startDate != null) filters['start_date'] = startDate.toIso8601String();
      if (endDate != null) filters['end_date'] = endDate.toIso8601String();

      final models = await _remoteDataSource.getEvents(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CalendarEventEntity>>> suggestSchedule(Map<String, dynamic> params) async {
    try {
      final models = await _remoteDataSource.suggestSchedule(params);
      return Success(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<WorkspaceTemplateEntity>> createTemplate(WorkspaceTemplateEntity template) async {
    try {
      final model = WorkspaceTemplateModel.fromEntity(template);
      final created = await _remoteDataSource.createTemplate(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<WorkspaceTemplateEntity>>> getTemplates(String templateType) async {
    try {
      final models = await _remoteDataSource.getTemplates({'template_type': templateType});
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<WorkspaceTemplateEntity>> useTemplate(String templateId) async {
    try {
      final model = await _remoteDataSource.useTemplate(templateId);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VERSION HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<WorkspaceVersionEntity>>> getVersionHistory(
    String resourceType,
    String resourceId,
  ) async {
    try {
      final models = await _remoteDataSource.getVersionHistory({
        'resource_type': resourceType,
        'resource_id': resourceId,
      });
      return Success(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<LessonPlanEntity>> restoreLessonPlanVersion(
    String planId,
    int versionNumber,
  ) async {
    try {
      final model = await _remoteDataSource.restoreLessonPlanVersion(planId, versionNumber);
      return Success(model.toEntity());
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPORT (general)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<String>> exportResource(
    String resourceType,
    String resourceId,
    String format,
  ) async {
    try {
      final url = await _remoteDataSource.exportResource(resourceType, resourceId, format);
      return Success(url);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATE QUESTIONS INTEGRATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<Map<String, dynamic>>> generateQuestionsFromContent(
    String resourceType,
    String resourceId,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await _remoteDataSource.generateQuestionsFromContent({
        'resource_type': resourceType,
        'resource_id': resourceId,
        ...params,
      });
      return Success(result);
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
