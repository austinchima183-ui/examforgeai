import '../../../../core/utils/result.dart';
import 'entities/results_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESULTS REPOSITORY CONTRACT
// ═══════════════════════════════════════════════════════════════════════
// Abstract contract defining all operations for the Results, Grading &
// Analytics Engine. Every method returns a [Result] to enforce explicit
// error handling at compile time across layer boundaries.
// ═══════════════════════════════════════════════════════════════════════

abstract class ResultsRepository {
  // ─── Grade Scales ────────────────────────────────────────────────────

  /// Creates a new grade scale for a school.
  Future<Result<GradeScaleEntity>> createGradeScale(GradeScaleEntity scale);

  /// Updates an existing grade scale.
  Future<Result<GradeScaleEntity>> updateGradeScale(GradeScaleEntity scale);

  /// Deletes a grade scale by [scaleId].
  Future<Result<void>> deleteGradeScale(String scaleId);

  /// Retrieves a grade scale by [scaleId] with its entries.
  Future<Result<GradeScaleEntity>> getGradeScale(String scaleId);

  /// Retrieves all grade scales for a school.
  Future<Result<List<GradeScaleEntity>>> getGradeScales(
    String schoolId, {
    bool? isActive,
    GradeType? gradeType,
  });

  /// Applies a grade scale to a percentage and returns the matching entry.
  Future<Result<GradeScaleEntryEntity?>> applyGradeScale(
    double percentage,
    String scaleId,
  );

  // ─── AI Grading ──────────────────────────────────────────────────────

  /// Requests AI grading for a subjective answer.
  Future<Result<AiGradingResultEntity>> requestAiGrading({
    required String answerId,
    required String examId,
    required String studentId,
    required String questionContent,
    required String studentAnswer,
    required String markingScheme,
    required double maxPossible,
    String? aiProvider,
  });

  /// Retrieves AI grading result for a specific answer.
  Future<Result<AiGradingResultEntity?>> getAiGradingResult(String answerId);

  /// Retrieves all pending AI grading results for an exam.
  Future<Result<List<AiGradingResultEntity>>> getPendingAiGradings(String examId);

  /// Reviews an AI grading result (accept, override, or reject).
  Future<Result<AiGradingResultEntity>> reviewAiGrading({
    required String aiGradingId,
    required double finalScore,
    required bool isAccepted,
    String? reviewComment,
  });

  /// Batch-requests AI grading for all subjective answers in an exam.
  Future<Result<List<AiGradingResultEntity>>> batchAiGrading(String examId);

  // ─── Teacher Feedback ────────────────────────────────────────────────

  /// Creates or updates teacher feedback for an answer.
  Future<Result<TeacherFeedbackEntity>> saveTeacherFeedback(
    TeacherFeedbackEntity feedback,
  );

  /// Retrieves teacher feedback for a specific answer.
  Future<Result<TeacherFeedbackEntity?>> getTeacherFeedback(String answerId);

  /// Retrieves all feedback given by a teacher for an exam.
  Future<Result<List<TeacherFeedbackEntity>>> getTeacherFeedbackByExam(
    String examId,
    String teacherId,
  );

  // ─── Student Subject Results ─────────────────────────────────────────

  /// Computes and retrieves a student's subject result.
  Future<Result<StudentSubjectResultEntity>> getStudentSubjectResult({
    required String studentId,
    required String subjectId,
    required String classId,
    required String academicSessionId,
  });

  /// Retrieves all subject results for a student in a session.
  Future<Result<List<StudentSubjectResultEntity>>> getStudentSubjectResults({
    required String studentId,
    required String academicSessionId,
  });

  /// Retrieves class-wide subject results (for teacher/admin dashboards).
  Future<Result<List<StudentSubjectResultEntity>>> getClassSubjectResults({
    required String classId,
    required String subjectId,
    required String academicSessionId,
  });

  // ─── Student Overall Results ─────────────────────────────────────────

  /// Computes and retrieves a student's overall result for a session.
  Future<Result<StudentOverallResultEntity>> getStudentOverallResult({
    required String studentId,
    required String classId,
    required String academicSessionId,
  });

  /// Retrieves class-wide overall results (for ranking and comparison).
  Future<Result<List<StudentOverallResultEntity>>> getClassOverallResults({
    required String classId,
    required String academicSessionId,
  });

  /// Updates the teacher comment on a student's overall result.
  Future<Result<StudentOverallResultEntity>> updateTeacherComment({
    required String resultId,
    required String comment,
  });

  // ─── Topic Mastery ───────────────────────────────────────────────────

  /// Retrieves a student's mastery for a specific topic.
  Future<Result<TopicMasteryEntity>> getTopicMastery({
    required String studentId,
    required String topicId,
  });

  /// Retrieves all topic mastery records for a student in a subject.
  Future<Result<List<TopicMasteryEntity>>> getStudentTopicMastery({
    required String studentId,
    required String subjectId,
  });

  /// Retrieves class-wide topic mastery (aggregated).
  Future<Result<List<TopicMasteryEntity>>> getClassTopicMastery({
    required String classId,
    required String subjectId,
  });

  // ─── Class Performance ───────────────────────────────────────────────

  /// Retrieves class performance summary.
  Future<Result<ClassPerformanceEntity>> getClassPerformance({
    required String classId,
    String? subjectId,
    required String academicSessionId,
  });

  /// Retrieves all class performance summaries for a school.
  Future<Result<List<ClassPerformanceEntity>>> getSchoolClassPerformances({
    required String schoolId,
    required String academicSessionId,
  });

  // ─── School Performance ──────────────────────────────────────────────

  /// Retrieves school performance summary.
  Future<Result<SchoolPerformanceEntity>> getSchoolPerformance({
    required String schoolId,
    required String academicSessionId,
  });

  // ─── Analytics Snapshots ─────────────────────────────────────────────

  /// Retrieves the latest analytics snapshot for a given type.
  Future<Result<AnalyticsSnapshotEntity?>> getAnalyticsSnapshot({
    required String schoolId,
    required String snapshotType,
    String? entityId,
    String? academicSessionId,
  });

  /// Creates a new analytics snapshot.
  Future<Result<AnalyticsSnapshotEntity>> createAnalyticsSnapshot(
    AnalyticsSnapshotEntity snapshot,
  );

  // ─── Dashboard Configurations ────────────────────────────────────────

  /// Retrieves the dashboard configuration for a school/role.
  Future<Result<DashboardConfigurationEntity>> getDashboardConfiguration({
    required String schoolId,
    required String role,
  });

  /// Creates or updates a dashboard configuration.
  Future<Result<DashboardConfigurationEntity>> saveDashboardConfiguration(
    DashboardConfigurationEntity config,
  );

  /// Updates widget visibility/order in a dashboard.
  Future<Result<void>> updateDashboardWidgets({
    required String dashboardId,
    required List<DashboardWidgetConfigEntity> widgets,
  });

  // ─── Report Exports ──────────────────────────────────────────────────

  /// Creates a new report export request.
  Future<Result<ReportExportEntity>> createReportExport({
    required String schoolId,
    required String requestedBy,
    required ReportType reportType,
    required ReportFormat reportFormat,
    required String title,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? filters,
  });

  /// Retrieves a report export by [exportId].
  Future<Result<ReportExportEntity>> getReportExport(String exportId);

  /// Retrieves all report exports for a school/user.
  Future<Result<List<ReportExportEntity>>> getReportExports({
    String? schoolId,
    String? requestedBy,
    ReportStatus? status,
    int page = 1,
    int perPage = 20,
  });

  /// Downloads a report export, returning the file URL.
  Future<Result<String>> downloadReport(String exportId);

  // ─── Result Locks ───────────────────────────────────────────────────

  /// Locks results for an exam (prevents further grading changes).
  Future<Result<ResultLockEntity>> lockResults({
    required String examId,
    required String schoolId,
    required String lockedBy,
    String? reason,
  });

  /// Unlocks results for an exam.
  Future<Result<ResultLockEntity>> unlockResults({
    required String examId,
    required String unlockedBy,
  });

  /// Checks if results are locked for an exam.
  Future<Result<bool>> isResultLocked(String examId);

  // ─── Result Access Logging ───────────────────────────────────────────

  /// Logs a result access event for auditing.
  Future<Result<void>> logResultAccess({
    required String userId,
    required String schoolId,
    required String action,
    required String entityType,
    required String entityId,
    ResultAccessLevel accessLevel = ResultAccessLevel.limited,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? details,
  });

  // ─── Bulk Operations ────────────────────────────────────────────────

  /// Recomputes all subject and overall results for a class/session.
  Future<Result<void>> recomputeClassResults({
    required String classId,
    required String academicSessionId,
  });

  /// Publishes results for an exam, making them visible to students.
  Future<Result<void>> publishResults(String examId);

  /// Withholds results for an exam, hiding them from students.
  Future<Result<void>> withholdResults(String examId);
}
