import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiSummarizeConversationParams extends Equatable {
  const AiSummarizeConversationParams({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class AiSummarizeConversationUseCase {
  AiSummarizeConversationUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiSummarizeConversationParams params,
  ) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    return _repository.summarizeConversation(
      conversationId: params.conversationId,
    );
  }
}
