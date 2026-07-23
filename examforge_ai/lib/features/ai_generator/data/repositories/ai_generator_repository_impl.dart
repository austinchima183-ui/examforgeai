import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../ai_generator/domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_generator_repository.dart';
import '../datasources/ai_generator_remote_datasource.dart';
import '../models/ai_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI GENERATOR REPOSITORY IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

/// Concrete implementation of [AiGeneratorRepository] that delegates
/// all operations to [AiGeneratorRemoteDataSource].
///
/// Responsibilities:
/// - Converts domain entities to/from data models
/// - Catches data-layer exceptions and converts them to domain [Failure] types
/// - Returns [Result] to force callers to handle both success and failure
class AiGeneratorRepositoryImpl implements AiGeneratorRepository {
  AiGeneratorRepositoryImpl({
    required AiGeneratorRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AiGeneratorRemoteDataSource _remoteDataSource;

  // ═══════════════════════════════════════════════════════════════════════
  // QUESTION GENERATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<GeneratedQuestionEntity>>> generateQuestions(
    GenerationInputEntity input,
  ) async {
    try {
      // Create the generation request
      final inputModel = GenerationInputModel.fromEntity(input);
      final requestData = {
        'school_id': '', // Will be set by the caller
        'requested_by': '', // Will be set by the caller
        'provider': input.provider?.value ?? 'openai',
        'model_name': input.provider?.defaultModel ?? 'gpt-4o',
        'prompt_template_id': input.promptTemplateId,
        'generation_type': 'question_generation',
        'status': 'pending',
        'input_params': inputModel.toJson(),
        'system_prompt': '',
        'user_prompt': '',
      };

      final requestModel =
          await _remoteDataSource.createGenerationRequest(requestData);

      // Update with processing status
      await _remoteDataSource.updateGenerationRequest(
        requestModel.id,
        {'status': 'processing', 'started_at': DateTime.now().toIso8601String()},
      );

      // Fetch prompt templates for generation
      final templatesData =
          await _remoteDataSource.getPromptTemplates({
        'prompt_type': 'question_generation',
        if (input.subjectId.isNotEmpty) 'subject_id': input.subjectId,
      });

      // Note: The actual AI generation happens in the AiService layer.
      // This repository method creates the request and returns the
      // generated questions after the AI service processes them.
      // For now, we return the generated questions associated with
      // the request after marking it as completed.

      final questions = await _remoteDataSource.getGeneratedQuestions({
        'generation_request_id': requestModel.id,
      });

      // Update request as completed
      await _remoteDataSource.updateGenerationRequest(
        requestModel.id,
        {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      return Success(questions.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected generateQuestions error', error: e);
      return const FailureResult(Failure.server(
        message: 'An unexpected error occurred during generation.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<List<GeneratedQuestionEntity>>> getGeneratedQuestions({
    String? schoolId,
    ReviewStatus? reviewStatus,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (schoolId != null) filters['school_id'] = schoolId;
      if (reviewStatus != null) filters['review_status'] = reviewStatus.value;

      final models = await _remoteDataSource.getGeneratedQuestions(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NetworkException catch (e) {
      return FailureResult(Failure.network(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getGeneratedQuestions error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve generated questions.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<GeneratedQuestionEntity>> getGeneratedQuestion(
    String id,
  ) async {
    try {
      final model = await _remoteDataSource.getGeneratedQuestion(id);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getGeneratedQuestion error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve generated question.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REVIEW
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<GeneratedQuestionEntity>> approveQuestion(
    String id, {
    String? reviewNotes,
  }) async {
    try {
      final model = await _remoteDataSource.approveQuestion(
        id,
        reviewNotes: reviewNotes,
      );
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected approveQuestion error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to approve question.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<GeneratedQuestionEntity>> rejectQuestion(
    String id,
    String reason,
  ) async {
    try {
      final model = await _remoteDataSource.rejectQuestion(id, reason);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected rejectQuestion error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to reject question.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<GeneratedQuestionEntity>> requestRevision(
    String id,
    String notes,
  ) async {
    try {
      final model = await _remoteDataSource.requestRevision(id, notes);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected requestRevision error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to request revision.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUESTION IMPROVEMENT
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<QuestionImprovementEntity>> improveQuestion(
    String id,
    String improvementType, {
    String? customInstructions,
  }) async {
    try {
      // Get the original question
      final questionModel = await _remoteDataSource.getGeneratedQuestion(id);
      final question = questionModel.toEntity();

      // Create improvement record
      final improvementData = {
        'generated_question_id': id,
        'improvement_type': improvementType,
        'provider': 'openai', // Default provider
        'original_content': question.content,
        'improved_content': question.content, // Will be updated after AI processing
        'original_answer_options': question.answerOptions.isNotEmpty
            ? question.answerOptions
            : null,
        'custom_instructions': customInstructions,
      };

      final model =
          await _remoteDataSource.createImprovement(improvementData);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected improveQuestion error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to improve question.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<GeneratedQuestionEntity>> acceptImprovement(
    String improvementId,
  ) async {
    try {
      // Get the improvement
      final improvementModel =
          await _remoteDataSource.getImprovement(improvementId);
      final improvement = improvementModel.toEntity();

      // Mark improvement as accepted
      await _remoteDataSource.updateImprovement(
        improvementId,
        {'is_accepted': true},
      );

      // Update the generated question with improved content
      final updateData = <String, dynamic>{
        'content': improvement.improvedContent,
        'is_edited': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (improvement.improvedAnswerOptions != null) {
        updateData['answer_options'] = improvement.improvedAnswerOptions;
      }

      final updatedQuestion = await _remoteDataSource.updateGeneratedQuestion(
        improvement.generatedQuestionId,
        updateData,
      );

      return Success(updatedQuestion.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected acceptImprovement error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to accept improvement.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<ValidationResultEntity>>> validateQuestion(
    String id,
  ) async {
    try {
      // Get existing validation results
      final models =
          await _remoteDataSource.getValidationResults(id);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected validateQuestion error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to validate question.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT UPLOAD & PROCESSING
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<DocumentUploadEntity>> uploadDocument(
    DocumentUploadEntity document,
  ) async {
    try {
      final model = DocumentUploadModel.fromEntity(document);
      final created = await _remoteDataSource.createDocumentUpload(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected uploadDocument error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to upload document.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<DocumentUploadEntity>> processDocument(
    String documentId,
  ) async {
    try {
      // Update status to processing
      final updated = await _remoteDataSource.updateDocumentUpload(
        documentId,
        {
          'status': 'processing',
        },
      );

      // The actual AI processing happens in the AiService layer.
      // Here we just update the status.

      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected processDocument error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to process document.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUESTION BANK INTEGRATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<String>> saveToQuestionBank(
    String generatedQuestionId,
  ) async {
    try {
      // Generate a new question bank ID (would be created in the
      // question_bank table via the question bank repository)
      final questionBankId = 'qb_${DateTime.now().millisecondsSinceEpoch}';

      final updated = await _remoteDataSource.saveToQuestionBank(
        generatedQuestionId,
        questionBankId,
      );

      return Success(updated.questionBankId ?? questionBankId);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected saveToQuestionBank error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to save question to bank.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROMPT TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<PromptTemplateEntity>>> getPromptTemplates({
    PromptType? type,
    String? subjectId,
    String? curriculum,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (type != null) filters['prompt_type'] = type.value;
      if (subjectId != null) filters['subject_id'] = subjectId;
      if (curriculum != null) filters['curriculum'] = curriculum;

      final models = await _remoteDataSource.getPromptTemplates(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getPromptTemplates error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve prompt templates.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<PromptTemplateEntity>> getPromptTemplate(String id) async {
    try {
      final model = await _remoteDataSource.getPromptTemplate(id);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getPromptTemplate error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve prompt template.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<PromptTemplateEntity>> createPromptTemplate(
    PromptTemplateEntity template,
  ) async {
    try {
      final model = PromptTemplateModel.fromEntity(template);
      final created =
          await _remoteDataSource.createPromptTemplate(model.toJson());
      return Success(created.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected createPromptTemplate error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to create prompt template.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<PromptTemplateEntity>> updatePromptTemplate(
    PromptTemplateEntity template,
  ) async {
    try {
      final model = PromptTemplateModel.fromEntity(template);
      final updated =
          await _remoteDataSource.updatePromptTemplate(
        template.id,
        model.toJson(),
      );
      return Success(updated.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected updatePromptTemplate error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to update prompt template.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROVIDER CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AiProviderConfigEntity>>> getProviderConfigs() async {
    try {
      final models = await _remoteDataSource.getProviderConfigs();
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getProviderConfigs error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve provider configs.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<AiProviderConfigEntity>> getProviderConfig(String id) async {
    try {
      final model = await _remoteDataSource.getProviderConfig(id);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getProviderConfig error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve provider config.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATION HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<GenerationRequestEntity>>> getGenerationHistory({
    String? schoolId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (schoolId != null) filters['school_id'] = schoolId;

      final models =
          await _remoteDataSource.getGenerationRequests(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getGenerationHistory error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve generation history.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<GenerationRequestEntity>> getGenerationRequest(
    String id,
  ) async {
    try {
      final model = await _remoteDataSource.getGenerationRequest(id);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected getGenerationRequest error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve generation request.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USAGE STATISTICS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<AiUsageStatsEntity>>> getUsageStats({
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (schoolId != null) filters['school_id'] = schoolId;
      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String().substring(0, 10);
      }
      if (endDate != null) {
        filters['end_date'] = endDate.toIso8601String().substring(0, 10);
      }

      final models = await _remoteDataSource.getUsageStats(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getUsageStats error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve usage stats.',
        statusCode: 500,
      ),);
    }
  }

  @override
  Future<Result<AiDashboardStatsEntity>> getDashboardStats({
    String? schoolId,
  }) async {
    try {
      final statsMap =
          await _remoteDataSource.getDashboardStats(schoolId);
      final model = AiDashboardStatsModel.fromJson(statsMap);
      return Success(model.toEntity());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getDashboardStats error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve dashboard stats.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CURRICULUM MAPPINGS
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<CurriculumMappingEntity>>> getCurriculumMappings({
    CurriculumType? curriculum,
    String? subjectId,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (curriculum != null) filters['curriculum'] = curriculum.value;
      if (subjectId != null) filters['subject_id'] = subjectId;

      final models =
          await _remoteDataSource.getCurriculumMappings(filters);
      return Success(models.map((m) => m.toEntity()).toList());
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } catch (e) {
      AppLogger.error('Unexpected getCurriculumMappings error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to retrieve curriculum mappings.',
        statusCode: 500,
      ),);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATION CONTROL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> cancelGeneration(String requestId) async {
    try {
      await _remoteDataSource.cancelGenerationRequest(requestId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(Failure.auth(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return FailureResult(Failure.server(
        message: e.message,
        statusCode: e.statusCode,
        data: e.data,
      ),);
    } on NotFoundException catch (e) {
      return FailureResult(Failure.notFound(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected cancelGeneration error', error: e);
      return const FailureResult(Failure.server(
        message: 'Failed to cancel generation.',
        statusCode: 500,
      ),);
    }
  }
}
