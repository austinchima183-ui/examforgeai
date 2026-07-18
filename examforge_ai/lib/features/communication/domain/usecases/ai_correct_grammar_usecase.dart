import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiCorrectGrammarParams extends Equatable {
  const AiCorrectGrammarParams({required this.text});

  final String text;

  @override
  List<Object?> get props => [text];
}

class AiCorrectGrammarUseCase {
  AiCorrectGrammarUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiCorrectGrammarParams params,
  ) async {
    if (params.text.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Text cannot be empty',
          fieldErrors: {'text': 'Text is required'},
        ),
      );
    }

    return _repository.correctGrammar(text: params.text);
  }
}
