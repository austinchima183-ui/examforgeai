import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/billing_repository.dart';


// ─── Get Billing Notifications ───────────────────────────────────────────────

class GetBillingNotificationsParams {
  const GetBillingNotificationsParams({
    required this.userId,
    required this.unreadOnly,
    required this.page,
    required this.perPage,
  });

  final String userId;
  final bool unreadOnly;
  final int page;
  final int perPage;
}

class GetBillingNotificationsUseCase {
  GetBillingNotificationsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<List<BillingNotificationEntity>>> call(
    GetBillingNotificationsParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'User ID cannot be empty'),
      );
    }
    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Per page must be at least 1'),
      );
    }

    return _repository.getBillingNotifications(
      userId: params.userId,
      unreadOnly: params.unreadOnly,
      page: params.page,
      perPage: params.perPage,
    );
  }
}

// ─── Mark Notification Read ──────────────────────────────────────────────────

class MarkNotificationReadParams {
  const MarkNotificationReadParams({required this.notificationId});
  final String notificationId;
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<void>> call(MarkNotificationReadParams params) async {
    if (params.notificationId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Notification ID cannot be empty'),
      );
    }

    return _repository.markNotificationRead(
      params.notificationId,
    );
  }
}

// ─── Update Notification Preferences ─────────────────────────────────────────

class UpdateNotificationPreferencesParams {
  const UpdateNotificationPreferencesParams({
    required this.userId,
    required this.preferences,
  });

  final String userId;
  final Map<String, bool> preferences;
}

class UpdateNotificationPreferencesUseCase {
  UpdateNotificationPreferencesUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<void>> call(UpdateNotificationPreferencesParams params) async {
    if (params.userId.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'User ID cannot be empty'),
      );
    }
    if (params.preferences.isEmpty) {
      return const FailureResult(
        Failure.validation(fieldErrors: {}, message: 'Preferences cannot be empty'),
      );
    }

    return _repository.updateNotificationPreferences(
      userId: params.userId,
      preferences: params.preferences,
    );
  }
}
