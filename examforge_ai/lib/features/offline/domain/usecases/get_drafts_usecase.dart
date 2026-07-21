import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../data/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [GetDraftsUseCase].
class GetDraftsParams extends Equatable {
  const GetDraftsParams({
    required this.userId,
    this.draftType,
  });

  final String userId;
  final String? draftType;

  @override
  List<Object?> get props => [userId, draftType];
}

/// Use case: get all drafts for a user.
class GetDraftsUseCase {
  GetDraftsUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<List<DraftWork>>> call(GetDraftsParams params) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }

    return _repository.getDrafts(
      params.userId,
      draftType: params.draftType,
    );
  }
}
