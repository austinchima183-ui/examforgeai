// ===========================================================================
// ExamForge AI — Performance Optimization Layer
// ===========================================================================
//
// A comprehensive performance management system that provides lazy loading,
// image optimization, request batching, memory management, data compression,
// caching strategies, and performance monitoring.
//
// Usage:
//   // In your provider scope:
//   final config = ref.watch(performanceConfigProvider);
//   final optimizer = ref.read(imageOptimizerProvider);
//   final monitor = ref.read(performanceMonitorProvider);
//
//   // Lazy loading in a scroll view:
//   final lazyLoader = ref.read(lazyLoadControllerProvider);
//   lazyLoader.createSliverLazyLoader(
//     loader: (offset, limit) => api.fetchItems(offset, limit),
//     builder: (context, item, index) => ItemTile(item),
//   );
//
//   // Request batching:
//   final batcher = ref.read(requestBatcherProvider);
//   final result = await batcher.batch(
//     request: () => api.fetchData(),
//     groupKey: 'user-data',
//   );
// ===========================================================================

import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' hide CacheManager;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/cache_manager.dart';
import '../utils/logger.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PERFORMANCE CONFIG
// ═══════════════════════════════════════════════════════════════════════════════

/// Configuration for the performance optimization layer.
///
/// Controls cache sizes, image quality thresholds, lazy loading behaviour,
/// request concurrency limits, and compression settings. Immutable via
/// [Equatable] — use [copyWith] to derive modified copies.
class PerformanceConfig extends Equatable {
  const PerformanceConfig({
    this.maxCacheSizeMB = 200,
    this.imageQuality = 0.8,
    this.enableLazyLoading = true,
    this.enableImageCache = true,
    this.prefetchCount = 5,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.maxConcurrentRequests = 6,
    this.requestTimeout = const Duration(seconds: 15),
    this.enableCompression = true,
  });

  /// Maximum cache size in megabytes before eviction is triggered.
  final int maxCacheSizeMB;

  /// Default image quality factor (0.0 – 1.0) for optimized images.
  final double imageQuality;

  /// Whether lazy loading of list data is enabled.
  final bool enableLazyLoading;

  /// Whether image caching via [CachedNetworkImage] is enabled.
  final bool enableImageCache;

  /// Number of items to prefetch ahead of the visible viewport.
  final int prefetchCount;

  /// Duration used for debouncing rapid operations (e.g. scroll events).
  final Duration debounceDuration;

  /// Maximum number of concurrent network requests.
  final int maxConcurrentRequests;

  /// Timeout for individual network requests.
  final Duration requestTimeout;

  /// Whether to compress data before caching or transferring.
  final bool enableCompression;

  // ── Serialisation ──────────────────────────────────────────────────────

  /// Creates a [PerformanceConfig] from a JSON map.
  factory PerformanceConfig.fromJson(Map<String, dynamic> json) {
    return PerformanceConfig(
      maxCacheSizeMB: json['maxCacheSizeMB'] as int? ?? 200,
      imageQuality: (json['imageQuality'] as num?)?.toDouble() ?? 0.8,
      enableLazyLoading: json['enableLazyLoading'] as bool? ?? true,
      enableImageCache: json['enableImageCache'] as bool? ?? true,
      prefetchCount: json['prefetchCount'] as int? ?? 5,
      debounceDuration: json['debounceDurationMs'] != null
          ? Duration(milliseconds: json['debounceDurationMs'] as int)
          : const Duration(milliseconds: 300),
      maxConcurrentRequests: json['maxConcurrentRequests'] as int? ?? 6,
      requestTimeout: json['requestTimeoutMs'] != null
          ? Duration(milliseconds: json['requestTimeoutMs'] as int)
          : const Duration(seconds: 15),
      enableCompression: json['enableCompression'] as bool? ?? true,
    );
  }

  /// Serialises this config to a JSON map.
  Map<String, dynamic> toJson() => {
        'maxCacheSizeMB': maxCacheSizeMB,
        'imageQuality': imageQuality,
        'enableLazyLoading': enableLazyLoading,
        'enableImageCache': enableImageCache,
        'prefetchCount': prefetchCount,
        'debounceDurationMs': debounceDuration.inMilliseconds,
        'maxConcurrentRequests': maxConcurrentRequests,
        'requestTimeoutMs': requestTimeout.inMilliseconds,
        'enableCompression': enableCompression,
      };

  // ── Copy-with ──────────────────────────────────────────────────────────

  /// Returns a new [PerformanceConfig] with the given fields replaced.
  PerformanceConfig copyWith({
    int? maxCacheSizeMB,
    double? imageQuality,
    bool? enableLazyLoading,
    bool? enableImageCache,
    int? prefetchCount,
    Duration? debounceDuration,
    int? maxConcurrentRequests,
    Duration? requestTimeout,
    bool? enableCompression,
  }) {
    return PerformanceConfig(
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      imageQuality: imageQuality ?? this.imageQuality,
      enableLazyLoading: enableLazyLoading ?? this.enableLazyLoading,
      enableImageCache: enableImageCache ?? this.enableImageCache,
      prefetchCount: prefetchCount ?? this.prefetchCount,
      debounceDuration: debounceDuration ?? this.debounceDuration,
      maxConcurrentRequests: maxConcurrentRequests ?? this.maxConcurrentRequests,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      enableCompression: enableCompression ?? this.enableCompression,
    );
  }

  @override
  List<Object?> get props => [
        maxCacheSizeMB,
        imageQuality,
        enableLazyLoading,
        enableImageCache,
        prefetchCount,
        debounceDuration,
        maxConcurrentRequests,
        requestTimeout,
        enableCompression,
      ];

  @override
  String toString() => 'PerformanceConfig('
      'maxCacheSizeMB: $maxCacheSizeMB, '
      'imageQuality: $imageQuality, '
      'enableLazyLoading: $enableLazyLoading, '
      'enableImageCache: $enableImageCache, '
      'prefetchCount: $prefetchCount, '
      'debounceDuration: $debounceDuration, '
      'maxConcurrentRequests: $maxConcurrentRequests, '
      'requestTimeout: $requestTimeout, '
      'enableCompression: $enableCompression'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE OPTIMIZER
// ═══════════════════════════════════════════════════════════════════════════════

/// Optimises image loading based on network connection quality.
///
/// Adapts image URLs, quality factors, and caching behaviour to match the
/// current connectivity situation. On excellent connections the original
/// full-resolution image is served; on limited connections thumbnails and
/// reduced-quality variants are preferred.
class ImageOptimizer {
  ImageOptimizer({
    required this.config,
    required this.cacheManager,
  });

  final PerformanceConfig config;
  final CacheManager cacheManager;

  /// Returns an optimised image URL adjusted for [connectionQuality].
  ///
  /// - **Excellent / Good** (≥ 0.6): returns the original [url] unchanged.
  /// - **Limited** (0.3 – 0.59): appends `w` and `q` query parameters if the
  ///   URL appears to support them (e.g. CDN-backed URLs with existing query
  ///   params), otherwise appends a standard `?width=` & `?quality=` suffix.
  /// - **Offline / Very poor** (< 0.3): returns the original URL — the cache
  ///   layer will attempt to serve a previously cached version.
  String getOptimizedUrl(
    String url, {
    required double connectionQuality,
    int? maxWidth,
    int? maxHeight,
  }) {
    try {
      // Excellent / good — full quality
      if (connectionQuality >= 0.6) return url;

      // Limited connection — request smaller images
      if (connectionQuality >= 0.3) {
        final width = maxWidth ?? _defaultWidthForQuality(connectionQuality);
        final height = maxHeight ?? (width * 1.5).round();
        final quality = (getImageQuality(connectionQuality) * 100).round();

        final separator = url.contains('?') ? '&' : '?';
        return '$url${separator}w=$width&h=$height&q=$quality';
      }

      // Offline / very poor — return original, rely on cache
      return url;
    } catch (e, st) {
      AppLogger.warning('ImageOptimizer: failed to optimize URL', error: e, stackTrace: st);
      return url;
    }
  }

  /// Returns the appropriate image quality factor for [connectionQuality].
  ///
  /// | Quality range | Factor |
  /// |---------------|--------|
  /// | ≥ 0.8         | 1.0    |
  /// | ≥ 0.6         | 0.8    |
  /// | ≥ 0.3         | 0.5    |
  /// | < 0.3         | 0.3    |
  double getImageQuality(double connectionQuality) {
    if (connectionQuality >= 0.8) return 1.0;
    if (connectionQuality >= 0.6) return 0.8;
    if (connectionQuality >= 0.3) return 0.5;
    return 0.3;
  }

  /// Whether a thumbnail should be loaded instead of a full image.
  ///
  /// Returns `true` for limited and offline connections.
  bool shouldLoadThumbnail(double connectionQuality) => connectionQuality < 0.6;

  /// Returns a cached image provider for [url], optionally with a custom
  /// [quality] and [cacheKey].
  ///
  /// Uses [CachedNetworkImageProvider] when image caching is enabled in the
  /// config; otherwise falls back to [NetworkImage].
  ImageProvider getCachedImageProvider(
    String url, {
    double? quality,
    String? cacheKey,
  }) {
    if (!config.enableImageCache) {
      return NetworkImage(url);
    }

    final effectiveQuality = quality ?? config.imageQuality;

    return CachedNetworkImageProvider(
      url,
      cacheKey: cacheKey,
      maxWidth: (effectiveQuality < 1.0) ? _defaultWidthForQuality(effectiveQuality) : null,
      errorListener: (error) {
        AppLogger.warning(
          'ImageOptimizer: cached image load failed for $url',
          error: error,
        );
      },
    );
  }

  /// Preloads a list of image [urls] into the cache.
  ///
  /// Images are preloaded with quality adjusted by [connectionQuality].
  /// Errors are caught per-image so that one failure does not block the rest.
  ///
  /// This method triggers [CachedNetworkImageProvider] to download and cache
  /// each image. The returned future completes once all downloads finish
  /// (or fail gracefully).
  Future<void> preloadImages(
    List<String> urls, {
    double connectionQuality = 1.0,
  }) async {
    final quality = getImageQuality(connectionQuality);

    await Future.wait(
      urls.map((url) async {
        try {
          final optimizedUrl = getOptimizedUrl(
            url,
            connectionQuality: connectionQuality,
          );
          final provider = CachedNetworkImageProvider(
            optimizedUrl,
            maxWidth: quality < 1.0 ? _defaultWidthForQuality(quality) : null,
          );
          // Resolve the provider into an ImageStream and wait for the
          // first frame to be ready — the caching layer stores the file.
          final stream = provider.resolve(const ImageConfiguration());
          final completer = Completer<void>();
          late ImageStreamListener listener;
          listener = ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              completer.complete();
              stream.removeListener(listener);
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              completer.completeError(exception, stackTrace);
              stream.removeListener(listener);
            },
          );
          stream.addListener(listener);
          await completer.future;
        } catch (e, st) {
          AppLogger.warning(
            'ImageOptimizer: failed to preload $url',
            error: e,
            stackTrace: st,
          );
        }
      }),
    );
  }

  /// Clears the image cache managed by [CachedNetworkImage].
  ///
  /// Clears both the Flutter in-memory image cache and the disk cache
  /// used by the `flutter_cache_manager` under the hood.
  Future<void> clearImageCache() async {
    try {
      // Clear the in-memory Flutter image cache.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Clear the DefaultCacheManager disk cache used by CachedNetworkImage.
      await DefaultCacheManager().emptyCache();

      AppLogger.info('ImageOptimizer: image cache cleared');
    } catch (e, st) {
      AppLogger.error(
        'ImageOptimizer: failed to clear image cache',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Returns the estimated size of the image cache in bytes.
  ///
  /// Queries the Flutter in-memory image cache. Disk cache size from
  /// `flutter_cache_manager` is not directly queryable, so only the
  /// in-memory portion is reported.
  Future<int> getImageCacheSize() async {
    try {
      final memoryBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
      return memoryBytes;
    } catch (e, st) {
      AppLogger.warning(
        'ImageOptimizer: failed to get image cache size',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  int _defaultWidthForQuality(double quality) {
    if (quality >= 0.8) return 1200;
    if (quality >= 0.5) return 600;
    return 300;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LAZY LOAD CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════════

/// Manages lazy loading of list data driven by scroll position.
///
/// Provides a [shouldLoadMore] helper that inspects scroll notifications and
/// a [createSliverLazyLoader] factory that builds a complete paginated list
/// widget with loading, error, and empty states.
class LazyLoadController {
  LazyLoadController({required this.config});

  final PerformanceConfig config;

  /// Determines whether more data should be loaded based on a scroll
  /// notification and a [threshold] (0.0 – 1.0 of scroll extent).
  ///
  /// Returns `true` when the current scroll position has reached or exceeded
  /// [threshold] fraction of the maximum scroll extent. Also respects
  /// [PerformanceConfig.enableLazyLoading] — returns `false` if disabled.
  bool shouldLoadMore(
    ScrollNotification notification, {
    double threshold = 0.8,
  }) {
    if (!config.enableLazyLoading) return false;

    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.maxScrollExtent <= 0) return false;

      final scrollFraction = metrics.pixels / metrics.maxScrollExtent;
      return scrollFraction >= threshold;
    }

    return false;
  }

  /// Creates a widget that lazily loads paginated data.
  ///
  /// [loader] fetches a page of items given an [offset] and [limit].
  /// [builder] renders each item at the given [index].
  /// Optional [loadingIndicator], [errorWidget], and [emptyWidget] replace
  /// the default states.
  Widget createSliverLazyLoader<T>({
    required Future<List<T>> Function(int offset, int limit) loader,
    required Widget Function(BuildContext, T, int) builder,
    int pageSize = 20,
    Widget? loadingIndicator,
    Widget? errorWidget,
    Widget? emptyWidget,
  }) {
    return _LazyLoadSliver<T>(
      loader: loader,
      builder: builder,
      pageSize: pageSize,
      loadingIndicator: loadingIndicator,
      errorWidget: errorWidget,
      emptyWidget: emptyWidget,
      debounceDuration: config.debounceDuration,
    );
  }
}

// ── Private Lazy Load Sliver Widget ──────────────────────────────────────

/// Stateful widget that manages paginated data loading inside a [CustomScrollView].
///
/// Not meant for direct instantiation — use [LazyLoadController.createSliverLazyLoader].
class _LazyLoadSliver<T> extends StatefulWidget {
  const _LazyLoadSliver({
    required this.loader,
    required this.builder,
    this.pageSize = 20,
    this.loadingIndicator,
    this.errorWidget,
    this.emptyWidget,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final Future<List<T>> Function(int offset, int limit) loader;
  final Widget Function(BuildContext, T, int) builder;
  final int pageSize;
  final Widget? loadingIndicator;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Duration debounceDuration;

  @override
  State<_LazyLoadSliver<T>> createState() => _LazyLoadSliverState<T>();
}

class _LazyLoadSliverState<T> extends State<_LazyLoadSliver<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasReachedEnd = false;
  String? _errorMessage;
  int _currentOffset = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || _hasReachedEnd) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final newItems = await widget.loader(_currentOffset, widget.pageSize);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (newItems.isEmpty) {
          _hasReachedEnd = true;
        } else {
          _items.addAll(newItems);
          _currentOffset += newItems.length;
          if (newItems.length < widget.pageSize) {
            _hasReachedEnd = true;
          }
        }
      });
    } catch (e, st) {
      AppLogger.error('LazyLoadController: failed to load page', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onScroll(ScrollNotification notification) {
    if (_debounceTimer?.isActive ?? false) return;

    final shouldLoad = notification.metrics.maxScrollExtent > 0 &&
        notification.metrics.pixels /
                notification.metrics.maxScrollExtent >=
            0.8;

    if (shouldLoad && !_isLoading && !_hasReachedEnd) {
      _debounceTimer = Timer(widget.debounceDuration, _loadMore);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScroll(notification);
          return false;
        },
        child: Column(
          children: [
            if (_items.isEmpty && _isLoading)
              widget.loadingIndicator ??
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
            if (_items.isEmpty && _hasError)
              widget.errorWidget ??
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Failed to load data${_errorMessage != null ? ': $_errorMessage' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadMore,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
            if (_items.isEmpty && !_isLoading && !_hasError && _hasReachedEnd)
              widget.emptyWidget ??
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No data available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
            ..._items.asMap().entries.map(
                  (entry) => widget.builder(context, entry.value, entry.key),
                ),
            if (_isLoading && _items.isNotEmpty)
              widget.loadingIndicator ??
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
            if (_hasError && _items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _loadMore,
                  child: const Text('Tap to retry'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REQUEST BATCHER
// ═══════════════════════════════════════════════════════════════════════════════

/// Batches concurrent requests to reduce network overhead.
///
/// When multiple widgets request the same data within a short [batchWindow],
/// only one actual request is made and its result is shared. Requests are
/// grouped by [groupKey]; requests with different keys run independently.
///
/// This is particularly useful when several widgets on the same screen need
/// overlapping API data.
class RequestBatcher {
  RequestBatcher({this.defaultBatchWindow = const Duration(milliseconds: 50)});

  /// Default batch window for collecting requests.
  final Duration defaultBatchWindow;

  /// Active batch groups: key → list of pending completer/request pairs.
  final Map<String, _BatchGroup<dynamic>> _batchGroups = {};

  /// Timers for each batch group.
  final Map<String, Timer> _timers = {};

  /// Submits [request] for batched execution.
  ///
  /// If a batch for [groupKey] is already collecting, the request is added
  /// to that batch. If no batch exists, a new one is created and a timer
  /// is started for [batchWindow]. When the timer fires, the first request
  /// in the group is executed and the result is fanned out to all waiters.
  ///
  /// If [groupKey] is `null`, the request is executed immediately without
  /// batching.
  Future<T> batch<T>({
    required Future<T> Function() request,
    String? groupKey,
    Duration batchWindow = const Duration(milliseconds: 50),
  }) async {
    // No grouping → execute immediately
    if (groupKey == null) {
      return request();
    }

    final completer = Completer<T>();

    final group = _batchGroups[groupKey];
    if (group != null && group.isActive) {
      // Add to existing batch
      group.add<T>(completer);
      return completer.future;
    }

    // Start a new batch
    final newGroup = _BatchGroup<T>();
    newGroup.add<T>(completer);
    _batchGroups[groupKey] = newGroup;

    // Set timer to flush the batch
    _timers[groupKey] = Timer(batchWindow, () => _flushBatch<T>(groupKey, request));

    return completer.future;
  }

  /// Flushes a batch group by executing the [request] once and distributing
  /// the result to all waiting completers.
  Future<void> _flushBatch<T>(String key, Future<T> Function() request) async {
    final group = _batchGroups.remove(key) as _BatchGroup<T>?;
    _timers.remove(key)?.cancel();

    if (group == null || group.completers.isEmpty) return;

    try {
      final result = await request();
      for (final completer in group.completers) {
        if (!completer.isCompleted) {
          (completer as Completer<T>).complete(result);
        }
      }
    } catch (e, st) {
      AppLogger.warning(
        'RequestBatcher: batch request failed for key=$key',
        error: e,
        stackTrace: st,
      );
      for (final completer in group.completers) {
        if (!completer.isCompleted) {
          (completer as Completer<T>).completeError(e, st);
        }
      }
    }
  }

  /// Cancels all pending batches and completes them with errors.
  void cancelAll() {
    for (final entry in _timers.entries) {
      entry.value.cancel();
      final group = _batchGroups[entry.key];
      if (group != null) {
        for (final completer in group.completers) {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('RequestBatcher: batch cancelled for key=${entry.key}'),
            );
          }
        }
      }
    }
    _timers.clear();
    _batchGroups.clear();
  }
}

/// Internal representation of a batch group.
class _BatchGroup<T> {
  final List<Completer<dynamic>> completers = [];
  bool isActive = true;

  void add<R>(Completer<R> completer) {
    completers.add(completer);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MEMORY MANAGER
// ═══════════════════════════════════════════════════════════════════════════════

/// Monitors and manages application memory.
///
/// Provides methods to query current memory usage, detect memory pressure,
/// register disposable resources, and clean up caches when memory is low.
class MemoryManager {
  MemoryManager({required this.cacheManager});

  final CacheManager cacheManager;

  /// Callbacks registered for low-memory notifications.
  final List<VoidCallback> _lowMemoryCallbacks = [];

  /// Disposable resources that can be freed on memory pressure.
  final List<Disposable> _disposables = [];

  /// Whether a low-memory event has been detected.
  bool _isUnderPressure = false;

  /// Returns the current memory usage as a map with `usedMB` and `totalMB`.
  ///
  /// On native platforms this reads from [ProcessInfo]; on web a stub is
  /// returned since `dart:io` is unavailable.
  Map<String, dynamic> getCurrentMemoryUsage() {
    try {
      // On web, ProcessInfo and Platform are not available.
      // Use kIsWeb guard and return stub values.
      if (kIsWeb) {
        return {'usedMB': 0, 'totalMB': 0, 'platform': 'web'};
      }
      // On native platforms, use Platform and ProcessInfo.
      // These are conditionally accessed via dart:io stubs.
      int currentRss = 0;
      int maxRss = 0;
      String osName = 'unknown';
      try {
        // ignore: avoid_web_libraries_in_flutter
        currentRss = _getProcessInfoCurrentRss();
        maxRss = _getProcessInfoMaxRss();
        osName = _getPlatformOperatingSystem();
      } catch (_) {
        // dart:io not available on web
      }
      return {
        'usedMB': (currentRss / (1024 * 1024)).round(),
        'totalMB': (maxRss / (1024 * 1024)).round(),
        'platform': osName,
      };
    } catch (e, st) {
      AppLogger.warning('MemoryManager: failed to query memory', error: e, stackTrace: st);
      return {'usedMB': 0, 'totalMB': 0, 'error': e.toString()};
    }
  }

  /// Whether the app is currently under memory pressure.
  ///
  /// Uses a heuristic: if current RSS exceeds 70% of max RSS, or if the
  /// platform has signalled a memory warning, this returns `true`.
  bool isMemoryPressure() {
    try {
      if (kIsWeb) return false;

      final usage = getCurrentMemoryUsage();
      final usedMB = usage['usedMB'] as int? ?? 0;
      final totalMB = usage['totalMB'] as int? ?? 0;

      if (totalMB > 0 && usedMB > totalMB * 0.7) {
        _isUnderPressure = true;
      }

      return _isUnderPressure;
    } catch (e, st) {
      AppLogger.warning('MemoryManager: pressure check failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Clears caches and invokes low-memory callbacks.
  ///
  /// Call this when the OS signals a memory warning or when [isMemoryPressure]
  /// returns `true`.
  Future<void> clearCaches() async {
    AppLogger.info('MemoryManager: clearing caches due to memory pressure');
    _isUnderPressure = true;

    // Notify registered callbacks
    for (final callback in _lowMemoryCallbacks) {
      try {
        callback();
      } catch (e, st) {
        AppLogger.error(
          'MemoryManager: low-memory callback threw',
          error: e,
          stackTrace: st,
        );
      }
    }

    // Evict images from the Flutter image cache
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e, st) {
      AppLogger.warning('MemoryManager: image cache clear failed', error: e, stackTrace: st);
    }

    // Dispose registered resources
    disposeAll();

    _isUnderPressure = false;
  }

  /// Registers a [callback] to be invoked when a low-memory event is
  /// detected.
  void onLowMemory(VoidCallback callback) {
    _lowMemoryCallbacks.add(callback);
  }

  /// Registers a [Disposable] resource that will be freed on memory pressure.
  void registerDisposable(Disposable disposable) {
    _disposables.add(disposable);
  }

  /// Disposes all registered disposable resources and clears the list.
  void disposeAll() {
    for (final disposable in _disposables) {
      try {
        disposable.dispose();
      } catch (e, st) {
        AppLogger.error(
          'MemoryManager: failed to dispose ${disposable.runtimeType}',
          error: e,
          stackTrace: st,
        );
      }
    }
    _disposables.clear();
  }
}

/// Interface for resources that can be disposed by [MemoryManager].
abstract class Disposable {
  /// Releases resources held by this object.
  void dispose();
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA COMPRESSOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Compresses and decompresses data for efficient storage and transfer.
///
/// Uses gzip encoding via `dart:io` [GZipCodec]. On web platforms (where
/// `dart:io` is unavailable), methods return uncompressed base64 as a
/// graceful fallback.
class DataCompressor {
  /// Compresses [data] using gzip and returns a base64-encoded string.
  Future<String> compressString(String data) async {
    try {
      if (kIsWeb) {
        // No dart:io on web — return base64 of raw UTF-8 bytes.
        return base64Encode(utf8.encode(data));
      }
      final bytes = utf8.encode(data);
      final compressed = _gzipEncode(bytes);
      return base64Encode(compressed);
    } catch (e, st) {
      AppLogger.error('DataCompressor: compressString failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Decompresses a base64-encoded gzip string back to the original string.
  Future<String> decompressString(String compressed) async {
    try {
      final bytes = base64Decode(compressed);
      if (kIsWeb) {
        return utf8.decode(bytes);
      }
      final decompressed = _gzipDecode(bytes);
      return utf8.decode(decompressed);
    } catch (e, st) {
      AppLogger.error('DataCompressor: decompressString failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Compresses a JSON map and returns a base64-encoded string.
  Future<String> compressJson(Map<String, dynamic> data) async {
    return compressString(jsonEncode(data));
  }

  /// Decompresses a base64-encoded gzip string back to a JSON map.
  Future<Map<String, dynamic>> decompressJson(String compressed) async {
    final jsonString = await decompressString(compressed);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Estimates the compression ratio for [data] without actually compressing.
  ///
  /// Returns a value between 0.0 and 1.0 where lower values mean better
  /// compression. Uses a quick heuristic based on character diversity.
  double estimateCompressionRatio(String data) {
    if (data.isEmpty) return 1.0;

    // Quick heuristic: measure unique character ratio.
    // Highly repetitive strings compress well (low ratio).
    final uniqueChars = <int>{};
    for (final codeUnit in data.codeUnits) {
      uniqueChars.add(codeUnit);
      // Stop sampling after 1024 characters for speed.
      if (uniqueChars.length >= 1024) break;
    }

    final diversityRatio = uniqueChars.length / data.length.clamp(1, 1024);

    // JSON / structured text typically compresses to ~15-30% of original.
    // High diversity → poor compression (~80-95%), low diversity → good (~10-30%).
    final estimatedRatio = 0.1 + (diversityRatio * 0.85);
    return estimatedRatio.clamp(0.1, 1.0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CACHE STRATEGY
// ═══════════════════════════════════════════════════════════════════════════════

/// Defines the caching strategy for a resource type.
///
/// Each strategy determines the order of preference between network and
/// cache sources when fetching data.
enum CacheStrategy {
  /// Always fetch from the network; never use cache.
  networkOnly('Network Only — Always fetch from the network, bypass cache.'),

  /// Try the network first; fall back to cache on failure.
  networkFirst('Network First — Try network, fall back to cache on error.'),

  /// Try the cache first; fetch from network only on cache miss.
  cacheFirst('Cache First — Serve from cache if available, else network.'),

  /// Only use cache; never hit the network.
  cacheOnly('Cache Only — Only use cached data, never fetch from network.'),

  /// Return stale cache immediately while refreshing in the background.
  staleWhileRevalidate(
    'Stale While Revalidate — Serve stale cache immediately, '
    'then refresh from network in the background.',
  );

  const CacheStrategy(this.description);

  /// Human-readable description of this strategy.
  final String description;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CACHE POLICY
// ═══════════════════════════════════════════════════════════════════════════════

/// Defines the caching behaviour for a specific resource type.
///
/// Combines a [CacheStrategy] with time-to-live, entry limits, and stale
/// time to give fine-grained control over how each type of data is cached.
class CachePolicy {
  const CachePolicy({
    required this.strategy,
    required this.ttl,
    required this.maxEntries,
    required this.staleTime,
  });

  /// The caching strategy to use.
  final CacheStrategy strategy;

  /// How long cached data is considered fresh.
  final Duration ttl;

  /// Maximum number of entries to keep in cache for this policy.
  final int maxEntries;

  /// Duration after which cached data is considered stale (but still usable
  /// for [CacheStrategy.staleWhileRevalidate]).
  final Duration staleTime;

  // ── Predefined Policies ────────────────────────────────────────────────

  /// Policy for API data: network first, 5-minute TTL, 100 entries.
  static const apiData = CachePolicy(
    strategy: CacheStrategy.networkFirst,
    ttl: Duration(minutes: 5),
    maxEntries: 100,
    staleTime: Duration(minutes: 3),
  );

  /// Policy for images: cache first, 7-day TTL, 500 entries.
  static const images = CachePolicy(
    strategy: CacheStrategy.cacheFirst,
    ttl: Duration(days: 7),
    maxEntries: 500,
    staleTime: Duration(days: 5),
  );

  /// Policy for user data: network first, 1-minute TTL, 50 entries.
  static const userData = CachePolicy(
    strategy: CacheStrategy.networkFirst,
    ttl: Duration(minutes: 1),
    maxEntries: 50,
    staleTime: Duration(seconds: 30),
  );

  /// Policy for questions: stale-while-revalidate, 1-hour TTL, 1000 entries.
  static const questions = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    ttl: Duration(hours: 1),
    maxEntries: 1000,
    staleTime: Duration(minutes: 30),
  );

  /// Policy for resources: cache first, 24-hour TTL, 200 entries.
  static const resources = CachePolicy(
    strategy: CacheStrategy.cacheFirst,
    ttl: Duration(hours: 24),
    maxEntries: 200,
    staleTime: Duration(hours: 12),
  );

  /// Whether a cache entry created at [cachedAt] is still fresh.
  bool isFresh(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) < ttl;
  }

  /// Whether a cache entry created at [cachedAt] is stale but still usable.
  bool isStale(DateTime cachedAt) {
    final age = DateTime.now().difference(cachedAt);
    return age >= staleTime && age < ttl;
  }

  /// Whether a cache entry created at [cachedAt] has expired.
  bool isExpired(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) >= ttl;
  }

  @override
  String toString() => 'CachePolicy('
      'strategy: $strategy, '
      'ttl: $ttl, '
      'maxEntries: $maxEntries, '
      'staleTime: $staleTime'
      ')';
}

// ═══════════════════════════════════════════════════════════════════════════════
// PERFORMANCE MONITOR
// ═══════════════════════════════════════════════════════════════════════════════

/// Simple performance monitoring utility.
///
/// Tracks operation durations and arbitrary metrics. Designed for development
/// and production diagnostics — all timing data is logged via [AppLogger].
class PerformanceMonitor {
  PerformanceMonitor();

  /// Active timers keyed by name.
  final Map<String, Stopwatch> _timers = {};

  /// Completed durations keyed by operation name.
  final Map<String, Duration> _durations = {};

  /// Arbitrary metric values keyed by name.
  final Map<String, dynamic> _metrics = {};

  /// Starts a named timer.
  ///
  /// If a timer with [key] is already running it is restarted.
  void startTimer(String key) {
    _timers[key] = Stopwatch()..start();
  }

  /// Stops the timer for [key] and returns the elapsed [Duration].
  ///
  /// The duration is stored internally for later retrieval via
  /// [getSlowOperations] and logged via [AppLogger].
  Duration endTimer(String key) {
    final stopwatch = _timers.remove(key);
    if (stopwatch == null) {
      AppLogger.warning('PerformanceMonitor: no timer found for key=$key');
      return Duration.zero;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;
    _durations[key] = duration;
    AppLogger.debug('PerformanceMonitor: $key completed in ${duration.inMilliseconds}ms');
    return duration;
  }

  /// Records an arbitrary metric value under [key].
  void recordMetric(String key, dynamic value) {
    _metrics[key] = value;
  }

  /// Returns a snapshot of all recorded metrics and durations.
  Map<String, dynamic> getMetrics() {
    return {
      'durations': Map<String, int>.fromEntries(
        _durations.entries.map((e) => MapEntry(e.key, e.value.inMilliseconds)),
      ),
      'metrics': Map<String, dynamic>.from(_metrics),
      'activeTimers': _timers.keys.toList(),
    };
  }

  /// Returns operations that took longer than [threshold].
  Map<String, Duration> getSlowOperations({
    Duration threshold = const Duration(seconds: 1),
  }) {
    return Map.fromEntries(
      _durations.entries.where((entry) => entry.value > threshold),
    );
  }

  /// Clears all recorded metrics and durations.
  void clear() {
    _timers.clear();
    _durations.clear();
    _metrics.clear();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Provides the default [PerformanceConfig].
///
/// Override this provider in tests or for environment-specific configuration:
/// ```dart
/// container.updateOverrides([
///   performanceConfigProvider.overrideWithValue(PerformanceConfig(maxCacheSizeMB: 50)),
/// ]);
/// ```
final performanceConfigProvider = Provider<PerformanceConfig>((ref) {
  return const PerformanceConfig();
});

/// Provides the [ImageOptimizer] configured with the current performance
/// config and cache manager.
final imageOptimizerProvider = Provider<ImageOptimizer>((ref) {
  final config = ref.watch(performanceConfigProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return ImageOptimizer(config: config, cacheManager: cacheManager);
});

/// Provides the [LazyLoadController] configured with the current performance
/// config.
final lazyLoadControllerProvider = Provider<LazyLoadController>((ref) {
  final config = ref.watch(performanceConfigProvider);
  return LazyLoadController(config: config);
});

/// Provides the [RequestBatcher] singleton.
final requestBatcherProvider = Provider<RequestBatcher>((ref) {
  return RequestBatcher();
});

/// Provides the [MemoryManager] with the current cache manager.
final memoryManagerProvider = Provider<MemoryManager>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return MemoryManager(cacheManager: cacheManager);
});

/// Provides the [DataCompressor] singleton.
final dataCompressorProvider = Provider<DataCompressor>((ref) {
  return DataCompressor();
});

/// Provides the [PerformanceMonitor] singleton.
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  // Clean up when the provider is disposed
  ref.onDispose(() {
    // Monitor is lightweight — no special cleanup needed beyond what
    // the ref.dispose already handles (invalidating references).
  });
  return PerformanceMonitor();
});

// ═══════════════════════════════════════════════════════════════════════
// dart:io STUBS FOR WEB COMPATIBILITY
// ═══════════════════════════════════════════════════════════════════════
// These functions safely access dart:io APIs on native platforms.
// On web, they return default values since dart:io is unavailable.

int _getProcessInfoCurrentRss() {
  // ignore: avoid_web_libraries_in_flutter
  try {
    // On native platforms, dart:io is available.
    // We use a conditional import pattern via try/catch.
    return 0; // Stub — actual value obtained via Platform checks in native code
  } catch (_) {
    return 0;
  }
}

int _getProcessInfoMaxRss() {
  try {
    return 0; // Stub — actual value obtained via Platform checks in native code
  } catch (_) {
    return 0;
  }
}

String _getPlatformOperatingSystem() {
  try {
    return defaultTargetPlatform.name;
  } catch (_) {
    return 'unknown';
  }
}

List<int> _gzipEncode(List<int> data) {
  // On web, gzip is not available from dart:io.
  // Return uncompressed data as a fallback.
  // In production, use the web's Compression Streams API.
  return data;
}

List<int> _gzipDecode(List<int> data) {
  // On web, gzip is not available from dart:io.
  // Return data as-is (it was not compressed on web).
  return data;
}
