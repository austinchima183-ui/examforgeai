import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/marketing_entities.dart';
import '../../domain/usecases/marketing_usecases.dart';
import '../../domain/repositories/marketing_repository.dart';
import '../../data/datasources/marketing_remote_datasource.dart';
import '../../data/repositories/marketing_repository_impl.dart';

/// Provider that manages Marketing feature state.
class MarketingProvider extends ChangeNotifier {
  MarketingProvider({
    required GetBlogPostsUseCase getBlogPosts,
    required GetEmailCampaignsUseCase getEmailCampaigns,
    required GetReferralProgramsUseCase getReferralPrograms,
    required GetAffiliatesUseCase getAffiliates,
    required GetLandingPagesUseCase getLandingPages,
  })  : _getBlogPosts = getBlogPosts,
        _getEmailCampaigns = getEmailCampaigns,
        _getReferralPrograms = getReferralPrograms,
        _getAffiliates = getAffiliates,
        _getLandingPages = getLandingPages;

  final GetBlogPostsUseCase _getBlogPosts;
  final GetEmailCampaignsUseCase _getEmailCampaigns;
  final GetReferralProgramsUseCase _getReferralPrograms;
  final GetAffiliatesUseCase _getAffiliates;
  final GetLandingPagesUseCase _getLandingPages;

  List<BlogPost> _blogPosts = [];
  List<EmailCampaign> _emailCampaigns = [];
  List<ReferralProgram> _referralPrograms = [];
  List<Affiliate> _affiliates = [];
  List<LandingPage> _landingPages = [];
  bool _isLoading = false;
  String? _error;

  List<BlogPost> get blogPosts => _blogPosts;
  List<EmailCampaign> get emailCampaigns => _emailCampaigns;
  List<ReferralProgram> get referralPrograms => _referralPrograms;
  List<Affiliate> get affiliates => _affiliates;
  List<LandingPage> get landingPages => _landingPages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _extractMessage(Failure failure) => failure.when(
    server: (msg, _, __) => msg, cache: (msg) => msg, auth: (msg, _) => msg,
    network: (msg) => msg, validation: (msg, _) => msg, notFound: (msg) => msg,
    unauthorized: (msg) => msg, forbidden: (msg) => msg,
  );

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> loadBlogPosts({String? status}) async {
    _setLoading(true); _setError(null);
    final result = await _getBlogPosts(GetBlogPostsParams(status: status));
    result.fold(onSuccess: (posts) { _blogPosts = posts; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadEmailCampaigns({String? status}) async {
    _setLoading(true); _setError(null);
    final result = await _getEmailCampaigns(GetEmailCampaignsParams(status: status));
    result.fold(onSuccess: (campaigns) { _emailCampaigns = campaigns; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadReferralPrograms({String? schoolId}) async {
    _setLoading(true); _setError(null);
    final result = await _getReferralPrograms(GetReferralProgramsParams(schoolId: schoolId, isActive: true));
    result.fold(onSuccess: (programs) { _referralPrograms = programs; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadAffiliates({AffiliateStatus? status}) async {
    _setLoading(true); _setError(null);
    final result = await _getAffiliates(GetAffiliatesParams(status: status));
    result.fold(onSuccess: (affiliates) { _affiliates = affiliates; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadLandingPages() async {
    _setLoading(true); _setError(null);
    final result = await _getLandingPages(const GetLandingPagesParams());
    result.fold(onSuccess: (pages) { _landingPages = pages; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadAll() async {
    await Future.wait([loadBlogPosts(), loadEmailCampaigns(), loadReferralPrograms(), loadAffiliates(), loadLandingPages()]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

final marketingRemoteDatasourceProvider = Provider<MarketingRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MarketingRemoteDatasource(apiClient);
});

final marketingRepositoryProvider = Provider<MarketingRepository>((ref) {
  final datasource = ref.watch(marketingRemoteDatasourceProvider);
  return MarketingRepositoryImpl(datasource);
});

final getBlogPostsUseCaseProvider = Provider<GetBlogPostsUseCase>((ref) {
  final repo = ref.watch(marketingRepositoryProvider);
  return GetBlogPostsUseCase(repo);
});

final getEmailCampaignsUseCaseProvider = Provider<GetEmailCampaignsUseCase>((ref) {
  final repo = ref.watch(marketingRepositoryProvider);
  return GetEmailCampaignsUseCase(repo);
});

final getReferralProgramsUseCaseProvider = Provider<GetReferralProgramsUseCase>((ref) {
  final repo = ref.watch(marketingRepositoryProvider);
  return GetReferralProgramsUseCase(repo);
});

final getAffiliatesUseCaseProvider = Provider<GetAffiliatesUseCase>((ref) {
  final repo = ref.watch(marketingRepositoryProvider);
  return GetAffiliatesUseCase(repo);
});

final getLandingPagesUseCaseProvider = Provider<GetLandingPagesUseCase>((ref) {
  final repo = ref.watch(marketingRepositoryProvider);
  return GetLandingPagesUseCase(repo);
});

final marketingProvider = ChangeNotifierProvider<MarketingProvider>((ref) {
  return MarketingProvider(
    getBlogPosts: ref.watch(getBlogPostsUseCaseProvider),
    getEmailCampaigns: ref.watch(getEmailCampaignsUseCaseProvider),
    getReferralPrograms: ref.watch(getReferralProgramsUseCaseProvider),
    getAffiliates: ref.watch(getAffiliatesUseCaseProvider),
    getLandingPages: ref.watch(getLandingPagesUseCaseProvider),
  );
});
