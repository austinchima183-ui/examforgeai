import 'package:equatable/equatable.dart';
import '../../../question_bank/domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Represents supported AI providers for question generation.
enum AiProvider {
  openai(
    value: 'openai',
    displayName: 'OpenAI',
    defaultModel: 'gpt-4o',
    defaultEndpoint: 'https://api.openai.com/v1',
  ),
  gemini(
    value: 'gemini',
    displayName: 'Google Gemini',
    defaultModel: 'gemini-1.5-pro',
    defaultEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
  ),
  claude(
    value: 'claude',
    displayName: 'Anthropic Claude',
    defaultModel: 'claude-3-5-sonnet-20241022',
    defaultEndpoint: 'https://api.anthropic.com/v1',
  ),
  deepseek(
    value: 'deepseek',
    displayName: 'DeepSeek',
    defaultModel: 'deepseek-chat',
    defaultEndpoint: 'https://api.deepseek.com/v1',
  ),
  grok(
    value: 'grok',
    displayName: 'Grok (xAI)',
    defaultModel: 'grok-2',
    defaultEndpoint: 'https://api.x.ai/v1',
  ),
  localLlm(
    value: 'local_llm',
    displayName: 'Local LLM',
    defaultModel: 'llama3',
    defaultEndpoint: 'http://localhost:11434/v1',
  );

  const AiProvider({
    required this.value,
    required this.displayName,
    required this.defaultModel,
    required this.defaultEndpoint,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable display name for the UI.
  final String displayName;

  /// The default model identifier for this provider.
  final String defaultModel;

  /// The default API endpoint for this provider.
  final String defaultEndpoint;

  /// Parses a raw [value] string into an [AiProvider].
  ///
  /// Returns `null` if the value does not match any known provider.
  static AiProvider? fromString(String? value) {
    if (value == null) return null;
    return AiProvider.values.cast<AiProvider?>().firstWhere(
          (provider) => provider?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the status of a generation request.
enum GenerationStatus {
  pending(
    value: 'pending',
    label: 'Pending',
    isTerminal: false,
  ),
  processing(
    value: 'processing',
    label: 'Processing',
    isTerminal: false,
  ),
  completed(
    value: 'completed',
    label: 'Completed',
    isTerminal: true,
  ),
  failed(
    value: 'failed',
    label: 'Failed',
    isTerminal: true,
  ),
  cancelled(
    value: 'cancelled',
    label: 'Cancelled',
    isTerminal: true,
  );

  const GenerationStatus({
    required this.value,
    required this.label,
    required this.isTerminal,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Whether this status represents a terminal (final) state.
  final bool isTerminal;

  /// Parses a raw [value] string into a [GenerationStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static GenerationStatus? fromString(String? value) {
    if (value == null) return null;
    return GenerationStatus.values.cast<GenerationStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the review status of a generated question.
enum ReviewStatus {
  pending(
    value: 'pending',
    label: 'Pending Review',
    color: '#F59E0B',
  ),
  approved(
    value: 'approved',
    label: 'Approved',
    color: '#22C55E',
  ),
  rejected(
    value: 'rejected',
    label: 'Rejected',
    color: '#EF4444',
  ),
  needsRevision(
    value: 'needs_revision',
    label: 'Needs Revision',
    color: '#3B82F6',
  );

  const ReviewStatus({
    required this.value,
    required this.label,
    required this.color,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Hex color string for UI rendering.
  final String color;

  /// Parses a raw [value] string into a [ReviewStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static ReviewStatus? fromString(String? value) {
    if (value == null) return null;
    return ReviewStatus.values.cast<ReviewStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the severity level of a validation result.
enum ValidationSeverity {
  info(
    value: 'info',
    label: 'Info',
    color: '#3B82F6',
    icon: 'info',
  ),
  warning(
    value: 'warning',
    label: 'Warning',
    color: '#F59E0B',
    icon: 'alert_triangle',
  ),
  error(
    value: 'error',
    label: 'Error',
    color: '#EF4444',
    icon: 'x_circle',
  ),
  critical(
    value: 'critical',
    label: 'Critical',
    color: '#DC2626',
    icon: 'octagon_alert',
  );

  const ValidationSeverity({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Hex color string for UI rendering.
  final String color;

  /// Icon identifier for UI rendering (Lucide icon name).
  final String icon;

  /// Parses a raw [value] string into a [ValidationSeverity].
  ///
  /// Returns `null` if the value does not match any known severity.
  static ValidationSeverity? fromString(String? value) {
    if (value == null) return null;
    return ValidationSeverity.values.cast<ValidationSeverity?>().firstWhere(
          (severity) => severity?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents Bloom's Taxonomy cognitive levels for question alignment.
enum BloomTaxonomy {
  remember(
    value: 'remember',
    label: 'Remember',
    description:
        'Recall facts and basic concepts — define, duplicate, list, memorize, repeat, state.',
    keywords: ['define', 'describe', 'identify', 'know', 'label', 'list', 'match', 'name', 'outline', 'recall', 'recognize', 'reproduce', 'select', 'state'],
  ),
  understand(
    value: 'understand',
    label: 'Understand',
    description:
        'Explain ideas or concepts — classify, describe, discuss, explain, identify, locate, recognize, report, select, translate.',
    keywords: ['classify', 'describe', 'discuss', 'explain', 'express', 'identify', 'indicate', 'locate', 'recognize', 'report', 'restate', 'review', 'select', 'translate'],
  ),
  apply(
    value: 'apply',
    label: 'Apply',
    description:
        'Use information in new situations — execute, implement, solve, use, demonstrate, interpret, operate, schedule, sketch.',
    keywords: ['apply', 'demonstrate', 'dramatize', 'employ', 'illustrate', 'implement', 'interpret', 'operate', 'practice', 'schedule', 'sketch', 'solve', 'use', 'write'],
  ),
  analyze(
    value: 'analyze',
    label: 'Analyze',
    description:
        'Draw connections among ideas — differentiate, organize, relate, compare, contrast, distinguish, examine, experiment, question, test.',
    keywords: ['analyze', 'appraise', 'breakdown', 'calculate', 'categorize', 'compare', 'contrast', 'criticize', 'differentiate', 'discriminate', 'distinguish', 'examine', 'experiment', 'question', 'test'],
  ),
  evaluate(
    value: 'evaluate',
    label: 'Evaluate',
    description:
        'Justify a stand or decision — appraise, argue, defend, judge, select, support, value, critique, weigh.',
    keywords: ['appraise', 'argue', 'assess', 'choose', 'conclude', 'critique', 'decide', 'defend', 'evaluate', 'judge', 'justify', 'predict', 'prioritize', 'prove', 'select', 'support', 'value'],
  ),
  create(
    value: 'create',
    label: 'Create',
    description:
        'Produce new or original work — design, assemble, construct, conjecture, develop, formulate, author, investigate.',
    keywords: ['assemble', 'combine', 'compile', 'compose', 'construct', 'create', 'design', 'develop', 'devise', 'formulate', 'generate', 'investigate', 'plan', 'produce', 'propose', 'synthesize'],
  );

  const BloomTaxonomy({
    required this.value,
    required this.label,
    required this.description,
    required this.keywords,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Description of this cognitive level.
  final String description;

  /// Keywords commonly associated with this taxonomy level.
  final List<String> keywords;

  /// Parses a raw [value] string into a [BloomTaxonomy].
  ///
  /// Returns `null` if the value does not match any known level.
  static BloomTaxonomy? fromString(String? value) {
    if (value == null) return null;
    return BloomTaxonomy.values.cast<BloomTaxonomy?>().firstWhere(
          (level) => level?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the type of prompt used for AI generation.
enum PromptType {
  questionGeneration(
    value: 'question_generation',
    label: 'Question Generation',
    description: 'Generate new questions from given parameters and content.',
  ),
  questionImprovement(
    value: 'question_improvement',
    label: 'Question Improvement',
    description: 'Improve an existing question by refining content, distractors, or clarity.',
  ),
  questionValidation(
    value: 'question_validation',
    label: 'Question Validation',
    description: 'Validate a question for quality, correctness, and curriculum alignment.',
  ),
  translation(
    value: 'translation',
    label: 'Translation',
    description: 'Translate question content between languages.',
  ),
  documentExtraction(
    value: 'document_extraction',
    label: 'Document Extraction',
    description: 'Extract questions and learning objectives from uploaded documents.',
  ),
  distractorGeneration(
    value: 'distractor_generation',
    label: 'Distractor Generation',
    description: 'Generate plausible distractors for multiple-choice questions.',
  ),
  explanationGeneration(
    value: 'explanation_generation',
    label: 'Explanation Generation',
    description: 'Generate explanations and worked solutions for questions.',
  );

  const PromptType({
    required this.value,
    required this.label,
    required this.description,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Description of what this prompt type does.
  final String description;

  /// Parses a raw [value] string into a [PromptType].
  ///
  /// Returns `null` if the value does not match any known type.
  static PromptType? fromString(String? value) {
    if (value == null) return null;
    return PromptType.values.cast<PromptType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents supported curriculum types for question alignment.
enum CurriculumType {
  waec(
    value: 'waec',
    label: 'WAEC',
    country: 'Nigeria',
  ),
  neco(
    value: 'neco',
    label: 'NECO',
    country: 'Nigeria',
  ),
  jamb(
    value: 'jamb',
    label: 'JAMB',
    country: 'Nigeria',
  ),
  bece(
    value: 'bece',
    label: 'BECE',
    country: 'Nigeria',
  ),
  cambridgeIgcse(
    value: 'cambridge_igcse',
    label: 'Cambridge IGCSE',
    country: 'International',
  ),
  custom(
    value: 'custom',
    label: 'Custom',
    country: 'Various',
  );

  const CurriculumType({
    required this.value,
    required this.label,
    required this.country,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Country or region for this curriculum.
  final String country;

  /// Parses a raw [value] string into a [CurriculumType].
  ///
  /// Returns `null` if the value does not match any known type.
  static CurriculumType? fromString(String? value) {
    if (value == null) return null;
    return CurriculumType.values.cast<CurriculumType?>().firstWhere(
          (type) => type?.value == value,
          orElse: () => null,
        );
  }
}

/// Represents the processing status of an uploaded document.
enum DocumentStatus {
  uploading(
    value: 'uploading',
    label: 'Uploading',
  ),
  uploaded(
    value: 'uploaded',
    label: 'Uploaded',
  ),
  processing(
    value: 'processing',
    label: 'Processing',
  ),
  completed(
    value: 'completed',
    label: 'Completed',
  ),
  failed(
    value: 'failed',
    label: 'Failed',
  );

  const DocumentStatus({
    required this.value,
    required this.label,
  });

  /// The string representation stored in the backend.
  final String value;

  /// Human-readable label for display in the UI.
  final String label;

  /// Parses a raw [value] string into a [DocumentStatus].
  ///
  /// Returns `null` if the value does not match any known status.
  static DocumentStatus? fromString(String? value) {
    if (value == null) return null;
    return DocumentStatus.values.cast<DocumentStatus?>().firstWhere(
          (status) => status?.value == value,
          orElse: () => null,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTING SIMPLE CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Represents a variable placeholder within a prompt template.
class PromptVariable extends Equatable {
  const PromptVariable({
    required this.name,
    this.description,
    this.isRequired = true,
    this.defaultValue,
  });

  /// The variable name used in the template (e.g., `{{subject}}`).
  final String name;

  /// A description of what this variable represents.
  final String? description;

  /// Whether this variable must be provided when using the template.
  final bool isRequired;

  /// Default value used when the variable is not provided.
  final String? defaultValue;

  PromptVariable copyWith({
    String? name,
    String? description,
    bool? isRequired,
    String? defaultValue,
  }) {
    return PromptVariable(
      name: name ?? this.name,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  List<Object?> get props => [name, description, isRequired, defaultValue];
}

/// Represents a few-shot example used in a prompt template.
class FewShotExample extends Equatable {
  const FewShotExample({
    required this.input,
    required this.output,
  });

  /// The input values for this example.
  final Map<String, dynamic> input;

  /// The expected output for this example.
  final Map<String, dynamic> output;

  FewShotExample copyWith({
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
  }) {
    return FewShotExample(
      input: input ?? this.input,
      output: output ?? this.output,
    );
  }

  @override
  List<Object?> get props => [input, output];
}

/// Represents a single day's usage summary.
class DailyUsage extends Equatable {
  const DailyUsage({
    required this.date,
    required this.requests,
    required this.tokens,
    required this.cost,
  });

  /// The date this usage record applies to.
  final DateTime date;

  /// Total number of requests on this date.
  final int requests;

  /// Total tokens consumed on this date.
  final int tokens;

  /// Total cost incurred on this date.
  final double cost;

  DailyUsage copyWith({
    DateTime? date,
    int? requests,
    int? tokens,
    double? cost,
  }) {
    return DailyUsage(
      date: date ?? this.date,
      requests: requests ?? this.requests,
      tokens: tokens ?? this.tokens,
      cost: cost ?? this.cost,
    );
  }

  @override
  List<Object?> get props => [date, requests, tokens, cost];
}

// ═══════════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════════

/// Configuration for an AI provider, including model settings and cost info.
class AiProviderConfigEntity extends Equatable {
  const AiProviderConfigEntity({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.modelName,
    required this.apiEndpoint,
    this.isActive = true,
    this.maxTokens = 4096,
    this.temperature = 0.7,
    this.topP = 1.0,
    this.costPer1kInputTokens = 0.0,
    this.costPer1kOutputTokens = 0.0,
    this.supportsStreaming = false,
    this.supportsFunctionCalling = false,
    this.supportsVision = false,
    this.rateLimitPerMinute = 60,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AiProvider provider;
  final String displayName;
  final String modelName;
  final String apiEndpoint;
  final bool isActive;
  final int maxTokens;
  final double temperature;
  final double topP;
  final double costPer1kInputTokens;
  final double costPer1kOutputTokens;
  final bool supportsStreaming;
  final bool supportsFunctionCalling;
  final bool supportsVision;
  final int rateLimitPerMinute;
  final Map<String, dynamic>? config;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiProviderConfigEntity copyWith({
    String? id,
    AiProvider? provider,
    String? displayName,
    String? modelName,
    String? apiEndpoint,
    bool? isActive,
    int? maxTokens,
    double? temperature,
    double? topP,
    double? costPer1kInputTokens,
    double? costPer1kOutputTokens,
    bool? supportsStreaming,
    bool? supportsFunctionCalling,
    bool? supportsVision,
    int? rateLimitPerMinute,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiProviderConfigEntity(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      displayName: displayName ?? this.displayName,
      modelName: modelName ?? this.modelName,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      isActive: isActive ?? this.isActive,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      costPer1kInputTokens: costPer1kInputTokens ?? this.costPer1kInputTokens,
      costPer1kOutputTokens: costPer1kOutputTokens ?? this.costPer1kOutputTokens,
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
      supportsFunctionCalling: supportsFunctionCalling ?? this.supportsFunctionCalling,
      supportsVision: supportsVision ?? this.supportsVision,
      rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        provider,
        displayName,
        modelName,
        apiEndpoint,
        isActive,
        maxTokens,
        temperature,
        topP,
        costPer1kInputTokens,
        costPer1kOutputTokens,
        supportsStreaming,
        supportsFunctionCalling,
        supportsVision,
        rateLimitPerMinute,
        config,
        createdAt,
        updatedAt,
      ];
}

/// Represents a reusable prompt template for AI generation.
class PromptTemplateEntity extends Equatable {
  const PromptTemplateEntity({
    required this.id,
    required this.name,
    this.description,
    required this.promptType,
    this.provider,
    this.curriculum,
    this.subjectId,
    this.questionType,
    this.difficulty,
    this.bloomLevel,
    this.language = 'en',
    required this.systemPrompt,
    required this.userPromptTemplate,
    this.variables = const [],
    this.fewShotExamples = const [],
    this.chainOfThought = false,
    this.outputFormat,
    this.isActive = true,
    this.isDefault = false,
    this.version = 1,
    this.parentId,
    this.qualityScore,
    this.usageCount = 0,
    this.successRate,
    this.createdBy,
    this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final PromptType promptType;
  final AiProvider? provider;
  final CurriculumType? curriculum;
  final String? subjectId;
  final QuestionType? questionType;
  final DifficultyLevel? difficulty;
  final BloomTaxonomy? bloomLevel;
  final String language;
  final String systemPrompt;
  final String userPromptTemplate;
  final List<PromptVariable> variables;
  final List<FewShotExample> fewShotExamples;
  final bool chainOfThought;
  final Map<String, dynamic>? outputFormat;
  final bool isActive;
  final bool isDefault;
  final int version;
  final String? parentId;
  final double? qualityScore;
  final int usageCount;
  final double? successRate;
  final String? createdBy;
  final String? schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PromptTemplateEntity copyWith({
    String? id,
    String? name,
    String? description,
    PromptType? promptType,
    AiProvider? provider,
    CurriculumType? curriculum,
    String? subjectId,
    QuestionType? questionType,
    DifficultyLevel? difficulty,
    BloomTaxonomy? bloomLevel,
    String? language,
    String? systemPrompt,
    String? userPromptTemplate,
    List<PromptVariable>? variables,
    List<FewShotExample>? fewShotExamples,
    bool? chainOfThought,
    Map<String, dynamic>? outputFormat,
    bool? isActive,
    bool? isDefault,
    int? version,
    String? parentId,
    double? qualityScore,
    int? usageCount,
    double? successRate,
    String? createdBy,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromptTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      promptType: promptType ?? this.promptType,
      provider: provider ?? this.provider,
      curriculum: curriculum ?? this.curriculum,
      subjectId: subjectId ?? this.subjectId,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      language: language ?? this.language,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPromptTemplate: userPromptTemplate ?? this.userPromptTemplate,
      variables: variables ?? this.variables,
      fewShotExamples: fewShotExamples ?? this.fewShotExamples,
      chainOfThought: chainOfThought ?? this.chainOfThought,
      outputFormat: outputFormat ?? this.outputFormat,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      version: version ?? this.version,
      parentId: parentId ?? this.parentId,
      qualityScore: qualityScore ?? this.qualityScore,
      usageCount: usageCount ?? this.usageCount,
      successRate: successRate ?? this.successRate,
      createdBy: createdBy ?? this.createdBy,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        promptType,
        provider,
        curriculum,
        subjectId,
        questionType,
        difficulty,
        bloomLevel,
        language,
        systemPrompt,
        userPromptTemplate,
        variables,
        fewShotExamples,
        chainOfThought,
        outputFormat,
        isActive,
        isDefault,
        version,
        parentId,
        qualityScore,
        usageCount,
        successRate,
        createdBy,
        schoolId,
        createdAt,
        updatedAt,
      ];
}

/// Represents a single AI generation request with full lifecycle data.
class GenerationRequestEntity extends Equatable {
  const GenerationRequestEntity({
    required this.id,
    required this.schoolId,
    required this.requestedBy,
    required this.provider,
    required this.modelName,
    this.promptTemplateId,
    required this.generationType,
    this.status = GenerationStatus.pending,
    required this.inputParams,
    required this.systemPrompt,
    required this.userPrompt,
    this.rawResponse,
    this.processedResponse,
    this.inputTokens,
    this.outputTokens,
    this.totalCost,
    this.generationTimeMs,
    this.errorMessage,
    this.retryCount = 0,
    this.priority = 0,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String requestedBy;
  final AiProvider provider;
  final String modelName;
  final String? promptTemplateId;
  final PromptType generationType;
  final GenerationStatus status;
  final Map<String, dynamic> inputParams;
  final String systemPrompt;
  final String userPrompt;
  final Map<String, dynamic>? rawResponse;
  final Map<String, dynamic>? processedResponse;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCost;
  final int? generationTimeMs;
  final String? errorMessage;
  final int retryCount;
  final int priority;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  GenerationRequestEntity copyWith({
    String? id,
    String? schoolId,
    String? requestedBy,
    AiProvider? provider,
    String? modelName,
    String? promptTemplateId,
    PromptType? generationType,
    GenerationStatus? status,
    Map<String, dynamic>? inputParams,
    String? systemPrompt,
    String? userPrompt,
    Map<String, dynamic>? rawResponse,
    Map<String, dynamic>? processedResponse,
    int? inputTokens,
    int? outputTokens,
    double? totalCost,
    int? generationTimeMs,
    String? errorMessage,
    int? retryCount,
    int? priority,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return GenerationRequestEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      requestedBy: requestedBy ?? this.requestedBy,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      promptTemplateId: promptTemplateId ?? this.promptTemplateId,
      generationType: generationType ?? this.generationType,
      status: status ?? this.status,
      inputParams: inputParams ?? this.inputParams,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPrompt: userPrompt ?? this.userPrompt,
      rawResponse: rawResponse ?? this.rawResponse,
      processedResponse: processedResponse ?? this.processedResponse,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalCost: totalCost ?? this.totalCost,
      generationTimeMs: generationTimeMs ?? this.generationTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        requestedBy,
        provider,
        modelName,
        promptTemplateId,
        generationType,
        status,
        inputParams,
        systemPrompt,
        userPrompt,
        rawResponse,
        processedResponse,
        inputTokens,
        outputTokens,
        totalCost,
        generationTimeMs,
        errorMessage,
        retryCount,
        priority,
        startedAt,
        completedAt,
        createdAt,
      ];
}

/// Represents a single question generated by an AI provider.
class GeneratedQuestionEntity extends Equatable {
  const GeneratedQuestionEntity({
    required this.id,
    required this.generationRequestId,
    this.questionBankId,
    required this.schoolId,
    required this.questionType,
    required this.difficulty,
    this.bloomLevel,
    required this.content,
    this.contentJson,
    this.answerOptions = const [],
    this.matchingPairs = const [],
    this.orderingItems = const [],
    this.fillInBlankAnswers = const [],
    this.explanation,
    this.suggestedReferences = const [],
    this.marks = 1,
    this.estimatedTimeSeconds,
    this.confidenceScore,
    this.curriculumAlignment,
    this.reviewStatus = ReviewStatus.pending,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.teacherEdits,
    this.isEdited = false,
    this.isApproved = false,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String generationRequestId;
  final String? questionBankId;
  final String schoolId;
  final QuestionType questionType;
  final DifficultyLevel difficulty;
  final BloomTaxonomy? bloomLevel;
  final String content;
  final Map<String, dynamic>? contentJson;
  final List<Map<String, dynamic>> answerOptions;
  final List<Map<String, dynamic>> matchingPairs;
  final List<Map<String, dynamic>> orderingItems;
  final List<Map<String, dynamic>> fillInBlankAnswers;
  final String? explanation;
  final List<String> suggestedReferences;
  final int marks;
  final int? estimatedTimeSeconds;
  final double? confidenceScore;
  final Map<String, dynamic>? curriculumAlignment;
  final ReviewStatus reviewStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final Map<String, dynamic>? teacherEdits;
  final bool isEdited;
  final bool isApproved;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeneratedQuestionEntity copyWith({
    String? id,
    String? generationRequestId,
    String? questionBankId,
    String? schoolId,
    QuestionType? questionType,
    DifficultyLevel? difficulty,
    BloomTaxonomy? bloomLevel,
    String? content,
    Map<String, dynamic>? contentJson,
    List<Map<String, dynamic>>? answerOptions,
    List<Map<String, dynamic>>? matchingPairs,
    List<Map<String, dynamic>>? orderingItems,
    List<Map<String, dynamic>>? fillInBlankAnswers,
    String? explanation,
    List<String>? suggestedReferences,
    int? marks,
    int? estimatedTimeSeconds,
    double? confidenceScore,
    Map<String, dynamic>? curriculumAlignment,
    ReviewStatus? reviewStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNotes,
    Map<String, dynamic>? teacherEdits,
    bool? isEdited,
    bool? isApproved,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeneratedQuestionEntity(
      id: id ?? this.id,
      generationRequestId: generationRequestId ?? this.generationRequestId,
      questionBankId: questionBankId ?? this.questionBankId,
      schoolId: schoolId ?? this.schoolId,
      questionType: questionType ?? this.questionType,
      difficulty: difficulty ?? this.difficulty,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      content: content ?? this.content,
      contentJson: contentJson ?? this.contentJson,
      answerOptions: answerOptions ?? this.answerOptions,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      orderingItems: orderingItems ?? this.orderingItems,
      fillInBlankAnswers: fillInBlankAnswers ?? this.fillInBlankAnswers,
      explanation: explanation ?? this.explanation,
      suggestedReferences: suggestedReferences ?? this.suggestedReferences,
      marks: marks ?? this.marks,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      curriculumAlignment: curriculumAlignment ?? this.curriculumAlignment,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      teacherEdits: teacherEdits ?? this.teacherEdits,
      isEdited: isEdited ?? this.isEdited,
      isApproved: isApproved ?? this.isApproved,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        generationRequestId,
        questionBankId,
        schoolId,
        questionType,
        difficulty,
        bloomLevel,
        content,
        contentJson,
        answerOptions,
        matchingPairs,
        orderingItems,
        fillInBlankAnswers,
        explanation,
        suggestedReferences,
        marks,
        estimatedTimeSeconds,
        confidenceScore,
        curriculumAlignment,
        reviewStatus,
        reviewedBy,
        reviewedAt,
        reviewNotes,
        teacherEdits,
        isEdited,
        isApproved,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Represents a validation result for a generated question.
class ValidationResultEntity extends Equatable {
  const ValidationResultEntity({
    required this.id,
    required this.generatedQuestionId,
    required this.validationType,
    required this.severity,
    required this.message,
    this.suggestion,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  final String id;
  final String generatedQuestionId;
  final String validationType;
  final ValidationSeverity severity;
  final String message;
  final String? suggestion;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  ValidationResultEntity copyWith({
    String? id,
    String? generatedQuestionId,
    String? validationType,
    ValidationSeverity? severity,
    String? message,
    String? suggestion,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return ValidationResultEntity(
      id: id ?? this.id,
      generatedQuestionId: generatedQuestionId ?? this.generatedQuestionId,
      validationType: validationType ?? this.validationType,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      suggestion: suggestion ?? this.suggestion,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        generatedQuestionId,
        validationType,
        severity,
        message,
        suggestion,
        isResolved,
        resolvedBy,
        resolvedAt,
        createdAt,
      ];
}

/// Represents an AI-powered improvement suggestion for a generated question.
class QuestionImprovementEntity extends Equatable {
  const QuestionImprovementEntity({
    required this.id,
    required this.generatedQuestionId,
    required this.improvementType,
    required this.provider,
    required this.originalContent,
    required this.improvedContent,
    this.originalAnswerOptions,
    this.improvedAnswerOptions,
    this.improvementPrompt,
    this.inputTokens,
    this.outputTokens,
    this.cost,
    this.isAccepted = false,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String generatedQuestionId;
  final String improvementType;
  final AiProvider provider;
  final String originalContent;
  final String improvedContent;
  final List<Map<String, dynamic>>? originalAnswerOptions;
  final List<Map<String, dynamic>>? improvedAnswerOptions;
  final String? improvementPrompt;
  final int? inputTokens;
  final int? outputTokens;
  final double? cost;
  final bool isAccepted;
  final String? createdBy;
  final DateTime createdAt;

  QuestionImprovementEntity copyWith({
    String? id,
    String? generatedQuestionId,
    String? improvementType,
    AiProvider? provider,
    String? originalContent,
    String? improvedContent,
    List<Map<String, dynamic>>? originalAnswerOptions,
    List<Map<String, dynamic>>? improvedAnswerOptions,
    String? improvementPrompt,
    int? inputTokens,
    int? outputTokens,
    double? cost,
    bool? isAccepted,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return QuestionImprovementEntity(
      id: id ?? this.id,
      generatedQuestionId: generatedQuestionId ?? this.generatedQuestionId,
      improvementType: improvementType ?? this.improvementType,
      provider: provider ?? this.provider,
      originalContent: originalContent ?? this.originalContent,
      improvedContent: improvedContent ?? this.improvedContent,
      originalAnswerOptions: originalAnswerOptions ?? this.originalAnswerOptions,
      improvedAnswerOptions: improvedAnswerOptions ?? this.improvedAnswerOptions,
      improvementPrompt: improvementPrompt ?? this.improvementPrompt,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cost: cost ?? this.cost,
      isAccepted: isAccepted ?? this.isAccepted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        generatedQuestionId,
        improvementType,
        provider,
        originalContent,
        improvedContent,
        originalAnswerOptions,
        improvedAnswerOptions,
        improvementPrompt,
        inputTokens,
        outputTokens,
        cost,
        isAccepted,
        createdBy,
        createdAt,
      ];
}

/// Represents an uploaded document for AI extraction and question generation.
class DocumentUploadEntity extends Equatable {
  const DocumentUploadEntity({
    required this.id,
    required this.schoolId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.mimeType,
    required this.documentType,
    this.status = DocumentStatus.uploading,
    this.extractedText,
    this.identifiedTopics = const [],
    this.suggestedObjectives = const [],
    this.questionGenerationRequestId,
    this.errorMessage,
    this.processedAt,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final String uploadedBy;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String mimeType;
  final String documentType;
  final DocumentStatus status;
  final String? extractedText;
  final List<Map<String, dynamic>> identifiedTopics;
  final List<Map<String, dynamic>> suggestedObjectives;
  final String? questionGenerationRequestId;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;

  DocumentUploadEntity copyWith({
    String? id,
    String? schoolId,
    String? uploadedBy,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    String? documentType,
    DocumentStatus? status,
    String? extractedText,
    List<Map<String, dynamic>>? identifiedTopics,
    List<Map<String, dynamic>>? suggestedObjectives,
    String? questionGenerationRequestId,
    String? errorMessage,
    DateTime? processedAt,
    DateTime? createdAt,
  }) {
    return DocumentUploadEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      extractedText: extractedText ?? this.extractedText,
      identifiedTopics: identifiedTopics ?? this.identifiedTopics,
      suggestedObjectives: suggestedObjectives ?? this.suggestedObjectives,
      questionGenerationRequestId:
          questionGenerationRequestId ?? this.questionGenerationRequestId,
      errorMessage: errorMessage ?? this.errorMessage,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        uploadedBy,
        fileName,
        fileUrl,
        fileSize,
        mimeType,
        documentType,
        status,
        extractedText,
        identifiedTopics,
        suggestedObjectives,
        questionGenerationRequestId,
        errorMessage,
        processedAt,
        createdAt,
      ];
}

/// Represents a queued generation request waiting for processing.
class GenerationQueueEntity extends Equatable {
  const GenerationQueueEntity({
    required this.id,
    required this.generationRequestId,
    this.priority = 0,
    this.attempts = 0,
    this.maxAttempts = 3,
    this.nextAttemptAt,
    this.status = GenerationStatus.pending,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String generationRequestId;
  final int priority;
  final int attempts;
  final int maxAttempts;
  final DateTime? nextAttemptAt;
  final GenerationStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  GenerationQueueEntity copyWith({
    String? id,
    String? generationRequestId,
    int? priority,
    int? attempts,
    int? maxAttempts,
    DateTime? nextAttemptAt,
    GenerationStatus? status,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GenerationQueueEntity(
      id: id ?? this.id,
      generationRequestId: generationRequestId ?? this.generationRequestId,
      priority: priority ?? this.priority,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        generationRequestId,
        priority,
        attempts,
        maxAttempts,
        nextAttemptAt,
        status,
        errorMessage,
        createdAt,
        updatedAt,
      ];
}

/// Represents aggregated AI usage statistics for a provider on a given date.
class AiUsageStatsEntity extends Equatable {
  const AiUsageStatsEntity({
    required this.id,
    required this.schoolId,
    required this.provider,
    required this.modelName,
    required this.date,
    this.totalRequests = 0,
    this.successfulRequests = 0,
    this.failedRequests = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCost = 0.0,
    this.avgGenerationTimeMs,
    this.questionsGenerated = 0,
    this.questionsApproved = 0,
    this.questionsRejected = 0,
    required this.createdAt,
  });

  final String id;
  final String schoolId;
  final AiProvider provider;
  final String modelName;
  final DateTime date;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCost;
  final double? avgGenerationTimeMs;
  final int questionsGenerated;
  final int questionsApproved;
  final int questionsRejected;
  final DateTime createdAt;

  AiUsageStatsEntity copyWith({
    String? id,
    String? schoolId,
    AiProvider? provider,
    String? modelName,
    DateTime? date,
    int? totalRequests,
    int? successfulRequests,
    int? failedRequests,
    int? totalInputTokens,
    int? totalOutputTokens,
    double? totalCost,
    double? avgGenerationTimeMs,
    int? questionsGenerated,
    int? questionsApproved,
    int? questionsRejected,
    DateTime? createdAt,
  }) {
    return AiUsageStatsEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      date: date ?? this.date,
      totalRequests: totalRequests ?? this.totalRequests,
      successfulRequests: successfulRequests ?? this.successfulRequests,
      failedRequests: failedRequests ?? this.failedRequests,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      totalCost: totalCost ?? this.totalCost,
      avgGenerationTimeMs: avgGenerationTimeMs ?? this.avgGenerationTimeMs,
      questionsGenerated: questionsGenerated ?? this.questionsGenerated,
      questionsApproved: questionsApproved ?? this.questionsApproved,
      questionsRejected: questionsRejected ?? this.questionsRejected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        provider,
        modelName,
        date,
        totalRequests,
        successfulRequests,
        failedRequests,
        totalInputTokens,
        totalOutputTokens,
        totalCost,
        avgGenerationTimeMs,
        questionsGenerated,
        questionsApproved,
        questionsRejected,
        createdAt,
      ];
}

/// Represents an encrypted API key for an AI provider.
class AiApiKeyEntity extends Equatable {
  const AiApiKeyEntity({
    required this.id,
    required this.schoolId,
    required this.provider,
    required this.encryptedKey,
    required this.keyHash,
    this.isActive = true,
    this.monthlyBudget,
    this.currentMonthUsage = 0.0,
    this.rateLimitPerMinute = 60,
    this.lastUsedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final AiProvider provider;
  final String encryptedKey;
  final String keyHash;
  final bool isActive;
  final double? monthlyBudget;
  final double currentMonthUsage;
  final int rateLimitPerMinute;
  final DateTime? lastUsedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiApiKeyEntity copyWith({
    String? id,
    String? schoolId,
    AiProvider? provider,
    String? encryptedKey,
    String? keyHash,
    bool? isActive,
    double? monthlyBudget,
    double? currentMonthUsage,
    int? rateLimitPerMinute,
    DateTime? lastUsedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiApiKeyEntity(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      provider: provider ?? this.provider,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      keyHash: keyHash ?? this.keyHash,
      isActive: isActive ?? this.isActive,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currentMonthUsage: currentMonthUsage ?? this.currentMonthUsage,
      rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        schoolId,
        provider,
        encryptedKey,
        keyHash,
        isActive,
        monthlyBudget,
        currentMonthUsage,
        rateLimitPerMinute,
        lastUsedAt,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

/// Represents a curriculum mapping that aligns topics with learning objectives
/// and Bloom's taxonomy levels.
class CurriculumMappingEntity extends Equatable {
  const CurriculumMappingEntity({
    required this.id,
    required this.curriculum,
    required this.subjectId,
    required this.topicId,
    this.subtopicId,
    this.classLevel,
    this.curriculumCode,
    this.learningObjectives = const [],
    this.bloomLevels = const [],
    this.suggestedDifficulty,
    this.marksGuidance,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final CurriculumType curriculum;
  final String subjectId;
  final String topicId;
  final String? subtopicId;
  final String? classLevel;
  final String? curriculumCode;
  final List<String> learningObjectives;
  final List<BloomTaxonomy> bloomLevels;
  final DifficultyLevel? suggestedDifficulty;
  final String? marksGuidance;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CurriculumMappingEntity copyWith({
    String? id,
    CurriculumType? curriculum,
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classLevel,
    String? curriculumCode,
    List<String>? learningObjectives,
    List<BloomTaxonomy>? bloomLevels,
    DifficultyLevel? suggestedDifficulty,
    String? marksGuidance,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CurriculumMappingEntity(
      id: id ?? this.id,
      curriculum: curriculum ?? this.curriculum,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      classLevel: classLevel ?? this.classLevel,
      curriculumCode: curriculumCode ?? this.curriculumCode,
      learningObjectives: learningObjectives ?? this.learningObjectives,
      bloomLevels: bloomLevels ?? this.bloomLevels,
      suggestedDifficulty: suggestedDifficulty ?? this.suggestedDifficulty,
      marksGuidance: marksGuidance ?? this.marksGuidance,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        curriculum,
        subjectId,
        topicId,
        subtopicId,
        classLevel,
        curriculumCode,
        learningObjectives,
        bloomLevels,
        suggestedDifficulty,
        marksGuidance,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Represents the teacher's input parameters for question generation.
///
/// This is a value object used to capture the teacher's intent and
/// preferences before constructing a generation request.
class GenerationInputEntity extends Equatable {
  const GenerationInputEntity({
    required this.subjectId,
    required this.topicId,
    this.subtopicId,
    this.classId,
    this.curriculum,
    required this.difficulty,
    this.bloomLevel,
    this.questionType,
    this.numQuestions = 5,
    this.language = 'en',
    this.examType,
    this.keywords = const [],
    this.customInstructions,
    this.provider,
    this.promptTemplateId,
  });

  final String subjectId;
  final String topicId;
  final String? subtopicId;
  final String? classId;
  final CurriculumType? curriculum;
  final DifficultyLevel difficulty;
  final BloomTaxonomy? bloomLevel;
  final QuestionType? questionType;
  final int numQuestions;
  final String language;
  final ExamType? examType;
  final List<String> keywords;
  final String? customInstructions;
  final AiProvider? provider;
  final String? promptTemplateId;

  GenerationInputEntity copyWith({
    String? subjectId,
    String? topicId,
    String? subtopicId,
    String? classId,
    CurriculumType? curriculum,
    DifficultyLevel? difficulty,
    BloomTaxonomy? bloomLevel,
    QuestionType? questionType,
    int? numQuestions,
    String? language,
    ExamType? examType,
    List<String>? keywords,
    String? customInstructions,
    AiProvider? provider,
    String? promptTemplateId,
  }) {
    return GenerationInputEntity(
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      subtopicId: subtopicId ?? this.subtopicId,
      classId: classId ?? this.classId,
      curriculum: curriculum ?? this.curriculum,
      difficulty: difficulty ?? this.difficulty,
      bloomLevel: bloomLevel ?? this.bloomLevel,
      questionType: questionType ?? this.questionType,
      numQuestions: numQuestions ?? this.numQuestions,
      language: language ?? this.language,
      examType: examType ?? this.examType,
      keywords: keywords ?? this.keywords,
      customInstructions: customInstructions ?? this.customInstructions,
      provider: provider ?? this.provider,
      promptTemplateId: promptTemplateId ?? this.promptTemplateId,
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        topicId,
        subtopicId,
        classId,
        curriculum,
        difficulty,
        bloomLevel,
        questionType,
        numQuestions,
        language,
        examType,
        keywords,
        customInstructions,
        provider,
        promptTemplateId,
      ];
}

/// Represents aggregated dashboard statistics for the AI generator module.
class AiDashboardStatsEntity extends Equatable {
  const AiDashboardStatsEntity({
    this.totalGenerated = 0,
    this.totalApproved = 0,
    this.totalRejected = 0,
    this.pendingReview = 0,
    this.totalCost = 0.0,
    this.totalTokensUsed = 0,
    this.questionsByType = const {},
    this.questionsByDifficulty = const {},
    this.questionsByBloomLevel = const {},
    this.avgConfidenceScore,
    this.avgGenerationTimeMs,
    this.recentGenerations = const [],
    this.costByProvider = const {},
    this.dailyUsage = const [],
  });

  final int totalGenerated;
  final int totalApproved;
  final int totalRejected;
  final int pendingReview;
  final double totalCost;
  final int totalTokensUsed;
  final Map<String, int> questionsByType;
  final Map<String, int> questionsByDifficulty;
  final Map<String, int> questionsByBloomLevel;
  final double? avgConfidenceScore;
  final double? avgGenerationTimeMs;
  final List<GenerationRequestEntity> recentGenerations;
  final Map<String, double> costByProvider;
  final List<DailyUsage> dailyUsage;

  AiDashboardStatsEntity copyWith({
    int? totalGenerated,
    int? totalApproved,
    int? totalRejected,
    int? pendingReview,
    double? totalCost,
    int? totalTokensUsed,
    Map<String, int>? questionsByType,
    Map<String, int>? questionsByDifficulty,
    Map<String, int>? questionsByBloomLevel,
    double? avgConfidenceScore,
    double? avgGenerationTimeMs,
    List<GenerationRequestEntity>? recentGenerations,
    Map<String, double>? costByProvider,
    List<DailyUsage>? dailyUsage,
  }) {
    return AiDashboardStatsEntity(
      totalGenerated: totalGenerated ?? this.totalGenerated,
      totalApproved: totalApproved ?? this.totalApproved,
      totalRejected: totalRejected ?? this.totalRejected,
      pendingReview: pendingReview ?? this.pendingReview,
      totalCost: totalCost ?? this.totalCost,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      questionsByType: questionsByType ?? this.questionsByType,
      questionsByDifficulty: questionsByDifficulty ?? this.questionsByDifficulty,
      questionsByBloomLevel: questionsByBloomLevel ?? this.questionsByBloomLevel,
      avgConfidenceScore: avgConfidenceScore ?? this.avgConfidenceScore,
      avgGenerationTimeMs: avgGenerationTimeMs ?? this.avgGenerationTimeMs,
      recentGenerations: recentGenerations ?? this.recentGenerations,
      costByProvider: costByProvider ?? this.costByProvider,
      dailyUsage: dailyUsage ?? this.dailyUsage,
    );
  }

  @override
  List<Object?> get props => [
        totalGenerated,
        totalApproved,
        totalRejected,
        pendingReview,
        totalCost,
        totalTokensUsed,
        questionsByType,
        questionsByDifficulty,
        questionsByBloomLevel,
        avgConfidenceScore,
        avgGenerationTimeMs,
        recentGenerations,
        costByProvider,
        dailyUsage,
      ];
}
