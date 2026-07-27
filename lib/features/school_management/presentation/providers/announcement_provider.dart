import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';



// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the announcement listing feature.
class AnnouncementListState {
  const AnnouncementListState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
    this.typeFilter,
  });

  /// The list of announcements.
  final List<AnnouncementEntity> announcements;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by announcement type.
  final AnnouncementType? typeFilter;

  /// Number of announcements currently loaded.
  int get loadedCount => announcements.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  AnnouncementListState copyWith({
    List<AnnouncementEntity>? announcements,
    bool? isLoading,
    String? error,
    AnnouncementType? typeFilter,
  }) {
    return AnnouncementListState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  /// Clears the current error message.
  AnnouncementListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the announcement list feature's state.
class AnnouncementListNotifier extends StateNotifier<AnnouncementListState> {
  AnnouncementListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const AnnouncementListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  // ─── Load Announcements ────────────────────────────────────────────

  /// Loads announcements for a school with optional filters.
  Future<void> loadAnnouncements({
    required String schoolId,
    AnnouncementType? type,
    bool? isPublished,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getAnnouncements(
      schoolId: schoolId,
      type: type ?? state.typeFilter,
      isPublished: isPublished,
      page: page,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (announcements) {
        state = state.copyWith(
          isLoading: false,
          announcements: announcements,
          error: null,
        );
        AppLogger.info('Loaded ${announcements.length} announcements');
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

  // ─── Create Announcement ───────────────────────────────────────────

  /// Creates a new announcement.
  Future<void> createAnnouncement(AnnouncementEntity announcement) async {
    final result = await _repository.createAnnouncement(announcement);

    result.fold(
      onSuccess: (createdAnnouncement) {
        final updatedList = [createdAnnouncement, ...state.announcements];
        state = state.copyWith(announcements: updatedList, error: null);
        AppLogger.info('Announcement created: ${createdAnnouncement.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create announcement: $failure');
      },
    );
  }

  // ─── Update Announcement ───────────────────────────────────────────

  /// Updates an existing announcement.
  Future<void> updateAnnouncement(AnnouncementEntity announcement) async {
    final result = await _repository.updateAnnouncement(announcement);

    result.fold(
      onSuccess: (updatedAnnouncement) {
        final updatedList = state.announcements
            .map((a) => a.id == updatedAnnouncement.id ? updatedAnnouncement : a)
            .toList();
        state = state.copyWith(announcements: updatedList, error: null);
        AppLogger.info('Announcement updated: ${updatedAnnouncement.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update announcement: $failure');
      },
    );
  }

  // ─── Delete Announcement ───────────────────────────────────────────

  /// Deletes an announcement by its ID.
  Future<void> deleteAnnouncement(String announcementId) async {
    final result = await _repository.deleteAnnouncement(announcementId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.announcements
            .where((a) => a.id != announcementId)
            .toList();
        state = state.copyWith(announcements: updatedList, error: null);
        AppLogger.info('Announcement deleted: $announcementId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete announcement: $failure');
      },
    );
  }

  // ─── Publish Announcement ──────────────────────────────────────────

  /// Publishes an announcement by its ID.
  Future<void> publishAnnouncement(String announcementId) async {
    final result = await _repository.publishAnnouncement(announcementId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.announcements.map((a) {
          if (a.id == announcementId) {
            return a.copyWith(
              isPublished: true,
              publishedAt: DateTime.now(),
            );
          }
          return a;
        }).toList();
        state = state.copyWith(announcements: updatedList, error: null);
        AppLogger.info('Announcement published: $announcementId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to publish announcement: $failure');
      },
    );
  }

  // ─── Set Type Filter ───────────────────────────────────────────────

  /// Sets the announcement type filter.
  void setTypeFilter(AnnouncementType? type) {
    state = state.copyWith(typeFilter: type);
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

/// Provides the [AnnouncementListNotifier] and its [AnnouncementListState].
final announcementListProvider =
    StateNotifierProvider<AnnouncementListNotifier, AnnouncementListState>(
        (ref) {
  return AnnouncementListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
