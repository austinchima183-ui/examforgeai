import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/offline_repository.dart';


/// Parameters for [DeleteDraftUseCase].
class DeleteDraftParams extends Equatable {
  const DeleteDraftParams({required this.draftId});

  final String draftId;

  @override
  List<Object?> get props => [draftId];
}

/// Use case: delete a draft by ID.
class DeleteDraftUseCase {
  DeleteDraftUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<bool>> call(DeleteDraftParams params) async {
    if (params.draftId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Draft ID cannot be empty'),
      );
    }

    return _repository.deleteDraft(params.draftId);
  }
}
