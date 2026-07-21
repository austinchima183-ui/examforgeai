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
// AI MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin AI Management Console.
///
/// Monitors and controls AI providers including:
/// - Provider cards with status, budget, cost, and rate limit info
/// - Add provider dialog
/// - Request logs data table with filters
/// - Usage analytics summary
class AIManagementPage extends ConsumerStatefulWidget {
  const AIManagementPage({super.key});

  @override
  ConsumerState<AIManagementPage> createState() => _AIManagementPageState();
}

class _AIManagementPageState extends ConsumerState<AIManagementPage> {
  String? _filterProviderId;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(aiManagementProvider.notifier).loadProviders();
    ref.read(aiManagementProvider.notifier).loadRequestLogs(
      providerId: _filterProviderId,
      startDate: _filterDateRange?.start,
      endDate: _filterDateRange?.end,
    );
  }

  // ─── Provider Status Color ──────────────────────────────────────────────

  Color _providerStatusColor(AIProviderStatus status) {
    switch (status) {
      case AIProviderStatus.active:
        return AppColors.success;
      case AIProviderStatus.inactive:
        return AppColors.error;
      case AIProviderStatus.degraded:
        return AppColors.warning;
      case AIProviderStatus.maintenance:
        return AppColors.info;
      case AIProviderStatus.suspended:
        return AppColors.error;
    }
  }

  IconData _providerStatusIcon(AIProviderStatus status) {
    switch (status) {
      case AIProviderStatus.active:
        return Icons.check_circle;
      case AIProviderStatus.inactive:
        return Icons.cancel;
      case AIProviderStatus.degraded:
        return Icons.warning_amber;
      case AIProviderStatus.maintenance:
        return Icons.build;
      case AIProviderStatus.suspended:
        return Icons.block;
    }
  }

  Color _budgetBarColor(double utilization) {
    if (utilization >= 90) return AppColors.error;
    if (utilization >= 70) return AppColors.warning;
    return AppColors.success;
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiManagementProvider);
    final cs = Theme.of(context).colorScheme;

    // Success snackbar
    ref.listen<AIManagementState>(aiManagementProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(aiManagementProvider.notifier).state = ref.read(aiManagementProvider).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(aiManagementProvider.notifier).state = ref.read(aiManagementProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Management Console',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: state.isLoading && state.providers.isEmpty
          ? const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null && state.providers.isEmpty
              ? _buildErrorState(state.error!, cs)
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Spacings.paddingScreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Usage Analytics Summary ───────────────────
                        _buildUsageAnalytics(state, cs),
                        Spacings.sectionGap,

                        // ─── Provider Cards ────────────────────────────
                        SectionHeader(
                          title: 'AI Providers',
                          subtitle: '${state.providers.length} provider(s) configured',
                          action: FilledButton.icon(
                            onPressed: () => _showAddProviderDialog(context),
                            icon: const Icon(Icons.add, size: Spacings.smIcon),
                            label: const Text('Add Provider'),
                          ),
                        ),
                        const SizedBox(height: Spacings.md),
                        if (state.providers.isEmpty)
                          const AdminEmptyState(
                            message: 'No AI providers configured. Add one to get started.',
                            icon: Icons.smart_toy_outlined,
                          )
                        else
                          ...state.providers.map((provider) => Padding(
                            padding: const EdgeInsets.only(bottom: Spacings.md),
                            child: _ProviderCard(
                              provider: provider,
                              statusColor: _providerStatusColor(provider.status),
                              statusIcon: _providerStatusIcon(provider.status),
                              budgetBarColor: _budgetBarColor(provider.budgetUtilization),
                              onSetDefault: () => ref
                                  .read(aiManagementProvider.notifier)
                                  .setDefault(provider.id),
                              onToggle: () => ref
                                  .read(aiManagementProvider.notifier)
                                  .toggleProvider(provider.id, !provider.isActive),
                              onEdit: () => _showEditProviderDialog(context, provider),
                            ),
                          )),

                        Spacings.sectionGap,

                        // ─── Request Logs ──────────────────────────────
                        SectionHeader(
                          title: 'Request Logs',
                          subtitle: 'Recent AI API requests',
                          action: _buildLogFilters(cs),
                        ),
                        const SizedBox(height: Spacings.md),
                        _buildRequestLogsTable(state, cs),
                      ],
                    ),
                  ),
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
                color: cs.onSurface.withOpacity(0.7),
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

  // ─── Usage Analytics Summary ────────────────────────────────────────────

  Widget _buildUsageAnalytics(AIManagementState state, ColorScheme cs) {
    final analytics = state.usageAnalytics;
    final totalRequests = analytics?['totalRequests'] as int? ?? 0;
    final totalCost = analytics?['totalCost'] as double? ?? 0.0;
    final avgLatency = analytics?['averageLatencyMs'] as double? ?? 0.0;
    final successRate = analytics?['successRate'] as double? ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Total Requests',
            value: _formatNumber(totalRequests),
            icon: Icons.api,
            color: AppColors.info,
            subtitle: 'This month',
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: MetricCard(
            title: 'Total Cost',
            value: '\$${totalCost.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: AppColors.success,
            subtitle: 'This month',
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: MetricCard(
            title: 'Avg Latency',
            value: '${avgLatency.toStringAsFixed(0)}ms',
            icon: Icons.speed,
            color: AppColors.warning,
            subtitle: 'Average response time',
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: MetricCard(
            title: 'Success Rate',
            value: '${successRate.toStringAsFixed(1)}%',
            icon: Icons.check_circle_outline,
            color: successRate >= 95 ? AppColors.success : AppColors.warning,
            subtitle: 'Request success',
          ),
        ),
      ],
    );
  }

  // ─── Log Filters ────────────────────────────────────────────────────────

  Widget _buildLogFilters(ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Provider filter dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline.withOpacity(0.3)),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: DropdownButton<String?>(
            value: _filterProviderId,
            hint: const Text('Provider', style: TextStyle(fontSize: 12)),
            underline: const SizedBox.shrink(),
            isDense: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All Providers')),
              ...ref.read(aiManagementProvider).providers.map(
                    (p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
                  ),
            ],
            onChanged: (value) {
              setState(() => _filterProviderId = value);
              ref.read(aiManagementProvider.notifier).loadRequestLogs(
                    providerId: value,
                    startDate: _filterDateRange?.start,
                    endDate: _filterDateRange?.end,
                  );
            },
          ),
        ),
        const SizedBox(width: Spacings.sm),
        // Date range filter
        IconButton.outlined(
          onPressed: _pickDateRange,
          icon: const Icon(Icons.date_range, size: Spacings.mdIcon),
          tooltip: 'Filter by date range',
        ),
        if (_filterDateRange != null)
          IconButton(
            onPressed: () {
              setState(() => _filterDateRange = null);
              ref.read(aiManagementProvider.notifier).loadRequestLogs(
                    providerId: _filterProviderId,
                  );
            },
            icon: const Icon(Icons.clear, size: Spacings.mdIcon),
            tooltip: 'Clear date filter',
          ),
      ],
    );
  }

  // ─── Request Logs DataTable ─────────────────────────────────────────────

  Widget _buildRequestLogsTable(AIManagementState state, ColorScheme cs) {
    final logs = state.requestLogs;

    if (logs.isEmpty) {
      return const AdminEmptyState(
        message: 'No request logs found.',
        icon: Icons.receipt_long_outlined,
      );
    }

    // Build a name lookup map from provider id → name
    final providerNameMap = <String, String>{};
    for (final p in state.providers) {
      providerNameMap[p.id] = p.name;
    }

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: Spacings.xl,
          headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHighest),
          columns: [
            DataColumn(label: _tableHeader('Timestamp', cs)),
            DataColumn(label: _tableHeader('Provider', cs)),
            DataColumn(label: _tableHeader('Model', cs)),
            DataColumn(label: _tableHeader('Request Type', cs)),
            DataColumn(label: _tableHeader('Tokens In', cs)),
            DataColumn(label: _tableHeader('Tokens Out', cs)),
            DataColumn(label: _tableHeader('Total Tokens', cs)),
            DataColumn(label: _tableHeader('Cost', cs)),
            DataColumn(label: _tableHeader('Latency', cs)),
            DataColumn(label: _tableHeader('Status', cs)),
          ],
          rows: logs.map((log) {
            final isSuccess = log.isSuccess;
            return DataRow(
              cells: [
                DataCell(Text(
                  _formatTimestamp(log.createdAt),
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  providerNameMap[log.providerId] ?? log.providerId.substring(0, 8),
                  style: AppTypography.wMedium.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  log.model,
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  log.requestType,
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  _formatNumber(log.inputTokens),
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  _formatNumber(log.outputTokens),
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  _formatNumber(log.totalTokens),
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  '\$${log.cost.toStringAsFixed(4)}',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 12),
                )),
                DataCell(Text(
                  '${log.latencyMs}ms',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: log.latencyMs > 3000
                        ? AppColors.error
                        : log.latencyMs > 1500
                            ? AppColors.warning
                            : null,
                  ),
                )),
                DataCell(
                  StatusBadge(
                    label: isSuccess ? 'Success' : 'Failed',
                    color: isSuccess ? AppColors.success : AppColors.error,
                    icon: isSuccess ? Icons.check_circle : Icons.error,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _tableHeader(String text, ColorScheme cs) {
    return Text(
      text,
      style: AppTypography.wSemiBold.copyWith(
        fontSize: 12,
        color: cs.onSurface.withOpacity(0.7),
      ),
    );
  }

  // ─── Date Range Picker ──────────────────────────────────────────────────

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      initialDateRange: _filterDateRange,
    );
    if (picked != null) {
      setState(() => _filterDateRange = picked);
      ref.read(aiManagementProvider.notifier).loadRequestLogs(
            providerId: _filterProviderId,
            startDate: picked.start,
            endDate: picked.end,
          );
    }
  }

  // ─── Add Provider Dialog ────────────────────────────────────────────────

  void _showAddProviderDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final costInCtrl = TextEditingController();
    final costOutCtrl = TextEditingController();
    final rateMinCtrl = TextEditingController(text: '60');
    final rateDayCtrl = TextEditingController(text: '10000');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add AI Provider', style: AppTypography.wBold.copyWith(fontSize: 18)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Provider Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: slugCtrl,
                  decoration: const InputDecoration(labelText: 'Slug *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(labelText: 'Provider Type * (e.g. openai, google)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'API Base URL *'),
                  keyboardType: TextInputType.url,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Default Model'),
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: costInCtrl,
                        decoration: const InputDecoration(labelText: 'Cost/1K In'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: TextFormField(
                        controller: costOutCtrl,
                        decoration: const InputDecoration(labelText: 'Cost/1K Out'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: budgetCtrl,
                  decoration: const InputDecoration(labelText: 'Monthly Budget (\$)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: rateMinCtrl,
                        decoration: const InputDecoration(labelText: 'Rate/Min'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: TextFormField(
                        controller: rateDayCtrl,
                        decoration: const InputDecoration(labelText: 'Rate/Day'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              final provider = AIProvider(
                id: '',
                name: nameCtrl.text.trim(),
                slug: slugCtrl.text.trim(),
                providerType: typeCtrl.text.trim(),
                apiBaseUrl: urlCtrl.text.trim(),
                defaultModel: modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : null,
                costPer1kInputTokens: double.tryParse(costInCtrl.text) ?? 0,
                costPer1kOutputTokens: double.tryParse(costOutCtrl.text) ?? 0,
                monthlyBudget: double.tryParse(budgetCtrl.text),
                rateLimitPerMinute: int.tryParse(rateMinCtrl.text) ?? 60,
                rateLimitPerDay: int.tryParse(rateDayCtrl.text) ?? 10000,
                status: AIProviderStatus.active,
                createdAt: now,
                updatedAt: now,
              );
              ref.read(aiManagementProvider.notifier).createProvider(provider);
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Provider'),
          ),
        ],
      ),
    );
  }

  // ─── Edit Provider Dialog ───────────────────────────────────────────────

  void _showEditProviderDialog(BuildContext context, AIProvider provider) {
    final nameCtrl = TextEditingController(text: provider.name);
    final urlCtrl = TextEditingController(text: provider.apiBaseUrl);
    final modelCtrl = TextEditingController(text: provider.defaultModel ?? '');
    final budgetCtrl = TextEditingController(
      text: provider.monthlyBudget?.toStringAsFixed(2) ?? '',
    );
    final costInCtrl = TextEditingController(text: provider.costPer1kInputTokens.toString());
    final costOutCtrl = TextEditingController(text: provider.costPer1kOutputTokens.toString());
    final rateMinCtrl = TextEditingController(text: provider.rateLimitPerMinute.toString());
    final rateDayCtrl = TextEditingController(text: provider.rateLimitPerDay.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${provider.name}', style: AppTypography.wBold.copyWith(fontSize: 18)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Provider Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'API Base URL'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(labelText: 'Default Model'),
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: costInCtrl,
                        decoration: const InputDecoration(labelText: 'Cost/1K In'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: TextFormField(
                        controller: costOutCtrl,
                        decoration: const InputDecoration(labelText: 'Cost/1K Out'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                TextFormField(
                  controller: budgetCtrl,
                  decoration: const InputDecoration(labelText: 'Monthly Budget (\$)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: rateMinCtrl,
                        decoration: const InputDecoration(labelText: 'Rate/Min'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: TextFormField(
                        controller: rateDayCtrl,
                        decoration: const InputDecoration(labelText: 'Rate/Day'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final updated = provider.copyWith(
                name: nameCtrl.text.trim(),
                apiBaseUrl: urlCtrl.text.trim(),
                defaultModel: modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : null,
                costPer1kInputTokens: double.tryParse(costInCtrl.text) ?? provider.costPer1kInputTokens,
                costPer1kOutputTokens: double.tryParse(costOutCtrl.text) ?? provider.costPer1kOutputTokens,
                monthlyBudget: double.tryParse(budgetCtrl.text) ?? provider.monthlyBudget,
                rateLimitPerMinute: int.tryParse(rateMinCtrl.text) ?? provider.rateLimitPerMinute,
                rateLimitPerDay: int.tryParse(rateDayCtrl.text) ?? provider.rateLimitPerDay,
              );
              ref.read(aiManagementProvider.notifier).updateProvider(updated);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROVIDER CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.statusColor,
    required this.statusIcon,
    required this.budgetBarColor,
    required this.onSetDefault,
    required this.onToggle,
    required this.onEdit,
  });

  final AIProvider provider;
  final Color statusColor;
  final IconData statusIcon;
  final Color budgetBarColor;
  final VoidCallback onSetDefault;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final utilization = provider.budgetUtilization;

    return Card(
      elevation: provider.isDefault ? Spacings.elevationMd : Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: provider.isDefault
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy, color: cs.primary, size: Spacings.lgIcon),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    provider.name,
                                    style: AppTypography.wSemiBold.copyWith(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (provider.isDefault) ...[
                                  const SizedBox(width: Spacings.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacings.sm,
                                      vertical: Spacings.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(0.1),
                                      borderRadius: Spacings.borderRadiusSm,
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: AppTypography.wBold.copyWith(
                                        fontSize: 10,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: Spacings.xs),
                            Text(
                              provider.slug,
                              style: AppTypography.wRegular.copyWith(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: provider.status.label,
                  color: statusColor,
                  icon: statusIcon,
                ),
              ],
            ),

            const SizedBox(height: Spacings.md),

            // ─── Budget Utilization ────────────────────────────────────
            if (provider.monthlyBudget != null) ...[
              Row(
                children: [
                  Text(
                    'Monthly Budget',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${provider.currentMonthSpend.toStringAsFixed(2)} / \$${provider.monthlyBudget!.toStringAsFixed(2)}',
                    style: AppTypography.wSemiBold.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xs),
              ClipRRect(
                borderRadius: Spacings.borderRadiusFull,
                child: LinearProgressIndicator(
                  value: (utilization / 100).clamp(0.0, 1.0),
                  backgroundColor: cs.surfaceContainerHighest,
                  color: budgetBarColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Row(
                children: [
                  Text(
                    '${utilization.toStringAsFixed(1)}% utilized',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 11,
                      color: budgetBarColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
            ] else ...[
              Row(
                children: [
                  Text(
                    'Current Spend: ',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '\$${provider.currentMonthSpend.toStringAsFixed(2)}',
                    style: AppTypography.wSemiBold.copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: Spacings.md),
                  Text(
                    '(No budget set)',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 11,
                      color: cs.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
            ],

            // ─── Cost & Rate Info ──────────────────────────────────────
            Wrap(
              spacing: Spacings.lg,
              runSpacing: Spacings.sm,
              children: [
                _infoChip(
                  icon: Icons.input,
                  label: 'In: \$${provider.costPer1kInputTokens.toStringAsFixed(3)}/1K',
                  cs: cs,
                ),
                _infoChip(
                  icon: Icons.output,
                  label: 'Out: \$${provider.costPer1kOutputTokens.toStringAsFixed(3)}/1K',
                  cs: cs,
                ),
                _infoChip(
                  icon: Icons.timer,
                  label: '${provider.rateLimitPerMinute}/min',
                  cs: cs,
                ),
                _infoChip(
                  icon: Icons.today,
                  label: '${provider.rateLimitPerDay}/day',
                  cs: cs,
                ),
                if (provider.defaultModel != null)
                  _infoChip(
                    icon: Icons.memory,
                    label: provider.defaultModel!,
                    cs: cs,
                  ),
              ],
            ),

            const SizedBox(height: Spacings.md),

            // ─── Actions ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!provider.isDefault)
                  OutlinedButton.icon(
                    onPressed: onSetDefault,
                    icon: const Icon(Icons.star_outline, size: Spacings.smIcon),
                    label: const Text('Set Default'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const SizedBox(width: Spacings.sm),
                FilledButton.tonalIcon(
                  onPressed: onToggle,
                  icon: Icon(
                    provider.isActive ? Icons.pause : Icons.play_arrow,
                    size: Spacings.smIcon,
                  ),
                  label: Text(provider.isActive ? 'Disable' : 'Enable'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                IconButton.outlined(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: Spacings.mdIcon),
                  tooltip: 'Edit Provider',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required ColorScheme cs,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.5)),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: AppTypography.wRegular.copyWith(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
