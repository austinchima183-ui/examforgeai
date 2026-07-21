import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/get_subscription_plans_usecase.dart';
import '../../domain/usecases/manage_subscription_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the subscription feature.
///
/// Tracks the current subscription, available plans, transactions,
/// selected billing preferences, and loading/error states.
class SubscriptionState {
  const SubscriptionState({
    this.isLoading = false,
    this.subscription,
    this.plans = const [],
    this.transactions = const [],
    this.error,
    this.successMessage,
    this.selectedBillingCycle,
    this.selectedBillingModel,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The current active subscription, or `null`.
  final SubscriptionEntity? subscription;

  /// The list of available subscription plans.
  final List<SubscriptionPlanEntity> plans;

  /// The list of recent transactions.
  final List<TransactionEntity> transactions;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The currently selected billing cycle filter.
  final String? selectedBillingCycle;

  /// The currently selected billing model filter.
  final BillingModel? selectedBillingModel;

  /// Whether the user has an active subscription.
  bool get hasActiveSubscription => subscription != null;

  /// Creates a copy of this state with the given fields replaced.
  SubscriptionState copyWith({
    bool? isLoading,
    SubscriptionEntity? subscription,
    List<SubscriptionPlanEntity>? plans,
    List<TransactionEntity>? transactions,
    String? error,
    String? successMessage,
    String? selectedBillingCycle,
    BillingModel? selectedBillingModel,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      transactions: transactions ?? this.transactions,
      error: error,
      successMessage: successMessage,
      selectedBillingCycle: selectedBillingCycle ?? this.selectedBillingCycle,
      selectedBillingModel:
          selectedBillingModel ?? this.selectedBillingModel,
    );
  }

  /// Clears the current error message.
  SubscriptionState clearError() => copyWith(error: null);

  /// Clears the current success message.
  SubscriptionState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the subscription feature's state.
///
/// Supports loading plans, managing the current subscription, and
/// performing subscription lifecycle operations (upgrade, downgrade,
/// cancel, renew, pause, resume).
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier({
    required GetSubscriptionPlansUseCase getSubscriptionPlansUseCase,
    required GetCurrentSubscriptionUseCase getCurrentSubscriptionUseCase,
    required CreateSubscriptionUseCase createSubscriptionUseCase,
    required UpgradeSubscriptionUseCase upgradeSubscriptionUseCase,
    required DowngradeSubscriptionUseCase downgradeSubscriptionUseCase,
    required CancelSubscriptionUseCase cancelSubscriptionUseCase,
    required RenewSubscriptionUseCase renewSubscriptionUseCase,
    required PauseSubscriptionUseCase pauseSubscriptionUseCase,
    required ResumeSubscriptionUseCase resumeSubscriptionUseCase,
  })  : _getSubscriptionPlansUseCase = getSubscriptionPlansUseCase,
        _getCurrentSubscriptionUseCase = getCurrentSubscriptionUseCase,
        _createSubscriptionUseCase = createSubscriptionUseCase,
        _upgradeSubscriptionUseCase = upgradeSubscriptionUseCase,
        _downgradeSubscriptionUseCase = downgradeSubscriptionUseCase,
        _cancelSubscriptionUseCase = cancelSubscriptionUseCase,
        _renewSubscriptionUseCase = renewSubscriptionUseCase,
        _pauseSubscriptionUseCase = pauseSubscriptionUseCase,
        _resumeSubscriptionUseCase = resumeSubscriptionUseCase,
        super(const SubscriptionState());

  final GetSubscriptionPlansUseCase _getSubscriptionPlansUseCase;
  final GetCurrentSubscriptionUseCase _getCurrentSubscriptionUseCase;
  final CreateSubscriptionUseCase _createSubscriptionUseCase;
  final UpgradeSubscriptionUseCase _upgradeSubscriptionUseCase;
  final DowngradeSubscriptionUseCase _downgradeSubscriptionUseCase;
  final CancelSubscriptionUseCase _cancelSubscriptionUseCase;
  final RenewSubscriptionUseCase _renewSubscriptionUseCase;
  final PauseSubscriptionUseCase _pauseSubscriptionUseCase;
  final ResumeSubscriptionUseCase _resumeSubscriptionUseCase;

  // ─── Load Plans ────────────────────────────────────────────────────

  /// Loads available subscription plans.
  Future<void> loadPlans({
    BillingModel? billingModel,
    bool activeOnly = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSubscriptionPlansUseCase(
      GetSubscriptionPlansParams(
        billingModel: billingModel,
        activeOnly: activeOnly,
      ),
    );

    result.fold(
      onSuccess: (plans) {
        state = state.copyWith(
          isLoading: false,
          plans: plans,
          error: null,
        );
        AppLogger.info('Loaded ${plans.length} subscription plans');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load subscription plans: $failure');
      },
    );
  }

  // ─── Load Current Subscription ─────────────────────────────────────

  /// Loads the current subscription for the given subscriber.
  Future<void> loadCurrentSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCurrentSubscriptionUseCase(
      GetCurrentSubscriptionParams(
        subscriberId: subscriberId,
        subscriberType: subscriberType,
      ),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          error: null,
        );
        AppLogger.info('Loaded current subscription');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load current subscription: $failure',
        );
      },
    );
  }

  // ─── Create Subscription ───────────────────────────────────────────

  /// Creates a new subscription.
  Future<void> createSubscription({
    required String subscriberId,
    required BillingModel subscriberType,
    required String planId,
    required String billingCycle,
    String? couponCode,
    int seats = 1,
    String? schoolId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createSubscriptionUseCase(
      CreateSubscriptionParams(
        subscriberId: subscriberId,
        subscriberType: subscriberType,
        planId: planId,
        billingCycle: billingCycle,
        couponCode: couponCode,
        seats: seats,
        schoolId: schoolId,
      ),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription created successfully',
          error: null,
        );
        AppLogger.info('Subscription created: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create subscription: $failure');
      },
    );
  }

  // ─── Upgrade Subscription ──────────────────────────────────────────

  /// Upgrades the subscription to a new plan.
  Future<void> upgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
    String? billingCycle,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _upgradeSubscriptionUseCase(
      UpgradeSubscriptionParams(
        subscriptionId: subscriptionId,
        newPlanId: newPlanId,
        billingCycle: billingCycle,
      ),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription upgraded successfully',
          error: null,
        );
        AppLogger.info('Subscription upgraded: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upgrade subscription: $failure');
      },
    );
  }

  // ─── Downgrade Subscription ────────────────────────────────────────

  /// Downgrades the subscription to a lower plan.
  Future<void> downgradeSubscription({
    required String subscriptionId,
    required String newPlanId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _downgradeSubscriptionUseCase(
      DowngradeSubscriptionParams(
        subscriptionId: subscriptionId,
        newPlanId: newPlanId,
      ),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription downgraded successfully',
          error: null,
        );
        AppLogger.info('Subscription downgraded: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to downgrade subscription: $failure');
      },
    );
  }

  // ─── Cancel Subscription ───────────────────────────────────────────

  /// Cancels the subscription.
  Future<void> cancelSubscription({
    required String subscriptionId,
    String? reason,
    bool immediate = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _cancelSubscriptionUseCase(
      CancelSubscriptionParams(
        subscriptionId: subscriptionId,
        reason: reason,
        immediate: immediate,
      ),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription cancelled successfully',
          error: null,
        );
        AppLogger.info('Subscription cancelled: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to cancel subscription: $failure');
      },
    );
  }

  // ─── Renew Subscription ────────────────────────────────────────────

  /// Renews the subscription.
  Future<void> renewSubscription({
    required String subscriptionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _renewSubscriptionUseCase(
      RenewSubscriptionParams(subscriptionId: subscriptionId),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription renewed successfully',
          error: null,
        );
        AppLogger.info('Subscription renewed: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to renew subscription: $failure');
      },
    );
  }

  // ─── Pause Subscription ────────────────────────────────────────────

  /// Pauses the subscription.
  Future<void> pauseSubscription({
    required String subscriptionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _pauseSubscriptionUseCase(
      PauseSubscriptionParams(subscriptionId: subscriptionId),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription paused successfully',
          error: null,
        );
        AppLogger.info('Subscription paused: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to pause subscription: $failure');
      },
    );
  }

  // ─── Resume Subscription ───────────────────────────────────────────

  /// Resumes a paused subscription.
  Future<void> resumeSubscription({
    required String subscriptionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _resumeSubscriptionUseCase(
      ResumeSubscriptionParams(subscriptionId: subscriptionId),
    );

    result.fold(
      onSuccess: (subscription) {
        state = state.copyWith(
          isLoading: false,
          subscription: subscription,
          successMessage: 'Subscription resumed successfully',
          error: null,
        );
        AppLogger.info('Subscription resumed: ${subscription.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to resume subscription: $failure');
      },
    );
  }

  // ─── Set Billing Cycle ─────────────────────────────────────────────

  /// Sets the selected billing cycle filter.
  void setBillingCycle(String billingCycle) {
    state = state.copyWith(selectedBillingCycle: billingCycle);
  }

  // ─── Set Billing Model ─────────────────────────────────────────────

  /// Sets the selected billing model filter.
  void setBillingModel(BillingModel billingModel) {
    state = state.copyWith(selectedBillingModel: billingModel);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success ─────────────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccess() {
    state = state.clearSuccess();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the subscription feature.
///
/// The factory accepts all required use cases via named parameters.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
  (ref) => SubscriptionNotifier(
    getSubscriptionPlansUseCase: ref.watch(getSubscriptionPlansUseCaseProvider),
    getCurrentSubscriptionUseCase:
        ref.watch(getCurrentSubscriptionUseCaseProvider),
    createSubscriptionUseCase: ref.watch(createSubscriptionUseCaseProvider),
    upgradeSubscriptionUseCase: ref.watch(upgradeSubscriptionUseCaseProvider),
    downgradeSubscriptionUseCase:
        ref.watch(downgradeSubscriptionUseCaseProvider),
    cancelSubscriptionUseCase: ref.watch(cancelSubscriptionUseCaseProvider),
    renewSubscriptionUseCase: ref.watch(renewSubscriptionUseCaseProvider),
    pauseSubscriptionUseCase: ref.watch(pauseSubscriptionUseCaseProvider),
    resumeSubscriptionUseCase: ref.watch(resumeSubscriptionUseCaseProvider),
  ),
);
