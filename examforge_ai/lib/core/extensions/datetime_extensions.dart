import 'package:intl/intl.dart';

/// Convenience getters and methods on [DateTime].
extension DateTimeExtensions on DateTime {
  // ─── Formatted Strings ─────────────────────────────────────────────

  /// `dd MMM yyyy` → `05 Jun 2024`
  String get formatted => DateFormat('dd MMM yyyy').format(this);

  /// `dd MMM yyyy, HH:mm` → `05 Jun 2024, 14:30`
  String get formattedWithTime => DateFormat('dd MMM yyyy, HH:mm').format(this);

  // ─── Relative Time ─────────────────────────────────────────────────

  /// Returns a human-readable "time ago" string such as
  /// `'just now'`, `'5 minutes ago'`, `'2 hours ago'`, `'3 days ago'`.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    final years = (diff.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  // ─── Day / Week / Month Checks ─────────────────────────────────────

  /// True when this date falls on today's calendar date.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True when this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// True when this date falls within the current ISO week.
  bool get isThisWeek {
    final now = DateTime.now();
    // Find the Monday of the current week.
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
    return !isBefore(start) && !isAfter(end);
  }

  /// True when this date falls within the current month.
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  // ─── Boundary Helpers ──────────────────────────────────────────────

  /// A new [DateTime] at 00:00:00.000 of this date.
  DateTime get startOfDay => DateTime(year, month, day);

  /// A new [DateTime] at 23:59:59.999 of this date.
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  // ─── Age ───────────────────────────────────────────────────────────

  /// Calculates whole years from this birthdate to today.
  int get age {
    final now = DateTime.now();
    var age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
}
