import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/paginated_query_mixin.dart';
import '../../../../core/utils/logger.dart';
import '../models/ai_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote AI generator data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions propagate to
/// the repository layer for conversion to domain [Failure] types.
abstract class AiGeneratorRemoteDataSource {
  // ─── Question Generation ──────────────────────────────────────────

  Future<GenerationRequestModel> createGenerationRequest(
    Map<String, dynamic> requestData,
  );
  Future<GenerationRequestModel> updateGenerationRequest(
    String id,
    Map<String, dynamic> data,
  );
  Future<GenerationRequestModel> getGenerationRequest(String id);
  Future<List<GenerationRequestModel>> getGenerationRequests(
    Map<String, dynamic> filters,
  );
  Future<void> cancelGenerationRequest(String id);

  Future<GeneratedQuestionModel> createGeneratedQuestion(
    Map<String, dynamic> questionData,
  );
  Future<List<GeneratedQuestionModel>> createGeneratedQuestions(
    List<Map<String, dynamic>> questionsData,
  );
  Future<GeneratedQuestionModel> updateGeneratedQuestion(
    String id,
    Map<String, dynamic> data,
  );
  Future<GeneratedQuestionModel> getGeneratedQuestion(String id);
  Future<List<GeneratedQuestionModel>> getGeneratedQuestions(
    Map<String, dynamic> filters,
  );
  Future<int> getGeneratedQuestionCount(Map<String, dynamic> filters);

  // ─── Review ───────────────────────────────────────────────────────

  Future<GeneratedQuestionModel> approveQuestion(
    String id, {
    String? reviewNotes,
  });
  Future<GeneratedQuestionModel> rejectQuestion(
    String id,
    String reason,
  );
  Future<GeneratedQuestionModel> requestRevision(
    String id,
    String notes,
  );

  // ─── Question Improvement ─────────────────────────────────────────

  Future<QuestionImprovementModel> createImprovement(
    Map<String, dynamic> improvementData,
  );
  Future<QuestionImprovementModel> updateImprovement(
    String id,
    Map<String, dynamic> data,
  );
  Future<QuestionImprovementModel> getImprovement(String id);
  Future<List<QuestionImprovementModel>> getImprovements(
    String generatedQuestionId,
  );

  // ─── Validation ───────────────────────────────────────────────────

  Future<ValidationResultModel> createValidationResult(
    Map<String, dynamic> resultData,
  );
  Future<List<ValidationResultModel>> createValidationResults(
    List<Map<String, dynamic>> resultsData,
  );
  Future<List<ValidationResultModel>> getValidationResults(
    String generatedQuestionId,
  );
  Future<ValidationResultModel> resolveValidationResult(
    String id,
    String resolvedBy,
  );

  // ─── Document Upload & Processing ─────────────────────────────────

  Future<DocumentUploadModel> createDocumentUpload(
    Map<String, dynamic> documentData,
  );
  Future<DocumentUploadModel> updateDocumentUpload(
    String id,
    Map<String, dynamic> data,
  );
  Future<DocumentUploadModel> getDocumentUpload(String id);
  Future<List<DocumentUploadModel>> getDocumentUploads(
    Map<String, dynamic> filters,
  );

  // ─── Question Bank Integration ────────────────────────────────────

  Future<GeneratedQuestionModel> saveToQuestionBank(
    String generatedQuestionId,
    String questionBankId,
  );

  // ─── Prompt Templates ─────────────────────────────────────────────

  Future<PromptTemplateModel> createPromptTemplate(
    Map<String, dynamic> templateData,
  );
  Future<PromptTemplateModel> updatePromptTemplate(
    String id,
    Map<String, dynamic> data,
  );
  Future<PromptTemplateModel> getPromptTemplate(String id);
  Future<List<PromptTemplateModel>> getPromptTemplates(
    Map<String, dynamic> filters,
  );
  Future<void> incrementTemplateUsage(String id);

  // ─── Provider Configuration ───────────────────────────────────────

  Future<AiProviderConfigModel> createProviderConfig(
    Map<String, dynamic> configData,
  );
  Future<AiProviderConfigModel> updateProviderConfig(
    String id,
    Map<String, dynamic> data,
  );
  Future<AiProviderConfigModel> getProviderConfig(String id);
  Future<List<AiProviderConfigModel>> getProviderConfigs();
  Future<AiApiKeyModel> getApiKey(String providerType, String schoolId);

  // ─── Generation Queue ─────────────────────────────────────────────

  Future<GenerationQueueModel> enqueueGeneration(
    Map<String, dynamic> queueData,
  );
  Future<GenerationQueueModel> updateQueueEntry(
    String id,
    Map<String, dynamic> data,
  );
  Future<GenerationQueueModel> dequeueNextGeneration();
  Future<List<GenerationQueueModel>> getPendingQueueEntries();

  // ─── Usage Statistics ─────────────────────────────────────────────

  Future<AiUsageStatsModel> upsertUsageStats(
    Map<String, dynamic> statsData,
  );
  Future<List<AiUsageStatsModel>> getUsageStats(
    Map<String, dynamic> filters,
  );
  Future<Map<String, dynamic>> getDashboardStats(String? schoolId);

  // ─── Curriculum Mappings ──────────────────────────────────────────

  Future<List<CurriculumMappingModel>> getCurriculumMappings(
    Map<String, dynamic> filters,
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class AiGeneratorRemoteDataSourceImpl implements AiGeneratorRemoteDataSource {
  AiGeneratorRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ──────────────────────────────────────────────────

  static const _generationRequestsTable = 'ai_generation_requests';
  static const _generatedQuestionsTable = 'ai_generated_questions';
  static const _improvementsTable = 'ai_question_improvements';
  static const _validationResultsTable = 'ai_validation_results';
  static const _documentsTable = 'ai_document_uploads';
  static const _promptTemplatesTable = 'ai_prompt_templates';
  static const _providerConfigsTable = 'ai_provider_configs';
  static const _apiKeysTable = 'ai_api_keys';
  static const _queueTable = 'ai_generation_queue';
  static const _usageStatsTable = 'ai_usage_stats';
  static const _curriculumMappingsTable = 'ai_curriculum_mappings';

  // ═══════════════════════════════════════════════════════════════════
  // QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<GenerationRequestModel> createGenerationRequest(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await _supabase
          .from(_generationRequestsTable)
          .insert(requestData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Generation request creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Generation request created: ${response.first['id']}');
      return GenerationRequestModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createGenerationRequest error', error: e);
      throw const ServerException(
        message: 'Failed to create generation request.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GenerationRequestModel> updateGenerationRequest(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_generationRequestsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generation request not found for update.');
      }

      return GenerationRequestModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateGenerationRequest error', error: e);
      throw const ServerException(
        message: 'Failed to update generation request.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GenerationRequestModel> getGenerationRequest(String id) async {
    try {
      final response = await _supabase
          .from(_generationRequestsTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generation request not found.');
      }

      return GenerationRequestModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getGenerationRequest error', error: e);
      throw const ServerException(
        message: 'Failed to get generation request.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<GenerationRequestModel>> getGenerationRequests(
    Map<String, dynamic> filters,
  ) async {
    try {
      // Build filter chain first (on PostgrestFilterBuilder),
      // then apply transforms (order, range) which return PostgrestTransformBuilder.
      var filterQuery = _supabase
          .from(_generationRequestsTable)
          .select();

      // Apply filters on PostgrestFilterBuilder
      if (filters.containsKey('school_id')) {
        filterQuery = filterQuery.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('status')) {
        filterQuery = filterQuery.eq('status', filters['status'] as String);
      }
      if (filters.containsKey('requested_by')) {
        filterQuery = filterQuery.eq('requested_by', filters['requested_by'] as String);
      }

      // Now apply transforms on PostgrestTransformBuilder
      var transformQuery = filterQuery.order('created_at', ascending: false);

      // Pagination
      final page = filters['page'] as int? ?? 1;
      final perPage = filters['per_page'] as int? ?? filters['perPage'] as int? ?? 20;
      final from = (page - 1) * perPage;
      transformQuery = transformQuery.range(from, from + perPage - 1);

      final response = await transformQuery;
      return response
          .map<GenerationRequestModel>(
              (json) => GenerationRequestModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getGenerationRequests error', error: e);
      throw const ServerException(
        message: 'Failed to get generation requests.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> cancelGenerationRequest(String id) async {
    try {
      await _supabase
          .from(_generationRequestsTable)
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      AppLogger.info('Generation request cancelled: $id');
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected cancelGenerationRequest error', error: e);
      throw const ServerException(
        message: 'Failed to cancel generation request.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GeneratedQuestionModel> createGeneratedQuestion(
    Map<String, dynamic> questionData,
  ) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .insert(questionData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Generated question creation returned no data.',
          statusCode: 500,
        );
      }

      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createGeneratedQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to create generated question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<GeneratedQuestionModel>> createGeneratedQuestions(
    List<Map<String, dynamic>> questionsData,
  ) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .insert(questionsData)
          .select();

      return response
          .map<GeneratedQuestionModel>(
              (json) => GeneratedQuestionModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected createGeneratedQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to create generated questions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GeneratedQuestionModel> updateGeneratedQuestion(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_generatedQuestionsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generated question not found for update.');
      }

      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateGeneratedQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to update generated question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GeneratedQuestionModel> getGeneratedQuestion(String id) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generated question not found.');
      }

      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getGeneratedQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to get generated question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<GeneratedQuestionModel>> getGeneratedQuestions(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_generatedQuestionsTable)
          .select();

      if (filters.containsKey('school_id')) {
        filterQuery = filterQuery.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('review_status')) {
        filterQuery = filterQuery.eq('review_status', filters['review_status'] as String);
      }
      if (filters.containsKey('generation_request_id')) {
        filterQuery = filterQuery.eq('generation_request_id',
            filters['generation_request_id'] as String,);
      }

      var transformQuery = filterQuery.order('created_at', ascending: false);

      final page = filters['page'] as int? ?? 1;
      final perPage = filters['per_page'] as int? ?? filters['perPage'] as int? ?? 20;
      final from = (page - 1) * perPage;
      transformQuery = transformQuery.range(from, from + perPage - 1);

      final response = await transformQuery;
      return response
          .map<GeneratedQuestionModel>(
              (json) => GeneratedQuestionModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getGeneratedQuestions error', error: e);
      throw const ServerException(
        message: 'Failed to get generated questions.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getGeneratedQuestionCount(Map<String, dynamic> filters) async {
    try {
      var query = _supabase
          .from(_generatedQuestionsTable)
          .select('id');

      if (filters.containsKey('school_id')) {
        query = query.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('review_status')) {
        query = query.eq('review_status', filters['review_status'] as String);
      }

      final response = await query;
      return response.length;
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getGeneratedQuestionCount error', error: e);
      throw const ServerException(
        message: 'Failed to count generated questions.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVIEW
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<GeneratedQuestionModel> approveQuestion(
    String id, {
    String? reviewNotes,
  }) async {
    try {
      final data = <String, dynamic>{
        'review_status': 'approved',
        'is_approved': true,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (reviewNotes != null) {
        data['review_notes'] = reviewNotes;
      }

      final response = await _supabase
          .from(_generatedQuestionsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generated question not found for approval.');
      }

      AppLogger.info('Question approved: $id');
      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected approveQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to approve question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GeneratedQuestionModel> rejectQuestion(
    String id,
    String reason,
  ) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .update({
            'review_status': 'rejected',
            'is_approved': false,
            'review_notes': reason,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Generated question not found for rejection.');
      }

      AppLogger.info('Question rejected: $id');
      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected rejectQuestion error', error: e);
      throw const ServerException(
        message: 'Failed to reject question.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GeneratedQuestionModel> requestRevision(
    String id,
    String notes,
  ) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .update({
            'review_status': 'needs_revision',
            'review_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 
            'Generated question not found for revision request.',);
      }

      AppLogger.info('Question revision requested: $id');
      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected requestRevision error', error: e);
      throw const ServerException(
        message: 'Failed to request revision.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUESTION IMPROVEMENT
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<QuestionImprovementModel> createImprovement(
    Map<String, dynamic> improvementData,
  ) async {
    try {
      final response = await _supabase
          .from(_improvementsTable)
          .insert(improvementData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Improvement creation returned no data.',
          statusCode: 500,
        );
      }

      return QuestionImprovementModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createImprovement error', error: e);
      throw const ServerException(
        message: 'Failed to create improvement.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionImprovementModel> updateImprovement(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(_improvementsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Improvement not found for update.');
      }

      return QuestionImprovementModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateImprovement error', error: e);
      throw const ServerException(
        message: 'Failed to update improvement.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<QuestionImprovementModel> getImprovement(String id) async {
    try {
      final response = await _supabase
          .from(_improvementsTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Improvement not found.');
      }

      return QuestionImprovementModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getImprovement error', error: e);
      throw const ServerException(
        message: 'Failed to get improvement.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<QuestionImprovementModel>> getImprovements(
    String generatedQuestionId,
  ) async {
    try {
      // PERF: Added limit to prevent unbounded query on improvements
      final response = await _supabase
          .from(_improvementsTable)
          .select()
          .eq('generated_question_id', generatedQuestionId)
          .order('created_at', ascending: false)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response
          .map<QuestionImprovementModel>(
              (json) => QuestionImprovementModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getImprovements error', error: e);
      throw const ServerException(
        message: 'Failed to get improvements.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ValidationResultModel> createValidationResult(
    Map<String, dynamic> resultData,
  ) async {
    try {
      final response = await _supabase
          .from(_validationResultsTable)
          .insert(resultData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Validation result creation returned no data.',
          statusCode: 500,
        );
      }

      return ValidationResultModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createValidationResult error', error: e);
      throw const ServerException(
        message: 'Failed to create validation result.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ValidationResultModel>> createValidationResults(
    List<Map<String, dynamic>> resultsData,
  ) async {
    try {
      final response = await _supabase
          .from(_validationResultsTable)
          .insert(resultsData)
          .select();

      return response
          .map<ValidationResultModel>(
              (json) => ValidationResultModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected createValidationResults error', error: e);
      throw const ServerException(
        message: 'Failed to create validation results.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ValidationResultModel>> getValidationResults(
    String generatedQuestionId,
  ) async {
    try {
      final response = await _supabase
          .from(_validationResultsTable)
          .select()
          .eq('generated_question_id', generatedQuestionId)
          .order('created_at', ascending: false);

      return response
          .map<ValidationResultModel>(
              (json) => ValidationResultModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getValidationResults error', error: e);
      throw const ServerException(
        message: 'Failed to get validation results.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ValidationResultModel> resolveValidationResult(
    String id,
    String resolvedBy,
  ) async {
    try {
      final response = await _supabase
          .from(_validationResultsTable)
          .update({
            'is_resolved': true,
            'resolved_by': resolvedBy,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Validation result not found.');
      }

      return ValidationResultModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected resolveValidationResult error', error: e);
      throw const ServerException(
        message: 'Failed to resolve validation result.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DOCUMENT UPLOAD & PROCESSING
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<DocumentUploadModel> createDocumentUpload(
    Map<String, dynamic> documentData,
  ) async {
    try {
      final response = await _supabase
          .from(_documentsTable)
          .insert(documentData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Document upload creation returned no data.',
          statusCode: 500,
        );
      }

      return DocumentUploadModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createDocumentUpload error', error: e);
      throw const ServerException(
        message: 'Failed to create document upload.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DocumentUploadModel> updateDocumentUpload(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(_documentsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Document upload not found for update.');
      }

      return DocumentUploadModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateDocumentUpload error', error: e);
      throw const ServerException(
        message: 'Failed to update document upload.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<DocumentUploadModel> getDocumentUpload(String id) async {
    try {
      final response = await _supabase
          .from(_documentsTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Document upload not found.');
      }

      return DocumentUploadModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getDocumentUpload error', error: e);
      throw const ServerException(
        message: 'Failed to get document upload.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<DocumentUploadModel>> getDocumentUploads(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_documentsTable)
          .select();

      if (filters.containsKey('school_id')) {
        filterQuery = filterQuery.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('uploaded_by')) {
        filterQuery = filterQuery.eq('uploaded_by', filters['uploaded_by'] as String);
      }

      var transformQuery = filterQuery.order('created_at', ascending: false);

      // PERF: Added default pagination to prevent unbounded query
      final page = filters['page'] as int? ?? 1;
      final perPage = filters['per_page'] as int? ?? filters['perPage'] as int? ?? PaginatedQueryMixin.defaultPageSize;
      final from = (page - 1) * perPage;
      transformQuery = transformQuery.range(from, from + perPage - 1);

      final response = await transformQuery;
      return response
          .map<DocumentUploadModel>(
              (json) => DocumentUploadModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getDocumentUploads error', error: e);
      throw const ServerException(
        message: 'Failed to get document uploads.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUESTION BANK INTEGRATION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<GeneratedQuestionModel> saveToQuestionBank(
    String generatedQuestionId,
    String questionBankId,
  ) async {
    try {
      final response = await _supabase
          .from(_generatedQuestionsTable)
          .update({
            'question_bank_id': questionBankId,
            'review_status': 'approved',
            'is_approved': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', generatedQuestionId)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 
            'Generated question not found for save-to-bank.',);
      }

      AppLogger.info(
          'Question saved to bank: $generatedQuestionId -> $questionBankId',);
      return GeneratedQuestionModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected saveToQuestionBank error', error: e);
      throw const ServerException(
        message: 'Failed to save question to bank.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROMPT TEMPLATES
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<PromptTemplateModel> createPromptTemplate(
    Map<String, dynamic> templateData,
  ) async {
    try {
      final response = await _supabase
          .from(_promptTemplatesTable)
          .insert(templateData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Prompt template creation returned no data.',
          statusCode: 500,
        );
      }

      AppLogger.info('Prompt template created: ${response.first['id']}');
      return PromptTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createPromptTemplate error', error: e);
      throw const ServerException(
        message: 'Failed to create prompt template.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PromptTemplateModel> updatePromptTemplate(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_promptTemplatesTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Prompt template not found for update.');
      }

      return PromptTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updatePromptTemplate error', error: e);
      throw const ServerException(
        message: 'Failed to update prompt template.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PromptTemplateModel> getPromptTemplate(String id) async {
    try {
      final response = await _supabase
          .from(_promptTemplatesTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Prompt template not found.');
      }

      return PromptTemplateModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getPromptTemplate error', error: e);
      throw const ServerException(
        message: 'Failed to get prompt template.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PromptTemplateModel>> getPromptTemplates(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_promptTemplatesTable)
          .select()
          .eq('is_active', true);

      if (filters.containsKey('prompt_type')) {
        filterQuery = filterQuery.eq('prompt_type', filters['prompt_type'] as String);
      }
      if (filters.containsKey('subject_id')) {
        filterQuery = filterQuery.eq('subject_id', filters['subject_id'] as String);
      }
      if (filters.containsKey('curriculum')) {
        filterQuery = filterQuery.eq('curriculum', filters['curriculum'] as String);
      }

      // PERF: Added limit to prevent unbounded query on prompt_templates
      final response = await filterQuery
          .order('is_default', ascending: false)
          .order('quality_score', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map<PromptTemplateModel>(
              (json) => PromptTemplateModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPromptTemplates error', error: e);
      throw const ServerException(
        message: 'Failed to get prompt templates.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> incrementTemplateUsage(String id) async {
    try {
      // Use an RPC call to atomically increment the usage_count
      await _supabase.rpc('increment_template_usage', params: {
        'template_id': id,
      },);
    } on sb.PostgrestException catch (e) {
      // If the RPC doesn't exist, fall back to a manual update
      if (e.code == '42883') {
        // undefined function
        try {
          final current = await _supabase
              .from(_promptTemplatesTable)
              .select('usage_count')
              .eq('id', id)
              .limit(1);

          if (current.isNotEmpty) {
            final count = current.first['usage_count'] as int? ?? 0;
            await _supabase
                .from(_promptTemplatesTable)
                .update({
                  'usage_count': count + 1,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', id);
          }
        } catch (_) {
          // Silently fail for usage increment
        }
      }
    } catch (e) {
      // Silently fail for usage increment - not critical
      AppLogger.debug('Failed to increment template usage: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROVIDER CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AiProviderConfigModel> createProviderConfig(
    Map<String, dynamic> configData,
  ) async {
    try {
      final response = await _supabase
          .from(_providerConfigsTable)
          .insert(configData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Provider config creation returned no data.',
          statusCode: 500,
        );
      }

      return AiProviderConfigModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected createProviderConfig error', error: e);
      throw const ServerException(
        message: 'Failed to create provider config.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiProviderConfigModel> updateProviderConfig(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_providerConfigsTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Provider config not found for update.');
      }

      return AiProviderConfigModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateProviderConfig error', error: e);
      throw const ServerException(
        message: 'Failed to update provider config.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiProviderConfigModel> getProviderConfig(String id) async {
    try {
      final response = await _supabase
          .from(_providerConfigsTable)
          .select()
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Provider config not found.');
      }

      return AiProviderConfigModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getProviderConfig error', error: e);
      throw const ServerException(
        message: 'Failed to get provider config.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AiProviderConfigModel>> getProviderConfigs() async {
    try {
      // PERF: Added limit to prevent unbounded query on provider_configs
      final response = await _supabase
          .from(_providerConfigsTable)
          .select()
          .order('provider', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);

      return response
          .map<AiProviderConfigModel>(
              (json) => AiProviderConfigModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getProviderConfigs error', error: e);
      throw const ServerException(
        message: 'Failed to get provider configs.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<AiApiKeyModel> getApiKey(
    String providerType,
    String schoolId,
  ) async {
    try {
      final response = await _supabase
          .from(_apiKeysTable)
          .select()
          .eq('provider', providerType)
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Active API key not found for provider.');
      }

      return AiApiKeyModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected getApiKey error', error: e);
      throw const ServerException(
        message: 'Failed to get API key.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GENERATION QUEUE
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<GenerationQueueModel> enqueueGeneration(
    Map<String, dynamic> queueData,
  ) async {
    try {
      final response = await _supabase
          .from(_queueTable)
          .insert(queueData)
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Queue entry creation returned no data.',
          statusCode: 500,
        );
      }

      return GenerationQueueModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected enqueueGeneration error', error: e);
      throw const ServerException(
        message: 'Failed to enqueue generation.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GenerationQueueModel> updateQueueEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_queueTable)
          .update(data)
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        throw const NotFoundException(message: 'Queue entry not found for update.');
      }

      return GenerationQueueModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected updateQueueEntry error', error: e);
      throw const ServerException(
        message: 'Failed to update queue entry.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<GenerationQueueModel> dequeueNextGeneration() async {
    try {
      // Get the highest priority, oldest pending entry
      final response = await _supabase
          .from(_queueTable)
          .select()
          .eq('status', 'pending')
          .order('priority', ascending: false)
          .order('created_at', ascending: true)
          .limit(1);

      if (response.isEmpty) {
        throw const NotFoundException(message: 'No pending generation in queue.');
      }

      final entry = response.first;
      final id = entry['id'] as String;

      // Mark as processing
      final updated = await _supabase
          .from(_queueTable)
          .update({
            'status': 'processing',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select();

      return GenerationQueueModel.fromJson(
          updated.isNotEmpty ? updated.first : entry,);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected dequeueNextGeneration error', error: e);
      throw const ServerException(
        message: 'Failed to dequeue generation.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<GenerationQueueModel>> getPendingQueueEntries() async {
    try {
      final response = await _supabase
          .from(_queueTable)
          .select()
          .eq('status', 'pending')
          .order('priority', ascending: false)
          // PERF: Added limit to prevent unbounded query on generation_queue
          .order('created_at', ascending: true)
          .limit(PaginatedQueryMixin.defaultPageSize);

      return response
          .map<GenerationQueueModel>(
              (json) => GenerationQueueModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getPendingQueueEntries error', error: e);
      throw const ServerException(
        message: 'Failed to get pending queue entries.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // USAGE STATISTICS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<AiUsageStatsModel> upsertUsageStats(
    Map<String, dynamic> statsData,
  ) async {
    try {
      final response = await _supabase
          .from(_usageStatsTable)
          .upsert(statsData, onConflict: 'school_id,provider,date')
          .select();

      if (response.isEmpty) {
        throw const ServerException(
          message: 'Usage stats upsert returned no data.',
          statusCode: 500,
        );
      }

      return AiUsageStatsModel.fromJson(response.first);
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected upsertUsageStats error', error: e);
      throw const ServerException(
        message: 'Failed to upsert usage stats.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<AiUsageStatsModel>> getUsageStats(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_usageStatsTable)
          .select();

      if (filters.containsKey('school_id')) {
        filterQuery = filterQuery.eq('school_id', filters['school_id'] as String);
      }
      if (filters.containsKey('provider')) {
        filterQuery = filterQuery.eq('provider', filters['provider'] as String);
      }
      if (filters.containsKey('start_date')) {
        filterQuery = filterQuery.gte('date', filters['start_date'] as String);
      }
      if (filters.containsKey('end_date')) {
        filterQuery = filterQuery.lte('date', filters['end_date'] as String);
      }

      // PERF: Added limit to prevent unbounded query on ai_usage_stats
      final response = await filterQuery
          .order('date', ascending: false)
          .limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map<AiUsageStatsModel>(
              (json) => AiUsageStatsModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getUsageStats error', error: e);
      throw const ServerException(
        message: 'Failed to get usage stats.',
        statusCode: 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats(String? schoolId) async {
    try {
      // Use an RPC call if available, otherwise aggregate manually
      try {
        final response = await _supabase.rpc(
          'get_ai_dashboard_stats',
          params: schoolId != null ? {'p_school_id': schoolId} : {},
        );
        return response as Map<String, dynamic>;
      } on sb.PostgrestException catch (e) {
        if (e.code != '42883') rethrow; // not undefined function

        // Fallback: manually aggregate stats
        final questionsQuery = _supabase
            .from(_generatedQuestionsTable)
            .select('review_status, question_type, difficulty, bloom_level, '
                'confidence_score, school_id');

        var filteredQuery = questionsQuery;
        if (schoolId != null) {
          filteredQuery = filteredQuery.eq('school_id', schoolId);
        }

        final questions = await filteredQuery;

        final int totalGenerated = questions.length;
        int totalApproved = 0;
        int totalRejected = 0;
        int pendingReview = 0;
        final questionsByType = <String, int>{};
        final questionsByDifficulty = <String, int>{};
        final questionsByBloomLevel = <String, int>{};
        double totalConfidence = 0;
        int confidenceCount = 0;

        for (final q in questions) {
          final status = q['review_status'] as String? ?? 'pending';
          switch (status) {
            case 'approved':
              totalApproved++;
              break;
            case 'rejected':
              totalRejected++;
              break;
            default:
              pendingReview++;
          }

          final type = q['question_type'] as String? ?? 'unknown';
          questionsByType[type] = (questionsByType[type] ?? 0) + 1;

          final diff = q['difficulty'] as String? ?? 'unknown';
          questionsByDifficulty[diff] =
              (questionsByDifficulty[diff] ?? 0) + 1;

          final bloom = q['bloom_level'] as String?;
          if (bloom != null) {
            questionsByBloomLevel[bloom] =
                (questionsByBloomLevel[bloom] ?? 0) + 1;
          }

          final conf = q['confidence_score'] as num?;
          if (conf != null) {
            totalConfidence += conf.toDouble();
            confidenceCount++;
          }
        }

        // Get cost info from usage stats
        var usageQuery = _supabase
            .from(_usageStatsTable)
            .select('total_cost, total_input_tokens, total_output_tokens, provider');
        if (schoolId != null) {
          usageQuery = usageQuery.eq('school_id', schoolId);
        }

        final usage = await usageQuery;
        double totalCost = 0;
        int totalTokensUsed = 0;
        final costByProvider = <String, double>{};

        for (final u in usage) {
          final cost = (u['total_cost'] as num?)?.toDouble() ?? 0;
          totalCost += cost;
          totalTokensUsed +=
              (u['total_input_tokens'] as int? ?? 0) +
                  (u['total_output_tokens'] as int? ?? 0);
          final prov = u['provider'] as String? ?? 'unknown';
          costByProvider[prov] = (costByProvider[prov] ?? 0) + cost;
        }

        return {
          'total_generated': totalGenerated,
          'total_approved': totalApproved,
          'total_rejected': totalRejected,
          'pending_review': pendingReview,
          'total_cost': totalCost,
          'total_tokens_used': totalTokensUsed,
          'questions_by_type': questionsByType,
          'questions_by_difficulty': questionsByDifficulty,
          'questions_by_bloom_level': questionsByBloomLevel,
          'avg_confidence_score':
              confidenceCount > 0 ? totalConfidence / confidenceCount : null,
          'avg_generation_time_ms': null,
          'recent_generations': [],
          'cost_by_provider': costByProvider,
          'daily_usage': [],
        };
      }
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getDashboardStats error', error: e);
      throw const ServerException(
        message: 'Failed to get dashboard stats.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // CURRICULUM MAPPINGS
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<CurriculumMappingModel>> getCurriculumMappings(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_curriculumMappingsTable)
          .select()
          .eq('is_active', true);

      if (filters.containsKey('curriculum')) {
        filterQuery = filterQuery.eq('curriculum', filters['curriculum'] as String);
      }
      if (filters.containsKey('subject_id')) {
        filterQuery = filterQuery.eq('subject_id', filters['subject_id'] as String);
      }

      // PERF: Added limit to prevent unbounded query on curriculum_mappings
      final response = await filterQuery
          .order('curriculum', ascending: true)
          .limit(PaginatedQueryMixin.dropdownPageSize);
      return response
          .map<CurriculumMappingModel>(
              (json) => CurriculumMappingModel.fromJson(json),)
          .toList();
    } on sb.PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      AppLogger.error('Unexpected getCurriculumMappings error', error: e);
      throw const ServerException(
        message: 'Failed to get curriculum mappings.',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ERROR MAPPING
  // ═══════════════════════════════════════════════════════════════════

  /// Maps a Supabase PostgrestException to a domain-appropriate exception.
  ServerException _mapPostgrestException(sb.PostgrestException e) {
    AppLogger.error('Supabase error: ${e.message}', error: e);

    switch (e.code) {
      case '23505':
        return ServerException(
          message: 'A record with this data already exists.',
          statusCode: 409,
          data: e.details,
        );
      case '23503':
        return ServerException(
          message: 'Referenced record not found.',
          statusCode: 400,
          data: e.details,
        );
      case '42501':
      case 'PGRST301':
        return ServerException(
          message: 'Insufficient permissions.',
          statusCode: 403,
          data: e.details,
        );
      case 'PGRST116':
        return ServerException(
          message: 'Resource not found.',
          statusCode: 404,
          data: e.details,
        );
      default:
        return ServerException(
          message: e.message ?? 'An unexpected database error occurred.',
          statusCode: int.tryParse(e.code ?? '') ?? 500,
          data: e.details,
        );
    }
  }
}
