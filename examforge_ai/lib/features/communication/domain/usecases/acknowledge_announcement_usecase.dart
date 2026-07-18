import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class AcknowledgeAnnouncementParams extends Equatable {
  const AcknowledgeAnnouncementParams({required this.announcementId});

  final String announcementId;

  @override
  List<Object?> get props => [announcementId];
}

class AcknowledgeAnnouncementUseCase {
  AcknowledgeAnnouncementUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(AcknowledgeAnnouncementParams params) async {
    if (params.announcementId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Announcement ID cannot be empty',
          fieldErrors: {'announcementId': 'Required'},
        ),
      );
    }

    return _repository.acknowledgeAnnouncement(params.announcementId);
  }
}
