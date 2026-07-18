import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the timetable listing feature.
class TimetableListState {
  const TimetableListState({
    this.timetables = const [],
    this.isLoading = false,
    this.error,
  });

  /// The list of timetables.
  final List<TimetableEntity> timetables;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Number of timetables currently loaded.
  int get loadedCount => timetables.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  TimetableListState copyWith({
    List<TimetableEntity>? timetables,
    bool? isLoading,
    String? error,
  }) {
    return TimetableListState(
      timetables: timetables ?? this.timetables,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  TimetableListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the timetable list feature's state.
class TimetableListNotifier extends StateNotifier<TimetableListState> {
  TimetableListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const TimetableListState());

  final SchoolManagementRepository _repository;

  // ─── Load Timetables ───────────────────────────────────────────────

  /// Loads timetables for a school with optional filters.
  Future<void> loadTimetables({
    required String schoolId,
    String? termId,
    String? classId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTimetables(
      schoolId: schoolId,
      termId: termId,
      classId: classId,
    );

    result.fold(
      onSuccess: (timetables) {
        state = state.copyWith(
          isLoading: false,
          timetables: timetables,
          error: null,
        );
        AppLogger.info('Loaded ${timetables.length} timetables');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load timetables: $failure');
      },
    );
  }

  // ─── Create Timetable ──────────────────────────────────────────────

  /// Creates a new timetable.
  Future<void> createTimetable(TimetableEntity timetable) async {
    final result = await _repository.createTimetable(timetable);

    result.fold(
      onSuccess: (createdTimetable) {
        final updatedList = [createdTimetable, ...state.timetables];
        state = state.copyWith(timetables: updatedList, error: null);
        AppLogger.info('Timetable created: ${createdTimetable.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create timetable: $failure');
      },
    );
  }

  // ─── Delete Timetable ──────────────────────────────────────────────

  /// Deletes a timetable by its ID.
  Future<void> deleteTimetable(String timetableId) async {
    final result = await _repository.deleteTimetable(timetableId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.timetables.where((t) => t.id != timetableId).toList();
        state = state.copyWith(timetables: updatedList, error: null);
        AppLogger.info('Timetable deleted: $timetableId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete timetable: $failure');
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
// TIMETABLE DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the timetable detail feature.
class TimetableDetailState {
  const TimetableDetailState({
    this.timetable,
    this.conflicts = const [],
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed timetable with its slots, or `null`.
  final TimetableEntity? timetable;

  /// Conflicting slots detected during conflict checks.
  final List<TimetableSlotEntity> conflicts;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the timetable data has been loaded.
  bool get isLoaded => timetable != null;

  /// The slots belonging to this timetable.
  List<TimetableSlotEntity> get slots => timetable?.slots ?? [];

  /// Whether there are any conflicts.
  bool get hasConflicts => conflicts.isNotEmpty;

  /// Creates a copy of this state with the given fields replaced.
  TimetableDetailState copyWith({
    TimetableEntity? timetable,
    List<TimetableSlotEntity>? conflicts,
    bool? isLoading,
    String? error,
  }) {
    return TimetableDetailState(
      timetable: timetable ?? this.timetable,
      conflicts: conflicts ?? this.conflicts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  TimetableDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the timetable detail feature's state.
class TimetableDetailNotifier extends StateNotifier<TimetableDetailState> {
  TimetableDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const TimetableDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load Timetable ────────────────────────────────────────────────

  /// Loads a timetable by ID with its slots.
  Future<void> loadTimetable(String timetableId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTimetable(timetableId);

    result.fold(
      onSuccess: (timetable) {
        state = state.copyWith(
          isLoading: false,
          timetable: timetable,
          conflicts: [],
          error: null,
        );
        AppLogger.info('Loaded timetable detail: $timetableId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load timetable: $failure');
      },
    );
  }

  // ─── Add Slot ──────────────────────────────────────────────────────

  /// Adds a new slot to the current timetable.
  Future<void> addSlot(TimetableSlotEntity slot) async {
    final result = await _repository.addTimetableSlot(slot);

    result.fold(
      onSuccess: (createdSlot) {
        if (state.timetable != null) {
          final updatedSlots = [...state.timetable!.slots, createdSlot];
          final updatedTimetable =
              state.timetable!.copyWith(slots: updatedSlots);
          state = state.copyWith(
            timetable: updatedTimetable,
            error: null,
          );
        }
        AppLogger.info('Timetable slot added: ${createdSlot.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to add timetable slot: $failure');
      },
    );
  }

  // ─── Update Slot ───────────────────────────────────────────────────

  /// Updates an existing slot in the current timetable.
  Future<void> updateSlot(TimetableSlotEntity slot) async {
    final result = await _repository.updateTimetableSlot(slot);

    result.fold(
      onSuccess: (updatedSlot) {
        if (state.timetable != null) {
          final updatedSlots = state.timetable!.slots
              .map((s) => s.id == updatedSlot.id ? updatedSlot : s)
              .toList();
          final updatedTimetable =
              state.timetable!.copyWith(slots: updatedSlots);
          state = state.copyWith(
            timetable: updatedTimetable,
            error: null,
          );
        }
        AppLogger.info('Timetable slot updated: ${updatedSlot.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update timetable slot: $failure');
      },
    );
  }

  // ─── Delete Slot ───────────────────────────────────────────────────

  /// Deletes a slot from the current timetable.
  Future<void> deleteSlot(String slotId) async {
    final result = await _repository.deleteTimetableSlot(slotId);

    result.fold(
      onSuccess: (_) {
        if (state.timetable != null) {
          final updatedSlots =
              state.timetable!.slots.where((s) => s.id != slotId).toList();
          final updatedTimetable =
              state.timetable!.copyWith(slots: updatedSlots);
          state = state.copyWith(
            timetable: updatedTimetable,
            error: null,
          );
        }
        AppLogger.info('Timetable slot deleted: $slotId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete timetable slot: $failure');
      },
    );
  }

  // ─── Publish Timetable ─────────────────────────────────────────────

  /// Publishes the current timetable.
  Future<void> publishTimetable() async {
    if (state.timetable == null) return;

    final result = await _repository.publishTimetable(state.timetable!.id);

    result.fold(
      onSuccess: (_) {
        final updatedTimetable =
            state.timetable!.copyWith(isPublished: true);
        state = state.copyWith(
          timetable: updatedTimetable,
          error: null,
        );
        AppLogger.info('Timetable published: ${state.timetable!.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish timetable: $failure');
      },
    );
  }

  // ─── Check Conflicts ───────────────────────────────────────────────

  /// Checks for scheduling conflicts for a given slot.
  Future<void> checkConflicts(TimetableSlotEntity slot) async {
    final result = await _repository.checkSlotConflicts(slot);

    result.fold(
      onSuccess: (conflictingSlots) {
        state = state.copyWith(conflicts: conflictingSlots);
        AppLogger.info(
          'Conflict check found ${conflictingSlots.length} conflicts',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to check conflicts: $failure');
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
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [TimetableListNotifier] and its [TimetableListState].
final timetableListProvider =
    StateNotifierProvider<TimetableListNotifier, TimetableListState>((ref) {
  return TimetableListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [TimetableDetailNotifier] and its [TimetableDetailState].
final timetableDetailProvider =
    StateNotifierProvider<TimetableDetailNotifier, TimetableDetailState>(
        (ref) {
  return TimetableDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
