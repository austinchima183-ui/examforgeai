import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class AiRewriteMessageParams extends Equatable {
  const AiRewriteMessageParams({
    required this.text,
    this.tone,
  });

  final String text;
  final String? tone;

  @override
  List<Object?> get props => [text, tone];
}

class AiRewriteMessageUseCase {
  AiRewriteMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AiCommunicationAssistantEntity>> call(
    AiRewriteMessageParams params,
  ) async {
    if (params.text.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Text cannot be empty',
          fieldErrors: {'text': 'Text is required'},
        ),
      );
    }

    return _repository.rewriteMessage(
      text: params.text,
      tone: params.tone,
    );
  }
}
