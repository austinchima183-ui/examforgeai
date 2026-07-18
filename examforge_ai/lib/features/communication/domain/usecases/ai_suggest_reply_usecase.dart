import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiSuggestReplyParams extends Equatable {
  const AiSuggestReplyParams({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;

  @override
  List<Object?> get props => [conversationId, messageId];
}

class AiSuggestReplyUseCase {
  AiSuggestReplyUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiSuggestReplyParams params,
  ) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
        ),
      );
    }

    return _repository.suggestReply(
      conversationId: params.conversationId,
      messageId: params.messageId,
    );
  }
}
