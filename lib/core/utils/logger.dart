import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_pkg;

/// Application-wide logging utility.
///
/// Provides static convenience methods that delegate to a singleton
/// [log_pkg.Logger] configured with a production-friendly printer.
/// Logs are suppressed in release builds.
///
/// ```dart
/// AppLogger.debug('Widget rebuilt');
/// AppLogger.info('User logged in', error: e, stackTrace: st);
/// AppLogger.error('Payment failed', error: e);
/// ```
class AppLogger {
  AppLogger._();

  static final log_pkg.Logger _logger = log_pkg.Logger(
    printer: log_pkg.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: log_pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? log_pkg.Level.debug : log_pkg.Level.nothing,
  );

  // ─── Public API ────────────────────────────────────────────────────

  /// Verbose / diagnostic messages. Only visible in debug builds.
  static void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// General informational messages.
  static void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Something is not right but the app can continue.
  static void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// A recoverable error that should be investigated.
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// A critical / unrecoverable error that requires immediate attention.
  static void critical(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
