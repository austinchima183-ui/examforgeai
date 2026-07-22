import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/repositories/teacher_workspace_repository.dart';
import '../datasources/teacher_workspace_remote_datasource.dart';
import '../models/teacher_workspace_models.dart';
import '../models/workspace_expansion_models.dart';

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
      return Failure.validation(fieldErrors: const {}, message: e.message, fieldErrors: e.fieldErrors);
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
      final original = await _remoteDataSource.getLessonPlan(planId);
      final data = original.toJson();
      data.remove('id');
      data['title'] = '${original.title} (Copy)';
      data.remove('created_at');
      data.remove('updated_at');
      final duplicated = await _remoteDataSource.createLessonPlan(data);
      return Success(duplicated.toEntity());
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
      final url = await _remoteDataSource.exportResource('worksheet', worksheetId, format);
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
      final aiParams = <String, dynamic>{
        ...params,
        'is_ai_generated': true,
      };
      final created = await _remoteDataSource.createReportComment(aiParams);
      final recentComments = await _remoteDataSource.getReportComments({
        'is_ai_generated': true,
        'teacher_id': params['teacher_id'],
        'subject_id': params['subject_id'],
      });
      return Success(recentComments.map((m) => m.toEntity()).toList());
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

      final models = await _remoteDataSource.getFolders(parentFolderId);
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
      final model = await _remoteDataSource.createContentHistory(requestParams);
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
      final data = model.toJson();
      data['target_type'] = targetType;
      final saved = await _remoteDataSource.createContentHistory(data);
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
      final models = await _remoteDataSource.getEvents(params);
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
      final models = await _remoteDataSource.getTemplates(templateType);
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
      final model = await _remoteDataSource.incrementTemplateUsage(templateId);
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
      final models = await _remoteDataSource.getVersionHistory(resourceType, resourceId);
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
      final versions = await _remoteDataSource.getVersionHistory('lesson_plan', planId);
      final version = versions.where((v) => v.versionNumber == versionNumber).firstOrNull;
      if (version == null) {
        return FailureResult(Failure.notFound(message: 'Version $versionNumber not found'));
      }
      final restored = await _remoteDataSource.updateLessonPlan(planId, version.snapshot);
      return Success(restored.toEntity());
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

  // ═══════════════════════════════════════════════════════════════════════
  // PRESENTATIONS (CRUD + AI + Export + Versioning)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<PresentationEntity>> createPresentation(PresentationEntity presentation) async {
    try {
      final model = PresentationModel.fromEntity(presentation);
      final result = await _remoteDataSource.createPresentation(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PresentationEntity>> updatePresentation(PresentationEntity presentation) async {
    try {
      final model = PresentationModel.fromEntity(presentation);
      final result = await _remoteDataSource.updatePresentation(presentation.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deletePresentation(String presentationId) async {
    try {
      await _remoteDataSource.deletePresentation(presentationId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PresentationEntity>> getPresentation(String presentationId) async {
    try {
      final model = await _remoteDataSource.getPresentation(presentationId);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<PresentationEntity>>> getPresentations(WorkspaceFilterEntity filter) async {
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

      final models = await _remoteDataSource.getPresentations(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PresentationEntity>> generatePresentation(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createPresentation({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> exportPresentation(String presentationId, String format) async {
    try {
      final url = await _remoteDataSource.exportPresentation(presentationId, format);
      return Success(url);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<WorkspaceVersionEntity>>> getPresentationVersions(String presentationId) async {
    try {
      final models = await _remoteDataSource.getPresentationVersions(presentationId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PresentationEntity>> restorePresentationVersion(
    String presentationId,
    int versionNumber,
  ) async {
    try {
      final versions = await _remoteDataSource.getPresentationVersions(presentationId);
      final version = versions.where((v) => v.versionNumber == versionNumber).firstOrNull;
      if (version == null) {
        return FailureResult(Failure.notFound(message: 'Version $versionNumber not found'));
      }
      final restored = await _remoteDataSource.updatePresentation(presentationId, version.snapshot);
      return Success(restored.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMMUNICATIONS (CRUD + AI + Send)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<CommunicationEntity>> createCommunication(CommunicationEntity communication) async {
    try {
      final model = CommunicationModel.fromEntity(communication);
      final result = await _remoteDataSource.createCommunication(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CommunicationEntity>> updateCommunication(CommunicationEntity communication) async {
    try {
      final model = CommunicationModel.fromEntity(communication);
      final result = await _remoteDataSource.updateCommunication(communication.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteCommunication(String communicationId) async {
    try {
      await _remoteDataSource.deleteCommunication(communicationId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CommunicationEntity>>> getCommunications(WorkspaceFilterEntity filter) async {
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

      final models = await _remoteDataSource.getCommunications(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CommunicationEntity>> generateCommunication(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createCommunication({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> sendCommunication(String communicationId) async {
    try {
      await _remoteDataSource.sendCommunication(communicationId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TASKS (CRUD + Complete)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TaskEntity>> createTask(TaskEntity task) async {
    try {
      final model = TaskModel.fromEntity(task);
      final result = await _remoteDataSource.createTask(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TaskEntity>> updateTask(TaskEntity task) async {
    try {
      final model = TaskModel.fromEntity(task);
      final result = await _remoteDataSource.updateTask(task.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteTask(String taskId) async {
    try {
      await _remoteDataSource.deleteTask(taskId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasks({
    String? status,
    String? category,
    DateTime? dueBefore,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (status != null) filters['status'] = status;
      if (category != null) filters['category'] = category;
      if (dueBefore != null) filters['due_before'] = dueBefore.toIso8601String();

      final models = await _remoteDataSource.getTasks(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<TaskEntity>> completeTask(String taskId, String? completionNotes) async {
    try {
      final model = await _remoteDataSource.completeTask(taskId, completionNotes);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RUBRICS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<RubricEntity>> createRubric(RubricEntity rubric) async {
    try {
      final model = RubricModel.fromEntity(rubric);
      final result = await _remoteDataSource.createRubric(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<RubricEntity>> updateRubric(RubricEntity rubric) async {
    try {
      final model = RubricModel.fromEntity(rubric);
      final result = await _remoteDataSource.updateRubric(rubric.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteRubric(String rubricId) async {
    try {
      await _remoteDataSource.deleteRubric(rubricId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<RubricEntity>>> getRubrics(WorkspaceFilterEntity filter) async {
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

      final models = await _remoteDataSource.getRubrics(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<RubricEntity>> generateRubric(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createRubric({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ORAL QUESTIONS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<OralQuestionEntity>> createOralQuestions(OralQuestionEntity oralQuestion) async {
    try {
      final model = OralQuestionModel.fromEntity(oralQuestion);
      final result = await _remoteDataSource.createOralQuestions(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<OralQuestionEntity>> updateOralQuestions(OralQuestionEntity oralQuestion) async {
    try {
      final model = OralQuestionModel.fromEntity(oralQuestion);
      final result = await _remoteDataSource.updateOralQuestions(oralQuestion.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteOralQuestions(String oralQuestionId) async {
    try {
      await _remoteDataSource.deleteOralQuestions(oralQuestionId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<OralQuestionEntity>>> getOralQuestions(WorkspaceFilterEntity filter) async {
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

      final models = await _remoteDataSource.getOralQuestions(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<OralQuestionEntity>> generateOralQuestions(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createOralQuestions({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRACTICAL ASSESSMENTS (CRUD + AI)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<PracticalAssessmentEntity>> createPracticalAssessment(PracticalAssessmentEntity assessment) async {
    try {
      final model = PracticalAssessmentModel.fromEntity(assessment);
      final result = await _remoteDataSource.createPracticalAssessment(model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PracticalAssessmentEntity>> updatePracticalAssessment(PracticalAssessmentEntity assessment) async {
    try {
      final model = PracticalAssessmentModel.fromEntity(assessment);
      final result = await _remoteDataSource.updatePracticalAssessment(assessment.id, model.toJson());
      return Success(result.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deletePracticalAssessment(String assessmentId) async {
    try {
      await _remoteDataSource.deletePracticalAssessment(assessmentId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<PracticalAssessmentEntity>>> getPracticalAssessments(WorkspaceFilterEntity filter) async {
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

      final models = await _remoteDataSource.getPracticalAssessments(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<PracticalAssessmentEntity>> generatePracticalAssessment(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.createPracticalAssessment({
        ...params,
        'is_ai_generated': true,
        'ai_prompt_snapshot': params,
      });
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COLLABORATION (Share, Accept/Decline, Comments)
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<SharedResourceEntity>> shareResource(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.shareResource(params);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<SharedResourceEntity>>> getSharedResources({
    String? resourceType,
    bool? pendingOnly,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (resourceType != null) filters['resource_type'] = resourceType;
      if (pendingOnly != null) filters['pending_only'] = pendingOnly;

      final models = await _remoteDataSource.getSharedResources(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> acceptSharedResource(String sharedResourceId) async {
    try {
      await _remoteDataSource.acceptSharedResource(sharedResourceId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> declineSharedResource(String sharedResourceId) async {
    try {
      await _remoteDataSource.declineSharedResource(sharedResourceId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<CollaborationCommentEntity>> addComment(Map<String, dynamic> params) async {
    try {
      final model = await _remoteDataSource.addComment(params);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CollaborationCommentEntity>>> getComments(
    String resourceType,
    String resourceId,
  ) async {
    try {
      final models = await _remoteDataSource.getComments(resourceType, resourceId);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> resolveComment(String commentId) async {
    try {
      await _remoteDataSource.resolveComment(commentId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENHANCED DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<EnhancedWorkspaceDashboardEntity>> getEnhancedDashboard() async {
    try {
      final model = await _remoteDataSource.getEnhancedDashboard();
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(message: e.message, statusCode: e.statusCode, data: e.data));
    } catch (e) {
      return FailureResult(_mapExceptionToFailure(e));
    }
  }
}
