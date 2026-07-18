import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_parent_calendar_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT CALENDAR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the parent calendar feature.
///
/// Tracks the calendar events, loading flag, error message,
/// selected date, and the active date range.
class ParentCalendarState {
  const ParentCalendarState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.selectedDate,
    this.startDate,
    this.endDate,
  });

  /// The list of calendar events for the active date range.
  final List<ParentCalendarEventEntity> events;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected date, or `null`.
  final DateTime? selectedDate;

  /// The start date of the active date range.
  final DateTime? startDate;

  /// The end date of the active date range.
  final DateTime? endDate;

  /// Creates a copy of this state with the given fields replaced.
  ParentCalendarState copyWith({
    List<ParentCalendarEventEntity>? events,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ParentCalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Clears the current error message.
  ParentCalendarState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT CALENDAR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the parent calendar feature's state.
///
/// All calendar operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the [GetParentCalendarUseCase]
/// 3. Updates [events] and date range on success
/// 4. Sets [error] on failure
class ParentCalendarNotifier extends StateNotifier<ParentCalendarState> {
  ParentCalendarNotifier({
    required GetParentCalendarUseCase getParentCalendarUseCase,
  })  : _getParentCalendarUseCase = getParentCalendarUseCase,
        super(const ParentCalendarState());

  final GetParentCalendarUseCase _getParentCalendarUseCase;

  // ─── Load Events ───────────────────────────────────────────────────

  /// Loads calendar events for the specified date range,
  /// optionally filtered by [studentId].
  Future<void> loadEvents(
    DateTime startDate,
    DateTime endDate, [
    String? studentId,
  ]) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      startDate: startDate,
      endDate: endDate,
    );

    final result = await _getParentCalendarUseCase(
      GetParentCalendarParams(
        startDate: startDate,
        endDate: endDate,
        studentId: studentId,
      ),
    );

    result.fold(
      onSuccess: (events) {
        state = state.copyWith(
          isLoading: false,
          events: events,
          error: null,
        );
        AppLogger.info(
          'Parent calendar events loaded (${events.length} events)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load parent calendar events: $failure');
      },
    );
  }

  // ─── Select Date ───────────────────────────────────────────────────

  /// Sets the currently selected date.
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
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
// PARENT CALENDAR PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final parentCalendarProvider =
    StateNotifierProvider<ParentCalendarNotifier, ParentCalendarState>(
        (ref) {
  return ParentCalendarNotifier(
    getParentCalendarUseCase: ref.watch(getParentCalendarUseCaseProvider),
  );
});
