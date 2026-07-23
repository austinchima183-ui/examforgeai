import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../core/utils/logger.dart';
import '../../features/ai_generator/domain/entities/ai_entities.dart';
import 'ai_provider_interface.dart';
import 'providers/gemini_provider.dart';
import 'providers/openai_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI PROVIDERS REGISTRY
// ═══════════════════════════════════════════════════════════════════════

/// Registry for managing AI provider instances.
///
/// Provides a central store for all registered providers, with lookup
/// by provider type. This enables the [AiService] to dynamically
/// select and switch between providers at runtime.
///
/// Usage:
/// ```dart
/// final registry = AiProvidersRegistry.createDefault(
///   openaiApiKey: 'sk-...',
///   geminiApiKey: 'AI...',
/// );
///
/// final openai = registry.get(AiProvider.openai);
/// final result = await openai!.complete(request);
/// ```
class AiProvidersRegistry {
  AiProvidersRegistry() : _providers = {};

  final Map<AiProvider, AiProviderInterface> _providers;

  // ─── Registration ─────────────────────────────────────────────────

  /// Register a provider instance.
  ///
  /// If a provider of the same type is already registered, it will be
  /// replaced and a warning will be logged.
  void register(AiProviderInterface provider) {
    final type = provider.providerType;
    if (_providers.containsKey(type)) {
      AppLogger.warning('Replacing existing provider for $type');
    }
    _providers[type] = provider;
    AppLogger.info('Registered AI provider: ${type.displayName}');
  }

  /// Unregister a provider by type.
  ///
  /// Returns `true` if a provider was removed, `false` if none was
  /// registered for the given type.
  bool unregister(AiProvider type) {
    final removed = _providers.remove(type) != null;
    if (removed) {
      AppLogger.info('Unregistered AI provider: ${type.displayName}');
    }
    return removed;
  }

  // ─── Lookup ───────────────────────────────────────────────────────

  /// Get a provider by type, or `null` if not registered.
  AiProviderInterface? get(AiProvider type) => _providers[type];

  /// Get a provider by type, throwing if not registered.
  AiProviderInterface require(AiProvider type) {
    final provider = _providers[type];
    if (provider == null) {
      throw StateError('No provider registered for ${type.displayName}');
    }
    return provider;
  }

  // ─── Collections ──────────────────────────────────────────────────

  /// All registered providers.
  List<AiProviderInterface> get all => List.unmodifiable(_providers.values);

  /// All active (currently available) providers.
  ///
  /// This performs an async health check on each registered provider
  /// and returns only those that respond successfully.
  Future<List<AiProviderInterface>> get active async {
    final results = <AiProviderInterface>[];
    for (final provider in _providers.values) {
      try {
        if (await provider.isAvailable()) {
          results.add(provider);
        }
      } catch (e) {
        AppLogger.warning(
            'Provider ${provider.providerType.displayName} health check failed',
            error: e,);
      }
    }
    return results;
  }

  /// The number of registered providers.
  int get count => _providers.length;

  /// Whether any providers are registered.
  bool get isEmpty => _providers.isEmpty;

  /// Whether any providers are registered.
  bool get isNotEmpty => _providers.isNotEmpty;

  /// The types of all registered providers.
  List<AiProvider> get registeredTypes =>
      List.unmodifiable(_providers.keys);

  // ─── Factory Constructors ─────────────────────────────────────────

  /// Create a registry with the default set of providers.
  ///
  /// Currently supports OpenAI and Gemini. Additional providers
  /// (Claude, DeepSeek, Grok, Local LLM) can be registered manually.
  ///
  /// When API keys are provided, providers make direct API calls.
  /// When API keys are absent but [supabaseClient] is provided,
  /// providers route calls through Supabase Edge Functions.
  static AiProvidersRegistry createDefault({
    String? openaiApiKey,
    String? geminiApiKey,
    sb.SupabaseClient? supabaseClient,
    String openaiBaseUrl = 'https://api.openai.com/v1',
    String geminiBaseUrl =
        'https://generativelanguage.googleapis.com/v1beta',
    String openaiModel = 'gpt-4o',
    String geminiModel = 'gemini-1.5-pro',
  }) {
    final registry = AiProvidersRegistry();

    final hasOpenai = openaiApiKey != null && openaiApiKey.isNotEmpty;
    final hasGemini = geminiApiKey != null && geminiApiKey.isNotEmpty;
    final hasEdgeFunctions = supabaseClient != null;

    // Register OpenAI provider
    if (hasOpenai || hasEdgeFunctions) {
      registry.register(OpenAiProvider(
        apiKey: openaiApiKey,
        baseUrl: openaiBaseUrl,
        defaultModel: openaiModel,
        supabaseClient: supabaseClient,
      ),);
    } else {
      AppLogger.warning('No OpenAI API key or Supabase client; skipping OpenAI registration');
    }

    // Register Gemini provider
    if (hasGemini || hasEdgeFunctions) {
      registry.register(GeminiProvider(
        apiKey: geminiApiKey,
        baseUrl: geminiBaseUrl,
        defaultModel: geminiModel,
        supabaseClient: supabaseClient,
      ),);
    } else {
      AppLogger.warning('No Gemini API key or Supabase client; skipping Gemini registration');
    }

    return registry;
  }

  /// Create an empty registry with no providers.
  static AiProvidersRegistry createEmpty() => AiProvidersRegistry();

  // ─── Debug ────────────────────────────────────────────────────────

  @override
  String toString() {
    return 'AiProvidersRegistry(providers: ${_providers.keys.map((p) => p.displayName).join(", ")})';
  }
}
