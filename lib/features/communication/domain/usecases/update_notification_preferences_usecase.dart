import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class UpdateNotificationPreferencesParams extends Equatable {
  const UpdateNotificationPreferencesParams({required this.preferences});

  final Map<String, dynamic> preferences;

  @override
  List<Object?> get props => [preferences];
}

class UpdateNotificationPreferencesUseCase {
  UpdateNotificationPreferencesUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<NotificationPreferencesEntity>> call(
    UpdateNotificationPreferencesParams params,
  ) async {
    if (params.preferences.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Preferences cannot be empty',
          fieldErrors: {'preferences': 'At least one preference is required'},
        ),
      );
    }

    return _repository.updateNotificationPreferences(params.preferences);
  }
}
