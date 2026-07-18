import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_school_billing_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL BILLING STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the school billing feature.
///
/// Tracks the school billing profile and loading/error/success states
/// for school billing operations.
class SchoolBillingState {
  const SchoolBillingState({
    this.isLoading = false,
    this.billingProfile,
    this.error,
    this.successMessage,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The school billing profile, or `null`.
  final SchoolBillingProfileEntity? billingProfile;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Whether a billing profile is loaded.
  bool get hasBillingProfile => billingProfile != null;

  /// Creates a copy of this state with the given fields replaced.
  SchoolBillingState copyWith({
    bool? isLoading,
    SchoolBillingProfileEntity? billingProfile,
    String? error,
    String? successMessage,
  }) {
    return SchoolBillingState(
      isLoading: isLoading ?? this.isLoading,
      billingProfile: billingProfile ?? this.billingProfile,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  SchoolBillingState clearError() => copyWith(error: null);

  /// Clears the current success message.
  SchoolBillingState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL BILLING NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the school billing feature's
/// state.
///
/// Supports loading and updating the school billing profile.
class SchoolBillingNotifier extends StateNotifier<SchoolBillingState> {
  SchoolBillingNotifier({
    required GetSchoolBillingProfileUseCase getSchoolBillingProfileUseCase,
    required UpdateSchoolBillingProfileUseCase
        updateSchoolBillingProfileUseCase,
  })  : _getSchoolBillingProfileUseCase = getSchoolBillingProfileUseCase,
        _updateSchoolBillingProfileUseCase =
            updateSchoolBillingProfileUseCase,
        super(const SchoolBillingState());

  final GetSchoolBillingProfileUseCase _getSchoolBillingProfileUseCase;
  final UpdateSchoolBillingProfileUseCase
      _updateSchoolBillingProfileUseCase;

  // ─── Load Billing Profile ──────────────────────────────────────────

  /// Loads the school billing profile.
  Future<void> loadBillingProfile({required String schoolId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSchoolBillingProfileUseCase(
      GetSchoolBillingProfileParams(schoolId: schoolId),
    );

    result.fold(
      onSuccess: (profile) {
        state = state.copyWith(
          isLoading: false,
          billingProfile: profile,
          error: null,
        );
        AppLogger.info('Loaded billing profile for school: $schoolId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load billing profile: $failure',
        );
      },
    );
  }

  // ─── Update Billing Profile ────────────────────────────────────────

  /// Updates the school billing profile.
  Future<void> updateBillingProfile({
    required SchoolBillingProfileEntity profile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _updateSchoolBillingProfileUseCase(
      UpdateSchoolBillingProfileParams(profile: profile),
    );

    result.fold(
      onSuccess: (updatedProfile) {
        state = state.copyWith(
          isLoading: false,
          billingProfile: updatedProfile,
          successMessage: 'Billing profile updated successfully',
          error: null,
        );
        AppLogger.info(
          'Updated billing profile for school: ${updatedProfile.schoolId}',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to update billing profile: $failure',
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
// SCHOOL BILLING PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the school billing feature.
///
/// The factory accepts all required use cases via named parameters.
final schoolBillingProvider =
    StateNotifierProvider<SchoolBillingNotifier, SchoolBillingState>(
  (ref) => SchoolBillingNotifier(
    getSchoolBillingProfileUseCase:
        ref.watch(getSchoolBillingProfileUseCaseProvider),
    updateSchoolBillingProfileUseCase:
        ref.watch(updateSchoolBillingProfileUseCaseProvider),
  ),
);
