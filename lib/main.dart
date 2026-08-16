import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'config/env_config.dart';
import 'config/supabase_config.dart';
import 'core/observability/crash_reporter.dart';
import 'core/utils/logger.dart';

/// Global [ProviderContainer] for accessing providers outside of the
/// widget tree (e.g. in background isolates, services, or top-level
/// functions). Only use this when [WidgetRef] is unavailable.
///
/// Must be set after [ProviderScope] is created in [runApp].
late final ProviderContainer globalContainer;

/// Logs a message to the browser console for production debugging.
void _jsLog(String message) {
  // In Flutter Web, print() maps to console.log() even in release mode.
  // ignore: avoid_print_in_production
  print(message);
}

void main() async {
  // ─── Ensure Flutter bindings ────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();
  _jsLog('[ExamForge] Flutter bindings initialized');

  // ─── Lock orientations ──────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ─── System UI overlay ──────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // ─── Initialize crash reporting FIRST (before any other bootstrap) ──
  CrashReporter.initialize();
  AppLogger.info('Crash reporter initialized');
  _jsLog('[ExamForge] Crash reporter initialized');

  // ─── Bootstrap sequence ─────────────────────────────────────────────
  try {
    // 1. Environment configuration — loads .env / dart-define values.
    _jsLog('[ExamForge] Starting EnvConfig.initialize()...');
    await EnvConfig.initialize();
    _jsLog('[ExamForge] EnvConfig initialized — url: ${EnvConfig.supabaseUrl.substring(0, 30)}...');
    AppLogger.info('Environment config initialized');

    // 2. Supabase — uses EnvConfig.supabaseUrl & .supabaseAnonKey.
    _jsLog('[ExamForge] Starting SupabaseConfig.initialize()...');
    await SupabaseConfig.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _jsLog('[ExamForge] Supabase initialization timed out after 10s!');
        throw TimeoutException('Supabase initialization timed out');
      },
    );
    _jsLog('[ExamForge] Supabase initialized successfully');
    AppLogger.info('Supabase initialized');

    // 3. App configuration — reads package info & resolves feature flags.
    _jsLog('[ExamForge] Starting AppConfig.initialize()...');
    await AppConfig.initialize();
    _jsLog('[ExamForge] App config initialized');
    AppLogger.info('App config initialized');
  } catch (e, stackTrace) {
    // If core services fail to initialize, we still want the app to
    // launch so the user sees an error screen rather than a crash.
    _jsLog('[ExamForge] FATAL INIT ERROR: $e');
    AppLogger.critical(
      'Fatal initialization error',
      error: e,
      stackTrace: stackTrace,
    );

    if (kReleaseMode) {
      CrashReporter.reportFatalError(
        e,
        stackTrace,
        featureModule: 'bootstrap',
      );
    }
  }

  // ─── Run the app ────────────────────────────────────────────────────
  _jsLog('[ExamForge] Calling runApp()...');
  final container = ProviderContainer();
  globalContainer = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ExamForgeApp(),
    ),
  );
  _jsLog('[ExamForge] runApp() called successfully');
}
