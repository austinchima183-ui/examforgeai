import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetParentMessagesUseCase].
class GetParentMessagesParams extends Equatable {
  const GetParentMessagesParams({
    this.threadId,
    this.studentId,
    required this.page,
    required this.perPage,
  });

  final String? threadId;
  final String? studentId;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [threadId, studentId, page, perPage];
}

/// Use case for retrieving parent messages.
///
/// Validates that [GetParentMessagesParams.page] is greater than or
/// equal to 1 before delegating to the [ParentPortalRepository].
class GetParentMessagesUseCase {
  GetParentMessagesUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves messages for the current parent.
  ///
  /// Returns a [Result] containing a list of [ParentMessageEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<ParentMessageEntity>>> call(
    GetParentMessagesParams params,
  ) async {
    if (params.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be greater than or equal to 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ));
    }
    return _repository.getParentMessages(
      threadId: params.threadId,
      studentId: params.studentId,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
