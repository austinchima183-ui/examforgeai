import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/exam_ecosystem_remote_datasource.dart';
import '../../data/repositories/exam_ecosystem_repository_impl.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../../domain/repositories/exam_ecosystem_repository.dart';
import '../../domain/usecases/exam_ecosystem_usecases.dart';

// ═══════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final _examEcosystemRemoteDataSourceProvider =
    Provider<ExamEcosystemRemoteDataSource>((ref) {
  return ExamEcosystemRemoteDataSourceImpl();
});

final examEcosystemRepositoryProvider = Provider<ExamEcosystemRepository>((ref) {
  return ExamEcosystemRepositoryImpl(
    remoteDataSource: ref.watch(_examEcosystemRemoteDataSourceProvider),
  );
});

// ─── Current User ID Provider ───────────────────────────────────────

/// Provides the current user ID from Supabase auth.
final currentUserIdProvider = Provider<String?>((ref) {
  try {
    final client = _supabaseClient;
    return client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
});

/// Helper to get Supabase client without importing config directly.
sb.SupabaseClient get _supabaseClient => sb.Supabase.instance.client;

// ─── Use Case Providers ─────────────────────────────────────────────

final _getExaminationBodiesUseCaseProvider =
    Provider<GetExaminationBodiesUseCase>((ref) {
  return GetExaminationBodiesUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getExaminationProductsUseCaseProvider =
    Provider<GetExaminationProductsUseCase>((ref) {
  return GetExaminationProductsUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _createExaminationProductUseCaseProvider =
    Provider<CreateExaminationProductUseCase>((ref) {
  return CreateExaminationProductUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getMockExamsUseCaseProvider = Provider<GetMockExamsUseCase>((ref) {
  return GetMockExamsUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _createMockExamUseCaseProvider = Provider<CreateMockExamUseCase>((ref) {
  return CreateMockExamUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _publishMockExamUseCaseProvider = Provider<PublishMockExamUseCase>((ref) {
  return PublishMockExamUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _startMockExamAttemptUseCaseProvider =
    Provider<StartMockExamAttemptUseCase>((ref) {
  return StartMockExamAttemptUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _submitMockExamAttemptUseCaseProvider =
    Provider<SubmitMockExamAttemptUseCase>((ref) {
  return SubmitMockExamAttemptUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getMockExamResultsUseCaseProvider =
    Provider<GetMockExamResultsUseCase>((ref) {
  return GetMockExamResultsUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getReadinessAssessmentUseCaseProvider =
    Provider<GetReadinessAssessmentUseCase>((ref) {
  return GetReadinessAssessmentUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _calculateReadinessUseCaseProvider =
    Provider<CalculateReadinessUseCase>((ref) {
  return CalculateReadinessUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getExamReadinessUseCaseProvider =
    Provider<GetExamReadinessUseCase>((ref) {
  return GetExamReadinessUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getStudyPlansUseCaseProvider = Provider<GetStudyPlansUseCase>((ref) {
  return GetStudyPlansUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _createStudyPlanUseCaseProvider =
    Provider<CreateStudyPlanUseCase>((ref) {
  return CreateStudyPlanUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _generateAiStudyPlanUseCaseProvider =
    Provider<GenerateAiStudyPlanUseCase>((ref) {
  return GenerateAiStudyPlanUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _getStudyPlanActivitiesUseCaseProvider =
    Provider<GetStudyPlanActivitiesUseCase>((ref) {
  return GetStudyPlanActivitiesUseCase(ref.watch(examEcosystemRepositoryProvider));
});

final _completeStudyPlanActivityUseCaseProvider =
    Provider<CompleteStudyPlanActivityUseCase>((ref) {
  return CompleteStudyPlanActivityUseCase(ref.watch(examEcosystemRepositoryProvider));
});

// ═══════════════════════════════════════════════════════════════════════
// EXAM ECOSYSTEM STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state for the main Exam Ecosystem feature.
class ExamEcosystemState {
  const ExamEcosystemState({
    this.bodies = const [],
    this.products = const [],
    this.mockExams = const [],
    this.isLoading = false,
    this.error,
    this.selectedBodyId,
    this.selectedProductId,
  });

  final List<ExaminationBody> bodies;
  final List<ExaminationProduct> products;
  final List<MockExam> mockExams;
  final bool isLoading;
  final String? error;
  final String? selectedBodyId;
  final String? selectedProductId;

  /// Get the currently selected body.
  ExaminationBody? get selectedBody => selectedBodyId != null
      ? bodies.where((b) => b.id == selectedBodyId).firstOrNull
      : null;

  /// Get products filtered by selected body.
  List<ExaminationProduct> get filteredProducts => selectedBodyId != null
      ? products.where((p) => p.examBodyId == selectedBodyId).toList()
      : products;

  /// Get mock exams filtered by selected product.
  List<MockExam> get filteredMockExams => selectedProductId != null
      ? mockExams
          .where((m) => m.examinationProductId == selectedProductId)
          .toList()
      : selectedBodyId != null
          ? mockExams
              .where((m) => m.examBodyType == selectedBody?.examBodyType)
              .toList()
          : mockExams;

  ExamEcosystemState copyWith({
    List<ExaminationBody>? bodies,
    List<ExaminationProduct>? products,
    List<MockExam>? mockExams,
    bool? isLoading,
    String? error,
    String? selectedBodyId,
    String? selectedProductId,
    bool clearSelectedBodyId = false,
    bool clearSelectedProductId = false,
    bool clearError = false,
  }) {
    return ExamEcosystemState(
      bodies: bodies ?? this.bodies,
      products: products ?? this.products,
      mockExams: mockExams ?? this.mockExams,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedBodyId: clearSelectedBodyId
          ? null
          : (selectedBodyId ?? this.selectedBodyId),
      selectedProductId: clearSelectedProductId
          ? null
          : (selectedProductId ?? this.selectedProductId),
    );
  }
}

/// Notifier for the Exam Ecosystem feature.
class ExamEcosystemNotifier extends StateNotifier<ExamEcosystemState> {
  ExamEcosystemNotifier({
    required GetExaminationBodiesUseCase getExaminationBodies,
    required GetExaminationProductsUseCase getExaminationProducts,
    required GetMockExamsUseCase getMockExams,
    required ExamEcosystemRepository repository,
  })  : _getExaminationBodies = getExaminationBodies,
        _getExaminationProducts = getExaminationProducts,
        _getMockExams = getMockExams,
        _repository = repository,
        super(const ExamEcosystemState());

  final GetExaminationBodiesUseCase _getExaminationBodies;
  final GetExaminationProductsUseCase _getExaminationProducts;
  final GetMockExamsUseCase _getMockExams;
  final ExamEcosystemRepository _repository;

  /// Loads all initial data (bodies, products, mock exams).
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final results = await Future.wait([
      _getExaminationBodies(const GetExaminationBodiesParams()),
      _getExaminationProducts(const GetExaminationProductsParams()),
      _getMockExams(const GetMockExamsParams()),
    ]);

    final bodiesResult = results[0] as Result<List<ExaminationBody>>;
    final productsResult = results[1] as Result<List<ExaminationProduct>>;
    final mockExamsResult = results[2] as Result<List<MockExam>>;

    bodiesResult.fold(
      onSuccess: (bodies) {
        state = state.copyWith(bodies: bodies);
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );

    productsResult.fold(
      onSuccess: (products) {
        state = state.copyWith(products: products);
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load products: $failure');
      },
    );

    mockExamsResult.fold(
      onSuccess: (mockExams) {
        state = state.copyWith(mockExams: mockExams);
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to load mock exams: $failure');
      },
    );

    state = state.copyWith(isLoading: false);
  }

  /// Select an exam body to filter products.
  Future<void> selectBody(String? bodyId) async {
    state = state.copyWith(
      selectedBodyId: bodyId,
      clearSelectedProductId: bodyId == null,
    );
  }

  /// Select a product to filter mock exams.
  void selectProduct(String? productId) {
    state = state.copyWith(selectedProductId: productId);
  }

  /// Refresh all data.
  Future<void> refresh() async {
    await loadAll();
  }

  /// Clear any error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailure(Failure failure) {
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

/// Provider for the main Exam Ecosystem notifier.
final examEcosystemProvider =
    StateNotifierProvider<ExamEcosystemNotifier, ExamEcosystemState>((ref) {
  return ExamEcosystemNotifier(
    getExaminationBodies: ref.watch(_getExaminationBodiesUseCaseProvider),
    getExaminationProducts: ref.watch(_getExaminationProductsUseCaseProvider),
    getMockExams: ref.watch(_getMockExamsUseCaseProvider),
    repository: ref.watch(examEcosystemRepositoryProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// READINESS STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state for the Readiness feature.
class ReadinessState {
  const ReadinessState({
    this.assessments = const [],
    this.currentAssessment,
    this.isLoading = false,
    this.error,
  });

  final List<ReadinessAssessment> assessments;
  final ReadinessAssessment? currentAssessment;
  final bool isLoading;
  final String? error;

  /// Overall readiness score (average of all assessments).
  double get overallReadinessScore {
    if (assessments.isEmpty) return 0;
    return assessments
            .map((a) => a.readinessScore)
            .reduce((a, b) => a + b) /
        assessments.length;
  }

  /// Average readiness level.
  ReadinessLevel get overallReadinessLevel {
    if (assessments.isEmpty) return ReadinessLevel.notStarted;
    final score = overallReadinessScore;
    if (score >= 90) return ReadinessLevel.examReady;
    if (score >= 75) return ReadinessLevel.advanced;
    if (score >= 60) return ReadinessLevel.proficient;
    if (score >= 40) return ReadinessLevel.developing;
    if (score >= 20) return ReadinessLevel.beginning;
    return ReadinessLevel.notStarted;
  }

  /// All weak topics across assessments.
  List<String> get allWeakTopics =>
      assessments.expand((a) => a.weakTopics).toSet().toList();

  /// All strong topics across assessments.
  List<String> get allStrongTopics =>
      assessments.expand((a) => a.strongTopics).toSet().toList();

  /// All recommendations across assessments.
  List<String> get allRecommendations =>
      assessments.expand((a) => a.recommendations).toSet().toList();

  ReadinessState copyWith({
    List<ReadinessAssessment>? assessments,
    ReadinessAssessment? currentAssessment,
    bool? isLoading,
    String? error,
    bool clearCurrentAssessment = false,
    bool clearError = false,
  }) {
    return ReadinessState(
      assessments: assessments ?? this.assessments,
      currentAssessment: clearCurrentAssessment
          ? null
          : (currentAssessment ?? this.currentAssessment),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for the Readiness feature.
class ReadinessNotifier extends StateNotifier<ReadinessState> {
  ReadinessNotifier({
    required GetReadinessAssessmentUseCase getReadinessAssessment,
    required CalculateReadinessUseCase calculateReadiness,
    required GetExamReadinessUseCase getExamReadiness,
    required ExamEcosystemRepository repository,
    required String? userId,
  })  : _getReadinessAssessment = getReadinessAssessment,
        _calculateReadiness = calculateReadiness,
        _getExamReadiness = getExamReadiness,
        _repository = repository,
        _userId = userId,
        super(const ReadinessState());

  final GetReadinessAssessmentUseCase _getReadinessAssessment;
  final CalculateReadinessUseCase _calculateReadiness;
  final GetExamReadinessUseCase _getExamReadiness;
  final ExamEcosystemRepository _repository;
  final String? _userId;

  /// Load readiness assessments for a user.
  Future<void> loadReadiness({String? examBodyId}) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getUserReadiness(
      userId: _userId,
      examBodyId: examBodyId,
    );

    result.fold(
      onSuccess: (assessments) {
        state = state.copyWith(
          isLoading: false,
          assessments: assessments,
          currentAssessment: assessments.isNotEmpty ? assessments.first : null,
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

  /// Calculate readiness for a specific exam.
  Future<void> calculateReadiness({
    required String examBodyId,
    String? subjectId,
  }) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _calculateReadiness(
      CalculateReadinessParams(
        userId: _userId,
        examBodyId: examBodyId,
        subjectId: subjectId,
      ),
    );

    result.fold(
      onSuccess: (assessment) {
        state = state.copyWith(
          isLoading: false,
          currentAssessment: assessment,
          assessments: [assessment, ...state.assessments],
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

  /// Get exam-level readiness summary.
  Future<void> loadExamReadiness({required String examBodyId}) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getExamReadiness(
      GetExamReadinessParams(userId: _userId, examBodyId: examBodyId),
    );

    result.fold(
      onSuccess: (assessments) {
        state = state.copyWith(
          isLoading: false,
          assessments: assessments,
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

  /// Clear the current error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailure(Failure failure) {
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

/// Provider for the Readiness notifier.
final readinessProvider =
    StateNotifierProvider<ReadinessNotifier, ReadinessState>((ref) {
  return ReadinessNotifier(
    getReadinessAssessment:
        ref.watch(_getReadinessAssessmentUseCaseProvider),
    calculateReadiness: ref.watch(_calculateReadinessUseCaseProvider),
    getExamReadiness: ref.watch(_getExamReadinessUseCaseProvider),
    repository: ref.watch(examEcosystemRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════
// STUDY PLAN STATE & NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state for the Study Plan feature.
class StudyPlanState {
  const StudyPlanState({
    this.plans = const [],
    this.currentPlan,
    this.activities = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  final List<StudyPlan> plans;
  final StudyPlan? currentPlan;
  final List<StudyPlanActivity> activities;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  /// Active plans.
  List<StudyPlan> get activePlans =>
      plans.where((p) => p.isActive).toList();

  /// Current streak from active plan.
  int get currentStreak => currentPlan?.currentStreakDays ?? 0;

  /// Longest streak across all plans.
  int get longestStreak =>
      plans.fold(0, (max, p) => p.longestStreakDays > max ? p.longestStreakDays : max);

  /// Today's activities.
  List<StudyPlanActivity> get todayActivities => activities
      .where((a) => a.isScheduledToday && !a.isCompleted)
      .toList();

  /// Overdue activities.
  List<StudyPlanActivity> get overdueActivities =>
      activities.where((a) => a.isOverdue).toList();

  /// Completed activities.
  List<StudyPlanActivity> get completedActivities =>
      activities.where((a) => a.isCompleted).toList();

  StudyPlanState copyWith({
    List<StudyPlan>? plans,
    StudyPlan? currentPlan,
    List<StudyPlanActivity>? activities,
    bool? isLoading,
    bool? isGenerating,
    String? error,
    bool clearCurrentPlan = false,
    bool clearError = false,
  }) {
    return StudyPlanState(
      plans: plans ?? this.plans,
      currentPlan: clearCurrentPlan
          ? null
          : (currentPlan ?? this.currentPlan),
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for the Study Plan feature.
class StudyPlanNotifier extends StateNotifier<StudyPlanState> {
  StudyPlanNotifier({
    required GetStudyPlansUseCase getStudyPlans,
    required CreateStudyPlanUseCase createStudyPlan,
    required GenerateAiStudyPlanUseCase generateAiStudyPlan,
    required GetStudyPlanActivitiesUseCase getStudyPlanActivities,
    required CompleteStudyPlanActivityUseCase completeStudyPlanActivity,
    required ExamEcosystemRepository repository,
    required String? userId,
  })  : _getStudyPlans = getStudyPlans,
        _createStudyPlan = createStudyPlan,
        _generateAiStudyPlan = generateAiStudyPlan,
        _getStudyPlanActivities = getStudyPlanActivities,
        _completeStudyPlanActivity = completeStudyPlanActivity,
        _repository = repository,
        _userId = userId,
        super(const StudyPlanState());

  final GetStudyPlansUseCase _getStudyPlans;
  final CreateStudyPlanUseCase _createStudyPlan;
  final GenerateAiStudyPlanUseCase _generateAiStudyPlan;
  final GetStudyPlanActivitiesUseCase _getStudyPlanActivities;
  final CompleteStudyPlanActivityUseCase _completeStudyPlanActivity;
  final ExamEcosystemRepository _repository;
  final String? _userId;

  /// Load all study plans for the current user.
  Future<void> loadPlans() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getStudyPlans(
      GetStudyPlansParams(userId: _userId),
    );

    result.fold(
      onSuccess: (plans) {
        state = state.copyWith(
          isLoading: false,
          plans: plans,
          currentPlan: plans.isNotEmpty ? plans.first : null,
        );
        if (plans.isNotEmpty) {
          loadActivities(plans.first.id);
        }
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Load activities for a specific plan.
  Future<void> loadActivities(String planId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getStudyPlanActivities(
      GetStudyPlanActivitiesParams(studyPlanId: planId),
    );

    result.fold(
      onSuccess: (activities) {
        state = state.copyWith(
          isLoading: false,
          activities: activities,
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

  /// Select a plan as the current plan.
  Future<void> selectPlan(StudyPlan plan) async {
    state = state.copyWith(currentPlan: plan);
    await loadActivities(plan.id);
  }

  /// Create a new study plan.
  Future<void> createPlan(StudyPlan plan) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _createStudyPlan(
      CreateStudyPlanParams(studyPlan: plan),
    );

    result.fold(
      onSuccess: (created) {
        state = state.copyWith(
          isLoading: false,
          plans: [created, ...state.plans],
          currentPlan: created,
        );
        loadActivities(created.id);
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Generate an AI study plan.
  Future<void> generateAiPlan({
    required String examBodyId,
    String? subjectId,
    String? educationalLevelId,
    DateTime? targetDate,
    int dailyStudyMinutes = 60,
  }) async {
    if (_userId == null) return;

    state = state.copyWith(isGenerating: true, clearError: true);

    final result = await _generateAiStudyPlan(
      GenerateAiStudyPlanParams(
        userId: _userId,
        examBodyId: examBodyId,
        subjectId: subjectId,
        educationalLevelId: educationalLevelId,
        targetDate: targetDate,
        dailyStudyMinutes: dailyStudyMinutes,
      ),
    );

    result.fold(
      onSuccess: (generated) {
        state = state.copyWith(
          isGenerating: false,
          plans: [generated, ...state.plans],
          currentPlan: generated,
        );
        loadActivities(generated.id);
      },
      onFailure: (failure) {
        state = state.copyWith(
          isGenerating: false,
          error: _mapFailure(failure),
        );
      },
    );
  }

  /// Complete a study plan activity.
  Future<void> completeActivity({
    required String activityId,
    double? performanceScore,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _completeStudyPlanActivity(
      CompleteStudyPlanActivityParams(
        activityId: activityId,
        performanceScore: performanceScore,
        metadata: metadata,
      ),
    );

    result.fold(
      onSuccess: (completed) {
        state = state.copyWith(
          activities: state.activities
              .map((a) => a.id == completed.id ? completed : a)
              .toList(),
        );
      },
      onFailure: (failure) {
        AppLogger.warning('Failed to complete activity: $failure');
      },
    );
  }

  /// Delete a study plan.
  Future<void> deletePlan(String planId) async {
    final result = await _repository.deleteStudyPlan(planId);

    result.fold(
      onSuccess: (_) {
        final updatedPlans =
            state.plans.where((p) => p.id != planId).toList();
        state = state.copyWith(
          plans: updatedPlans,
          currentPlan: state.currentPlan?.id == planId
              ? (updatedPlans.isNotEmpty ? updatedPlans.first : null)
              : state.currentPlan,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(error: _mapFailure(failure));
      },
    );
  }

  /// Clear the current error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailure(Failure failure) {
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

/// Provider for the Study Plan notifier.
final studyPlanProvider =
    StateNotifierProvider<StudyPlanNotifier, StudyPlanState>((ref) {
  return StudyPlanNotifier(
    getStudyPlans: ref.watch(_getStudyPlansUseCaseProvider),
    createStudyPlan: ref.watch(_createStudyPlanUseCaseProvider),
    generateAiStudyPlan: ref.watch(_generateAiStudyPlanUseCaseProvider),
    getStudyPlanActivities: ref.watch(_getStudyPlanActivitiesUseCaseProvider),
    completeStudyPlanActivity:
        ref.watch(_completeStudyPlanActivityUseCaseProvider),
    repository: ref.watch(examEcosystemRepositoryProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});
