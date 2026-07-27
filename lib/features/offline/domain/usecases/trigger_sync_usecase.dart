import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/offline_repository.dart';


/// Parameters for [TriggerSyncUseCase].
class TriggerSyncParams extends Equatable {
  const TriggerSyncParams({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Use case: trigger a manual sync for a user.
class TriggerSyncUseCase {
  TriggerSyncUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<bool>> call(TriggerSyncParams params) async {
    if (params.userId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'User ID cannot be empty'),
      );
    }

    return _repository.triggerSync(params.userId);
  }
}
