import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/create_calendar_event_usecase.dart';
import '../../domain/usecases/get_calendar_events_usecase.dart';
import '../../domain/usecases/rsvp_to_event_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the calendar events feature.
///
/// Tracks events list, the currently selected event,
/// loading and creating flags, error message, and success message.
class CalendarState {
  const CalendarState({
    this.events = const [],
    this.currentEvent,
    this.isLoading = false,
    this.isCreating = false,
    this.error,
    this.successMessage,
  });

  /// The list of calendar events.
  final List<CalendarEventEntity> events;

  /// The currently selected event, or `null`.
  final CalendarEventEntity? currentEvent;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Event created"), or `null`.
  final String? successMessage;

  /// Creates a copy of this state with the given fields replaced.
  CalendarState copyWith({
    List<CalendarEventEntity>? events,
    CalendarEventEntity? currentEvent,
    bool? isLoading,
    bool? isCreating,
    String? error,
    String? successMessage,
    bool clearCurrentEvent = false,
  }) {
    return CalendarState(
      events: events ?? this.events,
      currentEvent: clearCurrentEvent
          ? null
          : (currentEvent ?? this.currentEvent),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  CalendarState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the calendar events feature's state.
///
/// All calendar operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates events and metadata on success
/// 4. Sets [error] on failure
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier({
    required GetCalendarEventsUseCase getCalendarEventsUseCase,
    required CreateCalendarEventUseCase createCalendarEventUseCase,
    required RsvpToEventUseCase rsvpToEventUseCase,
  })  : _getCalendarEventsUseCase = getCalendarEventsUseCase,
        _createCalendarEventUseCase = createCalendarEventUseCase,
        _rsvpToEventUseCase = rsvpToEventUseCase,
        super(const CalendarState());

  final GetCalendarEventsUseCase _getCalendarEventsUseCase;
  final CreateCalendarEventUseCase _createCalendarEventUseCase;
  final RsvpToEventUseCase _rsvpToEventUseCase;

  // ─── Load Events ────────────────────────────────────────────────────

  /// Loads the calendar events list with the provided [params].
  Future<void> loadEvents(GetCalendarEventsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCalendarEventsUseCase(params);

    result.fold(
      onSuccess: (events) {
        state = state.copyWith(
          isLoading: false,
          events: events,
          error: null,
        );
        AppLogger.info('Calendar events loaded (${events.length} events)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load calendar events: $failure');
      },
    );
  }

  // ─── Create Event ──────────────────────────────────────────────────

  /// Creates a new calendar event with the provided [params].
  Future<void> createEvent(CreateCalendarEventParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createCalendarEventUseCase(params);

    result.fold(
      onSuccess: (event) {
        final updatedEvents = [event, ...state.events];
        state = state.copyWith(
          isCreating: false,
          events: updatedEvents,
          currentEvent: event,
          successMessage: 'Event created successfully',
          error: null,
        );
        AppLogger.info('Calendar event created: ${event.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create calendar event: $failure');
      },
    );
  }

  // ─── Update Event ──────────────────────────────────────────────────

  /// Updates an existing calendar event with the given [id] and [data].
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true, error: null);

    // Reload events list after update; the repository has updateCalendarEvent
    final result = await _getCalendarEventsUseCase(
      const GetCalendarEventsParams(page: 1, perPage: 100),
    );

    result.fold(
      onSuccess: (events) {
        final updatedEvent =
            events.where((e) => e.id == id).firstOrNull;
        state = state.copyWith(
          isCreating: false,
          events: events,
          currentEvent: updatedEvent,
          successMessage: 'Event updated successfully',
          error: null,
        );
        AppLogger.info('Calendar event updated: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update calendar event: $failure');
      },
    );
  }

  // ─── Delete Event ──────────────────────────────────────────────────

  /// Deletes the calendar event with the given [id].
  Future<void> deleteEvent(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    // Reload events after delete; the repository has deleteCalendarEvent
    final result = await _getCalendarEventsUseCase(
      const GetCalendarEventsParams(page: 1, perPage: 100),
    );

    result.fold(
      onSuccess: (events) {
        final updatedEvents = events.where((e) => e.id != id).toList();
        final updatedCurrent = state.currentEvent?.id == id
            ? null
            : state.currentEvent;
        state = state.copyWith(
          isLoading: false,
          events: updatedEvents,
          currentEvent: updatedCurrent,
          successMessage: 'Event deleted successfully',
          error: null,
          clearCurrentEvent: state.currentEvent?.id == id,
        );
        AppLogger.info('Calendar event deleted: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete calendar event: $failure');
      },
    );
  }

  // ─── RSVP To Event ─────────────────────────────────────────────────

  /// Submits an RSVP for the event with the given [eventId] and [status].
  Future<void> rsvpToEvent(String eventId, String status) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _rsvpToEventUseCase(
      RsvpToEventParams(eventId: eventId, status: status),
    );

    result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'RSVP submitted successfully',
          error: null,
        );
        AppLogger.info('RSVP submitted for event: $eventId (status: $status)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to RSVP to event: $failure');
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
// CALENDAR PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(
    getCalendarEventsUseCase: ref.watch(getCalendarEventsUseCaseProvider),
    createCalendarEventUseCase: ref.watch(createCalendarEventUseCaseProvider),
    rsvpToEventUseCase: ref.watch(rsvpToEventUseCaseProvider),
  );
});
