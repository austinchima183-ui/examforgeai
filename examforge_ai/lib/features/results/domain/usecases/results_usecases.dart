import '../../../../core/utils/result.dart';
import '../entities/results_entities.dart';
import '../repositories/results_repository.dart';
import '../../../../features/results/domain/entities/results_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// RESULTS ENGINE — USE CASES
// ═══════════════════════════════════════════════════════════════════════
// Each use case encapsulates a single business operation following the
// Single Responsibility Principle. All return Result<T> for compile-time
// error handling enforcement.
// ═══════════════════════════════════════════════════════════════════════

// ─── GRADE SCALE USE CASES ────────────────────────────────────────────

/// Creates a new grade scale for a school.
class CreateGradeScaleUseCase {
  CreateGradeScaleUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<GradeScaleEntity>> call(GradeScaleEntity scale) =>
      _repository.createGradeScale(scale);
}

/// Updates an existing grade scale.
class UpdateGradeScaleUseCase {
  UpdateGradeScaleUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<GradeScaleEntity>> call(GradeScaleEntity scale) =>
      _repository.updateGradeScale(scale);
}

/// Retrieves grade scales for a school.
class GetGradeScalesUseCase {
  GetGradeScalesUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<GradeScaleEntity>>> call(
    String schoolId, {
    bool? isActive,
    GradeType? gradeType,
  }) =>
      _repository.getGradeScales(schoolId, isActive: isActive, gradeType: gradeType);
}

/// Applies a grade scale to a percentage.
class ApplyGradeScaleUseCase {
  ApplyGradeScaleUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<GradeScaleEntryEntity?>> call(double percentage, String scaleId) =>
      _repository.applyGradeScale(percentage, scaleId);
}

// ─── AI GRADING USE CASES ─────────────────────────────────────────────

/// Requests AI grading for a subjective answer.
class RequestAiGradingUseCase {
  RequestAiGradingUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<AiGradingResultEntity>> call({
    required String answerId,
    required String examId,
    required String studentId,
    required String questionContent,
    required String studentAnswer,
    required String markingScheme,
    required double maxPossible,
    String? aiProvider,
  }) =>
      _repository.requestAiGrading(
        answerId: answerId,
        examId: examId,
        studentId: studentId,
        questionContent: questionContent,
        studentAnswer: studentAnswer,
        markingScheme: markingScheme,
        maxPossible: maxPossible,
        aiProvider: aiProvider,
      );
}

/// Reviews an AI grading result (teacher accepts, overrides, or rejects).
class ReviewAiGradingUseCase {
  ReviewAiGradingUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<AiGradingResultEntity>> call({
    required String aiGradingId,
    required double finalScore,
    required bool isAccepted,
    String? reviewComment,
  }) =>
      _repository.reviewAiGrading(
        aiGradingId: aiGradingId,
        finalScore: finalScore,
        isAccepted: isAccepted,
        reviewComment: reviewComment,
      );
}

/// Batch-requests AI grading for all subjective answers in an exam.
class BatchAiGradingUseCase {
  BatchAiGradingUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<AiGradingResultEntity>>> call(String examId) =>
      _repository.batchAiGrading(examId);
}

/// Gets pending AI grading results for an exam.
class GetPendingAiGradingsUseCase {
  GetPendingAiGradingsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<AiGradingResultEntity>>> call(String examId) =>
      _repository.getPendingAiGradings(examId);
}

// ─── TEACHER FEEDBACK USE CASES ───────────────────────────────────────

/// Saves teacher feedback (grading + comments) for a student answer.
class SaveTeacherFeedbackUseCase {
  SaveTeacherFeedbackUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<TeacherFeedbackEntity>> call(TeacherFeedbackEntity feedback) =>
      _repository.saveTeacherFeedback(feedback);
}

/// Gets teacher feedback for an exam.
class GetTeacherFeedbackUseCase {
  GetTeacherFeedbackUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<TeacherFeedbackEntity>>> call({
    required String examId,
    required String teacherId,
  }) =>
      _repository.getTeacherFeedbackByExam(examId, teacherId);
}

// ─── STUDENT RESULTS USE CASES ────────────────────────────────────────

/// Gets a student's subject-by-subject results for a session.
class GetStudentSubjectResultsUseCase {
  GetStudentSubjectResultsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<StudentSubjectResultEntity>>> call({
    required String studentId,
    required String academicSessionId,
  }) =>
      _repository.getStudentSubjectResults(
        studentId: studentId,
        academicSessionId: academicSessionId,
      );
}

/// Gets a student's overall result for a session.
class GetStudentOverallResultUseCase {
  GetStudentOverallResultUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<StudentOverallResultEntity>> call({
    required String studentId,
    required String classId,
    required String academicSessionId,
  }) =>
      _repository.getStudentOverallResult(
        studentId: studentId,
        classId: classId,
        academicSessionId: academicSessionId,
      );
}

/// Gets class-wide overall results for ranking and comparison.
class GetClassOverallResultsUseCase {
  GetClassOverallResultsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<StudentOverallResultEntity>>> call({
    required String classId,
    required String academicSessionId,
  }) =>
      _repository.getClassOverallResults(
        classId: classId,
        academicSessionId: academicSessionId,
      );
}

/// Updates teacher comment on student's overall result.
class UpdateTeacherCommentUseCase {
  UpdateTeacherCommentUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<StudentOverallResultEntity>> call({
    required String resultId,
    required String comment,
  }) =>
      _repository.updateTeacherComment(resultId: resultId, comment: comment);
}

// ─── TOPIC MASTERY USE CASES ──────────────────────────────────────────

/// Gets a student's topic mastery for a subject.
class GetStudentTopicMasteryUseCase {
  GetStudentTopicMasteryUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<TopicMasteryEntity>>> call({
    required String studentId,
    required String subjectId,
  }) =>
      _repository.getStudentTopicMastery(studentId: studentId, subjectId: subjectId);
}

/// Gets class-wide topic mastery.
class GetClassTopicMasteryUseCase {
  GetClassTopicMasteryUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<TopicMasteryEntity>>> call({
    required String classId,
    required String subjectId,
  }) =>
      _repository.getClassTopicMastery(classId: classId, subjectId: subjectId);
}

// ─── ANALYTICS USE CASES ──────────────────────────────────────────────

/// Gets class performance summary.
class GetClassPerformanceUseCase {
  GetClassPerformanceUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<ClassPerformanceEntity>> call({
    required String classId,
    String? subjectId,
    required String academicSessionId,
  }) =>
      _repository.getClassPerformance(
        classId: classId,
        subjectId: subjectId,
        academicSessionId: academicSessionId,
      );
}

/// Gets school performance summary.
class GetSchoolPerformanceUseCase {
  GetSchoolPerformanceUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<SchoolPerformanceEntity>> call({
    required String schoolId,
    required String academicSessionId,
  }) =>
      _repository.getSchoolPerformance(
        schoolId: schoolId,
        academicSessionId: academicSessionId,
      );
}

/// Gets an analytics snapshot.
class GetAnalyticsSnapshotUseCase {
  GetAnalyticsSnapshotUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<AnalyticsSnapshotEntity?>> call({
    required String schoolId,
    required String snapshotType,
    String? entityId,
    String? academicSessionId,
  }) =>
      _repository.getAnalyticsSnapshot(
        schoolId: schoolId,
        snapshotType: snapshotType,
        entityId: entityId,
        academicSessionId: academicSessionId,
      );
}

// ─── DASHBOARD CONFIGURATION USE CASES ────────────────────────────────

/// Gets the dashboard configuration for a school/role.
class GetDashboardConfigurationUseCase {
  GetDashboardConfigurationUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<DashboardConfigurationEntity>> call({
    required String schoolId,
    required String role,
  }) =>
      _repository.getDashboardConfiguration(schoolId: schoolId, role: role);
}

/// Saves a dashboard configuration (creates or updates).
class SaveDashboardConfigurationUseCase {
  SaveDashboardConfigurationUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<DashboardConfigurationEntity>> call(
    DashboardConfigurationEntity config,
  ) =>
      _repository.saveDashboardConfiguration(config);
}

// ─── REPORT EXPORT USE CASES ──────────────────────────────────────────

/// Creates a new report export request.
class CreateReportExportUseCase {
  CreateReportExportUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<ReportExportEntity>> call({
    required String schoolId,
    required String requestedBy,
    required ReportType reportType,
    required ReportFormat reportFormat,
    required String title,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? filters,
  }) =>
      _repository.createReportExport(
        schoolId: schoolId,
        requestedBy: requestedBy,
        reportType: reportType,
        reportFormat: reportFormat,
        title: title,
        parameters: parameters,
        filters: filters,
      );
}

/// Gets report exports for a school/user.
class GetReportExportsUseCase {
  GetReportExportsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<List<ReportExportEntity>>> call({
    String? schoolId,
    String? requestedBy,
    ReportStatus? status,
    int page = 1,
    int perPage = 20,
  }) =>
      _repository.getReportExports(
        schoolId: schoolId,
        requestedBy: requestedBy,
        status: status,
        page: page,
        perPage: perPage,
      );
}

/// Downloads a report export.
class DownloadReportUseCase {
  DownloadReportUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<String>> call(String exportId) =>
      _repository.downloadReport(exportId);
}

// ─── RESULT MANAGEMENT USE CASES ──────────────────────────────────────

/// Locks results for an exam (prevents modifications after publication).
class LockResultsUseCase {
  LockResultsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<ResultLockEntity>> call({
    required String examId,
    required String schoolId,
    required String lockedBy,
    String? reason,
  }) =>
      _repository.lockResults(
        examId: examId,
        schoolId: schoolId,
        lockedBy: lockedBy,
        reason: reason,
      );
}

/// Publishes results for an exam.
class PublishResultsUseCase {
  PublishResultsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<void>> call(String examId) =>
      _repository.publishResults(examId);
}

/// Recomputes all results for a class/session.
class RecomputeResultsUseCase {
  RecomputeResultsUseCase(this._repository);
  final ResultsRepository _repository;

  Future<Result<void>> call({
    required String classId,
    required String academicSessionId,
  }) =>
      _repository.recomputeClassResults(
        classId: classId,
        academicSessionId: academicSessionId,
      );
}
