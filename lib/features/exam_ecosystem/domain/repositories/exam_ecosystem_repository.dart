import '../../../../core/utils/result.dart';
import '../entities/exam_ecosystem_entities.dart';

/// Abstract contract for the Exam Ecosystem repository.
///
/// All exam ecosystem operations flow through this interface, enabling
/// Clean Architecture separation and testability.
abstract class ExamEcosystemRepository {
  // ─── Examination Bodies ────────────────────────────────────────────

  /// Get all examination bodies, optionally filtered by active status.
  Future<Result<List<ExaminationBody>>> getExaminationBodies({
    bool? isActive,
  });

  /// Get a single examination body by ID.
  Future<Result<ExaminationBody>> getExaminationBodyById(String id);

  /// Get examination bodies filtered by type.
  Future<Result<List<ExaminationBody>>> getExaminationBodiesByType(
    ExamBodyType examBodyType,
  );

  // ─── Examination Products ──────────────────────────────────────────

  /// Get examination products with optional filtering.
  Future<Result<List<ExaminationProduct>>> getExaminationProducts({
    String? examBodyId,
    ExamCategoryType? examCategory,
    PreparationType? preparationType,
    String? educationalLevelId,
    String? subjectId,
    bool? isActive,
  });

  /// Get a single examination product by ID.
  Future<Result<ExaminationProduct>> getExaminationProductById(String id);

  /// Create a new examination product.
  Future<Result<ExaminationProduct>> createExaminationProduct(
    ExaminationProduct product,
  );

  /// Update an existing examination product.
  Future<Result<ExaminationProduct>> updateExaminationProduct(
    ExaminationProduct product,
  );

  // ─── Mock Exams ────────────────────────────────────────────────────

  /// Get mock exams with optional filtering.
  Future<Result<List<MockExam>>> getMockExams({
    String? examinationProductId,
    String? schoolId,
    ExamBodyType? examBodyType,
    MockExamStatus? status,
  });

  /// Get a single mock exam by ID.
  Future<Result<MockExam>> getMockExamById(String id);

  /// Create a new mock exam.
  Future<Result<MockExam>> createMockExam(MockExam mockExam);

  /// Update an existing mock exam.
  Future<Result<MockExam>> updateMockExam(MockExam mockExam);

  /// Delete a mock exam by ID.
  Future<Result<bool>> deleteMockExam(String id);

  /// Publish a draft mock exam.
  Future<Result<MockExam>> publishMockExam(String id);

  /// Add a question to a mock exam.
  Future<Result<MockExamQuestion>> addMockExamQuestion(
    MockExamQuestion question,
  );

  /// Remove a question from a mock exam.
  Future<Result<bool>> removeMockExamQuestion(String questionId);

  // ─── Mock Exam Attempts ────────────────────────────────────────────

  /// Start a new mock exam attempt.
  Future<Result<MockExamAttempt>> startMockExamAttempt({
    required String mockExamId,
    required String userId,
    Map<String, dynamic>? deviceInfo,
  });

  /// Submit a mock exam attempt.
  Future<Result<MockExamAttempt>> submitMockExamAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
    int? timeTakenSeconds,
  });

  /// Get a single mock exam attempt by ID.
  Future<Result<MockExamAttempt>> getMockExamAttempt(String attemptId);

  /// Get all attempts for a user, optionally filtered by mock exam.
  Future<Result<List<MockExamAttempt>>> getUserMockExamAttempts({
    required String userId,
    String? mockExamId,
  });

  /// Get results for a specific mock exam (all attempts).
  Future<Result<List<MockExamAttempt>>> getMockExamResults(String mockExamId);

  // ─── Readiness ─────────────────────────────────────────────────────

  /// Get a specific readiness assessment by ID.
  Future<Result<ReadinessAssessment>> getReadinessAssessment(String id);

  /// Get readiness assessments for a user, optionally filtered.
  Future<Result<List<ReadinessAssessment>>> getUserReadiness({
    required String userId,
    String? examBodyId,
    String? subjectId,
  });

  /// Calculate readiness for a user for a given exam body/subject.
  Future<Result<ReadinessAssessment>> calculateReadiness({
    required String userId,
    required String examBodyId,
    String? subjectId,
  });

  /// Get exam-level readiness summary for a user.
  Future<Result<List<ReadinessAssessment>>> getExamReadiness({
    required String userId,
    required String examBodyId,
  });

  // ─── Study Plans ───────────────────────────────────────────────────

  /// Get study plans for a user.
  Future<Result<List<StudyPlan>>> getStudyPlans({
    required String userId,
    bool? isActive,
  });

  /// Get a single study plan by ID.
  Future<Result<StudyPlan>> getStudyPlanById(String id);

  /// Create a new study plan.
  Future<Result<StudyPlan>> createStudyPlan(StudyPlan studyPlan);

  /// Update an existing study plan.
  Future<Result<StudyPlan>> updateStudyPlan(StudyPlan studyPlan);

  /// Delete a study plan by ID.
  Future<Result<bool>> deleteStudyPlan(String id);

  /// Generate an AI-powered study plan.
  Future<Result<StudyPlan>> generateAiStudyPlan({
    required String userId,
    required String examBodyId,
    String? subjectId,
    String? educationalLevelId,
    DateTime? targetDate,
    int dailyStudyMinutes = 60,
  });

  // ─── Study Plan Activities ─────────────────────────────────────────

  /// Get activities for a study plan.
  Future<Result<List<StudyPlanActivity>>> getStudyPlanActivities(
    String studyPlanId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  });

  /// Create a new study plan activity.
  Future<Result<StudyPlanActivity>> createStudyPlanActivity(
    StudyPlanActivity activity,
  );

  /// Update a study plan activity.
  Future<Result<StudyPlanActivity>> updateStudyPlanActivity(
    StudyPlanActivity activity,
  );

  /// Mark a study plan activity as completed.
  Future<Result<StudyPlanActivity>> completeStudyPlanActivity({
    required String activityId,
    double? performanceScore,
    Map<String, dynamic>? metadata,
  });
}
