import '../../../../core/utils/result.dart';
import '../entities/cbt_entities.dart';


/// Abstract contract for all CBT engine operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
///
/// The three `watch*` streams leverage Supabase Realtime for live
/// monitoring dashboards.
abstract class CbtRepository {
  // ─── Exam CRUD ──────────────────────────────────────────────────────

  /// Creates a new exam and returns the persisted entity.
  Future<Result<ExamEntity>> createExam(ExamEntity exam);

  /// Updates an existing exam and returns the updated entity.
  Future<Result<ExamEntity>> updateExam(ExamEntity exam);

  /// Permanently deletes an exam by [examId].
  Future<Result<void>> deleteExam(String examId);

  /// Retrieves an exam by [examId] without related details.
  Future<Result<ExamEntity>> getExam(String examId);

  /// Retrieves an exam by [examId] with all related details
  /// (sections, questions with full question entities, and student list).
  Future<Result<ExamEntity>> getExamWithDetails(String examId);

  /// Retrieves a filtered, paginated list of exams.
  Future<Result<List<ExamEntity>>> getExams({
    String? schoolId,
    String? subjectId,
    ExamStatus? status,
    int page = 1,
    int perPage = 20,
  });

  // ─── Exam Lifecycle ─────────────────────────────────────────────────

  /// Publishes a draft exam, making it visible to assigned students.
  Future<Result<ExamEntity>> publishExam(String examId);

  /// Archives a completed or published exam.
  Future<Result<ExamEntity>> archiveExam(String examId);

  /// Creates a deep copy of an exam with a new ID and reset status.
  Future<Result<ExamEntity>> cloneExam(String examId);

  // ─── Exam Questions ─────────────────────────────────────────────────

  /// Adds one or more questions to an exam.
  Future<Result<void>> addQuestionsToExam(
    String examId,
    List<ExamQuestionEntity> questions,
  );

  /// Removes a single question from an exam.
  Future<Result<void>> removeQuestionFromExam(
    String examId,
    String questionId,
  );

  /// Reorders questions within an exam according to the given [questionIds]
  /// list order.
  Future<Result<void>> reorderQuestions(
    String examId,
    List<String> questionIds,
  );

  // ─── Exam Students ──────────────────────────────────────────────────

  /// Assigns one or more students to an exam.
  Future<Result<void>> assignStudents(
    String examId,
    List<String> studentIds,
  );

  /// Removes a single student from an exam.
  Future<Result<void>> removeStudent(String examId, String studentId);

  // ─── Exam Attempts ──────────────────────────────────────────────────

  /// Starts a new exam attempt for the current student.
  ///
  /// Validates exam status, student assignment, and attempt limits
  /// before creating the attempt record and session.
  Future<Result<ExamAttemptEntity>> startAttempt(String examId);

  /// Submits an exam attempt, computing auto-graded results.
  Future<Result<ExamResultEntity>> submitAttempt(
    String attemptId, {
    SubmissionType type = SubmissionType.manual,
  });

  /// Retrieves an attempt by [attemptId] without answers.
  Future<Result<ExamAttemptEntity>> getAttempt(String attemptId);

  /// Retrieves an attempt by [attemptId] with all submitted answers.
  Future<Result<ExamAttemptEntity>> getAttemptWithAnswers(String attemptId);

  /// Retrieves all attempts for a student on a specific exam.
  Future<Result<List<ExamAttemptEntity>>> getStudentAttempts(
    String examId,
    String studentId,
  );

  // ─── Answer Handling ────────────────────────────────────────────────

  /// Saves or updates a student's answer for a specific question within
  /// an attempt.
  Future<Result<StudentAnswerEntity>> saveAnswer(
    String attemptId,
    String questionId,
    Map<String, dynamic> answerData,
  );

  /// Toggles the flag status of a question within an attempt.
  Future<Result<void>> flagQuestion(
    String attemptId,
    String questionId,
    bool isFlagged,
  );

  /// Persists auto-save data for an attempt (used for crash recovery).
  Future<Result<void>> autoSave(
    String attemptId,
    Map<String, dynamic> saveData,
  );

  // ─── Session Management ─────────────────────────────────────────────

  /// Updates an exam session (used for real-time state sync).
  Future<Result<void>> updateSession(ExamSessionEntity session);

  /// Records a heartbeat for an active session to prevent timeout.
  Future<Result<void>> heartbeat(String sessionId);

  // ─── Monitoring ─────────────────────────────────────────────────────

  /// Logs a monitoring event during an exam attempt.
  Future<Result<void>> logMonitoringEvent(MonitoringLogEntity event);

  /// Retrieves monitoring logs for an exam, optionally filtered by
  /// [studentId].
  Future<Result<List<MonitoringLogEntity>>> getMonitoringLogs(
    String examId, {
    String? studentId,
  });

  // ─── Results & Grading ──────────────────────────────────────────────

  /// Retrieves exam results, optionally filtered by release status.
  Future<Result<List<ExamResultEntity>>> getExamResults(
    String examId, {
    bool? isReleased,
  });

  /// Retrieves the result for a specific student on an exam.
  ///
  /// Returns `null` if no result exists yet.
  Future<Result<ExamResultEntity?>> getStudentResult(
    String examId,
    String studentId,
  );

  /// Manually grades a single answer with awarded marks and optional
  /// comment.
  Future<Result<StudentAnswerEntity>> gradeAnswer(
    String answerId,
    double marksAwarded, {
    String? comment,
  });

  /// Releases exam results to students, making them visible.
  Future<Result<void>> releaseResults(String examId);

  // ─── Statistics & Rankings ──────────────────────────────────────────

  /// Computes and returns aggregated exam statistics.
  Future<Result<ExamStatistics>> getExamStatistics(String examId);

  /// Retrieves live exam stats for the monitoring dashboard.
  Future<Result<LiveExamStats>> getLiveExamStats(String examId);

  /// Retrieves the exam leaderboard rankings.
  Future<Result<List<ExamRankingEntity>>> getRankings(String examId);

  // ─── Realtime Streams (Supabase Realtime) ───────────────────────────

  /// Watches exam sessions in real time for the monitoring dashboard.
  Stream<ExamSessionEntity> watchExamSessions(String examId);

  /// Watches exam attempts in real time (e.g., for submission tracking).
  Stream<ExamAttemptEntity> watchExamAttempts(String examId);

  /// Watches monitoring events in real time for live anti-cheat
  /// dashboards.
  Stream<MonitoringLogEntity> watchMonitoringEvents(String examId);
}
