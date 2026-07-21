import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE MONITORING PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Real-time infrastructure health monitoring page.
///
/// Displays service status cards, health indicators, maintenance windows,
/// and provides actions for running health checks. Auto-refreshes every
/// 30 seconds.
///
/// Follows the standard ExamForge AI page pattern:
/// - [ConsumerStatefulWidget] + private state class
/// - `initState` → `addPostFrameCallback` → `_loadData()` via `ref.read`
/// - `ref.watch(provider)` in `build()` for reactive rebuilds
/// - Loading → Error → Content pattern
/// - Design tokens everywhere
class InfrastructureMonitoringPage extends ConsumerStatefulWidget {
  const InfrastructureMonitoringPage({super.key});

  @override
  ConsumerState<InfrastructureMonitoringPage> createState() =>
      _InfrastructureMonitoringPageState();
}

class _InfrastructureMonitoringPageState
    extends ConsumerState<InfrastructureMonitoringPage> {
  Timer? _autoRefreshTimer;

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    ref.read(infrastructureMonitoringProvider.notifier).loadServices();
    ref.read(infrastructureMonitoringProvider.notifier).loadMaintenanceWindows();
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final infraState = ref.watch(infrastructureMonitoringProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Infrastructure Monitoring'),
      body: _buildBody(context, infraState, cs),
    );
  }

  // ─── Body: Loading → Error → Content ────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    InfrastructureMonitoringState state,
    ColorScheme cs,
  ) {
    // Loading state
    if (state.isLoading && state.services.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    // Error state
    if (state.error != null && state.services.isEmpty) {
      return _buildErrorState(state);
    }

    // Content
    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(infrastructureMonitoringProvider.notifier)
            .loadServices();
        ref
            .read(infrastructureMonitoringProvider.notifier)
            .loadMaintenanceWindows();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall System Health
            _buildOverallHealth(state, cs),
            Spacings.sectionGap,

            // Service Status Grid
            SectionHeader(
              title: 'Service Status',
              subtitle: '${state.services.length} services monitored',
              action: _buildRunAllHealthChecksButton(state),
            ),
            Spacings.itemGap,
            _buildServiceGrid(state, cs),
            Spacings.sectionGap,

            // Maintenance Windows
            SectionHeader(
              title: 'Maintenance Windows',
              subtitle:
                  '${state.maintenanceWindows.where((w) => w.status == MaintenanceStatus.scheduled || w.status == MaintenanceStatus.inProgress).length} active',
              action: _buildScheduleMaintenanceButton(cs),
            ),
            Spacings.itemGap,
            _buildMaintenanceWindows(state, cs),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(InfrastructureMonitoringState state) {
    return Center(
      child: Padding(
        padding: Spacings.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: Spacings.lg),
            Text(
              'Failed to load infrastructure data',
              style: AppTypography.wSemiBold.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              state.error ?? 'An unexpected error occurred.',
              style: AppTypography.wRegular.copyWith(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.xl),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Overall System Health ──────────────────────────────────────────────

  Widget _buildOverallHealth(InfrastructureMonitoringState state, ColorScheme cs) {
    final services = state.services;
    if (services.isEmpty) return const SizedBox.shrink();

    final healthyCount =
        services.where((s) => s.healthStatus == HealthStatus.healthy).length;
    final degradedCount =
        services.where((s) => s.healthStatus == HealthStatus.degraded).length;
    final unhealthyCount = services
        .where((s) =>
            s.healthStatus == HealthStatus.unhealthy ||
            s.healthStatus == HealthStatus.down)
        .length;
    final maintenanceCount = services
        .where((s) => s.healthStatus == HealthStatus.maintenance)
        .length;

    // Determine overall health
    HealthStatus overallStatus;
    if (unhealthyCount > 0) {
      overallStatus = HealthStatus.unhealthy;
    } else if (degradedCount > 0) {
      overallStatus = HealthStatus.degraded;
    } else if (maintenanceCount > 0) {
      overallStatus = HealthStatus.maintenance;
    } else {
      overallStatus = HealthStatus.healthy;
    }

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Overall System Health',
                  style: AppTypography.wBold.copyWith(fontSize: 16),
                ),
                const Spacer(),
                HealthIndicator(status: overallStatus),
              ],
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                _buildHealthStatChip(
                  'Healthy',
                  healthyCount,
                  AppColors.success,
                ),
                const SizedBox(width: Spacings.md),
                _buildHealthStatChip(
                  'Degraded',
                  degradedCount,
                  AppColors.warning,
                ),
                const SizedBox(width: Spacings.md),
                _buildHealthStatChip(
                  'Down',
                  unhealthyCount,
                  AppColors.error,
                ),
                const SizedBox(width: Spacings.md),
                _buildHealthStatChip(
                  'Maintenance',
                  maintenanceCount,
                  AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md, vertical: Spacings.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            '$count $label',
            style: AppTypography.wSemiBold.copyWith(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  // ─── Run All Health Checks Button ───────────────────────────────────────

  Widget _buildRunAllHealthChecksButton(InfrastructureMonitoringState state) {
    final isRunning = state.runningHealthCheckFor == '__all__';
    return FilledButton.tonal(
      onPressed: isRunning
          ? null
          : () => ref
              .read(infrastructureMonitoringProvider.notifier)
              .runHealthCheck(),
      child: isRunning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.health_and_safety, size: 18),
                SizedBox(width: Spacings.sm),
                Text('Run All Health Checks'),
              ],
            ),
    );
  }

  // ─── Service Status Grid ────────────────────────────────────────────────

  Widget _buildServiceGrid(InfrastructureMonitoringState state, ColorScheme cs) {
    if (state.services.isEmpty) {
      return const AdminEmptyState(
        message: 'No infrastructure services found.',
        icon: Icons.dns_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width >= 1400) {
          crossAxisCount = 4;
        } else if (width >= 1100) {
          crossAxisCount = 3;
        } else if (width >= 700) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: state.services.length,
          itemBuilder: (context, index) {
            return _ServiceStatusCard(
              service: state.services[index],
              isRunningHealthCheck:
                  state.runningHealthCheckFor == state.services[index].id,
              onRunHealthCheck: () => ref
                  .read(infrastructureMonitoringProvider.notifier)
                  .runHealthCheck(serviceId: state.services[index].id),
              cs: cs,
            );
          },
        );
      },
    );
  }

  // ─── Schedule Maintenance Button ────────────────────────────────────────

  Widget _buildScheduleMaintenanceButton(ColorScheme cs) {
    return FilledButton.tonal(
      onPressed: _showScheduleMaintenanceDialog,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, size: 18),
          SizedBox(width: Spacings.sm),
          Text('Schedule Maintenance'),
        ],
      ),
    );
  }

  // ─── Maintenance Windows ────────────────────────────────────────────────

  Widget _buildMaintenanceWindows(
      InfrastructureMonitoringState state, ColorScheme cs) {
    final windows = state.maintenanceWindows;

    if (windows.isEmpty) {
      return const AdminEmptyState(
        message: 'No maintenance windows scheduled.',
        icon: Icons.calendar_today_outlined,
      );
    }

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: Spacings.paddingAll,
        itemCount: windows.length,
        separatorBuilder: (_, __) => const Divider(height: Spacings.lg),
        itemBuilder: (context, index) {
          return _MaintenanceWindowTile(
            window: windows[index],
            onCancel: windows[index].status == MaintenanceStatus.scheduled
                ? () => ref
                    .read(infrastructureMonitoringProvider.notifier)
                    .cancelMaintenanceWindow(windows[index].id)
                : null,
            cs: cs,
          );
        },
      ),
    );
  }

  // ─── Schedule Maintenance Dialog ────────────────────────────────────────

  void _showScheduleMaintenanceDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startAt;
    DateTime? endAt;
    final selectedServices = <String>[];

    final services =
        ref.read(infrastructureMonitoringProvider).services;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule Maintenance Window'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Spacings.md),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: Spacings.md),
                      // Start time picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_arrow),
                        title: Text(
                          startAt != null
                              ? _formatDateTime(startAt!)
                              : 'Select start time',
                          style: AppTypography.wRegular.copyWith(
                            fontSize: 14,
                            color: startAt != null
                                ? null
                                : AppColors.info,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(context, startAt);
                          if (picked != null) {
                            setDialogState(() => startAt = picked);
                          }
                        },
                      ),
                      // End time picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.stop),
                        title: Text(
                          endAt != null
                              ? _formatDateTime(endAt!)
                              : 'Select end time',
                          style: AppTypography.wRegular.copyWith(
                            fontSize: 14,
                            color: endAt != null
                                ? null
                                : AppColors.info,
                          ),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 20),
                        onTap: () async {
                          final picked = await _pickDateTime(context, endAt);
                          if (picked != null) {
                            setDialogState(() => endAt = picked);
                          }
                        },
                      ),
                      const SizedBox(height: Spacings.sm),
                      Text(
                        'Affected Services',
                        style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: Spacings.sm),
                      Wrap(
                        spacing: Spacings.sm,
                        runSpacing: Spacings.sm,
                        children: services.map((service) {
                          final isSelected = selectedServices
                              .contains(service.serviceName);
                          return FilterChip(
                            label: Text(service.serviceName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedServices.add(service.serviceName);
                                } else {
                                  selectedServices.remove(service.serviceName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        startAt == null ||
                        endAt == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Title, start time, and end time are required')),
                      );
                      return;
                    }
                    final window = MaintenanceWindow(
                      id: '',
                      title: titleController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      status: MaintenanceStatus.scheduled,
                      affectedServices: selectedServices.isEmpty
                          ? null
                          : selectedServices,
                      startAt: startAt!,
                      endAt: endAt!,
                      isPlanned: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    ref
                        .read(infrastructureMonitoringProvider.notifier)
                        .createMaintenanceWindow(window);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Date/Time Picker Helper ─────────────────────────────────────────────

  Future<DateTime?> _pickDateTime(
      BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
  }

  // ─── Formatting Helpers ─────────────────────────────────────────────────

  static String _formatDateTime(DateTime dt) {
    final month = _monthShort(dt.month);
    return '$month ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _monthShort(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE STATUS CARD — Single infrastructure service card
// ═══════════════════════════════════════════════════════════════════════════════

class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({
    required this.service,
    required this.isRunningHealthCheck,
    required this.onRunHealthCheck,
    required this.cs,
  });

  final InfrastructureService service;
  final bool isRunningHealthCheck;
  final VoidCallback onRunHealthCheck;
  final ColorScheme cs;

  Color _responseTimeColor(int? ms) {
    if (ms == null) return cs.onSurface.withOpacity(0.4);
    if (ms < 500) return AppColors.success;
    if (ms < 2000) return AppColors.warning;
    return AppColors.error;
  }

  Color _errorRateColor(double rate) {
    if (rate < 1) return AppColors.success;
    if (rate < 5) return AppColors.warning;
    return AppColors.error;
  }

  String _formatLastCheck(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: service.isCritical ? Spacings.elevationMd : Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: service.isCritical && service.isAlerting
            ? const BorderSide(color: AppColors.error, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: name + badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.serviceName,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (service.isCritical) ...[
                  const SizedBox(width: Spacings.sm),
                  StatusBadge(
                    label: 'Critical',
                    color: AppColors.error,
                    icon: Icons.warning_amber,
                  ),
                ],
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // Type badge + Health indicator
            Row(
              children: [
                StatusBadge(
                  label: service.serviceType,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.md),
                HealthIndicator(status: service.healthStatus),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // Response time
            _buildMetricRow(
              icon: Icons.speed,
              label: 'Response',
              value: service.responseTimeMs != null
                  ? '${service.responseTimeMs}ms'
                  : 'N/A',
              valueColor: _responseTimeColor(service.responseTimeMs),
            ),
            const SizedBox(height: Spacings.sm),

            // Uptime
            _buildMetricRow(
              icon: Icons.timeline,
              label: 'Uptime',
              value: '${service.uptimePercentage.toStringAsFixed(1)}%',
              valueColor: service.uptimePercentage >= 99.9
                  ? AppColors.success
                  : service.uptimePercentage >= 99
                      ? AppColors.warning
                      : AppColors.error,
            ),
            const SizedBox(height: Spacings.sm),

            // Error rate
            _buildMetricRow(
              icon: Icons.error_outline,
              label: 'Error Rate',
              value: '${service.errorRate.toStringAsFixed(1)}%',
              valueColor: _errorRateColor(service.errorRate),
            ),
            const SizedBox(height: Spacings.sm),

            // Last check
            _buildMetricRow(
              icon: Icons.schedule,
              label: 'Last Check',
              value: _formatLastCheck(service.lastCheckAt),
              valueColor: cs.onSurface.withOpacity(0.6),
            ),

            const Spacer(),

            // Run Health Check button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRunningHealthCheck ? null : onRunHealthCheck,
                icon: isRunningHealthCheck
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  isRunningHealthCheck ? 'Checking...' : 'Run Health Check',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.md, vertical: Spacings.sm),
                  textStyle: AppTypography.wSemiBold.copyWith(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: Spacings.sm),
        Text(
          label,
          style: AppTypography.wRegular.copyWith(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.wSemiBold.copyWith(
            fontSize: 12,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAINTENANCE WINDOW TILE — Single maintenance window row
// ═══════════════════════════════════════════════════════════════════════════════

class _MaintenanceWindowTile extends StatelessWidget {
  const _MaintenanceWindowTile({
    required this.window,
    this.onCancel,
    required this.cs,
  });

  final MaintenanceWindow window;
  final VoidCallback? onCancel;
  final ColorScheme cs;

  Color _statusColor() {
    switch (window.status) {
      case MaintenanceStatus.scheduled:
        return AppColors.info;
      case MaintenanceStatus.inProgress:
        return AppColors.warning;
      case MaintenanceStatus.completed:
        return AppColors.success;
      case MaintenanceStatus.cancelled:
        return cs.onSurface.withOpacity(0.4);
    }
  }

  IconData _statusIcon() {
    switch (window.status) {
      case MaintenanceStatus.scheduled:
        return Icons.schedule;
      case MaintenanceStatus.inProgress:
        return Icons.engineering;
      case MaintenanceStatus.completed:
        return Icons.check_circle;
      case MaintenanceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                window.title,
                style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            StatusBadge(
              label: window.status.label,
              color: statusColor,
              icon: _statusIcon(),
            ),
          ],
        ),
        if (window.description != null &&
            window.description!.isNotEmpty) ...[
          const SizedBox(height: Spacings.xs),
          Text(
            window.description!,
            style: AppTypography.wRegular.copyWith(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: Spacings.sm),
        Row(
          children: [
            Icon(Icons.play_arrow, size: 14,
                color: cs.onSurface.withOpacity(0.5)),
            const SizedBox(width: Spacings.xs),
            Text(
              _formatDateTime(window.startAt),
              style: AppTypography.wRegular.copyWith(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: Spacings.lg),
            Icon(Icons.stop, size: 14,
                color: cs.onSurface.withOpacity(0.5)),
            const SizedBox(width: Spacings.xs),
            Text(
              _formatDateTime(window.endAt),
              style: AppTypography.wRegular.copyWith(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        if (window.affectedServices != null &&
            window.affectedServices!.isNotEmpty) ...[
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.xs,
            runSpacing: Spacings.xs,
            children: window.affectedServices!.map((s) {
              return Chip(
                label: Text(s, style: AppTypography.wRegular.copyWith(fontSize: 11)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
        if (onCancel != null) ...[
          const SizedBox(height: Spacings.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('Cancel Window'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
