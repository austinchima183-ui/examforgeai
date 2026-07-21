import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/utils/logger.dart';
import '../../../features/ai_generator/domain/entities/ai_entities.dart';
import '../ai_provider_interface.dart';

// ═══════════════════════════════════════════════════════════════════════
// OPENAI PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Concrete [AiProviderInterface] implementation for OpenAI APIs.
///
/// Supports:
/// - GPT-4o, GPT-4o-mini (configurable via [defaultModel])
/// - Non-streaming completions via `/v1/chat/completions`
/// - Streaming completions via SSE on the same endpoint
/// - JSON mode for structured output (`response_format: { type: "json_object" }`)
/// - Token counting estimation (BPE-like heuristic)
/// - Rate-limit, auth, and context-length error handling
class OpenAiProvider implements AiProviderInterface {
  OpenAiProvider({
    String? apiKey,
    String baseUrl = 'https://api.openai.com/v1',
    this.defaultModel = 'gpt-4o',
    sb.SupabaseClient? supabaseClient,
    Dio? dio,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _supabaseClient = supabaseClient,
        _dio = dio ?? (apiKey != null && apiKey.isNotEmpty
            ? Dio(BaseOptions(
                baseUrl: baseUrl,
                headers: {
                  'Authorization': 'Bearer $apiKey',
                  'Content-Type': 'application/json',
                },
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
              ))
            : Dio());

  final String? _apiKey;
  final String _baseUrl;
  final sb.SupabaseClient? _supabaseClient;
  final String defaultModel;
  final Dio _dio;

  /// Whether to route AI calls through Supabase Edge Functions.
  bool get _useEdgeFunctions =>
      (_apiKey == null || _apiKey!.isEmpty) && _supabaseClient != null;

  // ─── Edge Function Names ──────────────────────────────────────────
  static const _aiCompleteFunction = 'ai-complete';
  static const _aiStreamFunction = 'ai-stream';

  // ─── Capability table per model ────────────────────────────────────

  static const Map<String, _ModelSpec> _modelSpecs = {
    'gpt-4o': _ModelSpec(
      maxContext: 128000,
      maxOutput: 16384,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gpt-4o-mini': _ModelSpec(
      maxContext: 128000,
      maxOutput: 16384,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gpt-4-turbo': _ModelSpec(
      maxContext: 128000,
      maxOutput: 4096,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gpt-4': _ModelSpec(
      maxContext: 8192,
      maxOutput: 8192,
      streaming: true,
      functionCalling: true,
      vision: false,
    ),
    'gpt-3.5-turbo': _ModelSpec(
      maxContext: 16385,
      maxOutput: 4096,
      streaming: true,
      functionCalling: true,
      vision: false,
    ),
  };

  // ─── AiProviderInterface ──────────────────────────────────────────

  @override
  AiProvider get providerType => AiProvider.openai;

  @override
  AiProviderCapabilities get capabilities {
    final spec = _modelSpecs[defaultModel] ??
        const _ModelSpec(
          maxContext: 128000,
          maxOutput: 16384,
          streaming: true,
          functionCalling: true,
          vision: true,
        );
    return AiProviderCapabilities(
      supportsStreaming: spec.streaming,
      supportsFunctionCalling: spec.functionCalling,
      supportsVision: spec.vision,
      maxContextTokens: spec.maxContext,
      maxOutputTokens: spec.maxOutput,
    );
  }

  @override
  Future<bool> isAvailable() async {
    if (_useEdgeFunctions) {
      try {
        final response = await _supabaseClient!.functions.invoke(
          _aiCompleteFunction,
          body: {'action': 'health_check', 'provider': 'openai'},
        );
        return response.status == 200;
      } catch (e) {
        AppLogger.warning('OpenAI Edge Function availability check failed', error: e);
        return false;
      }
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>('/models');
      return response.statusCode == 200;
    } on DioException catch (e) {
      AppLogger.warning('OpenAI availability check failed', error: e);
      return false;
    } catch (e) {
      AppLogger.warning('OpenAI availability check failed', error: e);
      return false;
    }
  }

  // ─── Non-streaming completion ─────────────────────────────────────

  @override
  Future<AiCompletionResult> complete(AiCompletionRequest request) async {
    final stopwatch = Stopwatch()..start();

    // ─── Route through Edge Function if no API key ──────────────────
    if (_useEdgeFunctions) {
      return _completeViaEdgeFunction(request, stopwatch);
    }

    try {
      final body = _buildRequestBody(request, stream: false);
      AppLogger.debug('OpenAI complete request: model=${body['model']}, '
          'jsonMode=${request.jsonMode}');

      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: body,
      );

      stopwatch.stop();

      final data = response.data!;
      final usage = data['usage'] as Map<String, dynamic>?;
      final choices = data['choices'] as List<dynamic>;
      final content = (choices.first['message'] as Map<String, dynamic>)['content']
          as String;

      Map<String, dynamic>? parsedJson;
      if (request.jsonMode) {
        parsedJson = _tryParseJson(content);
      }

      return AiCompletionResult(
        content: content,
        parsedJson: parsedJson,
        inputTokens: (usage?['prompt_tokens'] as int?) ?? 0,
        outputTokens: (usage?['completion_tokens'] as int?) ?? 0,
        model: data['model'] as String? ?? defaultModel,
        generationTime: stopwatch.elapsed,
        provider: AiProvider.openai,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      throw _mapDioException(e);
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('OpenAI complete failed', error: e);
      rethrow;
    }
  }

  /// Complete via Supabase Edge Function (server-side API key).
  Future<AiCompletionResult> _completeViaEdgeFunction(
    AiCompletionRequest request,
    Stopwatch stopwatch,
  ) async {
    try {
      final response = await _supabaseClient!.functions.invoke(
        _aiCompleteFunction,
        body: {
          'provider': 'openai',
          'model': defaultModel,
          'system_prompt': request.systemPrompt,
          'user_prompt': request.userPrompt,
          'temperature': request.temperature,
          'max_tokens': request.maxTokens,
          'top_p': request.topP,
          'json_mode': request.jsonMode,
          'extra_params': request.extraParams,
        },
      );

      stopwatch.stop();

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String? ?? 'OpenAI Edge Function failed.'
            : 'OpenAI Edge Function failed.';
        throw Exception('OpenAI Edge Function error: $message');
      }

      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as String? ?? '';

      Map<String, dynamic>? parsedJson;
      if (request.jsonMode) {
        parsedJson = _tryParseJson(content);
      }

      return AiCompletionResult(
        content: content,
        parsedJson: parsedJson,
        inputTokens: data['input_tokens'] as int? ?? 0,
        outputTokens: data['output_tokens'] as int? ?? 0,
        model: data['model'] as String? ?? defaultModel,
        generationTime: stopwatch.elapsed,
        provider: AiProvider.openai,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is Exception) rethrow;
      AppLogger.error('OpenAI Edge Function complete failed', error: e);
      throw Exception('OpenAI Edge Function complete failed: $e');
    }
  }

  // ─── Streaming completion ─────────────────────────────────────────

  @override
  Stream<AiCompletionChunk> completeStream(AiCompletionRequest request) async* {
    // ─── Route through Edge Function if no API key ──────────────────
    if (_useEdgeFunctions) {
      yield* _completeStreamViaEdgeFunction(request);
      return;
    }

    final body = _buildRequestBody(request, stream: true);
    AppLogger.debug('OpenAI stream request: model=${body['model']}');

    final controller = StreamController<AiCompletionChunk>();

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: body,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${_apiKey ?? ''}',
            'Content-Type': 'application/json',
          },
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line in buffer

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed == 'data: [DONE]') {
            if (trimmed == 'data: [DONE]') {
              controller.add(const AiCompletionChunk(delta: '', isDone: true));
            }
            continue;
          }
          if (!trimmed.startsWith('data: ')) continue;

          final jsonStr = trimmed.substring(6);
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final finishReason = choices[0]['finish_reason'] as String?;
            final content = delta?['content'] as String? ?? '';

            if (content.isNotEmpty) {
              controller.add(AiCompletionChunk(delta: content));
            }

            if (finishReason == 'stop') {
              // Try to extract usage from the final chunk if available
              final usage = json['usage'] as Map<String, dynamic>?;
              controller.add(AiCompletionChunk(
                delta: '',
                isDone: true,
                inputTokens: usage?['prompt_tokens'] as int?,
                outputTokens: usage?['completion_tokens'] as int?,
              ));
            }
          } on FormatException {
            // Skip malformed JSON in stream
            AppLogger.debug('Skipping malformed SSE chunk: $jsonStr');
          }
        }
      }

      // If stream ended without DONE, emit a done chunk
      if (!controller.isClosed) {
        controller.add(const AiCompletionChunk(delta: '', isDone: true));
      }
    } on DioException catch (e) {
      controller.addError(_mapDioException(e));
    } catch (e) {
      controller.addError(e);
    } finally {
      await controller.close();
    }

    yield* controller.stream;
  }

  /// Stream completion via Supabase Edge Function.
  ///
  /// The Edge Function returns a non-streaming response; we emit it as
  /// a single chunk followed by a done chunk. True SSE streaming from
  /// Edge Functions requires the `ai-stream` function to support SSE,
  /// which can be added in a future iteration.
  Stream<AiCompletionChunk> _completeStreamViaEdgeFunction(
    AiCompletionRequest request,
  ) async* {
    try {
      final response = await _supabaseClient!.functions.invoke(
        _aiStreamFunction,
        body: {
          'provider': 'openai',
          'model': defaultModel,
          'system_prompt': request.systemPrompt,
          'user_prompt': request.userPrompt,
          'temperature': request.temperature,
          'max_tokens': request.maxTokens,
          'top_p': request.topP,
          'json_mode': request.jsonMode,
          'extra_params': request.extraParams,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final message = data is Map<String, dynamic>
            ? data['message'] as String? ?? 'OpenAI stream Edge Function failed.'
            : 'OpenAI stream Edge Function failed.';
        throw Exception('OpenAI Edge Function stream error: $message');
      }

      final data = response.data as Map<String, dynamic>;
      final content = data['content'] as String? ?? '';

      // Emit content as a single chunk
      if (content.isNotEmpty) {
        yield AiCompletionChunk(delta: content);
      }

      // Emit done chunk with token counts
      yield AiCompletionChunk(
        delta: '',
        isDone: true,
        inputTokens: data['input_tokens'] as int?,
        outputTokens: data['output_tokens'] as int?,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      AppLogger.error('OpenAI Edge Function stream failed', error: e);
      throw Exception('OpenAI Edge Function stream failed: $e');
    }
  }

  // ─── Token counting ───────────────────────────────────────────────

  @override
  Future<int> countTokens(String text) async {
    // Estimation heuristic: ~4 characters per token for English text.
    // This is a rough approximation; for exact counts, a tiktoken
    // implementation would be needed.
    //
    // The heuristic accounts for:
    // - English text averages ~4 chars per token
    // - Code and special characters tend to use more tokens
    // - Whitespace is generally collapsed
    int estimatedTokens = (text.length / 4).ceil();

    // Adjust for common patterns that inflate token counts
    final specialCharCount = RegExp(r'[^\w\s]').allMatches(text).length;
    estimatedTokens += (specialCharCount / 3).ceil();

    // Clamp to a reasonable minimum
    return estimatedTokens.clamp(1, capabilities.maxContextTokens);
  }

  // ─── Private helpers ──────────────────────────────────────────────

  /// Builds the JSON body for a chat completion request.
  Map<String, dynamic> _buildRequestBody(
    AiCompletionRequest request, {
    required bool stream,
  }) {
    final body = <String, dynamic>{
      'model': defaultModel,
      'messages': [
        {'role': 'system', 'content': request.systemPrompt},
        {'role': 'user', 'content': request.userPrompt},
      ],
      'stream': stream,
    };

    if (request.temperature != null) {
      body['temperature'] = request.temperature!;
    }
    if (request.maxTokens != null) {
      body['max_tokens'] = request.maxTokens!;
    }
    if (request.topP != null) {
      body['top_p'] = request.topP!;
    }
    if (request.jsonMode) {
      body['response_format'] = const {'type': 'json_object'};
    }
    if (request.extraParams != null) {
      body.addAll(request.extraParams!);
    }

    return body;
  }

  /// Maps a [DioException] to a domain-appropriate exception.
  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data is Map
        ? (e.response?.data as Map)['error'] is Map
            ? ((e.response?.data as Map)['error'] as Map)['message'] as String? ??
                e.message
            : e.message
        : e.message;

    switch (statusCode) {
      case 401:
        return Exception('OpenAI authentication failed: $message');
      case 403:
        return Exception('OpenAI access forbidden: $message');
      case 429:
        return Exception('OpenAI rate limit exceeded: $message');
      case 400:
        // Context length exceeded is a 400 with specific error
        final errorMsg = message ?? '';
        if (errorMsg.contains('context_length_exceeded') ||
            errorMsg.contains('maximum context length')) {
          return Exception('OpenAI context length exceeded: $message');
        }
        return Exception('OpenAI bad request: $message');
      case 500:
      case 502:
      case 503:
        return Exception('OpenAI server error ($statusCode): $message');
      default:
        return Exception('OpenAI request failed ($statusCode): $message');
    }
  }

  /// Attempts to parse a JSON string, returning null on failure.
  Map<String, dynamic>? _tryParseJson(String content) {
    try {
      // Try direct parse
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } on FormatException {
      // Try extracting JSON from markdown code blocks
      final jsonBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final match = jsonBlockRegex.firstMatch(content);
      if (match != null) {
        try {
          final decoded = jsonDecode(match.group(1)!.trim());
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } on FormatException {
          // Second attempt failed
        }
      }

      // Try finding first { ... } block
      final braceStart = content.indexOf('{');
      final braceEnd = content.lastIndexOf('}');
      if (braceStart != -1 && braceEnd > braceStart) {
        try {
          final decoded = jsonDecode(content.substring(braceStart, braceEnd + 1));
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } on FormatException {
          // Third attempt failed
        }
      }
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INTERNAL MODEL SPEC
// ═══════════════════════════════════════════════════════════════════════

class _ModelSpec {
  const _ModelSpec({
    required this.maxContext,
    required this.maxOutput,
    required this.streaming,
    required this.functionCalling,
    required this.vision,
  });

  final int maxContext;
  final int maxOutput;
  final bool streaming;
  final bool functionCalling;
  final bool vision;
}
