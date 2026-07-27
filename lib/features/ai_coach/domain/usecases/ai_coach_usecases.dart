import '../../../../core/utils/result.dart';
import '../entities/ai_coach_entities.dart';
import '../repositories/ai_coach_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// GET COACH SESSIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetCoachSessionsUseCase {
  final AiCoachRepository _repository;
  GetCoachSessionsUseCase(this._repository);

  Future<Result<List<AiCoachSession>>> call({
    required String userId,
    CoachSessionType? sessionType,
    int page = 1,
    int pageSize = 20,
  }) =>
      _repository.getCoachSessions(
        userId: userId,
        sessionType: sessionType,
        page: page,
        pageSize: pageSize,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE COACH SESSION USE CASE
// ═══════════════════════════════════════════════════════════════════════

class CreateCoachSessionUseCase {
  final AiCoachRepository _repository;
  CreateCoachSessionUseCase(this._repository);

  Future<Result<AiCoachSession>> call({
    required String userId,
    required CoachSessionType sessionType,
    String? context,
  }) =>
      _repository.createCoachSession(
        userId: userId,
        sessionType: sessionType,
        context: context,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE COACH SESSION USE CASE
// ═══════════════════════════════════════════════════════════════════════

class UpdateCoachSessionUseCase {
  final AiCoachRepository _repository;
  UpdateCoachSessionUseCase(this._repository);

  Future<Result<AiCoachSession>> call({
    required String sessionId,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? recommendations,
    String? studyPlanId,
  }) =>
      _repository.updateCoachSession(
        sessionId: sessionId,
        messages: messages,
        recommendations: recommendations,
        studyPlanId: studyPlanId,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GET RECOMMENDATIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetRecommendationsUseCase {
  final AiCoachRepository _repository;
  GetRecommendationsUseCase(this._repository);

  Future<Result<List<AiCoachRecommendation>>> call({
    required String userId,
    bool activeOnly = true,
  }) =>
      _repository.getRecommendations(
        userId: userId,
        activeOnly: activeOnly,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// DISMISS RECOMMENDATION USE CASE
// ═══════════════════════════════════════════════════════════════════════

class DismissRecommendationUseCase {
  final AiCoachRepository _repository;
  DismissRecommendationUseCase(this._repository);

  Future<Result<AiCoachRecommendation>> call({
    required String recommendationId,
  }) =>
      _repository.dismissRecommendation(
        recommendationId: recommendationId,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATE STUDY PLAN USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GenerateStudyPlanUseCase {
  final AiCoachRepository _repository;
  GenerateStudyPlanUseCase(this._repository);

  Future<Result<GeneratedStudyPlan>> call({
    required String userId,
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  }) =>
      _repository.generateStudyPlan(
        userId: userId,
        focusSubjectId: focusSubjectId,
        durationDays: durationDays,
        targetExamTypes: targetExamTypes,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// DETECT WEAK TOPICS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class DetectWeakTopicsUseCase {
  final AiCoachRepository _repository;
  DetectWeakTopicsUseCase(this._repository);

  Future<Result<List<WeakTopic>>> call({
    required String userId,
    String? subjectId,
  }) =>
      _repository.detectWeakTopics(
        userId: userId,
        subjectId: subjectId,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PREDICT READINESS USE CASE
// ═══════════════════════════════════════════════════════════════════════

class PredictReadinessUseCase {
  final AiCoachRepository _repository;
  PredictReadinessUseCase(this._repository);

  Future<Result<ReadinessPrediction>> call({
    required String userId,
    String? examType,
    DateTime? targetDate,
  }) =>
      _repository.predictReadiness(
        userId: userId,
        examType: examType,
        targetDate: targetDate,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// GET MOTIVATIONAL MESSAGE USE CASE
// ═══════════════════════════════════════════════════════════════════════

class GetMotivationalMessageUseCase {
  final AiCoachRepository _repository;
  GetMotivationalMessageUseCase(this._repository);

  Future<Result<String>> call({
    required String userId,
  }) =>
      _repository.getMotivationalMessage(userId: userId);
}
