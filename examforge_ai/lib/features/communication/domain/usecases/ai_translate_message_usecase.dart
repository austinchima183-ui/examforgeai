import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiTranslateMessageParams extends Equatable {
  const AiTranslateMessageParams({
    required this.text,
    required this.targetLanguage,
  });

  final String text;
  final String targetLanguage;

  @override
  List<Object?> get props => [text, targetLanguage];
}

class AiTranslateMessageUseCase {
  AiTranslateMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiTranslateMessageParams params,
  ) async {
    if (params.text.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Text cannot be empty',
          fieldErrors: {'text': 'Text is required'},
        ),
      );
    }

    if (params.targetLanguage.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Target language cannot be empty',
          fieldErrors: {'targetLanguage': 'Target language is required'},
        ),
      );
    }

    return _repository.translateMessage(
      text: params.text,
      targetLanguage: params.targetLanguage,
    );
  }
}
