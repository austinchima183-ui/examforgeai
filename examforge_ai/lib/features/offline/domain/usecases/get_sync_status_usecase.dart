import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../data/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [GetSyncStatusUseCase].
class GetSyncStatusParams extends Equatable {
  const GetSyncStatusParams({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Use case: get the current sync status for a user.
class GetSyncStatusUseCase {
  GetSyncStatusUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<SyncStatusInfo>> call(GetSyncStatusParams params) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }

    return _repository.getSyncStatus(params.userId);
  }
}
