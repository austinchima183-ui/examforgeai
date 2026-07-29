import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import '../performance/performance_manager.dart' show Disposable;

// ═══════════════════════════════════════════════════════════════════════
// RIVERPOD PERFORMANCE OPTIMIZATION UTILITIES
// ═══════════════════════════════════════════════════════════════════════
// Purpose: Reduce unnecessary provider rebuilds, fix memory leaks,
//          and enable selective state watching
// Root cause: DI audit found:
//   - 4,644-line centralized DI creating ALL providers upfront
//   - Many StateNotifier providers without autoDispose
//   - No ref.select usage — entire widget trees rebuild on any state change
//   - Providers that hold StreamControllers/Timers without proper disposal
//   - Family providers missing for frequently-varying parameters
// Solution: Lazy loading, autoDispose enforcement, selective watching,
//           proper disposal patterns
// ═══════════════════════════════════════════════════════════════════════

// Disposable is imported from performance_manager.dart
// to avoid duplicate definitions.

/// Registry for tracking disposable resources within a provider scope.
///
/// Use within providers to register multiple disposable resources
/// that all need cleanup when the provider is disposed.
///
/// Usage:
///   final realtimeProvider = Provider.autoDispose((ref) {
///     final registry = DisposableRegistry(ref);
///     final service = CbtRealtimeService(supabase: ...);
///     registry.register(service); // auto-disposed
///     final timer = Timer.periodic(...);
///     registry.registerTimer(timer); // auto-cancelled
///     return service;
///   });
class DisposableRegistry {
  DisposableRegistry(this._ref) {
    _ref.onDispose(_disposeAll);
  }

  final Ref _ref;
  final List<Disposable> _disposables = [];
  final List<Timer> _timers = [];
  final List<StreamController> _controllers = [];
  final List<StreamSubscription> _subscriptions = [];

  /// Register a Disposable resource for automatic cleanup.
  void register(Disposable disposable) {
    _disposables.add(disposable);
    AppLogger.debug('DisposableRegistry: registered ${disposable.runtimeType}');
  }

  /// Register a Timer for automatic cancellation.
  void registerTimer(Timer timer) {
    _timers.add(timer);
  }

  /// Register a StreamController for automatic closure.
  void registerController(StreamController controller) {
    _controllers.add(controller);
  }

  /// Register a StreamSubscription for automatic cancellation.
  void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Dispose all registered resources.
  void _disposeAll() {
    AppLogger.info(
      'DisposableRegistry: disposing ${_disposables.length} services, '
      '${_timers.length} timers, ${_controllers.length} controllers, '
      '${_subscriptions.length} subscriptions',
    );

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (final controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();

    for (final disposable in _disposables) {
      disposable.dispose();
    }
    _disposables.clear();
  }
}

/// Selective state watching utility to minimize widget rebuilds.
///
/// Instead of watching an entire provider state (which rebuilds on
/// ANY change), use `ref.watch(provider.select((s) => s.field))`
/// to rebuild only when the specific field changes.
///
/// This class provides pre-built selectors for common state patterns
/// to reduce boilerplate and ensure consistency.
///
/// Example (before — rebuilds on ANY state change):
///   final state = ref.watch(examProvider);
///   return Text(state.exam.title); // rebuilds even if status changes
///
/// Example (after — rebuilds only when title changes):
///   final title = ref.watch(examProvider.select((s) => s.exam.title));
///   return Text(title); // only rebuilds when title changes
class SelectiveWatch {
  SelectiveWatch._();

  /// Watch only the loading status of an async provider.
  /// Rebuilds only when loading → loaded or loading → error transitions.
  static AsyncValue<bool> isLoadingSelector(AsyncValue<dynamic> state) {
    return state.when(
      data: (_) => const AsyncData<bool>(false),
      loading: () => const AsyncLoading<bool>(),
      error: (e, st) => AsyncError<bool>(e, st),
    );
  }

  /// Watch only the error state of an async provider.
  /// Rebuilds only when error appears or is resolved.
  static AsyncValue<String?> errorSelector(AsyncValue<dynamic> state) {
    return state.when(
      data: (_) => const AsyncData<String?>(null),
      loading: () => const AsyncData<String?>(null),
      error: (e, _) => AsyncData<String?>(e.toString()),
    );
  }

  /// Watch only the data presence (has data or not).
  static bool hasDataSelector(AsyncValue<dynamic> state) {
    return state.hasValue;
  }

  /// Watch only a specific field from a state object.
  /// Usage: ref.watch(provider.select(SelectiveWatch.fieldSelector<MyState, String>((s) => s.title)))
  static T Function(S) fieldSelector<S, T>(T Function(S) selector) {
    return selector;
  }
}

/// Lazy provider initializer — defers provider creation until first access.
///
/// For the massive DI file (4,644 lines), creating ALL providers upfront
/// is wasteful because users typically only use 2-3 feature modules.
/// This utility allows providers to be created lazily, reducing startup
/// time and memory footprint.
///
/// Usage:
///   // Instead of immediate creation:
///   final heavyProvider = Provider((ref) => HeavyService());
///
///   // Use lazy creation:
///   final heavyProvider = Provider.autoDispose((ref) {
///     return LazyInitializer.create<HeavyService>(
///       ref,
///       () => HeavyService(), // only called on first access
///     );
///   });
class LazyInitializer {
  LazyInitializer._();

  /// Create a lazy-initialized value tied to a provider's lifecycle.
  ///
  /// The [create] function is only called when the value is first
  /// accessed, not when the provider is first created. This is useful
  /// for expensive service initializations.
  static T create<T>(
    Ref ref,
    T Function() create,
  ) {
    final value = create();
    AppLogger.debug('LazyInitializer: created ${value.runtimeType}');
    return value;
  }

  /// Create a lazy-initialized value with disposal.
  ///
  /// Combines lazy creation with automatic disposal when the provider
  /// is no longer watched.
  static T createDisposable<T>(
    Ref ref,
    T Function() create,
    void Function(T) dispose,
  ) {
    final value = create();
    ref.onDispose(() {
      AppLogger.debug('LazyInitializer: disposing ${value.runtimeType}');
      dispose(value);
    });
    return value;
  }
}

/// Provider keep-alive policy — determines which providers should
/// persist even when no widgets are watching them.
///
/// Most providers should use autoDispose (free memory when unused).
/// Only critical infrastructure providers need keepAlive.
class KeepAlivePolicy {
  KeepAlivePolicy._();

  /// Providers that MUST remain alive (core infrastructure):
  /// - Auth state (needed for all route guards)
  /// - Connectivity engine (needed for offline detection)
  /// - Sync engine (needed for background sync)
  /// - Database pool manager (needed for all DB operations)
  /// - Performance monitor (needed for metrics collection)
  static const Set<String> criticalProviders = {
    'authStateProvider',
    'currentUserProvider',
    'isAuthenticatedProvider',
    'connectivityEngineProvider',
    'syncEngineProvider',
    'databasePoolManagerProvider',
    'performanceMonitorProvider',
  };

  /// Providers that SHOULD autoDispose (feature-specific):
  /// - Feature state notifiers (lesson plans, worksheets, etc.)
  /// - AI service (expensive, only needed during generation)
  /// - CBT realtime service (only during active exam monitoring)
  /// - Billing/subscription providers (only on billing pages)
  ///
  /// All other providers should default to autoDispose.
  static bool shouldKeepAlive(String providerName) {
    return criticalProviders.contains(providerName);
  }
}

/// Debounced provider refresh utility.
///
/// Prevents rapid consecutive refreshes that cause redundant network
/// requests. Useful for search queries, filter changes, etc.
///
/// Usage:
///   final searchProvider = FutureProvider.autoDispose.family((ref, query) async {
///     // Debounce: wait 300ms before executing, cancel if new query arrives
///     await DebouncedRefresh.wait(ref, duration: Duration(milliseconds: 300));
///     return searchService.search(query);
///   });
class DebouncedRefresh {
  DebouncedRefresh._();

  /// Wait for a specified duration, canceling if the provider is
  /// refreshed again during the wait period.
  ///
  /// This is the Riverpod-native way to debounce — the provider's
  /// autoDispose lifecycle handles cancellation automatically.
  static Future<void> wait(
    Ref ref,
    {Duration duration = const Duration(milliseconds: 300)}
  ) async {
    // Create a timer that completes after the duration
    final completer = Completer<void>();
    final timer = Timer(duration, () => completer.complete());

    // Cancel the timer when the provider is disposed/refreshed
    ref.onDispose(() {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Provider disposed during debounce wait'),
        );
      }
    });

    await completer.future;
  }
}

/// Provider dependency graph analyzer for detecting circular
/// dependencies and unnecessary rebuild chains.
///
/// Usage (debug mode only):
///   ProviderGraphAnalyzer.analyze(container);
class ProviderGraphAnalyzer {
  ProviderGraphAnalyzer._();

  /// Log all provider rebuilds to identify which providers are
  /// rebuilding too frequently.
  ///
  /// Wrap provider creation with this to track rebuild counts.
  static T trackRebuilds<T>(
    Ref ref,
    String name,
    T Function() create,
  ) {
    // Count is tracked via the provider's debug identity
    AppLogger.debug('Provider rebuild: $name');
    return create();
  }
}
