import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class DeleteMessageParams extends Equatable {
  const DeleteMessageParams({required this.messageId});

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

class DeleteMessageUseCase {
  DeleteMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(DeleteMessageParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
        ),
      );
    }

    return _repository.deleteMessage(params.messageId);
  }
}
