import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// INTELLIGENCE CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Operations Intelligence Center with AI — the "game-changer" feature.
///
/// Provides AI-driven operational insights through four tabs:
/// - **Alerts**: Intelligence alerts with filtering and acknowledge/resolve actions
/// - **Churn Prediction**: Schools at risk of churning with probability scores
/// - **Revenue Forecast**: 6-month revenue prediction with confidence intervals
/// - **Cost Optimization**: AI provider cost analysis and optimization suggestions
class IntelligenceCenterPage extends ConsumerStatefulWidget {
  const IntelligenceCenterPage({super.key});

  @override
  ConsumerState<IntelligenceCenterPage> createState() =>
      _IntelligenceCenterPageState();
}

class _IntelligenceCenterPageState
    extends ConsumerState<IntelligenceCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ─── Alert Filters ──────────────────────────────────────────────────────

  IntelligenceAlertType? _filterAlertType;
  IntelligenceSeverity? _filterSeverity;

  static const _tabs = [
    Tab(icon: Icon(Icons.notification_important), text: 'Alerts'),
    Tab(icon: Icon(Icons.person_off), text: 'Churn Prediction'),
    Tab(icon: Icon(Icons.show_chart), text: 'Revenue Forecast'),
    Tab(icon: Icon(Icons.savings), text: 'Cost Optimization'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTabData(_tabController.index);
    }
  }

  void _loadData() {
    _loadTabData(_tabController.index);
  }

  void _loadTabData(int index) {
    final notifier = ref.read(intelligenceProvider.notifier);
    switch (index) {
      case 0:
        notifier.loadAlerts(
          type: _filterAlertType,
          severity: _filterSeverity,
          unresolvedOnly: false,
        );
        break;
      case 1:
        notifier.loadChurnPredictions();
        break;
      case 2:
        notifier.loadRevenueForecast();
        break;
      case 3:
        notifier.loadCostOptimizations();
        break;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intelligenceProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error snackbar messages
    ref.listen<IntelligenceState>(intelligenceProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(intelligenceProvider.notifier).state =
            ref.read(intelligenceProvider).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(intelligenceProvider.notifier).state =
            ref.read(intelligenceProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Intelligence Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Insights',
            onPressed: () {
              ref.read(intelligenceProvider.notifier).generateInsights();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: state.isLoading && state.alerts.isEmpty
          ? const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null && state.alerts.isEmpty
              ? _buildErrorState(state.error!, cs)
              : Column(
                  children: [
                    // ─── Tab Bar ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: _tabs,
                        labelColor: cs.primary,
                        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.6),
                        indicatorColor: cs.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                        isScrollable: true,
                      ),
                    ),

                    // ─── Tab Content ──────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _AlertsTab(
                            filterAlertType: _filterAlertType,
                            filterSeverity: _filterSeverity,
                            onAlertTypeChanged: (type) {
                              setState(() => _filterAlertType = type);
                              ref.read(intelligenceProvider.notifier).loadAlerts(
                                    type: type,
                                    severity: _filterSeverity,
                                    unresolvedOnly: false,
                                  );
                            },
                            onSeverityChanged: (severity) {
                              setState(() => _filterSeverity = severity);
                              ref.read(intelligenceProvider.notifier).loadAlerts(
                                    type: _filterAlertType,
                                    severity: severity,
                                    unresolvedOnly: false,
                                  );
                            },
                            onAcknowledge: (alertId) {
                              ref.read(intelligenceProvider.notifier).acknowledgeAlert(alertId);
                            },
                            onResolve: (alertId) {
                              ref.read(intelligenceProvider.notifier).resolveAlert(alertId, 'Resolved via Intelligence Center');
                            },
                          ),
                          _ChurnPredictionTab(churnPredictions: state.churnPredictions),
                          _RevenueForecastTab(revenueForecast: state.revenueForecast),
                          _CostOptimizationTab(costOptimizations: state.costOptimizations),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorState(String error, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: Spacings.xlIcon, color: cs.error),
            const SizedBox(height: Spacings.lg),
            Text(
              error,
              style: AppTypography.wRegular.copyWith(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.lg),
            FilledButton.tonal(
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ALERTS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({
    required this.filterAlertType,
    required this.filterSeverity,
    required this.onAlertTypeChanged,
    required this.onSeverityChanged,
    required this.onAcknowledge,
    required this.onResolve,
  });

  final IntelligenceAlertType? filterAlertType;
  final IntelligenceSeverity? filterSeverity;
  final ValueChanged<IntelligenceAlertType?> onAlertTypeChanged;
  final ValueChanged<IntelligenceSeverity?> onSeverityChanged;
  final ValueChanged<String> onAcknowledge;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    // We need a ref here to read the state, but since this is a StatelessWidget
    // in a ConsumerStatefulWidget, the parent will handle state. However, we
    // need alerts from the provider. We'll use Consumer.
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(intelligenceProvider);
      final cs = Theme.of(context).colorScheme;

      return SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Generate Insights Button ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI-Generated Alerts',
                    style: AppTypography.wBold.copyWith(fontSize: 18),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(intelligenceProvider.notifier).generateInsights();
                  },
                  icon: const Icon(Icons.auto_awesome, size: Spacings.smIcon),
                  label: const Text('Generate Insights'),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Filters ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert Type',
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      FilterChipGroup<IntelligenceAlertType>(
                        items: IntelligenceAlertType.values.toList(),
                        selected: filterAlertType,
                        onSelected: onAlertTypeChanged,
                        labelBuilder: (type) => type.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Severity',
                  style: AppTypography.wSemiBold.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                FilterChipGroup<IntelligenceSeverity>(
                  items: IntelligenceSeverity.values.toList(),
                  selected: filterSeverity,
                  onSelected: onSeverityChanged,
                  labelBuilder: (severity) => severity.label,
                ),
              ],
            ),
            const SizedBox(height: Spacings.lg),

            // ─── Alert List ───────────────────────────────────────────
            if (state.alerts.isEmpty)
              const AdminEmptyState(
                message: 'No alerts match the current filters.',
                icon: Icons.notifications_off_outlined,
              )
            else
              ...state.alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: IntelligenceAlertCard(
                      alert: alert,
                      onAcknowledge: alert.isAcknowledged
                          ? null
                          : () => onAcknowledge(alert.id),
                      onResolve: alert.isResolved
                          ? null
                          : () => onResolve(alert.id),
                    ),
                  )),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHURN PREDICTION TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ChurnPredictionTab extends StatelessWidget {
  const _ChurnPredictionTab({required this.churnPredictions});

  final Map<String, dynamic>? churnPredictions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (churnPredictions == null) {
      return const AdminEmptyState(
        message: 'No churn prediction data available. Generate insights first.',
        icon: Icons.person_off_outlined,
      );
    }

    final predictions = churnPredictions!['predictions'] as List<dynamic>? ?? [];
    if (predictions.isEmpty) {
      return const AdminEmptyState(
        message: 'No schools predicted to churn at this time.',
        icon: Icons.thumb_up_outlined,
      );
    }

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Churn Prediction',
            subtitle: 'Schools at risk of churning based on AI analysis',
          ),
          const SizedBox(height: Spacings.md),
          ...predictions.map((pred) {
            final data = pred as Map<String, dynamic>;
            final schoolName = data['schoolName'] as String? ?? 'Unknown School';
            final probability = (data['churnProbability'] as num?)?.toDouble() ?? 0.0;
            final riskLevel = data['riskLevel'] as String? ?? 'low';
            final recommendedActions = data['recommendedActions'] as List<dynamic>? ?? [];

            return _ChurnPredictionCard(
              schoolName: schoolName,
              probability: probability,
              riskLevel: riskLevel,
              recommendedActions: recommendedActions.cast<Map<String, dynamic>>(),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CHURN PREDICTION CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ChurnPredictionCard extends StatelessWidget {
  const _ChurnPredictionCard({
    required this.schoolName,
    required this.probability,
    required this.riskLevel,
    required this.recommendedActions,
  });

  final String schoolName;
  final double probability;
  final String riskLevel;
  final List<Map<String, dynamic>> recommendedActions;

  Color _riskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _riskIcon() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final riskColor = _riskColor();

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────────────
            Row(
              children: [
                // Visual indicator dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    schoolName,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: riskLevel.toUpperCase(),
                  color: riskColor,
                  icon: _riskIcon(),
                ),
              ],
            ),

            const SizedBox(height: Spacings.md),

            // ─── Churn Probability Bar ─────────────────────────────────
            Row(
              children: [
                Text(
                  'Churn Probability',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  '${probability.toStringAsFixed(1)}%',
                  style: AppTypography.wBold.copyWith(
                    fontSize: 18,
                    color: riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xs),
            ClipRRect(
              borderRadius: Spacings.borderRadiusFull,
              child: LinearProgressIndicator(
                value: (probability / 100).clamp(0.0, 1.0),
                backgroundColor: cs.surfaceContainerHighest,
                color: riskColor,
                minHeight: 8,
              ),
            ),

            // ─── Recommended Actions ──────────────────────────────────
            if (recommendedActions.isNotEmpty) ...[
              const SizedBox(height: Spacings.md),
              Text(
                'Recommended Actions',
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: Spacings.sm),
              ...recommendedActions.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: Spacings.mdIcon,
                          color: cs.primary,
                        ),
                        const SizedBox(width: Spacings.xs),
                        Expanded(
                          child: Text(
                            action['description'] as String? ?? action['action'] as String? ?? '',
                            style: AppTypography.wRegular.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVENUE FORECAST TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _RevenueForecastTab extends StatelessWidget {
  const _RevenueForecastTab({required this.revenueForecast});

  final Map<String, dynamic>? revenueForecast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (revenueForecast == null) {
      return const AdminEmptyState(
        message: 'No revenue forecast data available. Generate insights first.',
        icon: Icons.show_chart,
      );
    }

    final forecastMonths =
        revenueForecast!['months'] as List<dynamic>? ?? [];
    final overallConfidence =
        (revenueForecast!['overallConfidence'] as num?)?.toDouble() ?? 0.0;

    if (forecastMonths.isEmpty) {
      return const AdminEmptyState(
        message: 'No forecast data available.',
        icon: Icons.show_chart,
      );
    }

    // Find max value for scaling
    double maxValue = 0;
    for (final m in forecastMonths) {
      final data = m as Map<String, dynamic>;
      final upper = (data['upperBound'] as num?)?.toDouble() ?? 0;
      if (upper > maxValue) maxValue = upper;
    }
    if (maxValue == 0) maxValue = 1;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Revenue Forecast',
            subtitle: '6-month AI-powered revenue prediction',
          ),
          const SizedBox(height: Spacings.md),

          // ─── Confidence Indicator ──────────────────────────────────
          Card(
            elevation: Spacings.elevationSm,
            shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
            child: Padding(
              padding: Spacings.paddingAll,
              child: Row(
                children: [
                  Icon(Icons.analytics, color: cs.primary, size: Spacings.lgIcon),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Confidence',
                          style: AppTypography.wRegular.copyWith(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${overallConfidence.toStringAsFixed(1)}%',
                          style: AppTypography.wBold.copyWith(
                            fontSize: 20,
                            color: overallConfidence >= 80
                                ? AppColors.success
                                : overallConfidence >= 60
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacings.lg),

          // ─── Forecast Bars ─────────────────────────────────────────
          Card(
            elevation: Spacings.elevationSm,
            shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
            child: Padding(
              padding: Spacings.paddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Forecast',
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: Spacings.lg),
                  ...forecastMonths.map((m) {
                    final data = m as Map<String, dynamic>;
                    final month = data['month'] as String? ?? 'Unknown';
                    final predicted = (data['predicted'] as num?)?.toDouble() ?? 0;
                    final lower = (data['lowerBound'] as num?)?.toDouble() ?? 0;
                    final upper = (data['upperBound'] as num?)?.toDouble() ?? 0;
                    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0;

                    return _ForecastBar(
                      month: month,
                      predicted: predicted,
                      lowerBound: lower,
                      upperBound: upper,
                      confidence: confidence,
                      maxValue: maxValue,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FORECAST BAR WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ForecastBar extends StatelessWidget {
  const _ForecastBar({
    required this.month,
    required this.predicted,
    required this.lowerBound,
    required this.upperBound,
    required this.confidence,
    required this.maxValue,
  });

  final String month;
  final double predicted;
  final double lowerBound;
  final double upperBound;
  final double confidence;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final predictedFraction = (predicted / maxValue).clamp(0.0, 1.0);
    final lowerFraction = (lowerBound / maxValue).clamp(0.0, 1.0);
    final upperFraction = (upperBound / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  month,
                  style: AppTypography.wSemiBold.copyWith(fontSize: 13),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confidence interval range
                    Stack(
                      children: [
                        // Background
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                        ),
                        // Confidence interval (lighter)
                        FractionallySizedBox(
                          widthFactor: upperFraction,
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                          ),
                        ),
                        // Predicted value (darker bar)
                        FractionallySizedBox(
                          widthFactor: predictedFraction,
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.5),
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: Spacings.sm),
                            child: Text(
                              '\$${_formatCompact(predicted)}',
                              style: AppTypography.wSemiBold.copyWith(
                                fontSize: 11,
                                color: cs.onPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacings.sm),
              SizedBox(
                width: 60,
                child: Text(
                  '${confidence.toStringAsFixed(0)}% conf.',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),
          Row(
            children: [
              const SizedBox(width: 80),
              Text(
                'Range: \$${_formatCompact(lowerBound)} — \$${_formatCompact(upperBound)}',
                style: AppTypography.wRegular.copyWith(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COST OPTIMIZATION TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CostOptimizationTab extends StatelessWidget {
  const _CostOptimizationTab({required this.costOptimizations});

  final Map<String, dynamic>? costOptimizations;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (costOptimizations == null) {
      return const AdminEmptyState(
        message: 'No cost optimization data available. Generate insights first.',
        icon: Icons.savings_outlined,
      );
    }

    final currentSpend = (costOptimizations!['currentMonthlySpend'] as num?)?.toDouble() ?? 0;
    final optimizedSpend = (costOptimizations!['optimizedMonthlySpend'] as num?)?.toDouble() ?? 0;
    final potentialSavings = currentSpend - optimizedSpend;
    final savingsPercentage = currentSpend > 0 ? (potentialSavings / currentSpend) * 100 : 0;
    final suggestions = costOptimizations!['suggestions'] as List<dynamic>? ?? [];
    final providerBreakdown = costOptimizations!['providerBreakdown'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Cost Optimization',
            subtitle: 'AI-powered suggestions to reduce infrastructure costs',
          ),
          const SizedBox(height: Spacings.md),

          // ─── Spend Comparison Cards ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Current Spend',
                  value: '\$${currentSpend.toStringAsFixed(2)}',
                  icon: Icons.payments,
                  color: AppColors.error,
                  subtitle: 'Per month',
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: MetricCard(
                  title: 'Optimized Spend',
                  value: '\$${optimizedSpend.toStringAsFixed(2)}',
                  icon: Icons.savings,
                  color: AppColors.success,
                  subtitle: 'Per month',
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: MetricCard(
                  title: 'Potential Savings',
                  value: '\$${potentialSavings.toStringAsFixed(2)}',
                  icon: Icons.trending_down,
                  color: AppColors.success,
                  subtitle: '${savingsPercentage.toStringAsFixed(1)}% reduction',
                  trend: savingsPercentage > 0 ? '-${savingsPercentage.toStringAsFixed(1)}%' : null,
                  trendIsUp: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacings.xl),

          // ─── Spend Comparison Bar ──────────────────────────────────
          Card(
            elevation: Spacings.elevationSm,
            shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
            child: Padding(
              padding: Spacings.paddingAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spend Comparison',
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: Spacings.lg),
                  _ComparisonBar(
                    label: 'Current',
                    value: currentSpend,
                    maxValue: currentSpend > 0 ? currentSpend : 1,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: Spacings.md),
                  _ComparisonBar(
                    label: 'Optimized',
                    value: optimizedSpend,
                    maxValue: currentSpend > 0 ? currentSpend : 1,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // ─── Provider Breakdown ────────────────────────────────────
          if (providerBreakdown.isNotEmpty) ...[
            Text(
              'Provider Cost Breakdown',
              style: AppTypography.wBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: Spacings.md),
            ...providerBreakdown.map((item) {
              final data = item as Map<String, dynamic>;
              final name = data['providerName'] as String? ?? 'Unknown';
              final current = (data['currentSpend'] as num?)?.toDouble() ?? 0;
              final optimized = (data['optimizedSpend'] as num?)?.toDouble() ?? 0;
              return _ProviderCostCard(
                providerName: name,
                currentSpend: current,
                optimizedSpend: optimized,
                maxValue: currentSpend > 0 ? currentSpend : 1,
              );
            }),
            const SizedBox(height: Spacings.xl),
          ],

          // ─── Optimization Suggestions ──────────────────────────────
          if (suggestions.isNotEmpty) ...[
            Text(
              'Optimization Suggestions',
              style: AppTypography.wBold.copyWith(fontSize: 16),
            ),
            const SizedBox(height: Spacings.md),
            ...suggestions.map((suggestion) {
              final data = suggestion as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Optimization';
              final description = data['description'] as String? ?? '';
              final impact = data['impact'] as String? ?? 'medium';
              final estimatedSavings = (data['estimatedSavings'] as num?)?.toDouble() ?? 0;

              return Card(
                elevation: Spacings.elevationNone,
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                  side: BorderSide(
                    color: cs.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: Spacings.paddingAll,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(Spacings.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.success,
                          size: Spacings.mdIcon,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                                  ),
                                ),
                                StatusBadge(
                                  label: impact.toUpperCase(),
                                  color: impact == 'high'
                                      ? AppColors.error
                                      : impact == 'medium'
                                          ? AppColors.warning
                                          : AppColors.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacings.xs),
                            Text(
                              description,
                              style: AppTypography.wRegular.copyWith(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            if (estimatedSavings > 0) ...[
                              const SizedBox(height: Spacings.sm),
                              Text(
                                'Estimated savings: \$${estimatedSavings.toStringAsFixed(2)}/mo',
                                style: AppTypography.wSemiBold.copyWith(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPARISON BAR WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.wSemiBold.copyWith(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: Spacings.borderRadiusSm,
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
              minHeight: 20,
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        SizedBox(
          width: 90,
          child: Text(
            '\$${value.toStringAsFixed(2)}',
            style: AppTypography.wSemiBold.copyWith(fontSize: 13),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER COST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ProviderCostCard extends StatelessWidget {
  const _ProviderCostCard({
    required this.providerName,
    required this.currentSpend,
    required this.optimizedSpend,
    required this.maxValue,
  });

  final String providerName;
  final double currentSpend;
  final double optimizedSpend;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final savings = currentSpend - optimizedSpend;
    final savingsPercent = currentSpend > 0 ? (savings / currentSpend) * 100 : 0;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, size: Spacings.mdIcon, color: cs.primary),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    providerName,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text(
                      'Save ${savingsPercent.toStringAsFixed(0)}%',
                      style: AppTypography.wSemiBold.copyWith(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            _ComparisonBar(
              label: 'Current',
              value: currentSpend,
              maxValue: maxValue,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacings.xs),
            _ComparisonBar(
              label: 'Optimized',
              value: optimizedSpend,
              maxValue: maxValue,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}
