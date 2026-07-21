/// Failure hierarchy for ExamForge AI.
///
/// A sealed union of failure types that are immutable, equatable, and
/// exhaustively matchable via `when` / `maybeWhen`.
///
/// This design provides the same API as a Freezed-generated union
/// without requiring build_runner.

sealed class Failure {
  const Failure();

  /// A human-readable description of what went wrong.
  String get message;

  /// Exhaustive pattern matching over all failure variants.
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  });

  /// Partial pattern matching with a default [orElse] branch.
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  });

  // ─── Factory Constructors ────────────────────────────────────────────

  /// Creates a [ServerFailure].
  const factory Failure.server({
    required String message,
    required int statusCode,
    dynamic data,
  }) = ServerFailure;

  /// Creates a [CacheFailure].
  const factory Failure.cache({
    required String message,
  }) = CacheFailure;

  /// Creates an [AuthFailure].
  const factory Failure.auth({
    required String message,
    required String code,
  }) = AuthFailure;

  /// Creates a [NetworkFailure].
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;

  /// Creates a [ValidationFailure].
  const factory Failure.validation({
    required String message,
    required Map<String, String> fieldErrors,
  }) = ValidationFailure;

  /// Creates a [NotFoundFailure].
  const factory Failure.notFound({
    required String message,
  }) = NotFoundFailure;

  /// Creates an [UnauthorizedFailure].
  const factory Failure.unauthorized({
    required String message,
  }) = UnauthorizedFailure;

  /// Creates a [ForbiddenFailure].
  const factory Failure.forbidden({
    required String message,
  }) = ForbiddenFailure;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Failure Subclasses
// ═══════════════════════════════════════════════════════════════════════════════

final class ServerFailure extends Failure {
  const ServerFailure({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  final String message;
  final int statusCode;
  final dynamic data;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => server(message, statusCode, data);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => server != null ? server(message, statusCode, data) : orElse();
}

final class CacheFailure extends Failure {
  const CacheFailure({required this.message});

  @override
  final String message;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => cache(message);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => cache != null ? cache(message) : orElse();
}

final class AuthFailure extends Failure {
  const AuthFailure({required this.message, required this.code});

  @override
  final String message;
  final String code;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => auth(message, code);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => auth != null ? auth(message, code) : orElse();
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required this.message});

  @override
  final String message;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => network(message);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => network != null ? network(message) : orElse();
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required this.message,
    required this.fieldErrors,
  });

  @override
  final String message;
  final Map<String, String> fieldErrors;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => validation(message, fieldErrors);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => validation != null ? validation(message, fieldErrors) : orElse();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.message});

  @override
  final String message;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => notFound(message);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => notFound != null ? notFound(message) : orElse();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required this.message});

  @override
  final String message;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => unauthorized(message);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => unauthorized != null ? unauthorized(message) : orElse();
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required this.message});

  @override
  final String message;

  @override
  T when<T>({
    required T Function(String message, int statusCode, dynamic data) server,
    required T Function(String message) cache,
    required T Function(String message, String code) auth,
    required T Function(String message) network,
    required T Function(String message, Map<String, String> fieldErrors)
        validation,
    required T Function(String message) notFound,
    required T Function(String message) unauthorized,
    required T Function(String message) forbidden,
  }) => forbidden(message);

  @override
  T maybeWhen<T>({
    T Function(String message, int statusCode, dynamic data)? server,
    T Function(String message)? cache,
    T Function(String message, String code)? auth,
    T Function(String message)? network,
    T Function(String message, Map<String, String> fieldErrors)? validation,
    T Function(String message)? notFound,
    T Function(String message)? unauthorized,
    T Function(String message)? forbidden,
    required T Function() orElse,
  }) => forbidden != null ? forbidden(message) : orElse();
}
