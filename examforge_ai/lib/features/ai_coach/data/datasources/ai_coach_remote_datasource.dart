import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/ai_coach_models.dart';

/// Abstract contract for the AI Coach remote data source.
abstract class AiCoachRemoteDatasource {
  Future<List<AiCoachSessionModel>> getCoachSessions({
    required String userId,
    String? sessionType,
    int page = 1,
    int pageSize = 20,
  });

  Future<AiCoachSessionModel> createCoachSession({
    required Map<String, dynamic> data,
  });

  Future<AiCoachSessionModel> updateCoachSession({
    required String sessionId,
    required Map<String, dynamic> data,
  });

  Future<List<AiCoachRecommendationModel>> getRecommendations({
    required String userId,
    bool? activeOnly,
  });

  Future<AiCoachRecommendationModel> dismissRecommendation({
    required String recommendationId,
  });

  Future<Map<String, dynamic>> generateStudyPlan({
    required String userId,
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  });

  Future<List<Map<String, dynamic>>> detectWeakTopics({
    required String userId,
    String? subjectId,
  });

  Future<Map<String, dynamic>> predictReadiness({
    required String userId,
    String? examType,
    DateTime? targetDate,
  });

  Future<String> getMotivationalMessage({
    required String userId,
  });
}

/// Supabase implementation of [AiCoachRemoteDatasource].
class AiCoachRemoteDatasourceImpl implements AiCoachRemoteDatasource {
  AiCoachRemoteDatasourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ── Table name constants ───────────────────────────────────────────────
  static const _coachSessionsTable = 'ai_coach_sessions';
  static const _coachRecommendationsTable = 'ai_coach_recommendations';

  // ── Edge function names ────────────────────────────────────────────────
  static const _generateStudyPlanFunction = 'ai-coach-generate-study-plan';
  static const _detectWeakTopicsFunction = 'ai-coach-detect-weak-topics';
  static const _predictReadinessFunction = 'ai-coach-predict-readiness';
  static const _motivationalMessageFunction = 'ai-coach-motivational-message';
  static const _coachChatFunction = 'ai-coach-chat';

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

  Never _handleGenericException(Object e, String operation) {
    AppLogger.error('Failed to $operation', error: e);
    if (e is sb.AuthException) {
      throw UnauthorizedException(message: e.message);
    }
    throw ServerException(message: e.toString(), statusCode: 500);
  }

  /// Invokes a Supabase Edge Function and returns the response data.
  Future<Map<String, dynamic>> _invokeFunction(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        functionName,
        body: body,
      );

      if (response.status != 200) {
        throw ServerException(
          message: 'Function $functionName failed: ${response.data}',
          statusCode: response.status,
        );
      }

      return response.data as Map<String, dynamic>;
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      _handleGenericException(e, 'invoke function $functionName');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // COACH SESSIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<AiCoachSessionModel>> getCoachSessions({
    required String userId,
    String? sessionType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase
          .from(_coachSessionsTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      if (sessionType != null) {
        query = query.eq('session_type', sessionType);
      }

      final offset = (page - 1) * pageSize;
      final response = await query.range(offset, offset + pageSize - 1);

      return response
          .map<AiCoachSessionModel>(
              (json) => AiCoachSessionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get coach sessions');
    }
  }

  @override
  Future<AiCoachSessionModel> createCoachSession({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_coachSessionsTable)
          .insert(data)
          .select()
          .single();

      return AiCoachSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'create coach session');
    }
  }

  @override
  Future<AiCoachSessionModel> updateCoachSession({
    required String sessionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(_coachSessionsTable)
          .update(data)
          .eq('id', sessionId)
          .select()
          .single();

      return AiCoachSessionModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'update coach session');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<AiCoachRecommendationModel>> getRecommendations({
    required String userId,
    bool? activeOnly,
  }) async {
    try {
      var query = _supabase
          .from(_coachRecommendationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (activeOnly == true) {
        query = query.eq('is_dismissed', false);
      }

      final response = await query;

      return response
          .map<AiCoachRecommendationModel>((json) =>
              AiCoachRecommendationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'get recommendations');
    }
  }

  @override
  Future<AiCoachRecommendationModel> dismissRecommendation({
    required String recommendationId,
  }) async {
    try {
      final response = await _supabase
          .from(_coachRecommendationsTable)
          .update({
            'is_dismissed': true,
            'dismissed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recommendationId)
          .select()
          .single();

      return AiCoachRecommendationModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      _mapPostgrestException(e);
    } catch (e) {
      _handleGenericException(e, 'dismiss recommendation');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI-POWERED FEATURES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> generateStudyPlan({
    required String userId,
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  }) =>
      _invokeFunction(_generateStudyPlanFunction, {
        'user_id': userId,
        if (focusSubjectId != null) 'focus_subject_id': focusSubjectId,
        if (durationDays != null) 'duration_days': durationDays,
        if (targetExamTypes != null) 'target_exam_types': targetExamTypes,
      });

  @override
  Future<List<Map<String, dynamic>>> detectWeakTopics({
    required String userId,
    String? subjectId,
  }) async {
    final response = await _invokeFunction(_detectWeakTopicsFunction, {
      'user_id': userId,
      if (subjectId != null) 'subject_id': subjectId,
    });

    final topics = response['weak_topics'] as List<dynamic>? ?? [];
    return topics.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<Map<String, dynamic>> predictReadiness({
    required String userId,
    String? examType,
    DateTime? targetDate,
  }) =>
      _invokeFunction(_predictReadinessFunction, {
        'user_id': userId,
        if (examType != null) 'exam_type': examType,
        if (targetDate != null) 'target_date': targetDate.toIso8601String(),
      });

  @override
  Future<String> getMotivationalMessage({
    required String userId,
  }) async {
    final response = await _invokeFunction(_motivationalMessageFunction, {
      'user_id': userId,
    });
    return response['message'] as String? ??
        'Keep going! Every step counts towards your goals. 🌟';
  }
}
