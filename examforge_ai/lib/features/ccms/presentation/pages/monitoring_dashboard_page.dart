import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class MonitoringDashboardPage extends ConsumerStatefulWidget {
  const MonitoringDashboardPage({super.key});

  @override
  ConsumerState<MonitoringDashboardPage> createState() =>
      _MonitoringDashboardPageState();
}

class _MonitoringDashboardPageState
    extends ConsumerState<MonitoringDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(monitoringProvider.notifier).loadMetrics();
      ref.read(monitoringProvider.notifier).loadAlertIncidents();
      ref.read(monitoringProvider.notifier).loadAlertRules();
      ref.read(monitoringProvider.notifier).loadPerformanceLogs(isSlow: true);
      ref.read(monitoringProvider.notifier).loadErrorReports();
      ref.read(monitoringProvider.notifier).loadCcmsStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monitoringProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: const AppAppBar(title: 'Monitoring Dashboard'),
      body: state.isLoading &&
              state.metrics.isEmpty &&
              state.alertIncidents.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(monitoringProvider.notifier).loadMetrics();
                ref.read(monitoringProvider.notifier).loadAlertIncidents();
                ref
                    .read(monitoringProvider.notifier)
                    .loadPerformanceLogs(isSlow: true);
                ref.read(monitoringProvider.notifier).loadErrorReports();
              },
              child: SingleChildScrollView(
                padding: Spacings.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── System Metrics ──────────────────────────────
                    Text('System Metrics',
                        style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,),),
                    const SizedBox(height: Spacings.md),
                    _buildMetricsGrid(isDesktop),
                    Spacings.sectionGap,

                    // ── Active Alerts ──────────────────────────────
                    Text('Active Alerts',
                        style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,),),
                    const SizedBox(height: Spacings.md),
                    if (state.alertIncidents.isEmpty)
                      AppEmptyState.noData(subtitle: 'No active alerts')
                    else
                      ...state.alertIncidents.take(5).map((incident) =>
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: Spacings.md),
                            child: AlertIncidentCard(
                              incident: incident,
                              onAcknowledge: () => ref
                                  .read(monitoringProvider.notifier)
                                  .acknowledgeAlert(
                                      incidentId: incident.id,
                                      acknowledgedBy: 'current_user',),
                              onResolve: () =>
                                  _showResolveDialog(incident.id),
                            ),
                          ),),
                    Spacings.sectionGap,

                    // ── Alert Rules ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Alert Rules',
                            style: tt.titleLarge?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: cs.onSurface,),),
                        AppButton(
                          label: 'Add Rule',
                          onPressed: _showCreateAlertRuleDialog,
                          icon: Icons.add_rounded,
                          size: AppButtonSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.md),
                    if (state.alertRules.isEmpty)
                      Text('No alert rules configured',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,),)
                    else
                      ...state.alertRules.map((rule) => Card(
                            child: ListTile(
                              leading: Switch(
                                value: rule.isActive,
                                onChanged: (_) {},
                              ),
                              title: Text(rule.name),
                              subtitle: Text(
                                  '${rule.severity.label} · ${rule.metricName} ${rule.conditionOperator} ${rule.thresholdValue}',),
                              trailing: AppIconButton(
                                icon: Icons.edit_outlined,
                                onPressed: () =>
                                    _showEditAlertRuleDialog(rule),
                                variant: AppIconButtonVariant.standard,
                                size: AppButtonSize.small,
                              ),
                            ),
                          ),),
                    Spacings.sectionGap,

                    // ── Slow Operations ────────────────────────────
                    Text('Slow Operations',
                        style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,),),
                    const SizedBox(height: Spacings.md),
                    if (state.performanceLogs.isEmpty)
                      Text('No slow operations detected',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,),)
                    else
                      ...state.performanceLogs.take(5).map((log) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.speed_rounded,
                                  color: AppColors.warning,),
                              title: Text(
                                  '${log.operationType}: ${log.operationName}',),
                              subtitle: Text(
                                  'Duration: ${log.durationMs}ms · ${_formatDate(log.createdAt)}',),
                            ),
                          ),),
                    Spacings.sectionGap,

                    // ── Error Reports ──────────────────────────────
                    Text('Error Reports',
                        style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,),),
                    const SizedBox(height: Spacings.md),
                    if (state.errorReports.isEmpty)
                      Text('No error reports',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,),)
                    else
                      ...state.errorReports.take(5).map((report) => Card(
                            child: ListTile(
                              leading: Icon(
                                  report.isResolved
                                      ? Icons.check_circle_rounded
                                      : Icons.error_outline_rounded,
                                  color: report.isResolved
                                      ? AppColors.success
                                      : AppColors.error,),
                              title: Text(report.errorType),
                              subtitle: Text(report.errorMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,),
                              trailing: report.isResolved
                                  ? null
                                  : AppButton(
                                      label: 'Resolve',
                                      onPressed: () => ref
                                          .read(monitoringProvider.notifier)
                                          .resolveError(
                                              errorId: report.id,
                                              resolvedBy: 'current_user',),
                                      variant: AppButtonVariant.text,
                                      size: AppButtonSize.small,
                                    ),
                            ),
                          ),),
                    Spacings.sectionGap,

                    // ── AI Usage Metrics ───────────────────────────
                    Text('AI Usage Metrics',
                        style: tt.titleLarge?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,),),
                    const SizedBox(height: Spacings.md),
                    _buildAiUsageMetrics(isDesktop, cs, tt),
                    Spacings.sectionGap,

                    // ── CCMS Statistics ────────────────────────────
                    if (state.ccmsStats != null) ...[
                      Text('CCMS Statistics',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,),),
                      const SizedBox(height: Spacings.md),
                      _buildStatsGrid(state.ccmsStats!, isDesktop),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid(bool isDesktop) {
    final state = ref.watch(monitoringProvider);
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: 2,
      children: [
        StatOverviewCard(
          title: 'CPU Usage',
          value:
              '${state.metrics.where((m) => m.metricName == 'cpu_usage').firstOrNull?.value ?? 0}%',
          icon: Icons.memory_rounded,
          color: AppColors.info,
        ),
        StatOverviewCard(
          title: 'Memory',
          value:
              '${state.metrics.where((m) => m.metricName == 'memory_usage').firstOrNull?.value ?? 0}%',
          icon: Icons.storage_rounded,
          color: const Color(0xFF8B5CF6),
        ),
        StatOverviewCard(
          title: 'Request Rate',
          value:
              '${state.metrics.where((m) => m.metricName == 'request_rate').firstOrNull?.value ?? 0}/s',
          icon: Icons.swap_vert_rounded,
          color: AppColors.success,
        ),
        StatOverviewCard(
          title: 'Error Rate',
          value:
              '${state.metrics.where((m) => m.metricName == 'error_rate').firstOrNull?.value ?? 0}%',
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildAiUsageMetrics(
      bool isDesktop, ColorScheme cs, TextTheme tt,) {
    final state = ref.watch(monitoringProvider);
    final aiGenerated = state.ccmsStats?.aiGeneratedContent ?? 0;
    final totalContent = state.ccmsStats?.totalContent ?? 0;
    final aiPercentage = totalContent > 0
        ? ((aiGenerated / totalContent) * 100).toStringAsFixed(1)
        : '0.0';

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: 2,
      children: [
        StatOverviewCard(
          title: 'AI Generated',
          value: '$aiGenerated',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF7C3AED),
        ),
        StatOverviewCard(
          title: 'AI Content %',
          value: '$aiPercentage%',
          icon: Icons.pie_chart_rounded,
          color: const Color(0xFFEC4899),
        ),
        StatOverviewCard(
          title: 'AI Quality Avg',
          value: state.ccmsStats?.avgQualityScore.toStringAsFixed(1) ?? '0.0',
          icon: Icons.star_rounded,
          color: AppColors.warning,
        ),
        StatOverviewCard(
          title: 'Pending Reviews',
          value: '${state.ccmsStats?.pendingReviews ?? 0}',
          icon: Icons.rate_review_rounded,
          color: const Color(0xFF0891B2),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(CcmsStats stats, bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: 2,
      children: [
        StatOverviewCard(
            title: 'Total Content',
            value: '${stats.totalContent}',
            icon: Icons.article_rounded,),
        StatOverviewCard(
            title: 'Published',
            value: '${stats.publishedContent}',
            icon: Icons.publish_rounded,
            color: AppColors.success,),
        StatOverviewCard(
            title: 'AI Generated',
            value: '${stats.aiGeneratedContent}',
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFF7C3AED),),
        StatOverviewCard(
            title: 'Avg Quality',
            value: stats.avgQualityScore.toStringAsFixed(1),
            icon: Icons.star_rounded,
            color: AppColors.warning,),
      ],
    );
  }

  void _showResolveDialog(String incidentId) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                border: OutlineInputBorder(),),
            maxLines: 3,),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),),
          AppButton(
            label: 'Resolve',
            onPressed: () {
              ref
                  .read(monitoringProvider.notifier)
                  .resolveAlert(
                      incidentId: incidentId,
                      resolutionNotes: notesCtrl.text,);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateAlertRuleDialog() {
    final nameCtrl = TextEditingController();
    final metricCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController();
    var severity = AlertSeverity.warning;
    var condition = '>';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Alert Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Rule Name *',
                        border: OutlineInputBorder(),),),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: metricCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Metric Name *',
                        border: OutlineInputBorder(),),),
                const SizedBox(height: Spacings.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: condition,
                        decoration: const InputDecoration(
                            labelText: 'Condition',
                            border: OutlineInputBorder(),),
                        items: ['>', '>=', '<', '<=', '==', '!=']
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c),),)
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => condition = v!),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: TextField(
                          controller: thresholdCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Threshold',
                              border: OutlineInputBorder(),),
                          keyboardType: TextInputType.number,),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<AlertSeverity>(
                  initialValue: severity,
                  decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),),
                  items: AlertSeverity.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.label),),)
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => severity = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),),
            AppButton(
              label: 'Create',
              onPressed: () {
                ref.read(monitoringProvider.notifier).createAlertRule(
                      AlertRule(
                        id: '',
                        name: nameCtrl.text,
                        metricName: metricCtrl.text,
                        conditionOperator: condition,
                        thresholdValue:
                            double.tryParse(thresholdCtrl.text) ?? 0,
                        severity: severity,
                        isActive: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAlertRuleDialog(AlertRule rule) {
    final nameCtrl = TextEditingController(text: rule.name);
    final thresholdCtrl =
        TextEditingController(text: '${rule.thresholdValue}');
    var severity = rule.severity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Alert Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Rule Name',
                        border: OutlineInputBorder(),),),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: thresholdCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Threshold',
                        border: OutlineInputBorder(),),
                    keyboardType: TextInputType.number,),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<AlertSeverity>(
                  initialValue: severity,
                  decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),),
                  items: AlertSeverity.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.label),),)
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => severity = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),),
            AppButton(
              label: 'Save',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
