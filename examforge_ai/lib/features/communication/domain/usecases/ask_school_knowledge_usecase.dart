import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AskSchoolKnowledgeParams extends Equatable {
  const AskSchoolKnowledgeParams({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class AskSchoolKnowledgeUseCase {
  AskSchoolKnowledgeUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiSchoolKnowledgeResponseEntity>> call(
    AskSchoolKnowledgeParams params,
  ) async {
    if (params.query.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Query cannot be empty',
          fieldErrors: {'query': 'Query is required'},
        ),
      );
    }

    return _repository.askSchoolKnowledge(query: params.query);
  }
}
