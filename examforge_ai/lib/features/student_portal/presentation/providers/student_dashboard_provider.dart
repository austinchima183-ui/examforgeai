import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the student dashboard feature.
///
/// Tracks the dashboard stats, recent conversations, notifications,
/// pending assignments, recent practice sessions, loading flags, and
/// error state.
class StudentDashboardState {
  const StudentDashboardState({
    this.stats = const StudentDashboardStats(),
    this.isLoading = false,
    this.error,
    this.recentConversations = const [],
    this.recentNotifications = const [],
    this.pendingAssignments = const [],
    this.recentPractice = const [],
  });

  /// Aggregated dashboard statistics.
  final StudentDashboardStats stats;

  /// Whether a dashboard load operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Recent AI Tutor conversations (limited for dashboard preview).
  final List<AiTutorConversationEntity> recentConversations;

  /// Recent notifications (unread / latest).
  final List<StudentNotificationEntity> recentNotifications;

  /// Assignments that are pending submission.
  final List<AssignmentSubmissionEntity> pendingAssignments;

  /// Recent practice sessions.
  final List<PracticeSessionEntity> recentPractice;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Number of unread notifications.
  int get unreadNotificationCount =>
      recentNotifications.where((n) => !n.isRead).length;

  /// Creates a copy of this state with the given fields replaced.
  StudentDashboardState copyWith({
    StudentDashboardStats? stats,
    bool? isLoading,
    String? error,
    List<AiTutorConversationEntity>? recentConversations,
    List<StudentNotificationEntity>? recentNotifications,
    List<AssignmentSubmissionEntity>? pendingAssignments,
    List<PracticeSessionEntity>? recentPractice,
  }) {
    return StudentDashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      recentConversations:
          recentConversations ?? this.recentConversations,
      recentNotifications:
          recentNotifications ?? this.recentNotifications,
      pendingAssignments:
          pendingAssignments ?? this.pendingAssignments,
      recentPractice: recentPractice ?? this.recentPractice,
    );
  }

  /// Clears the current error message.
  StudentDashboardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the student dashboard state.
///
/// All dashboard operations flow through this notifier, which:
/// 1. Sets [isLoading] before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates the dashboard data on success
/// 4. Sets [error] on failure
class StudentDashboardNotifier extends StateNotifier<StudentDashboardState> {
  StudentDashboardNotifier({
    required GetDashboardStatsUseCase getDashboardStats,
    required GetConversationsUseCase getConversations,
    required GetNotificationsUseCase getNotifications,
    required GetSubmissionsUseCase getSubmissions,
    required GetPracticeSessionsUseCase getPracticeSessions,
    required String? studentId,
  })  : _getDashboardStats = getDashboardStats,
        _getConversations = getConversations,
        _getNotifications = getNotifications,
        _getSubmissions = getSubmissions,
        _getPracticeSessions = getPracticeSessions,
        _studentId = studentId,
        super(const StudentDashboardState());

  final GetDashboardStatsUseCase _getDashboardStats;
  final GetConversationsUseCase _getConversations;
  final GetNotificationsUseCase _getNotifications;
  final GetSubmissionsUseCase _getSubmissions;
  final GetPracticeSessionsUseCase _getPracticeSessions;
  final String? _studentId;

  // ─── Load Dashboard ────────────────────────────────────────────────

  /// Loads all dashboard data in parallel for the current student.
  Future<void> loadDashboard() async {
    if (_studentId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Not authenticated',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    // Run all dashboard queries in parallel for faster load.
    final results = await Future.wait([
      _getDashboardStats(studentId: _studentId!),
      _getConversations(studentId: _studentId!, page: 1, pageSize: 5),
      _getNotifications(studentId: _studentId!, page: 1, pageSize: 5),
      _getSubmissions(
        studentId: _studentId!,
        page: 1,
        pageSize: 5,
        status: SubmissionStatus.draft,
      ),
      _getPracticeSessions(studentId: _studentId!, page: 1, pageSize: 5),
    ]);

    // Extract results, checking for failures.
    final statsResult = results[0] as Result<StudentDashboardStats>;
    final conversationsResult =
        results[1] as Result<List<AiTutorConversationEntity>>;
    final notificationsResult =
        results[2] as Result<List<StudentNotificationEntity>>;
    final submissionsResult =
        results[3] as Result<List<AssignmentSubmissionEntity>>;
    final practiceResult =
        results[4] as Result<List<PracticeSessionEntity>>;

    // If the main stats call failed, report the error.
    if (statsResult.isFailure) {
      statsResult.fold(
        onSuccess: (_) {},
        onFailure: (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _mapFailureToMessage(failure),
          );
          AppLogger.warning('Failed to load dashboard stats: $failure');
        },
      );
      return;
    }

    // Otherwise extract all successful data.
    final stats = statsResult.getOrElse(const StudentDashboardStats());
    final conversations =
        conversationsResult.getOrElse(const []);
    final notifications =
        notificationsResult.getOrElse(const []);
    final submissions = submissionsResult.getOrElse(const []);
    final practice = practiceResult.getOrElse(const []);

    state = state.copyWith(
      isLoading: false,
      stats: stats,
      recentConversations: conversations,
      recentNotifications: notifications,
      pendingAssignments: submissions,
      recentPractice: practice,
      error: null,
    );
    AppLogger.info('Dashboard loaded successfully');
  }

  // ─── Refresh Dashboard ─────────────────────────────────────────────

  /// Refreshes the dashboard by reloading all data.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await loadDashboard();
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the current student ID derived from auth state.
///
/// This is used by all student portal providers to identify the
/// currently logged-in student.
final currentStudentIdProvider = Provider<String?>((ref) {
  final userId = ref.watch(userIdProvider);
  return userId;
});

/// Provides the current student's school ID from auth state.
final studentSchoolIdProvider = Provider<String?>((ref) {
  return ref.watch(userSchoolIdProvider);
});

/// Provides the [StudentDashboardNotifier] with all required use cases.
///
/// Reads the current student ID from [currentStudentIdProvider] and
/// passes it to the notifier so that it can load dashboard data.
final studentDashboardProvider =
    StateNotifierProvider<StudentDashboardNotifier, StudentDashboardState>(
  (ref) {
    return StudentDashboardNotifier(
      getDashboardStats: ref.watch(getDashboardStatsUseCaseProvider),
      getConversations: ref.watch(studentGetConversationsUseCaseProvider),
      getNotifications: ref.watch(studentGetNotificationsUseCaseProvider),
      getSubmissions: ref.watch(getSubmissionsUseCaseProvider),
      getPracticeSessions: ref.watch(getPracticeSessionsUseCaseProvider),
      studentId: ref.watch(currentStudentIdProvider),
    );
  },
);
