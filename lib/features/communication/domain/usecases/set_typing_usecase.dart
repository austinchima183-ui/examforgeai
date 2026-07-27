import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class SetTypingParams extends Equatable {
  const SetTypingParams({
    required this.conversationId,
    required this.isTyping,
  });

  final String conversationId;
  final bool isTyping;

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class SetTypingUseCase {
  SetTypingUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(SetTypingParams params) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    return _repository.setTyping(
      conversationId: params.conversationId,
      isTyping: params.isTyping,
    );
  }
}
