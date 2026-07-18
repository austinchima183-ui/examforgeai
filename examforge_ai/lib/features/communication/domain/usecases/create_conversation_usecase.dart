import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class CreateConversationParams extends Equatable {
  const CreateConversationParams({
    required this.name,
    required this.type,
    required this.participantIds,
    this.classId,
    this.departmentId,
    this.subjectId,
  });

  final String name;
  final ConversationType type;
  final List<String> participantIds;
  final String? classId;
  final String? departmentId;
  final String? subjectId;

  @override
  List<Object?> get props => [
        name,
        type,
        participantIds,
        classId,
        departmentId,
        subjectId,
      ];
}

class CreateConversationUseCase {
  CreateConversationUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<ConversationEntity>> call(
    CreateConversationParams params,
  ) async {
    if (params.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Conversation name cannot be empty',
          fieldErrors: {'name': 'Name is required'},
        ),
      );
    }

    if (params.participantIds.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'At least one participant is required',
          fieldErrors: {'participantIds': 'Participants cannot be empty'},
        ),
      );
    }

    return _repository.createConversation(
      name: params.name,
      type: params.type,
      participantIds: params.participantIds,
      classId: params.classId,
      departmentId: params.departmentId,
      subjectId: params.subjectId,
    );
  }
}
