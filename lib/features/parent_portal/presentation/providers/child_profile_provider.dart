import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/get_child_profile_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD PROFILE STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the child profile feature.
///
/// Tracks the child profile entity, loading flag, and error state.
class ChildProfileState {
  const ChildProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  /// The child profile data, or `null` if not yet loaded.
  final ChildProfileEntity? profile;

  /// Whether a load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Creates a copy of this state with the given fields replaced.
  ChildProfileState copyWith({
    ChildProfileEntity? profile,
    bool? isLoading,
    String? error,
  }) {
    return ChildProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ChildProfileState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD PROFILE NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the child profile feature's state.
///
/// Loads and refreshes the profile for a specific student identified
/// by [studentId], delegating to [GetChildProfileUseCase].
class ChildProfileNotifier extends StateNotifier<ChildProfileState> {
  ChildProfileNotifier({
    required GetChildProfileUseCase getChildProfileUseCase,
  })  : _getChildProfileUseCase = getChildProfileUseCase,
        super(const ChildProfileState());

  final GetChildProfileUseCase _getChildProfileUseCase;

  // ─── Load Profile ────────────────────────────────────────────────

  /// Loads the profile for the specified [studentId].
  Future<void> loadProfile(String studentId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getChildProfileUseCase(
      GetChildProfileParams(studentId: studentId),
    );

    result.fold(
      onSuccess: (profile) {
        state = state.copyWith(
          isLoading: false,
          profile: profile,
          error: null,
        );
        AppLogger.info('Child profile loaded for student: $studentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load child profile: $failure');
      },
    );
  }

  // ─── Refresh Profile ─────────────────────────────────────────────

  /// Refreshes the child profile data.
  Future<void> refreshProfile(String studentId) async {
    await loadProfile(studentId);
  }

  // ─── Clear Error ─────────────────────────────────────────────────

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
// CHILD PROFILE PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the child profile [StateNotifier].
///
/// Wires up the [ChildProfileNotifier] with its required use case.
final childProfileProvider = StateNotifierProvider<
    ChildProfileNotifier, ChildProfileState>((ref) {
  return ChildProfileNotifier(
    getChildProfileUseCase:
        ref.watch(getChildProfileUseCaseProvider),
  );
});
