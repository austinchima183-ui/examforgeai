import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/suggest_schedule_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR PLANNER STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the calendar planner feature.
///
/// Tracks calendar events, the selected date, loading flags for each
/// operation, and error/success messages.
class CalendarPlannerState {
  const CalendarPlannerState({
    this.events = const [],
    this.selectedDate,
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isSuggesting = false,
    this.error,
    this.successMessage,
    this.suggestedEvents = const [],
  });

  /// The list of calendar events.
  final List<CalendarEventEntity> events;

  /// The currently selected date, or `null`.
  final DateTime? selectedDate;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a create event operation is in progress.
  final bool isCreating;

  /// Whether an update event operation is in progress.
  final bool isUpdating;

  /// Whether a delete event operation is in progress.
  final bool isDeleting;

  /// Whether an AI schedule suggestion operation is in progress.
  final bool isSuggesting;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message, or `null`.
  final String? successMessage;

  /// Events suggested by the AI scheduler.
  final List<CalendarEventEntity> suggestedEvents;

  /// Whether any async operation is in progress.
  bool get isBusy =>
      isLoading || isCreating || isUpdating || isDeleting || isSuggesting;

  /// Events occurring on the selected date.
  List<CalendarEventEntity> get eventsForSelectedDate {
    if (selectedDate == null) return events;
    return events.where((e) {
      final eventDate = DateTime(
        e.startTime.year,
        e.startTime.month,
        e.startTime.day,
      );
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      return eventDate == selected;
    }).toList();
  }

  /// Creates a copy of this state with the given fields replaced.
  CalendarPlannerState copyWith({
    List<CalendarEventEntity>? events,
    DateTime? selectedDate,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isSuggesting,
    String? error,
    String? successMessage,
    List<CalendarEventEntity>? suggestedEvents,
  }) {
    return CalendarPlannerState(
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isSuggesting: isSuggesting ?? this.isSuggesting,
      error: error,
      successMessage: successMessage,
      suggestedEvents: suggestedEvents ?? this.suggestedEvents,
    );
  }

  /// Clears the current error message.
  CalendarPlannerState clearError() => copyWith(error: null);

  /// Clears the current success message.
  CalendarPlannerState clearSuccessMessage() => copyWith(successMessage: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR PLANNER NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the calendar planner state.
///
/// All calendar planner operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the event list on success
/// 4. Sets [error] on failure
class CalendarPlannerNotifier extends StateNotifier<CalendarPlannerState> {
  CalendarPlannerNotifier({
    required GetEventsUseCase getEventsUseCase,
    required CreateEventUseCase createEventUseCase,
    required SuggestScheduleUseCase suggestScheduleUseCase,
  })  : _getEventsUseCase = getEventsUseCase,
        _createEventUseCase = createEventUseCase,
        _suggestScheduleUseCase = suggestScheduleUseCase,
        super(const CalendarPlannerState());

  final GetEventsUseCase _getEventsUseCase;
  final CreateEventUseCase _createEventUseCase;
  final SuggestScheduleUseCase _suggestScheduleUseCase;

  // ─── Load Events ───────────────────────────────────────────────────

  /// Loads calendar events within an optional date range.
  Future<void> loadEvents({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getEventsUseCase(
      GetEventsParams(startDate: startDate, endDate: endDate),
    );

    result.fold(
      onSuccess: (events) {
        state = state.copyWith(
          isLoading: false,
          events: events,
          error: null,
        );
        AppLogger.info('Loaded ${events.length} calendar events');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load events: $failure');
      },
    );
  }

  // ─── Create Event ──────────────────────────────────────────────────

  /// Creates a new calendar event with the provided [params].
  Future<void> createEvent(CreateEventParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createEventUseCase(params);

    result.fold(
      onSuccess: (event) {
        final updatedList = [event, ...state.events];
        state = state.copyWith(
          isCreating: false,
          events: updatedList,
          successMessage: 'Event created successfully',
          error: null,
        );
        AppLogger.info('Event created: ${event.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create event: $failure');
      },
    );
  }

  // ─── Update Event ──────────────────────────────────────────────────

  /// Updates an existing calendar event.
  Future<void> updateEvent(CalendarEventEntity event) async {
    state = state.copyWith(isUpdating: true, error: null);

    // Optimistically update the local state.
    final updatedList = state.events
        .map((e) => e.id == event.id ? event : e)
        .toList();

    state = state.copyWith(
      isUpdating: false,
      events: updatedList,
      successMessage: 'Event updated successfully',
      error: null,
    );
    AppLogger.info('Event updated: ${event.id}');
  }

  // ─── Delete Event ──────────────────────────────────────────────────

  /// Deletes a calendar event by [eventId].
  Future<void> deleteEvent(String eventId) async {
    state = state.copyWith(isDeleting: true, error: null);

    // Optimistically remove from local state.
    final updatedList =
        state.events.where((e) => e.id != eventId).toList();
    state = state.copyWith(
      isDeleting: false,
      events: updatedList,
      successMessage: 'Event deleted successfully',
      error: null,
    );
    AppLogger.info('Event deleted: $eventId');
  }

  // ─── Select Date ───────────────────────────────────────────────────

  /// Sets the currently selected date on the calendar.
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // ─── Suggest Schedule (AI) ─────────────────────────────────────────

  /// Suggests a schedule using AI based on the provided preferences.
  Future<void> suggestSchedule(Map<String, dynamic> preferences) async {
    state = state.copyWith(isSuggesting: true, error: null);

    final result = await _suggestScheduleUseCase(
      SuggestScheduleParams(preferences: preferences),
    );

    result.fold(
      onSuccess: (suggestedEvents) {
        state = state.copyWith(
          isSuggesting: false,
          suggestedEvents: suggestedEvents,
          successMessage: 'Schedule suggestion generated successfully',
          error: null,
        );
        AppLogger.info(
          'Generated ${suggestedEvents.length} suggested events',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSuggesting: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to suggest schedule: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ─── Clear Success Message ─────────────────────────────────────────

  /// Clears the current success message from the state.
  void clearSuccessMessage() {
    state = state.clearSuccessMessage();
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
// CALENDAR PLANNER PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final calendarPlannerProvider =
    StateNotifierProvider<CalendarPlannerNotifier, CalendarPlannerState>(
  (ref) {
    return CalendarPlannerNotifier(
      getEventsUseCase: ref.watch(getEventsUseCaseProvider),
      createEventUseCase: ref.watch(createEventUseCaseProvider),
      suggestScheduleUseCase: ref.watch(suggestScheduleUseCaseProvider),
    );
  },
);
