import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../providers/deployment_provider.dart';
import '../widgets/ccms_widgets.dart';

class DeploymentPage extends ConsumerStatefulWidget {
  const DeploymentPage({super.key});

  @override
  ConsumerState<DeploymentPage> createState() => _DeploymentPageState();
}

class _DeploymentPageState extends ConsumerState<DeploymentPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deploymentProvider.notifier).loadDeployments();
      ref.read(deploymentProvider.notifier).loadTestResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deploymentProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Deployment & CI/CD',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _showCreateDeploymentDialog,
            tooltip: 'New Deployment',
          ),
        ],
      ),
      body: state.isLoading && state.deployments.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null
              ? AppErrorState(
                  message: state.error,
                  onRetry: () =>
                      ref.read(deploymentProvider.notifier).loadDeployments(),
                )
              : SingleChildScrollView(
                  padding: Spacings.paddingScreen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Current Deployment Status by Environment ────
                      Text('Current Deployment Status',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface)),
                      const SizedBox(height: Spacings.md),
                      _buildEnvironmentStatusCards(state, isDesktop, cs, tt),
                      Spacings.sectionGap,

                      // ── Deployment History ──────────────────────────
                      Text('Deployment History',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface)),
                      const SizedBox(height: Spacings.md),
                      if (state.deployments.isEmpty)
                        AppEmptyState.noData(
                            subtitle: 'No deployments found')
                      else
                        ...state.deployments.map((deployment) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: Spacings.md),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                            _statusIcon(deployment.status),
                                            size: Spacings.mdIcon,
                                            color: _statusColor(
                                                deployment.status)),
                                        const SizedBox(width: Spacings.sm),
                                        Expanded(
                                          child: Text(
                                            '${deployment.environment} - ${deployment.version}',
                                            style: tt.titleSmall?.copyWith(
                                                fontWeight:
                                                    AppTypography.wSemiBold,
                                                color: cs.onSurface),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Spacings.sm,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                                    deployment.status)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                Spacings.borderRadiusSm,
                                          ),
                                          child: Text(
                                            deployment.status.label,
                                            style: tt.labelSmall!.copyWith(
                                                    color: _statusColor(
                                                        deployment.status),
                                                    fontWeight:
                                                        AppTypography
                                                            .wSemiBold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: Spacings.sm),
                                    Row(
                                      children: [
                                        Text(
                                            'Deployed by: ${deployment.deployerId ?? 'Unknown'}',
                                            style: tt.bodySmall?.copyWith(
                                                color:
                                                    cs.onSurfaceVariant)),
                                        const Spacer(),
                                        Text(_formatDate(deployment.startedAt),
                                            style: tt.bodySmall?.copyWith(
                                                color:
                                                    cs.onSurfaceVariant)),
                                      ],
                                    ),
                                    if (deployment.notes != null &&
                                        deployment.notes!.isNotEmpty) ...[
                                      const SizedBox(height: Spacings.xs),
                                      Text(deployment.notes!,
                                          style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant)),
                                    ],
                                    const SizedBox(height: Spacings.sm),
                                    Row(
                                      children: [
                                        if (deployment.status ==
                                                DeploymentStatus.running ||
                                            deployment.status ==
                                                DeploymentStatus.success)
                                          AppButton(
                                            label: 'Rollback',
                                            onPressed: () =>
                                                _confirmRollback(deployment),
                                            variant:
                                                AppButtonVariant.outlined,
                                            size: AppButtonSize.small,
                                            icon: Icons.restore_rounded,
                                          ),
                                        if (deployment.status ==
                                            DeploymentStatus.failed)
                                          AppButton(
                                            label: 'Retry',
                                            onPressed: () => ref
                                                .read(deploymentProvider
                                                    .notifier)
                                                .updateDeploymentStatus(
                                                  deploymentId:
                                                      deployment.id,
                                                  status: DeploymentStatus
                                                      .running,
                                                ),
                                            variant: AppButtonVariant.tonal,
                                            size: AppButtonSize.small,
                                            icon: Icons.refresh_rounded,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      Spacings.sectionGap,

                      // ── Test Results ────────────────────────────────
                      Text('Test Results',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface)),
                      const SizedBox(height: Spacings.md),
                      if (state.testResults.isEmpty)
                        Text('No test results available',
                            style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant))
                      else ...[
                        _buildTestResultsSummary(
                            state.testResults, isDesktop),
                        const SizedBox(height: Spacings.md),
                        ...state.testResults.take(10).map((result) =>
                            Card(
                              child: ListTile(
                                leading: Icon(
                                    result.status == 'passed'
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: result.status == 'passed'
                                        ? AppColors.success
                                        : AppColors.error),
                                title: Text(
                                    '${result.testType.label}: ${result.testName}'),
                                subtitle: Text(
                                    'Duration: ${result.durationMs}ms · ${_formatDate(result.createdAt)}'),
                                dense: true,
                              ),
                            )),
                      ],
                      Spacings.sectionGap,

                      // ── Database Migrations ────────────────────────
                      Text('Database Migrations',
                          style: tt.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface)),
                      const SizedBox(height: Spacings.md),
                      AppCard(
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.storage_rounded,
                                  color: cs.primary),
                              title: const Text('Migration Status'),
                              subtitle: Text(
                                  'Last applied: ${state.deployments.isNotEmpty ? _formatDate(state.deployments.first.startedAt) : "N/A"}'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: Icon(Icons.check_circle_rounded,
                                  color: AppColors.success),
                              title: const Text('Schema Version'),
                              subtitle: Text(
                                  'Current: ${state.deployments.isNotEmpty ? state.deployments.first.version : "N/A"}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEnvironmentStatusCards(
      DeploymentState state, bool isDesktop, ColorScheme cs, TextTheme tt) {
    // Group deployments by environment
    final envMap = <String, Deployment>{};
    for (final dep in state.deployments) {
      envMap[dep.environment] = dep;
    }

    final environments = ['dev', 'staging', 'production'];
    return GridView.count(
      crossAxisCount: isDesktop ? 3 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.md,
      crossAxisSpacing: Spacings.md,
      childAspectRatio: 3,
      children: environments.map((env) {
        final dep = envMap[env];
        final statusColor =
            dep != null ? _statusColor(dep.status) : cs.onSurfaceVariant;
        return AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  dep != null
                      ? _statusIcon(dep.status)
                      : Icons.cloud_off_rounded,
                  color: statusColor,
                  size: Spacings.lgIcon,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(env.toUpperCase(),
                        style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurfaceVariant)),
                    Text(
                        dep != null
                            ? 'v${dep.version}'
                            : 'No deployment',
                        style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface)),
                    if (dep != null)
                      Text(dep.status.label,
                          style: tt.bodySmall?.copyWith(
                              color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTestResultsSummary(
      List<TestResult> results, bool isDesktop) {
    final passed = results.where((r) => r.status == 'passed').length;
    final failed = results.where((r) => r.status == 'failed').length;
    final skipped = results.where((r) => r.status != 'passed' && r.durationMs == 0).length;
    final total = results.length;

    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.sm,
      crossAxisSpacing: Spacings.sm,
      childAspectRatio: 2.5,
      children: [
        StatOverviewCard(
          title: 'Total',
          value: '$total',
          icon: Icons.science_rounded,
          color: AppColors.info,
        ),
        StatOverviewCard(
          title: 'Passed',
          value: '$passed',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        StatOverviewCard(
          title: 'Failed',
          value: '$failed',
          icon: Icons.cancel_rounded,
          color: AppColors.error,
        ),
        StatOverviewCard(
          title: 'Pass Rate',
          value:
              '${total > 0 ? ((passed / total) * 100).toStringAsFixed(1) : 0}%',
          icon: Icons.pie_chart_rounded,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  void _showCreateDeploymentDialog() {
    final versionCtrl = TextEditingController();
    var environment = 'staging';
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Deployment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: versionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Version *',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<String>(
                  value: environment,
                  decoration: const InputDecoration(
                      labelText: 'Environment *',
                      border: OutlineInputBorder()),
                  items: ['dev', 'staging', 'production']
                      .map((e) => DropdownMenuItem(
                          value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => environment = v!),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder()),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Deploy',
              onPressed: () {
                ref.read(deploymentProvider.notifier).createDeployment(
                  Deployment(
                    id: '',
                    environment: environment,
                    version: versionCtrl.text,
                    commitHash: '',
                    branch: '',
                    status: DeploymentStatus.pending,
                    deployerId: 'current_user',
                    startedAt: DateTime.now(),
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
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

  void _confirmRollback(Deployment deployment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: Text(
            'Are you sure you want to rollback ${deployment.environment} from v${deployment.version}? '
            'This will revert to the previous deployment version.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Rollback',
            onPressed: () {
              ref.read(deploymentProvider.notifier).updateDeploymentStatus(
                deploymentId: deployment.id,
                status: DeploymentStatus.rolledBack,
                notes: 'Rolled back by current user',
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Color _statusColor(DeploymentStatus status) {
    return switch (status) {
      DeploymentStatus.pending => AppColors.warning,
      DeploymentStatus.running => AppColors.info,
      DeploymentStatus.success => AppColors.success,
      DeploymentStatus.failed => AppColors.error,
      DeploymentStatus.rolledBack => const Color(0xFF6B7280),
    };
  }

  IconData _statusIcon(DeploymentStatus status) {
    return switch (status) {
      DeploymentStatus.pending => Icons.schedule_rounded,
      DeploymentStatus.running => Icons.sync_rounded,
      DeploymentStatus.success => Icons.check_circle_rounded,
      DeploymentStatus.failed => Icons.error_rounded,
      DeploymentStatus.rolledBack => Icons.restore_rounded,
    };
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
