import '../../../../core/network/api_client.dart';
import '../models/edu_os_models.dart';

/// Remote data source for EduOS feature.
class EduOsRemoteDatasource {
  EduOsRemoteDatasource(this._apiClient);
  final ApiClient _apiClient;
  static const String _basePath = '/edu-os';

  Future<List<EduosModuleModel>> getModules({String? status, String? tier}) async {
    final response = await _apiClient.get('$_basePath/modules', queryParameters: {if (status != null) 'status': status, if (tier != null) 'tier': tier});
    final data = response.data as List?;
    return data?.map((e) => EduosModuleModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<EduosModuleModel> getModuleByCode(String code) async {
    final response = await _apiClient.get('$_basePath/modules/$code');
    return EduosModuleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EduosModuleSubscriptionModel>> getModuleSubscriptions({required String schoolId, bool? isEnabled}) async {
    final response = await _apiClient.get('$_basePath/subscriptions', queryParameters: {'school_id': schoolId, if (isEnabled != null) 'is_enabled': isEnabled});
    final data = response.data as List?;
    return data?.map((e) => EduosModuleSubscriptionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<EduosModuleSubscriptionModel> subscribeModule(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('$_basePath/subscriptions', data: payload);
    return EduosModuleSubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> unsubscribeModule(String subscriptionId) async {
    await _apiClient.delete('$_basePath/subscriptions/$subscriptionId');
  }

  Future<EduosModuleSubscriptionModel> enableModule(String subscriptionId) async {
    final response = await _apiClient.post('$_basePath/subscriptions/$subscriptionId/enable');
    return EduosModuleSubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EduosModuleSubscriptionModel> disableModule(String subscriptionId) async {
    final response = await _apiClient.post('$_basePath/subscriptions/$subscriptionId/disable');
    return EduosModuleSubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<EduosModuleApiModel>> getModuleApis(String moduleId) async {
    final response = await _apiClient.get('$_basePath/modules/$moduleId/apis');
    final data = response.data as List?;
    return data?.map((e) => EduosModuleApiModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
  }

  Future<bool> trackAnalyticsEvent(Map<String, dynamic> payload) async {
    await _apiClient.post('$_basePath/analytics/track', data: payload);
    return true;
  }

  Future<Map<String, dynamic>> getAnalyticsSummary(String schoolId) async {
    final response = await _apiClient.get('$_basePath/analytics/summary', queryParameters: {'school_id': schoolId});
    return Map<String, dynamic>.from(response.data as Map);
  }
}
