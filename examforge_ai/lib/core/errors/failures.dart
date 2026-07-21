/// Failure hierarchy for ExamForge AI.
///
/// A sealed union of failure types that are immutable, equatable, and
/// exhaustively matchable via `when` / `maybeWhen`.
///
/// This design provides the same API as a Freezed-generated union
/// without requiring build_runner.

sealed class Failure {
  const Failure();

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
    Map<String, String> fieldErrors = const {},
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
