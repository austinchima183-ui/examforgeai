import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class MarkAsReadParams extends Equatable {
  const MarkAsReadParams({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;

  @override
  List<Object?> get props => [conversationId, messageId];
}

class MarkAsReadUseCase {
  MarkAsReadUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(MarkAsReadParams params) async {
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

    return _repository.markAsRead(
      conversationId: params.conversationId,
      messageId: params.messageId,
    );
  }
}
