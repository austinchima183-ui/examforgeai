import '../../domain/entities/ai_entities.dart';
import '../../../question_bank/domain/entities/question_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUPPORTING MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Data-layer representation of a prompt variable.
class PromptVariableModel {
  const PromptVariableModel({
    required this.name,
    this.description,
    this.isRequired = true,
    this.defaultValue,
  });

  final String name;
  final String? description;
  final bool isRequired;
  final String? defaultValue;

  factory PromptVariableModel.fromJson(Map<String, dynamic> json) {
    return PromptVariableModel(
      name: json['name'] as String,
      description: json['description'] as String?,
      isRequired: json['is_required'] as bool? ?? json['isRequired'] as bool? ?? true,
      defaultValue: json['default_value'] as String? ?? json['defaultValue'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'is_required': isRequired,
        'default_value': defaultValue,
      };

  factory PromptVariableModel.fromEntity(PromptVariable entity) {
    return PromptVariableModel(
      name: entity.name,
      description: entity.description,
      isRequired: entity.isRequired,
      defaultValue: entity.defaultValue,
    );
  }

  PromptVariable toEntity() {
    return PromptVariable(
      name: name,
      description: description,
      isRequired: isRequired,
      defaultValue: defaultValue,
    );
  }

  PromptVariableModel copyWith({
    String? name,
    String? description,
    bool? isRequired,
    String? defaultValue,
  }) {
    return PromptVariableModel(
      name: name ?? this.name,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptVariableModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode => Object.hash(name, description, isRequired, defaultValue);
}

/// Data-layer representation of a few-shot example.
class FewShotExampleModel {
  const FewShotExampleModel({
    required this.input,
    required this.output,
  });

  final Map<String, dynamic> input;
  final Map<String, dynamic> output;

  factory FewShotExampleModel.fromJson(Map<String, dynamic> json) {
    return FewShotExampleModel(
      input: Map<String, dynamic>.from(json['input'] as Map? ?? {}),
      output: Map<String, dynamic>.from(json['output'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'input': input,
        'output': output,
      };

  factory FewShotExampleModel.fromEntity(FewShotExample entity) {
    return FewShotExampleModel(
      input: Map<String, dynamic>.from(entity.input),
      output: Map<String, dynamic>.from(entity.output),
    );
  }

  FewShotExample toEntity() {
    return FewShotExample(
      input: Map<String, dynamic>.from(input),
      output: Map<String, dynamic>.from(output),
    );
  }

  FewShotExampleModel copyWith({
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
  }) {
    return FewShotExampleModel(
      input: input ?? this.input,
      output: output ?? this.output,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FewShotExampleModel &&
          runtimeType == other.runtimeType &&
          _mapEquals(input, other.input) &&
          _mapEquals(output, other.output);

  @override
  int get hashCode => Object.hash(input.hashCode, output.hashCode);
}

/// Data-layer representation of a daily usage summary.
class DailyUsageModel {
  const DailyUsageModel({
    required this.date,
    required this.requests,
    required this.tokens,
    required this.cost,
  });

  final DateTime date;
  final int requests;
  final int tokens;
  final double cost;

  factory DailyUsageModel.fromJson(Map<String, dynamic> json) {
    return DailyUsageModel(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      requests: json['requests'] as int? ?? 0,
      tokens: json['tokens'] as int? ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'requests': requests,
        'tokens': tokens,
        'cost': cost,
      };

  factory DailyUsageModel.fromEntity(DailyUsage entity) {
    return DailyUsageModel(
      date: entity.date,
      requests: entity.requests,
      tokens: entity.tokens,
      cost: entity.cost,
    );
  }

  DailyUsage toEntity() {
    return DailyUsage(
      date: date,
      requests: requests,
      tokens: tokens,
      cost: cost,
    );
  }

  DailyUsageModel copyWith({
    DateTime? date,
    int? requests,
    int? tokens,
    double? cost,
  }) {
    return DailyUsageModel(
      date: date ?? this.date,
      requests: requests ?? this.requests,
      tokens: tokens ?? this.tokens,
      cost: cost ?? this.cost,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsageModel &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          requests == other.requests &&
          tokens == other.tokens &&
          cost == other.cost;

  @override
  int get hashCode => Object.hash(date, requests, tokens, cost);
}

// ═══════════════════════════════════════════════════════════════════════
// AI PROVIDER CONFIG MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiProviderConfigModel {
  const AiProviderConfigModel({
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

  factory AiProviderConfigModel.fromJson(Map<String, dynamic> json) {
    return AiProviderConfigModel(
      id: json['id'] as String,
      provider: AiProvider.fromString(json['provider'] as String?) ?? AiProvider.openai,
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      modelName: json['model_name'] as String? ?? json['modelName'] as String? ?? '',
      apiEndpoint: json['api_endpoint'] as String? ?? json['apiEndpoint'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      maxTokens: json['max_tokens'] as int? ?? json['maxTokens'] as int? ?? 4096,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['top_p'] as num?)?.toDouble() ?? (json['topP'] as num?)?.toDouble() ?? 1.0,
      costPer1kInputTokens: (json['cost_per_1k_input_tokens'] as num?)?.toDouble() ?? (json['costPer1kInputTokens'] as num?)?.toDouble() ?? 0.0,
      costPer1kOutputTokens: (json['cost_per_1k_output_tokens'] as num?)?.toDouble() ?? (json['costPer1kOutputTokens'] as num?)?.toDouble() ?? 0.0,
      supportsStreaming: json['supports_streaming'] as bool? ?? json['supportsStreaming'] as bool? ?? false,
      supportsFunctionCalling: json['supports_function_calling'] as bool? ?? json['supportsFunctionCalling'] as bool? ?? false,
      supportsVision: json['supports_vision'] as bool? ?? json['supportsVision'] as bool? ?? false,
      rateLimitPerMinute: json['rate_limit_per_minute'] as int? ?? json['rateLimitPerMinute'] as int? ?? 60,
      config: json['config'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'provider': provider.value,
        'display_name': displayName,
        'model_name': modelName,
        'api_endpoint': apiEndpoint,
        'is_active': isActive,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'top_p': topP,
        'cost_per_1k_input_tokens': costPer1kInputTokens,
        'cost_per_1k_output_tokens': costPer1kOutputTokens,
        'supports_streaming': supportsStreaming,
        'supports_function_calling': supportsFunctionCalling,
        'supports_vision': supportsVision,
        'rate_limit_per_minute': rateLimitPerMinute,
        'config': config,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AiProviderConfigModel.fromEntity(AiProviderConfigEntity entity) {
    return AiProviderConfigModel(
      id: entity.id,
      provider: entity.provider,
      displayName: entity.displayName,
      modelName: entity.modelName,
      apiEndpoint: entity.apiEndpoint,
      isActive: entity.isActive,
      maxTokens: entity.maxTokens,
      temperature: entity.temperature,
      topP: entity.topP,
      costPer1kInputTokens: entity.costPer1kInputTokens,
      costPer1kOutputTokens: entity.costPer1kOutputTokens,
      supportsStreaming: entity.supportsStreaming,
      supportsFunctionCalling: entity.supportsFunctionCalling,
      supportsVision: entity.supportsVision,
      rateLimitPerMinute: entity.rateLimitPerMinute,
      config: entity.config,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiProviderConfigEntity toEntity() {
    return AiProviderConfigEntity(
      id: id,
      provider: provider,
      displayName: displayName,
      modelName: modelName,
      apiEndpoint: apiEndpoint,
      isActive: isActive,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      costPer1kInputTokens: costPer1kInputTokens,
      costPer1kOutputTokens: costPer1kOutputTokens,
      supportsStreaming: supportsStreaming,
      supportsFunctionCalling: supportsFunctionCalling,
      supportsVision: supportsVision,
      rateLimitPerMinute: rateLimitPerMinute,
      config: config,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AiProviderConfigModel copyWith({
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
    return AiProviderConfigModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiProviderConfigModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          provider == other.provider &&
          displayName == other.displayName &&
          modelName == other.modelName &&
          apiEndpoint == other.apiEndpoint &&
          isActive == other.isActive &&
          maxTokens == other.maxTokens &&
          temperature == other.temperature &&
          topP == other.topP &&
          costPer1kInputTokens == other.costPer1kInputTokens &&
          costPer1kOutputTokens == other.costPer1kOutputTokens &&
          supportsStreaming == other.supportsStreaming &&
          supportsFunctionCalling == other.supportsFunctionCalling &&
          supportsVision == other.supportsVision &&
          rateLimitPerMinute == other.rateLimitPerMinute &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, provider, displayName, modelName, apiEndpoint, isActive,
        maxTokens, temperature, topP, costPer1kInputTokens,
        costPer1kOutputTokens, supportsStreaming, supportsFunctionCalling,
        supportsVision, rateLimitPerMinute, createdAt, updatedAt,
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PROMPT TEMPLATE MODEL
// ═══════════════════════════════════════════════════════════════════════

class PromptTemplateModel {
  const PromptTemplateModel({
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
  final List<PromptVariableModel> variables;
  final List<FewShotExampleModel> fewShotExamples;
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

  factory PromptTemplateModel.fromJson(Map<String, dynamic> json) {
    return PromptTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      promptType: PromptType.fromString(json['prompt_type'] as String? ?? json['promptType'] as String?) ?? PromptType.questionGeneration,
      provider: AiProvider.fromString(json['provider'] as String?),
      curriculum: CurriculumType.fromString(json['curriculum'] as String?),
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String?,
      questionType: _parseQuestionType(json['question_type'] ?? json['questionType']),
      difficulty: _parseDifficulty(json['difficulty']),
      bloomLevel: BloomTaxonomy.fromString(json['bloom_level'] as String? ?? json['bloomLevel'] as String?),
      language: json['language'] as String? ?? 'en',
      systemPrompt: json['system_prompt'] as String? ?? json['systemPrompt'] as String? ?? '',
      userPromptTemplate: json['user_prompt_template'] as String? ?? json['userPromptTemplate'] as String? ?? '',
      variables: _parseVariables(json['variables']),
      fewShotExamples: _parseFewShotExamples(json['few_shot_examples'] ?? json['fewShotExamples']),
      chainOfThought: json['chain_of_thought'] as bool? ?? json['chainOfThought'] as bool? ?? false,
      outputFormat: json['output_format'] as Map<String, dynamic>? ?? json['outputFormat'] as Map<String, dynamic>?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      version: json['version'] as int? ?? 1,
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? (json['qualityScore'] as num?)?.toDouble(),
      usageCount: json['usage_count'] as int? ?? json['usageCount'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? (json['successRate'] as num?)?.toDouble(),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String?,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'prompt_type': promptType.value,
        'provider': provider?.value,
        'curriculum': curriculum?.value,
        'subject_id': subjectId,
        'question_type': questionType?.value,
        'difficulty': difficulty?.value,
        'bloom_level': bloomLevel?.value,
        'language': language,
        'system_prompt': systemPrompt,
        'user_prompt_template': userPromptTemplate,
        'variables': variables.map((v) => v.toJson()).toList(),
        'few_shot_examples': fewShotExamples.map((e) => e.toJson()).toList(),
        'chain_of_thought': chainOfThought,
        'output_format': outputFormat,
        'is_active': isActive,
        'is_default': isDefault,
        'version': version,
        'parent_id': parentId,
        'quality_score': qualityScore,
        'usage_count': usageCount,
        'success_rate': successRate,
        'created_by': createdBy,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PromptTemplateModel.fromEntity(PromptTemplateEntity entity) {
    return PromptTemplateModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      promptType: entity.promptType,
      provider: entity.provider,
      curriculum: entity.curriculum,
      subjectId: entity.subjectId,
      questionType: entity.questionType,
      difficulty: entity.difficulty,
      bloomLevel: entity.bloomLevel,
      language: entity.language,
      systemPrompt: entity.systemPrompt,
      userPromptTemplate: entity.userPromptTemplate,
      variables: entity.variables.map((v) => PromptVariableModel.fromEntity(v)).toList(),
      fewShotExamples: entity.fewShotExamples.map((e) => FewShotExampleModel.fromEntity(e)).toList(),
      chainOfThought: entity.chainOfThought,
      outputFormat: entity.outputFormat,
      isActive: entity.isActive,
      isDefault: entity.isDefault,
      version: entity.version,
      parentId: entity.parentId,
      qualityScore: entity.qualityScore,
      usageCount: entity.usageCount,
      successRate: entity.successRate,
      createdBy: entity.createdBy,
      schoolId: entity.schoolId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PromptTemplateEntity toEntity() {
    return PromptTemplateEntity(
      id: id,
      name: name,
      description: description,
      promptType: promptType,
      provider: provider,
      curriculum: curriculum,
      subjectId: subjectId,
      questionType: questionType,
      difficulty: difficulty,
      bloomLevel: bloomLevel,
      language: language,
      systemPrompt: systemPrompt,
      userPromptTemplate: userPromptTemplate,
      variables: variables.map((v) => v.toEntity()).toList(),
      fewShotExamples: fewShotExamples.map((e) => e.toEntity()).toList(),
      chainOfThought: chainOfThought,
      outputFormat: outputFormat,
      isActive: isActive,
      isDefault: isDefault,
      version: version,
      parentId: parentId,
      qualityScore: qualityScore,
      usageCount: usageCount,
      successRate: successRate,
      createdBy: createdBy,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  PromptTemplateModel copyWith({
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
    List<PromptVariableModel>? variables,
    List<FewShotExampleModel>? fewShotExamples,
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
    return PromptTemplateModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptTemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          promptType == other.promptType &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, name, promptType, version);
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATION REQUEST MODEL
// ═══════════════════════════════════════════════════════════════════════

class GenerationRequestModel {
  const GenerationRequestModel({
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

  factory GenerationRequestModel.fromJson(Map<String, dynamic> json) {
    return GenerationRequestModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      requestedBy: json['requested_by'] as String? ?? json['requestedBy'] as String? ?? '',
      provider: AiProvider.fromString(json['provider'] as String?) ?? AiProvider.openai,
      modelName: json['model_name'] as String? ?? json['modelName'] as String? ?? '',
      promptTemplateId: json['prompt_template_id'] as String? ?? json['promptTemplateId'] as String?,
      generationType: PromptType.fromString(json['generation_type'] as String? ?? json['generationType'] as String?) ?? PromptType.questionGeneration,
      status: GenerationStatus.fromString(json['status'] as String?) ?? GenerationStatus.pending,
      inputParams: Map<String, dynamic>.from(json['input_params'] as Map? ?? json['inputParams'] as Map? ?? {}),
      systemPrompt: json['system_prompt'] as String? ?? json['systemPrompt'] as String? ?? '',
      userPrompt: json['user_prompt'] as String? ?? json['userPrompt'] as String? ?? '',
      rawResponse: json['raw_response'] as Map<String, dynamic>? ?? json['rawResponse'] as Map<String, dynamic>?,
      processedResponse: json['processed_response'] as Map<String, dynamic>? ?? json['processedResponse'] as Map<String, dynamic>?,
      inputTokens: json['input_tokens'] as int? ?? json['inputTokens'] as int?,
      outputTokens: json['output_tokens'] as int? ?? json['outputTokens'] as int?,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? (json['totalCost'] as num?)?.toDouble(),
      generationTimeMs: json['generation_time_ms'] as int? ?? json['generationTimeMs'] as int?,
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
      retryCount: json['retry_count'] as int? ?? json['retryCount'] as int? ?? 0,
      priority: json['priority'] as int? ?? 0,
      startedAt: _parseNullableDateTime(json, 'started_at', 'startedAt'),
      completedAt: _parseNullableDateTime(json, 'completed_at', 'completedAt'),
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'requested_by': requestedBy,
        'provider': provider.value,
        'model_name': modelName,
        'prompt_template_id': promptTemplateId,
        'generation_type': generationType.value,
        'status': status.value,
        'input_params': inputParams,
        'system_prompt': systemPrompt,
        'user_prompt': userPrompt,
        'raw_response': rawResponse,
        'processed_response': processedResponse,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'total_cost': totalCost,
        'generation_time_ms': generationTimeMs,
        'error_message': errorMessage,
        'retry_count': retryCount,
        'priority': priority,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory GenerationRequestModel.fromEntity(GenerationRequestEntity entity) {
    return GenerationRequestModel(
      id: entity.id,
      schoolId: entity.schoolId,
      requestedBy: entity.requestedBy,
      provider: entity.provider,
      modelName: entity.modelName,
      promptTemplateId: entity.promptTemplateId,
      generationType: entity.generationType,
      status: entity.status,
      inputParams: entity.inputParams,
      systemPrompt: entity.systemPrompt,
      userPrompt: entity.userPrompt,
      rawResponse: entity.rawResponse,
      processedResponse: entity.processedResponse,
      inputTokens: entity.inputTokens,
      outputTokens: entity.outputTokens,
      totalCost: entity.totalCost,
      generationTimeMs: entity.generationTimeMs,
      errorMessage: entity.errorMessage,
      retryCount: entity.retryCount,
      priority: entity.priority,
      startedAt: entity.startedAt,
      completedAt: entity.completedAt,
      createdAt: entity.createdAt,
    );
  }

  GenerationRequestEntity toEntity() {
    return GenerationRequestEntity(
      id: id,
      schoolId: schoolId,
      requestedBy: requestedBy,
      provider: provider,
      modelName: modelName,
      promptTemplateId: promptTemplateId,
      generationType: generationType,
      status: status,
      inputParams: inputParams,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      rawResponse: rawResponse,
      processedResponse: processedResponse,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCost: totalCost,
      generationTimeMs: generationTimeMs,
      errorMessage: errorMessage,
      retryCount: retryCount,
      priority: priority,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
    );
  }

  GenerationRequestModel copyWith({
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
    return GenerationRequestModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationRequestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATED QUESTION MODEL
// ═══════════════════════════════════════════════════════════════════════

class GeneratedQuestionModel {
  const GeneratedQuestionModel({
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

  factory GeneratedQuestionModel.fromJson(Map<String, dynamic> json) {
    return GeneratedQuestionModel(
      id: json['id'] as String,
      generationRequestId: json['generation_request_id'] as String? ?? json['generationRequestId'] as String? ?? '',
      questionBankId: json['question_bank_id'] as String? ?? json['questionBankId'] as String?,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      questionType: _parseQuestionType(json['question_type'] ?? json['questionType']) ?? QuestionType.multipleChoice,
      difficulty: _parseDifficulty(json['difficulty']) ?? DifficultyLevel.medium,
      bloomLevel: BloomTaxonomy.fromString(json['bloom_level'] as String? ?? json['bloomLevel'] as String?),
      content: json['content'] as String? ?? '',
      contentJson: json['content_json'] as Map<String, dynamic>? ?? json['contentJson'] as Map<String, dynamic>?,
      answerOptions: _parseDynamicList(json['answer_options'] ?? json['answerOptions']),
      matchingPairs: _parseDynamicList(json['matching_pairs'] ?? json['matchingPairs']),
      orderingItems: _parseDynamicList(json['ordering_items'] ?? json['orderingItems']),
      fillInBlankAnswers: _parseDynamicList(json['fill_in_blank_answers'] ?? json['fillInBlankAnswers']),
      explanation: json['explanation'] as String?,
      suggestedReferences: _parseStringList(json['suggested_references'] ?? json['suggestedReferences']),
      marks: json['marks'] as int? ?? 1,
      estimatedTimeSeconds: json['estimated_time_seconds'] as int? ?? json['estimatedTimeSeconds'] as int?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? (json['confidenceScore'] as num?)?.toDouble(),
      curriculumAlignment: json['curriculum_alignment'] as Map<String, dynamic>? ?? json['curriculumAlignment'] as Map<String, dynamic>?,
      reviewStatus: ReviewStatus.fromString(json['review_status'] as String? ?? json['reviewStatus'] as String?) ?? ReviewStatus.pending,
      reviewedBy: json['reviewed_by'] as String? ?? json['reviewedBy'] as String?,
      reviewedAt: _parseNullableDateTime(json, 'reviewed_at', 'reviewedAt'),
      reviewNotes: json['review_notes'] as String? ?? json['reviewNotes'] as String?,
      teacherEdits: json['teacher_edits'] as Map<String, dynamic>? ?? json['teacherEdits'] as Map<String, dynamic>?,
      isEdited: json['is_edited'] as bool? ?? json['isEdited'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? json['isApproved'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generation_request_id': generationRequestId,
        'question_bank_id': questionBankId,
        'school_id': schoolId,
        'question_type': questionType.value,
        'difficulty': difficulty.value,
        'bloom_level': bloomLevel?.value,
        'content': content,
        'content_json': contentJson,
        'answer_options': answerOptions,
        'matching_pairs': matchingPairs,
        'ordering_items': orderingItems,
        'fill_in_blank_answers': fillInBlankAnswers,
        'explanation': explanation,
        'suggested_references': suggestedReferences,
        'marks': marks,
        'estimated_time_seconds': estimatedTimeSeconds,
        'confidence_score': confidenceScore,
        'curriculum_alignment': curriculumAlignment,
        'review_status': reviewStatus.value,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'review_notes': reviewNotes,
        'teacher_edits': teacherEdits,
        'is_edited': isEdited,
        'is_approved': isApproved,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory GeneratedQuestionModel.fromEntity(GeneratedQuestionEntity entity) {
    return GeneratedQuestionModel(
      id: entity.id,
      generationRequestId: entity.generationRequestId,
      questionBankId: entity.questionBankId,
      schoolId: entity.schoolId,
      questionType: entity.questionType,
      difficulty: entity.difficulty,
      bloomLevel: entity.bloomLevel,
      content: entity.content,
      contentJson: entity.contentJson,
      answerOptions: entity.answerOptions,
      matchingPairs: entity.matchingPairs,
      orderingItems: entity.orderingItems,
      fillInBlankAnswers: entity.fillInBlankAnswers,
      explanation: entity.explanation,
      suggestedReferences: entity.suggestedReferences,
      marks: entity.marks,
      estimatedTimeSeconds: entity.estimatedTimeSeconds,
      confidenceScore: entity.confidenceScore,
      curriculumAlignment: entity.curriculumAlignment,
      reviewStatus: entity.reviewStatus,
      reviewedBy: entity.reviewedBy,
      reviewedAt: entity.reviewedAt,
      reviewNotes: entity.reviewNotes,
      teacherEdits: entity.teacherEdits,
      isEdited: entity.isEdited,
      isApproved: entity.isApproved,
      metadata: entity.metadata,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GeneratedQuestionEntity toEntity() {
    return GeneratedQuestionEntity(
      id: id,
      generationRequestId: generationRequestId,
      questionBankId: questionBankId,
      schoolId: schoolId,
      questionType: questionType,
      difficulty: difficulty,
      bloomLevel: bloomLevel,
      content: content,
      contentJson: contentJson,
      answerOptions: answerOptions,
      matchingPairs: matchingPairs,
      orderingItems: orderingItems,
      fillInBlankAnswers: fillInBlankAnswers,
      explanation: explanation,
      suggestedReferences: suggestedReferences,
      marks: marks,
      estimatedTimeSeconds: estimatedTimeSeconds,
      confidenceScore: confidenceScore,
      curriculumAlignment: curriculumAlignment,
      reviewStatus: reviewStatus,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      reviewNotes: reviewNotes,
      teacherEdits: teacherEdits,
      isEdited: isEdited,
      isApproved: isApproved,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  GeneratedQuestionModel copyWith({
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
    return GeneratedQuestionModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedQuestionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reviewStatus == other.reviewStatus;

  @override
  int get hashCode => Object.hash(id, reviewStatus);
}

// ═══════════════════════════════════════════════════════════════════════
// VALIDATION RESULT MODEL
// ═══════════════════════════════════════════════════════════════════════

class ValidationResultModel {
  const ValidationResultModel({
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

  factory ValidationResultModel.fromJson(Map<String, dynamic> json) {
    return ValidationResultModel(
      id: json['id'] as String,
      generatedQuestionId: json['generated_question_id'] as String? ?? json['generatedQuestionId'] as String? ?? '',
      validationType: json['validation_type'] as String? ?? json['validationType'] as String? ?? 'general',
      severity: ValidationSeverity.fromString(json['severity'] as String?) ?? ValidationSeverity.info,
      message: json['message'] as String? ?? '',
      suggestion: json['suggestion'] as String?,
      isResolved: json['is_resolved'] as bool? ?? json['isResolved'] as bool? ?? false,
      resolvedBy: json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolvedAt: _parseNullableDateTime(json, 'resolved_at', 'resolvedAt'),
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generated_question_id': generatedQuestionId,
        'validation_type': validationType,
        'severity': severity.value,
        'message': message,
        'suggestion': suggestion,
        'is_resolved': isResolved,
        'resolved_by': resolvedBy,
        'resolved_at': resolvedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ValidationResultModel.fromEntity(ValidationResultEntity entity) {
    return ValidationResultModel(
      id: entity.id,
      generatedQuestionId: entity.generatedQuestionId,
      validationType: entity.validationType,
      severity: entity.severity,
      message: entity.message,
      suggestion: entity.suggestion,
      isResolved: entity.isResolved,
      resolvedBy: entity.resolvedBy,
      resolvedAt: entity.resolvedAt,
      createdAt: entity.createdAt,
    );
  }

  ValidationResultEntity toEntity() {
    return ValidationResultEntity(
      id: id,
      generatedQuestionId: generatedQuestionId,
      validationType: validationType,
      severity: severity,
      message: message,
      suggestion: suggestion,
      isResolved: isResolved,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      createdAt: createdAt,
    );
  }

  ValidationResultModel copyWith({
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
    return ValidationResultModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          validationType == other.validationType;

  @override
  int get hashCode => Object.hash(id, validationType);
}

// ═══════════════════════════════════════════════════════════════════════
// QUESTION IMPROVEMENT MODEL
// ═══════════════════════════════════════════════════════════════════════

class QuestionImprovementModel {
  const QuestionImprovementModel({
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

  factory QuestionImprovementModel.fromJson(Map<String, dynamic> json) {
    return QuestionImprovementModel(
      id: json['id'] as String,
      generatedQuestionId: json['generated_question_id'] as String? ?? json['generatedQuestionId'] as String? ?? '',
      improvementType: json['improvement_type'] as String? ?? json['improvementType'] as String? ?? 'general',
      provider: AiProvider.fromString(json['provider'] as String?) ?? AiProvider.openai,
      originalContent: json['original_content'] as String? ?? json['originalContent'] as String? ?? '',
      improvedContent: json['improved_content'] as String? ?? json['improvedContent'] as String? ?? '',
      originalAnswerOptions: _parseNullableDynamicList(json['original_answer_options'] ?? json['originalAnswerOptions']),
      improvedAnswerOptions: _parseNullableDynamicList(json['improved_answer_options'] ?? json['improvedAnswerOptions']),
      improvementPrompt: json['improvement_prompt'] as String? ?? json['improvementPrompt'] as String?,
      inputTokens: json['input_tokens'] as int? ?? json['inputTokens'] as int?,
      outputTokens: json['output_tokens'] as int? ?? json['outputTokens'] as int?,
      cost: (json['cost'] as num?)?.toDouble(),
      isAccepted: json['is_accepted'] as bool? ?? json['isAccepted'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generated_question_id': generatedQuestionId,
        'improvement_type': improvementType,
        'provider': provider.value,
        'original_content': originalContent,
        'improved_content': improvedContent,
        'original_answer_options': originalAnswerOptions,
        'improved_answer_options': improvedAnswerOptions,
        'improvement_prompt': improvementPrompt,
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cost': cost,
        'is_accepted': isAccepted,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  factory QuestionImprovementModel.fromEntity(QuestionImprovementEntity entity) {
    return QuestionImprovementModel(
      id: entity.id,
      generatedQuestionId: entity.generatedQuestionId,
      improvementType: entity.improvementType,
      provider: entity.provider,
      originalContent: entity.originalContent,
      improvedContent: entity.improvedContent,
      originalAnswerOptions: entity.originalAnswerOptions,
      improvedAnswerOptions: entity.improvedAnswerOptions,
      improvementPrompt: entity.improvementPrompt,
      inputTokens: entity.inputTokens,
      outputTokens: entity.outputTokens,
      cost: entity.cost,
      isAccepted: entity.isAccepted,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }

  QuestionImprovementEntity toEntity() {
    return QuestionImprovementEntity(
      id: id,
      generatedQuestionId: generatedQuestionId,
      improvementType: improvementType,
      provider: provider,
      originalContent: originalContent,
      improvedContent: improvedContent,
      originalAnswerOptions: originalAnswerOptions,
      improvedAnswerOptions: improvedAnswerOptions,
      improvementPrompt: improvementPrompt,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      isAccepted: isAccepted,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  QuestionImprovementModel copyWith({
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
    return QuestionImprovementModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionImprovementModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT UPLOAD MODEL
// ═══════════════════════════════════════════════════════════════════════

class DocumentUploadModel {
  const DocumentUploadModel({
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

  factory DocumentUploadModel.fromJson(Map<String, dynamic> json) {
    return DocumentUploadModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      uploadedBy: json['uploaded_by'] as String? ?? json['uploadedBy'] as String? ?? '',
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? json['fileSize'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String? ?? '',
      documentType: json['document_type'] as String? ?? json['documentType'] as String? ?? '',
      status: DocumentStatus.fromString(json['status'] as String?) ?? DocumentStatus.uploading,
      extractedText: json['extracted_text'] as String? ?? json['extractedText'] as String?,
      identifiedTopics: _parseDynamicList(json['identified_topics'] ?? json['identifiedTopics']),
      suggestedObjectives: _parseDynamicList(json['suggested_objectives'] ?? json['suggestedObjectives']),
      questionGenerationRequestId: json['question_generation_request_id'] as String? ?? json['questionGenerationRequestId'] as String?,
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
      processedAt: _parseNullableDateTime(json, 'processed_at', 'processedAt'),
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'uploaded_by': uploadedBy,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_size': fileSize,
        'mime_type': mimeType,
        'document_type': documentType,
        'status': status.value,
        'extracted_text': extractedText,
        'identified_topics': identifiedTopics,
        'suggested_objectives': suggestedObjectives,
        'question_generation_request_id': questionGenerationRequestId,
        'error_message': errorMessage,
        'processed_at': processedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory DocumentUploadModel.fromEntity(DocumentUploadEntity entity) {
    return DocumentUploadModel(
      id: entity.id,
      schoolId: entity.schoolId,
      uploadedBy: entity.uploadedBy,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      documentType: entity.documentType,
      status: entity.status,
      extractedText: entity.extractedText,
      identifiedTopics: entity.identifiedTopics,
      suggestedObjectives: entity.suggestedObjectives,
      questionGenerationRequestId: entity.questionGenerationRequestId,
      errorMessage: entity.errorMessage,
      processedAt: entity.processedAt,
      createdAt: entity.createdAt,
    );
  }

  DocumentUploadEntity toEntity() {
    return DocumentUploadEntity(
      id: id,
      schoolId: schoolId,
      uploadedBy: uploadedBy,
      fileName: fileName,
      fileUrl: fileUrl,
      fileSize: fileSize,
      mimeType: mimeType,
      documentType: documentType,
      status: status,
      extractedText: extractedText,
      identifiedTopics: identifiedTopics,
      suggestedObjectives: suggestedObjectives,
      questionGenerationRequestId: questionGenerationRequestId,
      errorMessage: errorMessage,
      processedAt: processedAt,
      createdAt: createdAt,
    );
  }

  DocumentUploadModel copyWith({
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
    return DocumentUploadModel(
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
      questionGenerationRequestId: questionGenerationRequestId ?? this.questionGenerationRequestId,
      errorMessage: errorMessage ?? this.errorMessage,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentUploadModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATION QUEUE MODEL
// ═══════════════════════════════════════════════════════════════════════

class GenerationQueueModel {
  const GenerationQueueModel({
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

  factory GenerationQueueModel.fromJson(Map<String, dynamic> json) {
    return GenerationQueueModel(
      id: json['id'] as String,
      generationRequestId: json['generation_request_id'] as String? ?? json['generationRequestId'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      maxAttempts: json['max_attempts'] as int? ?? json['maxAttempts'] as int? ?? 3,
      nextAttemptAt: _parseNullableDateTime(json, 'next_attempt_at', 'nextAttemptAt'),
      status: GenerationStatus.fromString(json['status'] as String?) ?? GenerationStatus.pending,
      errorMessage: json['error_message'] as String? ?? json['errorMessage'] as String?,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generation_request_id': generationRequestId,
        'priority': priority,
        'attempts': attempts,
        'max_attempts': maxAttempts,
        'next_attempt_at': nextAttemptAt?.toIso8601String(),
        'status': status.value,
        'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory GenerationQueueModel.fromEntity(GenerationQueueEntity entity) {
    return GenerationQueueModel(
      id: entity.id,
      generationRequestId: entity.generationRequestId,
      priority: entity.priority,
      attempts: entity.attempts,
      maxAttempts: entity.maxAttempts,
      nextAttemptAt: entity.nextAttemptAt,
      status: entity.status,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GenerationQueueEntity toEntity() {
    return GenerationQueueEntity(
      id: id,
      generationRequestId: generationRequestId,
      priority: priority,
      attempts: attempts,
      maxAttempts: maxAttempts,
      nextAttemptAt: nextAttemptAt,
      status: status,
      errorMessage: errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  GenerationQueueModel copyWith({
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
    return GenerationQueueModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationQueueModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// AI USAGE STATS MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiUsageStatsModel {
  const AiUsageStatsModel({
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

  factory AiUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return AiUsageStatsModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      provider: AiProvider.fromString(json['provider'] as String?) ?? AiProvider.openai,
      modelName: json['model_name'] as String? ?? json['modelName'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      totalRequests: json['total_requests'] as int? ?? json['totalRequests'] as int? ?? 0,
      successfulRequests: json['successful_requests'] as int? ?? json['successfulRequests'] as int? ?? 0,
      failedRequests: json['failed_requests'] as int? ?? json['failedRequests'] as int? ?? 0,
      totalInputTokens: json['total_input_tokens'] as int? ?? json['totalInputTokens'] as int? ?? 0,
      totalOutputTokens: json['total_output_tokens'] as int? ?? json['totalOutputTokens'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      avgGenerationTimeMs: (json['avg_generation_time_ms'] as num?)?.toDouble() ?? (json['avgGenerationTimeMs'] as num?)?.toDouble(),
      questionsGenerated: json['questions_generated'] as int? ?? json['questionsGenerated'] as int? ?? 0,
      questionsApproved: json['questions_approved'] as int? ?? json['questionsApproved'] as int? ?? 0,
      questionsRejected: json['questions_rejected'] as int? ?? json['questionsRejected'] as int? ?? 0,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'provider': provider.value,
        'model_name': modelName,
        'date': date.toIso8601String().substring(0, 10),
        'total_requests': totalRequests,
        'successful_requests': successfulRequests,
        'failed_requests': failedRequests,
        'total_input_tokens': totalInputTokens,
        'total_output_tokens': totalOutputTokens,
        'total_cost': totalCost,
        'avg_generation_time_ms': avgGenerationTimeMs,
        'questions_generated': questionsGenerated,
        'questions_approved': questionsApproved,
        'questions_rejected': questionsRejected,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiUsageStatsModel.fromEntity(AiUsageStatsEntity entity) {
    return AiUsageStatsModel(
      id: entity.id,
      schoolId: entity.schoolId,
      provider: entity.provider,
      modelName: entity.modelName,
      date: entity.date,
      totalRequests: entity.totalRequests,
      successfulRequests: entity.successfulRequests,
      failedRequests: entity.failedRequests,
      totalInputTokens: entity.totalInputTokens,
      totalOutputTokens: entity.totalOutputTokens,
      totalCost: entity.totalCost,
      avgGenerationTimeMs: entity.avgGenerationTimeMs,
      questionsGenerated: entity.questionsGenerated,
      questionsApproved: entity.questionsApproved,
      questionsRejected: entity.questionsRejected,
      createdAt: entity.createdAt,
    );
  }

  AiUsageStatsEntity toEntity() {
    return AiUsageStatsEntity(
      id: id,
      schoolId: schoolId,
      provider: provider,
      modelName: modelName,
      date: date,
      totalRequests: totalRequests,
      successfulRequests: successfulRequests,
      failedRequests: failedRequests,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCost: totalCost,
      avgGenerationTimeMs: avgGenerationTimeMs,
      questionsGenerated: questionsGenerated,
      questionsApproved: questionsApproved,
      questionsRejected: questionsRejected,
      createdAt: createdAt,
    );
  }

  AiUsageStatsModel copyWith({
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
    return AiUsageStatsModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiUsageStatsModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// AI API KEY MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiApiKeyModel {
  const AiApiKeyModel({
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

  factory AiApiKeyModel.fromJson(Map<String, dynamic> json) {
    return AiApiKeyModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String? ?? json['schoolId'] as String? ?? '',
      provider: AiProvider.fromString(json['provider'] as String?) ?? AiProvider.openai,
      encryptedKey: json['encrypted_key'] as String? ?? json['encryptedKey'] as String? ?? '',
      keyHash: json['key_hash'] as String? ?? json['keyHash'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? (json['monthlyBudget'] as num?)?.toDouble(),
      currentMonthUsage: (json['current_month_usage'] as num?)?.toDouble() ?? (json['currentMonthUsage'] as num?)?.toDouble() ?? 0.0,
      rateLimitPerMinute: json['rate_limit_per_minute'] as int? ?? json['rateLimitPerMinute'] as int? ?? 60,
      lastUsedAt: _parseNullableDateTime(json, 'last_used_at', 'lastUsedAt'),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String?,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        'provider': provider.value,
        'encrypted_key': encryptedKey,
        'key_hash': keyHash,
        'is_active': isActive,
        'monthly_budget': monthlyBudget,
        'current_month_usage': currentMonthUsage,
        'rate_limit_per_minute': rateLimitPerMinute,
        'last_used_at': lastUsedAt?.toIso8601String(),
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory AiApiKeyModel.fromEntity(AiApiKeyEntity entity) {
    return AiApiKeyModel(
      id: entity.id,
      schoolId: entity.schoolId,
      provider: entity.provider,
      encryptedKey: entity.encryptedKey,
      keyHash: entity.keyHash,
      isActive: entity.isActive,
      monthlyBudget: entity.monthlyBudget,
      currentMonthUsage: entity.currentMonthUsage,
      rateLimitPerMinute: entity.rateLimitPerMinute,
      lastUsedAt: entity.lastUsedAt,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  AiApiKeyEntity toEntity() {
    return AiApiKeyEntity(
      id: id,
      schoolId: schoolId,
      provider: provider,
      encryptedKey: encryptedKey,
      keyHash: keyHash,
      isActive: isActive,
      monthlyBudget: monthlyBudget,
      currentMonthUsage: currentMonthUsage,
      rateLimitPerMinute: rateLimitPerMinute,
      lastUsedAt: lastUsedAt,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AiApiKeyModel copyWith({
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
    return AiApiKeyModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiApiKeyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// CURRICULUM MAPPING MODEL
// ═══════════════════════════════════════════════════════════════════════

class CurriculumMappingModel {
  const CurriculumMappingModel({
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

  factory CurriculumMappingModel.fromJson(Map<String, dynamic> json) {
    return CurriculumMappingModel(
      id: json['id'] as String,
      curriculum: CurriculumType.fromString(json['curriculum'] as String?) ?? CurriculumType.custom,
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? json['topicId'] as String? ?? '',
      subtopicId: json['subtopic_id'] as String? ?? json['subtopicId'] as String?,
      classLevel: json['class_level'] as String? ?? json['classLevel'] as String?,
      curriculumCode: json['curriculum_code'] as String? ?? json['curriculumCode'] as String?,
      learningObjectives: _parseStringList(json['learning_objectives'] ?? json['learningObjectives']),
      bloomLevels: _parseBloomLevels(json['bloom_levels'] ?? json['bloomLevels']),
      suggestedDifficulty: _parseDifficulty(json['suggested_difficulty'] ?? json['suggestedDifficulty']),
      marksGuidance: json['marks_guidance'] as String? ?? json['marksGuidance'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(json, 'created_at', 'createdAt'),
      updatedAt: _parseDateTime(json, 'updated_at', 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'curriculum': curriculum.value,
        'subject_id': subjectId,
        'topic_id': topicId,
        'subtopic_id': subtopicId,
        'class_level': classLevel,
        'curriculum_code': curriculumCode,
        'learning_objectives': learningObjectives,
        'bloom_levels': bloomLevels.map((b) => b.value).toList(),
        'suggested_difficulty': suggestedDifficulty?.value,
        'marks_guidance': marksGuidance,
        'description': description,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CurriculumMappingModel.fromEntity(CurriculumMappingEntity entity) {
    return CurriculumMappingModel(
      id: entity.id,
      curriculum: entity.curriculum,
      subjectId: entity.subjectId,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      classLevel: entity.classLevel,
      curriculumCode: entity.curriculumCode,
      learningObjectives: entity.learningObjectives,
      bloomLevels: entity.bloomLevels,
      suggestedDifficulty: entity.suggestedDifficulty,
      marksGuidance: entity.marksGuidance,
      description: entity.description,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CurriculumMappingEntity toEntity() {
    return CurriculumMappingEntity(
      id: id,
      curriculum: curriculum,
      subjectId: subjectId,
      topicId: topicId,
      subtopicId: subtopicId,
      classLevel: classLevel,
      curriculumCode: curriculumCode,
      learningObjectives: learningObjectives,
      bloomLevels: bloomLevels,
      suggestedDifficulty: suggestedDifficulty,
      marksGuidance: marksGuidance,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CurriculumMappingModel copyWith({
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
    return CurriculumMappingModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurriculumMappingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════
// GENERATION INPUT MODEL
// ═══════════════════════════════════════════════════════════════════════

class GenerationInputModel {
  const GenerationInputModel({
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

  factory GenerationInputModel.fromJson(Map<String, dynamic> json) {
    return GenerationInputModel(
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      topicId: json['topic_id'] as String? ?? json['topicId'] as String? ?? '',
      subtopicId: json['subtopic_id'] as String? ?? json['subtopicId'] as String?,
      classId: json['class_id'] as String? ?? json['classId'] as String?,
      curriculum: CurriculumType.fromString(json['curriculum'] as String?),
      difficulty: _parseDifficulty(json['difficulty']) ?? DifficultyLevel.medium,
      bloomLevel: BloomTaxonomy.fromString(json['bloom_level'] as String? ?? json['bloomLevel'] as String?),
      questionType: _parseQuestionType(json['question_type'] ?? json['questionType']),
      numQuestions: json['num_questions'] as int? ?? json['numQuestions'] as int? ?? 5,
      language: json['language'] as String? ?? 'en',
      examType: _parseExamType(json['exam_type'] ?? json['examType']),
      keywords: _parseStringList(json['keywords']),
      customInstructions: json['custom_instructions'] as String? ?? json['customInstructions'] as String?,
      provider: AiProvider.fromString(json['provider'] as String?),
      promptTemplateId: json['prompt_template_id'] as String? ?? json['promptTemplateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'subject_id': subjectId,
        'topic_id': topicId,
        'subtopic_id': subtopicId,
        'class_id': classId,
        'curriculum': curriculum?.value,
        'difficulty': difficulty.value,
        'bloom_level': bloomLevel?.value,
        'question_type': questionType?.value,
        'num_questions': numQuestions,
        'language': language,
        'exam_type': examType?.value,
        'keywords': keywords,
        'custom_instructions': customInstructions,
        'provider': provider?.value,
        'prompt_template_id': promptTemplateId,
      };

  factory GenerationInputModel.fromEntity(GenerationInputEntity entity) {
    return GenerationInputModel(
      subjectId: entity.subjectId,
      topicId: entity.topicId,
      subtopicId: entity.subtopicId,
      classId: entity.classId,
      curriculum: entity.curriculum,
      difficulty: entity.difficulty,
      bloomLevel: entity.bloomLevel,
      questionType: entity.questionType,
      numQuestions: entity.numQuestions,
      language: entity.language,
      examType: entity.examType,
      keywords: entity.keywords,
      customInstructions: entity.customInstructions,
      provider: entity.provider,
      promptTemplateId: entity.promptTemplateId,
    );
  }

  GenerationInputEntity toEntity() {
    return GenerationInputEntity(
      subjectId: subjectId,
      topicId: topicId,
      subtopicId: subtopicId,
      classId: classId,
      curriculum: curriculum,
      difficulty: difficulty,
      bloomLevel: bloomLevel,
      questionType: questionType,
      numQuestions: numQuestions,
      language: language,
      examType: examType,
      keywords: keywords,
      customInstructions: customInstructions,
      provider: provider,
      promptTemplateId: promptTemplateId,
    );
  }

  GenerationInputModel copyWith({
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
    return GenerationInputModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationInputModel &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          topicId == other.topicId &&
          difficulty == other.difficulty &&
          numQuestions == other.numQuestions;

  @override
  int get hashCode => Object.hash(subjectId, topicId, difficulty, numQuestions);
}

// ═══════════════════════════════════════════════════════════════════════
// AI DASHBOARD STATS MODEL
// ═══════════════════════════════════════════════════════════════════════

class AiDashboardStatsModel {
  const AiDashboardStatsModel({
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
  final List<GenerationRequestModel> recentGenerations;
  final Map<String, double> costByProvider;
  final List<DailyUsageModel> dailyUsage;

  factory AiDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AiDashboardStatsModel(
      totalGenerated: json['total_generated'] as int? ?? json['totalGenerated'] as int? ?? 0,
      totalApproved: json['total_approved'] as int? ?? json['totalApproved'] as int? ?? 0,
      totalRejected: json['total_rejected'] as int? ?? json['totalRejected'] as int? ?? 0,
      pendingReview: json['pending_review'] as int? ?? json['pendingReview'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      totalTokensUsed: json['total_tokens_used'] as int? ?? json['totalTokensUsed'] as int? ?? 0,
      questionsByType: _parseIntMap(json['questions_by_type'] ?? json['questionsByType']),
      questionsByDifficulty: _parseIntMap(json['questions_by_difficulty'] ?? json['questionsByDifficulty']),
      questionsByBloomLevel: _parseIntMap(json['questions_by_bloom_level'] ?? json['questionsByBloomLevel']),
      avgConfidenceScore: (json['avg_confidence_score'] as num?)?.toDouble() ?? (json['avgConfidenceScore'] as num?)?.toDouble(),
      avgGenerationTimeMs: (json['avg_generation_time_ms'] as num?)?.toDouble() ?? (json['avgGenerationTimeMs'] as num?)?.toDouble(),
      recentGenerations: _parseRecentGenerations(json['recent_generations'] ?? json['recentGenerations']),
      costByProvider: _parseDoubleMap(json['cost_by_provider'] ?? json['costByProvider']),
      dailyUsage: _parseDailyUsageList(json['daily_usage'] ?? json['dailyUsage']),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_generated': totalGenerated,
        'total_approved': totalApproved,
        'total_rejected': totalRejected,
        'pending_review': pendingReview,
        'total_cost': totalCost,
        'total_tokens_used': totalTokensUsed,
        'questions_by_type': questionsByType,
        'questions_by_difficulty': questionsByDifficulty,
        'questions_by_bloom_level': questionsByBloomLevel,
        'avg_confidence_score': avgConfidenceScore,
        'avg_generation_time_ms': avgGenerationTimeMs,
        'recent_generations': recentGenerations.map((g) => g.toJson()).toList(),
        'cost_by_provider': costByProvider,
        'daily_usage': dailyUsage.map((d) => d.toJson()).toList(),
      };

  factory AiDashboardStatsModel.fromEntity(AiDashboardStatsEntity entity) {
    return AiDashboardStatsModel(
      totalGenerated: entity.totalGenerated,
      totalApproved: entity.totalApproved,
      totalRejected: entity.totalRejected,
      pendingReview: entity.pendingReview,
      totalCost: entity.totalCost,
      totalTokensUsed: entity.totalTokensUsed,
      questionsByType: Map<String, int>.from(entity.questionsByType),
      questionsByDifficulty: Map<String, int>.from(entity.questionsByDifficulty),
      questionsByBloomLevel: Map<String, int>.from(entity.questionsByBloomLevel),
      avgConfidenceScore: entity.avgConfidenceScore,
      avgGenerationTimeMs: entity.avgGenerationTimeMs,
      recentGenerations: entity.recentGenerations
          .map((g) => GenerationRequestModel.fromEntity(g))
          .toList(),
      costByProvider: Map<String, double>.from(entity.costByProvider),
      dailyUsage: entity.dailyUsage.map((d) => DailyUsageModel.fromEntity(d)).toList(),
    );
  }

  AiDashboardStatsEntity toEntity() {
    return AiDashboardStatsEntity(
      totalGenerated: totalGenerated,
      totalApproved: totalApproved,
      totalRejected: totalRejected,
      pendingReview: pendingReview,
      totalCost: totalCost,
      totalTokensUsed: totalTokensUsed,
      questionsByType: Map<String, int>.from(questionsByType),
      questionsByDifficulty: Map<String, int>.from(questionsByDifficulty),
      questionsByBloomLevel: Map<String, int>.from(questionsByBloomLevel),
      avgConfidenceScore: avgConfidenceScore,
      avgGenerationTimeMs: avgGenerationTimeMs,
      recentGenerations: recentGenerations.map((g) => g.toEntity()).toList(),
      costByProvider: Map<String, double>.from(costByProvider),
      dailyUsage: dailyUsage.map((d) => d.toEntity()).toList(),
    );
  }

  AiDashboardStatsModel copyWith({
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
    List<GenerationRequestModel>? recentGenerations,
    Map<String, double>? costByProvider,
    List<DailyUsageModel>? dailyUsage,
  }) {
    return AiDashboardStatsModel(
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiDashboardStatsModel &&
          runtimeType == other.runtimeType &&
          totalGenerated == other.totalGenerated &&
          totalApproved == other.totalApproved;

  @override
  int get hashCode => Object.hash(totalGenerated, totalApproved);
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED PARSING UTILITIES
// ═══════════════════════════════════════════════════════════════════════

DateTime _parseDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  if (json[snakeKey] != null) return DateTime.parse(json[snakeKey] as String);
  if (json[camelKey] != null) return DateTime.parse(json[camelKey] as String);
  return DateTime.now();
}

DateTime? _parseNullableDateTime(Map<String, dynamic> json, String snakeKey, String camelKey) {
  if (json[snakeKey] != null) return DateTime.parse(json[snakeKey] as String);
  if (json[camelKey] != null) return DateTime.parse(json[camelKey] as String);
  return null;
}

QuestionType? _parseQuestionType(dynamic value) {
  if (value == null) return null;
  final str = value as String;
  return QuestionType.values.cast<QuestionType?>().firstWhere(
        (t) => t?.value == str,
        orElse: () => null,
      );
}

DifficultyLevel? _parseDifficulty(dynamic value) {
  if (value == null) return null;
  final str = value as String;
  return DifficultyLevel.values.cast<DifficultyLevel?>().firstWhere(
        (d) => d?.value == str,
        orElse: () => null,
      );
}

ExamType? _parseExamType(dynamic value) {
  if (value == null) return null;
  final str = value as String;
  return ExamType.values.cast<ExamType?>().firstWhere(
        (e) => e?.value == str,
        orElse: () => null,
      );
}

List<Map<String, dynamic>> _parseDynamicList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

List<Map<String, dynamic>>? _parseNullableDynamicList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return [];
}

List<BloomTaxonomy> _parseBloomLevels(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<String>()
        .map((s) => BloomTaxonomy.fromString(s))
        .whereType<BloomTaxonomy>()
        .toList();
  }
  return [];
}

List<PromptVariableModel> _parseVariables(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((m) => PromptVariableModel.fromJson(m))
        .toList();
  }
  return [];
}

List<FewShotExampleModel> _parseFewShotExamples(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((m) => FewShotExampleModel.fromJson(m))
        .toList();
  }
  return [];
}

Map<String, int> _parseIntMap(dynamic value) {
  if (value == null) return {};
  if (value is Map) {
    return Map<String, int>.from(
      value.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );
  }
  return {};
}

Map<String, double> _parseDoubleMap(dynamic value) {
  if (value == null) return {};
  if (value is Map) {
    return Map<String, double>.from(
      value.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }
  return {};
}

List<GenerationRequestModel> _parseRecentGenerations(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((m) => GenerationRequestModel.fromJson(m))
        .toList();
  }
  return [];
}

List<DailyUsageModel> _parseDailyUsageList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((m) => DailyUsageModel.fromJson(m))
        .toList();
  }
  return [];
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
