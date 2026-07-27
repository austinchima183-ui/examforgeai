import '../errors/failures.dart';

/// A lightweight [Result] type for functional error handling.
///
/// Instead of throwing exceptions across boundaries, return a `Result<T>`
/// so that callers are forced to handle both success and failure at
/// compile time.
///
/// ```dart
/// Result<User> result = await userRepository.getUser(id);
/// result.fold(
///   onSuccess: (user) => print(user.name),
///   onFailure: (failure) => print(failure.message),
/// );
/// ```
sealed class Result<T> {
  const Result();

  /// `true` when this is a [Success].
  bool get isSuccess;

  /// `true` when this is a [FailureResult].
  bool get isFailure;

  /// Pattern-matching: calls [onSuccess] for [Success] or [onFailure]
  /// for [FailureResult], returning the callback's value.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  });

  /// Returns the data if [isSuccess], or [defaultValue] otherwise.
  T getOrElse(T defaultValue);

  /// Transforms the success value using [mapper]; failure passes through
  /// unchanged.
  Result<R> map<R>(R Function(T data) mapper);
}

/// Represents a successful outcome containing [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      onSuccess(data);

  @override
  T getOrElse(T defaultValue) => data;

  @override
  Result<R> map<R>(R Function(T data) mapper) => Success(mapper(data));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed outcome containing a [Failure].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      onFailure(failure);

  @override
  T getOrElse(T defaultValue) => defaultValue;

  @override
  Result<R> map<R>(R Function(T data) mapper) => FailureResult(failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'FailureResult($failure)';
}
