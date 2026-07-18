import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class AddReactionParams extends Equatable {
  const AddReactionParams({
    required this.messageId,
    required this.emoji,
  });

  final String messageId;
  final String emoji;

  @override
  List<Object?> get props => [messageId, emoji];
}

class AddReactionUseCase {
  AddReactionUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(AddReactionParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
        ),
      );
    }

    if (params.emoji.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Emoji cannot be empty',
          fieldErrors: {'emoji': 'Emoji is required'},
        ),
      );
    }

    return _repository.addReaction(
      messageId: params.messageId,
      emoji: params.emoji,
    );
  }
}
