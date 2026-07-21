import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [AskParentAssistantUseCase].
class AskParentAssistantParams extends Equatable {
  const AskParentAssistantParams({
    required this.question,
    this.studentId,
    this.context,
  });

  final String question;
  final String? studentId;
  final Map<String, dynamic>? context;

  @override
  List<Object?> get props => [question, studentId, context];
}

/// Use case for asking the AI parent assistant a question.
///
/// Validates that the [AskParentAssistantParams.question] is not
/// empty before delegating to the [ParentPortalRepository].
class AskParentAssistantUseCase {
  AskParentAssistantUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Sends a question to the AI parent assistant.
  ///
  /// Returns a [Result] containing the [ParentAssistantResponseEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ParentAssistantResponseEntity>> call(
    AskParentAssistantParams params,
  ) async {
    if (params.question.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Question is required',
        fieldErrors: {'question': 'Question cannot be empty'},
      ));
    }
    return _repository.askParentAssistant(
      question: params.question,
      studentId: params.studentId,
      context: params.context,
    );
  }
}
