import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/teacher_workspace_models.dart';

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

  // ── Exception mapping helper ───────────────────────────────────────────
  Never _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Postgrest error: ${e.message}', error: e);
    switch (e.code) {
      case 'PGRST116':
        throw NotFoundException(message: e.message);
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
        throw ForbiddenException(
          message: 'You do not have permission for this action.',
        );
      default:
        throw ServerException(
          message: e.message,
          statusCode: e.statusCode ?? 500,
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

      // Ordering
      query = query.order('created_at', ascending: false);

      // Pagination
      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('name', ascending: true);

      final response = await query;
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

      query = query.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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

      query = query.order('start_time', ascending: true);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['perPage'] as int? ?? 20;
      query = query.range((page - 1) * perPage, page * perPage - 1);

      final response = await query;
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
}
