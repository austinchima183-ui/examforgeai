/// Custom exception hierarchy for ExamForge AI.
///
/// Each exception implements [Exception] and provides a meaningful
/// [toString] override for logging and debugging.

/// Thrown when the server returns a non-2xx response.
class ServerException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;

  const ServerException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() =>
      'ServerException(statusCode: $statusCode, message: $message, data: $data)';
}

/// Thrown when a local cache read / write fails.
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache operation failed'});

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Thrown on authentication / authorization failures.
class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}

/// Thrown when the device has no network connectivity.
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No network connection available'});

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Thrown when one or more fields fail validation.
class ValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors = const {},
  });

  @override
  String toString() =>
      'ValidationException(message: $message, fieldErrors: $fieldErrors)';
}

/// Thrown when the requested resource is not found (404).
class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'Resource not found'});

  @override
  String toString() => 'NotFoundException(message: $message)';
}

/// Thrown when the user is not authenticated (401).
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'Unauthorized access'});

  @override
  String toString() => 'UnauthorizedException(message: $message)';
}

/// Thrown when the user lacks permission for the operation (403).
class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException({this.message = 'Access forbidden'});

  @override
  String toString() => 'ForbiddenException(message: $message)';
}
