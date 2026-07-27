import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/ai_coach_entities.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../datasources/ai_coach_remote_datasource.dart';
import '../models/ai_coach_models.dart';

/// Concrete implementation of [AiCoachRepository] that delegates
/// all operations to [AiCoachRemoteDatasource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class AiCoachRepositoryImpl implements AiCoachRepository {
  AiCoachRepositoryImpl({
    required AiCoachRemoteDatasource remoteDatasource,
    required sb.SupabaseClient supabaseClient,
  })  : _datasource = remoteDatasource,
        _supabaseClient = supabaseClient;

  final AiCoachRemoteDatasource _datasource;
  final sb.SupabaseClient _supabaseClient;

  // ═══════════════════════════════════════════════════════════════════════
  // Helper: Safe call with exception → Failure mapping
  // ═══════════════════════════════════════════════════════════════════════

  Future<Result<T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final result = await call();
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } on UnauthorizedException catch (e) {
      return FailureResult(Failure.unauthorized(message: e.message));
    } on ForbiddenException catch (e) {
      return FailureResult(Failure.forbidden(message: e.message));
    } on ValidationException catch (e) {
      return FailureResult(Failure.validation(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ),);
    } on CacheException catch (e) {
      return FailureResult(Failure.cache(message: e.message));
    } catch (e) {
      AppLogger.error(
          'Unexpected exception in AiCoachRepositoryImpl', error: e,);
      return FailureResult(Failure.server(
        message: e.toString(),
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COACH SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AiCoachSession>>> getCoachSessions({
    required String userId,
    CoachSessionType? sessionType,
    int page = 1,
    int pageSize = 20,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getCoachSessions(
          userId: userId,
          sessionType: sessionType?.value,
          page: page,
          pageSize: pageSize,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AiCoachSession>> createCoachSession({
    required String userId,
    required CoachSessionType sessionType,
    String? context,
  }) =>
      _safeCall(() async {
        final data = AiCoachSessionModel(
          id: '',
          userId: userId,
          sessionType: sessionType.value,
          context: context,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toJson();
        final model = await _datasource.createCoachSession(data: data);
        return model.toEntity();
      });

  @override
  Future<Result<AiCoachSession>> updateCoachSession({
    required String sessionId,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? recommendations,
    String? studyPlanId,
  }) =>
      _safeCall(() async {
        final data = <String, dynamic>{};
        if (messages != null) data['messages'] = messages;
        if (recommendations != null) data['recommendations'] = recommendations;
        if (studyPlanId != null) data['study_plan_id'] = studyPlanId;
        final model = await _datasource.updateCoachSession(
          sessionId: sessionId,
          data: data,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AiCoachRecommendation>>> getRecommendations({
    required String userId,
    bool? activeOnly,
  }) =>
      _safeCall(() async {
        final models = await _datasource.getRecommendations(
          userId: userId,
          activeOnly: activeOnly,
        );
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AiCoachRecommendation>> dismissRecommendation({
    required String recommendationId,
  }) =>
      _safeCall(() async {
        final model = await _datasource.dismissRecommendation(
          recommendationId: recommendationId,
        );
        return model.toEntity();
      });

  // ═══════════════════════════════════════════════════════════════════════
  // AI-POWERED FEATURES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<GeneratedStudyPlan>> generateStudyPlan({
    required String userId,
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  }) =>
      _safeCall(() async {
        final response = await _datasource.generateStudyPlan(
          userId: userId,
          focusSubjectId: focusSubjectId,
          durationDays: durationDays,
          targetExamTypes: targetExamTypes,
        );

        return GeneratedStudyPlan(
          title: response['title'] as String? ?? 'AI Study Plan',
          description: response['description'] as String? ?? '',
          tasks: (response['tasks'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [],
          estimatedDurationDays:
              response['estimated_duration_days'] as int? ?? 30,
          focusAreas: (response['focus_areas'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          milestones: (response['milestones'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [],
        );
      });

  @override
  Future<Result<List<WeakTopic>>> detectWeakTopics({
    required String userId,
    String? subjectId,
  }) =>
      _safeCall(() async {
        final topicsData = await _datasource.detectWeakTopics(
          userId: userId,
          subjectId: subjectId,
        );

        return topicsData.map((data) {
          return WeakTopic(
            topicId: data['topic_id'] as String? ?? '',
            topicName: data['topic_name'] as String? ?? 'Unknown',
            subjectName: data['subject_name'] as String? ?? '',
            accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
            attemptsCount: data['attempts_count'] as int? ?? 0,
            correctCount: data['correct_count'] as int? ?? 0,
            severity: data['severity'] as String? ?? 'medium',
            recommendations: (data['recommendations'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [],
          );
        }).toList();
      });

  @override
  Future<Result<ReadinessPrediction>> predictReadiness({
    required String userId,
    String? examType,
    DateTime? targetDate,
  }) =>
      _safeCall(() async {
        final response = await _datasource.predictReadiness(
          userId: userId,
          examType: examType,
          targetDate: targetDate,
        );

        final subjectScoresRaw =
            response['subject_scores'] as Map<String, dynamic>? ?? {};
        final subjectScores = subjectScoresRaw.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        return ReadinessPrediction(
          overallScore:
              (response['overall_score'] as num?)?.toDouble() ?? 0.0,
          confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
          subjectScores: subjectScores,
          predictedGrade: response['predicted_grade'] as String?,
          improvementAreas:
              (response['improvement_areas'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
          strengths: (response['strengths'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          recommendedStudyHours:
              response['recommended_study_hours'] as int? ?? 0,
          targetDate: response['target_date'] != null
              ? DateTime.tryParse(response['target_date'] as String)
              : null,
        );
      });

  @override
  Future<Result<String>> getMotivationalMessage({
    required String userId,
  }) =>
      _safeCall(() async {
        return await _datasource.getMotivationalMessage(userId: userId);
      });
}
