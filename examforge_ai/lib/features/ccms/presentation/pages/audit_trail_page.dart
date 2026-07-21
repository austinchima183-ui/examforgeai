import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class AuditTrailPage extends ConsumerStatefulWidget {
  const AuditTrailPage({super.key});

  @override
  ConsumerState<AuditTrailPage> createState() => _AuditTrailPageState();
}

class _AuditTrailPageState extends ConsumerState<AuditTrailPage> {
  AuditAction? _filterAction;
  String? _filterResourceType;
  String? _filterUserId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enterpriseProvider.notifier).loadAuditTrail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enterpriseProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    var filtered = state.auditTrail.where((entry) {
      if (_filterAction != null && entry.action != _filterAction) {
        return false;
      }
      if (_filterResourceType != null &&
          entry.resourceType != _filterResourceType) return false;
      if (_filterUserId != null &&
          _filterUserId!.isNotEmpty &&
          !entry.userId
              .toLowerCase()
              .contains(_filterUserId!.toLowerCase())) return false;
      if (_dateRange != null) {
        if (entry.timestamp.isBefore(_dateRange!.start) ||
            entry.timestamp.isAfter(_dateRange!.end)) return false;
      }
      return true;
    }).toList();

    final resourceTypes =
        state.auditTrail.map((e) => e.resourceType).toSet().toList()
          ..sort();

    final userIds =
        state.auditTrail.map((e) => e.userId).toSet().toList()..sort();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Audit Trail',
        actions: [
          AppIconButton(
            icon: Icons.download_rounded,
            onPressed: _exportCsv,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: Spacings.paddingScreen,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AuditAction?>(
                        value: _filterAction,
                        decoration: const InputDecoration(
                            labelText: 'Action',
                            isDense: true,
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Actions')),
                          ...AuditAction.values.map((a) => DropdownMenuItem(
                              value: a, child: Text(a.label))),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterAction = v),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filterResourceType,
                        decoration: const InputDecoration(
                            labelText: 'Resource Type',
                            isDense: true,
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Types')),
                          ...resourceTypes.map((t) => DropdownMenuItem(
                              value: t, child: Text(t))),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterResourceType = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filterUserId,
                        decoration: const InputDecoration(
                            labelText: 'User',
                            isDense: true,
                            border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Users')),
                          ...userIds.map((u) => DropdownMenuItem(
                              value: u, child: Text(u))),
                        ],
                        onChanged: (v) =>
                            setState(() => _filterUserId = v),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    AppButton(
                      label: _dateRange != null
                          ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                          : 'Date Range',
                      onPressed: () async {
                        final range =
                            await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (range != null) {
                          setState(() => _dateRange = range);
                        }
                      },
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      icon: Icons.date_range_rounded,
                    ),
                    if (_dateRange != null) ...[
                      const SizedBox(width: Spacings.xs),
                      AppIconButton(
                        icon: Icons.clear_rounded,
                        onPressed: () =>
                            setState(() => _dateRange = null),
                        size: AppButtonSize.small,
                        tooltip: 'Clear date range',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Audit list
          Expanded(
            child: state.isLoading && state.auditTrail.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : state.error != null
                    ? AppErrorState(
                        message: state.error,
                        onRetry: () => ref
                            .read(enterpriseProvider.notifier)
                            .loadAuditTrail(),
                      )
                    : filtered.isEmpty
                        ? AppEmptyState.noResults(
                            subtitle:
                                'No audit entries match your filters')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.lg),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                AuditEntryTile(
                              entry: filtered[index],
                              onTap: () =>
                                  _showDetail(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showDetail(AuditEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.action.label} - ${entry.resourceType}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User', entry.userId),
              _detailRow('Resource ID', entry.resourceId),
              _detailRow(
                  'Timestamp', _formatDateTime(entry.timestamp)),
              _detailRow('Action', entry.action.label),
              if (entry.oldValues != null) ...[
                const SizedBox(height: Spacings.md),
                Text('Old Values:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: Spacings.xs),
                Container(
                  width: double.infinity,
                  padding: Spacings.paddingCard,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: Spacings.borderRadiusMd,
                    border: Border.all(
                        color:
                            AppColors.error.withOpacity(0.2)),
                  ),
                  child: Text(entry.oldValues.toString(),
                      style: AppTypography.bodySmall),
                ),
              ],
              if (entry.newValues != null) ...[
                const SizedBox(height: Spacings.md),
                Text('New Values:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: Spacings.xs),
                Container(
                  width: double.infinity,
                  padding: Spacings.paddingCard,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: Spacings.borderRadiusMd,
                    border: Border.all(
                        color: AppColors.success
                            .withOpacity(0.2)),
                  ),
                  child: Text(entry.newValues.toString(),
                      style: AppTypography.bodySmall),
                ),
              ],
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.text,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: AppTypography.wSemiBold)),
          ),
          Expanded(
              child: Text(value, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Exporting audit trail as CSV…')),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  String _formatDateTime(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
