import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [SendParentMessageUseCase].
class SendMessageParams extends Equatable {
  const SendMessageParams({
    required this.recipientId,
    required this.subject,
    required this.body,
    this.studentId,
    this.parentMessageId,
  });

  final String recipientId;
  final String subject;
  final String body;
  final String? studentId;
  final String? parentMessageId;

  @override
  List<Object?> get props => [recipientId, subject, body, studentId, parentMessageId];
}

/// Use case for sending a message from a parent.
///
/// Validates that [SendMessageParams.recipientId],
/// [SendMessageParams.subject], and [SendMessageParams.body] are
/// not empty before delegating to the [ParentPortalRepository].
class SendParentMessageUseCase {
  SendParentMessageUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Sends a message from the current parent.
  ///
  /// Returns a [Result] containing the persisted [ParentMessageEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<ParentMessageEntity>> call(SendMessageParams params) async {
    if (params.recipientId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Recipient ID is required',
        fieldErrors: {'recipientId': 'Recipient ID cannot be empty'},
      ),);
    }
    if (params.subject.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Subject is required',
        fieldErrors: {'subject': 'Subject cannot be empty'},
      ),);
    }
    if (params.body.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Message body is required',
        fieldErrors: {'body': 'Message body cannot be empty'},
      ),);
    }
    return _repository.sendMessage({
      'recipientId': params.recipientId,
      'subject': params.subject,
      'body': params.body,
      'studentId': params.studentId,
      'parentMessageId': params.parentMessageId,
    });
  }
}
