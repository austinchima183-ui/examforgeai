import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// SESSION LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the academic session listing feature.
class SessionListState {
  const SessionListState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.currentSession,
  });

  /// The list of academic sessions.
  final List<AcademicSessionEntity> sessions;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently active session.
  final AcademicSessionEntity? currentSession;

  /// Creates a copy of this state with the given fields replaced.
  SessionListState copyWith({
    List<AcademicSessionEntity>? sessions,
    bool? isLoading,
    String? error,
    AcademicSessionEntity? currentSession,
  }) {
    return SessionListState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentSession: currentSession ?? this.currentSession,
    );
  }

  /// Clears the current error message.
  SessionListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SESSION LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the academic session list feature's state.
class SessionListNotifier extends StateNotifier<SessionListState> {
  SessionListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const SessionListState());

  final SchoolManagementRepository _repository;

  // ─── Load Sessions ─────────────────────────────────────────────────

  /// Loads all academic sessions for a school.
  Future<void> loadSessions(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSessions(schoolId);

    result.fold(
      onSuccess: (sessions) {
        // Also fetch the current session
        final current = sessions.where((s) => s.isCurrent).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          sessions: sessions,
          currentSession: current,
          error: null,
        );
        AppLogger.info('Loaded ${sessions.length} academic sessions');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load sessions: $failure');
      },
    );
  }

  // ─── Create Session ────────────────────────────────────────────────

  /// Creates a new academic session.
  Future<void> createSession(AcademicSessionEntity session) async {
    final result = await _repository.createSession(session);

    result.fold(
      onSuccess: (createdSession) {
        final updatedList = [createdSession, ...state.sessions];
        state = state.copyWith(sessions: updatedList, error: null);
        AppLogger.info('Session created: ${createdSession.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create session: $failure');
      },
    );
  }

  // ─── Update Session ────────────────────────────────────────────────

  /// Updates an existing academic session.
  Future<void> updateSession(AcademicSessionEntity session) async {
    final result = await _repository.updateSession(session);

    result.fold(
      onSuccess: (updatedSession) {
        final updatedList = state.sessions
            .map((s) => s.id == updatedSession.id ? updatedSession : s)
            .toList();
        final isCurrent = updatedSession.isCurrent;
        state = state.copyWith(
          sessions: updatedList,
          currentSession: isCurrent ? updatedSession : state.currentSession,
          error: null,
        );
        AppLogger.info('Session updated: ${updatedSession.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update session: $failure');
      },
    );
  }

  // ─── Set Current Session ───────────────────────────────────────────

  /// Sets the given session as the current active session.
  Future<void> setCurrentSession(String sessionId) async {
    final result = await _repository.setCurrentSession(sessionId);

    result.fold(
      onSuccess: (_) {
        // Update local state to reflect the change
        final updatedSessions = state.sessions.map((s) {
          return s.copyWith(isCurrent: s.id == sessionId);
        }).toList();
        final current = updatedSessions.where((s) => s.id == sessionId).first;
        state = state.copyWith(
          sessions: updatedSessions,
          currentSession: current,
          error: null,
        );
        AppLogger.info('Current session set: $sessionId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to set current session: $failure');
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
// TERM LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the term listing feature.
class TermListState {
  const TermListState({
    this.terms = const [],
    this.isLoading = false,
    this.error,
    this.currentTerm,
  });

  /// The list of terms for the selected academic session.
  final List<TermEntity> terms;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently active term.
  final TermEntity? currentTerm;

  /// Creates a copy of this state with the given fields replaced.
  TermListState copyWith({
    List<TermEntity>? terms,
    bool? isLoading,
    String? error,
    TermEntity? currentTerm,
  }) {
    return TermListState(
      terms: terms ?? this.terms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentTerm: currentTerm ?? this.currentTerm,
    );
  }

  /// Clears the current error message.
  TermListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TERM LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the term list feature's state.
class TermListNotifier extends StateNotifier<TermListState> {
  TermListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const TermListState());

  final SchoolManagementRepository _repository;

  // ─── Load Terms ────────────────────────────────────────────────────

  /// Loads all terms for a given academic session.
  Future<void> loadTerms(String academicSessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTerms(academicSessionId);

    result.fold(
      onSuccess: (terms) {
        final current = terms.where((t) => t.isCurrent).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          terms: terms,
          currentTerm: current,
          error: null,
        );
        AppLogger.info('Loaded ${terms.length} terms');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load terms: $failure');
      },
    );
  }

  // ─── Create Term ───────────────────────────────────────────────────

  /// Creates a new term.
  Future<void> createTerm(TermEntity term) async {
    final result = await _repository.createTerm(term);

    result.fold(
      onSuccess: (createdTerm) {
        final updatedList = [createdTerm, ...state.terms];
        state = state.copyWith(terms: updatedList, error: null);
        AppLogger.info('Term created: ${createdTerm.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create term: $failure');
      },
    );
  }

  // ─── Update Term ───────────────────────────────────────────────────

  /// Updates an existing term.
  Future<void> updateTerm(TermEntity term) async {
    final result = await _repository.updateTerm(term);

    result.fold(
      onSuccess: (updatedTerm) {
        final updatedList = state.terms
            .map((t) => t.id == updatedTerm.id ? updatedTerm : t)
            .toList();
        final isCurrent = updatedTerm.isCurrent;
        state = state.copyWith(
          terms: updatedList,
          currentTerm: isCurrent ? updatedTerm : state.currentTerm,
          error: null,
        );
        AppLogger.info('Term updated: ${updatedTerm.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update term: $failure');
      },
    );
  }

  // ─── Set Current Term ──────────────────────────────────────────────

  /// Sets the given term as the current active term.
  Future<void> setCurrentTerm(String termId) async {
    final result = await _repository.setCurrentTerm(termId);

    result.fold(
      onSuccess: (_) {
        final updatedTerms = state.terms.map((t) {
          return t.copyWith(isCurrent: t.id == termId);
        }).toList();
        final current = updatedTerms.where((t) => t.id == termId).first;
        state = state.copyWith(
          terms: updatedTerms,
          currentTerm: current,
          error: null,
        );
        AppLogger.info('Current term set: $termId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to set current term: $failure');
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
// CALENDAR STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the school calendar feature.
class CalendarState {
  const CalendarState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.selectedMonth,
  });

  /// The list of calendar events.
  final List<CalendarEventEntity> events;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// The currently selected month for filtering.
  final DateTime? selectedMonth;

  /// Creates a copy of this state with the given fields replaced.
  CalendarState copyWith({
    List<CalendarEventEntity>? events,
    bool? isLoading,
    String? error,
    DateTime? selectedMonth,
  }) {
    return CalendarState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  /// Clears the current error message.
  CalendarState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the school calendar feature's state.
class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const CalendarState());

  final SchoolManagementRepository _repository;

  // ─── Load Events ───────────────────────────────────────────────────

  /// Loads calendar events for a school with optional filters.
  Future<void> loadEvents({
    required String schoolId,
    String? termId,
    DateTime? startDate,
    DateTime? endDate,
    CalendarEventType? eventType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getCalendarEvents(
      schoolId: schoolId,
      termId: termId,
      startDate: startDate,
      endDate: endDate,
      eventType: eventType,
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
        AppLogger.warning('Failed to load calendar events: $failure');
      },
    );
  }

  // ─── Create Event ──────────────────────────────────────────────────

  /// Creates a new calendar event.
  Future<void> createEvent(CalendarEventEntity event) async {
    final result = await _repository.createCalendarEvent(event);

    result.fold(
      onSuccess: (createdEvent) {
        final updatedList = [...state.events, createdEvent];
        state = state.copyWith(events: updatedList, error: null);
        AppLogger.info('Calendar event created: ${createdEvent.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create calendar event: $failure');
      },
    );
  }

  // ─── Update Event ──────────────────────────────────────────────────

  /// Updates an existing calendar event.
  Future<void> updateEvent(CalendarEventEntity event) async {
    final result = await _repository.updateCalendarEvent(event);

    result.fold(
      onSuccess: (updatedEvent) {
        final updatedList = state.events
            .map((e) => e.id == updatedEvent.id ? updatedEvent : e)
            .toList();
        state = state.copyWith(events: updatedList, error: null);
        AppLogger.info('Calendar event updated: ${updatedEvent.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update calendar event: $failure');
      },
    );
  }

  // ─── Delete Event ──────────────────────────────────────────────────

  /// Deletes a calendar event by its ID.
  Future<void> deleteEvent(String eventId) async {
    final result = await _repository.deleteCalendarEvent(eventId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.events.where((e) => e.id != eventId).toList();
        state = state.copyWith(events: updatedList, error: null);
        AppLogger.info('Calendar event deleted: $eventId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete calendar event: $failure');
      },
    );
  }

  // ─── Set Selected Month ────────────────────────────────────────────

  /// Sets the selected month for calendar navigation.
  void setSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [SessionListNotifier] and its [SessionListState].
final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, SessionListState>((ref) {
  return SessionListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [TermListNotifier] and its [TermListState].
final termListProvider =
    StateNotifierProvider<TermListNotifier, TermListState>((ref) {
  return TermListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [CalendarNotifier] and its [CalendarState].
final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
