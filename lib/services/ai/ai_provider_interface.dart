import '../../../features/ai_generator/domain/entities/ai_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI PROVIDER INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface that every AI provider must implement.
///
/// Provides a unified contract for completions (streaming and non-streaming),
/// token counting, health checks, and capability queries. All concrete
/// providers (OpenAI, Gemini, etc.) implement this interface so the
/// [AiService] orchestration layer can swap providers transparently.
abstract class AiProviderInterface {
  /// The provider type identifier.
  AiProvider get providerType;

  /// Generate a single completion (non-streaming).
  ///
  /// Returns the full result including content, token usage, model info,
  /// and generation timing.
  Future<AiCompletionResult> complete(AiCompletionRequest request);

  /// Generate a completion with streaming.
  ///
  /// Emits [AiCompletionChunk]s as they arrive from the provider.
  /// The final chunk will have [AiCompletionChunk.isDone] set to `true`
  /// and includes the total token counts.
  Stream<AiCompletionChunk> completeStream(AiCompletionRequest request);

  /// Count tokens for the given [text].
  ///
  /// Returns an estimated token count. Providers that expose a token
  /// counting endpoint should use it; otherwise a heuristic is applied.
  Future<int> countTokens(String text);

  /// Check if the provider is currently available (API key valid, no
  /// outage detected).
  Future<bool> isAvailable();

  /// Get the static capabilities of this provider.
  AiProviderCapabilities get capabilities;
}

// ═══════════════════════════════════════════════════════════════════════
// REQUEST / RESPONSE MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Request payload sent to an AI provider for completion.
class AiCompletionRequest {
  const AiCompletionRequest({
    required this.systemPrompt,
    required this.userPrompt,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.jsonMode = false,
    this.extraParams,
  });

  /// The system-level instruction that sets behaviour / persona.
  final String systemPrompt;

  /// The user-level prompt containing the actual task.
  final String userPrompt;

  /// Sampling temperature (0.0 – 2.0). `null` uses the provider default.
  final double? temperature;

  /// Maximum number of tokens to generate. `null` uses the provider default.
  final int? maxTokens;

  /// Nucleus sampling parameter. `null` uses the provider default.
  final double? topP;

  /// Whether to request JSON-structured output from the model.
  final bool jsonMode;

  /// Provider-specific extra parameters forwarded verbatim.
  final Map<String, dynamic>? extraParams;

  AiCompletionRequest copyWith({
    String? systemPrompt,
    String? userPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    bool? jsonMode,
    Map<String, dynamic>? extraParams,
  }) {
    return AiCompletionRequest(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPrompt: userPrompt ?? this.userPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      jsonMode: jsonMode ?? this.jsonMode,
      extraParams: extraParams ?? this.extraParams,
    );
  }
}

/// Result of a non-streaming completion call.
class AiCompletionResult {
  const AiCompletionResult({
    required this.content,
    this.parsedJson,
    required this.inputTokens,
    required this.outputTokens,
    required this.model,
    required this.generationTime,
    required this.provider,
  });

  /// The raw text content returned by the model.
  final String content;

  /// If the response was valid JSON and jsonMode was requested, the
  /// parsed map is stored here for convenience.
  final Map<String, dynamic>? parsedJson;

  /// Number of tokens in the prompt.
  final int inputTokens;

  /// Number of tokens in the completion.
  final int outputTokens;

  /// The model identifier used for this completion.
  final String model;

  /// Wall-clock time for the generation.
  final Duration generationTime;

  /// The provider that handled this request.
  final AiProvider provider;

  /// Total tokens consumed.
  int get totalTokens => inputTokens + outputTokens;

  AiCompletionResult copyWith({
    String? content,
    Map<String, dynamic>? parsedJson,
    int? inputTokens,
    int? outputTokens,
    String? model,
    Duration? generationTime,
    AiProvider? provider,
  }) {
    return AiCompletionResult(
      content: content ?? this.content,
      parsedJson: parsedJson ?? this.parsedJson,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      model: model ?? this.model,
      generationTime: generationTime ?? this.generationTime,
      provider: provider ?? this.provider,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCompletionResult &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          model == other.model &&
          provider == other.provider;

  @override
  int get hashCode => Object.hash(content, inputTokens, outputTokens, model, provider);

  @override
  String toString() => 'AiCompletionResult(model: $model, '
      'inputTokens: $inputTokens, outputTokens: $outputTokens, '
      'generationTime: ${generationTime.inMilliseconds}ms)';
}

/// A single chunk emitted during a streaming completion.
class AiCompletionChunk {
  const AiCompletionChunk({
    required this.delta,
    this.isDone = false,
    this.inputTokens,
    this.outputTokens,
  });

  /// The incremental text content for this chunk.
  final String delta;

  /// Whether this is the final chunk in the stream.
  final bool isDone;

  /// Token counts (available on the final chunk).
  final int? inputTokens;

  /// Token counts (available on the final chunk).
  final int? outputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiCompletionChunk &&
          runtimeType == other.runtimeType &&
          delta == other.delta &&
          isDone == other.isDone &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens;

  @override
  int get hashCode => Object.hash(delta, isDone, inputTokens, outputTokens);

  @override
  String toString() => 'AiCompletionChunk(delta: ${delta.length} chars, isDone: $isDone)';
}

/// Describes the static capabilities of an AI provider.
class AiProviderCapabilities {
  const AiProviderCapabilities({
    required this.supportsStreaming,
    required this.supportsFunctionCalling,
    required this.supportsVision,
    required this.maxContextTokens,
    required this.maxOutputTokens,
  });

  /// Whether the provider supports server-sent events / streaming.
  final bool supportsStreaming;

  /// Whether the provider supports function / tool calling.
  final bool supportsFunctionCalling;

  /// Whether the provider can process image inputs.
  final bool supportsVision;

  /// Maximum number of context tokens the provider accepts.
  final int maxContextTokens;

  /// Maximum number of tokens the provider can generate in a single request.
  final int maxOutputTokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiProviderCapabilities &&
          runtimeType == other.runtimeType &&
          supportsStreaming == other.supportsStreaming &&
          supportsFunctionCalling == other.supportsFunctionCalling &&
          supportsVision == other.supportsVision &&
          maxContextTokens == other.maxContextTokens &&
          maxOutputTokens == other.maxOutputTokens;

  @override
  int get hashCode => Object.hash(
        supportsStreaming,
        supportsFunctionCalling,
        supportsVision,
        maxContextTokens,
        maxOutputTokens,
      );

  @override
  String toString() => 'AiProviderCapabilities(streaming: $supportsStreaming, '
      'functionCalling: $supportsFunctionCalling, vision: $supportsVision, '
      'maxContext: $maxContextTokens, maxOutput: $maxOutputTokens)';
}
