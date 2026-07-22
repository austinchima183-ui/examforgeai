import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/manage_licenses_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// LICENSE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the license feature.
///
/// Tracks the list of licenses and loading/error/success states
/// for license operations.
class LicenseState {
  const LicenseState({
    this.isLoading = false,
    this.licenses = const [],
    this.error,
    this.successMessage,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The list of licenses.
  final List<LicenseEntity> licenses;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// The number of active licenses.
  int get activeLicenseCount =>
      licenses.where((l) => l.isActive).length;

  /// The number of expired licenses.
  int get expiredLicenseCount =>
      licenses.where((l) => l.isExpired).length;

  /// Creates a copy of this state with the given fields replaced.
  LicenseState copyWith({
    bool? isLoading,
    List<LicenseEntity>? licenses,
    String? error,
    String? successMessage,
  }) {
    return LicenseState(
      isLoading: isLoading ?? this.isLoading,
      licenses: licenses ?? this.licenses,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  LicenseState clearError() => copyWith(error: null);

  /// Clears the current success message.
  LicenseState clearSuccess() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// LICENSE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the license feature's state.
///
/// Supports loading licenses and revoking a license.
class LicenseNotifier extends StateNotifier<LicenseState> {
  LicenseNotifier({
    required GetLicensesUseCase getLicensesUseCase,
    required RevokeLicenseUseCase revokeLicenseUseCase,
  })  : _getLicensesUseCase = getLicensesUseCase,
        _revokeLicenseUseCase = revokeLicenseUseCase,
        super(const LicenseState());

  final GetLicensesUseCase _getLicensesUseCase;
  final RevokeLicenseUseCase _revokeLicenseUseCase;

  // ─── Load Licenses ─────────────────────────────────────────────────

  /// Loads the list of licenses.
  Future<void> loadLicenses({
    String? schoolId,
    String? userId,
    LicenseType? type,
    bool activeOnly = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getLicensesUseCase(
      GetLicensesParams(
        schoolId: schoolId,
        userId: userId,
        type: type,
        activeOnly: activeOnly,
      ),
    );

    result.fold(
      onSuccess: (licenses) {
        state = state.copyWith(
          isLoading: false,
          licenses: licenses,
          error: null,
        );
        AppLogger.info('Loaded ${licenses.length} licenses');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load licenses: $failure');
      },
    );
  }

  // ─── Revoke License ────────────────────────────────────────────────

  /// Revokes a license by ID.
  Future<void> revokeLicense({
    required String licenseId,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _revokeLicenseUseCase(
      RevokeLicenseParams(
        licenseId: licenseId,
        reason: reason,
      ),
    );

    result.fold(
      onSuccess: (revokedLicense) {
        final updatedList = state.licenses
            .map((l) => l.id == revokedLicense.id ? revokedLicense : l)
            .toList();
        state = state.copyWith(
          isLoading: false,
          licenses: updatedList,
          successMessage: 'License revoked successfully',
          error: null,
        );
        AppLogger.info('License revoked: $licenseId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to revoke license: $failure');
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
// LICENSE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the license feature.
///
/// The factory accepts all required use cases via named parameters.
final licenseProvider =
    StateNotifierProvider<LicenseNotifier, LicenseState>(
  (ref) => LicenseNotifier(
    getLicensesUseCase: ref.watch(getLicensesUseCaseProvider),
    revokeLicenseUseCase: ref.watch(revokeLicenseUseCaseProvider),
  ),
);
