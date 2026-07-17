import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../utils/logger.dart';

/// Miscellaneous utility methods shared across the application.
class Helpers {
  Helpers._();

  static const _uuid = Uuid();

  // ─── UUID ──────────────────────────────────────────────────────────

  /// Generates a new v4 UUID string.
  static String generateUUID() => _uuid.v4();

  // ─── File Size ─────────────────────────────────────────────────────

  /// Formats [bytes] into a human-readable file-size string
  /// (e.g. `1.5 MB`, `320 KB`).
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ─── Debounce ──────────────────────────────────────────────────────

  /// Returns a debounced version of [callback].
  ///
  /// Subsequent calls within [duration] cancel the previous pending
  /// invocation; only the last call fires after the timer elapses.
  ///
  /// ```dart
  /// final search = Helpers.debounce((query) => performSearch(query), const Duration(milliseconds: 300));
  /// ```
  static VoidCallback debounce(
    VoidCallback callback,
    Duration duration,
  ) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(duration, callback);
    };
  }

  /// Generic debounce that carries a value argument.
  static void Function(T) debounceWith<T>(
    void Function(T) callback,
    Duration duration,
  ) {
    Timer? timer;
    return (T value) {
      timer?.cancel();
      timer = Timer(duration, () => callback(value));
    };
  }

  // ─── Throttle ──────────────────────────────────────────────────────

  /// Returns a throttled version of [callback].
  ///
  /// The first call fires immediately; subsequent calls within
  /// [duration] are ignored.
  static VoidCallback throttle(
    VoidCallback callback,
    Duration duration,
  ) {
    bool ready = true;
    return () {
      if (!ready) return;
      ready = false;
      callback();
      Timer(duration, () => ready = true);
    };
  }

  // ─── Date Range ────────────────────────────────────────────────────

  /// Formats a date range as `'05 Jun 2024 – 12 Jul 2024'`.
  static String formatDateRange(DateTime start, DateTime end) {
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }

  // ─── Mask String ───────────────────────────────────────────────────

  /// Masks a string, keeping [visibleStart] characters at the beginning
  /// and [visibleEnd] at the end, replacing the middle with `*`.
  ///
  /// ```dart
  /// Helpers.maskString('ABCDEFGHIJ', visibleStart: 2, visibleEnd: 3)
  /// // → 'AB*****HIJ'
  /// ```
  static String maskString(
    String value, {
    int visibleStart = 2,
    int visibleEnd = 2,
  }) {
    if (value.length <= visibleStart + visibleEnd) return value;
    final start = value.substring(0, visibleStart);
    final end = value.substring(value.length - visibleEnd);
    final maskedLength = value.length - visibleStart - visibleEnd;
    return '$start${'*' * maskedLength}$end';
  }

  // ─── Launch URL ────────────────────────────────────────────────────

  /// Opens [url] in the platform's default browser.
  /// Returns `true` if the URL was launched successfully.
  static Future<bool> launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppLogger.warning('Invalid URL: $url');
      return false;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        AppLogger.warning('Could not launch URL: $url');
      }
      return launched;
    } catch (e) {
      AppLogger.error('Error launching URL: $url', error: e);
      return false;
    }
  }

  // ─── Clipboard ─────────────────────────────────────────────────────

  /// Copies [text] to the system clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
