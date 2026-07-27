import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class MuteConversationParams extends Equatable {
  const MuteConversationParams({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

class MuteConversationUseCase {
  MuteConversationUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(MuteConversationParams params) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    return _repository.muteConversation(params.conversationId);
  }
}
