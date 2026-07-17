import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'config/env_config.dart';
import 'config/supabase_config.dart';
import 'core/utils/logger.dart';

/// Global [ProviderContainer] for accessing providers outside of the
/// widget tree (e.g. in background isolates, services, or top-level
/// functions). Only use this when [WidgetRef] is unavailable.
///
/// Must be set after [ProviderScope] is created in [runApp].
late final ProviderContainer globalContainer;

void main() async {
  // ─── Ensure Flutter bindings ────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

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

  // ─── Bootstrap sequence ─────────────────────────────────────────────
  // Each step must complete before the next begins because later steps
  // depend on earlier ones (e.g. Supabase needs EnvConfig values).
  try {
    // 1. Environment configuration — loads .env / dart-define values.
    await EnvConfig.initialize();
    AppLogger.info('Environment config initialized');

    // 2. Supabase — uses EnvConfig.supabaseUrl & .supabaseAnonKey.
    await SupabaseConfig.initialize();
    AppLogger.info('Supabase initialized');

    // 3. App configuration — reads package info & resolves feature flags.
    await AppConfig.initialize();
    AppLogger.info('App config initialized');
  } catch (e, stackTrace) {
    // If core services fail to initialize, we still want the app to
    // launch so the user sees an error screen rather than a crash.
    AppLogger.critical(
      'Fatal initialization error',
      error: e,
      stackTrace: stackTrace,
    );

    // In release builds, report to crash reporting (e.g. Firebase Crashlytics).
    // In debug, the logger output is sufficient.
    if (kReleaseMode) {
      // TODO: Integrate crash reporting service here.
    }
  }

  // ─── Run the app ────────────────────────────────────────────────────
  final container = ProviderContainer();
  globalContainer = container;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ExamForgeApp(),
    ),
  );
}
