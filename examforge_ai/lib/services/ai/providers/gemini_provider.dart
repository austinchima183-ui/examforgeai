import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/utils/logger.dart';
import '../../../features/ai_generator/domain/entities/ai_entities.dart';
import '../ai_provider_interface.dart';

// ═══════════════════════════════════════════════════════════════════════
// GOOGLE GEMINI PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Concrete [AiProviderInterface] implementation for Google Gemini APIs.
///
/// Supports:
/// - Gemini 1.5 Pro, Gemini 1.5 Flash (configurable via [defaultModel])
/// - Non-streaming via `generateContent`
/// - Streaming via `streamGenerateContent` (SSE)
/// - JSON output mode (`responseMimeType: "application/json"`)
/// - Token counting estimation
/// - Proper error handling (rate limits, auth, safety filters)
class GeminiProvider implements AiProviderInterface {
  GeminiProvider({
    required String apiKey,
    String baseUrl =
        'https://generativelanguage.googleapis.com/v1beta',
    this.defaultModel = 'gemini-1.5-pro',
    Dio? dio,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  final String _apiKey;
  final String _baseUrl;
  final String defaultModel;
  final Dio _dio;

  // ─── Capability table per model ────────────────────────────────────

  static const Map<String, _GeminiModelSpec> _modelSpecs = {
    'gemini-1.5-pro': _GeminiModelSpec(
      maxContext: 2_097_152,
      maxOutput: 8_192,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gemini-1.5-flash': _GeminiModelSpec(
      maxContext: 1_048_576,
      maxOutput: 8_192,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gemini-1.5-flash-8b': _GeminiModelSpec(
      maxContext: 1_048_576,
      maxOutput: 8_192,
      streaming: true,
      functionCalling: true,
      vision: true,
    ),
    'gemini-pro': _GeminiModelSpec(
      maxContext: 32_768,
      maxOutput: 2_048,
      streaming: true,
      functionCalling: false,
      vision: false,
    ),
  };

  // ─── AiProviderInterface ──────────────────────────────────────────

  @override
  AiProvider get providerType => AiProvider.gemini;

  @override
  AiProviderCapabilities get capabilities {
    final spec = _modelSpecs[defaultModel] ??
        const _GeminiModelSpec(
          maxContext: 1_048_576,
          maxOutput: 8_192,
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
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/models/$defaultModel',
        queryParameters: {'key': _apiKey},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      AppLogger.warning('Gemini availability check failed', error: e);
      return false;
    } catch (e) {
      AppLogger.warning('Gemini availability check failed', error: e);
      return false;
    }
  }

  // ─── Non-streaming completion ─────────────────────────────────────

  @override
  Future<AiCompletionResult> complete(AiCompletionRequest request) async {
    final stopwatch = Stopwatch()..start();

    try {
      final body = _buildRequestBody(request);
      AppLogger.debug('Gemini complete request: model=$defaultModel, '
          'jsonMode=${request.jsonMode}');

      final response = await _dio.post<Map<String, dynamic>>(
        '/models/$defaultModel:generateContent',
        data: body,
        queryParameters: {'key': _apiKey},
      );

      stopwatch.stop();

      final data = response.data!;
      final candidates = data['candidates'] as List<dynamic>?;
      final usageMetadata = data['usageMetadata'] as Map<String, dynamic>?;

      String content = '';
      if (candidates != null && candidates.isNotEmpty) {
        final parts = (candidates.first['content'] as Map<String, dynamic>?)?['parts']
            as List<dynamic>? ??
            [];
        final textParts = parts
            .whereType<Map<String, dynamic>>()
            .where((p) => p.containsKey('text'))
            .map((p) => p['text'] as String)
            .toList();
        content = textParts.join('');
      }

      Map<String, dynamic>? parsedJson;
      if (request.jsonMode) {
        parsedJson = _tryParseJson(content);
      }

      return AiCompletionResult(
        content: content,
        parsedJson: parsedJson,
        inputTokens:
            (usageMetadata?['promptTokenCount'] as int?) ??
                (usageMetadata?['prompt_token_count'] as int?) ??
                0,
        outputTokens:
            (usageMetadata?['candidatesTokenCount'] as int?) ??
                (usageMetadata?['candidates_token_count'] as int?) ??
                0,
        model: defaultModel,
        generationTime: stopwatch.elapsed,
        provider: AiProvider.gemini,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      throw _mapDioException(e);
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Gemini complete failed', error: e);
      rethrow;
    }
  }

  // ─── Streaming completion ─────────────────────────────────────────

  @override
  Stream<AiCompletionChunk> completeStream(AiCompletionRequest request) async* {
    final body = _buildRequestBody(request);
    AppLogger.debug('Gemini stream request: model=$defaultModel');

    final controller = StreamController<AiCompletionChunk>();

    try {
      final response = await _dio.post<ResponseBody>(
        '/models/$defaultModel:streamGenerateContent?alt=sse',
        data: body,
        queryParameters: {'key': _apiKey},
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.startsWith('data: ')) continue;

          final jsonStr = trimmed.substring(6);
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final candidates = json['candidates'] as List<dynamic>?;

            if (candidates != null && candidates.isNotEmpty) {
              final parts = (candidates.first['content']
                      as Map<String, dynamic>?)?['parts'] as List<dynamic>? ??
                  [];

              for (final part in parts) {
                if (part is Map<String, dynamic> && part.containsKey('text')) {
                  final text = part['text'] as String;
                  if (text.isNotEmpty) {
                    controller.add(AiCompletionChunk(delta: text));
                  }
                }
              }

              // Check for finish reason
              final finishReason =
                  candidates.first['finishReason'] as String?;
              if (finishReason == 'STOP') {
                final usageMetadata =
                    json['usageMetadata'] as Map<String, dynamic>?;
                controller.add(AiCompletionChunk(
                  delta: '',
                  isDone: true,
                  inputTokens: usageMetadata?['promptTokenCount'] as int?,
                  outputTokens: usageMetadata?['candidatesTokenCount'] as int?,
                ));
              }
            }
          } on FormatException {
            AppLogger.debug('Skipping malformed SSE chunk: $jsonStr');
          }
        }
      }

      // Safety: emit done if stream ended without explicit STOP
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

  // ─── Token counting ───────────────────────────────────────────────

  @override
  Future<int> countTokens(String text) async {
    // Gemini uses a similar tokenization approach to other LLMs.
    // Estimation: ~4 characters per token for English text.
    // Gemini models have very large context windows so the estimation
    // is less critical for context-length checks.
    int estimatedTokens = (text.length / 4).ceil();

    // Adjust for special characters
    final specialCharCount = RegExp(r'[^\w\s]').allMatches(text).length;
    estimatedTokens += (specialCharCount / 3).ceil();

    // Try using the countTokens endpoint if possible
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/models/$defaultModel:countTokens',
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [{'text': text}],
            },
          ],
        },
        queryParameters: {'key': _apiKey},
      );
      final totalTokens =
          response.data?['totalTokens'] as int?;
      if (totalTokens != null) return totalTokens;
    } on DioException catch (e) {
      AppLogger.debug('Gemini countTokens endpoint failed, '
          'falling back to estimation', error: e);
    } catch (e) {
      AppLogger.debug('Gemini countTokens endpoint failed, '
          'falling back to estimation', error: e);
    }

    return estimatedTokens.clamp(1, capabilities.maxContextTokens);
  }

  // ─── Private helpers ──────────────────────────────────────────────

  /// Builds the request body in Gemini's content format.
  Map<String, dynamic> _buildRequestBody(AiCompletionRequest request) {
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': request.userPrompt}],
        },
      ],
    };

    // Build system instruction if provided
    if (request.systemPrompt.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [{'text': request.systemPrompt}],
      };
    }

    // Generation config
    final generationConfig = <String, dynamic>{};

    if (request.temperature != null) {
      generationConfig['temperature'] = request.temperature!;
    }
    if (request.maxTokens != null) {
      generationConfig['maxOutputTokens'] = request.maxTokens!;
    }
    if (request.topP != null) {
      generationConfig['topP'] = request.topP!;
    }
    if (request.jsonMode) {
      generationConfig['responseMimeType'] = 'application/json';
    }

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    if (request.extraParams != null) {
      // Merge extra params at the top level
      body.addAll(request.extraParams!);
    }

    return body;
  }

  /// Maps a [DioException] to a domain-appropriate exception.
  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = e.message ?? 'Unknown error';

    // Gemini returns errors in { error: { message, status, code } }
    if (data is Map<String, dynamic>) {
      final error = data['error'] as Map<String, dynamic>?;
      if (error != null) {
        message = error['message'] as String? ?? message;
      }
    } else if (data is String) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        if (message.contains('API key not valid') ||
            message.contains('API_KEY_INVALID')) {
          return Exception('Gemini authentication failed: $message');
        }
        return Exception('Gemini bad request: $message');
      case 401:
      case 403:
        return Exception('Gemini authentication/authorization failed: $message');
      case 429:
        return Exception('Gemini rate limit exceeded: $message');
      case 500:
      case 502:
      case 503:
        return Exception('Gemini server error ($statusCode): $message');
      default:
        return Exception('Gemini request failed ($statusCode): $message');
    }
  }

  /// Attempts to parse a JSON string, returning null on failure.
  Map<String, dynamic>? _tryParseJson(String content) {
    try {
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
          final decoded =
              jsonDecode(content.substring(braceStart, braceEnd + 1));
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

class _GeminiModelSpec {
  const _GeminiModelSpec({
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
