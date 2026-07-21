import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/teacher_workspace_models.dart';
import '../models/workspace_expansion_models.dart';

abstract class TeacherWorkspaceRemoteDataSource {
  // ── Dashboard ──────────────────────────────────────────────────────────
  Future<WorkspaceDashboardModel> getDashboardSummary();

  // ── Lesson Plans ───────────────────────────────────────────────────────
  Future<LessonPlanModel> createLessonPlan(Map<String, dynamic> data);
  Future<LessonPlanModel> updateLessonPlan(String id, Map<String, dynamic> data);
  Future<void> deleteLessonPlan(String id);
  Future<LessonPlanModel> getLessonPlan(String id);
  Future<List<LessonPlanModel>> getLessonPlans(Map<String, dynamic> filters);

  // ── Schemes of Work ────────────────────────────────────────────────────
  Future<SchemeOfWorkModel> createSchemeOfWork(Map<String, dynamic> data);
  Future<SchemeOfWorkModel> updateSchemeOfWork(String id, Map<String, dynamic> data);
  Future<void> deleteSchemeOfWork(String id);
  Future<SchemeOfWorkModel> getSchemeOfWork(String id);
  Future<List<SchemeOfWorkModel>> getSchemesOfWork(Map<String, dynamic> filters);

  // ── Worksheets ─────────────────────────────────────────────────────────
  Future<WorksheetModel> createWorksheet(Map<String, dynamic> data);
  Future<WorksheetModel> updateWorksheet(String id, Map<String, dynamic> data);
  Future<void> deleteWorksheet(String id);
  Future<WorksheetModel> getWorksheet(String id);
  Future<List<WorksheetModel>> getWorksheets(Map<String, dynamic> filters);

  // ── Assignments ────────────────────────────────────────────────────────
  Future<WorkspaceAssignmentModel> createAssignment(Map<String, dynamic> data);
  Future<WorkspaceAssignmentModel> updateAssignment(String id, Map<String, dynamic> data);
  Future<void> deleteAssignment(String id);
  Future<WorkspaceAssignmentModel> getAssignment(String id);
  Future<List<WorkspaceAssignmentModel>> getAssignments(Map<String, dynamic> filters);

  // ── Report Comments ────────────────────────────────────────────────────
  Future<ReportCommentModel> createReportComment(Map<String, dynamic> data);
  Future<ReportCommentModel> updateReportComment(String id, Map<String, dynamic> data);
  Future<void> deleteReportComment(String id);
  Future<List<ReportCommentModel>> getReportComments(Map<String, dynamic> filters);

  // ── Teaching Resources ─────────────────────────────────────────────────
  Future<TeachingResourceModel> createResource(Map<String, dynamic> data);
  Future<TeachingResourceModel> updateResource(String id, Map<String, dynamic> data);
  Future<void> deleteResource(String id);
  Future<TeachingResourceModel> getResource(String id);
  Future<List<TeachingResourceModel>> getResources(Map<String, dynamic> filters);

  // ── Resource Folders ───────────────────────────────────────────────────
  Future<ResourceFolderModel> createFolder(Map<String, dynamic> data);
  Future<ResourceFolderModel> updateFolder(String id, Map<String, dynamic> data);
  Future<void> deleteFolder(String id);
  Future<List<ResourceFolderModel>> getFolders(String? parentFolderId);

  // ── AI Content History ─────────────────────────────────────────────────
  Future<AiContentHistoryModel> createContentHistory(Map<String, dynamic> data);
  Future<AiContentHistoryModel> updateContentHistory(String id, Map<String, dynamic> data);
  Future<List<AiContentHistoryModel>> getContentHistory(Map<String, dynamic> filters);

  // ── Calendar Events ────────────────────────────────────────────────────
  Future<CalendarEventModel> createEvent(Map<String, dynamic> data);
  Future<CalendarEventModel> updateEvent(String id, Map<String, dynamic> data);
  Future<void> deleteEvent(String id);
  Future<List<CalendarEventModel>> getEvents(Map<String, dynamic> filters);

  // ── Templates ──────────────────────────────────────────────────────────
  Future<WorkspaceTemplateModel> createTemplate(Map<String, dynamic> data);
  Future<List<WorkspaceTemplateModel>> getTemplates(String templateType);
  Future<WorkspaceTemplateModel> incrementTemplateUsage(String id);

  // ── Version History ────────────────────────────────────────────────────
  Future<List<WorkspaceVersionModel>> getVersionHistory(
    String resourceType,
    String resourceId,
  );

  // ── Export ─────────────────────────────────────────────────────────────
  Future<String> exportResource(
    String resourceType,
    String resourceId,
    String format,
  );

  // ── AI Question Generation ─────────────────────────────────────────────
  Future<Map<String, dynamic>> generateQuestionsFromContent(
    Map<String, dynamic> params,
  );

  // ── Presentations ────────────────────────────────────────────────────
  Future<PresentationModel> createPresentation(Map<String, dynamic> data);
  Future<PresentationModel> updatePresentation(String id, Map<String, dynamic> data);
  Future<void> deletePresentation(String id);
  Future<PresentationModel> getPresentation(String id);
  Future<List<PresentationModel>> getPresentations(Map<String, dynamic> filters);
  Future<PresentationModel> generatePresentationAI(Map<String, dynamic> params);
  Future<String> exportPresentation(String id, String format);
  Future<List<PresentationVersionModel>> getPresentationVersions(String presentationId);

  // ── Communications ───────────────────────────────────────────────────
  Future<CommunicationModel> createCommunication(Map<String, dynamic> data);
  Future<CommunicationModel> updateCommunication(String id, Map<String, dynamic> data);
  Future<void> deleteCommunication(String id);
  Future<List<CommunicationModel>> getCommunications(Map<String, dynamic> filters);
  Future<CommunicationModel> generateCommunicationAI(Map<String, dynamic> params);
  Future<void> sendCommunication(String id);

  // ── Tasks ────────────────────────────────────────────────────────────
  Future<TaskModel> createTask(Map<String, dynamic> data);
  Future<TaskModel> updateTask(String id, Map<String, dynamic> data);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> getTasks(Map<String, dynamic> filters);
  Future<TaskModel> completeTask(String id, String? completionNotes);

  // ── Rubrics ──────────────────────────────────────────────────────────
  Future<RubricModel> createRubric(Map<String, dynamic> data);
  Future<RubricModel> updateRubric(String id, Map<String, dynamic> data);
  Future<void> deleteRubric(String id);
  Future<List<RubricModel>> getRubrics(Map<String, dynamic> filters);
  Future<RubricModel> generateRubricAI(Map<String, dynamic> params);

  // ── Oral Questions ───────────────────────────────────────────────────
  Future<OralQuestionModel> createOralQuestions(Map<String, dynamic> data);
  Future<OralQuestionModel> updateOralQuestions(String id, Map<String, dynamic> data);
  Future<void> deleteOralQuestions(String id);
  Future<List<OralQuestionModel>> getOralQuestions(Map<String, dynamic> filters);
  Future<OralQuestionModel> generateOralQuestionsAI(Map<String, dynamic> params);

  // ── Practical Assessments ────────────────────────────────────────────
  Future<PracticalAssessmentModel> createPracticalAssessment(Map<String, dynamic> data);
  Future<PracticalAssessmentModel> updatePracticalAssessment(String id, Map<String, dynamic> data);
  Future<void> deletePracticalAssessment(String id);
  Future<List<PracticalAssessmentModel>> getPracticalAssessments(Map<String, dynamic> filters);
  Future<PracticalAssessmentModel> generatePracticalAssessmentAI(Map<String, dynamic> params);

  // ── Collaboration ────────────────────────────────────────────────────
  Future<SharedResourceModel> shareResource(Map<String, dynamic> data);
  Future<List<SharedResourceModel>> getSharedResources(Map<String, dynamic> filters);
  Future<void> acceptSharedResource(String id);
  Future<void> declineSharedResource(String id);
  Future<CollaborationCommentModel> addComment(Map<String, dynamic> data);
  Future<List<CollaborationCommentModel>> getComments(String resourceType, String resourceId);
  Future<void> resolveComment(String commentId);

  // ── Enhanced Dashboard ───────────────────────────────────────────────
  Future<EnhancedDashboardModel> getEnhancedDashboard();
}

class TeacherWorkspaceRemoteDataSourceImpl
    implements TeacherWorkspaceRemoteDataSource {
  TeacherWorkspaceRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _lessonPlansTable = 'lesson_plans';
  static const _schemesOfWorkTable = 'schemes_of_work';
  static const _worksheetsTable = 'worksheets';
  static const _assignmentsTable = 'workspace_assignments';
  static const _reportCommentsTable = 'report_comments';
  static const _resourcesTable = 'teaching_resources';
  static const _foldersTable = 'resource_folders';
  static const _aiHistoryTable = 'ai_content_history';
  static const _calendarEventsTable = 'calendar_events';
  static const _templatesTable = 'workspace_templates';
  static const _versionHistoryTable = 'workspace_version_history';
  static const String _presentationsTable = 'presentations';
  static const String _presentationVersionsTable = 'presentation_versions';
  static const String _communicationsTable = 'communications';
  static const String _tasksTable = 'tasks';
  static const String _rubricsTable = 'rubrics';
  static const String _oralQuestionsTable = 'oral_questions';
  static const String _practicalAssessmentsTable = 'practical_assessments';
  static const String _sharedResourcesTable = 'shared_resources';
  static const String _commentsTable = 'collaboration_comments';

  // ── Exception mapping helper ───────────────────────────────────────────
  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(e.message);
      case '23505':
        throw ServerException(
          message: 'A record with this data already exists.',
          statusCode: 409,
        );
      case '23503':
        throw ServerException(
          message: 'Referenced record not found.',
          statusCode: 404,
        );
      case '42501':
        throw ForbiddenException('You do not have permission for this action.');
      default:
        throw ServerException(
          message: e.message,
          statusCode: int.tryParse(e.code ?? '') ?? 500,
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<WorkspaceDashboardModel> getDashboardSummary() async {
    try {
      AppLogger.info('Fetching teacher workspace dashboard summary');
      final response = await _supabase.rpc('get_teacher_workspace_summary');
      AppLogger.info('Dashboard summary fetched successfully');
      return WorkspaceDashboardModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard summary', error: e);
      throw ServerException(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LESSON PLANS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<LessonPlanModel> createLessonPlan(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating lesson plan');
      final response = await _supabase
          .from(_lessonPlansTable)
          .insert(data)
          .select();
      AppLogger.info('Lesson plan created successfully');
      return LessonPlanModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create lesson plan', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<LessonPlanModel> updateLessonPlan(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating lesson plan: $id');
      final response = await _supabase
          .from(_lessonPlansTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Lesson plan updated successfully: $id');
      return LessonPlanModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update lesson plan: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteLessonPlan(String id) async {
    try {
      AppLogger.info('Deleting lesson plan: $id');
      await _supabase.from(_lessonPlansTable).delete().eq('id', id);
      AppLogger.info('Lesson plan deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete lesson plan: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<LessonPlanModel> getLessonPlan(String id) async {
    try {
      AppLogger.info('Fetching lesson plan: $id');
      final response = await _supabase
          .from(_lessonPlansTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Lesson plan fetched successfully: $id');
      return LessonPlanModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch lesson plan: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<LessonPlanModel>> getLessonPlans(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching lesson plans with filters: $filters');
      var query = _supabase.from(_lessonPlansTable).select();

      // Search filter
      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }

      // Subject filter
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }

      // Class filter
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }

      // Published filter
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }

      // Archived filter
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }

      // Tags overlap filter
      if (filters['tags'] != null) {
        query = query.overlaps('tags', filters['tags']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} lesson plans');
      return response.map(LessonPlanModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch lesson plans', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCHEMES OF WORK
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<SchemeOfWorkModel> createSchemeOfWork(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating scheme of work');
      final response = await _supabase
          .from(_schemesOfWorkTable)
          .insert(data)
          .select();
      AppLogger.info('Scheme of work created successfully');
      return SchemeOfWorkModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create scheme of work', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<SchemeOfWorkModel> updateSchemeOfWork(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating scheme of work: $id');
      final response = await _supabase
          .from(_schemesOfWorkTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Scheme of work updated successfully: $id');
      return SchemeOfWorkModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update scheme of work: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteSchemeOfWork(String id) async {
    try {
      AppLogger.info('Deleting scheme of work: $id');
      await _supabase.from(_schemesOfWorkTable).delete().eq('id', id);
      AppLogger.info('Scheme of work deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete scheme of work: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<SchemeOfWorkModel> getSchemeOfWork(String id) async {
    try {
      AppLogger.info('Fetching scheme of work: $id');
      final response = await _supabase
          .from(_schemesOfWorkTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Scheme of work fetched successfully: $id');
      return SchemeOfWorkModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch scheme of work: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<SchemeOfWorkModel>> getSchemesOfWork(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching schemes of work with filters: $filters');
      var query = _supabase.from(_schemesOfWorkTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }
      if (filters['tags'] != null) {
        query = query.overlaps('tags', filters['tags']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} schemes of work');
      return response.map(SchemeOfWorkModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch schemes of work', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WORKSHEETS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<WorksheetModel> createWorksheet(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating worksheet');
      final response = await _supabase
          .from(_worksheetsTable)
          .insert(data)
          .select();
      AppLogger.info('Worksheet created successfully');
      return WorksheetModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create worksheet', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<WorksheetModel> updateWorksheet(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating worksheet: $id');
      final response = await _supabase
          .from(_worksheetsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Worksheet updated successfully: $id');
      return WorksheetModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update worksheet: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteWorksheet(String id) async {
    try {
      AppLogger.info('Deleting worksheet: $id');
      await _supabase.from(_worksheetsTable).delete().eq('id', id);
      AppLogger.info('Worksheet deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete worksheet: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<WorksheetModel> getWorksheet(String id) async {
    try {
      AppLogger.info('Fetching worksheet: $id');
      final response = await _supabase
          .from(_worksheetsTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Worksheet fetched successfully: $id');
      return WorksheetModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch worksheet: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<WorksheetModel>> getWorksheets(Map<String, dynamic> filters) async {
    try {
      AppLogger.info('Fetching worksheets with filters: $filters');
      var query = _supabase.from(_worksheetsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }
      if (filters['tags'] != null) {
        query = query.overlaps('tags', filters['tags']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} worksheets');
      return response.map(WorksheetModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch worksheets', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<WorkspaceAssignmentModel> createAssignment(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating assignment');
      final response = await _supabase
          .from(_assignmentsTable)
          .insert(data)
          .select();
      AppLogger.info('Assignment created successfully');
      return WorkspaceAssignmentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create assignment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<WorkspaceAssignmentModel> updateAssignment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating assignment: $id');
      final response = await _supabase
          .from(_assignmentsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Assignment updated successfully: $id');
      return WorkspaceAssignmentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update assignment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteAssignment(String id) async {
    try {
      AppLogger.info('Deleting assignment: $id');
      await _supabase.from(_assignmentsTable).delete().eq('id', id);
      AppLogger.info('Assignment deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete assignment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<WorkspaceAssignmentModel> getAssignment(String id) async {
    try {
      AppLogger.info('Fetching assignment: $id');
      final response = await _supabase
          .from(_assignmentsTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Assignment fetched successfully: $id');
      return WorkspaceAssignmentModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch assignment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<WorkspaceAssignmentModel>> getAssignments(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching assignments with filters: $filters');
      var query = _supabase.from(_assignmentsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }
      if (filters['status'] != null) {
        query = query.eq('status', filters['status']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} assignments');
      return response.map(WorkspaceAssignmentModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch assignments', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REPORT COMMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ReportCommentModel> createReportComment(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating report comment');
      final response = await _supabase
          .from(_reportCommentsTable)
          .insert(data)
          .select();
      AppLogger.info('Report comment created successfully');
      return ReportCommentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create report comment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ReportCommentModel> updateReportComment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating report comment: $id');
      final response = await _supabase
          .from(_reportCommentsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Report comment updated successfully: $id');
      return ReportCommentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update report comment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteReportComment(String id) async {
    try {
      AppLogger.info('Deleting report comment: $id');
      await _supabase.from(_reportCommentsTable).delete().eq('id', id);
      AppLogger.info('Report comment deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete report comment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<ReportCommentModel>> getReportComments(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching report comments with filters: $filters');
      var query = _supabase.from(_reportCommentsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('comment_text', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['student_id'] != null) {
        query = query.eq('student_id', filters['student_id']);
      }
      if (filters['category'] != null) {
        query = query.eq('category', filters['category']);
      }
      if (filters['is_ai_generated'] != null) {
        query = query.eq('is_ai_generated', filters['is_ai_generated']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} report comments');
      return response.map(ReportCommentModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch report comments', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEACHING RESOURCES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<TeachingResourceModel> createResource(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating teaching resource');
      final response = await _supabase
          .from(_resourcesTable)
          .insert(data)
          .select();
      AppLogger.info('Teaching resource created successfully');
      return TeachingResourceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create teaching resource', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TeachingResourceModel> updateResource(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating teaching resource: $id');
      final response = await _supabase
          .from(_resourcesTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Teaching resource updated successfully: $id');
      return TeachingResourceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update teaching resource: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteResource(String id) async {
    try {
      AppLogger.info('Deleting teaching resource: $id');
      await _supabase.from(_resourcesTable).delete().eq('id', id);
      AppLogger.info('Teaching resource deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete teaching resource: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TeachingResourceModel> getResource(String id) async {
    try {
      AppLogger.info('Fetching teaching resource: $id');
      final response = await _supabase
          .from(_resourcesTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Teaching resource fetched successfully: $id');
      return TeachingResourceModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch teaching resource: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<TeachingResourceModel>> getResources(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching teaching resources with filters: $filters');
      var query = _supabase.from(_resourcesTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['resource_type'] != null) {
        query = query.eq('resource_type', filters['resource_type']);
      }
      if (filters['folder_id'] != null) {
        query = query.eq('folder_id', filters['folder_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }
      if (filters['tags'] != null) {
        query = query.overlaps('tags', filters['tags']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} teaching resources');
      return response.map(TeachingResourceModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch teaching resources', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESOURCE FOLDERS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<ResourceFolderModel> createFolder(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating resource folder');
      final response = await _supabase
          .from(_foldersTable)
          .insert(data)
          .select();
      AppLogger.info('Resource folder created successfully');
      return ResourceFolderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create resource folder', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ResourceFolderModel> updateFolder(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating resource folder: $id');
      final response = await _supabase
          .from(_foldersTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Resource folder updated successfully: $id');
      return ResourceFolderModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update resource folder: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    try {
      AppLogger.info('Deleting resource folder: $id');
      await _supabase.from(_foldersTable).delete().eq('id', id);
      AppLogger.info('Resource folder deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete resource folder: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<ResourceFolderModel>> getFolders(String? parentFolderId) async {
    try {
      AppLogger.info('Fetching resource folders (parentFolderId: $parentFolderId)');
      var query = _supabase.from(_foldersTable).select();

      if (parentFolderId != null) {
        query = query.eq('parent_folder_id', parentFolderId);
      } else {
        query = query.isFilter('parent_folder_id', null);
      }

      final response = await query.order('name', ascending: true);
      AppLogger.info('Fetched ${response.length} resource folders');
      return response.map(ResourceFolderModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch resource folders', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI CONTENT HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<AiContentHistoryModel> createContentHistory(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating AI content history record');
      final response = await _supabase
          .from(_aiHistoryTable)
          .insert(data)
          .select();
      AppLogger.info('AI content history record created successfully');
      return AiContentHistoryModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create AI content history record', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AiContentHistoryModel> updateContentHistory(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating AI content history record: $id');
      final response = await _supabase
          .from(_aiHistoryTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('AI content history record updated successfully: $id');
      return AiContentHistoryModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update AI content history record: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<AiContentHistoryModel>> getContentHistory(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching AI content history with filters: $filters');
      var query = _supabase.from(_aiHistoryTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('prompt', '%${filters['searchQuery']}%');
      }
      if (filters['content_type'] != null) {
        query = query.eq('content_type', filters['content_type']);
      }
      if (filters['is_saved'] != null) {
        query = query.eq('is_saved', filters['is_saved']);
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} AI content history records');
      return response.map(AiContentHistoryModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch AI content history', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<CalendarEventModel> createEvent(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating calendar event');
      final response = await _supabase
          .from(_calendarEventsTable)
          .insert(data)
          .select();
      AppLogger.info('Calendar event created successfully');
      return CalendarEventModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create calendar event', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CalendarEventModel> updateEvent(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating calendar event: $id');
      final response = await _supabase
          .from(_calendarEventsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Calendar event updated successfully: $id');
      return CalendarEventModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update calendar event: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      AppLogger.info('Deleting calendar event: $id');
      await _supabase.from(_calendarEventsTable).delete().eq('id', id);
      AppLogger.info('Calendar event deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete calendar event: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<CalendarEventModel>> getEvents(Map<String, dynamic> filters) async {
    try {
      AppLogger.info('Fetching calendar events with filters: $filters');
      var query = _supabase.from(_calendarEventsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['event_type'] != null) {
        query = query.eq('event_type', filters['event_type']);
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }

      // Date range filter
      if (filters['startDate'] != null) {
        query = query.gte('start_time', filters['startDate']);
      }
      if (filters['endDate'] != null) {
        query = query.lte('end_time', filters['endDate']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('start_time', ascending: true).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} calendar events');
      return response.map(CalendarEventModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch calendar events', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<WorkspaceTemplateModel> createTemplate(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating workspace template');
      final response = await _supabase
          .from(_templatesTable)
          .insert(data)
          .select();
      AppLogger.info('Workspace template created successfully');
      return WorkspaceTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create workspace template', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<WorkspaceTemplateModel>> getTemplates(String templateType) async {
    try {
      AppLogger.info('Fetching workspace templates (type: $templateType)');
      final response = await _supabase
          .from(_templatesTable)
          .select()
          .eq('template_type', templateType)
          .order('usage_count', ascending: false);
      AppLogger.info('Fetched ${response.length} workspace templates');
      return response.map(WorkspaceTemplateModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch workspace templates', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<WorkspaceTemplateModel> incrementTemplateUsage(String id) async {
    try {
      AppLogger.info('Incrementing template usage count: $id');
      // Fetch current value first since Postgrest doesn't support atomic increment
      final current = await _supabase
          .from(_templatesTable)
          .select('usage_count')
          .eq('id', id)
          .single();
      final newCount = (current['usage_count'] as int) + 1;
      final response = await _supabase
          .from(_templatesTable)
          .update({'usage_count': newCount}).eq('id', id).select();
      AppLogger.info('Template usage count incremented: $id');
      return WorkspaceTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to increment template usage: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VERSION HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<WorkspaceVersionModel>> getVersionHistory(
    String resourceType,
    String resourceId,
  ) async {
    try {
      AppLogger.info(
        'Fetching version history (resourceType: $resourceType, resourceId: $resourceId)',
      );
      final response = await _supabase
          .from(_versionHistoryTable)
          .select()
          .eq('resource_type', resourceType)
          .eq('resource_id', resourceId)
          .order('created_at', ascending: false);
      AppLogger.info('Fetched ${response.length} version history records');
      return response.map(WorkspaceVersionModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch version history', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<String> exportResource(
    String resourceType,
    String resourceId,
    String format,
  ) async {
    try {
      AppLogger.info(
        'Exporting resource (type: $resourceType, id: $resourceId, format: $format)',
      );
      final response = await _supabase.rpc(
        'export_workspace_resource',
        params: {
          'p_resource_type': resourceType,
          'p_resource_id': resourceId,
          'p_format': format,
        },
      );
      AppLogger.info('Resource exported successfully');
      return response as String;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to export resource', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> generateQuestionsFromContent(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Generating questions from content');
      final response = await _supabase.rpc(
        'generate_questions_from_content',
        params: params,
      );
      AppLogger.info('Questions generated successfully');
      return response as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate questions from content', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRESENTATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<PresentationModel> createPresentation(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating presentation');
      final response = await _supabase
          .from(_presentationsTable)
          .insert(data)
          .select();
      AppLogger.info('Presentation created successfully');
      return PresentationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create presentation', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PresentationModel> updatePresentation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating presentation: $id');
      final response = await _supabase
          .from(_presentationsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Presentation updated successfully: $id');
      return PresentationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update presentation: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deletePresentation(String id) async {
    try {
      AppLogger.info('Deleting presentation: $id');
      await _supabase.from(_presentationsTable).delete().eq('id', id);
      AppLogger.info('Presentation deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete presentation: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PresentationModel> getPresentation(String id) async {
    try {
      AppLogger.info('Fetching presentation: $id');
      final response = await _supabase
          .from(_presentationsTable)
          .select()
          .eq('id', id)
          .single();
      AppLogger.info('Presentation fetched successfully: $id');
      return PresentationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch presentation: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<PresentationModel>> getPresentations(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching presentations with filters: $filters');
      var query = _supabase.from(_presentationsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }
      if (filters['is_archived'] != null) {
        query = query.eq('is_archived', filters['is_archived']);
      }
      if (filters['tags'] != null) {
        query = query.overlaps('tags', filters['tags']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} presentations');
      return response.map(PresentationModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch presentations', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PresentationModel> generatePresentationAI(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Generating presentation with AI');
      final response = await _supabase.rpc(
        'generate_presentation',
        params: params,
      );
      AppLogger.info('Presentation generated successfully');
      return PresentationModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate presentation with AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<String> exportPresentation(String id, String format) async {
    try {
      AppLogger.info('Exporting presentation: $id (format: $format)');
      final response = await _supabase.rpc(
        'export_presentation',
        params: {
          'p_presentation_id': id,
          'p_format': format,
        },
      );
      AppLogger.info('Presentation exported successfully: $id');
      return response as String;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to export presentation: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<PresentationVersionModel>> getPresentationVersions(
    String presentationId,
  ) async {
    try {
      AppLogger.info('Fetching presentation versions: $presentationId');
      final response = await _supabase
          .from(_presentationVersionsTable)
          .select()
          .eq('presentation_id', presentationId)
          .order('created_at', ascending: false);
      AppLogger.info('Fetched ${response.length} presentation versions');
      return response.map(PresentationVersionModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch presentation versions', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COMMUNICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<CommunicationModel> createCommunication(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating communication');
      final response = await _supabase
          .from(_communicationsTable)
          .insert(data)
          .select();
      AppLogger.info('Communication created successfully');
      return CommunicationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create communication', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CommunicationModel> updateCommunication(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating communication: $id');
      final response = await _supabase
          .from(_communicationsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Communication updated successfully: $id');
      return CommunicationModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update communication: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteCommunication(String id) async {
    try {
      AppLogger.info('Deleting communication: $id');
      await _supabase.from(_communicationsTable).delete().eq('id', id);
      AppLogger.info('Communication deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete communication: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<CommunicationModel>> getCommunications(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching communications with filters: $filters');
      var query = _supabase.from(_communicationsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['communication_type'] != null) {
        query = query.eq('communication_type', filters['communication_type']);
      }
      if (filters['status'] != null) {
        query = query.eq('status', filters['status']);
      }
      if (filters['is_ai_generated'] != null) {
        query = query.eq('is_ai_generated', filters['is_ai_generated']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} communications');
      return response.map(CommunicationModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch communications', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CommunicationModel> generateCommunicationAI(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Generating communication with AI');
      final response = await _supabase.rpc(
        'generate_communication',
        params: params,
      );
      AppLogger.info('Communication generated successfully');
      return CommunicationModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate communication with AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> sendCommunication(String id) async {
    try {
      AppLogger.info('Sending communication: $id');
      await _supabase
          .from(_communicationsTable)
          .update({'status': 'sent', 'sent_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      AppLogger.info('Communication sent successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to send communication: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TASKS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating task');
      final response = await _supabase
          .from(_tasksTable)
          .insert(data)
          .select();
      AppLogger.info('Task created successfully');
      return TaskModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create task', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TaskModel> updateTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating task: $id');
      final response = await _supabase
          .from(_tasksTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Task updated successfully: $id');
      return TaskModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update task: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      AppLogger.info('Deleting task: $id');
      await _supabase.from(_tasksTable).delete().eq('id', id);
      AppLogger.info('Task deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete task: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<TaskModel>> getTasks(Map<String, dynamic> filters) async {
    try {
      AppLogger.info('Fetching tasks with filters: $filters');
      var query = _supabase.from(_tasksTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['status'] != null) {
        query = query.eq('status', filters['status']);
      }
      if (filters['priority'] != null) {
        query = query.eq('priority', filters['priority']);
      }
      if (filters['due_date_from'] != null) {
        query = query.gte('due_date', filters['due_date_from']);
      }
      if (filters['due_date_to'] != null) {
        query = query.lte('due_date', filters['due_date_to']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} tasks');
      return response.map(TaskModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch tasks', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<TaskModel> completeTask(String id, String? completionNotes) async {
    try {
      AppLogger.info('Completing task: $id');
      final updateData = <String, dynamic>{
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      };
      if (completionNotes != null) {
        updateData['completion_notes'] = completionNotes;
      }
      final response = await _supabase
          .from(_tasksTable)
          .update(updateData)
          .eq('id', id)
          .select();
      AppLogger.info('Task completed successfully: $id');
      return TaskModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to complete task: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RUBRICS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<RubricModel> createRubric(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Creating rubric');
      final response = await _supabase
          .from(_rubricsTable)
          .insert(data)
          .select();
      AppLogger.info('Rubric created successfully');
      return RubricModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create rubric', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<RubricModel> updateRubric(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating rubric: $id');
      final response = await _supabase
          .from(_rubricsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Rubric updated successfully: $id');
      return RubricModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update rubric: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteRubric(String id) async {
    try {
      AppLogger.info('Deleting rubric: $id');
      await _supabase.from(_rubricsTable).delete().eq('id', id);
      AppLogger.info('Rubric deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete rubric: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<RubricModel>> getRubrics(Map<String, dynamic> filters) async {
    try {
      AppLogger.info('Fetching rubrics with filters: $filters');
      var query = _supabase.from(_rubricsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} rubrics');
      return response.map(RubricModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch rubrics', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<RubricModel> generateRubricAI(Map<String, dynamic> params) async {
    try {
      AppLogger.info('Generating rubric with AI');
      final response = await _supabase.rpc(
        'generate_rubric',
        params: params,
      );
      AppLogger.info('Rubric generated successfully');
      return RubricModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate rubric with AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ORAL QUESTIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<OralQuestionModel> createOralQuestions(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating oral questions');
      final response = await _supabase
          .from(_oralQuestionsTable)
          .insert(data)
          .select();
      AppLogger.info('Oral questions created successfully');
      return OralQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create oral questions', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<OralQuestionModel> updateOralQuestions(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating oral questions: $id');
      final response = await _supabase
          .from(_oralQuestionsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Oral questions updated successfully: $id');
      return OralQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update oral questions: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteOralQuestions(String id) async {
    try {
      AppLogger.info('Deleting oral questions: $id');
      await _supabase.from(_oralQuestionsTable).delete().eq('id', id);
      AppLogger.info('Oral questions deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete oral questions: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<OralQuestionModel>> getOralQuestions(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching oral questions with filters: $filters');
      var query = _supabase.from(_oralQuestionsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['difficulty'] != null) {
        query = query.eq('difficulty', filters['difficulty']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} oral questions');
      return response.map(OralQuestionModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch oral questions', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<OralQuestionModel> generateOralQuestionsAI(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Generating oral questions with AI');
      final response = await _supabase.rpc(
        'generate_oral_questions',
        params: params,
      );
      AppLogger.info('Oral questions generated successfully');
      return OralQuestionModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate oral questions with AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRACTICAL ASSESSMENTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<PracticalAssessmentModel> createPracticalAssessment(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Creating practical assessment');
      final response = await _supabase
          .from(_practicalAssessmentsTable)
          .insert(data)
          .select();
      AppLogger.info('Practical assessment created successfully');
      return PracticalAssessmentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to create practical assessment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PracticalAssessmentModel> updatePracticalAssessment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Updating practical assessment: $id');
      final response = await _supabase
          .from(_practicalAssessmentsTable)
          .update(data)
          .eq('id', id)
          .select();
      AppLogger.info('Practical assessment updated successfully: $id');
      return PracticalAssessmentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to update practical assessment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deletePracticalAssessment(String id) async {
    try {
      AppLogger.info('Deleting practical assessment: $id');
      await _supabase.from(_practicalAssessmentsTable).delete().eq('id', id);
      AppLogger.info('Practical assessment deleted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to delete practical assessment: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<PracticalAssessmentModel>> getPracticalAssessments(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching practical assessments with filters: $filters');
      var query = _supabase.from(_practicalAssessmentsTable).select();

      if (filters['searchQuery'] != null) {
        query = query.ilike('title', '%${filters['searchQuery']}%');
      }
      if (filters['subject_id'] != null) {
        query = query.eq('subject_id', filters['subject_id']);
      }
      if (filters['class_id'] != null) {
        query = query.eq('class_id', filters['class_id']);
      }
      if (filters['assessment_type'] != null) {
        query = query.eq('assessment_type', filters['assessment_type']);
      }
      if (filters['is_published'] != null) {
        query = query.eq('is_published', filters['is_published']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} practical assessments');
      return response.map(PracticalAssessmentModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch practical assessments', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<PracticalAssessmentModel> generatePracticalAssessmentAI(
    Map<String, dynamic> params,
  ) async {
    try {
      AppLogger.info('Generating practical assessment with AI');
      final response = await _supabase.rpc(
        'generate_practical_assessment',
        params: params,
      );
      AppLogger.info('Practical assessment generated successfully');
      return PracticalAssessmentModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to generate practical assessment with AI', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COLLABORATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<SharedResourceModel> shareResource(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Sharing resource');
      final response = await _supabase
          .from(_sharedResourcesTable)
          .insert(data)
          .select();
      AppLogger.info('Resource shared successfully');
      return SharedResourceModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to share resource', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<SharedResourceModel>> getSharedResources(
    Map<String, dynamic> filters,
  ) async {
    try {
      AppLogger.info('Fetching shared resources with filters: $filters');
      var query = _supabase.from(_sharedResourcesTable).select();

      if (filters['shared_with_id'] != null) {
        query = query.eq('shared_with_id', filters['shared_with_id']);
      }
      if (filters['shared_by_id'] != null) {
        query = query.eq('shared_by_id', filters['shared_by_id']);
      }
      if (filters['resource_type'] != null) {
        query = query.eq('resource_type', filters['resource_type']);
      }
      if (filters['status'] != null) {
        query = query.eq('status', filters['status']);
      }

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      final response = await query.order('created_at', ascending: false).range((page - 1) * perPage, page * perPage - 1);
      AppLogger.info('Fetched ${response.length} shared resources');
      return response.map(SharedResourceModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch shared resources', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> acceptSharedResource(String id) async {
    try {
      AppLogger.info('Accepting shared resource: $id');
      await _supabase
          .from(_sharedResourcesTable)
          .update({'status': 'accepted'})
          .eq('id', id);
      AppLogger.info('Shared resource accepted successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to accept shared resource: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> declineSharedResource(String id) async {
    try {
      AppLogger.info('Declining shared resource: $id');
      await _supabase
          .from(_sharedResourcesTable)
          .update({'status': 'declined'})
          .eq('id', id);
      AppLogger.info('Shared resource declined successfully: $id');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to decline shared resource: $id', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<CollaborationCommentModel> addComment(
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.info('Adding collaboration comment');
      final response = await _supabase
          .from(_commentsTable)
          .insert(data)
          .select();
      AppLogger.info('Collaboration comment added successfully');
      return CollaborationCommentModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to add collaboration comment', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<List<CollaborationCommentModel>> getComments(
    String resourceType,
    String resourceId,
  ) async {
    try {
      AppLogger.info(
        'Fetching comments (resourceType: $resourceType, resourceId: $resourceId)',
      );
      final response = await _supabase
          .from(_commentsTable)
          .select()
          .eq('resource_type', resourceType)
          .eq('resource_id', resourceId)
          .order('created_at', ascending: true);
      AppLogger.info('Fetched ${response.length} collaboration comments');
      return response.map(CollaborationCommentModel.fromJson).toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch collaboration comments', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> resolveComment(String commentId) async {
    try {
      AppLogger.info('Resolving collaboration comment: $commentId');
      await _supabase
          .from(_commentsTable)
          .update({'is_resolved': true})
          .eq('id', commentId);
      AppLogger.info('Collaboration comment resolved successfully: $commentId');
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to resolve collaboration comment: $commentId', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENHANCED DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<EnhancedDashboardModel> getEnhancedDashboard() async {
    try {
      AppLogger.info('Fetching enhanced workspace dashboard');
      final response = await _supabase.rpc(
        'get_enhanced_workspace_dashboard',
        params: {'p_teacher_id': _supabase.auth.currentUser?.id},
      );
      AppLogger.info('Enhanced workspace dashboard fetched successfully');
      return EnhancedDashboardModel.fromJson(response as Map<String, dynamic>);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Failed to fetch enhanced workspace dashboard', error: e);
      throw ServerException(message: e.toString(), statusCode: 500);
    }
  }
}
