import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [MarkMessageReadUseCase].
class MarkMessageReadParams extends Equatable {
  const MarkMessageReadParams({required this.messageId});
  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Use case for marking a parent message as read.
///
/// Validates that the [MarkMessageReadParams.messageId] is not
/// empty before delegating to the [ParentPortalRepository].
class MarkMessageReadUseCase {
  MarkMessageReadUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Marks the specified message as read.
  ///
  /// Returns a [Result] containing `void` on success, or a
  /// [FailureResult] if validation fails or the repository
  /// encounters an error.
  Future<Result<void>> call(MarkMessageReadParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Message ID is required',
        fieldErrors: {'messageId': 'Message ID cannot be empty'},
      ));
    }
    return _repository.markMessageRead(params.messageId);
  }
}
