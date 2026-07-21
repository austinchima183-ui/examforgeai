import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../data/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [GetOfflineResourcesUseCase].
class GetOfflineResourcesParams extends Equatable {
  const GetOfflineResourcesParams({
    required this.userId,
    this.resourceType,
  });

  final String userId;
  final String? resourceType;

  @override
  List<Object?> get props => [userId, resourceType];
}

/// Use case: get offline resources for a user.
class GetOfflineResourcesUseCase {
  GetOfflineResourcesUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<List<OfflineResource>>> call(
    GetOfflineResourcesParams params,
  ) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }

    return _repository.getOfflineResources(
      params.userId,
      resourceType: params.resourceType,
    );
  }
}
