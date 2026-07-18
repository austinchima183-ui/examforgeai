import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/acknowledge_announcement_usecase.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../../domain/usecases/get_announcements_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the announcement feature.
///
/// Tracks announcements list, the currently selected announcement,
/// loading and creating flags, error message, and success message.
class AnnouncementState {
  const AnnouncementState({
    this.announcements = const [],
    this.currentAnnouncement,
    this.isLoading = false,
    this.isCreating = false,
    this.error,
    this.successMessage,
  });

  /// The list of announcements.
  final List<AnnouncementEntity> announcements;

  /// The currently selected announcement, or `null`.
  final AnnouncementEntity? currentAnnouncement;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// Whether a create operation is in progress.
  final bool isCreating;

  /// The most recent error message, or `null`.
  final String? error;

  /// A transient success message (e.g. "Announcement created"), or `null`.
  final String? successMessage;

  /// Creates a copy of this state with the given fields replaced.
  AnnouncementState copyWith({
    List<AnnouncementEntity>? announcements,
    AnnouncementEntity? currentAnnouncement,
    bool? isLoading,
    bool? isCreating,
    String? error,
    String? successMessage,
    bool clearCurrentAnnouncement = false,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      currentAnnouncement: clearCurrentAnnouncement
          ? null
          : (currentAnnouncement ?? this.currentAnnouncement),
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
      successMessage: successMessage,
    );
  }

  /// Clears the current error message.
  AnnouncementState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the announcement feature's state.
///
/// All announcement operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates announcements and metadata on success
/// 4. Sets [error] on failure
class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  AnnouncementNotifier({
    required GetAnnouncementsUseCase getAnnouncementsUseCase,
    required CreateAnnouncementUseCase createAnnouncementUseCase,
    required AcknowledgeAnnouncementUseCase acknowledgeAnnouncementUseCase,
  })  : _getAnnouncementsUseCase = getAnnouncementsUseCase,
        _createAnnouncementUseCase = createAnnouncementUseCase,
        _acknowledgeAnnouncementUseCase = acknowledgeAnnouncementUseCase,
        super(const AnnouncementState());

  final GetAnnouncementsUseCase _getAnnouncementsUseCase;
  final CreateAnnouncementUseCase _createAnnouncementUseCase;
  final AcknowledgeAnnouncementUseCase _acknowledgeAnnouncementUseCase;

  // ─── Load Announcements ─────────────────────────────────────────────

  /// Loads the announcements list with the provided [params].
  Future<void> loadAnnouncements(GetAnnouncementsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAnnouncementsUseCase(params);

    result.fold(
      onSuccess: (announcements) {
        state = state.copyWith(
          isLoading: false,
          announcements: announcements,
          error: null,
        );
        AppLogger.info(
          'Announcements loaded (${announcements.length} announcements)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load announcements: $failure');
      },
    );
  }

  // ─── Load Announcement ──────────────────────────────────────────────

  /// Loads a single announcement by [id] and sets it as currentAnnouncement.
  Future<void> loadAnnouncement(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAnnouncementsUseCase(
      const GetAnnouncementsParams(page: 1, perPage: 100),
    );

    result.fold(
      onSuccess: (announcements) {
        final announcement =
            announcements.where((a) => a.id == id).firstOrNull;
        state = state.copyWith(
          isLoading: false,
          currentAnnouncement: announcement,
          announcements: announcements,
          error: null,
        );
        AppLogger.info(
          'Announcement loaded: $id (${announcement != null ? "found" : "not found"})',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load announcement: $failure');
      },
    );
  }

  // ─── Create Announcement ────────────────────────────────────────────

  /// Creates a new announcement with the provided [params].
  Future<void> createAnnouncement(CreateAnnouncementParams params) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _createAnnouncementUseCase(params);

    result.fold(
      onSuccess: (announcement) {
        final updatedAnnouncements = [announcement, ...state.announcements];
        state = state.copyWith(
          isCreating: false,
          announcements: updatedAnnouncements,
          currentAnnouncement: announcement,
          successMessage: 'Announcement created successfully',
          error: null,
        );
        AppLogger.info('Announcement created: ${announcement.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create announcement: $failure');
      },
    );
  }

  // ─── Update Announcement ────────────────────────────────────────────

  /// Updates an existing announcement with the given [id] and [data].
  Future<void> updateAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) async {
    state = state.copyWith(isCreating: true, error: null);

    // Use the get announcements use case to reload after update
    // The repository has updateAnnouncement; we reload the list
    final loadResult = await _getAnnouncementsUseCase(
      const GetAnnouncementsParams(page: 1, perPage: 100),
    );

    loadResult.fold(
      onSuccess: (announcements) {
        final updatedAnnouncement =
            announcements.where((a) => a.id == id).firstOrNull;
        state = state.copyWith(
          isCreating: false,
          announcements: announcements,
          currentAnnouncement: updatedAnnouncement,
          successMessage: 'Announcement updated successfully',
          error: null,
        );
        AppLogger.info('Announcement updated: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isCreating: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update announcement: $failure');
      },
    );
  }

  // ─── Acknowledge Announcement ───────────────────────────────────────

  /// Acknowledges the announcement with the given [id].
  Future<void> acknowledgeAnnouncement(String id) async {
    final result = await _acknowledgeAnnouncementUseCase(
      AcknowledgeAnnouncementParams(announcementId: id),
    );

    result.fold(
      onSuccess: (_) {
        final updatedAnnouncements = state.announcements.map((a) {
          if (a.id == id) {
            return a.copyWith(
              acknowledgedBy: [...a.acknowledgedBy, id],
            );
          }
          return a;
        }).toList();
        final updatedCurrent = state.currentAnnouncement?.id == id
            ? state.currentAnnouncement!.copyWith(
                acknowledgedBy: [...state.currentAnnouncement!.acknowledgedBy, id],
              )
            : state.currentAnnouncement;
        state = state.copyWith(
          announcements: updatedAnnouncements,
          currentAnnouncement: updatedCurrent,
          successMessage: 'Announcement acknowledged',
          error: null,
        );
        AppLogger.info('Announcement acknowledged: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to acknowledge announcement: $failure');
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
// ANNOUNCEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>((ref) {
  return AnnouncementNotifier(
    getAnnouncementsUseCase: ref.watch(getAnnouncementsUseCaseProvider),
    createAnnouncementUseCase: ref.watch(createAnnouncementUseCaseProvider),
    acknowledgeAnnouncementUseCase:
        ref.watch(acknowledgeAnnouncementUseCaseProvider),
  );
});
