import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../domain/repositories/offline_repository.dart';


/// Parameters for [SaveDraftUseCase].
class SaveDraftParams extends Equatable {
  const SaveDraftParams({required this.draft});

  final DraftWork draft;

  @override
  List<Object?> get props => [draft];
}

/// Use case: save or update a draft.
class SaveDraftUseCase {
  SaveDraftUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<DraftWork>> call(SaveDraftParams params) async {
    if (params.draft.id.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Draft ID cannot be empty'),
      );
    }
    if (params.draft.userId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'User ID cannot be empty'),
      );
    }
    if (params.draft.title.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Draft title cannot be empty'),
      );
    }

    return _repository.saveDraft(params.draft);
  }
}
