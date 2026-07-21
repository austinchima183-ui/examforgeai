import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [MarkNotificationReadUseCase].
class MarkNotificationReadParams extends Equatable {
  const MarkNotificationReadParams({required this.notificationId});
  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

/// Use case for marking a parent notification as read.
///
/// Validates that the [MarkNotificationReadParams.notificationId] is
/// not empty before delegating to the [ParentPortalRepository].
class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Marks the specified notification as read.
  ///
  /// Returns a [Result] containing `void` on success, or a
  /// [FailureResult] if validation fails or the repository
  /// encounters an error.
  Future<Result<void>> call(MarkNotificationReadParams params) async {
    if (params.notificationId.trim().isEmpty) {
      return const FailureResult(Failure.validation(
        message: 'Notification ID is required',
        fieldErrors: {'notificationId': 'Notification ID cannot be empty'},
      ));
    }
    return _repository.markNotificationRead(params.notificationId);
  }
}
