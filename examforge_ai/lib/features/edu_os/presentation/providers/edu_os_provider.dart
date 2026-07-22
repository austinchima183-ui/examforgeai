import 'package:flutter/foundation.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/edu_os_entities.dart';
import '../../domain/usecases/edu_os_usecases.dart';

/// Provider that manages EduOS feature state.
class EduOsProvider extends ChangeNotifier {
  EduOsProvider({
    required GetModulesUseCase getModules,
    required GetModuleByCodeUseCase getModuleByCode,
    required GetModuleSubscriptionsUseCase getModuleSubscriptions,
    required SubscribeModuleUseCase subscribeModule,
    required UnsubscribeModuleUseCase unsubscribeModule,
    required EnableModuleUseCase enableModule,
    required DisableModuleUseCase disableModule,
    required GetModuleApisUseCase getModuleApis,
    required GetAnalyticsSummaryUseCase getAnalyticsSummary,
  })  : _getModules = getModules,
        _getModuleByCode = getModuleByCode,
        _getModuleSubscriptions = getModuleSubscriptions,
        _subscribeModule = subscribeModule,
        _unsubscribeModule = unsubscribeModule,
        _enableModule = enableModule,
        _disableModule = disableModule,
        _getModuleApis = getModuleApis,
        _getAnalyticsSummary = getAnalyticsSummary;

  final GetModulesUseCase _getModules;
  final GetModuleByCodeUseCase _getModuleByCode;
  final GetModuleSubscriptionsUseCase _getModuleSubscriptions;
  final SubscribeModuleUseCase _subscribeModule;
  final UnsubscribeModuleUseCase _unsubscribeModule;
  final EnableModuleUseCase _enableModule;
  final DisableModuleUseCase _disableModule;
  final GetModuleApisUseCase _getModuleApis;
  final GetAnalyticsSummaryUseCase _getAnalyticsSummary;

  List<EduosModule> _modules = [];
  EduosModule? _selectedModule;
  List<EduosModuleSubscription> _subscriptions = [];
  List<EduosModuleApi> _moduleApis = [];
  Map<String, dynamic>? _analyticsSummary;
  bool _isLoading = false;
  String? _error;

  List<EduosModule> get modules => _modules;
  EduosModule? get selectedModule => _selectedModule;
  List<EduosModuleSubscription> get subscriptions => _subscriptions;
  List<EduosModuleApi> get moduleApis => _moduleApis;
  Map<String, dynamic>? get analyticsSummary => _analyticsSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EduosModule> get activeModules => _modules.where((m) => m.moduleStatus.isActive).toList();
  List<EduosModule> get coreModules => _modules.where((m) => m.isCore).toList();
  List<EduosModule> get premiumModules => _modules.where((m) => m.isPremium).toList();

  String _extractMessage(Failure failure) => failure.when(
    server: (msg, _, __) => msg, cache: (msg) => msg, auth: (msg, _) => msg,
    network: (msg) => msg, validation: (msg, _) => msg, notFound: (msg) => msg,
    unauthorized: (msg) => msg, forbidden: (msg) => msg,
  );

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<void> loadModules({ModuleStatus? status, ModuleTier? tier}) async {
    _setLoading(true); _setError(null);
    final result = await _getModules(GetModulesParams(status: status, tier: tier));
    result.fold(onSuccess: (modules) { _modules = modules; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadModuleByCode(String code) async {
    _setLoading(true); _setError(null);
    final result = await _getModuleByCode(GetModuleByCodeParams(code: code));
    result.fold(onSuccess: (module) { _selectedModule = module; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<void> loadSubscriptions(String schoolId, {bool? isEnabled}) async {
    _setLoading(true); _setError(null);
    final result = await _getModuleSubscriptions(GetModuleSubscriptionsParams(schoolId: schoolId, isEnabled: isEnabled));
    result.fold(onSuccess: (subs) { _subscriptions = subs; _setLoading(false); },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); });
  }

  Future<bool> subscribeToModule(String schoolId, String moduleId, ModuleTier tier) async {
    _setLoading(true); _setError(null);
    final result = await _subscribeModule(SubscribeModuleParams(schoolId: schoolId, moduleId: moduleId, tier: tier));
    return result.fold(onSuccess: (sub) { _subscriptions.add(sub); _setLoading(false); return true; },
      onFailure: (f) { _setError(_extractMessage(f)); _setLoading(false); return false; });
  }

  Future<bool> unsubscribeFromModule(String subscriptionId) async {
    final result = await _unsubscribeModule(UnsubscribeModuleParams(subscriptionId: subscriptionId));
    return result.fold(onSuccess: (_) { _subscriptions.removeWhere((s) => s.id == subscriptionId); notifyListeners(); return true; },
      onFailure: (f) { _setError(_extractMessage(f)); return false; });
  }

  Future<void> toggleModuleEnabled(String subscriptionId, bool enable) async {
    final result = enable
        ? await _enableModule(EnableModuleParams(subscriptionId: subscriptionId))
        : await _disableModule(DisableModuleParams(subscriptionId: subscriptionId));
    result.fold(onSuccess: (sub) {
      final idx = _subscriptions.indexWhere((s) => s.id == subscriptionId);
      if (idx >= 0) _subscriptions[idx] = sub;
      notifyListeners();
    }, onFailure: (f) { _setError(_extractMessage(f)); });
  }

  Future<void> loadModuleApis(String moduleId) async {
    final result = await _getModuleApis(GetModuleApisParams(moduleId: moduleId));
    result.fold(onSuccess: (apis) { _moduleApis = apis; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); });
  }

  Future<void> loadAnalyticsSummary(String schoolId) async {
    final result = await _getAnalyticsSummary(GetAnalyticsSummaryParams(schoolId: schoolId));
    result.fold(onSuccess: (summary) { _analyticsSummary = summary; notifyListeners(); },
      onFailure: (f) { _setError(_extractMessage(f)); });
  }

  void selectModule(EduosModule module) {
    _selectedModule = module;
    notifyListeners();
  }
}
