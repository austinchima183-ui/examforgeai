import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_config.dart';
import '../config/env_config.dart';
import '../config/supabase_config.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/utils/logger.dart';
import '../features/ai_generator/data/datasources/ai_generator_remote_datasource.dart';
import '../features/ai_generator/data/repositories/ai_generator_repository_impl.dart';
import '../features/ai_generator/domain/repositories/ai_generator_repository.dart';
import '../features/ai_generator/domain/usecases/generate_questions_usecase.dart';
import '../features/ai_generator/domain/usecases/get_ai_dashboard_stats_usecase.dart';
import '../features/ai_generator/domain/usecases/get_generation_history_usecase.dart';
import '../features/ai_generator/domain/usecases/improve_question_usecase.dart';
import '../features/ai_generator/domain/usecases/manage_prompt_templates_usecase.dart';
import '../features/ai_generator/domain/usecases/review_generated_question_usecase.dart';
import '../features/ai_generator/domain/usecases/save_to_question_bank_usecase.dart';
import '../features/ai_generator/domain/usecases/upload_document_usecase.dart';
import '../features/ai_generator/domain/usecases/validate_question_usecase.dart';
import '../features/ai_generator/presentation/providers/ai_document_provider.dart';
import '../features/ai_generator/presentation/providers/ai_generator_provider.dart';
import '../features/ai_generator/presentation/providers/ai_review_provider.dart';
import '../features/ai_generator/presentation/providers/ai_stats_provider.dart';
import '../features/ai_generator/presentation/providers/prompt_template_provider.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/signup_usecase.dart';
import '../features/auth/presentation/providers/auth_form_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/cbt_engine/data/datasources/cbt_remote_datasource.dart';
import '../features/cbt_engine/data/repositories/cbt_repository_impl.dart';
import '../features/cbt_engine/domain/repositories/cbt_repository.dart';
import '../features/cbt_engine/domain/usecases/create_exam_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_exam_results_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_exam_statistics_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_live_exam_stats_usecase.dart';
import '../features/cbt_engine/domain/usecases/grade_exam_usecase.dart';
import '../features/cbt_engine/domain/usecases/manage_exam_status_usecase.dart';
import '../features/cbt_engine/domain/usecases/save_answer_usecase.dart';
import '../features/cbt_engine/domain/usecases/start_exam_attempt_usecase.dart';
import '../features/cbt_engine/domain/usecases/submit_exam_attempt_usecase.dart';
import '../features/cbt_engine/domain/usecases/update_exam_usecase.dart';
import '../features/cbt_engine/presentation/providers/exam_builder_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_list_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_monitor_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_results_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_taker_provider.dart';
import '../features/cbt_engine/presentation/providers/student_exams_provider.dart';
import '../features/question_bank/data/datasources/question_bank_remote_datasource.dart';
import '../features/question_bank/data/repositories/question_bank_repository_impl.dart';
import '../features/question_bank/domain/repositories/question_bank_repository.dart';
import '../features/question_bank/domain/usecases/create_question_usecase.dart';
import '../features/question_bank/domain/usecases/delete_question_usecase.dart';
import '../features/question_bank/domain/usecases/export_questions_usecase.dart';
import '../features/question_bank/domain/usecases/get_question_detail_usecase.dart';
import '../features/question_bank/domain/usecases/get_question_stats_usecase.dart';
import '../features/question_bank/domain/usecases/get_questions_usecase.dart';
import '../features/question_bank/domain/usecases/import_questions_usecase.dart';
import '../features/question_bank/domain/usecases/manage_collections_usecase.dart';
import '../features/question_bank/domain/usecases/manage_question_status_usecase.dart';
import '../features/question_bank/domain/usecases/search_questions_usecase.dart';
import '../features/question_bank/domain/usecases/update_question_usecase.dart';
import '../features/question_bank/presentation/providers/collection_provider.dart';
import '../features/question_bank/presentation/providers/import_export_provider.dart';
import '../features/question_bank/presentation/providers/question_bank_stats_provider.dart';
import '../features/question_bank/presentation/providers/question_editor_provider.dart';
import '../features/question_bank/presentation/providers/question_filter_provider.dart';
import '../features/question_bank/presentation/providers/question_provider.dart';
import '../services/ai/ai_providers_registry.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/prompt_engine.dart';
import '../services/ai/providers/gemini_provider.dart';
import '../services/ai/providers/openai_provider.dart';
import '../services/ai/validation_engine.dart';
import '../services/auth_service.dart';
import '../services/cbt/anti_cheat_service.dart';
import '../services/cbt/auto_save_service.dart';
import '../services/cbt/exam_timer_service.dart';
import '../services/cbt/realtime_service.dart';
import '../services/cbt/result_processor.dart';
import '../services/cbt/session_recovery_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

// ═══════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the Supabase client singleton.
///
/// Depends on [SupabaseConfig.initialize] having been called in `main()`.
final supabaseClientProvider = Provider<sb.SupabaseClient>((ref) {
  try {
    return SupabaseConfig.client;
  } catch (e) {
    AppLogger.error('Failed to resolve Supabase client', error: e);
    rethrow;
  }
});

/// Provides a configured [Dio] instance with base options pulled from
/// [AppConfig] and [ApiConstants].
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeoutDuration,
      receiveTimeout: AppConfig.receiveTimeoutDuration,
      sendTimeout: AppConfig.sendTimeoutDuration,
      headers: ApiConstants.baseHeaders(),
      responseType: ResponseType.json,
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  return dio;
});

/// Provides the [ApiClient] wrapper around [Dio].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

/// Re-exports the [NetworkInfo] provider from the core layer so that
/// it is accessible through the DI container alongside other services.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  // Delegate to the core-layer provider.
  return ref.watch(coreNetworkInfoProvider);
});

// ═══════════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [StorageService] singleton.
///
/// Lazily initialized on first access.
final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  ref.onDispose(() {
    // StorageService wraps singletons; no explicit dispose needed.
  });
  return service;
});

/// Provides the [AuthService] instance, injecting the Supabase client
/// and the storage service.
final authServiceProvider = Provider<AuthService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(
    supabaseClient: supabaseClient,
    storageService: storageService,
  );
});

/// Provides the [NotificationService] instance, injecting the Supabase
/// client and the storage service.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return NotificationService(
    supabaseClient: supabaseClient,
    storageService: storageService,
  );
});

// ═══════════════════════════════════════════════════════════════════════
// AUTH STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Stream provider that emits the current Supabase [sb.AuthState].
///
/// Automatically reconnects on transient failures and emits the latest
/// state to any listener.
final authStateProvider = StreamProvider<sb.AuthState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return supabaseClient.auth.onAuthStateChange;
});

/// Convenience provider that yields the currently authenticated [sb.User],
/// or `null` if not signed in.
final currentUserProvider = Provider<sb.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => SupabaseConfig.currentUser,
    error: (_, __) => null,
  );
});

/// Convenience provider that yields `true` when the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Provides the current user's role from secure storage, or a default.
///
/// This is a future provider since it reads from secure storage.
final userRoleProvider = FutureProvider<String>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getUserRole() ?? 'student';
});

// ═══════════════════════════════════════════════════════════════════════
// CONNECTIVITY PROVIDERS (re-exported from core)
// ═══════════════════════════════════════════════════════════════════════

/// Re-exports the connectivity stream from the core network layer.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
  (ref) {
    final networkInfo = ref.watch(networkInfoProvider);
    return networkInfo.onConnectivityChanged;
  },
);

/// Re-exports the simple "is connected" boolean from the core layer.
final isConnectedProvider = Provider<bool>((ref) {
  final asyncResult = ref.watch(connectivityStreamProvider);
  return asyncResult.when(
    data: (results) =>
        results.any((r) => r != ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => false,
  );
});

// ═══════════════════════════════════════════════════════════════════════
// AUTH FEATURE — CLEAN ARCHITECTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [AuthRemoteDataSource] implementation.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AuthRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    storageService: storageService,
  );
});

/// Provides the [LoginUseCase].
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

/// Provides the [SignUpUseCase].
final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

/// Provides the [ForgotPasswordUseCase].
final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordUseCase(repository);
});

/// Provides the [LogoutUseCase].
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

/// Provides the [GetCurrentUserUseCase].
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

/// Provides the [AuthNotifier] with all required use cases.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    signUpUseCase: ref.watch(signUpUseCaseProvider),
    forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Provides the [AuthFormNotifier] for form validation state.
final authFormProvider =
    StateNotifierProvider<AuthFormNotifier, AuthFormState>((ref) {
  return AuthFormNotifier();
});

// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK FEATURE — CLEAN ARCHITECTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [QuestionBankRemoteDataSource] implementation.
final questionBankRemoteDataSourceProvider =
    Provider<QuestionBankRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return QuestionBankRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [QuestionBankRepository] implementation.
final questionBankRepositoryProvider = Provider<QuestionBankRepository>((ref) {
  final remoteDataSource = ref.watch(questionBankRemoteDataSourceProvider);
  return QuestionBankRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provides the [GetQuestionsUseCase].
final getQuestionsUseCaseProvider = Provider<GetQuestionsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return GetQuestionsUseCase(repository);
});

/// Provides the [CreateQuestionUseCase].
final createQuestionUseCaseProvider = Provider<CreateQuestionUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return CreateQuestionUseCase(repository);
});

/// Provides the [UpdateQuestionUseCase].
final updateQuestionUseCaseProvider = Provider<UpdateQuestionUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return UpdateQuestionUseCase(repository);
});

/// Provides the [DeleteQuestionUseCase].
final deleteQuestionUseCaseProvider = Provider<DeleteQuestionUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return DeleteQuestionUseCase(repository);
});

/// Provides the [GetQuestionDetailUseCase].
final getQuestionDetailUseCaseProvider =
    Provider<GetQuestionDetailUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return GetQuestionDetailUseCase(repository);
});

/// Provides the [SearchQuestionsUseCase].
final searchQuestionsUseCaseProvider =
    Provider<SearchQuestionsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return SearchQuestionsUseCase(repository);
});

/// Provides the [ManageQuestionStatusUseCase].
final manageQuestionStatusUseCaseProvider =
    Provider<ManageQuestionStatusUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return ManageQuestionStatusUseCase(repository);
});

/// Provides the [GetQuestionStatsUseCase].
final getQuestionStatsUseCaseProvider =
    Provider<GetQuestionStatsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return GetQuestionStatsUseCase(repository);
});

/// Provides the [ImportQuestionsUseCase].
final importQuestionsUseCaseProvider =
    Provider<ImportQuestionsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return ImportQuestionsUseCase(repository);
});

/// Provides the [ExportQuestionsUseCase].
final exportQuestionsUseCaseProvider =
    Provider<ExportQuestionsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return ExportQuestionsUseCase(repository);
});

/// Provides the [ManageCollectionsUseCase].
final manageCollectionsUseCaseProvider =
    Provider<ManageCollectionsUseCase>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return ManageCollectionsUseCase(repository);
});

/// Provides the [QuestionBankNotifier] with all required use cases.
final questionBankProvider =
    StateNotifierProvider<QuestionBankNotifier, QuestionBankState>((ref) {
  return QuestionBankNotifier(
    getQuestionsUseCase: ref.watch(getQuestionsUseCaseProvider),
    createQuestionUseCase: ref.watch(createQuestionUseCaseProvider),
    updateQuestionUseCase: ref.watch(updateQuestionUseCaseProvider),
    deleteQuestionUseCase: ref.watch(deleteQuestionUseCaseProvider),
    getQuestionDetailUseCase: ref.watch(getQuestionDetailUseCaseProvider),
    searchQuestionsUseCase: ref.watch(searchQuestionsUseCaseProvider),
    manageQuestionStatusUseCase: ref.watch(manageQuestionStatusUseCaseProvider),
    getQuestionStatsUseCase: ref.watch(getQuestionStatsUseCaseProvider),
  );
});

/// Provides the [QuestionFilterNotifier] for filter state management.
final questionFilterProvider =
    StateNotifierProvider<QuestionFilterNotifier, QuestionFilterState>((ref) {
  final repository = ref.watch(questionBankRepositoryProvider);
  return QuestionFilterNotifier(repository: repository);
});

/// Provides the [CollectionNotifier] for collection management.
final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
  return CollectionNotifier(
    manageCollectionsUseCase: ref.watch(manageCollectionsUseCaseProvider),
  );
});

/// Provides the [ImportExportNotifier] for import/export state management.
final importExportProvider =
    StateNotifierProvider<ImportExportNotifier, ImportExportState>((ref) {
  return ImportExportNotifier(
    importQuestionsUseCase: ref.watch(importQuestionsUseCaseProvider),
    exportQuestionsUseCase: ref.watch(exportQuestionsUseCaseProvider),
    repository: ref.watch(questionBankRepositoryProvider),
  );
});

/// Provides the [QuestionBankStatsNotifier] for stats dashboard.
final questionBankStatsProvider =
    StateNotifierProvider<QuestionBankStatsNotifier, QuestionBankStatsState>(
        (ref) {
  return QuestionBankStatsNotifier(
    getQuestionStatsUseCase: ref.watch(getQuestionStatsUseCaseProvider),
  );
});

/// Provides the [QuestionEditorNotifier] for the question editor form.
final questionEditorProvider =
    StateNotifierProvider<QuestionEditorNotifier, QuestionEditorState>((ref) {
  return QuestionEditorNotifier(
    createQuestionUseCase: ref.watch(createQuestionUseCaseProvider),
    updateQuestionUseCase: ref.watch(updateQuestionUseCaseProvider),
    manageQuestionStatusUseCase: ref.watch(manageQuestionStatusUseCaseProvider),
    repository: ref.watch(questionBankRepositoryProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// AI GENERATOR FEATURE — CLEAN ARCHITECTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

// ─── AI Service Infrastructure ────────────────────────────────────────

/// Provides the [AiProvidersRegistry] singleton.
///
/// Registers OpenAI and Gemini providers conditionally based on
/// whether their API keys are available in the environment config.
final aiProviderRegistryProvider = Provider<AiProvidersRegistry>((ref) {
  final openaiApiKey = EnvConfig.maybeGet('OPENAI_API_KEY') ?? '';
  final geminiApiKey = EnvConfig.maybeGet('GEMINI_API_KEY') ?? '';

  if (openaiApiKey.isEmpty && geminiApiKey.isEmpty) {
    AppLogger.warning(
      'No AI API keys configured — AI features will be unavailable',
    );
    return AiProvidersRegistry.createEmpty();
  }

  return AiProvidersRegistry.createDefault(
    openaiApiKey: openaiApiKey,
    geminiApiKey: geminiApiKey,
  );
});

/// Provides the [PromptEngine] singleton.
final promptEngineProvider = Provider<PromptEngine>((ref) {
  return PromptEngine();
});

/// Provides the [ValidationEngine] singleton.
final validationEngineProvider = Provider<ValidationEngine>((ref) {
  return ValidationEngine();
});

/// Provides the [AiService] singleton, injecting the provider registry,
/// prompt engine, and validation engine.
final aiServiceProvider = Provider<AiService>((ref) {
  final registry = ref.watch(aiProviderRegistryProvider);
  final promptEngine = ref.watch(promptEngineProvider);
  final validationEngine = ref.watch(validationEngineProvider);

  return AiService(
    providersRegistry: registry,
    promptEngine: promptEngine,
    validationEngine: validationEngine,
  );
});

/// Provides the [OpenAiProvider] conditionally if an API key is set.
final openaiProvider = Provider<OpenAiProvider?>((ref) {
  final apiKey = EnvConfig.maybeGet('OPENAI_API_KEY') ?? '';
  if (apiKey.isEmpty) return null;
  return OpenAiProvider(apiKey: apiKey);
});

/// Provides the [GeminiProvider] conditionally if an API key is set.
final geminiProvider = Provider<GeminiProvider?>((ref) {
  final apiKey = EnvConfig.maybeGet('GEMINI_API_KEY') ?? '';
  if (apiKey.isEmpty) return null;
  return GeminiProvider(apiKey: apiKey);
});

// ─── AI Generator Data Layer ──────────────────────────────────────────

/// Provides the [AiGeneratorRemoteDataSource] implementation.
final aiGeneratorRemoteDataSourceProvider =
    Provider<AiGeneratorRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return AiGeneratorRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [AiGeneratorRepository] implementation.
final aiGeneratorRepositoryProvider = Provider<AiGeneratorRepository>((ref) {
  final remoteDataSource = ref.watch(aiGeneratorRemoteDataSourceProvider);
  return AiGeneratorRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ─── AI Generator Use Cases ───────────────────────────────────────────

/// Provides the [GenerateQuestionsUseCase].
final generateQuestionsUseCaseProvider =
    Provider<GenerateQuestionsUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return GenerateQuestionsUseCase(repository);
});

/// Provides the [ReviewGeneratedQuestionUseCase].
final reviewGeneratedQuestionUseCaseProvider =
    Provider<ReviewGeneratedQuestionUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return ReviewGeneratedQuestionUseCase(repository);
});

/// Provides the [ImproveQuestionUseCase].
final improveQuestionUseCaseProvider = Provider<ImproveQuestionUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return ImproveQuestionUseCase(repository);
});

/// Provides the [ValidateQuestionUseCase].
final validateQuestionUseCaseProvider =
    Provider<ValidateQuestionUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return ValidateQuestionUseCase(repository);
});

/// Provides the [SaveToQuestionBankUseCase].
final saveToQuestionBankUseCaseProvider =
    Provider<SaveToQuestionBankUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return SaveToQuestionBankUseCase(repository);
});

/// Provides the [UploadDocumentUseCase].
final uploadDocumentUseCaseProvider = Provider<UploadDocumentUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return UploadDocumentUseCase(repository);
});

/// Provides the [GetGenerationHistoryUseCase].
final getGenerationHistoryUseCaseProvider =
    Provider<GetGenerationHistoryUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return GetGenerationHistoryUseCase(repository);
});

/// Provides the [ManagePromptTemplatesUseCase].
final managePromptTemplatesUseCaseProvider =
    Provider<ManagePromptTemplatesUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return ManagePromptTemplatesUseCase(repository);
});

/// Provides the [GetAiDashboardStatsUseCase].
final getAiDashboardStatsUseCaseProvider =
    Provider<GetAiDashboardStatsUseCase>((ref) {
  final repository = ref.watch(aiGeneratorRepositoryProvider);
  return GetAiDashboardStatsUseCase(repository);
});

// ─── AI Generator State Notifiers ─────────────────────────────────────

/// Provides the [AiGeneratorNotifier] for main generation state.
final aiGeneratorProvider =
    StateNotifierProvider<AiGeneratorNotifier, AiGeneratorState>((ref) {
  return AiGeneratorNotifier(
    generateQuestionsUseCase: ref.watch(generateQuestionsUseCaseProvider),
    reviewGeneratedQuestionUseCase:
        ref.watch(reviewGeneratedQuestionUseCaseProvider),
    improveQuestionUseCase: ref.watch(improveQuestionUseCaseProvider),
    validateQuestionUseCase: ref.watch(validateQuestionUseCaseProvider),
    saveToQuestionBankUseCase: ref.watch(saveToQuestionBankUseCaseProvider),
    getGenerationHistoryUseCase:
        ref.watch(getGenerationHistoryUseCaseProvider),
    aiService: ref.watch(aiServiceProvider),
    managePromptTemplatesUseCase:
        ref.watch(managePromptTemplatesUseCaseProvider),
  );
});

/// Provides the [AiReviewNotifier] for review workflow state.
final aiReviewProvider =
    StateNotifierProvider<AiReviewNotifier, AiReviewState>((ref) {
  return AiReviewNotifier(
    repository: ref.watch(aiGeneratorRepositoryProvider),
    reviewGeneratedQuestionUseCase:
        ref.watch(reviewGeneratedQuestionUseCaseProvider),
    improveQuestionUseCase: ref.watch(improveQuestionUseCaseProvider),
    validateQuestionUseCase: ref.watch(validateQuestionUseCaseProvider),
    saveToQuestionBankUseCase: ref.watch(saveToQuestionBankUseCaseProvider),
  );
});

/// Provides the [AiDocumentNotifier] for document upload/processing state.
final aiDocumentProvider =
    StateNotifierProvider<AiDocumentNotifier, AiDocumentState>((ref) {
  return AiDocumentNotifier(
    uploadDocumentUseCase: ref.watch(uploadDocumentUseCaseProvider),
    repository: ref.watch(aiGeneratorRepositoryProvider),
  );
});

/// Provides the [PromptTemplateNotifier] for prompt management state.
final promptTemplateProvider =
    StateNotifierProvider<PromptTemplateNotifier, PromptTemplateState>(
        (ref) {
  return PromptTemplateNotifier(
    managePromptTemplatesUseCase:
        ref.watch(managePromptTemplatesUseCaseProvider),
  );
});

/// Provides the [AiStatsNotifier] for dashboard stats state.
final aiStatsProvider =
    StateNotifierProvider<AiStatsNotifier, AiStatsState>((ref) {
  return AiStatsNotifier(
    getAiDashboardStatsUseCase: ref.watch(getAiDashboardStatsUseCaseProvider),
    repository: ref.watch(aiGeneratorRepositoryProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// CBT ENGINE FEATURE — CLEAN ARCHITECTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

// ─── CBT Data Layer ──────────────────────────────────────────────────

/// Provides the [CbtRemoteDataSource] implementation.
final cbtRemoteDataSourceProvider = Provider<CbtRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return CbtRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [CbtRepository] implementation.
final cbtRepositoryProvider = Provider<CbtRepository>((ref) {
  final remoteDataSource = ref.watch(cbtRemoteDataSourceProvider);
  return CbtRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ─── CBT Use Cases ───────────────────────────────────────────────────

/// Provides the [CreateExamUseCase].
final createExamUseCaseProvider = Provider<CreateExamUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return CreateExamUseCase(repository);
});

/// Provides the [UpdateExamUseCase].
final updateExamUseCaseProvider = Provider<UpdateExamUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return UpdateExamUseCase(repository);
});

/// Provides the [ManageExamStatusUseCase].
final manageExamStatusUseCaseProvider =
    Provider<ManageExamStatusUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return ManageExamStatusUseCase(repository);
});

/// Provides the [StartExamAttemptUseCase].
final startExamAttemptUseCaseProvider =
    Provider<StartExamAttemptUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return StartExamAttemptUseCase(repository);
});

/// Provides the [SubmitExamAttemptUseCase].
final submitExamAttemptUseCaseProvider =
    Provider<SubmitExamAttemptUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return SubmitExamAttemptUseCase(repository);
});

/// Provides the [SaveAnswerUseCase].
final saveAnswerUseCaseProvider = Provider<SaveAnswerUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return SaveAnswerUseCase(repository);
});

/// Provides the [GetExamResultsUseCase].
final getExamResultsUseCaseProvider = Provider<GetExamResultsUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return GetExamResultsUseCase(repository);
});

/// Provides the [GetExamStatisticsUseCase].
final getExamStatisticsUseCaseProvider =
    Provider<GetExamStatisticsUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return GetExamStatisticsUseCase(repository);
});

/// Provides the [GetLiveExamStatsUseCase].
final getLiveExamStatsUseCaseProvider =
    Provider<GetLiveExamStatsUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return GetLiveExamStatsUseCase(repository);
});

/// Provides the [GradeExamUseCase].
final gradeExamUseCaseProvider = Provider<GradeExamUseCase>((ref) {
  final repository = ref.watch(cbtRepositoryProvider);
  return GradeExamUseCase(repository);
});

// ─── CBT Service Providers ───────────────────────────────────────────

/// Provides the [AutoSaveService] singleton.
final autoSaveServiceProvider = Provider<AutoSaveService>((ref) {
  final service = AutoSaveService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provides the [ExamTimerService] singleton.
final examTimerServiceProvider = Provider<ExamTimerService>((ref) {
  final service = ExamTimerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provides the [SessionRecoveryService] singleton.
final sessionRecoveryServiceProvider = Provider<SessionRecoveryService>((ref) {
  final service = SessionRecoveryService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provides the [AntiCheatService] singleton.
final antiCheatServiceProvider = Provider<AntiCheatService>((ref) {
  return AntiCheatService();
});

/// Provides the [ResultProcessor] singleton.
final resultProcessorProvider = Provider<ResultProcessor>((ref) {
  return ResultProcessor();
});

/// Provides the [CbtRealtimeService] singleton.
final cbtRealtimeServiceProvider = Provider<CbtRealtimeService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final service = CbtRealtimeService(supabaseClient: supabaseClient);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// ─── CBT State Notifiers ─────────────────────────────────────────────

/// Provides the [ExamBuilderNotifier] for exam creation/editing state.
final examBuilderProvider =
    StateNotifierProvider<ExamBuilderNotifier, ExamBuilderState>((ref) {
  return ExamBuilderNotifier(
    createExamUseCase: ref.watch(createExamUseCaseProvider),
    updateExamUseCase: ref.watch(updateExamUseCaseProvider),
    manageExamStatusUseCase: ref.watch(manageExamStatusUseCaseProvider),
    cbtRepository: ref.watch(cbtRepositoryProvider),
  );
});

/// Provides the [ExamListNotifier] for exam listing and filtering state.
final examListProvider =
    StateNotifierProvider<ExamListNotifier, ExamListState>((ref) {
  return ExamListNotifier(
    cbtRepository: ref.watch(cbtRepositoryProvider),
    manageExamStatusUseCase: ref.watch(manageExamStatusUseCaseProvider),
  );
});

/// Provides the [ExamTakerNotifier] for student exam-taking state.
final examTakerProvider =
    StateNotifierProvider<ExamTakerNotifier, ExamTakerState>((ref) {
  return ExamTakerNotifier(
    startExamAttemptUseCase: ref.watch(startExamAttemptUseCaseProvider),
    saveAnswerUseCase: ref.watch(saveAnswerUseCaseProvider),
    submitExamAttemptUseCase: ref.watch(submitExamAttemptUseCaseProvider),
    cbtRepository: ref.watch(cbtRepositoryProvider),
    autoSaveService: ref.watch(autoSaveServiceProvider),
    examTimerService: ref.watch(examTimerServiceProvider),
    sessionRecoveryService: ref.watch(sessionRecoveryServiceProvider),
    antiCheatService: ref.watch(antiCheatServiceProvider),
  );
});

/// Provides the [ExamMonitorNotifier] for live monitoring state.
final examMonitorProvider =
    StateNotifierProvider<ExamMonitorNotifier, ExamMonitorState>((ref) {
  return ExamMonitorNotifier(
    cbtRepository: ref.watch(cbtRepositoryProvider),
    getLiveExamStatsUseCase: ref.watch(getLiveExamStatsUseCaseProvider),
    cbtRealtimeService: ref.watch(cbtRealtimeServiceProvider),
  );
});

/// Provides the [ExamResultsNotifier] for results and grading state.
final examResultsProvider =
    StateNotifierProvider<ExamResultsNotifier, ExamResultsState>((ref) {
  return ExamResultsNotifier(
    cbtRepository: ref.watch(cbtRepositoryProvider),
    getExamResultsUseCase: ref.watch(getExamResultsUseCaseProvider),
    getExamStatisticsUseCase: ref.watch(getExamStatisticsUseCaseProvider),
    gradeExamUseCase: ref.watch(gradeExamUseCaseProvider),
  );
});

/// Provides the [StudentExamsNotifier] for student's exam list state.
final studentExamsProvider =
    StateNotifierProvider<StudentExamsNotifier, StudentExamsState>((ref) {
  return StudentExamsNotifier(
    cbtRepository: ref.watch(cbtRepositoryProvider),
  );
});
