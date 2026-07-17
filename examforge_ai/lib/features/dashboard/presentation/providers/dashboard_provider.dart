import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// Loads role-specific dashboard data, supports pull-to-refresh, and
/// provides mock data for development until the backend APIs are ready.
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({required this.role}) : super(const DashboardState()) {
    loadDashboard();
  }

  final UserRole role;

  /// Loads dashboard data based on the user's role.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate network delay for realistic loading state.
      await Future.delayed(const Duration(milliseconds: 600));

      final stats = _loadStatsForRole(role);
      final activity = _loadActivityForRole(role);
      final notifications = _loadNotificationsForRole(role);

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        recentActivity: activity,
        notifications: notifications,
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

  // ─── Role-Specific Mock Data ──────────────────────────────────────

  DashboardStats _loadStatsForRole(UserRole role) {
    return switch (role) {
      UserRole.teacher => const DashboardStats(
          totalStudents: 156,
          totalClasses: 6,
          totalSubjects: 4,
          totalExams: 24,
          pendingExams: 3,
          averageScore: 74.5,
        ),
      UserRole.student => const DashboardStats(
          upcomingExams: 2,
          completedExams: 12,
          averageScore: 82.3,
          totalSubjects: 6,
          bestScore: 98.0,
        ),
      UserRole.schoolAdmin => const DashboardStats(
          totalTeachers: 28,
          totalStudents: 842,
          totalClasses: 36,
          activeExams: 15,
          questionBankCount: 1240,
        ),
      UserRole.superAdmin => const DashboardStats(
          totalSchools: 14,
          totalUsers: 3287,
          totalExams: 892,
          platformRevenue: 47850.0,
        ),
    };
  }

  List<ActivityItem> _loadActivityForRole(UserRole role) {
    final now = DateTime.now();
    return switch (role) {
      UserRole.teacher => [
          ActivityItem(
            title: 'New submission for Math Quiz 3',
            subtitle: 'Alice Johnson scored 92%',
            timestamp: now.subtract(const Duration(minutes: 12)),
            icon: Icons.assignment_turned_in_outlined,
          ),
          ActivityItem(
            title: 'Biology Mid-Term graded',
            subtitle: '32 students evaluated',
            timestamp: now.subtract(const Duration(hours: 2)),
            icon: Icons.grading_outlined,
          ),
          ActivityItem(
            title: 'Question bank updated',
            subtitle: '15 new questions added to Chemistry',
            timestamp: now.subtract(const Duration(hours: 5)),
            icon: Icons.library_add_outlined,
          ),
          ActivityItem(
            title: 'Class 10-A exam completed',
            subtitle: 'Average score: 78.4%',
            timestamp: now.subtract(const Duration(days: 1)),
            icon: Icons.fact_check_outlined,
          ),
          ActivityItem(
            title: 'New student enrolled',
            subtitle: 'Mark Thompson joined Physics class',
            timestamp: now.subtract(const Duration(days: 1, hours: 3)),
            icon: Icons.person_add_outlined,
          ),
        ],
      UserRole.student => [
          ActivityItem(
            title: 'Math Quiz 3 result published',
            subtitle: 'You scored 92%',
            timestamp: now.subtract(const Duration(minutes: 30)),
            icon: Icons.emoji_events_outlined,
          ),
          ActivityItem(
            title: 'Physics Mid-Term scheduled',
            subtitle: 'March 15, 2025 at 10:00 AM',
            timestamp: now.subtract(const Duration(hours: 4)),
            icon: Icons.event_outlined,
          ),
          ActivityItem(
            title: 'Chemistry assignment due',
            subtitle: 'Due in 2 days',
            timestamp: now.subtract(const Duration(hours: 8)),
            icon: Icons.assignment_outlined,
          ),
          ActivityItem(
            title: 'Biology practice test available',
            subtitle: '25 questions, 30 minutes',
            timestamp: now.subtract(const Duration(days: 1)),
            icon: Icons.quiz_outlined,
          ),
        ],
      UserRole.schoolAdmin => [
          ActivityItem(
            title: 'New teacher registered',
            subtitle: 'Dr. Sarah Williams — Mathematics',
            timestamp: now.subtract(const Duration(minutes: 45)),
            icon: Icons.person_add_outlined,
          ),
          ActivityItem(
            title: 'Term exam schedule published',
            subtitle: 'March 10–20, 2025',
            timestamp: now.subtract(const Duration(hours: 3)),
            icon: Icons.calendar_month_outlined,
          ),
          ActivityItem(
            title: 'Class 8-B performance report ready',
            subtitle: 'Average improvement: +12%',
            timestamp: now.subtract(const Duration(days: 1)),
            icon: Icons.trending_up_outlined,
          ),
          ActivityItem(
            title: 'Student enrollment updated',
            subtitle: '5 new students this week',
            timestamp: now.subtract(const Duration(days: 1, hours: 5)),
            icon: Icons.group_add_outlined,
          ),
        ],
      UserRole.superAdmin => [
          ActivityItem(
            title: 'New school registered',
            subtitle: 'Greenfield Academy, London',
            timestamp: now.subtract(const Duration(minutes: 20)),
            icon: Icons.domain_add_outlined,
          ),
          ActivityItem(
            title: 'Platform usage milestone',
            subtitle: '3,000+ active users this month',
            timestamp: now.subtract(const Duration(hours: 1)),
            icon: Icons.insights_outlined,
          ),
          ActivityItem(
            title: 'System maintenance scheduled',
            subtitle: 'March 12, 2025 at 2:00 AM UTC',
            timestamp: now.subtract(const Duration(hours: 6)),
            icon: Icons.build_outlined,
          ),
          ActivityItem(
            title: 'Monthly revenue report ready',
            subtitle: '\$47,850 — up 18% from last month',
            timestamp: now.subtract(const Duration(days: 1)),
            icon: Icons.attach_money,
          ),
        ],
    };
  }

  List<NotificationItem> _loadNotificationsForRole(UserRole role) {
    final now = DateTime.now();
    return [
      NotificationItem(
        title: 'System update completed',
        subtitle: 'Version 2.4.1 deployed successfully',
        timestamp: now.subtract(const Duration(minutes: 5)),
        icon: Icons.system_update_outlined,
        isRead: false,
      ),
      NotificationItem(
        title: 'New features available',
        subtitle: 'AI-powered question generation is now live',
        timestamp: now.subtract(const Duration(hours: 2)),
        icon: Icons.auto_awesome_outlined,
        isRead: false,
      ),
      NotificationItem(
        title: 'Security alert',
        subtitle: 'Please update your password',
        timestamp: now.subtract(const Duration(days: 1)),
        icon: Icons.security_outlined,
        isRead: true,
      ),
      NotificationItem(
        title: 'Weekly report ready',
        subtitle: 'Your activity summary for this week',
        timestamp: now.subtract(const Duration(days: 2)),
        icon: Icons.summarize_outlined,
        isRead: true,
      ),
    ];
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
final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, DashboardState>(
  (ref) {
    final role = ref.watch(_dashboardRoleProvider);
    return DashboardNotifier(role: role ?? UserRole.student);
  },
);
