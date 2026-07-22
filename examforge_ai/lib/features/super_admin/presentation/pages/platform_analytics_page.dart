import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../../config/dependency_injection.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../../domain/usecases/super_admin_usecases.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══ Provider ═══

class AnalyticsState {
  const AnalyticsState({
    this.isLoading = false,
    this.schoolGrowth,
    this.userGrowth,
    this.featureUsage,
    this.storageUsage,
    this.geographicDistribution,
    this.retentionMetrics,
    this.error,
  });
  final bool isLoading;
  final Map<String, dynamic>? schoolGrowth;
  final Map<String, dynamic>? userGrowth;
  final Map<String, dynamic>? featureUsage;
  final Map<String, dynamic>? storageUsage;
  final Map<String, dynamic>? geographicDistribution;
  final Map<String, dynamic>? retentionMetrics;
  final String? error;

  AnalyticsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? schoolGrowth,
    Map<String, dynamic>? userGrowth,
    Map<String, dynamic>? featureUsage,
    Map<String, dynamic>? storageUsage,
    Map<String, dynamic>? geographicDistribution,
    Map<String, dynamic>? retentionMetrics,
    String? error,
  }) => AnalyticsState(
    isLoading: isLoading ?? this.isLoading,
    schoolGrowth: schoolGrowth ?? this.schoolGrowth,
    userGrowth: userGrowth ?? this.userGrowth,
    featureUsage: featureUsage ?? this.featureUsage,
    storageUsage: storageUsage ?? this.storageUsage,
    geographicDistribution: geographicDistribution ?? this.geographicDistribution,
    retentionMetrics: retentionMetrics ?? this.retentionMetrics,
    error: error,
  );
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier({
    required GetSchoolGrowthUseCase schoolGrowthUseCase,
    required GetUserGrowthUseCase userGrowthUseCase,
    required GetFeatureUsageUseCase featureUsageUseCase,
    required GetRetentionMetricsUseCase retentionUseCase,
  })  : _schoolGrowthUseCase = schoolGrowthUseCase,
        _userGrowthUseCase = userGrowthUseCase,
        _featureUsageUseCase = featureUsageUseCase,
        _retentionUseCase = retentionUseCase,
        super(const AnalyticsState());

  final GetSchoolGrowthUseCase _schoolGrowthUseCase;
  final GetUserGrowthUseCase _userGrowthUseCase;
  final GetFeatureUsageUseCase _featureUsageUseCase;
  final GetRetentionMetricsUseCase _retentionUseCase;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.wait([
      _loadSchoolGrowth(),
      _loadUserGrowth(),
      _loadFeatureUsage(),
      _loadRetention(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> _loadSchoolGrowth() async {
    final result = await _schoolGrowthUseCase(const GetPlatformAnalyticsParams());
    result.fold(
      onSuccess: (data) => state = state.copyWith(schoolGrowth: data),
      onFailure: (f) => state = state.copyWith(error: _map(f)),
    );
  }

  Future<void> _loadUserGrowth() async {
    final result = await _userGrowthUseCase(const GetPlatformAnalyticsParams());
    result.fold(
      onSuccess: (data) => state = state.copyWith(userGrowth: data),
      onFailure: (f) => state = state.copyWith(error: _map(f)),
    );
  }

  Future<void> _loadFeatureUsage() async {
    final result = await _featureUsageUseCase(const GetPlatformAnalyticsParams());
    result.fold(
      onSuccess: (data) => state = state.copyWith(featureUsage: data),
      onFailure: (f) => state = state.copyWith(error: _map(f)),
    );
  }

  Future<void> _loadRetention() async {
    final result = await _retentionUseCase();
    result.fold(
      onSuccess: (data) => state = state.copyWith(retentionMetrics: data),
      onFailure: (f) => state = state.copyWith(error: _map(f)),
    );
  }

  String _map(Failure f) => f.when(
    server: (m, _, __) => m, cache: (m) => m, auth: (m, _) => m,
    network: (m) => m, validation: (m, _) => m, notFound: (m) => m,
    unauthorized: (m) => m, forbidden: (m) => m,
  );
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(
    schoolGrowthUseCase: ref.watch(getSchoolGrowthUseCaseProvider),
    userGrowthUseCase: ref.watch(getUserGrowthUseCaseProvider),
    featureUsageUseCase: ref.watch(getFeatureUsageUseCaseProvider),
    retentionUseCase: ref.watch(getRetentionMetricsUseCaseProvider),
  );
});

// ═══ Page ═══

class PlatformAnalyticsPage extends ConsumerStatefulWidget {
  const PlatformAnalyticsPage({super.key});

  @override
  ConsumerState<PlatformAnalyticsPage> createState() => _PlatformAnalyticsPageState();
}

class _PlatformAnalyticsPageState extends ConsumerState<PlatformAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ref.read(analyticsProvider.notifier).loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    return Scaffold(
      appBar: AppAppBar(
        title: 'Platform Analytics',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'School Growth'),
            Tab(text: 'User Growth'),
            Tab(text: 'Feature Usage'),
            Tab(text: 'Retention'),
            Tab(text: 'Geographic'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.schoolGrowth == null
              ? _buildError(state.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _SchoolGrowthTab(data: state.schoolGrowth),
                    _UserGrowthTab(data: state.userGrowth),
                    _FeatureUsageTab(data: state.featureUsage),
                    _RetentionTab(data: state.retentionMetrics),
                    _GeographicTab(data: state.geographicDistribution),
                  ],
                ),
    );
  }

  Widget _buildError(String error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: Spacings.lg),
        Text(error, style: AppTypography.wRegular.copyWith(color: AppColors.error)),
        const SizedBox(height: Spacings.lg),
        FilledButton(onPressed: _loadData, child: const Text('Retry')),
      ],
    ),
  );
}

// ═══ School Growth Tab ═══

class _SchoolGrowthTab extends StatelessWidget {
  const _SchoolGrowthTab({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const AdminEmptyState(message: 'No school growth data available');
    final schools = data!['schools'] as List<dynamic>? ?? data!['data'] as List<dynamic>? ?? [];
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        const SectionHeader(title: 'School Growth Over Time', subtitle: 'Monthly new registrations and total active schools'),
        Spacings.sectionGap,
        if (schools.isEmpty)
          const AdminEmptyState(message: 'No growth data recorded yet')
        else
          ...schools.map((entry) {
            final e = entry as Map<String, dynamic>;
            final month = e['month'] as String? ?? '';
            final newSchools = e['new_schools'] as int? ?? e['newSchools'] as int? ?? 0;
            final totalSchools = e['total_schools'] as int? ?? e['totalSchools'] as int? ?? 0;
            final churned = e['churned_schools'] as int? ?? e['churnedSchools'] as int? ?? 0;
            return Card(
              child: Padding(
                padding: Spacings.paddingAll,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(month, style: AppTypography.wSemiBold.copyWith(fontSize: 14)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('$newSchools', style: AppTypography.wBold.copyWith(fontSize: 18, color: AppColors.success)),
                          Text('New', style: AppTypography.wRegular.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('$totalSchools', style: AppTypography.wBold.copyWith(fontSize: 18, color: AppColors.info)),
                          Text('Total', style: AppTypography.wRegular.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('$churned', style: AppTypography.wBold.copyWith(fontSize: 18, color: churned > 0 ? AppColors.error : AppColors.success)),
                          Text('Churned', style: AppTypography.wRegular.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ═══ User Growth Tab ═══

class _UserGrowthTab extends StatelessWidget {
  const _UserGrowthTab({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const AdminEmptyState(message: 'No user growth data available');
    final users = data!['users'] as List<dynamic>? ?? data!['data'] as List<dynamic>? ?? [];
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        const SectionHeader(title: 'User Growth', subtitle: 'User registrations by role over time'),
        Spacings.sectionGap,
        if (users.isEmpty)
          const AdminEmptyState(message: 'No user data yet')
        else
          ...users.map((entry) {
            final e = entry as Map<String, dynamic>;
            final month = e['month'] as String? ?? '';
            final teachers = e['teachers'] as int? ?? 0;
            final students = e['students'] as int? ?? 0;
            final parents = e['parents'] as int? ?? 0;
            final admins = e['admins'] as int? ?? 0;
            return Card(
              child: Padding(
                padding: Spacings.paddingAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(month, style: AppTypography.wSemiBold.copyWith(fontSize: 14)),
                    const SizedBox(height: Spacings.sm),
                    Row(
                      children: [
                        _UserGrowthChip(label: 'Teachers', count: teachers, color: Colors.teal),
                        const SizedBox(width: Spacings.sm),
                        _UserGrowthChip(label: 'Students', count: students, color: AppColors.info),
                        const SizedBox(width: Spacings.sm),
                        _UserGrowthChip(label: 'Parents', count: parents, color: Colors.purple),
                        const SizedBox(width: Spacings.sm),
                        _UserGrowthChip(label: 'Admins', count: admins, color: Colors.indigo),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _UserGrowthChip extends StatelessWidget {
  const _UserGrowthChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: Spacings.borderRadiusSm,
        ),
        child: Column(
          children: [
            Text('$count', style: AppTypography.wBold.copyWith(fontSize: 16, color: color)),
            Text(label, style: AppTypography.wRegular.copyWith(fontSize: 9, color: color)),
          ],
        ),
      ),
    );
  }
}

// ═══ Feature Usage Tab ═══

class _FeatureUsageTab extends StatelessWidget {
  const _FeatureUsageTab({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const AdminEmptyState(message: 'No feature usage data available');
    final features = data!['features'] as List<dynamic>? ?? data!['data'] as List<dynamic>? ?? [];
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        const SectionHeader(title: 'Feature Usage', subtitle: 'Most used platform features'),
        Spacings.sectionGap,
        if (features.isEmpty)
          const AdminEmptyState(message: 'No feature data yet')
        else
          ...features.map((entry) {
            final e = entry as Map<String, dynamic>;
            final name = e['feature_name'] as String? ?? e['name'] as String? ?? '';
            final usage = e['usage_count'] as int? ?? e['count'] as int? ?? 0;
            final users = e['unique_users'] as int? ?? 0;
            return Card(
              child: ListTile(
                leading: Icon(Icons.stars, color: AppColors.info),
                title: Text(name, style: TextStyle(fontWeight: AppTypography.wSemiBold)),
                subtitle: Text('$users unique users'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text('$usage uses', style: AppTypography.wSemiBold.copyWith(color: AppColors.info, fontSize: 13)),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ═══ Retention Tab ═══

class _RetentionTab extends StatelessWidget {
  const _RetentionTab({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const AdminEmptyState(message: 'No retention data available');
    final overall = data!['overall_retention'] as num?;
    final cohorts = data!['cohorts'] as List<dynamic>? ?? [];
    final churn = data!['churn_rate'] as num?;
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Overall Retention',
                value: overall != null ? '${overall.toStringAsFixed(1)}%' : 'N/A',
                icon: Icons.refresh,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: MetricCard(
                title: 'Churn Rate',
                value: churn != null ? '${churn.toStringAsFixed(1)}%' : 'N/A',
                icon: Icons.trending_down,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        Spacings.sectionGap,
        const SectionHeader(title: 'Retention by Cohort'),
        Spacings.itemGap,
        if (cohorts.isEmpty)
          const AdminEmptyState(message: 'No cohort data yet')
        else
          ...cohorts.map((entry) {
            final e = entry as Map<String, dynamic>;
            final cohort = e['cohort'] as String? ?? '';
            final retention = (e['retention_rate'] as num?)?.toDouble() ?? 0;
            final color = retention >= 80 ? AppColors.success : retention >= 50 ? AppColors.warning : AppColors.error;
            return Card(
              child: Padding(
                padding: Spacings.paddingAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cohort, style: TextStyle(fontWeight: AppTypography.wSemiBold)),
                    const SizedBox(height: Spacings.sm),
                    ClipRRect(
                      borderRadius: Spacings.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: retention / 100,
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text('${retention.toStringAsFixed(1)}% retention', style: AppTypography.wRegular.copyWith(fontSize: 12, color: color)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ═══ Geographic Tab ═══

class _GeographicTab extends StatelessWidget {
  const _GeographicTab({this.data});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const AdminEmptyState(message: 'No geographic data available');
    final regions = data!['regions'] as List<dynamic>? ?? data!['countries'] as List<dynamic>? ?? [];
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        const SectionHeader(title: 'Geographic Distribution', subtitle: 'Schools and users by region'),
        Spacings.sectionGap,
        if (regions.isEmpty)
          const AdminEmptyState(message: 'No geographic data yet')
        else
          ...regions.map((entry) {
            final e = entry as Map<String, dynamic>;
            final name = e['region'] as String? ?? e['country'] as String? ?? '';
            final schools = e['school_count'] as int? ?? 0;
            final users = e['user_count'] as int? ?? 0;
            return Card(
              child: ListTile(
                leading: Icon(Icons.public, color: AppColors.info),
                title: Text(name, style: TextStyle(fontWeight: AppTypography.wSemiBold)),
                subtitle: Text('$schools schools | $users users'),
              ),
            );
          }),
      ],
    );
  }
}
