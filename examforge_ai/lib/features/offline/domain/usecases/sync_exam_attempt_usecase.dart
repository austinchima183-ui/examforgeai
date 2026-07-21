import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../data/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [SyncExamAttemptUseCase].
class SyncExamAttemptParams extends Equatable {
  const SyncExamAttemptParams({required this.attemptId});

  final String attemptId;

  @override
  List<Object?> get props => [attemptId];
}

/// Use case: sync a single exam attempt to the server.
class SyncExamAttemptUseCase {
  SyncExamAttemptUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<bool>> call(SyncExamAttemptParams params) async {
    if (params.attemptId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Attempt ID cannot be empty'),
      );
    }

    return _repository.syncExamAttempt(params.attemptId);
  }
}
