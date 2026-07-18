import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class ReportMessageParams extends Equatable {
  const ReportMessageParams({
    required this.messageId,
    required this.reason,
  });

  final String messageId;
  final String reason;

  @override
  List<Object?> get props => [messageId, reason];
}

class ReportMessageUseCase {
  ReportMessageUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(ReportMessageParams params) async {
    if (params.messageId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Message ID cannot be empty',
          fieldErrors: {'messageId': 'Required'},
        ),
      );
    }

    if (params.reason.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Report reason cannot be empty',
          fieldErrors: {'reason': 'Reason is required'},
        ),
      );
    }

    return _repository.reportMessage(
      messageId: params.messageId,
      reason: params.reason,
    );
  }
}
