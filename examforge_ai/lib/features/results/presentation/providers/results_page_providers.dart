// ═══════════════════════════════════════════════════════════════════════
// RESULTS ENGINE — PAGE-LEVEL RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════
// Re-exports the real providers from dependency_injection.dart so that
// page-level widgets can import a single, convenient file.
// ═══════════════════════════════════════════════════════════════════════

export '../../../../config/dependency_injection.dart'
    show studentResultsProvider, analyticsProvider, reportExportProvider;
