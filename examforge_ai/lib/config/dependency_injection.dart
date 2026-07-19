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
import '../features/cbt_engine/data/datasources/exam_template_remote_datasource.dart';
import '../features/cbt_engine/data/repositories/cbt_repository_impl.dart';
import '../features/cbt_engine/data/repositories/exam_template_repository_impl.dart';
import '../features/cbt_engine/domain/repositories/cbt_repository.dart';
import '../features/cbt_engine/domain/repositories/exam_template_repository.dart';
import '../features/cbt_engine/domain/usecases/create_exam_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_exam_results_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_exam_statistics_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_live_exam_stats_usecase.dart';
import '../features/cbt_engine/domain/usecases/get_submission_receipt_usecase.dart';
import '../features/cbt_engine/domain/usecases/grade_exam_usecase.dart';
import '../features/cbt_engine/domain/usecases/manage_exam_status_usecase.dart';
import '../features/cbt_engine/domain/usecases/manage_exam_templates_usecase.dart';
import '../features/cbt_engine/domain/usecases/save_answer_usecase.dart';
import '../features/cbt_engine/domain/usecases/start_exam_attempt_usecase.dart';
import '../features/cbt_engine/domain/usecases/submit_exam_attempt_usecase.dart';
import '../features/cbt_engine/domain/usecases/update_exam_usecase.dart';
import '../features/cbt_engine/presentation/providers/exam_builder_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_list_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_monitor_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_notification_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_results_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_template_provider.dart';
import '../features/cbt_engine/presentation/providers/exam_taker_provider.dart';
import '../features/cbt_engine/presentation/providers/student_exams_provider.dart';
import '../features/cbt_engine/presentation/providers/submission_receipt_provider.dart';
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
import '../services/cbt/exam_notification_service.dart';
import '../services/cbt/exam_timer_service.dart';
import '../services/cbt/rate_limiting_service.dart';
import '../services/cbt/realtime_service.dart';
import '../services/cbt/result_processor.dart';
import '../services/cbt/session_recovery_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/results/ai_grading_service.dart';
import '../services/results/analytics_engine.dart';
import '../services/results/report_generator.dart';
import '../features/results/data/datasources/results_remote_datasource.dart';
import '../features/results/data/repositories/results_repository_impl.dart';
import '../features/results/domain/repositories/results_repository.dart';
import '../features/results/domain/usecases/results_usecases.dart';
import '../features/results/presentation/providers/results_providers.dart';
import '../features/student_portal/data/datasources/student_portal_remote_datasource.dart';
import '../features/student_portal/data/repositories/student_portal_repository_impl.dart';
import '../features/student_portal/domain/repositories/student_portal_repository.dart';
import '../features/student_portal/domain/usecases/student_portal_usecases.dart' hide GenerateQuestionsFromContentUseCase;
import '../features/student_portal/presentation/providers/ai_tutor_provider.dart';
import '../features/student_portal/presentation/providers/assignment_provider.dart';
import '../features/student_portal/presentation/providers/document_chat_provider.dart';
import '../features/student_portal/presentation/providers/flashcard_provider.dart';
import '../features/student_portal/presentation/providers/goals_provider.dart';
import '../features/student_portal/presentation/providers/practice_provider.dart';
import '../features/student_portal/presentation/providers/progress_provider.dart';
import '../features/student_portal/presentation/providers/resource_provider.dart';
import '../features/student_portal/presentation/providers/student_dashboard_provider.dart';
import '../features/student_portal/presentation/providers/student_notification_provider.dart';
import '../features/student_portal/presentation/providers/study_planner_provider.dart';
import '../features/parent_portal/presentation/providers/parent_dashboard_provider.dart';
import '../features/parent_portal/presentation/providers/child_profile_provider.dart';
import '../features/parent_portal/presentation/providers/child_performance_provider.dart';
import '../features/parent_portal/presentation/providers/child_attendance_provider.dart';
import '../features/parent_portal/presentation/providers/child_assignments_provider.dart';
import '../features/parent_portal/presentation/providers/parent_messaging_provider.dart';
import '../features/parent_portal/presentation/providers/parent_notification_provider.dart';
import '../features/parent_portal/presentation/providers/parent_calendar_provider.dart';
import '../features/parent_portal/presentation/providers/parent_assistant_provider.dart';
import '../features/parent_portal/presentation/providers/parent_insights_provider.dart';
import '../features/parent_portal/presentation/providers/parent_reports_provider.dart';
import '../features/parent_portal/presentation/providers/parent_engagement_provider.dart';
import '../features/super_admin/data/datasources/super_admin_remote_datasource.dart';
import '../features/super_admin/data/repositories/super_admin_repository_impl.dart';
import '../features/super_admin/domain/repositories/super_admin_repository.dart';
import '../features/super_admin/domain/usecases/super_admin_usecases.dart';

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

// ─── CBT Exam Template Data Layer ────────────────────────────────────

/// Provides the [ExamTemplateRemoteDataSource] implementation.
final examTemplateRemoteDataSourceProvider =
    Provider<ExamTemplateRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ExamTemplateRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [ExamTemplateRepository] implementation.
final examTemplateRepositoryProvider = Provider<ExamTemplateRepository>((ref) {
  final remoteDataSource = ref.watch(examTemplateRemoteDataSourceProvider);
  return ExamTemplateRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ─── CBT Exam Template Use Cases ─────────────────────────────────────

/// Provides the [SaveAsTemplateUseCase].
final saveAsTemplateUseCaseProvider = Provider<SaveAsTemplateUseCase>((ref) {
  return SaveAsTemplateUseCase(ref.watch(examTemplateRepositoryProvider));
});

/// Provides the [GetExamTemplatesUseCase].
final getExamTemplatesUseCaseProvider =
    Provider<GetExamTemplatesUseCase>((ref) {
  return GetExamTemplatesUseCase(ref.watch(examTemplateRepositoryProvider));
});

/// Provides the [GetExamTemplateDetailUseCase].
final getExamTemplateDetailUseCaseProvider =
    Provider<GetExamTemplateDetailUseCase>((ref) {
  return GetExamTemplateDetailUseCase(
      ref.watch(examTemplateRepositoryProvider));
});

/// Provides the [DeleteExamTemplateUseCase].
final deleteExamTemplateUseCaseProvider =
    Provider<DeleteExamTemplateUseCase>((ref) {
  return DeleteExamTemplateUseCase(ref.watch(examTemplateRepositoryProvider));
});

/// Provides the [CreateExamFromTemplateUseCase].
final createExamFromTemplateUseCaseProvider =
    Provider<CreateExamFromTemplateUseCase>((ref) {
  return CreateExamFromTemplateUseCase(
      ref.watch(examTemplateRepositoryProvider));
});

// ─── CBT Submission Receipt Use Cases ────────────────────────────────

/// Provides the [GetSubmissionReceiptUseCase].
final getSubmissionReceiptUseCaseProvider =
    Provider<GetSubmissionReceiptUseCase>((ref) {
  return GetSubmissionReceiptUseCase(
      ref.watch(examTemplateRepositoryProvider));
});

/// Provides the [VerifySubmissionReceiptUseCase].
final verifySubmissionReceiptUseCaseProvider =
    Provider<VerifySubmissionReceiptUseCase>((ref) {
  return VerifySubmissionReceiptUseCase(
      ref.watch(examTemplateRepositoryProvider));
});

// ─── CBT New Service Providers ───────────────────────────────────────

/// Provides the [ExamNotificationService] singleton.
final examNotificationServiceProvider = Provider<ExamNotificationService>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final service = ExamNotificationService(supabaseClient: supabaseClient);
  return service;
});

/// Provides the [RateLimitingService] singleton.
final rateLimitingServiceProvider = Provider<RateLimitingService>((ref) {
  final service = RateLimitingService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// ─── CBT Exam Template State Notifier ────────────────────────────────

/// Provides the [ExamTemplateNotifier] for exam template management state.
final examTemplateProvider =
    StateNotifierProvider<ExamTemplateNotifier, ExamTemplateState>((ref) {
  return ExamTemplateNotifier(
    saveAsTemplateUseCase: ref.watch(saveAsTemplateUseCaseProvider),
    getExamTemplatesUseCase: ref.watch(getExamTemplatesUseCaseProvider),
    getExamTemplateDetailUseCase:
        ref.watch(getExamTemplateDetailUseCaseProvider),
    deleteExamTemplateUseCase: ref.watch(deleteExamTemplateUseCaseProvider),
    createExamFromTemplateUseCase:
        ref.watch(createExamFromTemplateUseCaseProvider),
  );
});

/// Provides the [SubmissionReceiptNotifier] for submission receipt state.
final submissionReceiptProvider = StateNotifierProvider<SubmissionReceiptNotifier,
    SubmissionReceiptState>((ref) {
  return SubmissionReceiptNotifier(
    getSubmissionReceiptUseCase:
        ref.watch(getSubmissionReceiptUseCaseProvider),
    verifySubmissionReceiptUseCase:
        ref.watch(verifySubmissionReceiptUseCaseProvider),
  );
});

/// Provides the [ExamNotificationNotifier] for exam notification state.
final examNotificationProvider =
    StateNotifierProvider<ExamNotificationNotifier, ExamNotificationState>(
        (ref) {
  return ExamNotificationNotifier(
    cbtRepository: ref.watch(cbtRepositoryProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// RESULTS, GRADING & ANALYTICS ENGINE — CLEAN ARCHITECTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

// ─── Results Service Providers ────────────────────────────────────────

/// Provides the [AiGradingService] singleton for AI-assisted essay grading.
final aiGradingServiceProvider = Provider<AiGradingService>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final promptEngine = ref.watch(promptEngineProvider);
  return AiGradingService(
    aiService: aiService,
    promptEngine: promptEngine,
  );
});

/// Provides the [AnalyticsEngine] singleton for analytics computations.
final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) {
  return AnalyticsEngine();
});

/// Provides the [ReportGenerator] singleton for report data generation.
final reportGeneratorProvider = Provider<ReportGenerator>((ref) {
  return ReportGenerator();
});

// ─── Results Data Layer ──────────────────────────────────────────────

/// Provides the [ResultsRemoteDataSource] implementation.
final resultsRemoteDataSourceProvider =
    Provider<ResultsRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ResultsRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

/// Provides the [ResultsRepository] implementation.
final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  final remoteDataSource = ref.watch(resultsRemoteDataSourceProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ResultsRepositoryImpl(
    remoteDataSource: remoteDataSource,
    supabaseClient: supabaseClient,
  );
});

// ─── Results Use Cases ───────────────────────────────────────────────

/// Provides the [CreateGradeScaleUseCase].
final createGradeScaleUseCaseProvider =
    Provider<CreateGradeScaleUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return CreateGradeScaleUseCase(repository);
});

/// Provides the [UpdateGradeScaleUseCase].
final updateGradeScaleUseCaseProvider =
    Provider<UpdateGradeScaleUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return UpdateGradeScaleUseCase(repository);
});

/// Provides the [GetGradeScalesUseCase].
final getGradeScalesUseCaseProvider =
    Provider<GetGradeScalesUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetGradeScalesUseCase(repository);
});

/// Provides the [ApplyGradeScaleUseCase].
final applyGradeScaleUseCaseProvider =
    Provider<ApplyGradeScaleUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return ApplyGradeScaleUseCase(repository);
});

/// Provides the [RequestAiGradingUseCase].
final requestAiGradingUseCaseProvider =
    Provider<RequestAiGradingUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return RequestAiGradingUseCase(repository);
});

/// Provides the [ReviewAiGradingUseCase].
final reviewAiGradingUseCaseProvider =
    Provider<ReviewAiGradingUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return ReviewAiGradingUseCase(repository);
});

/// Provides the [BatchAiGradingUseCase].
final batchAiGradingUseCaseProvider =
    Provider<BatchAiGradingUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return BatchAiGradingUseCase(repository);
});

/// Provides the [GetPendingAiGradingsUseCase].
final getPendingAiGradingsUseCaseProvider =
    Provider<GetPendingAiGradingsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetPendingAiGradingsUseCase(repository);
});

/// Provides the [SaveTeacherFeedbackUseCase].
final saveTeacherFeedbackUseCaseProvider =
    Provider<SaveTeacherFeedbackUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return SaveTeacherFeedbackUseCase(repository);
});

/// Provides the [GetTeacherFeedbackUseCase].
final getTeacherFeedbackUseCaseProvider =
    Provider<GetTeacherFeedbackUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetTeacherFeedbackUseCase(repository);
});

/// Provides the [GetStudentSubjectResultsUseCase].
final getStudentSubjectResultsUseCaseProvider =
    Provider<GetStudentSubjectResultsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetStudentSubjectResultsUseCase(repository);
});

/// Provides the [GetStudentOverallResultUseCase].
final getStudentOverallResultUseCaseProvider =
    Provider<GetStudentOverallResultUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetStudentOverallResultUseCase(repository);
});

/// Provides the [GetClassOverallResultsUseCase].
final getClassOverallResultsUseCaseProvider =
    Provider<GetClassOverallResultsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetClassOverallResultsUseCase(repository);
});

/// Provides the [UpdateTeacherCommentUseCase].
final updateTeacherCommentUseCaseProvider =
    Provider<UpdateTeacherCommentUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return UpdateTeacherCommentUseCase(repository);
});

/// Provides the [GetStudentTopicMasteryUseCase].
final getStudentTopicMasteryUseCaseProvider =
    Provider<GetStudentTopicMasteryUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetStudentTopicMasteryUseCase(repository);
});

/// Provides the [GetClassTopicMasteryUseCase].
final getClassTopicMasteryUseCaseProvider =
    Provider<GetClassTopicMasteryUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetClassTopicMasteryUseCase(repository);
});

/// Provides the [GetClassPerformanceUseCase].
final getClassPerformanceUseCaseProvider =
    Provider<GetClassPerformanceUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetClassPerformanceUseCase(repository);
});

/// Provides the [GetSchoolPerformanceUseCase].
final getSchoolPerformanceUseCaseProvider =
    Provider<GetSchoolPerformanceUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetSchoolPerformanceUseCase(repository);
});

/// Provides the [GetAnalyticsSnapshotUseCase].
final getAnalyticsSnapshotUseCaseProvider =
    Provider<GetAnalyticsSnapshotUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetAnalyticsSnapshotUseCase(repository);
});

/// Provides the [GetDashboardConfigurationUseCase].
final getDashboardConfigurationUseCaseProvider =
    Provider<GetDashboardConfigurationUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetDashboardConfigurationUseCase(repository);
});

/// Provides the [SaveDashboardConfigurationUseCase].
final saveDashboardConfigurationUseCaseProvider =
    Provider<SaveDashboardConfigurationUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return SaveDashboardConfigurationUseCase(repository);
});

/// Provides the [CreateReportExportUseCase].
final createReportExportUseCaseProvider =
    Provider<CreateReportExportUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return CreateReportExportUseCase(repository);
});

/// Provides the [GetReportExportsUseCase].
final getReportExportsUseCaseProvider =
    Provider<GetReportExportsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return GetReportExportsUseCase(repository);
});

/// Provides the [DownloadReportUseCase].
final downloadReportUseCaseProvider =
    Provider<DownloadReportUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return DownloadReportUseCase(repository);
});

/// Provides the [LockResultsUseCase].
final lockResultsUseCaseProvider = Provider<LockResultsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return LockResultsUseCase(repository);
});

/// Provides the [PublishResultsUseCase].
final publishResultsUseCaseProvider = Provider<PublishResultsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return PublishResultsUseCase(repository);
});

/// Provides the [RecomputeResultsUseCase].
final recomputeResultsUseCaseProvider =
    Provider<RecomputeResultsUseCase>((ref) {
  final repository = ref.watch(resultsRepositoryProvider);
  return RecomputeResultsUseCase(repository);
});

// ─── Results State Notifiers ─────────────────────────────────────────

/// Provides the [ResultsDashboardNotifier] for the results dashboard.
final resultsDashboardProvider =
    StateNotifierProvider<ResultsDashboardNotifier, ResultsDashboardState>(
        (ref) {
  return ResultsDashboardNotifier(
    getGradeScalesUseCase: ref.watch(getGradeScalesUseCaseProvider),
    getClassPerformanceUseCase: ref.watch(getClassPerformanceUseCaseProvider),
    getSchoolPerformanceUseCase: ref.watch(getSchoolPerformanceUseCaseProvider),
  );
});

/// Provides the [GradeScaleNotifier] for grade scale management.
final gradeScaleProvider =
    StateNotifierProvider<GradeScaleNotifier, GradeScaleState>((ref) {
  return GradeScaleNotifier(
    getGradeScalesUseCase: ref.watch(getGradeScalesUseCaseProvider),
    createGradeScaleUseCase: ref.watch(createGradeScaleUseCaseProvider),
    updateGradeScaleUseCase: ref.watch(updateGradeScaleUseCaseProvider),
    applyGradeScaleUseCase: ref.watch(applyGradeScaleUseCaseProvider),
  );
});

/// Provides the [AiGradingNotifier] for AI grading workflow.
final aiGradingProvider =
    StateNotifierProvider<AiGradingNotifier, AiGradingState>((ref) {
  return AiGradingNotifier(
    requestAiGradingUseCase: ref.watch(requestAiGradingUseCaseProvider),
    reviewAiGradingUseCase: ref.watch(reviewAiGradingUseCaseProvider),
    batchAiGradingUseCase: ref.watch(batchAiGradingUseCaseProvider),
    getPendingAiGradingsUseCase: ref.watch(getPendingAiGradingsUseCaseProvider),
    aiGradingService: ref.watch(aiGradingServiceProvider),
  );
});

/// Provides the [TeacherGradingNotifier] for teacher manual grading.
final teacherGradingProvider =
    StateNotifierProvider<TeacherGradingNotifier, TeacherGradingState>(
        (ref) {
  return TeacherGradingNotifier(
    saveTeacherFeedbackUseCase: ref.watch(saveTeacherFeedbackUseCaseProvider),
    getTeacherFeedbackUseCase: ref.watch(getTeacherFeedbackUseCaseProvider),
    reviewAiGradingUseCase: ref.watch(reviewAiGradingUseCaseProvider),
  );
});

/// Provides the [StudentResultsNotifier] for student result viewing.
final studentResultsProvider =
    StateNotifierProvider<StudentResultsNotifier, StudentResultsState>(
        (ref) {
  return StudentResultsNotifier(
    getStudentSubjectResultsUseCase:
        ref.watch(getStudentSubjectResultsUseCaseProvider),
    getStudentOverallResultUseCase:
        ref.watch(getStudentOverallResultUseCaseProvider),
    getStudentTopicMasteryUseCase:
        ref.watch(getStudentTopicMasteryUseCaseProvider),
  );
});

/// Provides the [AnalyticsNotifier] for analytics and dashboards.
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(
    getClassPerformanceUseCase: ref.watch(getClassPerformanceUseCaseProvider),
    getSchoolPerformanceUseCase: ref.watch(getSchoolPerformanceUseCaseProvider),
    getAnalyticsSnapshotUseCase: ref.watch(getAnalyticsSnapshotUseCaseProvider),
    getDashboardConfigurationUseCase:
        ref.watch(getDashboardConfigurationUseCaseProvider),
    saveDashboardConfigurationUseCase:
        ref.watch(saveDashboardConfigurationUseCaseProvider),
    analyticsEngine: ref.watch(analyticsEngineProvider),
  );
});

/// Provides the [ReportExportNotifier] for report generation and export.
final reportExportProvider =
    StateNotifierProvider<ReportExportNotifier, ReportExportState>((ref) {
  return ReportExportNotifier(
    createReportExportUseCase: ref.watch(createReportExportUseCaseProvider),
    getReportExportsUseCase: ref.watch(getReportExportsUseCaseProvider),
    downloadReportUseCase: ref.watch(downloadReportUseCaseProvider),
    reportGenerator: ref.watch(reportGeneratorProvider),
  );
});

/// Provides the [ResultManagementNotifier] for result locking and publishing.
final resultManagementProvider =
    StateNotifierProvider<ResultManagementNotifier, ResultManagementState>(
        (ref) {
  return ResultManagementNotifier(
    lockResultsUseCase: ref.watch(lockResultsUseCaseProvider),
    publishResultsUseCase: ref.watch(publishResultsUseCaseProvider),
    recomputeResultsUseCase: ref.watch(recomputeResultsUseCaseProvider),
    resultsRepository: ref.watch(resultsRepositoryProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// TEACHER WORKSPACE MODULE
// ═══════════════════════════════════════════════════════════════════════════════

import '../features/teacher_workspace/data/datasources/teacher_workspace_remote_datasource.dart';
import '../features/teacher_workspace/data/repositories/teacher_workspace_repository_impl.dart';
import '../features/teacher_workspace/domain/repositories/teacher_workspace_repository.dart';
import '../features/teacher_workspace/domain/usecases/ai_content_assistant_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_event_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_events_usecase.dart';
import '../features/teacher_workspace/domain/usecases/suggest_schedule_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_assignment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_lesson_plan_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_report_comment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_resource_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_scheme_of_work_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_worksheet_usecase.dart';
import '../features/teacher_workspace/domain/usecases/delete_lesson_plan_usecase.dart';
import '../features/teacher_workspace/domain/usecases/export_worksheet_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_assignment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_lesson_plan_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_questions_from_content_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_report_comments_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_resource_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_scheme_of_work_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_worksheet_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_assignments_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_content_history_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_lesson_plans_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_resources_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_schemes_of_work_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_version_history_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_worksheets_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_workspace_dashboard_usecase.dart';
import '../features/teacher_workspace/domain/usecases/publish_assignment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/toggle_favorite_usecase.dart';
import '../features/teacher_workspace/domain/usecases/update_lesson_plan_usecase.dart';
import '../features/teacher_workspace/presentation/providers/assignment_provider.dart';
import '../features/teacher_workspace/presentation/providers/calendar_planner_provider.dart';
import '../features/teacher_workspace/presentation/providers/content_assistant_provider.dart';
import '../features/teacher_workspace/presentation/providers/generate_questions_provider.dart';
import '../features/teacher_workspace/presentation/providers/lesson_plan_provider.dart';
import '../features/teacher_workspace/presentation/providers/report_comment_provider.dart';
import '../features/teacher_workspace/presentation/providers/resource_library_provider.dart';
import '../features/teacher_workspace/presentation/providers/scheme_of_work_provider.dart';
import '../features/teacher_workspace/presentation/providers/teaching_resource_provider.dart';
import '../features/teacher_workspace/presentation/providers/worksheet_provider.dart';
import '../features/teacher_workspace/presentation/providers/workspace_dashboard_provider.dart';
import '../features/teacher_workspace/domain/usecases/generate_presentation_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_presentations_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_presentation_usecase.dart';
import '../features/teacher_workspace/domain/usecases/export_presentation_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_communication_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_communications_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_communication_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_task_usecase.dart';
import '../features/teacher_workspace/domain/usecases/update_task_usecase.dart';
import '../features/teacher_workspace/domain/usecases/delete_task_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_tasks_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_rubric_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_rubrics_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_rubric_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_oral_questions_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_oral_questions_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_oral_questions_usecase.dart';
import '../features/teacher_workspace/domain/usecases/generate_practical_assessment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_practical_assessments_usecase.dart';
import '../features/teacher_workspace/domain/usecases/create_practical_assessment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/share_resource_usecase.dart';
import '../features/teacher_workspace/domain/usecases/add_comment_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_comments_usecase.dart';
import '../features/teacher_workspace/domain/usecases/get_enhanced_dashboard_usecase.dart';
import '../features/teacher_workspace/presentation/providers/presentation_provider.dart';
import '../features/teacher_workspace/presentation/providers/communication_provider.dart';
import '../features/teacher_workspace/presentation/providers/task_provider.dart';
import '../features/teacher_workspace/presentation/providers/rubric_provider.dart';
import '../features/teacher_workspace/presentation/providers/oral_question_provider.dart';
import '../features/teacher_workspace/presentation/providers/practical_assessment_provider.dart';
import '../features/teacher_workspace/presentation/providers/collaboration_provider.dart';
import '../features/teacher_workspace/presentation/providers/enhanced_dashboard_provider.dart';

// ─── Data Source ───────────────────────────────────────────────────────────────

final teacherWorkspaceRemoteDataSourceProvider =
    Provider<TeacherWorkspaceRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return TeacherWorkspaceRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

// ─── Repository ────────────────────────────────────────────────────────────────

final teacherWorkspaceRepositoryProvider =
    Provider<TeacherWorkspaceRepository>((ref) {
  final remoteDataSource = ref.watch(teacherWorkspaceRemoteDataSourceProvider);
  return TeacherWorkspaceRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ─── Use Cases ─────────────────────────────────────────────────────────────────

final getWorkspaceDashboardUseCaseProvider =
    Provider<GetWorkspaceDashboardUseCase>((ref) {
  return GetWorkspaceDashboardUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createLessonPlanUseCaseProvider =
    Provider<CreateLessonPlanUseCase>((ref) {
  return CreateLessonPlanUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final updateLessonPlanUseCaseProvider =
    Provider<UpdateLessonPlanUseCase>((ref) {
  return UpdateLessonPlanUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final deleteLessonPlanUseCaseProvider =
    Provider<DeleteLessonPlanUseCase>((ref) {
  return DeleteLessonPlanUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getLessonPlansUseCaseProvider =
    Provider<GetLessonPlansUseCase>((ref) {
  return GetLessonPlansUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateLessonPlanUseCaseProvider =
    Provider<GenerateLessonPlanUseCase>((ref) {
  return GenerateLessonPlanUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createSchemeOfWorkUseCaseProvider =
    Provider<CreateSchemeOfWorkUseCase>((ref) {
  return CreateSchemeOfWorkUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getSchemesOfWorkUseCaseProvider =
    Provider<GetSchemesOfWorkUseCase>((ref) {
  return GetSchemesOfWorkUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateSchemeOfWorkUseCaseProvider =
    Provider<GenerateSchemeOfWorkUseCase>((ref) {
  return GenerateSchemeOfWorkUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createWorksheetUseCaseProvider =
    Provider<CreateWorksheetUseCase>((ref) {
  return CreateWorksheetUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getWorksheetsUseCaseProvider =
    Provider<GetWorksheetsUseCase>((ref) {
  return GetWorksheetsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateWorksheetUseCaseProvider =
    Provider<GenerateWorksheetUseCase>((ref) {
  return GenerateWorksheetUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final exportWorksheetUseCaseProvider =
    Provider<ExportWorksheetUseCase>((ref) {
  return ExportWorksheetUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createAssignmentUseCaseProvider =
    Provider<CreateAssignmentUseCase>((ref) {
  return CreateAssignmentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getAssignmentsUseCaseProvider =
    Provider<GetAssignmentsUseCase>((ref) {
  return GetAssignmentsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateAssignmentUseCaseProvider =
    Provider<GenerateAssignmentUseCase>((ref) {
  return GenerateAssignmentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final publishAssignmentUseCaseProvider =
    Provider<PublishAssignmentUseCase>((ref) {
  return PublishAssignmentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createReportCommentUseCaseProvider =
    Provider<CreateReportCommentUseCase>((ref) {
  return CreateReportCommentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateReportCommentsUseCaseProvider =
    Provider<GenerateReportCommentsUseCase>((ref) {
  return GenerateReportCommentsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createResourceUseCaseProvider =
    Provider<CreateResourceUseCase>((ref) {
  return CreateResourceUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getResourcesUseCaseProvider =
    Provider<GetResourcesUseCase>((ref) {
  return GetResourcesUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateResourceUseCaseProvider =
    Provider<GenerateResourceUseCase>((ref) {
  return GenerateResourceUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final toggleFavoriteUseCaseProvider =
    Provider<ToggleFavoriteUseCase>((ref) {
  return ToggleFavoriteUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final aiContentAssistantUseCaseProvider =
    Provider<AiContentAssistantUseCase>((ref) {
  return AiContentAssistantUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getContentHistoryUseCaseProvider =
    Provider<GetContentHistoryUseCase>((ref) {
  return GetContentHistoryUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createEventUseCaseProvider =
    Provider<CreateEventUseCase>((ref) {
  return CreateEventUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getEventsUseCaseProvider =
    Provider<GetEventsUseCase>((ref) {
  return GetEventsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final suggestScheduleUseCaseProvider =
    Provider<SuggestScheduleUseCase>((ref) {
  return SuggestScheduleUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getVersionHistoryUseCaseProvider =
    Provider<GetVersionHistoryUseCase>((ref) {
  return GetVersionHistoryUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateQuestionsFromContentUseCaseProvider =
    Provider<GenerateQuestionsFromContentUseCase>((ref) {
  return GenerateQuestionsFromContentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

// ─── Workspace Expansion Use Cases ──────────────────────────────────

final generatePresentationUseCaseProvider = Provider<GeneratePresentationUseCase>((ref) {
  return GeneratePresentationUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getPresentationsUseCaseProvider = Provider<GetPresentationsUseCase>((ref) {
  return GetPresentationsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createPresentationUseCaseProvider = Provider<CreatePresentationUseCase>((ref) {
  return CreatePresentationUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final exportPresentationUseCaseProvider = Provider<ExportPresentationUseCase>((ref) {
  return ExportPresentationUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateCommunicationUseCaseProvider = Provider<GenerateCommunicationUseCase>((ref) {
  return GenerateCommunicationUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getCommunicationsUseCaseProvider = Provider<GetCommunicationsUseCase>((ref) {
  return GetCommunicationsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createCommunicationUseCaseProvider = Provider<CreateCommunicationUseCase>((ref) {
  return CreateCommunicationUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  return UpdateTaskUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  return DeleteTaskUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getTasksUseCaseProvider = Provider<GetTasksUseCase>((ref) {
  return GetTasksUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateRubricUseCaseProvider = Provider<GenerateRubricUseCase>((ref) {
  return GenerateRubricUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getRubricsUseCaseProvider = Provider<GetRubricsUseCase>((ref) {
  return GetRubricsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createRubricUseCaseProvider = Provider<CreateRubricUseCase>((ref) {
  return CreateRubricUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generateOralQuestionsUseCaseProvider = Provider<GenerateOralQuestionsUseCase>((ref) {
  return GenerateOralQuestionsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getOralQuestionsUseCaseProvider = Provider<GetOralQuestionsUseCase>((ref) {
  return GetOralQuestionsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createOralQuestionsUseCaseProvider = Provider<CreateOralQuestionsUseCase>((ref) {
  return CreateOralQuestionsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final generatePracticalAssessmentUseCaseProvider = Provider<GeneratePracticalAssessmentUseCase>((ref) {
  return GeneratePracticalAssessmentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getPracticalAssessmentsUseCaseProvider = Provider<GetPracticalAssessmentsUseCase>((ref) {
  return GetPracticalAssessmentsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final createPracticalAssessmentUseCaseProvider = Provider<CreatePracticalAssessmentUseCase>((ref) {
  return CreatePracticalAssessmentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final shareResourceUseCaseProvider = Provider<ShareResourceUseCase>((ref) {
  return ShareResourceUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final addCommentUseCaseProvider = Provider<AddCommentUseCase>((ref) {
  return AddCommentUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getCommentsUseCaseProvider = Provider<GetCommentsUseCase>((ref) {
  return GetCommentsUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

final getEnhancedDashboardUseCaseProvider = Provider<GetEnhancedDashboardUseCase>((ref) {
  return GetEnhancedDashboardUseCase(ref.watch(teacherWorkspaceRepositoryProvider));
});

// ─── State Notifiers ───────────────────────────────────────────────────────────

final workspaceDashboardProvider =
    StateNotifierProvider<WorkspaceDashboardNotifier, WorkspaceDashboardState>(
        (ref) {
  return WorkspaceDashboardNotifier(
    getWorkspaceDashboardUseCase: ref.watch(getWorkspaceDashboardUseCaseProvider),
  );
});

final lessonPlanProvider =
    StateNotifierProvider<LessonPlanNotifier, LessonPlanState>((ref) {
  return LessonPlanNotifier(
    getLessonPlansUseCase: ref.watch(getLessonPlansUseCaseProvider),
    createLessonPlanUseCase: ref.watch(createLessonPlanUseCaseProvider),
    updateLessonPlanUseCase: ref.watch(updateLessonPlanUseCaseProvider),
    deleteLessonPlanUseCase: ref.watch(deleteLessonPlanUseCaseProvider),
    generateLessonPlanUseCase: ref.watch(generateLessonPlanUseCaseProvider),
  );
});

final schemeOfWorkProvider =
    StateNotifierProvider<SchemeOfWorkNotifier, SchemeOfWorkState>((ref) {
  return SchemeOfWorkNotifier(
    getSchemesOfWorkUseCase: ref.watch(getSchemesOfWorkUseCaseProvider),
    createSchemeOfWorkUseCase: ref.watch(createSchemeOfWorkUseCaseProvider),
    generateSchemeOfWorkUseCase: ref.watch(generateSchemeOfWorkUseCaseProvider),
  );
});

final worksheetProvider =
    StateNotifierProvider<WorksheetNotifier, WorksheetState>((ref) {
  return WorksheetNotifier(
    getWorksheetsUseCase: ref.watch(getWorksheetsUseCaseProvider),
    createWorksheetUseCase: ref.watch(createWorksheetUseCaseProvider),
    generateWorksheetUseCase: ref.watch(generateWorksheetUseCaseProvider),
    exportWorksheetUseCase: ref.watch(exportWorksheetUseCaseProvider),
  );
});

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
  return AssignmentNotifier(
    getAssignmentsUseCase: ref.watch(getAssignmentsUseCaseProvider),
    createAssignmentUseCase: ref.watch(createAssignmentUseCaseProvider),
    generateAssignmentUseCase: ref.watch(generateAssignmentUseCaseProvider),
    publishAssignmentUseCase: ref.watch(publishAssignmentUseCaseProvider),
  );
});

final reportCommentProvider =
    StateNotifierProvider<ReportCommentNotifier, ReportCommentState>((ref) {
  return ReportCommentNotifier(
    createReportCommentUseCase: ref.watch(createReportCommentUseCaseProvider),
    generateReportCommentsUseCase: ref.watch(generateReportCommentsUseCaseProvider),
  );
});

final teachingResourceProvider =
    StateNotifierProvider<TeachingResourceNotifier, TeachingResourceState>(
        (ref) {
  return TeachingResourceNotifier(
    getResourcesUseCase: ref.watch(getResourcesUseCaseProvider),
    createResourceUseCase: ref.watch(createResourceUseCaseProvider),
    generateResourceUseCase: ref.watch(generateResourceUseCaseProvider),
    toggleFavoriteUseCase: ref.watch(toggleFavoriteUseCaseProvider),
  );
});

final contentAssistantProvider =
    StateNotifierProvider<ContentAssistantNotifier, ContentAssistantState>(
        (ref) {
  return ContentAssistantNotifier(
    aiContentAssistantUseCase: ref.watch(aiContentAssistantUseCaseProvider),
    getContentHistoryUseCase: ref.watch(getContentHistoryUseCaseProvider),
  );
});

final resourceLibraryProvider =
    StateNotifierProvider<ResourceLibraryNotifier, ResourceLibraryState>((ref) {
  return ResourceLibraryNotifier(
    getResourcesUseCase: ref.watch(getResourcesUseCaseProvider),
    toggleFavoriteUseCase: ref.watch(toggleFavoriteUseCaseProvider),
  );
});

final calendarPlannerProvider =
    StateNotifierProvider<CalendarPlannerNotifier, CalendarPlannerState>((ref) {
  return CalendarPlannerNotifier(
    getEventsUseCase: ref.watch(getEventsUseCaseProvider),
    createEventUseCase: ref.watch(createEventUseCaseProvider),
    suggestScheduleUseCase: ref.watch(suggestScheduleUseCaseProvider),
  );
});

final generateQuestionsProvider =
    StateNotifierProvider<GenerateQuestionsNotifier, GenerateQuestionsState>(
        (ref) {
  return GenerateQuestionsNotifier(
    generateQuestionsFromContentUseCase:
        ref.watch(generateQuestionsFromContentUseCaseProvider),
  );
});

// ─── Workspace Expansion State Notifiers ────────────────────────────

final presentationProvider =
    StateNotifierProvider<PresentationNotifier, PresentationState>((ref) {
  return PresentationNotifier(
    getPresentationsUseCase: ref.watch(getPresentationsUseCaseProvider),
    createPresentationUseCase: ref.watch(createPresentationUseCaseProvider),
    generatePresentationUseCase: ref.watch(generatePresentationUseCaseProvider),
    exportPresentationUseCase: ref.watch(exportPresentationUseCaseProvider),
  );
});

final communicationProvider =
    StateNotifierProvider<CommunicationNotifier, CommunicationState>((ref) {
  return CommunicationNotifier(
    getCommunicationsUseCase: ref.watch(getCommunicationsUseCaseProvider),
    createCommunicationUseCase: ref.watch(createCommunicationUseCaseProvider),
    generateCommunicationUseCase: ref.watch(generateCommunicationUseCaseProvider),
  );
});

final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(
    getTasksUseCase: ref.watch(getTasksUseCaseProvider),
    createTaskUseCase: ref.watch(createTaskUseCaseProvider),
    updateTaskUseCase: ref.watch(updateTaskUseCaseProvider),
    deleteTaskUseCase: ref.watch(deleteTaskUseCaseProvider),
  );
});

final rubricProvider =
    StateNotifierProvider<RubricNotifier, RubricState>((ref) {
  return RubricNotifier(
    getRubricsUseCase: ref.watch(getRubricsUseCaseProvider),
    createRubricUseCase: ref.watch(createRubricUseCaseProvider),
    generateRubricUseCase: ref.watch(generateRubricUseCaseProvider),
  );
});

final oralQuestionProvider =
    StateNotifierProvider<OralQuestionNotifier, OralQuestionState>((ref) {
  return OralQuestionNotifier(
    getOralQuestionsUseCase: ref.watch(getOralQuestionsUseCaseProvider),
    createOralQuestionsUseCase: ref.watch(createOralQuestionsUseCaseProvider),
    generateOralQuestionsUseCase: ref.watch(generateOralQuestionsUseCaseProvider),
  );
});

final practicalAssessmentProvider =
    StateNotifierProvider<PracticalAssessmentNotifier, PracticalAssessmentState>((ref) {
  return PracticalAssessmentNotifier(
    getPracticalAssessmentsUseCase: ref.watch(getPracticalAssessmentsUseCaseProvider),
    createPracticalAssessmentUseCase: ref.watch(createPracticalAssessmentUseCaseProvider),
    generatePracticalAssessmentUseCase: ref.watch(generatePracticalAssessmentUseCaseProvider),
  );
});

final collaborationProvider =
    StateNotifierProvider<CollaborationNotifier, CollaborationState>((ref) {
  return CollaborationNotifier(
    shareResourceUseCase: ref.watch(shareResourceUseCaseProvider),
    addCommentUseCase: ref.watch(addCommentUseCaseProvider),
    getCommentsUseCase: ref.watch(getCommentsUseCaseProvider),
  );
});

final enhancedDashboardProvider =
    StateNotifierProvider<EnhancedDashboardNotifier, EnhancedDashboardState>((ref) {
  return EnhancedDashboardNotifier(
    getEnhancedDashboardUseCase: ref.watch(getEnhancedDashboardUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// STUDENT PORTAL MODULE
// ═══════════════════════════════════════════════════════════════════════

// ─── Student Portal Data Layer ───────────────────────────────────────

/// Provides the [StudentPortalRemoteDataSource] implementation.
final studentPortalRemoteDataSourceProvider =
    Provider<StudentPortalRemoteDatasource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return StudentPortalRemoteDatasource(supabaseClient: supabaseClient);
});

/// Provides the [StudentPortalRepository] implementation.
final studentPortalRepositoryProvider =
    Provider<StudentPortalRepository>((ref) {
  final remoteDataSource = ref.watch(studentPortalRemoteDataSourceProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return StudentPortalRepositoryImpl(
    remoteDatasource: remoteDataSource,
    supabaseClient: supabaseClient,
  );
});

// ─── Student Portal — AI Tutor Use Cases ─────────────────────────────

final createConversationUseCaseProvider =
    Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getConversationsUseCaseProvider =
    Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getConversationDetailUseCaseProvider =
    Provider<GetConversationDetailUseCase>((ref) {
  return GetConversationDetailUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(studentPortalRepositoryProvider));
});

final deleteConversationUseCaseProvider =
    Provider<DeleteConversationUseCase>((ref) {
  return DeleteConversationUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Practice Session Use Cases ─────────────────────

final createPracticeSessionUseCaseProvider =
    Provider<CreatePracticeSessionUseCase>((ref) {
  return CreatePracticeSessionUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final getPracticeSessionsUseCaseProvider =
    Provider<GetPracticeSessionsUseCase>((ref) {
  return GetPracticeSessionsUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final getPracticeSessionDetailUseCaseProvider =
    Provider<GetPracticeSessionDetailUseCase>((ref) {
  return GetPracticeSessionDetailUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final submitPracticeAnswerUseCaseProvider =
    Provider<SubmitPracticeAnswerUseCase>((ref) {
  return SubmitPracticeAnswerUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final completePracticeSessionUseCaseProvider =
    Provider<CompletePracticeSessionUseCase>((ref) {
  return CompletePracticeSessionUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Assignment Submission Use Cases ────────────────

final getSubmissionsUseCaseProvider = Provider<GetSubmissionsUseCase>((ref) {
  return GetSubmissionsUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getSubmissionDetailUseCaseProvider =
    Provider<GetSubmissionDetailUseCase>((ref) {
  return GetSubmissionDetailUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final createSubmissionUseCaseProvider =
    Provider<CreateSubmissionUseCase>((ref) {
  return CreateSubmissionUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final submitAssignmentUseCaseProvider =
    Provider<SubmitAssignmentUseCase>((ref) {
  return SubmitAssignmentUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final getAssignedAssignmentsUseCaseProvider =
    Provider<GetAssignedAssignmentsUseCase>((ref) {
  return GetAssignedAssignmentsUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Learning Resources Use Cases ───────────────────

final studentGetResourcesUseCaseProvider =
    Provider<GetStudentResourcesUseCase>((ref) {
  return GetStudentResourcesUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getResourceDetailUseCaseProvider =
    Provider<GetResourceDetailUseCase>((ref) {
  return GetResourceDetailUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final logResourceAccessUseCaseProvider =
    Provider<LogResourceAccessUseCase>((ref) {
  return LogResourceAccessUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Document Chat Use Cases ────────────────────────

final uploadDocumentUseCaseProvider = Provider<UploadDocumentUseCase>((ref) {
  return UploadDocumentUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getDocumentsUseCaseProvider = Provider<GetDocumentsUseCase>((ref) {
  return GetDocumentsUseCase(ref.watch(studentPortalRepositoryProvider));
});

final sendDocumentMessageUseCaseProvider =
    Provider<SendDocumentMessageUseCase>((ref) {
  return SendDocumentMessageUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Flashcard Use Cases ────────────────────────────

final getFlashcardDecksUseCaseProvider =
    Provider<GetFlashcardDecksUseCase>((ref) {
  return GetFlashcardDecksUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final createFlashcardDeckUseCaseProvider =
    Provider<CreateFlashcardDeckUseCase>((ref) {
  return CreateFlashcardDeckUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final getFlashcardsUseCaseProvider = Provider<GetFlashcardsUseCase>((ref) {
  return GetFlashcardsUseCase(ref.watch(studentPortalRepositoryProvider));
});

final createFlashcardUseCaseProvider =
    Provider<CreateFlashcardUseCase>((ref) {
  return CreateFlashcardUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final rateFlashcardUseCaseProvider = Provider<RateFlashcardUseCase>((ref) {
  return RateFlashcardUseCase(ref.watch(studentPortalRepositoryProvider));
});

final generateFlashcardsUseCaseProvider =
    Provider<GenerateFlashcardsUseCase>((ref) {
  return GenerateFlashcardsUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final deleteFlashcardDeckUseCaseProvider =
    Provider<DeleteFlashcardDeckUseCase>((ref) {
  return DeleteFlashcardDeckUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Study Planner Use Cases ────────────────────────

final getStudyPlansUseCaseProvider = Provider<GetStudyPlansUseCase>((ref) {
  return GetStudyPlansUseCase(ref.watch(studentPortalRepositoryProvider));
});

final createStudyPlanUseCaseProvider =
    Provider<CreateStudyPlanUseCase>((ref) {
  return CreateStudyPlanUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final updateStudyTaskUseCaseProvider =
    Provider<UpdateStudyTaskUseCase>((ref) {
  return UpdateStudyTaskUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final suggestStudyPlanUseCaseProvider =
    Provider<SuggestStudyPlanUseCase>((ref) {
  return SuggestStudyPlanUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final deleteStudyPlanUseCaseProvider =
    Provider<DeleteStudyPlanUseCase>((ref) {
  return DeleteStudyPlanUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Goals Use Cases ────────────────────────────────

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>((ref) {
  return GetGoalsUseCase(ref.watch(studentPortalRepositoryProvider));
});

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>((ref) {
  return CreateGoalUseCase(ref.watch(studentPortalRepositoryProvider));
});

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  return UpdateGoalUseCase(ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Progress & Analytics Use Cases ─────────────────

final getProgressUseCaseProvider = Provider<GetProgressUseCase>((ref) {
  return GetProgressUseCase(ref.watch(studentPortalRepositoryProvider));
});

final getLatestProgressUseCaseProvider =
    Provider<GetLatestProgressUseCase>((ref) {
  return GetLatestProgressUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final getDashboardStatsUseCaseProvider =
    Provider<GetDashboardStatsUseCase>((ref) {
  return GetDashboardStatsUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ─── Student Portal — Notification Use Cases ─────────────────────────

final getNotificationsUseCaseProvider =
    Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>((ref) {
  return MarkAllNotificationsReadUseCase(
      ref.watch(studentPortalRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT MODULE
// ═══════════════════════════════════════════════════════════════════════

import '../features/school_management/data/datasources/school_management_remote_datasource.dart';
import '../features/school_management/data/repositories/school_management_repository_impl.dart';
import '../features/school_management/domain/repositories/school_management_repository.dart';
import '../features/school_management/domain/usecases/school_usecases.dart';
import '../features/school_management/domain/usecases/student_usecases.dart';
import '../features/school_management/domain/usecases/teacher_usecases.dart';
import '../features/school_management/domain/usecases/parent_usecases.dart';
import '../features/school_management/domain/usecases/academic_session_usecases.dart';
import '../features/school_management/domain/usecases/timetable_usecases.dart';
import '../features/school_management/domain/usecases/attendance_usecases.dart';
import '../features/school_management/domain/usecases/homework_usecases.dart';
import '../features/school_management/domain/usecases/announcement_usecases.dart';
import '../features/school_management/domain/usecases/report_usecases.dart';

// ─── Data Source ──────────────────────────────────────────────────────

final schoolManagementRemoteDataSourceProvider =
    Provider<SchoolManagementRemoteDataSource>((ref) {
  return SchoolManagementRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// ─── Repository ──────────────────────────────────────────────────────

final schoolManagementRepositoryProvider =
    Provider<SchoolManagementRepository>((ref) {
  return SchoolManagementRepositoryImpl(
    remoteDataSource: ref.watch(schoolManagementRemoteDataSourceProvider),
  );
});

// ─── Use Cases ───────────────────────────────────────────────────────

// School
final createSchoolUseCaseProvider = Provider<CreateSchoolUseCase>((ref) {
  return CreateSchoolUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateSchoolUseCaseProvider = Provider<UpdateSchoolUseCase>((ref) {
  return UpdateSchoolUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getSchoolUseCaseProvider = Provider<GetSchoolUseCase>((ref) {
  return GetSchoolUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getSchoolsUseCaseProvider = Provider<GetSchoolsUseCase>((ref) {
  return GetSchoolsUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final createBranchUseCaseProvider = Provider<CreateBranchUseCase>((ref) {
  return CreateBranchUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateBranchUseCaseProvider = Provider<UpdateBranchUseCase>((ref) {
  return UpdateBranchUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final createDepartmentUseCaseProvider =
    Provider<CreateDepartmentUseCase>((ref) {
  return CreateDepartmentUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateDepartmentUseCaseProvider =
    Provider<UpdateDepartmentUseCase>((ref) {
  return UpdateDepartmentUseCase(ref.watch(schoolManagementRepositoryProvider));
});

// Student
final createStudentProfileUseCaseProvider =
    Provider<CreateStudentProfileUseCase>((ref) {
  return CreateStudentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateStudentProfileUseCaseProvider =
    Provider<UpdateStudentProfileUseCase>((ref) {
  return UpdateStudentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getStudentProfileUseCaseProvider =
    Provider<GetStudentProfileUseCase>((ref) {
  return GetStudentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getStudentProfilesUseCaseProvider =
    Provider<GetStudentProfilesUseCase>((ref) {
  return GetStudentProfilesUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final promoteStudentUseCaseProvider = Provider<PromoteStudentUseCase>((ref) {
  return PromoteStudentUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final graduateStudentUseCaseProvider =
    Provider<GraduateStudentUseCase>((ref) {
  return GraduateStudentUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Teacher
final createTeacherProfileUseCaseProvider =
    Provider<CreateTeacherProfileUseCase>((ref) {
  return CreateTeacherProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateTeacherProfileUseCaseProvider =
    Provider<UpdateTeacherProfileUseCase>((ref) {
  return UpdateTeacherProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getTeacherProfileUseCaseProvider =
    Provider<GetTeacherProfileUseCase>((ref) {
  return GetTeacherProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getTeacherProfilesUseCaseProvider =
    Provider<GetTeacherProfilesUseCase>((ref) {
  return GetTeacherProfilesUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Parent
final createParentProfileUseCaseProvider =
    Provider<CreateParentProfileUseCase>((ref) {
  return CreateParentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateParentProfileUseCaseProvider =
    Provider<UpdateParentProfileUseCase>((ref) {
  return UpdateParentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getParentProfileUseCaseProvider =
    Provider<GetParentProfileUseCase>((ref) {
  return GetParentProfileUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getParentProfilesUseCaseProvider =
    Provider<GetParentProfilesUseCase>((ref) {
  return GetParentProfilesUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final linkParentToStudentUseCaseProvider =
    Provider<LinkParentToStudentUseCase>((ref) {
  return LinkParentToStudentUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final unlinkParentFromStudentUseCaseProvider =
    Provider<UnlinkParentFromStudentUseCase>((ref) {
  return UnlinkParentFromStudentUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Academic Sessions
final createSessionUseCaseProvider = Provider<CreateSessionUseCase>((ref) {
  return CreateSessionUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateSessionUseCaseProvider = Provider<UpdateSessionUseCase>((ref) {
  return UpdateSessionUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getCurrentSessionUseCaseProvider =
    Provider<GetCurrentSessionUseCase>((ref) {
  return GetCurrentSessionUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final setCurrentSessionUseCaseProvider =
    Provider<SetCurrentSessionUseCase>((ref) {
  return SetCurrentSessionUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final createTermUseCaseProvider = Provider<CreateTermUseCase>((ref) {
  return CreateTermUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateTermUseCaseProvider = Provider<UpdateTermUseCase>((ref) {
  return UpdateTermUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getCurrentTermUseCaseProvider = Provider<GetCurrentTermUseCase>((ref) {
  return GetCurrentTermUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final setCurrentTermUseCaseProvider = Provider<SetCurrentTermUseCase>((ref) {
  return SetCurrentTermUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final createCalendarEventUseCaseProvider =
    Provider<CreateCalendarEventUseCase>((ref) {
  return CreateCalendarEventUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateCalendarEventUseCaseProvider =
    Provider<UpdateCalendarEventUseCase>((ref) {
  return UpdateCalendarEventUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getCalendarEventsUseCaseProvider =
    Provider<GetCalendarEventsUseCase>((ref) {
  return GetCalendarEventsUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Timetable
final createTimetableUseCaseProvider =
    Provider<CreateTimetableUseCase>((ref) {
  return CreateTimetableUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateTimetableUseCaseProvider =
    Provider<UpdateTimetableUseCase>((ref) {
  return UpdateTimetableUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getTimetableUseCaseProvider = Provider<GetTimetableUseCase>((ref) {
  return GetTimetableUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getTimetablesUseCaseProvider = Provider<GetTimetablesUseCase>((ref) {
  return GetTimetablesUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final addTimetableSlotUseCaseProvider =
    Provider<AddTimetableSlotUseCase>((ref) {
  return AddTimetableSlotUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateTimetableSlotUseCaseProvider =
    Provider<UpdateTimetableSlotUseCase>((ref) {
  return UpdateTimetableSlotUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final deleteTimetableSlotUseCaseProvider =
    Provider<DeleteTimetableSlotUseCase>((ref) {
  return DeleteTimetableSlotUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final publishTimetableUseCaseProvider =
    Provider<PublishTimetableUseCase>((ref) {
  return PublishTimetableUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final checkSlotConflictsUseCaseProvider =
    Provider<CheckSlotConflictsUseCase>((ref) {
  return CheckSlotConflictsUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Attendance
final createAttendanceRecordUseCaseProvider =
    Provider<CreateAttendanceRecordUseCase>((ref) {
  return CreateAttendanceRecordUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateAttendanceRecordUseCaseProvider =
    Provider<UpdateAttendanceRecordUseCase>((ref) {
  return UpdateAttendanceRecordUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getAttendanceRecordUseCaseProvider =
    Provider<GetAttendanceRecordUseCase>((ref) {
  return GetAttendanceRecordUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getAttendanceRecordsUseCaseProvider =
    Provider<GetAttendanceRecordsUseCase>((ref) {
  return GetAttendanceRecordsUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final markAttendanceUseCaseProvider = Provider<MarkAttendanceUseCase>((ref) {
  return MarkAttendanceUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final getAttendanceSummaryUseCaseProvider =
    Provider<GetAttendanceSummaryUseCase>((ref) {
  return GetAttendanceSummaryUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Homework
final createHomeworkUseCaseProvider = Provider<CreateHomeworkUseCase>((ref) {
  return CreateHomeworkUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final updateHomeworkUseCaseProvider = Provider<UpdateHomeworkUseCase>((ref) {
  return UpdateHomeworkUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final publishHomeworkUseCaseProvider =
    Provider<PublishHomeworkUseCase>((ref) {
  return PublishHomeworkUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final submitHomeworkUseCaseProvider = Provider<SubmitHomeworkUseCase>((ref) {
  return SubmitHomeworkUseCase(ref.watch(schoolManagementRepositoryProvider));
});

final gradeSubmissionUseCaseProvider =
    Provider<GradeSubmissionUseCase>((ref) {
  return GradeSubmissionUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getHomeworkSubmissionsUseCaseProvider =
    Provider<GetHomeworkSubmissionsUseCase>((ref) {
  return GetHomeworkSubmissionsUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Announcements
final createAnnouncementUseCaseProvider =
    Provider<CreateAnnouncementUseCase>((ref) {
  return CreateAnnouncementUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final updateAnnouncementUseCaseProvider =
    Provider<UpdateAnnouncementUseCase>((ref) {
  return UpdateAnnouncementUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final deleteAnnouncementUseCaseProvider =
    Provider<DeleteAnnouncementUseCase>((ref) {
  return DeleteAnnouncementUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final publishAnnouncementUseCaseProvider =
    Provider<PublishAnnouncementUseCase>((ref) {
  return PublishAnnouncementUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getAnnouncementsUseCaseProvider =
    Provider<GetAnnouncementsUseCase>((ref) {
  return GetAnnouncementsUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// Reports
final getSchoolOverviewUseCaseProvider =
    Provider<GetSchoolOverviewUseCase>((ref) {
  return GetSchoolOverviewUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getStudentListReportUseCaseProvider =
    Provider<GetStudentListReportUseCase>((ref) {
  return GetStudentListReportUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getTeacherListReportUseCaseProvider =
    Provider<GetTeacherListReportUseCase>((ref) {
  return GetTeacherListReportUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

final getAttendanceReportUseCaseProvider =
    Provider<GetAttendanceReportUseCase>((ref) {
  return GetAttendanceReportUseCase(
      ref.watch(schoolManagementRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════
// PARENT PORTAL
// ═══════════════════════════════════════════════════════════════════════

import '../features/parent_portal/data/datasources/parent_portal_remote_datasource.dart';
import '../features/parent_portal/data/repositories/parent_portal_repository_impl.dart';
import '../features/parent_portal/domain/repositories/parent_portal_repository.dart';
import '../features/parent_portal/domain/usecases/get_parent_dashboard_usecase.dart';
import '../features/parent_portal/domain/usecases/get_parent_insights_usecase.dart';
import '../features/parent_portal/domain/usecases/get_child_profile_usecase.dart';
import '../features/parent_portal/domain/usecases/get_child_performance_usecase.dart';
import '../features/parent_portal/domain/usecases/get_child_attendance_usecase.dart';
import '../features/parent_portal/domain/usecases/get_child_assignments_usecase.dart';
import '../features/parent_portal/domain/usecases/get_parent_notifications_usecase.dart';
import '../features/parent_portal/domain/usecases/mark_notification_read_usecase.dart';
import '../features/parent_portal/domain/usecases/get_parent_messages_usecase.dart';
import '../features/parent_portal/domain/usecases/mark_message_read_usecase.dart';
import '../features/parent_portal/domain/usecases/send_parent_message_usecase.dart';
import '../features/parent_portal/domain/usecases/get_message_threads_usecase.dart';
import '../features/parent_portal/domain/usecases/get_parent_calendar_usecase.dart';
import '../features/parent_portal/domain/usecases/dismiss_insight_usecase.dart';
import '../features/parent_portal/domain/usecases/ask_parent_assistant_usecase.dart';
import '../features/parent_portal/domain/usecases/download_report_usecase.dart';
import '../features/parent_portal/domain/usecases/record_engagement_usecase.dart';
import '../features/parent_portal/domain/usecases/get_engagement_analytics_usecase.dart';

// ─── Data Source ──────────────────────────────────────────────────────

final parentPortalRemoteDataSourceProvider =
    Provider<ParentPortalRemoteDataSource>((ref) {
  return ParentPortalRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// ─── Repository ──────────────────────────────────────────────────────

final parentPortalRepositoryProvider =
    Provider<ParentPortalRepository>((ref) {
  return ParentPortalRepositoryImpl(
    remoteDataSource: ref.watch(parentPortalRemoteDataSourceProvider),
  );
});

// ─── Use Cases ───────────────────────────────────────────────────────

final getParentDashboardUseCaseProvider =
    Provider<GetParentDashboardUseCase>((ref) {
  return GetParentDashboardUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getParentInsightsUseCaseProvider =
    Provider<GetParentInsightsUseCase>((ref) {
  return GetParentInsightsUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getChildProfileUseCaseProvider =
    Provider<GetChildProfileUseCase>((ref) {
  return GetChildProfileUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getChildPerformanceUseCaseProvider =
    Provider<GetChildPerformanceUseCase>((ref) {
  return GetChildPerformanceUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getChildAttendanceUseCaseProvider =
    Provider<GetChildAttendanceUseCase>((ref) {
  return GetChildAttendanceUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getChildAssignmentsUseCaseProvider =
    Provider<GetChildAssignmentsUseCase>((ref) {
  return GetChildAssignmentsUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getParentNotificationsUseCaseProvider =
    Provider<GetParentNotificationsUseCase>((ref) {
  return GetParentNotificationsUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getParentMessagesUseCaseProvider =
    Provider<GetParentMessagesUseCase>((ref) {
  return GetParentMessagesUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final markMessageReadUseCaseProvider =
    Provider<MarkMessageReadUseCase>((ref) {
  return MarkMessageReadUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final sendParentMessageUseCaseProvider =
    Provider<SendParentMessageUseCase>((ref) {
  return SendParentMessageUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getMessageThreadsUseCaseProvider =
    Provider<GetMessageThreadsUseCase>((ref) {
  return GetMessageThreadsUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getParentCalendarUseCaseProvider =
    Provider<GetParentCalendarUseCase>((ref) {
  return GetParentCalendarUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final dismissInsightUseCaseProvider =
    Provider<DismissInsightUseCase>((ref) {
  return DismissInsightUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final askParentAssistantUseCaseProvider =
    Provider<AskParentAssistantUseCase>((ref) {
  return AskParentAssistantUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final downloadReportUseCaseProvider =
    Provider<DownloadReportUseCase>((ref) {
  return DownloadReportUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final recordEngagementUseCaseProvider =
    Provider<RecordEngagementUseCase>((ref) {
  return RecordEngagementUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

final getEngagementAnalyticsUseCaseProvider =
    Provider<GetEngagementAnalyticsUseCase>((ref) {
  return GetEngagementAnalyticsUseCase(
      ref.watch(parentPortalRepositoryProvider));
});

// ─── State Notifiers ──────────────────────────────────────────────────

final parentDashboardProvider =
    StateNotifierProvider<ParentDashboardNotifier, ParentDashboardState>(
        (ref) {
  return ParentDashboardNotifier(
    getParentDashboardUseCase: ref.watch(getParentDashboardUseCaseProvider),
  );
});

final childProfileProvider =
    StateNotifierProvider<ChildProfileNotifier, ChildProfileState>((ref) {
  return ChildProfileNotifier(
    getChildProfileUseCase: ref.watch(getChildProfileUseCaseProvider),
  );
});

final childPerformanceProvider =
    StateNotifierProvider<ChildPerformanceNotifier, ChildPerformanceState>(
        (ref) {
  return ChildPerformanceNotifier(
    getChildPerformanceUseCase: ref.watch(getChildPerformanceUseCaseProvider),
  );
});

final childAttendanceProvider =
    StateNotifierProvider<ChildAttendanceNotifier, ChildAttendanceState>(
        (ref) {
  return ChildAttendanceNotifier(
    getChildAttendanceUseCase: ref.watch(getChildAttendanceUseCaseProvider),
  );
});

final childAssignmentsProvider =
    StateNotifierProvider<ChildAssignmentsNotifier, ChildAssignmentsState>(
        (ref) {
  return ChildAssignmentsNotifier(
    getChildAssignmentsUseCase: ref.watch(getChildAssignmentsUseCaseProvider),
  );
});

final parentMessagingProvider =
    StateNotifierProvider<ParentMessagingNotifier, ParentMessagingState>(
        (ref) {
  return ParentMessagingNotifier(
    sendParentMessageUseCase: ref.watch(sendParentMessageUseCaseProvider),
    getParentMessagesUseCase: ref.watch(getParentMessagesUseCaseProvider),
    getMessageThreadsUseCase: ref.watch(getMessageThreadsUseCaseProvider),
    markMessageReadUseCase: ref.watch(markMessageReadUseCaseProvider),
  );
});

final parentNotificationProvider =
    StateNotifierProvider<ParentNotificationNotifier, ParentNotificationState>(
        (ref) {
  return ParentNotificationNotifier(
    getParentNotificationsUseCase:
        ref.watch(getParentNotificationsUseCaseProvider),
    markNotificationReadUseCase:
        ref.watch(markNotificationReadUseCaseProvider),
  );
});

final parentCalendarProvider =
    StateNotifierProvider<ParentCalendarNotifier, ParentCalendarState>(
        (ref) {
  return ParentCalendarNotifier(
    getParentCalendarUseCase: ref.watch(getParentCalendarUseCaseProvider),
  );
});

final parentAssistantProvider =
    StateNotifierProvider<ParentAssistantNotifier, ParentAssistantState>(
        (ref) {
  return ParentAssistantNotifier(
    askParentAssistantUseCase: ref.watch(askParentAssistantUseCaseProvider),
  );
});

final parentInsightsProvider =
    StateNotifierProvider<ParentInsightsNotifier, ParentInsightsState>(
        (ref) {
  return ParentInsightsNotifier(
    getParentInsightsUseCase: ref.watch(getParentInsightsUseCaseProvider),
    dismissInsightUseCase: ref.watch(dismissInsightUseCaseProvider),
  );
});

final parentReportsProvider =
    StateNotifierProvider<ParentReportsNotifier, ParentReportsState>((ref) {
  return ParentReportsNotifier(
    downloadReportUseCase: ref.watch(downloadReportUseCaseProvider),
  );
});

final parentEngagementProvider =
    StateNotifierProvider<ParentEngagementNotifier, ParentEngagementState>(
        (ref) {
  return ParentEngagementNotifier(
    getEngagementAnalyticsUseCase:
        ref.watch(getEngagementAnalyticsUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════

import '../features/communication/data/datasources/communication_remote_datasource.dart';
import '../features/communication/data/repositories/communication_repository_impl.dart';
import '../features/communication/domain/repositories/communication_repository.dart';
// Use cases
import '../features/communication/domain/usecases/get_conversations_usecase.dart';
import '../features/communication/domain/usecases/create_conversation_usecase.dart';
import '../features/communication/domain/usecases/get_messages_usecase.dart';
import '../features/communication/domain/usecases/send_message_usecase.dart';
import '../features/communication/domain/usecases/edit_message_usecase.dart';
import '../features/communication/domain/usecases/delete_message_usecase.dart';
import '../features/communication/domain/usecases/pin_message_usecase.dart';
import '../features/communication/domain/usecases/add_reaction_usecase.dart';
import '../features/communication/domain/usecases/mark_as_read_usecase.dart';
import '../features/communication/domain/usecases/get_announcements_usecase.dart';
import '../features/communication/domain/usecases/create_announcement_usecase.dart';
import '../features/communication/domain/usecases/acknowledge_announcement_usecase.dart';
import '../features/communication/domain/usecases/get_notifications_usecase.dart';
import '../features/communication/domain/usecases/mark_notification_read_usecase.dart';
import '../features/communication/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../features/communication/domain/usecases/get_notification_preferences_usecase.dart';
import '../features/communication/domain/usecases/update_notification_preferences_usecase.dart';
import '../features/communication/domain/usecases/get_forums_usecase.dart';
import '../features/communication/domain/usecases/create_forum_usecase.dart';
import '../features/communication/domain/usecases/get_forum_posts_usecase.dart';
import '../features/communication/domain/usecases/create_forum_post_usecase.dart';
import '../features/communication/domain/usecases/create_forum_comment_usecase.dart';
import '../features/communication/domain/usecases/get_calendar_events_usecase.dart';
import '../features/communication/domain/usecases/create_calendar_event_usecase.dart';
import '../features/communication/domain/usecases/rsvp_to_event_usecase.dart';
import '../features/communication/domain/usecases/ai_draft_announcement_usecase.dart';
import '../features/communication/domain/usecases/ai_rewrite_message_usecase.dart';
import '../features/communication/domain/usecases/ai_summarize_conversation_usecase.dart';
import '../features/communication/domain/usecases/ai_translate_message_usecase.dart';
import '../features/communication/domain/usecases/ai_suggest_reply_usecase.dart';
import '../features/communication/domain/usecases/ai_correct_grammar_usecase.dart';
import '../features/communication/domain/usecases/ai_adjust_tone_usecase.dart';
import '../features/communication/domain/usecases/ask_school_knowledge_usecase.dart';
import '../features/communication/domain/usecases/get_knowledge_documents_usecase.dart';
import '../features/communication/domain/usecases/upload_knowledge_document_usecase.dart';
import '../features/communication/domain/usecases/report_message_usecase.dart';
import '../features/communication/domain/usecases/mute_conversation_usecase.dart';
import '../features/communication/domain/usecases/archive_conversation_usecase.dart';
import '../features/communication/domain/usecases/get_audit_logs_usecase.dart';
import '../features/communication/domain/usecases/get_communication_dashboard_usecase.dart';
import '../features/communication/domain/usecases/set_typing_usecase.dart';
import '../features/communication/domain/usecases/update_presence_usecase.dart';
// Providers
import '../features/communication/presentation/providers/conversation_provider.dart';
import '../features/communication/presentation/providers/message_provider.dart';
import '../features/communication/presentation/providers/announcement_provider.dart';
import '../features/communication/presentation/providers/notification_provider.dart';
import '../features/communication/presentation/providers/forum_provider.dart';
import '../features/communication/presentation/providers/calendar_provider.dart';
import '../features/communication/presentation/providers/ai_assistant_provider.dart';
import '../features/communication/presentation/providers/knowledge_assistant_provider.dart';
import '../features/communication/presentation/providers/communication_dashboard_provider.dart';
import '../features/communication/presentation/providers/moderation_provider.dart';

// ── Billing & Subscription ──
import '../features/billing/data/datasources/billing_remote_datasource.dart';
import '../features/billing/data/datasources/flutterwave_datasource.dart';
import '../features/billing/data/repositories/billing_repository_impl.dart';
import '../features/billing/domain/repositories/billing_repository.dart';
import '../features/billing/domain/usecases/get_subscription_plans_usecase.dart';
import '../features/billing/domain/usecases/manage_subscription_usecase.dart';
import '../features/billing/domain/usecases/process_payment_usecase.dart';
import '../features/billing/domain/usecases/manage_ai_credits_usecase.dart';
import '../features/billing/domain/usecases/manage_coupons_usecase.dart';
import '../features/billing/domain/usecases/manage_referrals_usecase.dart';
import '../features/billing/domain/usecases/manage_invoices_usecase.dart';
import '../features/billing/domain/usecases/manage_licenses_usecase.dart';
import '../features/billing/domain/usecases/get_revenue_analytics_usecase.dart';
import '../features/billing/domain/usecases/manage_school_billing_usecase.dart';
import '../features/billing/domain/usecases/manage_billing_notifications_usecase.dart';
import '../features/billing/presentation/providers/subscription_provider.dart';
import '../features/billing/presentation/providers/payment_provider.dart';
import '../features/billing/presentation/providers/ai_credits_provider.dart';
import '../features/billing/presentation/providers/coupon_provider.dart';
import '../features/billing/presentation/providers/referral_provider.dart';
import '../features/billing/presentation/providers/invoice_provider.dart';
import '../features/billing/presentation/providers/license_provider.dart';
import '../features/billing/presentation/providers/revenue_provider.dart';
import '../features/billing/presentation/providers/school_billing_provider.dart';
import '../features/billing/presentation/providers/billing_notification_provider.dart';

// ─── Data Source ──────────────────────────────────────────────────────

final communicationRemoteDataSourceProvider =
    Provider<CommunicationRemoteDataSource>((ref) {
  return CommunicationRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// ─── Repository ──────────────────────────────────────────────────────

final communicationRepositoryProvider =
    Provider<CommunicationRepository>((ref) {
  return CommunicationRepositoryImpl(
    remoteDataSource: ref.watch(communicationRemoteDataSourceProvider),
  );
});

// ─── Use Cases ───────────────────────────────────────────────────────

final getConversationsUseCaseProvider =
    Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(communicationRepositoryProvider));
});

final createConversationUseCaseProvider =
    Provider<CreateConversationUseCase>((ref) {
  return CreateConversationUseCase(ref.watch(communicationRepositoryProvider));
});

final getMessagesUseCaseProvider =
    Provider<GetMessagesUseCase>((ref) {
  return GetMessagesUseCase(ref.watch(communicationRepositoryProvider));
});

final sendMessageUseCaseProvider =
    Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final editMessageUseCaseProvider =
    Provider<EditMessageUseCase>((ref) {
  return EditMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final deleteMessageUseCaseProvider =
    Provider<DeleteMessageUseCase>((ref) {
  return DeleteMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final pinMessageUseCaseProvider =
    Provider<PinMessageUseCase>((ref) {
  return PinMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final addReactionUseCaseProvider =
    Provider<AddReactionUseCase>((ref) {
  return AddReactionUseCase(ref.watch(communicationRepositoryProvider));
});

final markAsReadUseCaseProvider =
    Provider<MarkAsReadUseCase>((ref) {
  return MarkAsReadUseCase(ref.watch(communicationRepositoryProvider));
});

final getAnnouncementsUseCaseProvider =
    Provider<GetAnnouncementsUseCase>((ref) {
  return GetAnnouncementsUseCase(ref.watch(communicationRepositoryProvider));
});

final createAnnouncementUseCaseProvider =
    Provider<CreateAnnouncementUseCase>((ref) {
  return CreateAnnouncementUseCase(ref.watch(communicationRepositoryProvider));
});

final acknowledgeAnnouncementUseCaseProvider =
    Provider<AcknowledgeAnnouncementUseCase>((ref) {
  return AcknowledgeAnnouncementUseCase(ref.watch(communicationRepositoryProvider));
});

final getNotificationsUseCaseProvider =
    Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(communicationRepositoryProvider));
});

final markNotificationReadUseCaseProvider =
    Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(communicationRepositoryProvider));
});

final markAllNotificationsReadUseCaseProvider =
    Provider<MarkAllNotificationsReadUseCase>((ref) {
  return MarkAllNotificationsReadUseCase(ref.watch(communicationRepositoryProvider));
});

final getNotificationPreferencesUseCaseProvider =
    Provider<GetNotificationPreferencesUseCase>((ref) {
  return GetNotificationPreferencesUseCase(ref.watch(communicationRepositoryProvider));
});

final updateNotificationPreferencesUseCaseProvider =
    Provider<UpdateNotificationPreferencesUseCase>((ref) {
  return UpdateNotificationPreferencesUseCase(ref.watch(communicationRepositoryProvider));
});

final getForumsUseCaseProvider =
    Provider<GetForumsUseCase>((ref) {
  return GetForumsUseCase(ref.watch(communicationRepositoryProvider));
});

final createForumUseCaseProvider =
    Provider<CreateForumUseCase>((ref) {
  return CreateForumUseCase(ref.watch(communicationRepositoryProvider));
});

final getForumPostsUseCaseProvider =
    Provider<GetForumPostsUseCase>((ref) {
  return GetForumPostsUseCase(ref.watch(communicationRepositoryProvider));
});

final createForumPostUseCaseProvider =
    Provider<CreateForumPostUseCase>((ref) {
  return CreateForumPostUseCase(ref.watch(communicationRepositoryProvider));
});

final createForumCommentUseCaseProvider =
    Provider<CreateForumCommentUseCase>((ref) {
  return CreateForumCommentUseCase(ref.watch(communicationRepositoryProvider));
});

final getCalendarEventsUseCaseProvider =
    Provider<GetCalendarEventsUseCase>((ref) {
  return GetCalendarEventsUseCase(ref.watch(communicationRepositoryProvider));
});

final createCalendarEventUseCaseProvider =
    Provider<CreateCalendarEventUseCase>((ref) {
  return CreateCalendarEventUseCase(ref.watch(communicationRepositoryProvider));
});

final rsvpToEventUseCaseProvider =
    Provider<RsvpToEventUseCase>((ref) {
  return RsvpToEventUseCase(ref.watch(communicationRepositoryProvider));
});

final aiDraftAnnouncementUseCaseProvider =
    Provider<AiDraftAnnouncementUseCase>((ref) {
  return AiDraftAnnouncementUseCase(ref.watch(communicationRepositoryProvider));
});

final aiRewriteMessageUseCaseProvider =
    Provider<AiRewriteMessageUseCase>((ref) {
  return AiRewriteMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final aiSummarizeConversationUseCaseProvider =
    Provider<AiSummarizeConversationUseCase>((ref) {
  return AiSummarizeConversationUseCase(ref.watch(communicationRepositoryProvider));
});

final aiTranslateMessageUseCaseProvider =
    Provider<AiTranslateMessageUseCase>((ref) {
  return AiTranslateMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final aiSuggestReplyUseCaseProvider =
    Provider<AiSuggestReplyUseCase>((ref) {
  return AiSuggestReplyUseCase(ref.watch(communicationRepositoryProvider));
});

final aiCorrectGrammarUseCaseProvider =
    Provider<AiCorrectGrammarUseCase>((ref) {
  return AiCorrectGrammarUseCase(ref.watch(communicationRepositoryProvider));
});

final aiAdjustToneUseCaseProvider =
    Provider<AiAdjustToneUseCase>((ref) {
  return AiAdjustToneUseCase(ref.watch(communicationRepositoryProvider));
});

final askSchoolKnowledgeUseCaseProvider =
    Provider<AskSchoolKnowledgeUseCase>((ref) {
  return AskSchoolKnowledgeUseCase(ref.watch(communicationRepositoryProvider));
});

final getKnowledgeDocumentsUseCaseProvider =
    Provider<GetKnowledgeDocumentsUseCase>((ref) {
  return GetKnowledgeDocumentsUseCase(ref.watch(communicationRepositoryProvider));
});

final uploadKnowledgeDocumentUseCaseProvider =
    Provider<UploadKnowledgeDocumentUseCase>((ref) {
  return UploadKnowledgeDocumentUseCase(ref.watch(communicationRepositoryProvider));
});

final reportMessageUseCaseProvider =
    Provider<ReportMessageUseCase>((ref) {
  return ReportMessageUseCase(ref.watch(communicationRepositoryProvider));
});

final muteConversationUseCaseProvider =
    Provider<MuteConversationUseCase>((ref) {
  return MuteConversationUseCase(ref.watch(communicationRepositoryProvider));
});

final archiveConversationUseCaseProvider =
    Provider<ArchiveConversationUseCase>((ref) {
  return ArchiveConversationUseCase(ref.watch(communicationRepositoryProvider));
});

final getAuditLogsUseCaseProvider =
    Provider<GetAuditLogsUseCase>((ref) {
  return GetAuditLogsUseCase(ref.watch(communicationRepositoryProvider));
});

final getCommunicationDashboardUseCaseProvider =
    Provider<GetCommunicationDashboardUseCase>((ref) {
  return GetCommunicationDashboardUseCase(ref.watch(communicationRepositoryProvider));
});

final setTypingUseCaseProvider =
    Provider<SetTypingUseCase>((ref) {
  return SetTypingUseCase(ref.watch(communicationRepositoryProvider));
});

final updatePresenceUseCaseProvider =
    Provider<UpdatePresenceUseCase>((ref) {
  return UpdatePresenceUseCase(ref.watch(communicationRepositoryProvider));
});

// ─── State Notifiers ──────────────────────────────────────────────────

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
  return ConversationNotifier(
    getConversationsUseCase: ref.watch(getConversationsUseCaseProvider),
    createConversationUseCase: ref.watch(createConversationUseCaseProvider),
    muteConversationUseCase: ref.watch(muteConversationUseCaseProvider),
    archiveConversationUseCase: ref.watch(archiveConversationUseCaseProvider),
  );
});

final messageProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
  return MessageNotifier(
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    sendMessageUseCase: ref.watch(sendMessageUseCaseProvider),
    editMessageUseCase: ref.watch(editMessageUseCaseProvider),
    deleteMessageUseCase: ref.watch(deleteMessageUseCaseProvider),
    pinMessageUseCase: ref.watch(pinMessageUseCaseProvider),
    markAsReadUseCase: ref.watch(markAsReadUseCaseProvider),
    addReactionUseCase: ref.watch(addReactionUseCaseProvider),
  );
});

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>((ref) {
  return AnnouncementNotifier(
    getAnnouncementsUseCase: ref.watch(getAnnouncementsUseCaseProvider),
    createAnnouncementUseCase: ref.watch(createAnnouncementUseCaseProvider),
    acknowledgeAnnouncementUseCase: ref.watch(acknowledgeAnnouncementUseCaseProvider),
  );
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(
    getNotificationsUseCase: ref.watch(getNotificationsUseCaseProvider),
    markNotificationReadUseCase: ref.watch(markNotificationReadUseCaseProvider),
    markAllNotificationsReadUseCase: ref.watch(markAllNotificationsReadUseCaseProvider),
    getNotificationPreferencesUseCase: ref.watch(getNotificationPreferencesUseCaseProvider),
    updateNotificationPreferencesUseCase: ref.watch(updateNotificationPreferencesUseCaseProvider),
  );
});

final forumProvider =
    StateNotifierProvider<ForumNotifier, ForumState>((ref) {
  return ForumNotifier(
    getForumsUseCase: ref.watch(getForumsUseCaseProvider),
    createForumUseCase: ref.watch(createForumUseCaseProvider),
    getForumPostsUseCase: ref.watch(getForumPostsUseCaseProvider),
    createForumPostUseCase: ref.watch(createForumPostUseCaseProvider),
    createForumCommentUseCase: ref.watch(createForumCommentUseCaseProvider),
  );
});

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(
    getCalendarEventsUseCase: ref.watch(getCalendarEventsUseCaseProvider),
    createCalendarEventUseCase: ref.watch(createCalendarEventUseCaseProvider),
    rsvpToEventUseCase: ref.watch(rsvpToEventUseCaseProvider),
  );
});

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier(
    aiDraftAnnouncementUseCase: ref.watch(aiDraftAnnouncementUseCaseProvider),
    aiRewriteMessageUseCase: ref.watch(aiRewriteMessageUseCaseProvider),
    aiSummarizeConversationUseCase: ref.watch(aiSummarizeConversationUseCaseProvider),
    aiTranslateMessageUseCase: ref.watch(aiTranslateMessageUseCaseProvider),
    aiSuggestReplyUseCase: ref.watch(aiSuggestReplyUseCaseProvider),
    aiCorrectGrammarUseCase: ref.watch(aiCorrectGrammarUseCaseProvider),
    aiAdjustToneUseCase: ref.watch(aiAdjustToneUseCaseProvider),
  );
});

final knowledgeAssistantProvider =
    StateNotifierProvider<KnowledgeAssistantNotifier, KnowledgeAssistantState>((ref) {
  return KnowledgeAssistantNotifier(
    askSchoolKnowledgeUseCase: ref.watch(askSchoolKnowledgeUseCaseProvider),
    getKnowledgeDocumentsUseCase: ref.watch(getKnowledgeDocumentsUseCaseProvider),
    uploadKnowledgeDocumentUseCase: ref.watch(uploadKnowledgeDocumentUseCaseProvider),
  );
});

final communicationDashboardProvider =
    StateNotifierProvider<CommunicationDashboardNotifier, CommunicationDashboardState>((ref) {
  return CommunicationDashboardNotifier(
    getCommunicationDashboardUseCase: ref.watch(getCommunicationDashboardUseCaseProvider),
  );
});

final moderationProvider =
    StateNotifierProvider<ModerationNotifier, ModerationState>((ref) {
  return ModerationNotifier(
    reportMessageUseCase: ref.watch(reportMessageUseCaseProvider),
    muteConversationUseCase: ref.watch(muteConversationUseCaseProvider),
    archiveConversationUseCase: ref.watch(archiveConversationUseCaseProvider),
    getAuditLogsUseCase: ref.watch(getAuditLogsUseCaseProvider),
  );
});

// ════════════════════════════════════════════════════════════════════════════
// BILLING & SUBSCRIPTION
// ════════════════════════════════════════════════════════════════════════════

// ─── Data Layer ─────────────────────────────────────────────────────────────

final billingRemoteDataSourceProvider = Provider<BillingRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return BillingRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

final flutterwaveDataSourceProvider = Provider<FlutterwaveDataSource>((ref) {
  return FlutterwaveDataSourceImpl(
    secretKey: EnvConfig.flutterwaveSecretKey,
    publicKey: EnvConfig.flutterwavePublicKey,
    webhookSecretHash: EnvConfig.flutterwaveWebhookSecretHash,
    dio: ref.watch(dioProvider),
  );
});

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(
    remoteDataSource: ref.watch(billingRemoteDataSourceProvider),
    flutterwaveDataSource: ref.watch(flutterwaveDataSourceProvider),
  );
});

// ─── Use Cases ──────────────────────────────────────────────────────────────

// Subscription Plans
final getSubscriptionPlansUseCaseProvider = Provider<GetSubscriptionPlansUseCase>((ref) {
  return GetSubscriptionPlansUseCase(ref.watch(billingRepositoryProvider));
});

// Subscription Management
final createSubscriptionUseCaseProvider = Provider<CreateSubscriptionUseCase>((ref) {
  return CreateSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final upgradeSubscriptionUseCaseProvider = Provider<UpgradeSubscriptionUseCase>((ref) {
  return UpgradeSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final downgradeSubscriptionUseCaseProvider = Provider<DowngradeSubscriptionUseCase>((ref) {
  return DowngradeSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final cancelSubscriptionUseCaseProvider = Provider<CancelSubscriptionUseCase>((ref) {
  return CancelSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final renewSubscriptionUseCaseProvider = Provider<RenewSubscriptionUseCase>((ref) {
  return RenewSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final pauseSubscriptionUseCaseProvider = Provider<PauseSubscriptionUseCase>((ref) {
  return PauseSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final resumeSubscriptionUseCaseProvider = Provider<ResumeSubscriptionUseCase>((ref) {
  return ResumeSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final getCurrentSubscriptionUseCaseProvider = Provider<GetCurrentSubscriptionUseCase>((ref) {
  return GetCurrentSubscriptionUseCase(ref.watch(billingRepositoryProvider));
});
final getSubscriptionsUseCaseProvider = Provider<GetSubscriptionsUseCase>((ref) {
  return GetSubscriptionsUseCase(ref.watch(billingRepositoryProvider));
});

// Payments
final initializePaymentUseCaseProvider = Provider<InitializePaymentUseCase>((ref) {
  return InitializePaymentUseCase(ref.watch(billingRepositoryProvider));
});
final verifyPaymentUseCaseProvider = Provider<VerifyPaymentUseCase>((ref) {
  return VerifyPaymentUseCase(ref.watch(billingRepositoryProvider));
});
final processWebhookUseCaseProvider = Provider<ProcessWebhookUseCase>((ref) {
  return ProcessWebhookUseCase(ref.watch(billingRepositoryProvider));
});
final requestRefundUseCaseProvider = Provider<RequestRefundUseCase>((ref) {
  return RequestRefundUseCase(ref.watch(billingRepositoryProvider));
});
final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  return GetTransactionsUseCase(ref.watch(billingRepositoryProvider));
});

// AI Credits
final getCreditBalanceUseCaseProvider = Provider<GetCreditBalanceUseCase>((ref) {
  return GetCreditBalanceUseCase(ref.watch(billingRepositoryProvider));
});
final getCreditTransactionsUseCaseProvider = Provider<GetCreditTransactionsUseCase>((ref) {
  return GetCreditTransactionsUseCase(ref.watch(billingRepositoryProvider));
});
final consumeCreditsUseCaseProvider = Provider<ConsumeCreditsUseCase>((ref) {
  return ConsumeCreditsUseCase(ref.watch(billingRepositoryProvider));
});
final purchaseCreditsUseCaseProvider = Provider<PurchaseCreditsUseCase>((ref) {
  return PurchaseCreditsUseCase(ref.watch(billingRepositoryProvider));
});
final getCreditPacksUseCaseProvider = Provider<GetCreditPacksUseCase>((ref) {
  return GetCreditPacksUseCase(ref.watch(billingRepositoryProvider));
});

// Coupons
final validateCouponUseCaseProvider = Provider<ValidateCouponUseCase>((ref) {
  return ValidateCouponUseCase(ref.watch(billingRepositoryProvider));
});
final redeemCouponUseCaseProvider = Provider<RedeemCouponUseCase>((ref) {
  return RedeemCouponUseCase(ref.watch(billingRepositoryProvider));
});
final getCouponsUseCaseProvider = Provider<GetCouponsUseCase>((ref) {
  return GetCouponsUseCase(ref.watch(billingRepositoryProvider));
});
final createCouponUseCaseProvider = Provider<CreateCouponUseCase>((ref) {
  return CreateCouponUseCase(ref.watch(billingRepositoryProvider));
});
final updateCouponUseCaseProvider = Provider<UpdateCouponUseCase>((ref) {
  return UpdateCouponUseCase(ref.watch(billingRepositoryProvider));
});

// Referrals
final getOrCreateReferralCodeUseCaseProvider = Provider<GetOrCreateReferralCodeUseCase>((ref) {
  return GetOrCreateReferralCodeUseCase(ref.watch(billingRepositoryProvider));
});
final applyReferralCodeUseCaseProvider = Provider<ApplyReferralCodeUseCase>((ref) {
  return ApplyReferralCodeUseCase(ref.watch(billingRepositoryProvider));
});
final getReferralTrackingUseCaseProvider = Provider<GetReferralTrackingUseCase>((ref) {
  return GetReferralTrackingUseCase(ref.watch(billingRepositoryProvider));
});

// Invoices
final getInvoicesUseCaseProvider = Provider<GetInvoicesUseCase>((ref) {
  return GetInvoicesUseCase(ref.watch(billingRepositoryProvider));
});
final getInvoiceUseCaseProvider = Provider<GetInvoiceUseCase>((ref) {
  return GetInvoiceUseCase(ref.watch(billingRepositoryProvider));
});
final generateInvoiceUseCaseProvider = Provider<GenerateInvoiceUseCase>((ref) {
  return GenerateInvoiceUseCase(ref.watch(billingRepositoryProvider));
});
final getInvoicePdfUrlUseCaseProvider = Provider<GetInvoicePdfUrlUseCase>((ref) {
  return GetInvoicePdfUrlUseCase(ref.watch(billingRepositoryProvider));
});
final getReceiptsUseCaseProvider = Provider<GetReceiptsUseCase>((ref) {
  return GetReceiptsUseCase(ref.watch(billingRepositoryProvider));
});
final getReceiptPdfUrlUseCaseProvider = Provider<GetReceiptPdfUrlUseCase>((ref) {
  return GetReceiptPdfUrlUseCase(ref.watch(billingRepositoryProvider));
});

// Licenses
final getLicensesUseCaseProvider = Provider<GetLicensesUseCase>((ref) {
  return GetLicensesUseCase(ref.watch(billingRepositoryProvider));
});
final revokeLicenseUseCaseProvider = Provider<RevokeLicenseUseCase>((ref) {
  return RevokeLicenseUseCase(ref.watch(billingRepositoryProvider));
});

// Revenue Analytics
final getRevenueDataUseCaseProvider = Provider<GetRevenueDataUseCase>((ref) {
  return GetRevenueDataUseCase(ref.watch(billingRepositoryProvider));
});
final getBillingDashboardSummaryUseCaseProvider = Provider<GetBillingDashboardSummaryUseCase>((ref) {
  return GetBillingDashboardSummaryUseCase(ref.watch(billingRepositoryProvider));
});

// School Billing
final getSchoolBillingProfileUseCaseProvider = Provider<GetSchoolBillingProfileUseCase>((ref) {
  return GetSchoolBillingProfileUseCase(ref.watch(billingRepositoryProvider));
});
final updateSchoolBillingProfileUseCaseProvider = Provider<UpdateSchoolBillingProfileUseCase>((ref) {
  return UpdateSchoolBillingProfileUseCase(ref.watch(billingRepositoryProvider));
});

// Billing Notifications
final getBillingNotificationsUseCaseProvider = Provider<GetBillingNotificationsUseCase>((ref) {
  return GetBillingNotificationsUseCase(ref.watch(billingRepositoryProvider));
});
final markNotificationReadUseCaseProvider = Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(billingRepositoryProvider));
});
final updateNotificationPreferencesUseCaseProvider = Provider<UpdateNotificationPreferencesUseCase>((ref) {
  return UpdateNotificationPreferencesUseCase(ref.watch(billingRepositoryProvider));
});

// ─── Presentation Layer (State Notifiers) ───────────────────────────────────

final billingSubscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(
    getSubscriptionPlansUseCase: ref.watch(getSubscriptionPlansUseCaseProvider),
    getCurrentSubscriptionUseCase: ref.watch(getCurrentSubscriptionUseCaseProvider),
    createSubscriptionUseCase: ref.watch(createSubscriptionUseCaseProvider),
    upgradeSubscriptionUseCase: ref.watch(upgradeSubscriptionUseCaseProvider),
    downgradeSubscriptionUseCase: ref.watch(downgradeSubscriptionUseCaseProvider),
    cancelSubscriptionUseCase: ref.watch(cancelSubscriptionUseCaseProvider),
    renewSubscriptionUseCase: ref.watch(renewSubscriptionUseCaseProvider),
    pauseSubscriptionUseCase: ref.watch(pauseSubscriptionUseCaseProvider),
    resumeSubscriptionUseCase: ref.watch(resumeSubscriptionUseCaseProvider),
  );
});

final billingPaymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    initializePaymentUseCase: ref.watch(initializePaymentUseCaseProvider),
    verifyPaymentUseCase: ref.watch(verifyPaymentUseCaseProvider),
    getTransactionsUseCase: ref.watch(getTransactionsUseCaseProvider),
    requestRefundUseCase: ref.watch(requestRefundUseCaseProvider),
  );
});

final billingAiCreditsProvider =
    StateNotifierProvider<AiCreditsNotifier, AiCreditsState>((ref) {
  return AiCreditsNotifier(
    getCreditBalanceUseCase: ref.watch(getCreditBalanceUseCaseProvider),
    getCreditTransactionsUseCase: ref.watch(getCreditTransactionsUseCaseProvider),
    consumeCreditsUseCase: ref.watch(consumeCreditsUseCaseProvider),
    purchaseCreditsUseCase: ref.watch(purchaseCreditsUseCaseProvider),
    getCreditPacksUseCase: ref.watch(getCreditPacksUseCaseProvider),
  );
});

final billingCouponProvider =
    StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(
    validateCouponUseCase: ref.watch(validateCouponUseCaseProvider),
    redeemCouponUseCase: ref.watch(redeemCouponUseCaseProvider),
    getCouponsUseCase: ref.watch(getCouponsUseCaseProvider),
    createCouponUseCase: ref.watch(createCouponUseCaseProvider),
    updateCouponUseCase: ref.watch(updateCouponUseCaseProvider),
  );
});

final billingReferralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>((ref) {
  return ReferralNotifier(
    getOrCreateReferralCodeUseCase: ref.watch(getOrCreateReferralCodeUseCaseProvider),
    applyReferralCodeUseCase: ref.watch(applyReferralCodeUseCaseProvider),
    getReferralTrackingUseCase: ref.watch(getReferralTrackingUseCaseProvider),
  );
});

final billingInvoiceProvider =
    StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier(
    getInvoicesUseCase: ref.watch(getInvoicesUseCaseProvider),
    getInvoiceUseCase: ref.watch(getInvoiceUseCaseProvider),
    generateInvoiceUseCase: ref.watch(generateInvoiceUseCaseProvider),
    getReceiptsUseCase: ref.watch(getReceiptsUseCaseProvider),
    getInvoicePdfUrlUseCase: ref.watch(getInvoicePdfUrlUseCaseProvider),
    getReceiptPdfUrlUseCase: ref.watch(getReceiptPdfUrlUseCaseProvider),
  );
});

final billingLicenseProvider =
    StateNotifierProvider<LicenseNotifier, LicenseState>((ref) {
  return LicenseNotifier(
    getLicensesUseCase: ref.watch(getLicensesUseCaseProvider),
    revokeLicenseUseCase: ref.watch(revokeLicenseUseCaseProvider),
  );
});

final billingRevenueProvider =
    StateNotifierProvider<RevenueNotifier, RevenueState>((ref) {
  return RevenueNotifier(
    getRevenueDataUseCase: ref.watch(getRevenueDataUseCaseProvider),
    getBillingDashboardSummaryUseCase: ref.watch(getBillingDashboardSummaryUseCaseProvider),
  );
});

final billingSchoolBillingProvider =
    StateNotifierProvider<SchoolBillingNotifier, SchoolBillingState>((ref) {
  return SchoolBillingNotifier(
    getSchoolBillingProfileUseCase: ref.watch(getSchoolBillingProfileUseCaseProvider),
    updateSchoolBillingProfileUseCase: ref.watch(updateSchoolBillingProfileUseCaseProvider),
  );
});

final billingNotificationProvider =
    StateNotifierProvider<BillingNotificationNotifier, BillingNotificationState>((ref) {
  return BillingNotificationNotifier(
    getBillingNotificationsUseCase: ref.watch(getBillingNotificationsUseCaseProvider),
    markNotificationReadUseCase: ref.watch(markNotificationReadUseCaseProvider),
    updateNotificationPreferencesUseCase: ref.watch(updateNotificationPreferencesUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// SUPER ADMIN FEATURE
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Data Sources ──────────────────────────────────────────────────────────

final superAdminRemoteDataSourceProvider = Provider<SuperAdminRemoteDataSource>((ref) {
  return SuperAdminRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

// ─── Repository ────────────────────────────────────────────────────────────

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepositoryImpl(
    remoteDataSource: ref.watch(superAdminRemoteDataSourceProvider),
  );
});

// ─── Use Cases — Dashboard ──────────────────────────────────────────────────

final getDashboardMetricsUseCaseProvider = Provider<GetDashboardMetricsUseCase>((ref) {
  return GetDashboardMetricsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — AI Management ─────────────────────────────────────────────

final getAIProvidersUseCaseProvider = Provider<GetAIProvidersUseCase>((ref) {
  return GetAIProvidersUseCase(ref.watch(superAdminRepositoryProvider));
});

final createAIProviderUseCaseProvider = Provider<CreateAIProviderUseCase>((ref) {
  return CreateAIProviderUseCase(ref.watch(superAdminRepositoryProvider));
});

final updateAIProviderUseCaseProvider = Provider<UpdateAIProviderUseCase>((ref) {
  return UpdateAIProviderUseCase(ref.watch(superAdminRepositoryProvider));
});

final setDefaultProviderUseCaseProvider = Provider<SetDefaultProviderUseCase>((ref) {
  return SetDefaultProviderUseCase(ref.watch(superAdminRepositoryProvider));
});

final toggleProviderUseCaseProvider = Provider<ToggleProviderUseCase>((ref) {
  return ToggleProviderUseCase(ref.watch(superAdminRepositoryProvider));
});

final getAIRequestLogsUseCaseProvider = Provider<GetAIRequestLogsUseCase>((ref) {
  return GetAIRequestLogsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Intelligence ──────────────────────────────────────────────

final getIntelligenceAlertsUseCaseProvider = Provider<GetIntelligenceAlertsUseCase>((ref) {
  return GetIntelligenceAlertsUseCase(ref.watch(superAdminRepositoryProvider));
});

final acknowledgeAlertUseCaseProvider = Provider<AcknowledgeAlertUseCase>((ref) {
  return AcknowledgeAlertUseCase(ref.watch(superAdminRepositoryProvider));
});

final resolveAlertUseCaseProvider = Provider<ResolveAlertUseCase>((ref) {
  return ResolveAlertUseCase(ref.watch(superAdminRepositoryProvider));
});

final generateIntelligenceInsightsUseCaseProvider = Provider<GenerateIntelligenceInsightsUseCase>((ref) {
  return GenerateIntelligenceInsightsUseCase(ref.watch(superAdminRepositoryProvider));
});

final getChurnPredictionsUseCaseProvider = Provider<GetChurnPredictionsUseCase>((ref) {
  return GetChurnPredictionsUseCase(ref.watch(superAdminRepositoryProvider));
});

final getRevenueForecastUseCaseProvider = Provider<GetRevenueForecastUseCase>((ref) {
  return GetRevenueForecastUseCase(ref.watch(superAdminRepositoryProvider));
});

final getCostOptimizationsUseCaseProvider = Provider<GetCostOptimizationsUseCase>((ref) {
  return GetCostOptimizationsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Infrastructure ────────────────────────────────────────────

final getInfrastructureServicesUseCaseProvider = Provider<GetInfrastructureServicesUseCase>((ref) {
  return GetInfrastructureServicesUseCase(ref.watch(superAdminRepositoryProvider));
});

final runHealthCheckUseCaseProvider = Provider<RunHealthCheckUseCase>((ref) {
  return RunHealthCheckUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Maintenance Windows ───────────────────────────────────────

final getMaintenanceWindowsUseCaseProvider = Provider<GetMaintenanceWindowsUseCase>((ref) {
  return GetMaintenanceWindowsUseCase(ref.watch(superAdminRepositoryProvider));
});

final createMaintenanceWindowUseCaseProvider = Provider<CreateMaintenanceWindowUseCase>((ref) {
  return CreateMaintenanceWindowUseCase(ref.watch(superAdminRepositoryProvider));
});

final cancelMaintenanceWindowUseCaseProvider = Provider<CancelMaintenanceWindowUseCase>((ref) {
  return CancelMaintenanceWindowUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Revenue & Billing ─────────────────────────────────────────

final getRevenueAnalyticsUseCaseProvider = Provider<GetRevenueAnalyticsUseCase>((ref) {
  return GetRevenueAnalyticsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Platform Settings ─────────────────────────────────────────

final getPlatformSettingsUseCaseProvider = Provider<GetPlatformSettingsUseCase>((ref) {
  return GetPlatformSettingsUseCase(ref.watch(superAdminRepositoryProvider));
});

final updatePlatformSettingUseCaseProvider = Provider<UpdatePlatformSettingUseCase>((ref) {
  return UpdatePlatformSettingUseCase(ref.watch(superAdminRepositoryProvider));
});

final bulkUpdateSettingsUseCaseProvider = Provider<BulkUpdateSettingsUseCase>((ref) {
  return BulkUpdateSettingsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Feature Flags ──────────────────────────────────────────────

final getFeatureFlagsUseCaseProvider = Provider<GetFeatureFlagsUseCase>((ref) {
  return GetFeatureFlagsUseCase(ref.watch(superAdminRepositoryProvider));
});

final createFeatureFlagUseCaseProvider = Provider<CreateFeatureFlagUseCase>((ref) {
  return CreateFeatureFlagUseCase(ref.watch(superAdminRepositoryProvider));
});

final updateFeatureFlagUseCaseProvider = Provider<UpdateFeatureFlagUseCase>((ref) {
  return UpdateFeatureFlagUseCase(ref.watch(superAdminRepositoryProvider));
});

final toggleFeatureFlagUseCaseProvider = Provider<ToggleFeatureFlagUseCase>((ref) {
  return ToggleFeatureFlagUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Marketplace Management ─────────────────────────────────────

final getMarketplaceContentUseCaseProvider = Provider<GetMarketplaceContentUseCase>((ref) {
  return GetMarketplaceContentUseCase(ref.watch(superAdminRepositoryProvider));
});

final approveContentUseCaseProvider = Provider<ApproveContentUseCase>((ref) {
  return ApproveContentUseCase(ref.watch(superAdminRepositoryProvider));
});

final rejectContentUseCaseProvider = Provider<RejectContentUseCase>((ref) {
  return RejectContentUseCase(ref.watch(superAdminRepositoryProvider));
});

final featureContentUseCaseProvider = Provider<FeatureContentUseCase>((ref) {
  return FeatureContentUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — School Management ───────────────────────────────────────

final getSchoolsUseCaseProvider = Provider<GetSchoolsUseCase>((ref) {
  return GetSchoolsUseCase(ref.watch(superAdminRepositoryProvider));
});

final createSchoolUseCaseProvider = Provider<CreateSchoolUseCase>((ref) {
  return CreateSchoolUseCase(ref.watch(superAdminRepositoryProvider));
});

final suspendSchoolUseCaseProvider = Provider<SuspendSchoolUseCase>((ref) {
  return SuspendSchoolUseCase(ref.watch(superAdminRepositoryProvider));
});

final reactivateSchoolUseCaseProvider = Provider<ReactivateSchoolUseCase>((ref) {
  return ReactivateSchoolUseCase(ref.watch(superAdminRepositoryProvider));
});

final verifySchoolUseCaseProvider = Provider<VerifySchoolUseCase>((ref) {
  return VerifySchoolUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — User Management ─────────────────────────────────────────

final getUsersUseCaseProvider = Provider<GetUsersUseCase>((ref) {
  return GetUsersUseCase(ref.watch(superAdminRepositoryProvider));
});

final suspendUserUseCaseProvider = Provider<SuspendUserUseCase>((ref) {
  return SuspendUserUseCase(ref.watch(superAdminRepositoryProvider));
});

final activateUserUseCaseProvider = Provider<ActivateUserUseCase>((ref) {
  return ActivateUserUseCase(ref.watch(superAdminRepositoryProvider));
});

final resetUserPasswordUseCaseProvider = Provider<ResetUserPasswordUseCase>((ref) {
  return ResetUserPasswordUseCase(ref.watch(superAdminRepositoryProvider));
});

final changeUserRoleUseCaseProvider = Provider<ChangeUserRoleUseCase>((ref) {
  return ChangeUserRoleUseCase(ref.watch(superAdminRepositoryProvider));
});

final startImpersonationUseCaseProvider = Provider<StartImpersonationUseCase>((ref) {
  return StartImpersonationUseCase(ref.watch(superAdminRepositoryProvider));
});

final endImpersonationUseCaseProvider = Provider<EndImpersonationUseCase>((ref) {
  return EndImpersonationUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Support ─────────────────────────────────────────────────

final getSupportTicketsUseCaseProvider = Provider<GetSupportTicketsUseCase>((ref) {
  return GetSupportTicketsUseCase(ref.watch(superAdminRepositoryProvider));
});

final assignTicketUseCaseProvider = Provider<AssignTicketUseCase>((ref) {
  return AssignTicketUseCase(ref.watch(superAdminRepositoryProvider));
});

final escalateTicketUseCaseProvider = Provider<EscalateTicketUseCase>((ref) {
  return EscalateTicketUseCase(ref.watch(superAdminRepositoryProvider));
});

final resolveTicketUseCaseProvider = Provider<ResolveTicketUseCase>((ref) {
  return ResolveTicketUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Security ────────────────────────────────────────────────

final getLoginMonitoringUseCaseProvider = Provider<GetLoginMonitoringUseCase>((ref) {
  return GetLoginMonitoringUseCase(ref.watch(superAdminRepositoryProvider));
});

final detectSuspiciousActivityUseCaseProvider = Provider<DetectSuspiciousActivityUseCase>((ref) {
  return DetectSuspiciousActivityUseCase(ref.watch(superAdminRepositoryProvider));
});

final lockUserAccountUseCaseProvider = Provider<LockUserAccountUseCase>((ref) {
  return LockUserAccountUseCase(ref.watch(superAdminRepositoryProvider));
});

final unlockUserAccountUseCaseProvider = Provider<UnlockUserAccountUseCase>((ref) {
  return UnlockUserAccountUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Audit Logs ──────────────────────────────────────────────

final getAuditLogsUseCaseProvider = Provider<GetAuditLogsUseCase>((ref) {
  return GetAuditLogsUseCase(ref.watch(superAdminRepositoryProvider));
});

final createAuditLogUseCaseProvider = Provider<CreateAuditLogUseCase>((ref) {
  return CreateAuditLogUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Notifications ───────────────────────────────────────────

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(superAdminRepositoryProvider));
});

final markNotificationReadUseCaseProvider = Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(superAdminRepositoryProvider));
});

final getUnreadNotificationCountUseCaseProvider = Provider<GetUnreadNotificationCountUseCase>((ref) {
  return GetUnreadNotificationCountUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Use Cases — Platform Analytics ──────────────────────────────────────

final getSchoolGrowthUseCaseProvider = Provider<GetSchoolGrowthUseCase>((ref) {
  return GetSchoolGrowthUseCase(ref.watch(superAdminRepositoryProvider));
});

final getUserGrowthUseCaseProvider = Provider<GetUserGrowthUseCase>((ref) {
  return GetUserGrowthUseCase(ref.watch(superAdminRepositoryProvider));
});

final getFeatureUsageUseCaseProvider = Provider<GetFeatureUsageUseCase>((ref) {
  return GetFeatureUsageUseCase(ref.watch(superAdminRepositoryProvider));
});

final getRetentionMetricsUseCaseProvider = Provider<GetRetentionMetricsUseCase>((ref) {
  return GetRetentionMetricsUseCase(ref.watch(superAdminRepositoryProvider));
});

// ─── Presentation Providers ──────────────────────────────────────────────

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    getDashboardMetricsUseCase: ref.watch(getDashboardMetricsUseCaseProvider),
  );
});

final platformSettingsProvider = StateNotifierProvider<PlatformSettingsNotifier, PlatformSettingsState>((ref) {
  return PlatformSettingsNotifier(
    getSettingsUseCase: ref.watch(getPlatformSettingsUseCaseProvider),
    updateSettingUseCase: ref.watch(updatePlatformSettingUseCaseProvider),
    bulkUpdateUseCase: ref.watch(bulkUpdateSettingsUseCaseProvider),
  );
});

final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, FeatureFlagsState>((ref) {
  return FeatureFlagsNotifier(
    getFlagsUseCase: ref.watch(getFeatureFlagsUseCaseProvider),
    createFlagUseCase: ref.watch(createFeatureFlagUseCaseProvider),
    updateFlagUseCase: ref.watch(updateFeatureFlagUseCaseProvider),
    toggleFlagUseCase: ref.watch(toggleFeatureFlagUseCaseProvider),
  );
});

final schoolManagementProvider = StateNotifierProvider<SchoolManagementNotifier, SchoolManagementState>((ref) {
  return SchoolManagementNotifier(
    getSchoolsUseCase: ref.watch(getSchoolsUseCaseProvider),
    createSchoolUseCase: ref.watch(createSchoolUseCaseProvider),
    suspendSchoolUseCase: ref.watch(suspendSchoolUseCaseProvider),
    reactivateSchoolUseCase: ref.watch(reactivateSchoolUseCaseProvider),
    verifySchoolUseCase: ref.watch(verifySchoolUseCaseProvider),
  );
});

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  return UserManagementNotifier(
    getUsersUseCase: ref.watch(getUsersUseCaseProvider),
    suspendUserUseCase: ref.watch(suspendUserUseCaseProvider),
    activateUserUseCase: ref.watch(activateUserUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetUserPasswordUseCaseProvider),
    changeRoleUseCase: ref.watch(changeUserRoleUseCaseProvider),
    startImpersonationUseCase: ref.watch(startImpersonationUseCaseProvider),
    endImpersonationUseCase: ref.watch(endImpersonationUseCaseProvider),
  );
});

final aiManagementProvider = StateNotifierProvider<AIManagementNotifier, AIManagementState>((ref) {
  return AIManagementNotifier(
    getProvidersUseCase: ref.watch(getAIProvidersUseCaseProvider),
    createProviderUseCase: ref.watch(createAIProviderUseCaseProvider),
    updateProviderUseCase: ref.watch(updateAIProviderUseCaseProvider),
    setDefaultUseCase: ref.watch(setDefaultProviderUseCaseProvider),
    toggleProviderUseCase: ref.watch(toggleProviderUseCaseProvider),
    getRequestLogsUseCase: ref.watch(getAIRequestLogsUseCaseProvider),
  );
});

final supportCenterProvider = StateNotifierProvider<SupportCenterNotifier, SupportCenterState>((ref) {
  return SupportCenterNotifier(
    getTicketsUseCase: ref.watch(getSupportTicketsUseCaseProvider),
    assignTicketUseCase: ref.watch(assignTicketUseCaseProvider),
    escalateTicketUseCase: ref.watch(escalateTicketUseCaseProvider),
    resolveTicketUseCase: ref.watch(resolveTicketUseCaseProvider),
  );
});

final intelligenceProvider = StateNotifierProvider<IntelligenceNotifier, IntelligenceState>((ref) {
  return IntelligenceNotifier(
    getAlertsUseCase: ref.watch(getIntelligenceAlertsUseCaseProvider),
    acknowledgeAlertUseCase: ref.watch(acknowledgeAlertUseCaseProvider),
    resolveAlertUseCase: ref.watch(resolveAlertUseCaseProvider),
    generateInsightsUseCase: ref.watch(generateIntelligenceInsightsUseCaseProvider),
    getChurnPredictionsUseCase: ref.watch(getChurnPredictionsUseCaseProvider),
    getRevenueForecastUseCase: ref.watch(getRevenueForecastUseCaseProvider),
    getCostOptimizationsUseCase: ref.watch(getCostOptimizationsUseCaseProvider),
  );
});

final securityCenterProvider = StateNotifierProvider<SecurityCenterNotifier, SecurityCenterState>((ref) {
  return SecurityCenterNotifier(
    getLoginMonitoringUseCase: ref.watch(getLoginMonitoringUseCaseProvider),
    detectSuspiciousUseCase: ref.watch(detectSuspiciousActivityUseCaseProvider),
    lockAccountUseCase: ref.watch(lockUserAccountUseCaseProvider),
    unlockAccountUseCase: ref.watch(unlockUserAccountUseCaseProvider),
    getAuditLogsUseCase: ref.watch(getAuditLogsUseCaseProvider),
  );
});

final adminNotificationProvider = StateNotifierProvider<AdminNotificationNotifier, AdminNotificationState>((ref) {
  return AdminNotificationNotifier(
    getNotificationsUseCase: ref.watch(getNotificationsUseCaseProvider),
    markReadUseCase: ref.watch(markNotificationReadUseCaseProvider),
    getUnreadCountUseCase: ref.watch(getUnreadNotificationCountUseCaseProvider),
  );
});
