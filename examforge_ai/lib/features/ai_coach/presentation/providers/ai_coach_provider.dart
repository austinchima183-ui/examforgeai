import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/ai_coach_remote_datasource.dart';
import '../../data/repositories/ai_coach_repository_impl.dart';
import '../../domain/entities/ai_coach_entities.dart';
import '../../domain/usecases/ai_coach_usecases.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI COACH STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the AI Coach feature.
class AiCoachState {
  const AiCoachState({
    this.sessions = const [],
    this.currentSession,
    this.recommendations = const [],
    this.weakTopics = const [],
    this.readinessPrediction,
    this.generatedStudyPlan,
    this.motivationalMessage,
    this.isLoading = false,
    this.isSendingMessage = false,
    this.isLoadingRecommendations = false,
    this.isGeneratingPlan = false,
    this.isDetectingWeakTopics = false,
    this.isPredictingReadiness = false,
    this.isLoadingMessage = false,
    this.error,
    this.hasMoreSessions = true,
    this.currentPage = 1,
  });

  final List<AiCoachSession> sessions;
  final AiCoachSession? currentSession;
  final List<AiCoachRecommendation> recommendations;
  final List<WeakTopic> weakTopics;
  final ReadinessPrediction? readinessPrediction;
  final GeneratedStudyPlan? generatedStudyPlan;
  final String? motivationalMessage;

  final bool isLoading;
  final bool isSendingMessage;
  final bool isLoadingRecommendations;
  final bool isGeneratingPlan;
  final bool isDetectingWeakTopics;
  final bool isPredictingReadiness;
  final bool isLoadingMessage;

  final String? error;
  final bool hasMoreSessions;
  final int currentPage;

  int get currentPage => currentPage;
  bool get isBusy =>
      isLoading ||
      isSendingMessage ||
      isLoadingRecommendations ||
      isGeneratingPlan ||
      isDetectingWeakTopics ||
      isPredictingReadiness ||
      isLoadingMessage;

  /// Number of active (not dismissed) recommendations.
  int get activeRecommendationCount =>
      recommendations.where((r) => r.isActive).length;

  AiCoachState copyWith({
    List<AiCoachSession>? sessions,
    AiCoachSession? currentSession,
    List<AiCoachRecommendation>? recommendations,
    List<WeakTopic>? weakTopics,
    ReadinessPrediction? readinessPrediction,
    GeneratedStudyPlan? generatedStudyPlan,
    String? motivationalMessage,
    bool? isLoading,
    bool? isSendingMessage,
    bool? isLoadingRecommendations,
    bool? isGeneratingPlan,
    bool? isDetectingWeakTopics,
    bool? isPredictingReadiness,
    bool? isLoadingMessage,
    String? error,
    bool? hasMoreSessions,
    int? currentPage,
    bool clearCurrentSession = false,
    bool clearReadinessPrediction = false,
    bool clearGeneratedStudyPlan = false,
    bool clearMotivationalMessage = false,
  }) {
    return AiCoachState(
      sessions: sessions ?? this.sessions,
      currentSession: clearCurrentSession
          ? null
          : (currentSession ?? this.currentSession),
      recommendations: recommendations ?? this.recommendations,
      weakTopics: weakTopics ?? this.weakTopics,
      readinessPrediction: clearReadinessPrediction
          ? null
          : (readinessPrediction ?? this.readinessPrediction),
      generatedStudyPlan: clearGeneratedStudyPlan
          ? null
          : (generatedStudyPlan ?? this.generatedStudyPlan),
      motivationalMessage: clearMotivationalMessage
          ? null
          : (motivationalMessage ?? this.motivationalMessage),
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      isLoadingRecommendations:
          isLoadingRecommendations ?? this.isLoadingRecommendations,
      isGeneratingPlan: isGeneratingPlan ?? this.isGeneratingPlan,
      isDetectingWeakTopics:
          isDetectingWeakTopics ?? this.isDetectingWeakTopics,
      isPredictingReadiness:
          isPredictingReadiness ?? this.isPredictingReadiness,
      isLoadingMessage: isLoadingMessage ?? this.isLoadingMessage,
      error: error,
      hasMoreSessions: hasMoreSessions ?? this.hasMoreSessions,
      currentPage: currentPage ?? currentPage,
    );
  }

  AiCoachState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// AI COACH NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the AI Coach feature's state.
class AiCoachNotifier extends StateNotifier<AiCoachState> {
  AiCoachNotifier({
    required GetCoachSessionsUseCase getCoachSessions,
    required CreateCoachSessionUseCase createCoachSession,
    required UpdateCoachSessionUseCase updateCoachSession,
    required GetRecommendationsUseCase getRecommendations,
    required DismissRecommendationUseCase dismissRecommendation,
    required GenerateStudyPlanUseCase generateStudyPlan,
    required DetectWeakTopicsUseCase detectWeakTopics,
    required PredictReadinessUseCase predictReadiness,
    required GetMotivationalMessageUseCase getMotivationalMessage,
    required String? userId,
  })  : _getCoachSessions = getCoachSessions,
        _createCoachSession = createCoachSession,
        _updateCoachSession = updateCoachSession,
        _getRecommendations = getRecommendations,
        _dismissRecommendation = dismissRecommendation,
        _generateStudyPlan = generateStudyPlan,
        _detectWeakTopics = detectWeakTopics,
        _predictReadiness = predictReadiness,
        _getMotivationalMessage = getMotivationalMessage,
        _userId = userId,
        super(const AiCoachState());

  final GetCoachSessionsUseCase _getCoachSessions;
  final CreateCoachSessionUseCase _createCoachSession;
  final UpdateCoachSessionUseCase _updateCoachSession;
  final GetRecommendationsUseCase _getRecommendations;
  final DismissRecommendationUseCase _dismissRecommendation;
  final GenerateStudyPlanUseCase _generateStudyPlan;
  final DetectWeakTopicsUseCase _detectWeakTopics;
  final PredictReadinessUseCase _predictReadiness;
  final GetMotivationalMessageUseCase _getMotivationalMessage;
  final String? _userId;

  static const int _pageSize = 20;

  // ─── Load Sessions ──────────────────────────────────────────────────

  /// Loads the first page of coach sessions.
  Future<void> loadSessions() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCoachSessions(
      userId: _userId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (sessions) {
        state = state.copyWith(
          isLoading: false,
          sessions: sessions,
          currentPage: 1,
          hasMoreSessions: sessions.length >= _pageSize,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Loads more sessions (pagination).
  Future<void> loadMoreSessions() async {
    if (_userId == null || state.isBusy || !state.hasMoreSessions) return;

    final nextPage = state.currentPage + 1;
    final result = await _getCoachSessions(
      userId: _userId!,
      page: nextPage,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (sessions) {
        state = state.copyWith(
          sessions: [...state.sessions, ...sessions],
          currentPage: nextPage,
          hasMoreSessions: sessions.length >= _pageSize,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );
  }

  // ─── Create Session ─────────────────────────────────────────────────

  /// Creates a new coaching session.
  Future<void> createSession({
    required CoachSessionType sessionType,
    String? context,
  }) async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createCoachSession(
      userId: _userId!,
      sessionType: sessionType,
      context: context,
    );

    result.fold(
      onSuccess: (session) {
        state = state.copyWith(
          isLoading: false,
          currentSession: session,
          sessions: [session, ...state.sessions],
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Send Message ───────────────────────────────────────────────────

  /// Sends a message in the current session and receives AI response.
  Future<void> sendMessage(String content) async {
    final session = state.currentSession;
    if (session == null) return;

    state = state.copyWith(isSendingMessage: true, error: null);

    // Add user message
    final userMessage = {
      'role': 'user',
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final updatedMessages = [...session.messages, userMessage];

    final result = await _updateCoachSession(
      sessionId: session.id,
      messages: updatedMessages,
    );

    result.fold(
      onSuccess: (updatedSession) {
        state = state.copyWith(
          isSendingMessage: false,
          currentSession: updatedSession,
          sessions: state.sessions
              .map((s) => s.id == updatedSession.id ? updatedSession : s)
              .toList(),
        );

        // The AI response will come via Realtime subscription
        // or be included in the updated session from the backend
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSendingMessage: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Recommendations ────────────────────────────────────────────────

  /// Loads recommendations for the current user.
  Future<void> loadRecommendations() async {
    if (_userId == null) return;
    state = state.copyWith(isLoadingRecommendations: true, error: null);

    final result = await _getRecommendations(
      userId: _userId!,
      activeOnly: true,
    );

    result.fold(
      onSuccess: (recommendations) {
        state = state.copyWith(
          isLoadingRecommendations: false,
          recommendations: recommendations,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingRecommendations: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Dismisses a recommendation.
  Future<void> dismissRecommendation(String recommendationId) async {
    final result = await _dismissRecommendation(
      recommendationId: recommendationId,
    );

    result.fold(
      onSuccess: (dismissed) {
        state = state.copyWith(
          recommendations: state.recommendations
              .map((r) => r.id == dismissed.id ? dismissed : r)
              .toList(),
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );
  }

  // ─── Generate Study Plan ────────────────────────────────────────────

  /// Generates a personalized study plan.
  Future<void> generateStudyPlan({
    String? focusSubjectId,
    int? durationDays,
    List<String>? targetExamTypes,
  }) async {
    if (_userId == null) return;
    state = state.copyWith(
      isGeneratingPlan: true,
      clearGeneratedStudyPlan: true,
      error: null,
    );

    final result = await _generateStudyPlan(
      userId: _userId!,
      focusSubjectId: focusSubjectId,
      durationDays: durationDays,
      targetExamTypes: targetExamTypes,
    );

    result.fold(
      onSuccess: (plan) {
        state = state.copyWith(
          isGeneratingPlan: false,
          generatedStudyPlan: plan,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGeneratingPlan: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Detect Weak Topics ─────────────────────────────────────────────

  /// Detects weak topics for the current user.
  Future<void> detectWeakTopics({String? subjectId}) async {
    if (_userId == null) return;
    state = state.copyWith(isDetectingWeakTopics: true, error: null);

    final result = await _detectWeakTopics(
      userId: _userId!,
      subjectId: subjectId,
    );

    result.fold(
      onSuccess: (weakTopics) {
        state = state.copyWith(
          isDetectingWeakTopics: false,
          weakTopics: weakTopics,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isDetectingWeakTopics: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Predict Readiness ──────────────────────────────────────────────

  /// Predicts exam readiness.
  Future<void> predictReadiness({
    String? examType,
    DateTime? targetDate,
  }) async {
    if (_userId == null) return;
    state = state.copyWith(
      isPredictingReadiness: true,
      clearReadinessPrediction: true,
      error: null,
    );

    final result = await _predictReadiness(
      userId: _userId!,
      examType: examType,
      targetDate: targetDate,
    );

    result.fold(
      onSuccess: (prediction) {
        state = state.copyWith(
          isPredictingReadiness: false,
          readinessPrediction: prediction,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isPredictingReadiness: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Motivational Message ───────────────────────────────────────────

  /// Gets a motivational message.
  Future<void> loadMotivationalMessage() async {
    if (_userId == null) return;
    state = state.copyWith(isLoadingMessage: true, error: null);

    final result = await _getMotivationalMessage(userId: _userId!);

    result.fold(
      onSuccess: (message) {
        state = state.copyWith(
          isLoadingMessage: false,
          motivationalMessage: message,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoadingMessage: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  // ─── Select Session ─────────────────────────────────────────────────

  /// Selects a session to view its messages.
  void selectSession(AiCoachSession session) {
    state = state.copyWith(currentSession: session);
  }

  /// Clears the current session selection.
  void clearCurrentSession() {
    state = state.copyWith(clearCurrentSession: true);
  }

  // ─── Failure Mapping ────────────────────────────────────────────────

  String _mapFailure(Failure failure) => failure.when(
        server: (message, statusCode, data) =>
            'Server error ($statusCode): $message',
        cache: (message) => 'Cache error: $message',
        auth: (message, code) => 'Auth error: $message',
        network: (message) => 'Network error: $message',
        validation: (message, fieldErrors) =>
            'Validation error: $message',
        notFound: (message) => message,
        unauthorized: (message) => 'Unauthorized: $message',
        forbidden: (message) => 'Forbidden: $message',
      );
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the Supabase client.
final _supabaseClientProvider = Provider<sb.SupabaseClient>((ref) {
  return sb.Supabase.instance.client;
});

/// Provides the remote datasource.
final _remoteDatasourceProvider =
    Provider<AiCoachRemoteDatasource>((ref) {
  return AiCoachRemoteDatasourceImpl(
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provides the repository implementation.
final _repositoryProvider = Provider<AiCoachRepositoryImpl>((ref) {
  return AiCoachRepositoryImpl(
    remoteDatasource: ref.watch(_remoteDatasourceProvider),
    supabaseClient: ref.watch(_supabaseClientProvider),
  );
});

/// Provides the current user ID.
final _userIdProvider = Provider<String?>((ref) {
  return sb.Supabase.instance.client.auth.currentUser?.id;
});

/// Use case providers.
final _getCoachSessionsUseCaseProvider =
    Provider<GetCoachSessionsUseCase>((ref) {
  return GetCoachSessionsUseCase(ref.watch(_repositoryProvider));
});

final _createCoachSessionUseCaseProvider =
    Provider<CreateCoachSessionUseCase>((ref) {
  return CreateCoachSessionUseCase(ref.watch(_repositoryProvider));
});

final _updateCoachSessionUseCaseProvider =
    Provider<UpdateCoachSessionUseCase>((ref) {
  return UpdateCoachSessionUseCase(ref.watch(_repositoryProvider));
});

final _getRecommendationsUseCaseProvider =
    Provider<GetRecommendationsUseCase>((ref) {
  return GetRecommendationsUseCase(ref.watch(_repositoryProvider));
});

final _dismissRecommendationUseCaseProvider =
    Provider<DismissRecommendationUseCase>((ref) {
  return DismissRecommendationUseCase(ref.watch(_repositoryProvider));
});

final _generateStudyPlanUseCaseProvider =
    Provider<GenerateStudyPlanUseCase>((ref) {
  return GenerateStudyPlanUseCase(ref.watch(_repositoryProvider));
});

final _detectWeakTopicsUseCaseProvider =
    Provider<DetectWeakTopicsUseCase>((ref) {
  return DetectWeakTopicsUseCase(ref.watch(_repositoryProvider));
});

final _predictReadinessUseCaseProvider =
    Provider<PredictReadinessUseCase>((ref) {
  return PredictReadinessUseCase(ref.watch(_repositoryProvider));
});

final _getMotivationalMessageUseCaseProvider =
    Provider<GetMotivationalMessageUseCase>((ref) {
  return GetMotivationalMessageUseCase(ref.watch(_repositoryProvider));
});

/// Main provider for the AI Coach feature.
final aiCoachProvider =
    StateNotifierProvider<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(
    getCoachSessions: ref.watch(_getCoachSessionsUseCaseProvider),
    createCoachSession: ref.watch(_createCoachSessionUseCaseProvider),
    updateCoachSession: ref.watch(_updateCoachSessionUseCaseProvider),
    getRecommendations: ref.watch(_getRecommendationsUseCaseProvider),
    dismissRecommendation: ref.watch(_dismissRecommendationUseCaseProvider),
    generateStudyPlan: ref.watch(_generateStudyPlanUseCaseProvider),
    detectWeakTopics: ref.watch(_detectWeakTopicsUseCaseProvider),
    predictReadiness: ref.watch(_predictReadinessUseCaseProvider),
    getMotivationalMessage: ref.watch(_getMotivationalMessageUseCaseProvider),
    userId: ref.watch(_userIdProvider),
  );
});
