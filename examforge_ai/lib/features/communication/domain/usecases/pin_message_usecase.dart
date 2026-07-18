import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class PinMessageParams extends Equatable {
  const PinMessageParams({
    required this.messageId,
    required this.isPinned,
  });

  final String messageId;
  final bool isPinned;

  @override
  List<Object?> get props => [messageId, isPinned];
}

class PinMessageUseCase {
  PinMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(PinMessageParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
        ),
      );
    }

    if (params.isPinned) {
      return _repository.pinMessage(params.messageId);
    } else {
      return _repository.unpinMessage(params.messageId);
    }
  }
}
