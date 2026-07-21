import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetMessageThreadsUseCase].
class GetMessageThreadsParams extends Equatable {
  const GetMessageThreadsParams({
    required this.page,
    required this.perPage,
  });

  final int page;
  final int perPage;

  @override
  List<Object?> get props => [page, perPage];
}

/// Use case for retrieving message threads for the current parent.
///
/// Validates that [GetMessageThreadsParams.page] is greater than or
/// equal to 1 before delegating to the [ParentPortalRepository].
class GetMessageThreadsUseCase {
  GetMessageThreadsUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves message threads for the current parent.
  ///
  /// Returns a [Result] containing a list of [MessageThreadEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<MessageThreadEntity>>> call(
    GetMessageThreadsParams params,
  ) async {
    if (params.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be greater than or equal to 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ));
    }
    return _repository.getMessageThreads(
      page: params.page,
      perPage: params.perPage,
    );
  }
}
