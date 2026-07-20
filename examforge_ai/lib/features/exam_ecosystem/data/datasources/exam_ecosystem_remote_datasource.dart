import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote Exam Ecosystem data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain JSON maps. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class ExamEcosystemRemoteDataSource {
  // ─── Examination Bodies ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExaminationBodies({
    bool? isActive,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<Map<String, dynamic>> getExaminationBodyById(String id);
  Future<List<Map<String, dynamic>>> getExaminationBodiesByType(
    String examBodyType, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Examination Products ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExaminationProducts(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getExaminationProductById(String id);
  Future<Map<String, dynamic>> createExaminationProduct(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateExaminationProduct(String id, Map<String, dynamic> data);

  // ─── Mock Exams ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMockExams(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getMockExamById(String id);
  Future<Map<String, dynamic>> createMockExam(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateMockExam(String id, Map<String, dynamic> data);
  Future<void> deleteMockExam(String id);
  Future<Map<String, dynamic>> publishMockExam(String id);
  Future<Map<String, dynamic>> addMockExamQuestion(Map<String, dynamic> data);
  Future<void> removeMockExamQuestion(String questionId);

  // ─── Mock Exam Attempts ────────────────────────────────────────────

  Future<Map<String, dynamic>> startMockExamAttempt(Map<String, dynamic> data);
  Future<Map<String, dynamic>> submitMockExamAttempt(String attemptId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> getMockExamAttempt(String attemptId);
  Future<List<Map<String, dynamic>>> getUserMockExamAttempts(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<List<Map<String, dynamic>>> getMockExamResults(
    String mockExamId, {
    int limit = PaginatedQueryMixin.defaultPageSize,
  });

  // ─── Readiness ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getReadinessAssessment(String id);
  Future<List<Map<String, dynamic>>> getUserReadiness(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> calculateReadiness(Map<String, dynamic> params);
  Future<List<Map<String, dynamic>>> getExamReadiness(Map<String, dynamic> params);

  // ─── Study Plans ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudyPlans(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> getStudyPlanById(String id);
  Future<Map<String, dynamic>> createStudyPlan(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateStudyPlan(String id, Map<String, dynamic> data);
  Future<void> deleteStudyPlan(String id);
  Future<Map<String, dynamic>> generateAiStudyPlan(Map<String, dynamic> params);

  // ─── Study Plan Activities ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStudyPlanActivities(String studyPlanId, {Map<String, dynamic>? filters});
  Future<Map<String, dynamic>> createStudyPlanActivity(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateStudyPlanActivity(String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>> completeStudyPlanActivity(String id, Map<String, dynamic> data);
}

// ═══════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Concrete implementation using the Supabase client.
class ExamEcosystemRemoteDataSourceImpl
    implements ExamEcosystemRemoteDataSource {
  ExamEcosystemRemoteDataSourceImpl({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _client;

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════════════════

  /// Executes a Supabase query, catching postgrest errors and converting
  /// them to domain [Exception] types.
  Future<T> _safeCall<T>(Future<T> Function() callback) async {
    try {
      return await callback();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Supabase Postgrest error', error: e);
      if (e.code == '404' || e.code == 'PGRST116') {
        throw NotFoundException(e.message);
      }
      if (e.code == '401') {
        throw UnauthorizedException(e.message);
      }
      if (e.code == '403') {
        throw ForbiddenException(e.message);
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } on sb.AuthException catch (e) {
      AppLogger.error('Supabase Auth error', error: e);
      throw AuthException(message: e.message, code: e.code ?? 'auth_error');
    } catch (e) {
      AppLogger.error('Unexpected datasource error', error: e);
      throw ServerException(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAMINATION BODIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getExaminationBodies({
    bool? isActive,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    return _safeCall(() async {
      var query = _client.from('examination_bodies').select();
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      // PERF: Added limit to prevent unbounded query on examination_bodies
      final response = await query.order('name').limit(limit);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> getExaminationBodyById(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('examination_bodies')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getExaminationBodiesByType(
    String examBodyType, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    return _safeCall(() async {
      // PERF: Added limit to prevent unbounded query on examination_bodies
      final response = await _client
          .from('examination_bodies')
          .select()
          .eq('exam_body_type', examBodyType)
          .order('name')
          .limit(limit);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXAMINATION PRODUCTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getExaminationProducts(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    return _safeCall(() async {
      var query = _client.from('examination_products').select();
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('name').range(offset, offset + limit - 1);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> getExaminationProductById(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('examination_products')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> createExaminationProduct(
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('examination_products')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> updateExaminationProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('examination_products')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOCK EXAMS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getMockExams(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    return _safeCall(() async {
      var query = _client.from('mock_exams').select();
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> getMockExamById(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exams')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> createMockExam(Map<String, dynamic> data) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exams')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> updateMockExam(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exams')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<void> deleteMockExam(String id) async {
    return _safeCall(() async {
      await _client.from('mock_exams').delete().eq('id', id);
    });
  }

  @override
  Future<Map<String, dynamic>> publishMockExam(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exams')
          .update({
            'status': 'published',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> addMockExamQuestion(
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exam_questions')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<void> removeMockExamQuestion(String questionId) async {
    return _safeCall(() async {
      await _client.from('mock_exam_questions').delete().eq('id', questionId);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MOCK EXAM ATTEMPTS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> startMockExamAttempt(
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exam_attempts')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> submitMockExamAttempt(
    String attemptId,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exam_attempts')
          .update(data)
          .eq('id', attemptId)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> getMockExamAttempt(String attemptId) async {
    return _safeCall(() async {
      final response = await _client
          .from('mock_exam_attempts')
          .select()
          .eq('id', attemptId)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUserMockExamAttempts(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    return _safeCall(() async {
      var query = _client.from('mock_exam_attempts').select();
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('started_at', ascending: false).range(offset, offset + limit - 1);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getMockExamResults(
    String mockExamId, {
    int limit = PaginatedQueryMixin.defaultPageSize,
  }) async {
    return _safeCall(() async {
      // PERF: Added limit to prevent unbounded query on mock_exam_attempts
      final response = await _client
          .from('mock_exam_attempts')
          .select()
          .eq('mock_exam_id', mockExamId)
          .eq('is_completed', true)
          .order('total_score', ascending: false)
          .limit(limit);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // READINESS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getReadinessAssessment(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('readiness_assessments')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUserReadiness(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    return _safeCall(() async {
      var query = _client.from('readiness_assessments').select();
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('assessed_at', ascending: false).range(offset, offset + limit - 1);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> calculateReadiness(
    Map<String, dynamic> params,
  ) async {
    return _safeCall(() async {
      final response = await _client.rpc(
        'calculate_readiness',
        params: params,
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return Map<String, dynamic>.from(response as Map);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getExamReadiness(
    Map<String, dynamic> params,
  ) async {
    return _safeCall(() async {
      final response = await _client.rpc(
        'get_exam_readiness',
        params: params,
      );
      if (response is List) {
        return response
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLANS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getStudyPlans(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    return _safeCall(() async {
      var query = _client.from('study_plans').select();
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> getStudyPlanById(String id) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plans')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> createStudyPlan(Map<String, dynamic> data) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plans')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> updateStudyPlan(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plans')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<void> deleteStudyPlan(String id) async {
    return _safeCall(() async {
      await _client.from('study_plans').delete().eq('id', id);
    });
  }

  @override
  Future<Map<String, dynamic>> generateAiStudyPlan(
    Map<String, dynamic> params,
  ) async {
    return _safeCall(() async {
      final response = await _client.rpc(
        'generate_ai_study_plan',
        params: params,
      );
      if (response is Map<String, dynamic>) {
        return response;
      }
      return Map<String, dynamic>.from(response as Map);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY PLAN ACTIVITIES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<List<Map<String, dynamic>>> getStudyPlanActivities(
    String studyPlanId, {
    Map<String, dynamic>? filters,
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    return _safeCall(() async {
      var query = _client
          .from('study_plan_activities')
          .select()
          .eq('study_plan_id', studyPlanId);
      filters?.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
      // PERF: Added limit to prevent unbounded query on study_plan_activities
      final response = await query.order('scheduled_date').limit(limit);
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  @override
  Future<Map<String, dynamic>> createStudyPlanActivity(
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plan_activities')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> updateStudyPlanActivity(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plan_activities')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }

  @override
  Future<Map<String, dynamic>> completeStudyPlanActivity(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _safeCall(() async {
      final response = await _client
          .from('study_plan_activities')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            ...data,
          })
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    });
  }
}
