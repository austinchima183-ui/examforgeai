import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../../domain/usecases/super_admin_usecases.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DASHBOARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class DashboardState {
  const DashboardState({
    this.isLoading = false,
    this.metrics,
    this.error,
  });
  final bool isLoading;
  final DashboardMetrics? metrics;
  final String? error;

  DashboardState copyWith({bool? isLoading, DashboardMetrics? metrics, String? error}) =>
      DashboardState(isLoading: isLoading ?? this.isLoading, metrics: metrics ?? this.metrics, error: error);
  DashboardState clearError() => DashboardState(isLoading: isLoading, metrics: metrics);
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({required GetDashboardMetricsUseCase getDashboardMetricsUseCase})
      : _getDashboardMetricsUseCase = getDashboardMetricsUseCase, super(const DashboardState());

  final GetDashboardMetricsUseCase _getDashboardMetricsUseCase;

  Future<void> loadMetrics({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getDashboardMetricsUseCase(GetDashboardMetricsParams(forceRefresh: forceRefresh));
    result.fold(
      onSuccess: (metrics) => state = state.copyWith(isLoading: false, metrics: metrics),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailure(failure)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLATFORM SETTINGS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class PlatformSettingsState {
  const PlatformSettingsState({
    this.isLoading = false, this.settings = const [], this.error, this.successMessage,
  });
  final bool isLoading;
  final List<PlatformSetting> settings;
  final String? error;
  final String? successMessage;

  PlatformSettingsState copyWith({
    bool? isLoading, List<PlatformSetting>? settings, String? error, String? successMessage,
  }) => PlatformSettingsState(
    isLoading: isLoading ?? this.isLoading, settings: settings ?? this.settings,
    error: error, successMessage: successMessage,
  );
  PlatformSettingsState clearError() => copyWith(error: null);
  PlatformSettingsState clearSuccess() => copyWith(successMessage: null);
}

class PlatformSettingsNotifier extends StateNotifier<PlatformSettingsState> {
  PlatformSettingsNotifier({
    required GetPlatformSettingsUseCase getSettingsUseCase,
    required UpdatePlatformSettingUseCase updateSettingUseCase,
    required BulkUpdateSettingsUseCase bulkUpdateUseCase,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _updateSettingUseCase = updateSettingUseCase,
        _bulkUpdateUseCase = bulkUpdateUseCase,
        super(const PlatformSettingsState());

  final GetPlatformSettingsUseCase _getSettingsUseCase;
  final UpdatePlatformSettingUseCase _updateSettingUseCase;
  final BulkUpdateSettingsUseCase _bulkUpdateUseCase;

  Future<void> loadSettings({SettingScope? scope}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSettingsUseCase(GetPlatformSettingsParams(scope: scope));
    result.fold(
      onSuccess: (settings) => state = state.copyWith(isLoading: false, settings: settings),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> updateSetting(PlatformSetting setting) async {
    final result = await _updateSettingUseCase(UpdatePlatformSettingParams(setting: setting));
    result.fold(
      onSuccess: (updated) {
        final newList = state.settings.map((s) => s.id == updated.id ? updated : s).toList();
        state = state.copyWith(settings: newList, successMessage: 'Setting updated successfully');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> bulkUpdate(List<PlatformSetting> settings) async {
    final result = await _bulkUpdateUseCase(BulkUpdateSettingsParams(settings: settings));
    result.fold(
      onSuccess: (updated) => state = state.copyWith(settings: updated, successMessage: 'Settings updated successfully'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEATURE FLAGS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class FeatureFlagsState {
  const FeatureFlagsState({
    this.isLoading = false, this.flags = const [], this.error, this.successMessage,
  });
  final bool isLoading;
  final List<FeatureFlag> flags;
  final String? error;
  final String? successMessage;

  FeatureFlagsState copyWith({
    bool? isLoading, List<FeatureFlag>? flags, String? error, String? successMessage,
  }) => FeatureFlagsState(
    isLoading: isLoading ?? this.isLoading, flags: flags ?? this.flags,
    error: error, successMessage: successMessage,
  );
  FeatureFlagsState clearError() => copyWith(error: null);
  FeatureFlagsState clearSuccess() => copyWith(successMessage: null);
}

class FeatureFlagsNotifier extends StateNotifier<FeatureFlagsState> {
  FeatureFlagsNotifier({
    required GetFeatureFlagsUseCase getFlagsUseCase,
    required CreateFeatureFlagUseCase createFlagUseCase,
    required UpdateFeatureFlagUseCase updateFlagUseCase,
    required ToggleFeatureFlagUseCase toggleFlagUseCase,
  })  : _getFlagsUseCase = getFlagsUseCase, _createFlagUseCase = createFlagUseCase,
        _updateFlagUseCase = updateFlagUseCase, _toggleFlagUseCase = toggleFlagUseCase,
        super(const FeatureFlagsState());

  final GetFeatureFlagsUseCase _getFlagsUseCase;
  final CreateFeatureFlagUseCase _createFlagUseCase;
  final UpdateFeatureFlagUseCase _updateFlagUseCase;
  final ToggleFeatureFlagUseCase _toggleFlagUseCase;

  Future<void> loadFlags({bool? isActive}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getFlagsUseCase(GetFeatureFlagsParams(isActive: isActive));
    result.fold(
      onSuccess: (flags) => state = state.copyWith(isLoading: false, flags: flags),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> createFlag(FeatureFlag flag) async {
    final result = await _createFlagUseCase(CreateFeatureFlagParams(flag: flag));
    result.fold(
      onSuccess: (newFlag) => state = state.copyWith(flags: [...state.flags, newFlag], successMessage: 'Flag created'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> toggleFlag(String flagId, bool isActive) async {
    final result = await _toggleFlagUseCase(ToggleFeatureFlagParams(flagId: flagId, isActive: isActive));
    result.fold(
      onSuccess: (updated) {
        final newList = state.flags.map((f) => f.id == updated.id ? updated : f).toList();
        state = state.copyWith(flags: newList, successMessage: 'Flag ${isActive ? "enabled" : "disabled"}');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class SchoolManagementState {
  const SchoolManagementState({
    this.isLoading = false, this.schools = const [], this.selectedSchool,
    this.totalCount = 0, this.error, this.successMessage,
  });
  final bool isLoading;
  final List<SchoolManagementDetail> schools;
  final SchoolManagementDetail? selectedSchool;
  final int totalCount;
  final String? error;
  final String? successMessage;

  SchoolManagementState copyWith({
    bool? isLoading, List<SchoolManagementDetail>? schools,
    SchoolManagementDetail? selectedSchool, int? totalCount,
    String? error, String? successMessage,
  }) => SchoolManagementState(
    isLoading: isLoading ?? this.isLoading, schools: schools ?? this.schools,
    selectedSchool: selectedSchool ?? this.selectedSchool, totalCount: totalCount ?? this.totalCount,
    error: error, successMessage: successMessage,
  );
  SchoolManagementState clearError() => copyWith(error: null);
  SchoolManagementState clearSuccess() => copyWith(successMessage: null);
}

class SchoolManagementNotifier extends StateNotifier<SchoolManagementState> {
  SchoolManagementNotifier({
    required GetSchoolsUseCase getSchoolsUseCase,
    required CreateSchoolUseCase createSchoolUseCase,
    required SuspendSchoolUseCase suspendSchoolUseCase,
    required ReactivateSchoolUseCase reactivateSchoolUseCase,
    required VerifySchoolUseCase verifySchoolUseCase,
  })  : _getSchoolsUseCase = getSchoolsUseCase, _createSchoolUseCase = createSchoolUseCase,
        _suspendSchoolUseCase = suspendSchoolUseCase, _reactivateSchoolUseCase = reactivateSchoolUseCase,
        _verifySchoolUseCase = verifySchoolUseCase, super(const SchoolManagementState());

  final GetSchoolsUseCase _getSchoolsUseCase;
  final CreateSchoolUseCase _createSchoolUseCase;
  final SuspendSchoolUseCase _suspendSchoolUseCase;
  final ReactivateSchoolUseCase _reactivateSchoolUseCase;
  final VerifySchoolUseCase _verifySchoolUseCase;

  Future<void> loadSchools({bool? isActive, bool? isVerified, String? search, String? subscriptionStatus, int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSchoolsUseCase(GetSchoolsParams(
      isActive: isActive, isVerified: isVerified, search: search,
      subscriptionStatus: subscriptionStatus, limit: limit, offset: offset,
    ));
    result.fold(
      onSuccess: (schools) => state = state.copyWith(isLoading: false, schools: schools),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> createSchool(Map<String, dynamic> data) async {
    final result = await _createSchoolUseCase(CreateSchoolParams(schoolData: data));
    result.fold(
      onSuccess: (school) => state = state.copyWith(schools: [school, ...state.schools], successMessage: 'School created successfully'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> suspendSchool(String schoolId, String reason) async {
    final result = await _suspendSchoolUseCase(ManageSchoolParams(schoolId: schoolId, reason: reason));
    result.fold(
      onSuccess: (_) {
        final updated = state.schools.map((s) => s.id == schoolId ? s.copyWith(isActive: false) : s).toList();
        state = state.copyWith(schools: updated, successMessage: 'School suspended');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> reactivateSchool(String schoolId) async {
    final result = await _reactivateSchoolUseCase(ManageSchoolParams(schoolId: schoolId));
    result.fold(
      onSuccess: (_) {
        final updated = state.schools.map((s) => s.id == schoolId ? s.copyWith(isActive: true) : s).toList();
        state = state.copyWith(schools: updated, successMessage: 'School reactivated');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> verifySchool(String schoolId) async {
    final result = await _verifySchoolUseCase(ManageSchoolParams(schoolId: schoolId));
    result.fold(
      onSuccess: (_) {
        final updated = state.schools.map((s) => s.id == schoolId ? s.copyWith(isVerified: true) : s).toList();
        state = state.copyWith(schools: updated, successMessage: 'School verified');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class UserManagementState {
  const UserManagementState({
    this.isLoading = false, this.users = const [], this.totalCount = 0,
    this.error, this.successMessage, this.impersonationSession,
  });
  final bool isLoading;
  final List<UserManagementDetail> users;
  final int totalCount;
  final String? error;
  final String? successMessage;
  final ImpersonationSession? impersonationSession;

  UserManagementState copyWith({
    bool? isLoading, List<UserManagementDetail>? users, int? totalCount,
    String? error, String? successMessage, ImpersonationSession? impersonationSession,
  }) => UserManagementState(
    isLoading: isLoading ?? this.isLoading, users: users ?? this.users,
    totalCount: totalCount ?? this.totalCount, error: error,
    successMessage: successMessage, impersonationSession: impersonationSession ?? this.impersonationSession,
  );
  UserManagementState clearError() => copyWith(error: null);
  UserManagementState clearSuccess() => copyWith(successMessage: null);
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  UserManagementNotifier({
    required GetUsersUseCase getUsersUseCase,
    required SuspendUserUseCase suspendUserUseCase,
    required ActivateUserUseCase activateUserUseCase,
    required ResetUserPasswordUseCase resetPasswordUseCase,
    required ChangeUserRoleUseCase changeRoleUseCase,
    required StartImpersonationUseCase startImpersonationUseCase,
    required EndImpersonationUseCase endImpersonationUseCase,
  })  : _getUsersUseCase = getUsersUseCase, _suspendUserUseCase = suspendUserUseCase,
        _activateUserUseCase = activateUserUseCase, _resetPasswordUseCase = resetPasswordUseCase,
        _changeRoleUseCase = changeRoleUseCase, _startImpersonationUseCase = startImpersonationUseCase,
        _endImpersonationUseCase = endImpersonationUseCase, super(const UserManagementState());

  final GetUsersUseCase _getUsersUseCase;
  final SuspendUserUseCase _suspendUserUseCase;
  final ActivateUserUseCase _activateUserUseCase;
  final ResetUserPasswordUseCase _resetPasswordUseCase;
  final ChangeUserRoleUseCase _changeRoleUseCase;
  final StartImpersonationUseCase _startImpersonationUseCase;
  final EndImpersonationUseCase _endImpersonationUseCase;

  Future<void> loadUsers({String? role, String? schoolId, bool? isActive, String? search, int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getUsersUseCase(GetUsersParams(role: role, schoolId: schoolId, isActive: isActive, search: search, limit: limit, offset: offset));
    result.fold(
      onSuccess: (users) => state = state.copyWith(isLoading: false, users: users),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> suspendUser(String userId, String reason) async {
    final result = await _suspendUserUseCase(ManageUserParams(userId: userId, reason: reason));
    result.fold(
      onSuccess: (_) {
        final updated = state.users.map((u) => u.id == userId ? u.copyWith(isActive: false) : u).toList();
        state = state.copyWith(users: updated, successMessage: 'User suspended');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> activateUser(String userId) async {
    final result = await _activateUserUseCase(ManageUserParams(userId: userId));
    result.fold(
      onSuccess: (_) {
        final updated = state.users.map((u) => u.id == userId ? u.copyWith(isActive: true) : u).toList();
        state = state.copyWith(users: updated, successMessage: 'User activated');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> resetPassword(String userId) async {
    final result = await _resetPasswordUseCase(ManageUserParams(userId: userId));
    result.fold(
      onSuccess: (_) => state = state.copyWith(successMessage: 'Password reset email sent'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> changeRole(String userId, String newRole) async {
    final result = await _changeRoleUseCase(ManageUserParams(userId: userId, newRole: newRole));
    result.fold(
      onSuccess: (_) {
        final updated = state.users.map((u) => u.id == userId ? u.copyWith(role: newRole) : u).toList();
        state = state.copyWith(users: updated, successMessage: 'Role updated');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> startImpersonation(String targetUserId, String reason) async {
    final result = await _startImpersonationUseCase(StartImpersonationParams(targetUserId: targetUserId, reason: reason));
    result.fold(
      onSuccess: (session) => state = state.copyWith(impersonationSession: session, successMessage: 'Impersonation started'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> endImpersonation(String sessionId) async {
    final result = await _endImpersonationUseCase(EndImpersonationParams(sessionId: sessionId));
    result.fold(
      onSuccess: (_) => state = state.copyWith(impersonationSession: null, successMessage: 'Impersonation ended'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// AI MANAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class AIManagementState {
  const AIManagementState({
    this.isLoading = false, this.providers = const [], this.requestLogs = const [],
    this.usageAnalytics, this.error, this.successMessage,
  });
  final bool isLoading;
  final List<AIProvider> providers;
  final List<AIRequestLog> requestLogs;
  final Map<String, dynamic>? usageAnalytics;
  final String? error;
  final String? successMessage;

  AIManagementState copyWith({
    bool? isLoading, List<AIProvider>? providers, List<AIRequestLog>? requestLogs,
    Map<String, dynamic>? usageAnalytics, String? error, String? successMessage,
  }) => AIManagementState(
    isLoading: isLoading ?? this.isLoading, providers: providers ?? this.providers,
    requestLogs: requestLogs ?? this.requestLogs, usageAnalytics: usageAnalytics ?? this.usageAnalytics,
    error: error, successMessage: successMessage,
  );
  AIManagementState clearError() => copyWith(error: null);
  AIManagementState clearSuccess() => copyWith(successMessage: null);
}

class AIManagementNotifier extends StateNotifier<AIManagementState> {
  AIManagementNotifier({
    required GetAIProvidersUseCase getProvidersUseCase,
    required CreateAIProviderUseCase createProviderUseCase,
    required UpdateAIProviderUseCase updateProviderUseCase,
    required SetDefaultProviderUseCase setDefaultUseCase,
    required ToggleProviderUseCase toggleProviderUseCase,
    required GetAIRequestLogsUseCase getRequestLogsUseCase,
  })  : _getProvidersUseCase = getProvidersUseCase, _createProviderUseCase = createProviderUseCase,
        _updateProviderUseCase = updateProviderUseCase, _setDefaultUseCase = setDefaultUseCase,
        _toggleProviderUseCase = toggleProviderUseCase, _getRequestLogsUseCase = getRequestLogsUseCase,
        super(const AIManagementState());

  final GetAIProvidersUseCase _getProvidersUseCase;
  final CreateAIProviderUseCase _createProviderUseCase;
  final UpdateAIProviderUseCase _updateProviderUseCase;
  final SetDefaultProviderUseCase _setDefaultUseCase;
  final ToggleProviderUseCase _toggleProviderUseCase;
  final GetAIRequestLogsUseCase _getRequestLogsUseCase;

  Future<void> loadProviders({bool? isActive}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getProvidersUseCase(isActive: isActive);
    result.fold(
      onSuccess: (providers) => state = state.copyWith(isLoading: false, providers: providers),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> createProvider(AIProvider provider) async {
    final result = await _createProviderUseCase(UpsertAIProviderParams(provider: provider));
    result.fold(
      onSuccess: (p) => state = state.copyWith(providers: [...state.providers, p], successMessage: 'Provider created'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> updateProvider(AIProvider provider) async {
    final result = await _updateProviderUseCase(UpsertAIProviderParams(provider: provider));
    result.fold(
      onSuccess: (updated) {
        final newList = state.providers.map((p) => p.id == updated.id ? updated : p).toList();
        state = state.copyWith(providers: newList, successMessage: 'Provider updated');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> setDefault(String providerId) async {
    final result = await _setDefaultUseCase(SetDefaultProviderParams(providerId: providerId));
    result.fold(
      onSuccess: (updated) {
        final newList = state.providers.map((p) => p.id == updated.id ? updated : p.copyWith(isDefault: false)).toList();
        state = state.copyWith(providers: newList, successMessage: 'Default provider set');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> toggleProvider(String providerId, bool isActive) async {
    final result = await _toggleProviderUseCase(ToggleProviderParams(providerId: providerId, isActive: isActive));
    result.fold(
      onSuccess: (updated) {
        final newList = state.providers.map((p) => p.id == updated.id ? updated : p).toList();
        state = state.copyWith(providers: newList, successMessage: 'Provider ${isActive ? "enabled" : "disabled"}');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> loadRequestLogs({String? providerId, DateTime? startDate, DateTime? endDate, int limit = 50}) async {
    final result = await _getRequestLogsUseCase(GetAIRequestLogsParams(
      providerId: providerId, startDate: startDate, endDate: endDate, limit: limit,
    ));
    result.fold(
      onSuccess: (logs) => state = state.copyWith(requestLogs: logs),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORT CENTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class SupportCenterState {
  const SupportCenterState({
    this.isLoading = false, this.tickets = const [], this.selectedTicket,
    this.comments = const [], this.error, this.successMessage,
  });
  final bool isLoading;
  final List<SupportTicket> tickets;
  final SupportTicket? selectedTicket;
  final List<TicketComment> comments;
  final String? error;
  final String? successMessage;

  SupportCenterState copyWith({
    bool? isLoading, List<SupportTicket>? tickets, SupportTicket? selectedTicket,
    List<TicketComment>? comments, String? error, String? successMessage,
  }) => SupportCenterState(
    isLoading: isLoading ?? this.isLoading, tickets: tickets ?? this.tickets,
    selectedTicket: selectedTicket ?? this.selectedTicket, comments: comments ?? this.comments,
    error: error, successMessage: successMessage,
  );
  SupportCenterState clearError() => copyWith(error: null);
  SupportCenterState clearSuccess() => copyWith(successMessage: null);
}

class SupportCenterNotifier extends StateNotifier<SupportCenterState> {
  SupportCenterNotifier({
    required GetSupportTicketsUseCase getTicketsUseCase,
    required AssignTicketUseCase assignTicketUseCase,
    required EscalateTicketUseCase escalateTicketUseCase,
    required ResolveTicketUseCase resolveTicketUseCase,
  })  : _getTicketsUseCase = getTicketsUseCase, _assignTicketUseCase = assignTicketUseCase,
        _escalateTicketUseCase = escalateTicketUseCase, _resolveTicketUseCase = resolveTicketUseCase,
        super(const SupportCenterState());

  final GetSupportTicketsUseCase _getTicketsUseCase;
  final AssignTicketUseCase _assignTicketUseCase;
  final EscalateTicketUseCase _escalateTicketUseCase;
  final ResolveTicketUseCase _resolveTicketUseCase;

  Future<void> loadTickets({TicketStatus? status, TicketPriority? priority, String? search, int limit = 50}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getTicketsUseCase(GetSupportTicketsParams(status: status, priority: priority, search: search, limit: limit));
    result.fold(
      onSuccess: (tickets) => state = state.copyWith(isLoading: false, tickets: tickets),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> assignTicket(String ticketId, String assignToUserId) async {
    final result = await _assignTicketUseCase(AssignTicketParams(ticketId: ticketId, assignToUserId: assignToUserId));
    result.fold(
      onSuccess: (updated) {
        final newList = state.tickets.map((t) => t.id == updated.id ? updated : t).toList();
        state = state.copyWith(tickets: newList, successMessage: 'Ticket assigned');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> resolveTicket(String ticketId, String resolutionNotes) async {
    final result = await _resolveTicketUseCase(ResolveTicketParams(ticketId: ticketId, resolutionNotes: resolutionNotes));
    result.fold(
      onSuccess: (updated) {
        final newList = state.tickets.map((t) => t.id == updated.id ? updated : t).toList();
        state = state.copyWith(tickets: newList, successMessage: 'Ticket resolved');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// INTELLIGENCE PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class IntelligenceState {
  const IntelligenceState({
    this.isLoading = false, this.alerts = const [], this.churnPredictions,
    this.revenueForecast, this.costOptimizations, this.engagementInsights,
    this.error, this.successMessage,
  });
  final bool isLoading;
  final List<IntelligenceAlert> alerts;
  final Map<String, dynamic>? churnPredictions;
  final Map<String, dynamic>? revenueForecast;
  final Map<String, dynamic>? costOptimizations;
  final Map<String, dynamic>? engagementInsights;
  final String? error;
  final String? successMessage;

  IntelligenceState copyWith({
    bool? isLoading, List<IntelligenceAlert>? alerts,
    Map<String, dynamic>? churnPredictions, Map<String, dynamic>? revenueForecast,
    Map<String, dynamic>? costOptimizations, Map<String, dynamic>? engagementInsights,
    String? error, String? successMessage,
  }) => IntelligenceState(
    isLoading: isLoading ?? this.isLoading, alerts: alerts ?? this.alerts,
    churnPredictions: churnPredictions ?? this.churnPredictions,
    revenueForecast: revenueForecast ?? this.revenueForecast,
    costOptimizations: costOptimizations ?? this.costOptimizations,
    engagementInsights: engagementInsights ?? this.engagementInsights,
    error: error, successMessage: successMessage,
  );
  IntelligenceState clearError() => copyWith(error: null);
  IntelligenceState clearSuccess() => copyWith(successMessage: null);
}

class IntelligenceNotifier extends StateNotifier<IntelligenceState> {
  IntelligenceNotifier({
    required GetIntelligenceAlertsUseCase getAlertsUseCase,
    required AcknowledgeAlertUseCase acknowledgeAlertUseCase,
    required ResolveAlertUseCase resolveAlertUseCase,
    required GenerateIntelligenceInsightsUseCase generateInsightsUseCase,
    required GetChurnPredictionsUseCase getChurnPredictionsUseCase,
    required GetRevenueForecastUseCase getRevenueForecastUseCase,
    required GetCostOptimizationsUseCase getCostOptimizationsUseCase,
  })  : _getAlertsUseCase = getAlertsUseCase, _acknowledgeAlertUseCase = acknowledgeAlertUseCase,
        _resolveAlertUseCase = resolveAlertUseCase, _generateInsightsUseCase = generateInsightsUseCase,
        _getChurnPredictionsUseCase = getChurnPredictionsUseCase,
        _getRevenueForecastUseCase = getRevenueForecastUseCase,
        _getCostOptimizationsUseCase = getCostOptimizationsUseCase,
        super(const IntelligenceState());

  final GetIntelligenceAlertsUseCase _getAlertsUseCase;
  final AcknowledgeAlertUseCase _acknowledgeAlertUseCase;
  final ResolveAlertUseCase _resolveAlertUseCase;
  final GenerateIntelligenceInsightsUseCase _generateInsightsUseCase;
  final GetChurnPredictionsUseCase _getChurnPredictionsUseCase;
  final GetRevenueForecastUseCase _getRevenueForecastUseCase;
  final GetCostOptimizationsUseCase _getCostOptimizationsUseCase;

  Future<void> loadAlerts({IntelligenceAlertType? type, IntelligenceSeverity? severity, bool unresolvedOnly = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAlertsUseCase(GetIntelligenceAlertsParams(
      alertType: type, severity: severity, unresolvedOnly: unresolvedOnly,
    ));
    result.fold(
      onSuccess: (alerts) => state = state.copyWith(isLoading: false, alerts: alerts),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final result = await _acknowledgeAlertUseCase(AcknowledgeAlertParams(alertId: alertId));
    result.fold(
      onSuccess: (updated) {
        final newList = state.alerts.map((a) => a.id == updated.id ? updated : a).toList();
        state = state.copyWith(alerts: newList, successMessage: 'Alert acknowledged');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> resolveAlert(String alertId, String notes) async {
    final result = await _resolveAlertUseCase(ResolveAlertParams(alertId: alertId, resolutionNotes: notes));
    result.fold(
      onSuccess: (updated) {
        final newList = state.alerts.map((a) => a.id == updated.id ? updated : a).toList();
        state = state.copyWith(alerts: newList, successMessage: 'Alert resolved');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> generateInsights() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _generateInsightsUseCase();
    result.fold(
      onSuccess: (alerts) => state = state.copyWith(isLoading: false, alerts: alerts, successMessage: 'Insights generated'),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> loadChurnPredictions({int limit = 20}) async {
    final result = await _getChurnPredictionsUseCase(GetChurnPredictionsParams(limit: limit));
    result.fold(
      onSuccess: (data) => state = state.copyWith(churnPredictions: data),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> loadRevenueForecast({int monthsAhead = 6}) async {
    final result = await _getRevenueForecastUseCase(GetRevenueForecastParams(monthsAhead: monthsAhead));
    result.fold(
      onSuccess: (data) => state = state.copyWith(revenueForecast: data),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> loadCostOptimizations() async {
    final result = await _getCostOptimizationsUseCase();
    result.fold(
      onSuccess: (data) => state = state.copyWith(costOptimizations: data),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER DECLARATIONS — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

/// Dashboard provider — loads and exposes platform-wide metrics.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    getDashboardMetricsUseCase: ref.watch(getDashboardMetricsUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER DECLARATIONS — AI MANAGEMENT & INTELLIGENCE
// ═══════════════════════════════════════════════════════════════════════════════

/// AI Management provider — monitors and controls AI providers.
final aiManagementProvider =
    StateNotifierProvider<AIManagementNotifier, AIManagementState>((ref) {
  return AIManagementNotifier(
    getProvidersUseCase: ref.watch(getAIProvidersUseCaseProvider),
    createProviderUseCase: ref.watch(createAIProviderUseCaseProvider),
    updateProviderUseCase: ref.watch(updateAIProviderUseCaseProvider),
    setDefaultUseCase: ref.watch(setDefaultProviderUseCaseProvider),
    toggleProviderUseCase: ref.watch(toggleProviderUseCaseProvider),
    getRequestLogsUseCase: ref.watch(getAIRequestLogsUseCaseProvider),
  );
});

/// Intelligence provider — alerts, churn prediction, revenue forecast, cost optimization.
final intelligenceProvider =
    StateNotifierProvider<IntelligenceNotifier, IntelligenceState>((ref) {
  return IntelligenceNotifier(
    getAlertsUseCase: ref.watch(getIntelligenceAlertsUseCaseProvider),
    acknowledgeAlertUseCase: ref.watch(acknowledgeAlertUseCaseProvider),
    resolveAlertUseCase: ref.watch(resolveAlertUseCaseProvider),
    generateInsightsUseCase: ref.watch(generateIntelligenceInsightsUseCaseProvider),
    getChurnPredictionsUseCase: ref.watch(getChurnPredictionsUseCaseProvider),
    getRevenueForecastUseCase: ref.watch(getRevenueForecastUseCaseProvider),
    getCostOptimizationsUseCase: ref.watch(getCostOptimizationsUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY CENTER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class SecurityCenterState {
  const SecurityCenterState({
    this.isLoading = false, this.loginEntries = const [], this.activeSessions = const [],
    this.suspiciousActivity = const [], this.auditLogs = const [],
    this.error, this.successMessage,
  });
  final bool isLoading;
  final List<LoginMonitoringEntry> loginEntries;
  final List<ActiveSession> activeSessions;
  final List<Map<String, dynamic>> suspiciousActivity;
  final List<AuditLog> auditLogs;
  final String? error;
  final String? successMessage;

  SecurityCenterState copyWith({
    bool? isLoading, List<LoginMonitoringEntry>? loginEntries,
    List<ActiveSession>? activeSessions, List<Map<String, dynamic>>? suspiciousActivity,
    List<AuditLog>? auditLogs, String? error, String? successMessage,
  }) => SecurityCenterState(
    isLoading: isLoading ?? this.isLoading, loginEntries: loginEntries ?? this.loginEntries,
    activeSessions: activeSessions ?? this.activeSessions,
    suspiciousActivity: suspiciousActivity ?? this.suspiciousActivity,
    auditLogs: auditLogs ?? this.auditLogs, error: error, successMessage: successMessage,
  );
  SecurityCenterState clearError() => copyWith(error: null);
  SecurityCenterState clearSuccess() => copyWith(successMessage: null);
}

class SecurityCenterNotifier extends StateNotifier<SecurityCenterState> {
  SecurityCenterNotifier({
    required GetLoginMonitoringUseCase getLoginMonitoringUseCase,
    required DetectSuspiciousActivityUseCase detectSuspiciousUseCase,
    required LockUserAccountUseCase lockAccountUseCase,
    required UnlockUserAccountUseCase unlockAccountUseCase,
    required GetAuditLogsUseCase getAuditLogsUseCase,
  })  : _getLoginMonitoringUseCase = getLoginMonitoringUseCase,
        _detectSuspiciousUseCase = detectSuspiciousUseCase,
        _lockAccountUseCase = lockAccountUseCase,
        _unlockAccountUseCase = unlockAccountUseCase,
        _getAuditLogsUseCase = getAuditLogsUseCase,
        super(const SecurityCenterState());

  final GetLoginMonitoringUseCase _getLoginMonitoringUseCase;
  final DetectSuspiciousActivityUseCase _detectSuspiciousUseCase;
  final LockUserAccountUseCase _lockAccountUseCase;
  final UnlockUserAccountUseCase _unlockAccountUseCase;
  final GetAuditLogsUseCase _getAuditLogsUseCase;

  Future<void> loadLoginMonitoring({bool failedOnly = false, int limit = 50}) async {
    final result = await _getLoginMonitoringUseCase(GetLoginMonitoringParams(failedOnly: failedOnly, limit: limit));
    result.fold(
      onSuccess: (entries) => state = state.copyWith(loginEntries: entries),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> detectSuspicious({int lookbackHours = 24}) async {
    final result = await _detectSuspiciousUseCase(DetectSuspiciousActivityParams(lookbackHours: lookbackHours));
    result.fold(
      onSuccess: (data) => state = state.copyWith(suspiciousActivity: data),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> lockAccount(String userId, String reason) async {
    final result = await _lockAccountUseCase(LockUserAccountParams(userId: userId, reason: reason));
    result.fold(
      onSuccess: (_) => state = state.copyWith(successMessage: 'Account locked'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> unlockAccount(String userId) async {
    final result = await _unlockAccountUseCase(UnlockUserAccountParams(userId: userId));
    result.fold(
      onSuccess: (_) => state = state.copyWith(successMessage: 'Account unlocked'),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> loadAuditLogs({AuditCategory? category, int limit = 50}) async {
    final result = await _getAuditLogsUseCase(GetAuditLogsParams(category: category, limit: limit));
    result.fold(
      onSuccess: (logs) => state = state.copyWith(auditLogs: logs),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class AdminNotificationState {
  const AdminNotificationState({
    this.isLoading = false, this.notifications = const [], this.unreadCount = 0, this.error,
  });
  final bool isLoading;
  final List<PlatformNotification> notifications;
  final int unreadCount;
  final String? error;

  AdminNotificationState copyWith({
    bool? isLoading, List<PlatformNotification>? notifications, int? unreadCount, String? error,
  }) => AdminNotificationState(
    isLoading: isLoading ?? this.isLoading, notifications: notifications ?? this.notifications,
    unreadCount: unreadCount ?? this.unreadCount, error: error,
  );
}

class AdminNotificationNotifier extends StateNotifier<AdminNotificationState> {
  AdminNotificationNotifier({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkNotificationReadUseCase markReadUseCase,
    required GetUnreadNotificationCountUseCase getUnreadCountUseCase,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markReadUseCase = markReadUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        super(const AdminNotificationState());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;
  final GetUnreadNotificationCountUseCase _getUnreadCountUseCase;

  Future<void> loadNotifications({bool unreadOnly = false, int limit = 50}) async {
    state = state.copyWith(isLoading: true);
    final result = await _getNotificationsUseCase(GetNotificationsParams(unreadOnly: unreadOnly, limit: limit));
    result.fold(
      onSuccess: (notifs) => state = state.copyWith(isLoading: false, notifications: notifs),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: f.when(
        server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
        network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
        unauthorized: (m) => m, forbidden: (m) => m,
      )),
    );
  }

  Future<void> markRead(String notificationId) async {
    final result = await _markReadUseCase(notificationId);
    result.fold(
      onSuccess: (updated) {
        final newList = state.notifications.map((n) => n.id == updated.id ? updated : n).toList();
        state = state.copyWith(notifications: newList, unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0);
      },
      onFailure: (_) {},
    );
  }

  Future<void> loadUnreadCount() async {
    final result = await _getUnreadCountUseCase();
    result.fold(
      onSuccess: (count) => state = state.copyWith(unreadCount: count),
      onFailure: (_) {},
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE MONITORING PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class InfrastructureMonitoringState {
  const InfrastructureMonitoringState({
    this.isLoading = false,
    this.services = const [],
    this.maintenanceWindows = const [],
    this.error,
    this.successMessage,
    this.runningHealthCheckFor,
  });
  final bool isLoading;
  final List<InfrastructureService> services;
  final List<MaintenanceWindow> maintenanceWindows;
  final String? error;
  final String? successMessage;
  final String? runningHealthCheckFor; // serviceId currently being checked

  InfrastructureMonitoringState copyWith({
    bool? isLoading,
    List<InfrastructureService>? services,
    List<MaintenanceWindow>? maintenanceWindows,
    String? error,
    String? successMessage,
    String? runningHealthCheckFor,
  }) =>
      InfrastructureMonitoringState(
        isLoading: isLoading ?? this.isLoading,
        services: services ?? this.services,
        maintenanceWindows: maintenanceWindows ?? this.maintenanceWindows,
        error: error,
        successMessage: successMessage,
        runningHealthCheckFor: runningHealthCheckFor,
      );
  InfrastructureMonitoringState clearError() => copyWith(error: null);
  InfrastructureMonitoringState clearSuccess() => copyWith(successMessage: null);
}

class InfrastructureMonitoringNotifier
    extends StateNotifier<InfrastructureMonitoringState> {
  InfrastructureMonitoringNotifier({
    required GetInfrastructureServicesUseCase getServicesUseCase,
    required RunHealthCheckUseCase runHealthCheckUseCase,
    required GetMaintenanceWindowsUseCase getMaintenanceWindowsUseCase,
    required CreateMaintenanceWindowUseCase createMaintenanceWindowUseCase,
    required CancelMaintenanceWindowUseCase cancelMaintenanceWindowUseCase,
  })  : _getServicesUseCase = getServicesUseCase,
        _runHealthCheckUseCase = runHealthCheckUseCase,
        _getMaintenanceWindowsUseCase = getMaintenanceWindowsUseCase,
        _createMaintenanceWindowUseCase = createMaintenanceWindowUseCase,
        _cancelMaintenanceWindowUseCase = cancelMaintenanceWindowUseCase,
        super(const InfrastructureMonitoringState());

  final GetInfrastructureServicesUseCase _getServicesUseCase;
  final RunHealthCheckUseCase _runHealthCheckUseCase;
  final GetMaintenanceWindowsUseCase _getMaintenanceWindowsUseCase;
  final CreateMaintenanceWindowUseCase _createMaintenanceWindowUseCase;
  final CancelMaintenanceWindowUseCase _cancelMaintenanceWindowUseCase;

  Future<void> loadServices() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getServicesUseCase();
    result.fold(
      onSuccess: (services) =>
          state = state.copyWith(isLoading: false, services: services),
      onFailure: (f) =>
          state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> loadMaintenanceWindows({MaintenanceStatus? status}) async {
    final result =
        await _getMaintenanceWindowsUseCase(GetMaintenanceWindowsParams(status: status));
    result.fold(
      onSuccess: (windows) =>
          state = state.copyWith(maintenanceWindows: windows),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> runHealthCheck({String? serviceId}) async {
    state = state.copyWith(runningHealthCheckFor: serviceId ?? '__all__');
    final result = await _runHealthCheckUseCase(
        RunHealthCheckParams(serviceId: serviceId));
    state = state.copyWith(runningHealthCheckFor: null);
    result.fold(
      onSuccess: (_) {
        state = state.copyWith(successMessage: serviceId != null
            ? 'Health check completed'
            : 'All health checks completed');
        // Refresh services after health check
        loadServices();
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> createMaintenanceWindow(MaintenanceWindow window) async {
    final result = await _createMaintenanceWindowUseCase(
        CreateMaintenanceWindowParams(window: window));
    result.fold(
      onSuccess: (newWindow) => state = state.copyWith(
        maintenanceWindows: [newWindow, ...state.maintenanceWindows],
        successMessage: 'Maintenance window scheduled',
      ),
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> cancelMaintenanceWindow(String windowId) async {
    final result = await _cancelMaintenanceWindowUseCase(
        CancelMaintenanceWindowParams(windowId: windowId));
    result.fold(
      onSuccess: (_) {
        final updated = state.maintenanceWindows
            .map((w) => w.id == windowId
                ? w.copyWith(status: MaintenanceStatus.cancelled)
                : w)
            .toList();
        state = state.copyWith(
          maintenanceWindows: updated,
          successMessage: 'Maintenance window cancelled',
        );
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
        server: (m, _, __) => m,
        cache: (m) => m,
        auth: (m, _) => m,
        network: (m) => m,
        validation: (m, _) => m,
        notFound: (m) => m,
        unauthorized: (m) => m,
        forbidden: (m) => m,
      );
}

/// Infrastructure monitoring provider.
final infrastructureMonitoringProvider = StateNotifierProvider<
    InfrastructureMonitoringNotifier, InfrastructureMonitoringState>((ref) {
  return InfrastructureMonitoringNotifier(
    getServicesUseCase:
        ref.watch(getInfrastructureServicesUseCaseProvider),
    runHealthCheckUseCase: ref.watch(runHealthCheckUseCaseProvider),
    getMaintenanceWindowsUseCase:
        ref.watch(getMaintenanceWindowsUseCaseProvider),
    createMaintenanceWindowUseCase:
        ref.watch(createMaintenanceWindowUseCaseProvider),
    cancelMaintenanceWindowUseCase:
        ref.watch(cancelMaintenanceWindowUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// BILLING MANAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class BillingManagementState {
  const BillingManagementState({
    this.isLoading = false,
    this.revenueAnalytics,
    this.error,
    this.successMessage,
  });
  final bool isLoading;
  final RevenueAnalytics? revenueAnalytics;
  final String? error;
  final String? successMessage;

  BillingManagementState copyWith({
    bool? isLoading,
    RevenueAnalytics? revenueAnalytics,
    String? error,
    String? successMessage,
  }) =>
      BillingManagementState(
        isLoading: isLoading ?? this.isLoading,
        revenueAnalytics: revenueAnalytics ?? this.revenueAnalytics,
        error: error,
        successMessage: successMessage,
      );
  BillingManagementState clearError() => copyWith(error: null);
  BillingManagementState clearSuccess() => copyWith(successMessage: null);
}

class BillingManagementNotifier
    extends StateNotifier<BillingManagementState> {
  BillingManagementNotifier({
    required GetRevenueAnalyticsUseCase getRevenueAnalyticsUseCase,
  })  : _getRevenueAnalyticsUseCase = getRevenueAnalyticsUseCase,
        super(const BillingManagementState());

  final GetRevenueAnalyticsUseCase _getRevenueAnalyticsUseCase;

  Future<void> loadRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getRevenueAnalyticsUseCase(
      GetRevenueAnalyticsParams(startDate: startDate, endDate: endDate),
    );
    result.fold(
      onSuccess: (analytics) =>
          state = state.copyWith(isLoading: false, revenueAnalytics: analytics),
      onFailure: (f) =>
          state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
        server: (m, _, __) => m,
        cache: (m) => m,
        auth: (m, _) => m,
        network: (m) => m,
        validation: (m, _) => m,
        notFound: (m) => m,
        unauthorized: (m) => m,
        forbidden: (m) => m,
      );
}

/// Billing management provider.
final billingManagementProvider = StateNotifierProvider<
    BillingManagementNotifier, BillingManagementState>((ref) {
  return BillingManagementNotifier(
    getRevenueAnalyticsUseCase:
        ref.watch(getRevenueAnalyticsUseCaseProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE MANAGEMENT PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class MarketplaceManagementState {
  const MarketplaceManagementState({
    this.isLoading = false,
    this.pendingContent = const [],
    this.allContent = const [],
    this.totalCount = 0,
    this.error,
    this.successMessage,
  });
  final bool isLoading;
  final List<MarketplaceContent> pendingContent;
  final List<MarketplaceContent> allContent;
  final int totalCount;
  final String? error;
  final String? successMessage;

  MarketplaceManagementState copyWith({
    bool? isLoading,
    List<MarketplaceContent>? pendingContent,
    List<MarketplaceContent>? allContent,
    int? totalCount,
    String? error,
    String? successMessage,
  }) => MarketplaceManagementState(
    isLoading: isLoading ?? this.isLoading,
    pendingContent: pendingContent ?? this.pendingContent,
    allContent: allContent ?? this.allContent,
    totalCount: totalCount ?? this.totalCount,
    error: error,
    successMessage: successMessage,
  );
  MarketplaceManagementState clearError() => copyWith(error: null);
  MarketplaceManagementState clearSuccess() => copyWith(successMessage: null);
}

class MarketplaceManagementNotifier extends StateNotifier<MarketplaceManagementState> {
  MarketplaceManagementNotifier({
    required GetMarketplaceContentUseCase getContentUseCase,
    required ApproveContentUseCase approveContentUseCase,
    required RejectContentUseCase rejectContentUseCase,
    required FeatureContentUseCase featureContentUseCase,
  })  : _getContentUseCase = getContentUseCase,
        _approveContentUseCase = approveContentUseCase,
        _rejectContentUseCase = rejectContentUseCase,
        _featureContentUseCase = featureContentUseCase,
        super(const MarketplaceManagementState());

  final GetMarketplaceContentUseCase _getContentUseCase;
  final ApproveContentUseCase _approveContentUseCase;
  final RejectContentUseCase _rejectContentUseCase;
  final FeatureContentUseCase _featureContentUseCase;

  Future<void> loadPendingContent() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContentUseCase(
      GetMarketplaceContentParams(status: 'pending_review', limit: 100),
    );
    result.fold(
      onSuccess: (content) => state = state.copyWith(isLoading: false, pendingContent: content),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> loadAllContent({MarketplaceStatus? status, MarketplaceContentType? contentType, String? search, int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContentUseCase(
      GetMarketplaceContentParams(
        status: status?.value,
        contentType: contentType?.value,
        search: search,
        limit: limit,
        offset: offset,
      ),
    );
    result.fold(
      onSuccess: (content) => state = state.copyWith(isLoading: false, allContent: content),
      onFailure: (f) => state = state.copyWith(isLoading: false, error: _mapFailure(f)),
    );
  }

  Future<void> approveContent(String contentId) async {
    final result = await _approveContentUseCase(ModerateContentParams(contentId: contentId));
    result.fold(
      onSuccess: (updated) {
        final newPending = state.pendingContent.where((c) => c.id != contentId).toList();
        final newAll = state.allContent.map((c) => c.id == updated.id ? updated : c).toList();
        state = state.copyWith(pendingContent: newPending, allContent: newAll, successMessage: 'Content approved');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> rejectContent(String contentId, String reason) async {
    final result = await _rejectContentUseCase(ModerateContentParams(contentId: contentId, reason: reason));
    result.fold(
      onSuccess: (updated) {
        final newPending = state.pendingContent.where((c) => c.id != contentId).toList();
        final newAll = state.allContent.map((c) => c.id == updated.id ? updated : c).toList();
        state = state.copyWith(pendingContent: newPending, allContent: newAll, successMessage: 'Content rejected');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  Future<void> featureContent(String contentId) async {
    final result = await _featureContentUseCase(ModerateContentParams(contentId: contentId));
    result.fold(
      onSuccess: (updated) {
        final newPending = state.pendingContent.where((c) => c.id != contentId).toList();
        final newAll = state.allContent.map((c) => c.id == updated.id ? updated : c).toList();
        state = state.copyWith(pendingContent: newPending, allContent: newAll, successMessage: 'Content featured');
      },
      onFailure: (f) => state = state.copyWith(error: _mapFailure(f)),
    );
  }

  String _mapFailure(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// RIVERPOD PROVIDER DECLARATIONS — SETTINGS, FLAGS, MARKETPLACE
// ═══════════════════════════════════════════════════════════════════════════════

/// Platform Settings provider — manages global configuration values.
final platformSettingsProvider =
    StateNotifierProvider<PlatformSettingsNotifier, PlatformSettingsState>((ref) {
  return PlatformSettingsNotifier(
    getSettingsUseCase: ref.watch(getPlatformSettingsUseCaseProvider),
    updateSettingUseCase: ref.watch(updatePlatformSettingUseCaseProvider),
    bulkUpdateUseCase: ref.watch(bulkUpdateSettingsUseCaseProvider),
  );
});

/// Feature Flags provider — manages feature flag toggles and rollout.
final featureFlagsProvider =
    StateNotifierProvider<FeatureFlagsNotifier, FeatureFlagsState>((ref) {
  return FeatureFlagsNotifier(
    getFlagsUseCase: ref.watch(getFeatureFlagsUseCaseProvider),
    createFlagUseCase: ref.watch(createFeatureFlagUseCaseProvider),
    updateFlagUseCase: ref.watch(updateFeatureFlagUseCaseProvider),
    toggleFlagUseCase: ref.watch(toggleFeatureFlagUseCaseProvider),
  );
});

/// Marketplace Management provider — moderates marketplace content.
final marketplaceManagementProvider =
    StateNotifierProvider<MarketplaceManagementNotifier, MarketplaceManagementState>((ref) {
  return MarketplaceManagementNotifier(
    getContentUseCase: ref.watch(getMarketplaceContentUseCaseProvider),
    approveContentUseCase: ref.watch(approveContentUseCaseProvider),
    rejectContentUseCase: ref.watch(rejectContentUseCaseProvider),
    featureContentUseCase: ref.watch(featureContentUseCaseProvider),
  );
});
