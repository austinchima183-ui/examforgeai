import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetMessagesParams extends Equatable {
  const GetMessagesParams({
    required this.conversationId,
    this.page = 1,
    this.perPage = 50,
    this.before,
  });

  final String conversationId;
  final int page;
  final int perPage;
  final DateTime? before;

  @override
  List<Object?> get props => [conversationId, page, perPage, before];
}

class GetMessagesUseCase {
  GetMessagesUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<MessageEntity>>> call(GetMessagesParams params) async {
    if (params.conversationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation ID cannot be empty',
          fieldErrors: {'conversationId': 'Required'},
        ),
      );
    }

    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page must be >= 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'PerPage must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid perPage'},
        ),
      );
    }

    return _repository.getMessages(
      conversationId: params.conversationId,
      page: params.page,
      perPage: params.perPage,
      before: params.before,
    );
  }
}
