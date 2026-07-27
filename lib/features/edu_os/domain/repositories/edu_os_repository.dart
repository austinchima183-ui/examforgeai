import '../../../../core/utils/result.dart';
import '../entities/edu_os_entities.dart';

/// Abstract contract for the EduOS repository.
abstract class EduOsRepository {
  Future<Result<List<EduosModule>>> getModules({ModuleStatus? status, ModuleTier? tier});
  Future<Result<EduosModule>> getModuleByCode(String code);
  Future<Result<List<EduosModuleSubscription>>> getModuleSubscriptions({required String schoolId, bool? isEnabled});
  Future<Result<EduosModuleSubscription>> subscribeModule({required String schoolId, required String moduleId, required ModuleTier tier});
  Future<Result<bool>> unsubscribeModule({required String subscriptionId});
  Future<Result<EduosModuleSubscription>> enableModule({required String subscriptionId});
  Future<Result<EduosModuleSubscription>> disableModule({required String subscriptionId});
  Future<Result<List<EduosModuleApi>>> getModuleApis({required String moduleId});
  Future<Result<bool>> trackAnalyticsEvent({required String eventType, required Map<String, dynamic> properties});
  Future<Result<Map<String, dynamic>>> getAnalyticsSummary({required String schoolId});
}
