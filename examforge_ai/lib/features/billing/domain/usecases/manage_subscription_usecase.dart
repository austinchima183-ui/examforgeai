import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/result.dart';
import '../../entities/billing_entities.dart';
import '../../repositories/billing_repository.dart';

// ─── Create Subscription ─────────────────────────────────────────────────────

class CreateSubscriptionParams {
  const CreateSubscriptionParams({
    required this.subscriberId,
    required this.subscriberType,
    required this.planId,
    required this.billingCycle,
    this.couponCode,
    this.seats = 1,
    this.schoolId,
  });

  final String subscriberId;
  final SubscriberType subscriberType;
  final String planId;
  final BillingCycle billingCycle;
  final String? couponCode;
  final int seats;
  final String? schoolId;
}

class CreateSubscriptionUseCase {
  CreateSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    CreateSubscriptionParams params,
  ) async {
    if (params.subscriberId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscriber ID cannot be empty'),
      );
    }
    if (params.planId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Plan ID cannot be empty'),
      );
    }
    if (params.seats < 1) {
      return FailureResult(
        Failure.validation(message: 'Seats must be at least 1'),
      );
    }

    return _repository.createSubscription(
      subscriberId: params.subscriberId,
      subscriberType: params.subscriberType,
      planId: params.planId,
      billingCycle: params.billingCycle,
      couponCode: params.couponCode,
      seats: params.seats,
      schoolId: params.schoolId,
    );
  }
}

// ─── Upgrade Subscription ────────────────────────────────────────────────────

class UpgradeSubscriptionParams {
  const UpgradeSubscriptionParams({
    required this.subscriptionId,
    required this.newPlanId,
    this.billingCycle,
  });

  final String subscriptionId;
  final String newPlanId;
  final BillingCycle? billingCycle;
}

class UpgradeSubscriptionUseCase {
  UpgradeSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    UpgradeSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }
    if (params.newPlanId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'New plan ID cannot be empty'),
      );
    }

    return _repository.upgradeSubscription(
      subscriptionId: params.subscriptionId,
      newPlanId: params.newPlanId,
      billingCycle: params.billingCycle,
    );
  }
}

// ─── Downgrade Subscription ──────────────────────────────────────────────────

class DowngradeSubscriptionParams {
  const DowngradeSubscriptionParams({
    required this.subscriptionId,
    required this.newPlanId,
  });

  final String subscriptionId;
  final String newPlanId;
}

class DowngradeSubscriptionUseCase {
  DowngradeSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    DowngradeSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }
    if (params.newPlanId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'New plan ID cannot be empty'),
      );
    }

    return _repository.downgradeSubscription(
      subscriptionId: params.subscriptionId,
      newPlanId: params.newPlanId,
    );
  }
}

// ─── Cancel Subscription ─────────────────────────────────────────────────────

class CancelSubscriptionParams {
  const CancelSubscriptionParams({
    required this.subscriptionId,
    this.reason,
    this.immediate = false,
  });

  final String subscriptionId;
  final String? reason;
  final bool immediate;
}

class CancelSubscriptionUseCase {
  CancelSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    CancelSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }

    return _repository.cancelSubscription(
      subscriptionId: params.subscriptionId,
      reason: params.reason,
      immediate: params.immediate,
    );
  }
}

// ─── Renew Subscription ──────────────────────────────────────────────────────

class RenewSubscriptionParams {
  const RenewSubscriptionParams({required this.subscriptionId});
  final String subscriptionId;
}

class RenewSubscriptionUseCase {
  RenewSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    RenewSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }

    return _repository.renewSubscription(
      subscriptionId: params.subscriptionId,
    );
  }
}

// ─── Pause Subscription ──────────────────────────────────────────────────────

class PauseSubscriptionParams {
  const PauseSubscriptionParams({required this.subscriptionId});
  final String subscriptionId;
}

class PauseSubscriptionUseCase {
  PauseSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    PauseSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }

    return _repository.pauseSubscription(
      subscriptionId: params.subscriptionId,
    );
  }
}

// ─── Resume Subscription ─────────────────────────────────────────────────────

class ResumeSubscriptionParams {
  const ResumeSubscriptionParams({required this.subscriptionId});
  final String subscriptionId;
}

class ResumeSubscriptionUseCase {
  ResumeSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity>> call(
    ResumeSubscriptionParams params,
  ) async {
    if (params.subscriptionId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscription ID cannot be empty'),
      );
    }

    return _repository.resumeSubscription(
      subscriptionId: params.subscriptionId,
    );
  }
}

// ─── Get Current Subscription ────────────────────────────────────────────────

class GetCurrentSubscriptionParams {
  const GetCurrentSubscriptionParams({
    required this.subscriberId,
    required this.subscriberType,
  });

  final String subscriberId;
  final SubscriberType subscriberType;
}

class GetCurrentSubscriptionUseCase {
  GetCurrentSubscriptionUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<SubscriptionEntity?>> call(
    GetCurrentSubscriptionParams params,
  ) async {
    if (params.subscriberId.isEmpty) {
      return FailureResult(
        Failure.validation(message: 'Subscriber ID cannot be empty'),
      );
    }

    return _repository.getCurrentSubscription(
      subscriberId: params.subscriberId,
      subscriberType: params.subscriberType,
    );
  }
}

// ─── Get Subscriptions ───────────────────────────────────────────────────────

class GetSubscriptionsParams {
  const GetSubscriptionsParams({
    this.schoolId,
    this.subscriberType,
    this.status,
    required this.page,
    required this.perPage,
  });

  final String? schoolId;
  final SubscriberType? subscriberType;
  final SubscriptionStatus? status;
  final int page;
  final int perPage;
}

class GetSubscriptionsUseCase {
  GetSubscriptionsUseCase(this._repository);
  final BillingRepository _repository;

  Future<Result<PaginatedResult<SubscriptionEntity>>> call(
    GetSubscriptionsParams params,
  ) async {
    if (params.page < 1) {
      return FailureResult(
        Failure.validation(message: 'Page must be at least 1'),
      );
    }
    if (params.perPage < 1) {
      return FailureResult(
        Failure.validation(message: 'Per page must be at least 1'),
      );
    }

    return _repository.getSubscriptions(
      schoolId: params.schoolId,
      subscriberType: params.subscriberType,
      status: params.status,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
