import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/usecases/get_revenue_analytics_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// REVENUE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the revenue analytics feature.
///
/// Tracks revenue data points, dashboard summary, and loading/error
/// states for revenue operations.
class RevenueState {
  const RevenueState({
    this.isLoading = false,
    this.revenueData = const [],
    this.dashboardSummary,
    this.error,
  });

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// The list of revenue data points.
  final List<RevenueDataPoint> revenueData;

  /// The billing dashboard summary, or `null`.
  final BillingDashboardSummaryEntity? dashboardSummary;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether revenue data is available.
  bool get hasRevenueData => revenueData.isNotEmpty;

  /// Whether a dashboard summary is available.
  bool get hasDashboardSummary => dashboardSummary != null;

  /// Creates a copy of this state with the given fields replaced.
  RevenueState copyWith({
    bool? isLoading,
    List<RevenueDataPoint>? revenueData,
    BillingDashboardSummaryEntity? dashboardSummary,
    String? error,
  }) {
    return RevenueState(
      isLoading: isLoading ?? this.isLoading,
      revenueData: revenueData ?? this.revenueData,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      error: error,
    );
  }

  /// Clears the current error message.
  RevenueState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// REVENUE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the revenue analytics feature's
/// state.
///
/// Supports loading revenue data and the billing dashboard summary.
class RevenueNotifier extends StateNotifier<RevenueState> {
  RevenueNotifier({
    required GetRevenueDataUseCase getRevenueDataUseCase,
    required GetBillingDashboardSummaryUseCase
        getBillingDashboardSummaryUseCase,
  })  : _getRevenueDataUseCase = getRevenueDataUseCase,
        _getBillingDashboardSummaryUseCase =
            getBillingDashboardSummaryUseCase,
        super(const RevenueState());

  final GetRevenueDataUseCase _getRevenueDataUseCase;
  final GetBillingDashboardSummaryUseCase
      _getBillingDashboardSummaryUseCase;

  // ─── Load Revenue Data ─────────────────────────────────────────────

  /// Loads revenue data for the given period.
  Future<void> loadRevenueData({
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getRevenueDataUseCase(
      GetRevenueDataParams(
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    result.fold(
      onSuccess: (revenueDataEntity) {
        state = state.copyWith(
          isLoading: false,
          revenueData: revenueDataEntity.dataPoints,
          error: null,
        );
        AppLogger.info(
          'Loaded ${revenueDataEntity.dataPoints.length} revenue data points',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load revenue data: $failure');
      },
    );
  }

  // ─── Load Dashboard Summary ────────────────────────────────────────

  /// Loads the billing dashboard summary.
  Future<void> loadDashboardSummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getBillingDashboardSummaryUseCase();

    result.fold(
      onSuccess: (summary) {
        state = state.copyWith(
          isLoading: false,
          dashboardSummary: summary,
          error: null,
        );
        AppLogger.info('Loaded billing dashboard summary');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning(
          'Failed to load dashboard summary: $failure',
        );
      },
    );
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
// REVENUE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod provider for the revenue analytics feature.
///
/// The factory accepts all required use cases via named parameters.
final revenueProvider =
    StateNotifierProvider<RevenueNotifier, RevenueState>(
  (ref) => RevenueNotifier(
    getRevenueDataUseCase: ref.watch(getRevenueDataUseCaseProvider),
    getBillingDashboardSummaryUseCase:
        ref.watch(getBillingDashboardSummaryUseCaseProvider),
  ),
);
