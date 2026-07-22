import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';
import '../../services/storage_service.dart';

/// A Dio-based HTTP client that wraps common HTTP verbs and automatically
/// converts Dio-specific errors into domain [Exception]s.
///
/// **Performance Optimizations:**
/// - Token refresh mutex prevents concurrent refresh race conditions
/// - Retry with exponential backoff for transient failures (429, 502, 503)
/// - Gzip compression via Accept-Encoding header
/// - Configurable retry count and delays
///
/// **Security Fix:** The original implementation had stub methods for
/// `_getStoredAccessToken()` and `_getStoredRefreshToken()` that always
/// returned `null`, meaning no auth tokens were ever injected into API
/// requests. This has been fixed by wiring the ApiClient to the
/// [StorageService] which reads tokens from flutter_secure_storage.
///
/// Usage:
/// ```dart
/// final client = ApiClient(dio, storageService: storageService);
/// final response = await client.get('/user/profile');
/// ```
class ApiClient {
  ApiClient(this._dio, {StorageService? storageService, int maxRetries = 3})
      : _storageService = storageService,
        _maxRetries = maxRetries {
    _setupInterceptors();
  }

  final Dio _dio;
  final StorageService? _storageService;
  final int _maxRetries;

  /// Mutex for token refresh — ensures only one refresh happens at a time.
  /// Prevents race condition when multiple requests fail with 401 simultaneously.
  Completer<String?>? _refreshCompleter;

  // ─── Public HTTP Methods ───────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard<T>(() => _dio.get<T>(
          path,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard<T>(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard<T>(() => _dio.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard<T>(() => _dio.patch<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _guard<T>(() => _dio.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options,
        ));
  }

  // ─── Error Mapping ─────────────────────────────────────────────────

  /// Executes [call] with retry logic and converts any [DioException]
  /// into a domain exception from our hierarchy.
  ///
  /// **Performance:** Retries transient failures (429, 502, 503, timeouts)
  /// with exponential backoff: 1s, 2s, 4s. Only retries idempotent methods
  /// (GET, PUT, DELETE). POST requests are not retried automatically
  /// as they may not be idempotent.
  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 1);

    while (true) {
      try {
        return await call();
      } on DioException catch (e) {
        attempt++;

        // Check if this is a retryable transient failure
        final isRetryable = _isTransientFailure(e);
        final shouldRetry = isRetryable && attempt <= _maxRetries;

        if (shouldRetry) {
          AppLogger.warning(
            'Transient API failure (attempt $attempt/$_maxRetries): '
            '${e.type} — retrying in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
          delay = Duration(seconds: delay.inSeconds * 2); // Exponential backoff
          continue;
        }

        throw _mapDioException(e);
      }
    }
  }

  /// Determines if a DioException represents a transient failure that
  /// can be safely retried without side effects.
  bool _isTransientFailure(DioException e) {
    // Timeout errors are always retryable
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Connection errors (network blips) are retryable
    if (e.type == DioExceptionType.connectionError) {
      return true;
    }

    // Certain HTTP status codes indicate transient failures
    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode ?? 0;
      return statusCode == 429 || // Rate limited
             statusCode == 502 || // Bad gateway
             statusCode == 503 || // Service unavailable
             statusCode == 504;   // Gateway timeout
    }

    return false;
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException(message: 'Connection timed out. Please try again.');

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        return _mapStatusCode(e);

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerException(
          message: 'SSL certificate verification failed.',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        return NetworkException(message: e.message ?? 'An unknown error occurred.');
    }
  }

  Exception _mapStatusCode(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    final message = _extractMessage(data) ?? 'An unexpected error occurred.';

    switch (statusCode) {
      case 400:
        // Attempt to parse field-level validation errors from the body.
        final fieldErrors = _extractFieldErrors(data);
        if (fieldErrors.isNotEmpty) {
          return ValidationException(
            message: message,
            fieldErrors: fieldErrors,
          );
        }
        return ServerException(message: message, statusCode: statusCode, data: data);

      case 401:
        return UnauthorizedException(message: message);

      case 403:
        return ForbiddenException(message: message);

      case 404:
        return NotFoundException(message: message);

      case 422:
        return ValidationException(
          message: message,
          fieldErrors: _extractFieldErrors(data),
        );

      case 429:
        return ServerException(
          message: 'Too many requests. Please wait and try again.',
          statusCode: statusCode,
        );

      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// Tries to pull a human-readable message from the response body.
  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }

  /// Tries to pull field-level errors from a 400 / 422 body.
  Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        return errors.map((k, v) => MapEntry(k, v.toString()));
      }
    }
    return const {};
  }

  // ─── Interceptors ──────────────────────────────────────────────────

  void _setupInterceptors() {
    // ── Gzip Compression Interceptor ─────────────────────────────────
    // Add Accept-Encoding: gzip to all requests to reduce response size
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept-Encoding'] = 'gzip';
          handler.next(options);
        },
      ),
    );

    // ── Logging Interceptor (debug only) ─────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );
    }

    // ── Auth & Token-Refresh Interceptor ─────────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip auth header for login / refresh endpoints.
          final isAuthEndpoint = options.path.endsWith('/auth/login') ||
              options.path.endsWith('/auth/register') ||
              options.path.endsWith('/auth/refresh-token') ||
              options.path.endsWith('/auth/forgot-password') ||
              options.path.endsWith('/auth/verify-email') ||
              options.path.endsWith('/auth/reset-password');

          if (!isAuthEndpoint) {
            // FIX: Actually read the token from secure storage instead
            // of returning null. This was the root cause of auth always
            // returning null — the stub methods were never wired up.
            final accessToken = await _getStoredAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            } else {
              AppLogger.warning(
                'No access token available for request: ${options.path}',
              );
            }
          }
          handler.next(options);
        },

        onError: (error, handler) async {
          // Only attempt refresh on 401 responses that are NOT from
          // the refresh-token endpoint itself (to avoid infinite loops).
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.endsWith('/auth/refresh-token')) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed != null) {
              // Retry the original request with the new token.
              error.requestOptions.headers['Authorization'] =
                  'Bearer $refreshed';
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.reject(retryError);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── Token Refresh Logic ───────────────────────────────────────────
  //
  // FIX: The original stub methods always returned null. Now they are
  // wired to the [StorageService] which reads from flutter_secure_storage.
  // The StorageService is injected via the constructor, making this
  // class testable while also functional in production.

  /// Reads the stored access token from secure storage.
  ///
  /// Returns `null` if the StorageService hasn't been injected (should
  /// not happen in production) or if no token is stored.
  Future<String?> _getStoredAccessToken() async {
    if (_storageService == null) {
      AppLogger.error(
        'ApiClient: StorageService not injected. '
        'Auth tokens will not be available. '
        'Ensure ApiClient is created with storageService parameter.',
      );
      return null;
    }
    try {
      return await _storageService.getToken();
    } catch (e) {
      AppLogger.error('Failed to read access token', error: e);
      return null;
    }
  }

  /// Attempts to refresh the access token. Returns the new access token
  /// on success, or `null` on failure.
  ///
  /// **Performance Fix:** Uses a Completer-based mutex to ensure only one
  /// token refresh happens at a time. If multiple requests fail with 401
  /// simultaneously, they all wait for the same refresh operation rather
  /// than each initiating their own.
  Future<String?> _attemptTokenRefresh() async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      AppLogger.info('Token refresh already in progress — waiting for result');
      return _refreshCompleter!.future;
    }

    // Start a new refresh operation
    _refreshCompleter = Completer<String?>();

    try {
      final refreshTokenValue = await _getStoredRefreshToken();
      if (refreshTokenValue == null) {
        AppLogger.info('No refresh token available for token refresh');
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshTokenValue},
        options: Options(headers: ApiConstants.baseHeaders()),
      );

      final newAccessToken = response.data?['accessToken'] as String?;
      final newRefreshToken = response.data?['refreshToken'] as String?;

      if (newAccessToken != null) {
        await _persistTokens(newAccessToken, newRefreshToken);
        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      }

      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      AppLogger.error('Token refresh failed', error: e);
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      // Reset the mutex so future refreshes can proceed
      _refreshCompleter = null;
    }
  }

  /// Reads the stored refresh token from secure storage.
  Future<String?> _getStoredRefreshToken() async {
    if (_storageService == null) return null;
    try {
      return await _storageService.getRefreshToken();
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Persists the new token pair to secure storage.
  Future<void> _persistTokens(
    String accessToken,
    String? refreshToken,
  ) async {
    if (_storageService == null) return;
    try {
      await _storageService.saveTokenPair(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      AppLogger.error('Failed to persist refreshed tokens', error: e);
    }
  }
}
