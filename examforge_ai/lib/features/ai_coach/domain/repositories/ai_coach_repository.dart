import '../../../../core/utils/result.dart';
import '../entities/ai_coach_entities.dart';

/// Abstract contract for the AI Coach repository.
///
/// Defines all operations the AI Coach feature requires from
/// the data layer. The implementation maps Supabase / network
/// exceptions to domain [Failure]s and wraps results in [Result<T>].
abstract class AiCoachRepository {
  // ═══════════════════════════════════════════════════════════════════════
  // COACH SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches all coach sessions for a user.
  Future<Result<List<AiCoachSession>>> getCoachSessions({
    required String userId,
    CoachSessionType? sessionType,
    int page = 1,
    int pageSize = 20,
  });

  /// Creates a new coach session.
  Future<Result<AiCoachSession>> createCoachSession({
    required String userId,
    required CoachSessionType sessionType,
    String? context,
  });

  /// Updates an existing coach session (adds messages, etc.).
  Future<Result<AiCoachSession>> updateCoachSession({
    required String sessionId,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? recommendations,
    String? studyPlanId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets active recommendations for a user.
  Future<Result<List<AiCoachRecommendation>>> getRecommendations({
    required String userId,
    bool? activeOnly,
  });

  /// Dismisses a recommendation.
  Future<Result<AiCoachRecommendation>> dismissRecommendation({
    required String recommendationId,
  });

  // ═══════════════════════════════════════════════════════════════════════
  // AI-POWERED FEATURES
  // ═══════════════════════════════════════════════════════════════════════

  /// Generates a personalized study plan using AI.
  Future<Result<GeneratedStudyPlan>> generateStudyPlan({
    required String userId,
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  });

  /// Detects weak topics based on student's performance history.
  Future<Result<List<WeakTopic>>> detectWeakTopics({
    required String userId,
    String? subjectId,
  });

  /// Predicts exam readiness based on current performance.
  Future<Result<ReadinessPrediction>> predictReadiness({
    required String userId,
    String? examType,
    DateTime? targetDate,
  });

  /// Gets a motivational message personalized for the student.
  Future<Result<String>> getMotivationalMessage({
    required String userId,
  });
}
