import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/get_communication_dashboard_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the communication dashboard feature.
///
/// Tracks dashboard data, loading flag, and error message.
class CommunicationDashboardState {
  const CommunicationDashboardState({
    this.dashboardData,
    this.isLoading = false,
    this.error,
  });

  /// The communication dashboard data, or `null`.
  final CommunicationDashboardEntity? dashboardData;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  CommunicationDashboardState copyWith({
    CommunicationDashboardEntity? dashboardData,
    bool? isLoading,
    String? error,
    bool clearDashboardData = false,
  }) {
    return CommunicationDashboardState(
      dashboardData: clearDashboardData
          ? null
          : (dashboardData ?? this.dashboardData),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  CommunicationDashboardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the communication dashboard feature's state.
///
/// All dashboard operations flow through this notifier, which:
/// 1. Sets the loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates dashboard data on success
/// 4. Sets [error] on failure
class CommunicationDashboardNotifier
    extends StateNotifier<CommunicationDashboardState> {
  CommunicationDashboardNotifier({
    required GetCommunicationDashboardUseCase getCommunicationDashboardUseCase,
  })  : _getCommunicationDashboardUseCase = getCommunicationDashboardUseCase,
        super(const CommunicationDashboardState());

  final GetCommunicationDashboardUseCase _getCommunicationDashboardUseCase;

  // ─── Load Dashboard ─────────────────────────────────────────────────

  /// Loads the communication dashboard data.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCommunicationDashboardUseCase();

    result.fold(
      onSuccess: (dashboard) {
        state = state.copyWith(
          isLoading: false,
          dashboardData: dashboard,
          error: null,
        );
        AppLogger.info('Communication dashboard loaded');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load communication dashboard: $failure');
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
// COMMUNICATION DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final communicationDashboardProvider = StateNotifierProvider<
    CommunicationDashboardNotifier, CommunicationDashboardState>((ref) {
  return CommunicationDashboardNotifier(
    getCommunicationDashboardUseCase:
        ref.watch(getCommunicationDashboardUseCaseProvider),
  );
});
