import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiDraftAnnouncementParams extends Equatable {
  const AiDraftAnnouncementParams({
    required this.topic,
    this.audience,
    this.tone,
  });

  final String topic;
  final String? audience;
  final String? tone;

  @override
  List<Object?> get props => [topic, audience, tone];
}

class AiDraftAnnouncementUseCase {
  AiDraftAnnouncementUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiDraftAnnouncementParams params,
  ) async {
    if (params.topic.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Topic cannot be empty',
          fieldErrors: {'topic': 'Topic is required'},
        ),
      );
    }

    return _repository.draftAnnouncement(
      topic: params.topic,
      audience: params.audience,
      tone: params.tone,
    );
  }
}
