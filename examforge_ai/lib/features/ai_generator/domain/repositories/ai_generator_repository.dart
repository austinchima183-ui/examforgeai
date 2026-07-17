import '../../../../core/utils/result.dart';
import 'entities/ai_entities.dart';

/// Abstract contract for all AI generator operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
abstract class AiGeneratorRepository {
  // ─── Question Generation ────────────────────────────────────────────

  /// Generates questions based on the teacher's [input] parameters.
  ///
  /// Returns the list of generated questions with AI-provided content,
  /// answer options, and metadata.
  Future<Result<List<GeneratedQuestionEntity>>> generateQuestions(
    GenerationInputEntity input,
  );

  /// Retrieves generated questions with optional filters.
  ///
  /// [schoolId] scopes results to a specific school.
  /// [reviewStatus] filters by the review status of the questions.
  /// [page] and [perPage] control pagination.
  Future<Result<List<GeneratedQuestionEntity>>> getGeneratedQuestions({
    String? schoolId,
    ReviewStatus? reviewStatus,
    int page = 1,
    int perPage = 20,
  });

  /// Retrieves a single generated question by [id].
  Future<Result<GeneratedQuestionEntity>> getGeneratedQuestion(String id);

  // ─── Review ─────────────────────────────────────────────────────────

  /// Approves a generated question, marking it as ready for the
  /// question bank. Optionally stores [reviewNotes].
  Future<Result<GeneratedQuestionEntity>> approveQuestion(
    String id, {
    String? reviewNotes,
  });

  /// Rejects a generated question with the given [reason].
  Future<Result<GeneratedQuestionEntity>> rejectQuestion(
    String id,
    String reason,
  );

  /// Marks a generated question as needing revision with the
  /// given [notes].
  Future<Result<GeneratedQuestionEntity>> requestRevision(
    String id,
    String notes,
  );

  // ─── Question Improvement ───────────────────────────────────────────

  /// Submits a generated question for AI-powered improvement.
  ///
  /// [improvementType] describes the kind of improvement requested
  /// (e.g., "clarity", "distractors", "difficulty").
  /// [customInstructions] provides additional guidance for the AI.
  Future<Result<QuestionImprovementEntity>> improveQuestion(
    String id,
    String improvementType, {
    String? customInstructions,
  });

  /// Accepts an improvement suggestion, applying it to the generated
  /// question.
  Future<Result<GeneratedQuestionEntity>> acceptImprovement(
    String improvementId,
  );

  // ─── Validation ─────────────────────────────────────────────────────

  /// Validates a generated question for quality, correctness, and
  /// curriculum alignment.
  ///
  /// Returns a list of validation results with varying severity levels.
  Future<Result<List<ValidationResultEntity>>> validateQuestion(String id);

  // ─── Document Upload & Processing ───────────────────────────────────

  /// Uploads a document for AI extraction and question generation.
  Future<Result<DocumentUploadEntity>> uploadDocument(
    DocumentUploadEntity document,
  );

  /// Processes an uploaded document to extract text, identify topics,
  /// and suggest learning objectives.
  Future<Result<DocumentUploadEntity>> processDocument(String documentId);

  // ─── Question Bank Integration ──────────────────────────────────────

  /// Saves a generated question to the Question Bank module.
  ///
  /// Returns the question bank ID of the newly created question.
  Future<Result<String>> saveToQuestionBank(String generatedQuestionId);

  // ─── Prompt Templates ───────────────────────────────────────────────

  /// Retrieves prompt templates with optional filters.
  Future<Result<List<PromptTemplateEntity>>> getPromptTemplates({
    PromptType? type,
    String? subjectId,
    String? curriculum,
  });

  /// Retrieves a single prompt template by [id].
  Future<Result<PromptTemplateEntity>> getPromptTemplate(String id);

  /// Creates a new prompt template.
  Future<Result<PromptTemplateEntity>> createPromptTemplate(
    PromptTemplateEntity template,
  );

  /// Updates an existing prompt template.
  Future<Result<PromptTemplateEntity>> updatePromptTemplate(
    PromptTemplateEntity template,
  );

  // ─── Provider Configuration ─────────────────────────────────────────

  /// Retrieves all AI provider configurations.
  Future<Result<List<AiProviderConfigEntity>>> getProviderConfigs();

  /// Retrieves a single AI provider configuration by [id].
  Future<Result<AiProviderConfigEntity>> getProviderConfig(String id);

  // ─── Generation History ─────────────────────────────────────────────

  /// Retrieves generation request history with pagination.
  Future<Result<List<GenerationRequestEntity>>> getGenerationHistory({
    String? schoolId,
    int page = 1,
    int perPage = 20,
  });

  /// Retrieves a single generation request by [id].
  Future<Result<GenerationRequestEntity>> getGenerationRequest(String id);

  // ─── Usage Statistics ───────────────────────────────────────────────

  /// Retrieves AI usage statistics within an optional date range.
  Future<Result<List<AiUsageStatsEntity>>> getUsageStats({
    String? schoolId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Retrieves aggregated dashboard statistics for the AI generator.
  Future<Result<AiDashboardStatsEntity>> getDashboardStats({
    String? schoolId,
  });

  // ─── Curriculum Mappings ────────────────────────────────────────────

  /// Retrieves curriculum mappings with optional filters.
  Future<Result<List<CurriculumMappingEntity>>> getCurriculumMappings({
    CurriculumType? curriculum,
    String? subjectId,
  });

  // ─── Generation Control ─────────────────────────────────────────────

  /// Cancels an in-progress generation request.
  Future<Result<void>> cancelGeneration(String requestId);
}
