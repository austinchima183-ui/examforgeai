import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/results_entities.dart';
import '../providers/results_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESULTS ENGINE — PAGE-LEVEL RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════
// These StateNotifierProvider definitions are placeholders that must be
// overridden in the app's ProviderScope (typically via dependency_injection.dart)
// once the use-case providers are wired up.
// ═══════════════════════════════════════════════════════════════════════

/// Provider for [StudentResultsNotifier].
///
/// Used by student-facing pages (StudentResultsPage, TopicMasteryPage).
final studentResultsProvider =
    StateNotifierProvider<StudentResultsNotifier, StudentResultsState>(
  (ref) {
    // TODO: Wire up with actual use-case providers from dependency_injection.dart
    throw UnimplementedError(
      'studentResultsProvider must be overridden in the ProviderScope',
    );
  },
);

/// Provider for [AnalyticsNotifier].
///
/// Used by admin-facing analytics dashboard page.
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) {
    // TODO: Wire up with actual use-case providers from dependency_injection.dart
    throw UnimplementedError(
      'analyticsProvider must be overridden in the ProviderScope',
    );
  },
);

/// Provider for [ReportExportNotifier].
///
/// Used by admin-facing reports page.
final reportExportProvider =
    StateNotifierProvider<ReportExportNotifier, ReportExportState>(
  (ref) {
    // TODO: Wire up with actual use-case providers from dependency_injection.dart
    throw UnimplementedError(
      'reportExportProvider must be overridden in the ProviderScope',
    );
  },
);
