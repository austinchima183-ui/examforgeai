import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote CCMS data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain JSON maps. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class CcmsRemoteDataSource {
  // ─── Educational Levels ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEducationalLevels({
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<List<Map<String, dynamic>>> getSchoolLevels(String schoolId);
  Future<Map<String, dynamic>> configureSchoolLevel(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateSchoolLevelConfiguration(
    String id,
    Map<String, dynamic> data,
  );

  // ─── Curricula ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCurricula(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getCurriculumById(String id);
  Future<Map<String, dynamic>> createCurriculum(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateCurriculum(String id, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getCurriculumVersions(
    String curriculumId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<List<Map<String, dynamic>>> getCurriculumLevelMappings(
    String curriculumId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Subjects ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSubjects(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getSubjectById(String id);
  Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateSubject(String id, Map<String, dynamic> data);
  Future<void> deleteSubject(String id);
  Future<List<Map<String, dynamic>>> getLevelSubjects(String educationalLevelId);

  // ─── Topics ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTopics(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> getTopicById(String id);
  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateTopic(String id, Map<String, dynamic> data);
  Future<void> deleteTopic(String id);
  Future<List<Map<String, dynamic>>> getSubtopics(
    String topicId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<Map<String, dynamic>> createSubtopic(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateSubtopic(String id, Map<String, dynamic> data);
  Future<void> deleteSubtopic(String id);
  Future<List<Map<String, dynamic>>> getCurriculumTree(String subjectId);

  // ─── Learning Objectives ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLearningObjectives(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> createLearningObjective(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateLearningObjective(
    String id,
    Map<String, dynamic> data,
  );
  Future<void> deleteLearningObjective(String id);

  // ─── Content ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getContentItems(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> getContentById(String id);
  Future<Map<String, dynamic>> createContent(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateContent(String id, Map<String, dynamic> data);
  Future<void> deleteContent(String id);
  Future<Map<String, dynamic>> publishContent(String id);
  Future<Map<String, dynamic>> archiveContent(String id);
  Future<List<Map<String, dynamic>>> getContentVersions(
    String contentItemId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<Map<String, dynamic>> getContentWithDetails(String id);

  // ─── Reviews ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getContentReviews(
    String contentItemId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Imports ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createImport(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getImports(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> getImportById(String id);

  // ─── Collections ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCollections(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> getCollectionById(String id);
  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateCollection(String id, Map<String, dynamic> data);
  Future<void> deleteCollection(String id);
  Future<Map<String, dynamic>> addCollectionItem(Map<String, dynamic> data);
  Future<void> removeCollectionItem(String collectionItemId);

  // ─── AI Curriculum ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAiCurriculumConfig(Map<String, dynamic> params);
  Future<Map<String, dynamic>> upsertAiCurriculumConfig(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getAiGenerationRules(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> createAiGenerationRule(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateAiGenerationRule(
    String id,
    Map<String, dynamic> data,
  );

  // ─── Answer Repository ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getAnswerEntry(String contentItemId);
  Future<Map<String, dynamic>> createAnswerEntry(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateAnswerEntry(String id, Map<String, dynamic> data);
  Future<Map<String, dynamic>> verifyAnswer(Map<String, dynamic> params);

  // ─── Stats ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCcmsStats(Map<String, dynamic> params);

  // ─── Audit ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> recordAuditEvent(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getAuditTrail(Map<String, dynamic> filters);

  // ─── MFA ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMfaConfig(String userId);
  Future<Map<String, dynamic>> enableMfa(Map<String, dynamic> params);
  Future<void> disableMfa(Map<String, dynamic> params);
  Future<bool> verifyMfa(Map<String, dynamic> params);

  // ─── API Keys ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> data);
  Future<void> revokeApiKey(String apiKeyId);
  Future<List<Map<String, dynamic>>> getApiKeys(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });

  // ─── Security ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> recordSecurityEvent(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSecurityEvents(
    Map<String, dynamic> filters,
  );
  Future<bool> checkRateLimit(Map<String, dynamic> params);

  // ─── Sessions ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserSessions(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  });
  Future<void> invalidateUserSessions(Map<String, dynamic> params);
  Future<void> invalidateAllOtherSessions(Map<String, dynamic> params);

  // ─── Monitoring ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> recordMetric(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSystemMetrics(
    Map<String, dynamic> filters,
  );
  Future<List<Map<String, dynamic>>> getAlertRules(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  });
  Future<Map<String, dynamic>> createAlertRule(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getAlertIncidents(
    Map<String, dynamic> filters,
  );
  Future<Map<String, dynamic>> acknowledgeAlert(Map<String, dynamic> params);
  Future<Map<String, dynamic>> resolveAlert(Map<String, dynamic> params);

  // ─── Performance ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> recordPerformanceLog(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getPerformanceLogs(
    Map<String, dynamic> filters,
  );

  // ─── Errors ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> reportError(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getErrorReports(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> resolveError(Map<String, dynamic> params);

  // ─── Deployments ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDeployments(Map<String, dynamic> filters);
  Future<Map<String, dynamic>> createDeployment(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateDeploymentStatus(
    Map<String, dynamic> params,
  );

  // ─── Testing ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> recordTestResult(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getTestResults(Map<String, dynamic> filters);
}

// ═══════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class CcmsRemoteDataSourceImpl implements CcmsRemoteDataSource {
  CcmsRemoteDataSourceImpl({required sb.SupabaseClient supabase})
      : _supabase = supabase;

  final sb.SupabaseClient _supabase;

  // ─── Helper: Handle Supabase errors ────────────────────────────────

  Never _handlePostgrestError(sb.PostgrestException e) {
    AppLogger.error('Supabase error: ${e.message}', error: e);
    if (e.code == '401') {
      throw UnauthorizedException(message: e.message);
    } else if (e.code == '403') {
      throw ForbiddenException(message: e.message);
    } else if (e.code == '404' || e.code == 'PGRST116') {
      throw NotFoundException(message: e.message);
    }
    throw ServerException(
      message: e.message,
      statusCode: int.tryParse(e.code ?? '500') ?? 500,
      data: e.details,
    );
  }

  // ─── Educational Levels ────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getEducationalLevels({
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on educational_levels
      final response = await _supabase
          .from('educational_levels')
          .select()
          .eq('is_active', true)
          .order('level_order')
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSchoolLevels(String schoolId) async {
    try {
      final response = await _supabase.rpc(
        'get_school_levels',
        params: {'p_school_id': schoolId},
      );
      return List<Map<String, dynamic>>.from(response as List);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> configureSchoolLevel(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('school_level_configurations')
          .upsert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateSchoolLevelConfiguration(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('school_level_configurations')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Curricula ─────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getCurricula(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('curricula').select();

      if (filters.containsKey('country_code')) {
        query = query.eq('country_code', filters['country_code'] as String);
      }
      if (filters.containsKey('curriculum_type')) {
        query =
            query.eq('curriculum_type', filters['curriculum_type'] as String);
      }
      if (filters.containsKey('is_active')) {
        query = query.eq('is_active', filters['is_active'] as bool);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('name').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCurriculumById(String id) async {
    try {
      final response = await _supabase
          .from('curricula')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createCurriculum(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('curricula')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateCurriculum(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('curricula')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurriculumVersions(
    String curriculumId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on curriculum_versions
      final response = await _supabase
          .from('curriculum_versions')
          .select()
          .eq('curriculum_id', curriculumId)
          .order('version_number', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurriculumLevelMappings(
    String curriculumId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on curriculum_level_mappings
      final response = await _supabase
          .from('curriculum_level_mappings')
          .select()
          .eq('curriculum_id', curriculumId)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Subjects ──────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSubjects(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('subjects').select();

      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }
      if (filters.containsKey('curriculum_id')) {
        query =
            query.eq('curriculum_id', filters['curriculum_id'] as String);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('sort_order').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSubjectById(String id) async {
    try {
      final response =
          await _supabase.from('subjects').select().eq('id', id).single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createSubject(Map<String, dynamic> data) async {
    try {
      final response =
          await _supabase.from('subjects').insert(data).select().single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateSubject(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('subjects')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      await _supabase.from('subjects').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLevelSubjects(
    String educationalLevelId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_level_subjects',
        params: {'p_educational_level_id': educationalLevelId},
      );
      return List<Map<String, dynamic>>.from(response as List);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Topics ────────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getTopics(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('topics').select();

      if (filters.containsKey('subject_id')) {
        query = query.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }
      if (filters.containsKey('curriculum_id')) {
        query =
            query.eq('curriculum_id', filters['curriculum_id'] as String);
      }
      if (filters.containsKey('parent_topic_id')) {
        final parentId = filters['parent_topic_id'];
        if (parentId == null) {
          query = query.filter('parent_topic_id', 'is.null');
        } else {
          query = query.eq('parent_topic_id', parentId as String);
        }
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('sort_order').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getTopicById(String id) async {
    try {
      final response =
          await _supabase.from('topics').select().eq('id', id).single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createTopic(Map<String, dynamic> data) async {
    try {
      final response =
          await _supabase.from('topics').insert(data).select().single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateTopic(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('topics')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteTopic(String id) async {
    try {
      await _supabase.from('topics').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSubtopics(
    String topicId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on subtopics
      final response = await _supabase
          .from('subtopics')
          .select()
          .eq('topic_id', topicId)
          .order('sort_order')
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createSubtopic(Map<String, dynamic> data) async {
    try {
      final response =
          await _supabase.from('subtopics').insert(data).select().single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateSubtopic(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('subtopics')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteSubtopic(String id) async {
    try {
      await _supabase.from('subtopics').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurriculumTree(String subjectId) async {
    try {
      final response = await _supabase.rpc(
        'get_curriculum_tree',
        params: {'p_subject_id': subjectId},
      );
      return List<Map<String, dynamic>>.from(response as List);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Learning Objectives ───────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getLearningObjectives(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('learning_objectives').select();

      if (filters.containsKey('topic_id')) {
        query = query.eq('topic_id', filters['topic_id'] as String);
      }
      if (filters.containsKey('subtopic_id')) {
        final subtopicId = filters['subtopic_id'];
        if (subtopicId == null) {
          query = query.filter('subtopic_id', 'is.null');
        } else {
          query = query.eq('subtopic_id', subtopicId as String);
        }
      }
      if (filters.containsKey('subject_id')) {
        query = query.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('sort_order').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createLearningObjective(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('learning_objectives')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateLearningObjective(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('learning_objectives')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteLearningObjective(String id) async {
    try {
      await _supabase.from('learning_objectives').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Content ───────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getContentItems(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('content_items').select();

      if (filters.containsKey('subject_id')) {
        query = query.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }
      if (filters.containsKey('topic_id')) {
        query = query.eq('topic_id', filters['topic_id'] as String);
      }
      if (filters.containsKey('subtopic_id')) {
        query = query.eq('subtopic_id', filters['subtopic_id'] as String);
      }
      if (filters.containsKey('curriculum_id')) {
        query =
            query.eq('curriculum_id', filters['curriculum_id'] as String);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('content_type')) {
        query =
            query.eq('content_type', filters['content_type'] as String);
      }
      if (filters.containsKey('question_category')) {
        query = query.eq(
          'question_category',
          filters['question_category'] as String,
        );
      }
      if (filters.containsKey('difficulty_level')) {
        query = query.eq(
          'difficulty_level',
          filters['difficulty_level'] as String,
        );
      }
      if (filters.containsKey('bloom_level')) {
        query =
            query.eq('bloom_level', filters['bloom_level'] as String);
      }
      if (filters.containsKey('status')) {
        query = query.eq('status', filters['status'] as String);
      }
      if (filters.containsKey('is_past_question')) {
        query = query.eq(
          'is_past_question',
          filters['is_past_question'] as bool,
        );
      }
      if (filters.containsKey('is_ai_generated')) {
        query = query.eq(
          'is_ai_generated',
          filters['is_ai_generated'] as bool,
        );
      }
      if (filters.containsKey('search')) {
        query = query.ilike('title', '%${filters['search']}%');
      }

      final limit = filters['limit'] as int? ?? 20;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getContentById(String id) async {
    try {
      final response = await _supabase
          .from('content_items')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createContent(Map<String, dynamic> data) async {
    try {
      final response =
          await _supabase.from('content_items').insert(data).select().single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateContent(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('content_items')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteContent(String id) async {
    try {
      await _supabase.from('content_items').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> publishContent(String id) async {
    try {
      final response = await _supabase
          .from('content_items')
          .update({
            'status': 'published',
            'published_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> archiveContent(String id) async {
    try {
      final response = await _supabase
          .from('content_items')
          .update({'status': 'archived'})
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContentVersions(
    String contentItemId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on content_versions
      final response = await _supabase
          .from('content_versions')
          .select()
          .eq('content_item_id', contentItemId)
          .order('version_number', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getContentWithDetails(String id) async {
    try {
      final response = await _supabase.rpc(
        'get_content_with_details',
        params: {'p_content_id': id},
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Reviews ───────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createReview(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('content_reviews')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getContentReviews(
    String contentItemId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on content_reviews
      final response = await _supabase
          .from('content_reviews')
          .select()
          .eq('content_item_id', contentItemId)
          .order('reviewed_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Imports ───────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createImport(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('content_imports')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getImports(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('content_imports').select();

      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('status')) {
        query = query.eq('status', filters['status'] as String);
      }

      final limit = filters['limit'] as int? ?? 20;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getImportById(String id) async {
    try {
      final response = await _supabase
          .from('content_imports')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Collections ───────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getCollections(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('content_collections').select();

      if (filters.containsKey('subject_id')) {
        query = query.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('is_public')) {
        query = query.eq('is_public', filters['is_public'] as bool);
      }

      final limit = filters['limit'] as int? ?? 20;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('sort_order')
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCollectionById(String id) async {
    try {
      final response = await _supabase
          .from('content_collections')
          .select()
          .eq('id', id)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createCollection(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('content_collections')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateCollection(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('content_collections')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> deleteCollection(String id) async {
    try {
      await _supabase.from('content_collections').delete().eq('id', id);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> addCollectionItem(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('content_collection_items')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> removeCollectionItem(String collectionItemId) async {
    try {
      await _supabase
          .from('content_collection_items')
          .delete()
          .eq('id', collectionItemId);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── AI Curriculum ─────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getAiCurriculumConfig(
    Map<String, dynamic> params,
  ) async {
    try {
      var query = _supabase.from('ai_curriculum_configs').select();

      query = query
          .eq('school_id', params['school_id'] as String)
          .eq('subject_id', params['subject_id'] as String)
          .eq(
            'educational_level_id',
            params['educational_level_id'] as String,
          );

      final response = await query.single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> upsertAiCurriculumConfig(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('ai_curriculum_configs')
          .upsert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAiGenerationRules(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('ai_generation_rules').select();

      if (filters.containsKey('educational_level_id')) {
        query = query.eq(
          'educational_level_id',
          filters['educational_level_id'] as String,
        );
      }
      if (filters.containsKey('subject_id')) {
        query = query.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('is_active')) {
        query = query.eq('is_active', filters['is_active'] as bool);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('priority').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createAiGenerationRule(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('ai_generation_rules')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateAiGenerationRule(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('ai_generation_rules')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Answer Repository ─────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getAnswerEntry(String contentItemId) async {
    try {
      final response = await _supabase
          .from('answer_repository_entries')
          .select()
          .eq('content_item_id', contentItemId)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createAnswerEntry(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('answer_repository_entries')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateAnswerEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('answer_repository_entries')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyAnswer(Map<String, dynamic> params) async {
    try {
      final response = await _supabase.rpc(
        'verify_answer_entry',
        params: {
          'p_entry_id': params['entry_id'],
          'p_verified_by': params['verified_by'],
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Stats ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getCcmsStats(Map<String, dynamic> params) async {
    try {
      final response = await _supabase.rpc(
        'get_ccms_stats',
        params: {
          if (params.containsKey('school_id'))
            'p_school_id': params['school_id'],
          if (params.containsKey('educational_level_id'))
            'p_educational_level_id': params['educational_level_id'],
          if (params.containsKey('subject_id'))
            'p_subject_id': params['subject_id'],
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Audit ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> recordAuditEvent(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase.rpc(
        'record_audit_event',
        params: {'p_audit_data': data},
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditTrail(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('audit_entries').select();

      if (filters.containsKey('user_id')) {
        query = query.eq('user_id', filters['user_id'] as String);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('action')) {
        query = query.eq('action', filters['action'] as String);
      }
      if (filters.containsKey('resource_type')) {
        query =
            query.eq('resource_type', filters['resource_type'] as String);
      }
      if (filters.containsKey('resource_id')) {
        query = query.eq('resource_id', filters['resource_id'] as String);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── MFA ───────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getMfaConfig(String userId) async {
    try {
      final response = await _supabase
          .from('mfa_configurations')
          .select()
          .eq('user_id', userId)
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> enableMfa(Map<String, dynamic> params) async {
    try {
      final response = await _supabase
          .from('mfa_configurations')
          .insert({
            'user_id': params['user_id'],
            'mfa_method': params['method'],
            'phone_number_encrypted': params['phone_number'],
            'is_enabled': true,
          })
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> disableMfa(Map<String, dynamic> params) async {
    try {
      await _supabase
          .from('mfa_configurations')
          .update({
            'is_enabled': false,
          })
          .eq('user_id', params['user_id'] as String)
          .eq('is_enabled', true);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<bool> verifyMfa(Map<String, dynamic> params) async {
    try {
      final response = await _supabase.rpc(
        'verify_mfa_challenge',
        params: {
          'p_user_id': params['user_id'],
          'p_verification_code': params['verification_code'],
        },
      );
      return response as bool;
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── API Keys ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('api_keys')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> revokeApiKey(String apiKeyId) async {
    try {
      await _supabase
          .from('api_keys')
          .update({'is_active': false})
          .eq('id', apiKeyId);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getApiKeys(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on api_keys
      final response = await _supabase
          .from('api_keys')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Security ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> recordSecurityEvent(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase.rpc(
        'record_security_event',
        params: {'p_event_data': data},
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSecurityEvents(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('security_events').select();

      if (filters.containsKey('user_id')) {
        query = query.eq('user_id', filters['user_id'] as String);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('severity')) {
        query = query.eq('severity', filters['severity'] as String);
      }
      if (filters.containsKey('is_resolved')) {
        query = query.eq('is_resolved', filters['is_resolved'] as bool);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<bool> checkRateLimit(Map<String, dynamic> params) async {
    try {
      final response = await _supabase.rpc(
        'check_rate_limit',
        params: {
          'p_scope': params['scope'],
          'p_identifier': params['identifier'],
          if (params.containsKey('endpoint_pattern'))
            'p_endpoint_pattern': params['endpoint_pattern'],
        },
      );
      return response as bool;
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Sessions ──────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getUserSessions(
    String userId, {
    int limit = PaginatedQueryMixin.dropdownPageSize,
  }) async {
    try {
      // PERF: Added limit to prevent unbounded query on user_sessions
      final response = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_activity_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> invalidateUserSessions(Map<String, dynamic> params) async {
    try {
      await _supabase.rpc(
        'invalidate_user_session',
        params: {
          'p_user_id': params['user_id'],
          'p_session_id': params['session_id'],
        },
      );
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<void> invalidateAllOtherSessions(Map<String, dynamic> params) async {
    try {
      await _supabase.rpc(
        'invalidate_all_other_sessions',
        params: {
          'p_user_id': params['user_id'],
          'p_current_session_id': params['current_session_id'],
        },
      );
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Monitoring ────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> recordMetric(Map<String, dynamic> data) async {
    try {
      final response = await _supabase.rpc(
        'record_system_metric',
        params: {'p_metric_data': data},
      );
      return Map<String, dynamic>.from(response as Map);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSystemMetrics(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('system_metrics').select();

      if (filters.containsKey('metric_name')) {
        query = query.eq('metric_name', filters['metric_name'] as String);
      }
      if (filters.containsKey('metric_type')) {
        query = query.eq('metric_type', filters['metric_type'] as String);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }

      final limit = filters['limit'] as int? ?? 100;

      final response =
          await query.order('recorded_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlertRules(
    Map<String, dynamic> filters, {
    int limit = PaginatedQueryMixin.defaultPageSize,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('alert_rules').select();

      if (filters.containsKey('is_active')) {
        query = query.eq('is_active', filters['is_active'] as bool);
      }
      if (filters.containsKey('severity')) {
        query = query.eq('severity', filters['severity'] as String);
      }

      // PERF: Added range-based pagination to prevent unbounded query
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createAlertRule(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('alert_rules')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlertIncidents(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('alert_incidents').select();

      if (filters.containsKey('alert_rule_id')) {
        query =
            query.eq('alert_rule_id', filters['alert_rule_id'] as String);
      }
      if (filters.containsKey('status')) {
        query = query.eq('status', filters['status'] as String);
      }
      if (filters.containsKey('severity')) {
        query = query.eq('severity', filters['severity'] as String);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> acknowledgeAlert(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _supabase
          .from('alert_incidents')
          .update({
            'acknowledged_by': params['acknowledged_by'],
            'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
            'status': 'acknowledged',
          })
          .eq('id', params['incident_id'] as String)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> resolveAlert(Map<String, dynamic> params) async {
    try {
      final response = await _supabase
          .from('alert_incidents')
          .update({
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
            'resolution_notes': params['resolution_notes'],
            'status': 'resolved',
          })
          .eq('id', params['incident_id'] as String)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Performance ───────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> recordPerformanceLog(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('performance_logs')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPerformanceLogs(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('performance_logs').select();

      if (filters.containsKey('operation_type')) {
        query =
            query.eq('operation_type', filters['operation_type'] as String);
      }
      if (filters.containsKey('operation_name')) {
        query =
            query.eq('operation_name', filters['operation_name'] as String);
      }
      if (filters.containsKey('is_slow')) {
        query = query.eq('is_slow', filters['is_slow'] as bool);
      }
      if (filters.containsKey('user_id')) {
        query = query.eq('user_id', filters['user_id'] as String);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Errors ────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> reportError(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('error_reports')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getErrorReports(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('error_reports').select();

      if (filters.containsKey('error_type')) {
        query = query.eq('error_type', filters['error_type'] as String);
      }
      if (filters.containsKey('is_resolved')) {
        query = query.eq('is_resolved', filters['is_resolved'] as bool);
      }
      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('last_seen_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> resolveError(Map<String, dynamic> params) async {
    try {
      final response = await _supabase
          .from('error_reports')
          .update({
            'is_resolved': true,
            'resolved_by': params['resolved_by'],
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', params['error_id'] as String)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Deployments ───────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getDeployments(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('deployments').select();

      if (filters.containsKey('environment')) {
        query = query.eq('environment', filters['environment'] as String);
      }
      if (filters.containsKey('status')) {
        query = query.eq('status', filters['status'] as String);
      }

      final limit = filters['limit'] as int? ?? 20;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('started_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createDeployment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('deployments')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateDeploymentStatus(
    Map<String, dynamic> params,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': params['status'],
      };
      if (params.containsKey('notes')) {
        updateData['notes'] = params['notes'];
      }
      if (params['status'] == 'success' || params['status'] == 'failed') {
        updateData['completed_at'] =
            DateTime.now().toUtc().toIso8601String();
      }

      final response = await _supabase
          .from('deployments')
          .update(updateData)
          .eq('id', params['deployment_id'] as String)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  // ─── Testing ───────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> recordTestResult(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('test_results')
          .insert(data)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTestResults(
    Map<String, dynamic> filters,
  ) async {
    try {
      var query = _supabase.from('test_results').select();

      if (filters.containsKey('test_type')) {
        query = query.eq('test_type', filters['test_type'] as String);
      }
      if (filters.containsKey('deployment_id')) {
        query =
            query.eq('deployment_id', filters['deployment_id'] as String);
      }
      if (filters.containsKey('status')) {
        query = query.eq('status', filters['status'] as String);
      }

      final limit = filters['limit'] as int? ?? 50;
      final offset = filters['offset'] as int? ?? 0;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } on sb.PostgrestException catch (e) {
      _handlePostgrestError(e);
    }
  }
}
