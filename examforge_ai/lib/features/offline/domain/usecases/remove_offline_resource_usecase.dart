import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/offline_repository.dart';


/// Parameters for [RemoveOfflineResourceUseCase].
class RemoveOfflineResourceParams extends Equatable {
  const RemoveOfflineResourceParams({required this.resourceId});

  final String resourceId;

  @override
  List<Object?> get props => [resourceId];
}

/// Use case: remove an offline resource from local storage.
class RemoveOfflineResourceUseCase {
  RemoveOfflineResourceUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<bool>> call(RemoveOfflineResourceParams params) async {
    if (params.resourceId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Resource ID cannot be empty'),
      );
    }

    return _repository.removeOfflineResource(params.resourceId);
  }
}
