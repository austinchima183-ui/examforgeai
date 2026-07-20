import '../../../../core/utils/result.dart';
import '../entities/exam_ecosystem_entities.dart';
import '../repositories/exam_ecosystem_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAMINATION BODIES USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetExaminationBodiesUseCase].
class GetExaminationBodiesParams {
  const GetExaminationBodiesParams({this.isActive});
  final bool? isActive;
}

/// Retrieves all examination bodies, optionally filtered by active status.
class GetExaminationBodiesUseCase {
  GetExaminationBodiesUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<ExaminationBody>>> call(
    GetExaminationBodiesParams params,
  ) async {
    return _repository.getExaminationBodies(isActive: params.isActive);
  }
}

/// Retrieves examination bodies filtered by type.
class GetExaminationBodiesByTypeUseCase {
  GetExaminationBodiesByTypeUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<ExaminationBody>>> call(ExamBodyType examBodyType) async {
    return _repository.getExaminationBodiesByType(examBodyType);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EXAMINATION PRODUCTS USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetExaminationProductsUseCase].
class GetExaminationProductsParams {
  const GetExaminationProductsParams({
    this.examBodyId,
    this.examCategory,
    this.preparationType,
    this.educationalLevelId,
    this.subjectId,
    this.isActive,
  });

  final String? examBodyId;
  final ExamCategoryType? examCategory;
  final PreparationType? preparationType;
  final String? educationalLevelId;
  final String? subjectId;
  final bool? isActive;
}

/// Retrieves examination products with optional filtering.
class GetExaminationProductsUseCase {
  GetExaminationProductsUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<ExaminationProduct>>> call(
    GetExaminationProductsParams params,
  ) async {
    return _repository.getExaminationProducts(
      examBodyId: params.examBodyId,
      examCategory: params.examCategory,
      preparationType: params.preparationType,
      educationalLevelId: params.educationalLevelId,
      subjectId: params.subjectId,
      isActive: params.isActive,
    );
  }
}

/// Params for [CreateExaminationProductUseCase].
class CreateExaminationProductParams {
  const CreateExaminationProductParams({required this.product});
  final ExaminationProduct product;
}

/// Creates a new examination product.
class CreateExaminationProductUseCase {
  CreateExaminationProductUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<ExaminationProduct>> call(
    CreateExaminationProductParams params,
  ) async {
    return _repository.createExaminationProduct(params.product);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MOCK EXAMS USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetMockExamsUseCase].
class GetMockExamsParams {
  const GetMockExamsParams({
    this.examinationProductId,
    this.schoolId,
    this.examBodyType,
    this.status,
  });

  final String? examinationProductId;
  final String? schoolId;
  final ExamBodyType? examBodyType;
  final MockExamStatus? status;
}

/// Retrieves mock exams with optional filtering.
class GetMockExamsUseCase {
  GetMockExamsUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<MockExam>>> call(GetMockExamsParams params) async {
    return _repository.getMockExams(
      examinationProductId: params.examinationProductId,
      schoolId: params.schoolId,
      examBodyType: params.examBodyType,
      status: params.status,
    );
  }
}

/// Params for [CreateMockExamUseCase].
class CreateMockExamParams {
  const CreateMockExamParams({required this.mockExam});
  final MockExam mockExam;
}

/// Creates a new mock exam.
class CreateMockExamUseCase {
  CreateMockExamUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<MockExam>> call(CreateMockExamParams params) async {
    return _repository.createMockExam(params.mockExam);
  }
}

/// Params for [PublishMockExamUseCase].
class PublishMockExamParams {
  const PublishMockExamParams({required this.mockExamId});
  final String mockExamId;
}

/// Publishes a draft mock exam.
class PublishMockExamUseCase {
  PublishMockExamUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<MockExam>> call(PublishMockExamParams params) async {
    return _repository.publishMockExam(params.mockExamId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MOCK EXAM ATTEMPT USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [StartMockExamAttemptUseCase].
class StartMockExamAttemptParams {
  const StartMockExamAttemptParams({
    required this.mockExamId,
    required this.userId,
    this.deviceInfo,
  });

  final String mockExamId;
  final String userId;
  final Map<String, dynamic>? deviceInfo;
}

/// Starts a new mock exam attempt.
class StartMockExamAttemptUseCase {
  StartMockExamAttemptUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<MockExamAttempt>> call(
    StartMockExamAttemptParams params,
  ) async {
    return _repository.startMockExamAttempt(
      mockExamId: params.mockExamId,
      userId: params.userId,
      deviceInfo: params.deviceInfo,
    );
  }
}

/// Params for [SubmitMockExamAttemptUseCase].
class SubmitMockExamAttemptParams {
  const SubmitMockExamAttemptParams({
    required this.attemptId,
    required this.answers,
    this.timeTakenSeconds,
  });

  final String attemptId;
  final Map<String, dynamic> answers;
  final int? timeTakenSeconds;
}

/// Submits a mock exam attempt.
class SubmitMockExamAttemptUseCase {
  SubmitMockExamAttemptUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<MockExamAttempt>> call(
    SubmitMockExamAttemptParams params,
  ) async {
    return _repository.submitMockExamAttempt(
      attemptId: params.attemptId,
      answers: params.answers,
      timeTakenSeconds: params.timeTakenSeconds,
    );
  }
}

/// Params for [GetMockExamResultsUseCase].
class GetMockExamResultsParams {
  const GetMockExamResultsParams({required this.mockExamId});
  final String mockExamId;
}

/// Gets results for a specific mock exam.
class GetMockExamResultsUseCase {
  GetMockExamResultsUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<MockExamAttempt>>> call(
    GetMockExamResultsParams params,
  ) async {
    return _repository.getMockExamResults(params.mockExamId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// READINESS USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetReadinessAssessmentUseCase].
class GetReadinessAssessmentParams {
  const GetReadinessAssessmentParams({required this.assessmentId});
  final String assessmentId;
}

/// Gets a specific readiness assessment.
class GetReadinessAssessmentUseCase {
  GetReadinessAssessmentUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<ReadinessAssessment>> call(
    GetReadinessAssessmentParams params,
  ) async {
    return _repository.getReadinessAssessment(params.assessmentId);
  }
}

/// Params for [CalculateReadinessUseCase].
class CalculateReadinessParams {
  const CalculateReadinessParams({
    required this.userId,
    required this.examBodyId,
    this.subjectId,
  });

  final String userId;
  final String examBodyId;
  final String? subjectId;
}

/// Calculates readiness for a user for a given exam body/subject.
class CalculateReadinessUseCase {
  CalculateReadinessUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<ReadinessAssessment>> call(
    CalculateReadinessParams params,
  ) async {
    return _repository.calculateReadiness(
      userId: params.userId,
      examBodyId: params.examBodyId,
      subjectId: params.subjectId,
    );
  }
}

/// Params for [GetExamReadinessUseCase].
class GetExamReadinessParams {
  const GetExamReadinessParams({
    required this.userId,
    required this.examBodyId,
  });

  final String userId;
  final String examBodyId;
}

/// Gets exam-level readiness summary for a user.
class GetExamReadinessUseCase {
  GetExamReadinessUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<ReadinessAssessment>>> call(
    GetExamReadinessParams params,
  ) async {
    return _repository.getExamReadiness(
      userId: params.userId,
      examBodyId: params.examBodyId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLAN USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetStudyPlansUseCase].
class GetStudyPlansParams {
  const GetStudyPlansParams({required this.userId, this.isActive});
  final String userId;
  final bool? isActive;
}

/// Retrieves study plans for a user.
class GetStudyPlansUseCase {
  GetStudyPlansUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<StudyPlan>>> call(GetStudyPlansParams params) async {
    return _repository.getStudyPlans(
      userId: params.userId,
      isActive: params.isActive,
    );
  }
}

/// Params for [CreateStudyPlanUseCase].
class CreateStudyPlanParams {
  const CreateStudyPlanParams({required this.studyPlan});
  final StudyPlan studyPlan;
}

/// Creates a new study plan.
class CreateStudyPlanUseCase {
  CreateStudyPlanUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<StudyPlan>> call(CreateStudyPlanParams params) async {
    return _repository.createStudyPlan(params.studyPlan);
  }
}

/// Params for [GenerateAiStudyPlanUseCase].
class GenerateAiStudyPlanParams {
  const GenerateAiStudyPlanParams({
    required this.userId,
    required this.examBodyId,
    this.subjectId,
    this.educationalLevelId,
    this.targetDate,
    this.dailyStudyMinutes = 60,
  });

  final String userId;
  final String examBodyId;
  final String? subjectId;
  final String? educationalLevelId;
  final DateTime? targetDate;
  final int dailyStudyMinutes;
}

/// Generates an AI-powered study plan.
class GenerateAiStudyPlanUseCase {
  GenerateAiStudyPlanUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<StudyPlan>> call(GenerateAiStudyPlanParams params) async {
    return _repository.generateAiStudyPlan(
      userId: params.userId,
      examBodyId: params.examBodyId,
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
      targetDate: params.targetDate,
      dailyStudyMinutes: params.dailyStudyMinutes,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLAN ACTIVITY USE CASES
// ═══════════════════════════════════════════════════════════════════════

/// Params for [GetStudyPlanActivitiesUseCase].
class GetStudyPlanActivitiesParams {
  const GetStudyPlanActivitiesParams({
    required this.studyPlanId,
    this.startDate,
    this.endDate,
    this.isCompleted,
  });

  final String studyPlanId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isCompleted;
}

/// Retrieves activities for a study plan.
class GetStudyPlanActivitiesUseCase {
  GetStudyPlanActivitiesUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<List<StudyPlanActivity>>> call(
    GetStudyPlanActivitiesParams params,
  ) async {
    return _repository.getStudyPlanActivities(
      params.studyPlanId,
      startDate: params.startDate,
      endDate: params.endDate,
      isCompleted: params.isCompleted,
    );
  }
}

/// Params for [CompleteStudyPlanActivityUseCase].
class CompleteStudyPlanActivityParams {
  const CompleteStudyPlanActivityParams({
    required this.activityId,
    this.performanceScore,
    this.metadata,
  });

  final String activityId;
  final double? performanceScore;
  final Map<String, dynamic>? metadata;
}

/// Marks a study plan activity as completed.
class CompleteStudyPlanActivityUseCase {
  CompleteStudyPlanActivityUseCase(this._repository);
  final ExamEcosystemRepository _repository;

  Future<Result<StudyPlanActivity>> call(
    CompleteStudyPlanActivityParams params,
  ) async {
    return _repository.completeStudyPlanActivity(
      activityId: params.activityId,
      performanceScore: params.performanceScore,
      metadata: params.metadata,
    );
  }
}
