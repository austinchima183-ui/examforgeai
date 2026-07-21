import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [DownloadResourceUseCase].
class DownloadResourceParams extends Equatable {
  const DownloadResourceParams({
    required this.userId,
    required this.resourceType,
    required this.resourceId,
  });

  final String userId;
  final String resourceType;
  final String resourceId;

  @override
  List<Object?> get props => [userId, resourceType, resourceId];
}

/// Use case: download a resource for offline access.
class DownloadResourceUseCase {
  DownloadResourceUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<bool>> call(DownloadResourceParams params) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }
    if (params.resourceType.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Resource type cannot be empty'),
      );
    }
    if (params.resourceId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Resource ID cannot be empty'),
      );
    }

    return _repository.downloadResourceForOffline(
      params.userId,
      params.resourceType,
      params.resourceId,
    );
  }
}
