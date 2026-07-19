import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/offline_entities.dart';
import '../../repositories/offline_repository.dart';

/// Parameters for [StartDownloadUseCase].
class StartDownloadParams extends Equatable {
  const StartDownloadParams({
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.fileUrl,
    required this.fileName,
  });

  final String userId;
  final String resourceType;
  final String resourceId;
  final String fileUrl;
  final String fileName;

  @override
  List<Object?> get props => [userId, resourceType, resourceId, fileUrl, fileName];
}

/// Use case: start a file download for offline access.
class StartDownloadUseCase {
  StartDownloadUseCase(this._repository);
  final OfflineRepository _repository;

  Future<Result<FileDownload>> call(StartDownloadParams params) async {
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
    if (params.fileUrl.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'File URL cannot be empty'),
      );
    }
    if (params.fileName.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'File name cannot be empty'),
      );
    }

    return _repository.startDownload(
      params.userId,
      params.resourceType,
      params.resourceId,
      params.fileUrl,
      params.fileName,
    );
  }
}
