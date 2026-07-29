import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/logger.dart';
import '../../../../routing/route_guards.dart';

// ═══════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════

/// Aggregated statistics displayed on the dashboard.
///
/// Not every field is relevant for every role — the provider populates
/// only the fields that make sense for the current [UserRole].
class DashboardStats {
  const DashboardStats({
    this.totalStudents = 0,
    this.totalClasses = 0,
    this.totalSubjects = 0,
    this.totalExams = 0,
    this.pendingExams = 0,
    this.completedExams = 0,
    this.upcomingExams = 0,
    this.averageScore = 0.0,
    this.bestScore = 0.0,
    this.totalTeachers = 0,
    this.activeExams = 0,
    this.totalSchools = 0,
    this.totalUsers = 0,
    this.platformRevenue = 0.0,
    this.questionBankCount = 0,
  });

  final int totalStudents;
  final int totalClasses;
  final int totalSubjects;
  final int totalExams;
  final int pendingExams;
  final int completedExams;
  final int upcomingExams;
  final double averageScore;
  final double bestScore;
  final int totalTeachers;
  final int activeExams;
  final int totalSchools;
  final int totalUsers;
  final double platformRevenue;
  final int questionBankCount;

  DashboardStats copyWith({
    int? totalStudents,
    int? totalClasses,
    int? totalSubjects,
    int? totalExams,
    int? pendingExams,
    int? completedExams,
    int? upcomingExams,
    double? averageScore,
    double? bestScore,
    int? totalTeachers,
    int? activeExams,
    int? totalSchools,
    int? totalUsers,
    double? platformRevenue,
    int? questionBankCount,
  }) {
    return DashboardStats(
      totalStudents: totalStudents ?? this.totalStudents,
      totalClasses: totalClasses ?? this.totalClasses,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      totalExams: totalExams ?? this.totalExams,
      pendingExams: pendingExams ?? this.pendingExams,
      completedExams: completedExams ?? this.completedExams,
      upcomingExams: upcomingExams ?? this.upcomingExams,
      averageScore: averageScore ?? this.averageScore,
      bestScore: bestScore ?? this.bestScore,
      totalTeachers: totalTeachers ?? this.totalTeachers,
      activeExams: activeExams ?? this.activeExams,
      totalSchools: totalSchools ?? this.totalSchools,
      totalUsers: totalUsers ?? this.totalUsers,
      platformRevenue: platformRevenue ?? this.platformRevenue,
      questionBankCount: questionBankCount ?? this.questionBankCount,
    );
  }
}

/// A single activity item shown in the "Recent Activity" list.
class ActivityItem {
  const ActivityItem({
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.icon,
    this.color,
  });

  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final IconData? icon;
  final Color? color;
}

/// A single notification item for the notification summary.
class NotificationItem {
  const NotificationItem({
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.icon,
    this.isRead = false,
  });

  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final IconData? icon;
  final bool isRead;
}

// ═══════════════════════════════════════════════════════════════════════
// DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the dashboard feature.
class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.stats = const DashboardStats(),
    this.recentActivity = const [],
    this.notifications = const [],
    this.error,
  });

  /// Whether dashboard data is currently being loaded.
  final bool isLoading;

  /// Aggregated statistics for the current user's role.
  final DashboardStats stats;

  /// Recent activity items.
  final List<ActivityItem> recentActivity;

  /// Notification items.
  final List<NotificationItem> notifications;

  /// The most recent error message, or `null`.
  final String? error;

  /// Number of unread notifications.
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Whether there are unread notifications.
  bool get hasUnread => unreadCount > 0;

  DashboardState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    List<ActivityItem>? recentActivity,
    List<NotificationItem>? notifications,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      recentActivity: recentActivity ?? this.recentActivity,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the dashboard feature's state.
///
/// Loads role-specific dashboard data from Supabase, supports
/// pull-to-refresh, and handles errors gracefully.
///
/// All queries are RLS-protected — the user's JWT automatically filters
/// rows according to their role and school membership.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({
    required this.role,
    required sb.SupabaseClient supabaseClient,
  })  : _supabaseClient = supabaseClient,
        super(const DashboardState()) {
    loadDashboard();
  }

  final UserRole role;
  final sb.SupabaseClient _supabaseClient;

  /// Loads dashboard data based on the user's role.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _loadStatsForRole(role);
      final activity = _loadActivityForRole(role);
      final notifications = _loadNotificationsForRole(role);

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        recentActivity: activity,
        notifications: notifications,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Dashboard Supabase query failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data. Please try again.',
      );
    } catch (e) {
      AppLogger.error('Dashboard load failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data. Please try again.',
      );
    }
  }

  /// Refreshes dashboard data (pull-to-refresh).
  Future<void> refresh() async {
    await loadDashboard();
  }

  // ─── Role-Specific Stats from Supabase ───────────────────────────

  /// Fetches real dashboard stats from Supabase for the given [role].
  ///
  /// Each role queries a different set of tables. RLS policies on the
  /// Supabase side ensure that the user only sees data they are
  /// authorised to access — the JWT is sent automatically with every
  /// request.
  Future<DashboardStats> _loadStatsForRole(UserRole role) async {
    return switch (role) {
      UserRole.superAdmin => _loadSuperAdminStats(),
      UserRole.schoolAdmin => _loadSchoolAdminStats(),
      UserRole.teacher => _loadTeacherStats(),
      UserRole.student => _loadStudentStats(),
    };
  }

  // ─── Super Admin ──────────────────────────────────────────────────

  Future<DashboardStats> _loadSuperAdminStats() async {
    final results = await Future.wait([
      _countRows('schools'),
      _countRows('users'),
      _countRows('subscriptions'),
      _countRows('transactions'),
    ]);

    return DashboardStats(
      totalSchools: results[0],
      totalUsers: results[1],
      activeExams: results[2],
      platformRevenue: results[3].toDouble(),
    );
  }

  // ─── School Admin ─────────────────────────────────────────────────

  Future<DashboardStats> _loadSchoolAdminStats() async {
    final results = await Future.wait([
      _countRows('students'),
      _countRows('teachers'),
      _countRows('classes'),
      _countRows('exams'),
    ]);

    return DashboardStats(
      totalStudents: results[0],
      totalTeachers: results[1],
      totalClasses: results[2],
      activeExams: results[3],
    );
  }

  // ─── Teacher ──────────────────────────────────────────────────────

  Future<DashboardStats> _loadTeacherStats() async {
    final results = await Future.wait([
      _countRows('exams'),
      _countRows('questions'),
      _countRows('students'),
    ]);

    // Compute average score from the teacher's exam attempts.
    final avgScore = await _fetchAverageScore(
      table: 'exam_attempts',
      scoreColumn: 'score',
    );

    return DashboardStats(
      totalExams: results[0],
      questionBankCount: results[1],
      totalStudents: results[2],
      averageScore: avgScore,
    );
  }

  // ─── Student ──────────────────────────────────────────────────────

  Future<DashboardStats> _loadStudentStats() async {
    final results = await Future.wait([
      _countRows('exams'),
      _countRows('exam_attempts'),
    ]);

    // Compute average score from the student's own attempts.
    final avgScore = await _fetchAverageScore(
      table: 'exam_attempts',
      scoreColumn: 'score',
    );

    // Compute best score from the student's own attempts.
    final bestScore = await _fetchBestScore(
      table: 'exam_attempts',
      scoreColumn: 'score',
    );

    // Count upcoming (not yet started) exams.
    final upcomingCount = await _countRows(
      'exams',
      filter: 'status=eq.upcoming',
    );

    // Count completed attempts.
    final completedCount = await _countRows(
      'exam_attempts',
      filter: 'status=eq.completed',
    );

    return DashboardStats(
      totalExams: results[0],
      completedExams: completedCount,
      upcomingExams: upcomingCount,
      averageScore: avgScore,
      bestScore: bestScore,
    );
  }

  // ─── Supabase Query Helpers ───────────────────────────────────────

  /// Counts rows in [table], optionally applying a PostgREST [filter].
  ///
  /// Uses the Supabase `count: CountOption.exact` option so that the
  /// total count is returned even when `select` is limited. RLS
  /// automatically scopes the query to the current user.
  Future<int> _countRows(String table, {String? filter}) async {
    try {
      var query = _supabaseClient.from(table).select('*');

      if (filter != null) {
        // Apply filter by chaining the filter method.
        // The filter string format is "column=eq.value".
        final parts = filter.split('=');
        if (parts.length == 2) {
          final column = parts[0];
          final value = parts[1];
          query = query.eq(column, value);
        }
      }

      final response = await query.count(sb.CountOption.exact);
      return response.count;
    } on sb.PostgrestException catch (e) {
      AppLogger.warning('Failed to count rows in "$table"', error: e);
      return 0;
    } catch (e) {
      AppLogger.warning('Unexpected error counting rows in "$table"',
          error: e);
      return 0;
    }
  }

  /// Fetches the average value of [scoreColumn] from [table].
  ///
  /// Uses an RPC call to a `get_avg` Postgres function if available,
  /// otherwise falls back to fetching all rows and computing the average
  /// in Dart. RLS ensures only the user's own rows are visible.
  Future<double> _fetchAverageScore({
    required String table,
    required String scoreColumn,
  }) async {
    try {
      // Try the RPC function first — it's more efficient.
      final result = await _supabaseClient.rpc(
        'get_dashboard_avg_score',
        params: {
          'table_name': table,
          'score_column': scoreColumn,
        },
      );

      if (result is num) return result.toDouble();
      if (result is Map<String, dynamic> && result.containsKey('avg')) {
        final avg = result['avg'];
        if (avg is num) return avg.toDouble();
      }
    } on sb.PostgrestException {
      // RPC function may not exist — fall back to client-side calculation.
      AppLogger.info(
        'RPC "get_dashboard_avg_score" not available, '
        'falling back to client-side average for $table.$scoreColumn',
      );
    } catch (e) {
      AppLogger.info(
        'RPC fallback for average score failed, '
        'using client-side calculation',
      );
    }

    // Client-side fallback: fetch scores and compute average.
    try {
      final response = await _supabaseClient
          .from(table)
          .select(scoreColumn);

      final scores = response
          .map<double?>((row) {
            final val = row[scoreColumn];
            return val is num ? val.toDouble() : null;
          })
          .whereType<double>()
          .toList();

      if (scores.isEmpty) return 0.0;
      return scores.reduce((a, b) => a + b) / scores.length;
    } catch (e) {
      AppLogger.warning('Client-side average score failed', error: e);
      return 0.0;
    }
  }

  /// Fetches the best (maximum) value of [scoreColumn] from [table].
  ///
  /// Uses an RPC call first, then falls back to client-side calculation.
  Future<double> _fetchBestScore({
    required String table,
    required String scoreColumn,
  }) async {
    try {
      final result = await _supabaseClient.rpc(
        'get_dashboard_best_score',
        params: {
          'table_name': table,
          'score_column': scoreColumn,
        },
      );

      if (result is num) return result.toDouble();
      if (result is Map<String, dynamic> && result.containsKey('max')) {
        final max = result['max'];
        if (max is num) return max.toDouble();
      }
    } on sb.PostgrestException {
      AppLogger.info(
        'RPC "get_dashboard_best_score" not available, '
        'falling back to client-side max for $table.$scoreColumn',
      );
    } catch (e) {
      AppLogger.info(
        'RPC fallback for best score failed, '
        'using client-side calculation',
      );
    }

    // Client-side fallback.
    try {
      final response = await _supabaseClient
          .from(table)
          .select(scoreColumn);

      final scores = response
          .map<double?>((row) {
            final val = row[scoreColumn];
            return val is num ? val.toDouble() : null;
          })
          .whereType<double>()
          .toList();

      if (scores.isEmpty) return 0.0;
      return scores.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      AppLogger.warning('Client-side best score failed', error: e);
      return 0.0;
    }
  }

  // ─── Activity & Notifications (placeholder) ───────────────────────
  //
  // Activity and notifications will be migrated to real Supabase
  // queries in a follow-up task. For now they return an empty list
  // so the UI is not blocked by stale mock data.

  List<ActivityItem> _loadActivityForRole(UserRole role) {
    // TODO: Replace with real Supabase queries for activity feed.
    return const [];
  }

  List<NotificationItem> _loadNotificationsForRole(UserRole role) {
    // TODO: Replace with real Supabase queries for notifications.
    return const [];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provider for the current user's role, resolving from auth state.
final _dashboardRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentRoleProvider);
});

/// Main dashboard provider — creates a [DashboardNotifier] scoped to
/// the user's current role and exposes the [DashboardState].
///
/// The [SupabaseClient] is injected from [supabaseClientProvider] so
/// that all queries are automatically RLS-protected by the user's JWT.
final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>(
  (ref) {
    final role = ref.watch(_dashboardRoleProvider);
    final supabaseClient = ref.watch(supabaseClientProvider);
    return DashboardNotifier(
      role: role ?? UserRole.student,
      supabaseClient: supabaseClient,
    );
  },
);
