import 'package:flutter/foundation.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../../domain/usecases/customer_success_usecases.dart';

/// Provider that manages Customer Success state for the entire feature.
class CustomerSuccessProvider extends ChangeNotifier {
  CustomerSuccessProvider({
    required GetOnboardingFlowsUseCase getOnboardingFlows,
    required GetOnboardingProgressUseCase getOnboardingProgress,
    required CompleteOnboardingStepUseCase completeOnboardingStep,
    required SkipOnboardingStepUseCase skipOnboardingStep,
    required GetProductToursUseCase getProductTours,
    required GetHelpArticlesUseCase getHelpArticles,
    required SearchHelpArticlesUseCase searchHelpArticles,
    required GetVideoTutorialsUseCase getVideoTutorials,
    required SubmitFeedbackUseCase submitFeedback,
    required GetFeedbackSubmissionsUseCase getFeedbackSubmissions,
    required GetFeatureRequestsUseCase getFeatureRequests,
    required CreateFeatureRequestUseCase createFeatureRequest,
    required VoteFeatureRequestUseCase voteFeatureRequest,
    required GetFeatureRequestVotesUseCase getFeatureRequestVotes,
  })  : _getOnboardingFlows = getOnboardingFlows,
        _getOnboardingProgress = getOnboardingProgress,
        _completeOnboardingStep = completeOnboardingStep,
        _skipOnboardingStep = skipOnboardingStep,
        _getProductTours = getProductTours,
        _getHelpArticles = getHelpArticles,
        _searchHelpArticles = searchHelpArticles,
        _getVideoTutorials = getVideoTutorials,
        _submitFeedback = submitFeedback,
        _getFeedbackSubmissions = getFeedbackSubmissions,
        _getFeatureRequests = getFeatureRequests,
        _createFeatureRequest = createFeatureRequest,
        _voteFeatureRequest = voteFeatureRequest,
        _getFeatureRequestVotes = getFeatureRequestVotes;

  // ─── Use Cases ────────────────────────────────────────────────────
  final GetOnboardingFlowsUseCase _getOnboardingFlows;
  final GetOnboardingProgressUseCase _getOnboardingProgress;
  final CompleteOnboardingStepUseCase _completeOnboardingStep;
  final SkipOnboardingStepUseCase _skipOnboardingStep;
  final GetProductToursUseCase _getProductTours;
  final GetHelpArticlesUseCase _getHelpArticles;
  final SearchHelpArticlesUseCase _searchHelpArticles;
  final GetVideoTutorialsUseCase _getVideoTutorials;
  final SubmitFeedbackUseCase _submitFeedback;
  final GetFeedbackSubmissionsUseCase _getFeedbackSubmissions;
  final GetFeatureRequestsUseCase _getFeatureRequests;
  final CreateFeatureRequestUseCase _createFeatureRequest;
  final VoteFeatureRequestUseCase _voteFeatureRequest;
  final GetFeatureRequestVotesUseCase _getFeatureRequestVotes;

  // ─── State ────────────────────────────────────────────────────────
  List<OnboardingFlow> _onboardingFlows = [];
  List<OnboardingProgress> _onboardingProgress = [];
  List<ProductTour> _productTours = [];
  List<HelpArticle> _helpArticles = [];
  List<VideoTutorial> _videoTutorials = [];
  List<FeedbackSubmission> _feedbackSubmissions = [];
  List<FeatureRequest> _featureRequests = [];
  List<String> _userVotes = [];
  bool _isLoading = false;
  String? _error;
  int _currentOnboardingStep = 0;

  // ─── Getters ──────────────────────────────────────────────────────
  List<OnboardingFlow> get onboardingFlows => _onboardingFlows;
  List<OnboardingProgress> get onboardingProgress => _onboardingProgress;
  List<ProductTour> get productTours => _productTours;
  List<HelpArticle> get helpArticles => _helpArticles;
  List<VideoTutorial> get videoTutorials => _videoTutorials;
  List<FeedbackSubmission> get feedbackSubmissions => _feedbackSubmissions;
  List<FeatureRequest> get featureRequests => _featureRequests;
  List<String> get userVotes => _userVotes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentOnboardingStep => _currentOnboardingStep;

  double get onboardingCompletionPercentage {
    if (_onboardingFlows.isEmpty) return 0.0;
    final completedCount = _onboardingProgress.where((p) => p.isCompleted).length;
    return completedCount / _onboardingFlows.length;
  }

  // ─── Methods ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // ─── Onboarding ───────────────────────────────────────────────────

  Future<void> loadOnboardingFlows(String role) async {
    _setLoading(true);
    _setError(null);
    final result = await _getOnboardingFlows(GetOnboardingFlowsParams(role: role));
    result.fold(
      onSuccess: (flows) {
        _onboardingFlows = flows;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  Future<void> loadOnboardingProgress(String userId) async {
    final result = await _getOnboardingProgress(GetOnboardingProgressParams(userId: userId));
    result.fold(
      onSuccess: (progress) {
        _onboardingProgress = progress;
        notifyListeners();
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
      },
    );
  }

  Future<void> completeStep(String userId, String flowId, {Map<String, dynamic>? data}) async {
    final result = await _completeOnboardingStep(CompleteOnboardingStepParams(
      userId: userId,
      onboardingFlowId: flowId,
      data: data,
    ));
    result.fold(
      onSuccess: (progress) {
        final idx = _onboardingProgress.indexWhere((p) => p.onboardingFlowId == flowId);
        if (idx >= 0) {
          _onboardingProgress[idx] = progress;
        } else {
          _onboardingProgress.add(progress);
        }
        if (_currentOnboardingStep < _onboardingFlows.length - 1) {
          _currentOnboardingStep++;
        }
        notifyListeners();
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
      },
    );
  }

  Future<void> skipStep(String userId, String flowId) async {
    final result = await _skipOnboardingStep(SkipOnboardingStepParams(
      userId: userId,
      onboardingFlowId: flowId,
    ));
    result.fold(
      onSuccess: (progress) {
        final idx = _onboardingProgress.indexWhere((p) => p.onboardingFlowId == flowId);
        if (idx >= 0) {
          _onboardingProgress[idx] = progress;
        } else {
          _onboardingProgress.add(progress);
        }
        if (_currentOnboardingStep < _onboardingFlows.length - 1) {
          _currentOnboardingStep++;
        }
        notifyListeners();
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
      },
    );
  }

  void setCurrentOnboardingStep(int step) {
    _currentOnboardingStep = step;
    notifyListeners();
  }

  // ─── Product Tours ────────────────────────────────────────────────

  Future<void> loadProductTours(String targetRole) async {
    _setLoading(true);
    _setError(null);
    final result = await _getProductTours(GetProductToursParams(targetRole: targetRole));
    result.fold(
      onSuccess: (tours) {
        _productTours = tours;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  // ─── Help Articles ────────────────────────────────────────────────

  Future<void> loadHelpArticles({String? category, String? tag}) async {
    _setLoading(true);
    _setError(null);
    final result = await _getHelpArticles(GetHelpArticlesParams(category: category, tag: tag));
    result.fold(
      onSuccess: (articles) {
        _helpArticles = articles;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  Future<void> searchHelpArticles(String query) async {
    _setLoading(true);
    _setError(null);
    final result = await _searchHelpArticles(SearchHelpArticlesParams(query: query));
    result.fold(
      onSuccess: (articles) {
        _helpArticles = articles;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  // ─── Video Tutorials ──────────────────────────────────────────────

  Future<void> loadVideoTutorials({String? category, String? targetRole}) async {
    _setLoading(true);
    _setError(null);
    final result = await _getVideoTutorials(GetVideoTutorialsParams(category: category, targetRole: targetRole));
    result.fold(
      onSuccess: (tutorials) {
        _videoTutorials = tutorials;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  // ─── Feedback ─────────────────────────────────────────────────────

  Future<bool> submitFeedback({
    required String userId,
    required FeedbackType feedbackType,
    required String subject,
    required String description,
    String priority = 'medium',
    List<String> attachments = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    _setLoading(true);
    _setError(null);
    final result = await _submitFeedback(SubmitFeedbackParams(
      userId: userId,
      feedbackType: feedbackType,
      subject: subject,
      description: description,
      priority: priority,
      attachments: attachments,
      metadata: metadata,
    ));
    return result.fold(
      onSuccess: (submission) {
        _feedbackSubmissions.insert(0, submission);
        _setLoading(false);
        return true;
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
        return false;
      },
    );
  }

  Future<void> loadFeedbackSubmissions(String userId, {String? status}) async {
    _setLoading(true);
    _setError(null);
    final result = await _getFeedbackSubmissions(GetFeedbackSubmissionsParams(userId: userId, status: status));
    result.fold(
      onSuccess: (submissions) {
        _feedbackSubmissions = submissions;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  // ─── Feature Requests ─────────────────────────────────────────────

  Future<void> loadFeatureRequests({String? status, String? category, String sortBy = 'upvotes'}) async {
    _setLoading(true);
    _setError(null);
    final result = await _getFeatureRequests(GetFeatureRequestsParams(status: status, category: category, sortBy: sortBy));
    result.fold(
      onSuccess: (requests) {
        _featureRequests = requests;
        _setLoading(false);
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
      },
    );
  }

  Future<bool> createFeatureRequest({
    required String userId,
    required String title,
    required String description,
    required String category,
  }) async {
    _setLoading(true);
    _setError(null);
    final result = await _createFeatureRequest(CreateFeatureRequestParams(
      userId: userId,
      title: title,
      description: description,
      category: category,
    ));
    return result.fold(
      onSuccess: (request) {
        _featureRequests.insert(0, request);
        _setLoading(false);
        return true;
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
        _setLoading(false);
        return false;
      },
    );
  }

  Future<void> voteForFeatureRequest(String featureRequestId, String userId) async {
    final result = await _voteFeatureRequest(VoteFeatureRequestParams(
      featureRequestId: featureRequestId,
      userId: userId,
    ));
    result.fold(
      onSuccess: (updated) {
        final idx = _featureRequests.indexWhere((r) => r.id == featureRequestId);
        if (idx >= 0) {
          _featureRequests[idx] = updated;
        }
        if (!_userVotes.contains(featureRequestId)) {
          _userVotes.add(featureRequestId);
        }
        notifyListeners();
      },
      onFailure: (failure) {
        _setError(failure.when(
          server: (msg, _, __) => msg,
          cache: (msg) => msg,
          auth: (msg, _) => msg,
          network: (msg) => msg,
          validation: (msg, _) => msg,
          notFound: (msg) => msg,
          unauthorized: (msg) => msg,
          forbidden: (msg) => msg,
        ));
      },
    );
  }

  Future<void> loadUserVotes(String userId) async {
    final result = await _getFeatureRequestVotes(GetFeatureRequestVotesParams(userId: userId));
    result.fold(
      onSuccess: (votes) {
        _userVotes = votes;
        notifyListeners();
      },
      onFailure: (_) {},
    );
  }
}
