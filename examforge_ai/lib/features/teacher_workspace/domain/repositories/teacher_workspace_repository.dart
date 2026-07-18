import '../../../../core/utils/result.dart';
import '../entities/teacher_workspace_entities.dart';

/// Abstract contract for all AI Teacher Workspace operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class TeacherWorkspaceRepository {
  // ─── Dashboard ────────────────────────────────────────────────────────

  /// Retrieves the aggregated dashboard summary for the current teacher.
  Future<Result<WorkspaceDashboardEntity>> getDashboardSummary();

  // ─── Lesson Plans (CRUD + AI) ────────────────────────────────────────

  /// Creates a new lesson plan and returns the persisted entity.
  Future<Result<LessonPlanEntity>> createLessonPlan(LessonPlanEntity plan);

  /// Updates an existing lesson plan and returns the updated entity.
  Future<Result<LessonPlanEntity>> updateLessonPlan(LessonPlanEntity plan);

  /// Permanently deletes a lesson plan by [planId].
  Future<Result<void>> deleteLessonPlan(String planId);

  /// Retrieves a single lesson plan by [planId].
  Future<Result<LessonPlanEntity>> getLessonPlan(String planId);

  /// Retrieves a filtered list of lesson plans based on [filter].
  Future<Result<List<LessonPlanEntity>>> getLessonPlans(
    WorkspaceFilterEntity filter,
  );

  /// Generates a lesson plan using AI based on the provided [params].
  Future<Result<LessonPlanEntity>> generateLessonPlan(
    Map<String, dynamic> params,
  );

  /// Publishes a lesson plan, making it visible to students.
  Future<Result<void>> publishLessonPlan(String planId);

  /// Archives a lesson plan, hiding it from active lists.
  Future<Result<void>> archiveLessonPlan(String planId);

  /// Creates a deep copy of a lesson plan with a new ID, returning
  /// the duplicated entity.
  Future<Result<LessonPlanEntity>> duplicateLessonPlan(String planId);

  // ─── Schemes of Work (CRUD + AI) ─────────────────────────────────────

  /// Creates a new scheme of work and returns the persisted entity.
  Future<Result<SchemeOfWorkEntity>> createSchemeOfWork(
    SchemeOfWorkEntity scheme,
  );

  /// Updates an existing scheme of work and returns the updated entity.
  Future<Result<SchemeOfWorkEntity>> updateSchemeOfWork(
    SchemeOfWorkEntity scheme,
  );

  /// Permanently deletes a scheme of work by [schemeId].
  Future<Result<void>> deleteSchemeOfWork(String schemeId);

  /// Retrieves a single scheme of work by [schemeId].
  Future<Result<SchemeOfWorkEntity>> getSchemeOfWork(String schemeId);

  /// Retrieves a filtered list of schemes of work based on [filter].
  Future<Result<List<SchemeOfWorkEntity>>> getSchemesOfWork(
    WorkspaceFilterEntity filter,
  );

  /// Generates a scheme of work using AI based on the provided [params].
  Future<Result<SchemeOfWorkEntity>> generateSchemeOfWork(
    Map<String, dynamic> params,
  );

  // ─── Worksheets (CRUD + AI + Export) ─────────────────────────────────

  /// Creates a new worksheet and returns the persisted entity.
  Future<Result<WorksheetEntity>> createWorksheet(WorksheetEntity worksheet);

  /// Updates an existing worksheet and returns the updated entity.
  Future<Result<WorksheetEntity>> updateWorksheet(WorksheetEntity worksheet);

  /// Permanently deletes a worksheet by [worksheetId].
  Future<Result<void>> deleteWorksheet(String worksheetId);

  /// Retrieves a single worksheet by [worksheetId].
  Future<Result<WorksheetEntity>> getWorksheet(String worksheetId);

  /// Retrieves a filtered list of worksheets based on [filter].
  Future<Result<List<WorksheetEntity>>> getWorksheets(
    WorkspaceFilterEntity filter,
  );

  /// Generates a worksheet using AI based on the provided [params].
  Future<Result<WorksheetEntity>> generateWorksheet(
    Map<String, dynamic> params,
  );

  /// Exports a worksheet to the specified [format] (e.g., PDF, DOCX)
  /// and returns the download URL or file path.
  Future<Result<String>> exportWorksheet(String worksheetId, String format);

  // ─── Assignments (CRUD + AI) ─────────────────────────────────────────

  /// Creates a new assignment and returns the persisted entity.
  Future<Result<WorkspaceAssignmentEntity>> createAssignment(
    WorkspaceAssignmentEntity assignment,
  );

  /// Updates an existing assignment and returns the updated entity.
  Future<Result<WorkspaceAssignmentEntity>> updateAssignment(
    WorkspaceAssignmentEntity assignment,
  );

  /// Permanently deletes an assignment by [assignmentId].
  Future<Result<void>> deleteAssignment(String assignmentId);

  /// Retrieves a single assignment by [assignmentId].
  Future<Result<WorkspaceAssignmentEntity>> getAssignment(String assignmentId);

  /// Retrieves a filtered list of assignments based on [filter].
  Future<Result<List<WorkspaceAssignmentEntity>>> getAssignments(
    WorkspaceFilterEntity filter,
  );

  /// Generates an assignment using AI based on the provided [params].
  Future<Result<WorkspaceAssignmentEntity>> generateAssignment(
    Map<String, dynamic> params,
  );

  /// Publishes an assignment, making it visible to students.
  Future<Result<void>> publishAssignment(String assignmentId);

  // ─── Report Comments (CRUD + AI) ─────────────────────────────────────

  /// Creates a new report comment and returns the persisted entity.
  Future<Result<ReportCommentEntity>> createReportComment(
    ReportCommentEntity comment,
  );

  /// Updates an existing report comment and returns the updated entity.
  Future<Result<ReportCommentEntity>> updateReportComment(
    ReportCommentEntity comment,
  );

  /// Permanently deletes a report comment by [commentId].
  Future<Result<void>> deleteReportComment(String commentId);

  /// Retrieves a filtered list of report comments based on [filter].
  Future<Result<List<ReportCommentEntity>>> getReportComments(
    WorkspaceFilterEntity filter,
  );

  /// Generates report comments using AI based on the provided [params].
  Future<Result<List<ReportCommentEntity>>> generateReportComments(
    Map<String, dynamic> params,
  );

  /// Publishes a report comment.
  Future<Result<void>> publishReportComment(String commentId);

  // ─── Teaching Resources (CRUD + AI) ──────────────────────────────────

  /// Creates a new teaching resource and returns the persisted entity.
  Future<Result<TeachingResourceEntity>> createResource(
    TeachingResourceEntity resource,
  );

  /// Updates an existing teaching resource and returns the updated entity.
  Future<Result<TeachingResourceEntity>> updateResource(
    TeachingResourceEntity resource,
  );

  /// Permanently deletes a teaching resource by [resourceId].
  Future<Result<void>> deleteResource(String resourceId);

  /// Retrieves a single teaching resource by [resourceId].
  Future<Result<TeachingResourceEntity>> getResource(String resourceId);

  /// Retrieves a filtered list of teaching resources based on [filter].
  Future<Result<List<TeachingResourceEntity>>> getResources(
    WorkspaceFilterEntity filter,
  );

  /// Generates a teaching resource using AI based on the provided [params].
  Future<Result<TeachingResourceEntity>> generateResource(
    Map<String, dynamic> params,
  );

  /// Toggles the favorite status of a teaching resource for the
  /// current user.
  Future<Result<void>> toggleFavorite(String resourceId);

  // ─── Resource Folders ────────────────────────────────────────────────

  /// Creates a new resource folder and returns the persisted entity.
  Future<Result<ResourceFolderEntity>> createFolder(ResourceFolderEntity folder);

  /// Updates an existing resource folder and returns the updated entity.
  Future<Result<ResourceFolderEntity>> updateFolder(ResourceFolderEntity folder);

  /// Permanently deletes a resource folder by [folderId].
  Future<Result<void>> deleteFolder(String folderId);

  /// Retrieves resource folders, optionally scoped to a
  /// [parentFolderId] for hierarchical navigation.
  Future<Result<List<ResourceFolderEntity>>> getFolders(String? parentFolderId);

  // ─── AI Content Assistant ────────────────────────────────────────────

  /// Generates content using the AI assistant based on the specified
  /// [action], [sourceContent], and optional [params].
  Future<Result<AiContentHistoryEntity>> generateContent(
    ContentAction action,
    String sourceContent,
    Map<String, dynamic>? params,
  );

  /// Retrieves AI content generation history based on [filter].
  Future<Result<List<AiContentHistoryEntity>>> getContentHistory(
    WorkspaceFilterEntity filter,
  );

  /// Saves an AI-generated content entry as a specific [targetType]
  /// (e.g., lesson plan, worksheet, assignment).
  Future<Result<AiContentHistoryEntity>> saveContentAs(
    AiContentHistoryEntity history,
    String targetType,
  );

  // ─── Calendar & Planner ──────────────────────────────────────────────

  /// Creates a new calendar event and returns the persisted entity.
  Future<Result<CalendarEventEntity>> createEvent(CalendarEventEntity event);

  /// Updates an existing calendar event and returns the updated entity.
  Future<Result<CalendarEventEntity>> updateEvent(CalendarEventEntity event);

  /// Permanently deletes a calendar event by [eventId].
  Future<Result<void>> deleteEvent(String eventId);

  /// Retrieves calendar events within an optional date range.
  Future<Result<List<CalendarEventEntity>>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Suggests a schedule using AI based on the provided [params].
  Future<Result<List<CalendarEventEntity>>> suggestSchedule(
    Map<String, dynamic> params,
  );

  // ─── Templates ───────────────────────────────────────────────────────

  /// Creates a new workspace template and returns the persisted entity.
  Future<Result<WorkspaceTemplateEntity>> createTemplate(
    WorkspaceTemplateEntity template,
  );

  /// Retrieves workspace templates filtered by [templateType].
  Future<Result<List<WorkspaceTemplateEntity>>> getTemplates(
    String templateType,
  );

  /// Instantiates a workspace resource from a template by [templateId],
  /// returning the newly created entity.
  Future<Result<WorkspaceTemplateEntity>> useTemplate(String templateId);

  // ─── Version History ─────────────────────────────────────────────────

  /// Retrieves the full version history for a resource identified by
  /// [resourceType] and [resourceId].
  Future<Result<List<WorkspaceVersionEntity>>> getVersionHistory(
    String resourceType,
    String resourceId,
  );

  /// Restores a lesson plan to a specific [versionNumber], creating a
  /// new version entry.
  Future<Result<LessonPlanEntity>> restoreLessonPlanVersion(
    String planId,
    int versionNumber,
  );

  // ─── Export (general) ────────────────────────────────────────────────

  /// Exports any workspace resource to the specified [format]
  /// (e.g., PDF, DOCX, XLSX) and returns the download URL or file path.
  Future<Result<String>> exportResource(
    String resourceType,
    String resourceId,
    String format,
  );

  // ─── Generate Questions Integration ──────────────────────────────────

  /// Sends workspace content to the AI Question Generator module,
  /// returning generated question data based on the specified
  /// [resourceType], [resourceId], and [params].
  Future<Result<Map<String, dynamic>>> generateQuestionsFromContent(
    String resourceType,
    String resourceId,
    Map<String, dynamic> params,
  );
}
