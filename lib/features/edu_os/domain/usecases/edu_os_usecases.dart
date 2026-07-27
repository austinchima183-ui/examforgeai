import '../../../../core/utils/result.dart';
import '../entities/edu_os_entities.dart';
import '../repositories/edu_os_repository.dart';

// ============================================================================
// PARAMS
// ============================================================================

class GetModulesParams {
  final ModuleStatus? status;
  final ModuleTier? tier;
  const GetModulesParams({this.status, this.tier});
}

class GetModuleByCodeParams {
  final String code;
  const GetModuleByCodeParams({required this.code});
}

class GetModuleSubscriptionsParams {
  final String schoolId;
  final bool? isEnabled;
  const GetModuleSubscriptionsParams({required this.schoolId, this.isEnabled});
}

class SubscribeModuleParams {
  final String schoolId;
  final String moduleId;
  final ModuleTier tier;
  const SubscribeModuleParams({required this.schoolId, required this.moduleId, required this.tier});
}

class UnsubscribeModuleParams {
  final String subscriptionId;
  const UnsubscribeModuleParams({required this.subscriptionId});
}

class EnableModuleParams {
  final String subscriptionId;
  const EnableModuleParams({required this.subscriptionId});
}

class DisableModuleParams {
  final String subscriptionId;
  const DisableModuleParams({required this.subscriptionId});
}

class GetModuleApisParams {
  final String moduleId;
  const GetModuleApisParams({required this.moduleId});
}

class TrackAnalyticsEventParams {
  final String eventType;
  final Map<String, dynamic> properties;
  const TrackAnalyticsEventParams({required this.eventType, required this.properties});
}

class GetAnalyticsSummaryParams {
  final String schoolId;
  const GetAnalyticsSummaryParams({required this.schoolId});
}

// ============================================================================
// USE CASES
// ============================================================================

class GetModulesUseCase {
  final EduOsRepository _repo;
  GetModulesUseCase(this._repo);
  Future<Result<List<EduosModule>>> call(GetModulesParams p) => _repo.getModules(status: p.status, tier: p.tier);
}

class GetModuleByCodeUseCase {
  final EduOsRepository _repo;
  GetModuleByCodeUseCase(this._repo);
  Future<Result<EduosModule>> call(GetModuleByCodeParams p) => _repo.getModuleByCode(p.code);
}

class GetModuleSubscriptionsUseCase {
  final EduOsRepository _repo;
  GetModuleSubscriptionsUseCase(this._repo);
  Future<Result<List<EduosModuleSubscription>>> call(GetModuleSubscriptionsParams p) => _repo.getModuleSubscriptions(schoolId: p.schoolId, isEnabled: p.isEnabled);
}

class SubscribeModuleUseCase {
  final EduOsRepository _repo;
  SubscribeModuleUseCase(this._repo);
  Future<Result<EduosModuleSubscription>> call(SubscribeModuleParams p) => _repo.subscribeModule(schoolId: p.schoolId, moduleId: p.moduleId, tier: p.tier);
}

class UnsubscribeModuleUseCase {
  final EduOsRepository _repo;
  UnsubscribeModuleUseCase(this._repo);
  Future<Result<bool>> call(UnsubscribeModuleParams p) => _repo.unsubscribeModule(subscriptionId: p.subscriptionId);
}

class EnableModuleUseCase {
  final EduOsRepository _repo;
  EnableModuleUseCase(this._repo);
  Future<Result<EduosModuleSubscription>> call(EnableModuleParams p) => _repo.enableModule(subscriptionId: p.subscriptionId);
}

class DisableModuleUseCase {
  final EduOsRepository _repo;
  DisableModuleUseCase(this._repo);
  Future<Result<EduosModuleSubscription>> call(DisableModuleParams p) => _repo.disableModule(subscriptionId: p.subscriptionId);
}

class GetModuleApisUseCase {
  final EduOsRepository _repo;
  GetModuleApisUseCase(this._repo);
  Future<Result<List<EduosModuleApi>>> call(GetModuleApisParams p) => _repo.getModuleApis(moduleId: p.moduleId);
}

class TrackAnalyticsEventUseCase {
  final EduOsRepository _repo;
  TrackAnalyticsEventUseCase(this._repo);
  Future<Result<bool>> call(TrackAnalyticsEventParams p) => _repo.trackAnalyticsEvent(eventType: p.eventType, properties: p.properties);
}

class GetAnalyticsSummaryUseCase {
  final EduOsRepository _repo;
  GetAnalyticsSummaryUseCase(this._repo);
  Future<Result<Map<String, dynamic>>> call(GetAnalyticsSummaryParams p) => _repo.getAnalyticsSummary(schoolId: p.schoolId);
}
