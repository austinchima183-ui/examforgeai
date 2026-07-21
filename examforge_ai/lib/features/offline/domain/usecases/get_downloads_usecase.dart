import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/offline_entities.dart';
import '../../data/repositories/offline_repository.dart';
import '../../../../features/offline/domain/repositories/offline_repository.dart';


/// Parameters for [GetDownloadsUseCase].
class GetDownloadsParams extends Equatable {
  const GetDownloadsParams({
    required this.userId,
    this.status,
  });

  final String userId;
  final String? status;

  @override
  List<Object?> get props => [userId, status];
}

/// Use case: get all downloads for a user, optionally filtered by status.
class GetDownloadsUseCase {
  GetDownloadsUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<List<FileDownload>>> call(GetDownloadsParams params) async {
    if (params.userId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'User ID cannot be empty'),
      );
    }

    return _repository.getDownloads(
      params.userId,
      status: params.status,
    );
  }
}
