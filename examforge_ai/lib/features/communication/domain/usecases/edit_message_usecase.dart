import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class EditMessageParams extends Equatable {
  const EditMessageParams({
    required this.messageId,
    required this.body,
  });

  final String messageId;
  final String body;

  @override
  List<Object?> get props => [messageId, body];
}

class EditMessageUseCase {
  EditMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<MessageEntity>> call(EditMessageParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
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

    return _repository.editMessage(
      messageId: params.messageId,
      body: params.body,
    );
  }
}
