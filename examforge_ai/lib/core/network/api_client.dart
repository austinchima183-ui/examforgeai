import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// A Dio-based HTTP client that wraps common HTTP verbs and automatically
/// converts Dio-specific errors into domain [Exception]s.
///
/// Usage:
/// ```dart
/// final client = ApiClient(dio);
/// final response = await client.get('/user/profile');
/// ```
class ApiClient {
  ApiClient(this._dio) {
    _setupInterceptors();
  }

  final Dio _dio;

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
            final accessToken = await _getStoredAccessToken();
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
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
  // In a production app, the token is stored securely (flutter_secure_storage).
  // This class only coordinates the refresh; the actual storage read / write
  // is delegated so that the ApiClient stays testable.

  /// Override this getter or inject a storage adapter in production.
  Future<String?> _getStoredAccessToken() async {
    // Will be wired to secure storage in the auth layer.
    return null;
  }

  /// Attempts to refresh the access token. Returns the new access token
  /// on success, or `null` on failure.
  Future<String?> _attemptTokenRefresh() async {
    try {
      final refreshTokenValue = await _getStoredRefreshToken();
      if (refreshTokenValue == null) return null;

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

  /// Reads the stored refresh token.
  Future<String?> _getStoredRefreshToken() async {
    // Will be wired to secure storage in the auth layer.
    return null;
  }

  /// Persists the new token pair.
  Future<void> _persistTokens(
    String accessToken,
    String? refreshToken,
  ) async {
    // Will be wired to secure storage in the auth layer.
  }
}
