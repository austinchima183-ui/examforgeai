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
  ApiClient(this._dio, {StorageService? storageService})
      : _storageService = storageService {
    _setupInterceptors();
  }

  final Dio _dio;
  final StorageService? _storageService;

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

  /// Executes [call] and converts any [DioException] into a domain
  /// exception from our hierarchy.
  Future<Response<T>> _guard<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timed out. Please try again.');

      case DioExceptionType.connectionError:
        return const NetworkException(
          'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        return _mapStatusCode(e);

      case DioExceptionType.cancel:
        return const NetworkException('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerException(
          message: 'SSL certificate verification failed.',
          statusCode: 0,
        );

      case DioExceptionType.unknown:
        return NetworkException(e.message ?? 'An unknown error occurred.');
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
        return UnauthorizedException(message);

      case 403:
        return ForbiddenException(message);

      case 404:
        return NotFoundException(message);

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
  Future<String?> _attemptTokenRefresh() async {
    try {
      final refreshTokenValue = await _getStoredRefreshToken();
      if (refreshTokenValue == null) {
        AppLogger.info('No refresh token available for token refresh');
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
        return newAccessToken;
      }
      return null;
    } catch (e) {
      AppLogger.error('Token refresh failed', error: e);
      return null;
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
