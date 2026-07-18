import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.conversationId,
    required this.body,
    this.type = MessageType.text,
    this.replyToId,
    this.attachments,
  });

  final String conversationId;
  final String body;
  final MessageType type;
  final String? replyToId;
  final List<Map<String, dynamic>>? attachments;

  @override
  List<Object?> get props => [conversationId, body, type, replyToId, attachments];
}

class SendMessageUseCase {
  SendMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<MessageEntity>> call(SendMessageParams params) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    if (params.body.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message body cannot be empty',
          fieldErrors: {'body': 'Message body is required'},
        ),
      );
    }

    return _repository.sendMessage(
      conversationId: params.conversationId,
      body: params.body,
      type: params.type,
      replyToId: params.replyToId,
      attachments: params.attachments,
    );
  }
}
