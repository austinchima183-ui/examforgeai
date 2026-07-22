import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/parent_portal_entities.dart';
import '../repositories/parent_portal_repository.dart';

/// Parameters for [GetParentNotificationsUseCase].
class GetParentNotificationsParams extends Equatable {
  const GetParentNotificationsParams({
    this.category,
    this.isRead,
    required this.page,
    required this.perPage,
  });

  final String? category;
  final bool? isRead;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [category, isRead, page, perPage];
}

/// Use case for retrieving parent notifications.
///
/// Validates that [GetParentNotificationsParams.page] is greater than
/// or equal to 1 before delegating to the [ParentPortalRepository].
class GetParentNotificationsUseCase {
  GetParentNotificationsUseCase(this._repository);
  final ParentPortalRepository _repository;

  /// Retrieves notifications for the current parent.
  ///
  /// Returns a [Result] containing a list of [ParentNotificationEntity]
  /// on success, or a [FailureResult] if validation fails or the
  /// repository encounters an error.
  Future<Result<List<ParentNotificationEntity>>> call(
    GetParentNotificationsParams params,
  ) async {
    if (params.page < 1) {
      return const FailureResult(Failure.validation(
        message: 'Page must be greater than or equal to 1',
        fieldErrors: {'page': 'Page must be >= 1'},
      ));
    }
    return _repository.getNotifications(
      category: params.category,
      isRead: params.isRead,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
