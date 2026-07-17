import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the onboarding feature.
class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.pageCount = 3,
    this.isCompleting = false,
    this.isComplete = false,
  });

  /// The currently visible onboarding page index.
  final int currentPage;

  /// Total number of onboarding pages.
  final int pageCount;

  /// Whether the onboarding completion process is in progress.
  final bool isCompleting;

  /// Whether onboarding has been fully completed.
  final bool isComplete;

  /// Whether the user is on the last page.
  bool get isLastPage => currentPage >= pageCount - 1;

  /// Whether the user is on the first page.
  bool get isFirstPage => currentPage <= 0;

  /// Creates a copy of this state with the given fields replaced.
  OnboardingState copyWith({
    int? currentPage,
    int? pageCount,
    bool? isCompleting,
    bool? isComplete,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      pageCount: pageCount ?? this.pageCount,
      isCompleting: isCompleting ?? this.isCompleting,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the onboarding flow state.
///
/// Controls page navigation, skip action, and completion persistence.
/// On completion, the status is saved to [StorageService] so that
/// the onboarding guard can redirect the user appropriately on
/// subsequent app launches.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier({
    required Ref ref,
  })  : _ref = ref,
        super(const OnboardingState());

  final Ref _ref;

  // ─── Navigation ──────────────────────────────────────────────────

  /// Advances to the next page. If on the last page, completes onboarding.
  void nextPage() {
    if (state.isLastPage) {
      complete();
      return;
    }
    state = state.copyWith(currentPage: state.currentPage + 1);
    AppLogger.debug('Onboarding page: ${state.currentPage}');
  }

  /// Goes back to the previous page.
  void previousPage() {
    if (state.isFirstPage) return;
    state = state.copyWith(currentPage: state.currentPage - 1);
    AppLogger.debug('Onboarding page: ${state.currentPage}');
  }

  /// Jumps to a specific page by [pageIndex].
  void goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= state.pageCount) return;
    state = state.copyWith(currentPage: pageIndex);
    AppLogger.debug('Onboarding page: ${state.currentPage}');
  }

  /// Skips the onboarding flow entirely and marks it as complete.
  void skip() {
    AppLogger.info('Onboarding skipped');
    complete();
  }

  // ─── Completion ──────────────────────────────────────────────────

  /// Marks onboarding as complete and persists the flag to storage.
  ///
  /// This triggers the onboarding guard to redirect the user to
  /// the dashboard on the next navigation cycle.
  Future<void> complete() async {
    state = state.copyWith(isCompleting: true);

    try {
      final storageService = _ref.read(storageServiceProvider);
      await storageService.setOnboardingComplete(complete: true);

      state = state.copyWith(
        isCompleting: false,
        isComplete: true,
      );

      AppLogger.info('Onboarding completed successfully');
    } catch (e) {
      AppLogger.error('Failed to save onboarding completion', error: e);
      state = state.copyWith(isCompleting: false);
    }
  }

  // ─── Reset ───────────────────────────────────────────────────────

  /// Resets onboarding state (for debugging / testing).
  Future<void> reset() async {
    try {
      final storageService = _ref.read(storageServiceProvider);
      await storageService.setOnboardingComplete(complete: false);

      state = const OnboardingState();
      AppLogger.info('Onboarding state reset');
    } catch (e) {
      AppLogger.error('Failed to reset onboarding state', error: e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider that holds the current [OnboardingState].
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref: ref),
);

/// Convenience provider that watches the current page index.
final onboardingCurrentPageProvider = Provider<int>((ref) {
  return ref.watch(onboardingProvider).currentPage;
});

/// Convenience provider that watches whether onboarding is complete.
final onboardingIsCompleteProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isComplete;
});
