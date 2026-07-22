import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_referrals_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// REFERRAL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the referral feature.
///
/// Tracks the referral code, referral tracking data, and
/// loading/error/success states for referral operations.
class ReferralState {
  const ReferralState({
    this.isLoading = false,
    this.referralCode,
    this.referralTracking = const [],
    this.error,
    this.successMessage,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The user's referral code, or `null`.
  final ReferralCodeEntity? referralCode;

  /// The list of referral tracking entries.
  final List<Map<String, dynamic>> referralTracking;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether a referral code is available.
  bool get hasReferralCode => referralCode != null;

  /// The total number of successful referrals.
  int get totalSuccessfulReferrals =>
      referralCode?.successfulReferrals ?? 0;

  /// The total rewards earned from referrals.
  double get totalRewardsEarned =>
      referralCode?.totalRewardsEarned ?? 0;

  /// Creates a copy of this state with the given fields replaced.
  ReferralState copyWith({
    bool? isLoading,
    ReferralCodeEntity? referralCode,
    List<Map<String, dynamic>>? referralTracking,
    String? error,
    String? successMessage,
  }) {
    return ReferralState(
      isLoading: isLoading ?? this.isLoading,
      referralCode: referralCode ?? this.referralCode,
      referralTracking: referralTracking ?? this.referralTracking,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  ReferralState clearError() => copyWith(error: null);

  /// Clears the current success message.
  ReferralState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// REFERRAL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the referral feature's state.
///
/// Supports getting or creating referral codes, applying referral
/// codes, and loading referral tracking data.
class ReferralNotifier extends StateNotifier<ReferralState> {
  ReferralNotifier({
    required GetOrCreateReferralCodeUseCase getOrCreateReferralCodeUseCase,
    required ApplyReferralCodeUseCase applyReferralCodeUseCase,
    required GetReferralTrackingUseCase getReferralTrackingUseCase,
  })  : _getOrCreateReferralCodeUseCase = getOrCreateReferralCodeUseCase,
        _applyReferralCodeUseCase = applyReferralCodeUseCase,
        _getReferralTrackingUseCase = getReferralTrackingUseCase,
        super(const ReferralState());

  final GetOrCreateReferralCodeUseCase _getOrCreateReferralCodeUseCase;
  final ApplyReferralCodeUseCase _applyReferralCodeUseCase;
  final GetReferralTrackingUseCase _getReferralTrackingUseCase;

  // ─── Load Or Create Referral Code ──────────────────────────────────

  /// Gets or creates a referral code for the given referrer.
  Future<void> loadOrCreateReferralCode({
    required String referrerId,
    required BillingModel referrerType,
    String? schoolId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getOrCreateReferralCodeUseCase(
      GetOrCreateReferralCodeParams(
        referrerId: referrerId,
        referrerType: referrerType,
        schoolId: schoolId,
      ),
    );

    result.fold(
      onSuccess: (referralCode) {
        state = state.copyWith(
          isLoading: false,
          referralCode: referralCode,
          error: null,
        );
        AppLogger.info(
          'Loaded referral code: ${referralCode.code}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load referral code: $failure',
        );
      },
    );
  }

  // ─── Apply Referral Code ───────────────────────────────────────────

  /// Applies a referral code for the given referee.
  Future<void> applyReferralCode({
    required String code,
    required String refereeId,
    required BillingModel refereeType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _applyReferralCodeUseCase(
      ApplyReferralCodeParams(
        code: code,
        refereeId: refereeId,
        refereeType: refereeType,
      ),
    );

    result.fold(
      onSuccess: (referral) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Referral code applied successfully',
          error: null,
        );
        AppLogger.info('Referral code applied: $code');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to apply referral code: $failure');
      },
    );
  }

  // ─── Load Referral Tracking ────────────────────────────────────────

  /// Loads referral tracking data for the given referrer.
  Future<void> loadReferralTracking({
    required String referrerId,
    required int page,
    required int perPage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getReferralTrackingUseCase(
      GetReferralTrackingParams(
        referrerId: referrerId,
        page: page,
        perPage: perPage,
      ),
    );

    result.fold(
      onSuccess: (trackingData) {
        state = state.copyWith(
          isLoading: false,
          referralTracking: trackingData,
          error: null,
        );
        AppLogger.info(
          'Loaded ${trackingData.length} referral tracking entries',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load referral tracking: $failure',
        );
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
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
// REFERRAL PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the referral feature.
///
/// The factory accepts all required use cases via named parameters.
final referralProvider =
    StateNotifierProvider<ReferralNotifier, ReferralState>(
  (ref) => ReferralNotifier(
    getOrCreateReferralCodeUseCase:
        ref.watch(getOrCreateReferralCodeUseCaseProvider),
    applyReferralCodeUseCase: ref.watch(applyReferralCodeUseCaseProvider),
    getReferralTrackingUseCase:
        ref.watch(getReferralTrackingUseCaseProvider),
  ),
);
