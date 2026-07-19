import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/logger.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../../domain/usecases/get_commission_rates_usecase.dart';
import '../../domain/usecases/get_commission_records_usecase.dart';
import '../../domain/usecases/upsert_commission_rate_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMISSION STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the commission management feature (Super Admin).
///
/// Tracks commission rates, commission records, and loading/error states.
class CommissionState {
  const CommissionState({
    this.isLoading = false,
    this.error,
    this.commissionRates = const [],
    this.commissionRecords = const [],
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The list of commission rate configurations.
  final List<CommissionRateEntity> commissionRates;

  /// The list of commission payment records.
  final List<CommissionRecordEntity> commissionRecords;

  // ─── Computed Getters ────────────────────────────────────────────────

  /// Whether there are commission rates configured.
  bool get hasCommissionRates => commissionRates.isNotEmpty;

  /// Whether there are commission records.
  bool get hasCommissionRecords => commissionRecords.isNotEmpty;

  /// The total commission amount across all records.
  double get totalCommissionAmount =>
      commissionRecords.fold(0, (sum, r) => sum + r.commissionAmount);

  /// The total seller revenue across all records.
  double get totalSellerRevenue =>
      commissionRecords.fold(0, (sum, r) => sum + r.sellerRevenue);

  /// Currently effective commission rates.
  List<CommissionRateEntity> get activeRates =>
      commissionRates.where((r) => r.isCurrentlyEffective).toList();

  /// Creates a copy of this state with the given fields replaced.
  CommissionState copyWith({
    bool? isLoading,
    String? error,
    List<CommissionRateEntity>? commissionRates,
    List<CommissionRecordEntity>? commissionRecords,
  }) {
    return CommissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      commissionRates: commissionRates ?? this.commissionRates,
      commissionRecords: commissionRecords ?? this.commissionRecords,
    );
  }

  /// Clears the current error message.
  CommissionState clearError() => copyWith(error: null);

  /// Clears the current success message (no-op, included for consistency).
  CommissionState clearSuccess() => copyWith();
}

// ═══════════════════════════════════════════════════════════════════════
// COMMISSION NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the commission management state.
///
/// Supports loading commission rates, upserting rate configurations,
/// and loading commission records.
class CommissionNotifier extends StateNotifier<CommissionState> {
  CommissionNotifier({
    required GetCommissionRatesUseCase getCommissionRatesUseCase,
    required UpsertCommissionRateUseCase upsertCommissionRateUseCase,
    required GetCommissionRecordsUseCase getCommissionRecordsUseCase,
  })  : _getCommissionRatesUseCase = getCommissionRatesUseCase,
        _upsertCommissionRateUseCase = upsertCommissionRateUseCase,
        _getCommissionRecordsUseCase = getCommissionRecordsUseCase,
        super(const CommissionState());

  final GetCommissionRatesUseCase _getCommissionRatesUseCase;
  final UpsertCommissionRateUseCase _upsertCommissionRateUseCase;
  final GetCommissionRecordsUseCase _getCommissionRecordsUseCase;

  // ─── Load Commission Rates ──────────────────────────────────────────

  /// Loads commission rate configurations.
  Future<void> loadCommissionRates({
    MarketplaceProductType? productType,
    MarketplaceLicenseType? licenseType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCommissionRatesUseCase(
      GetCommissionRatesParams(
        productType: productType,
        licenseType: licenseType,
      ),
    );

    result.fold(
      onSuccess: (rates) {
        state = state.copyWith(isLoading: false, commissionRates: rates);
        AppLogger.info('Loaded ${rates.length} commission rates');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load commission rates: $failure');
      },
    );
  }

  // ─── Upsert Commission Rate ─────────────────────────────────────────

  /// Creates or updates a commission rate configuration.
  Future<void> upsertCommissionRate({
    required CommissionRateEntity rate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _upsertCommissionRateUseCase(
      UpsertCommissionRateParams(rate: rate),
    );

    result.fold(
      onSuccess: (upsertedRate) {
        final existingIndex =
            state.commissionRates.indexWhere((r) => r.id == upsertedRate.id);
        final updatedRates = List<CommissionRateEntity>.from(
          state.commissionRates,
        );
        if (existingIndex >= 0) {
          updatedRates[existingIndex] = upsertedRate;
        } else {
          updatedRates.add(upsertedRate);
        }

        state = state.copyWith(
          isLoading: false,
          commissionRates: updatedRates,
        );
        AppLogger.info('Commission rate upserted: ${upsertedRate.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upsert commission rate: $failure');
      },
    );
  }

  // ─── Load Commission Records ────────────────────────────────────────

  /// Loads commission payment records.
  Future<void> loadCommissionRecords({
    String? sellerId,
    int limit = 20,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCommissionRecordsUseCase(
      GetCommissionRecordsParams(
        sellerId: sellerId,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      onSuccess: (records) {
        state = state.copyWith(isLoading: false, commissionRecords: records);
        AppLogger.info('Loaded ${records.length} commission records');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load commission records: $failure');
      },
    );
  }

  // ─── Clear Error ────────────────────────────────────────────────────

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
// COMMISSION PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the commission management feature (Super Admin).
///
/// The factory accepts all required use cases via named parameters.
final commissionProvider =
    StateNotifierProvider<CommissionNotifier, CommissionState>(
  (ref) => CommissionNotifier(
    getCommissionRatesUseCase: ref.watch(getCommissionRatesUseCaseProvider),
    upsertCommissionRateUseCase:
        ref.watch(upsertCommissionRateUseCaseProvider),
    getCommissionRecordsUseCase:
        ref.watch(getCommissionRecordsUseCaseProvider),
  ),
);
