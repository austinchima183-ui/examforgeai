import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/communication_repository.dart';

class MarkNotificationReadParams extends Equatable {
  const MarkNotificationReadParams({required this.notificationId});

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<void>> call(MarkNotificationReadParams params) async {
    if (params.notificationId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Notification ID cannot be empty',
          fieldErrors: {'notificationId': 'Required'},
        ),
      );
    }

    return _repository.markNotificationRead(params.notificationId);
  }
}
