import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/utils/logger.dart';
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
import '../services/auth_service.dart';
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
