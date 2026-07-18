import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiAdjustToneParams extends Equatable {
  const AiAdjustToneParams({
    required this.text,
    required this.targetTone,
  });

  final String text;
  final String targetTone;

  @override
  List<Object?> get props => [text, targetTone];
}

class AiAdjustToneUseCase {
  AiAdjustToneUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiAdjustToneParams params,
  ) async {
    if (params.text.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Text cannot be empty',
          fieldErrors: {'text': 'Text is required'},
        ),
      );
    }

    if (params.targetTone.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Target tone cannot be empty',
          fieldErrors: {'targetTone': 'Target tone is required'},
        ),
      );
    }

    return _repository.adjustTone(
      text: params.text,
      targetTone: params.targetTone,
    );
  }
}
