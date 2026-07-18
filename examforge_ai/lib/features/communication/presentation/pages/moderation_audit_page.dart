import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/moderation_provider.dart';

/// Communication audit logs and moderation page (admin only).
///
/// Displays:
/// - Audit log entries with action, user, resource, timestamp
/// - Severity badges (info, warning, critical)
/// - Filter by action type and resource type
class ModerationAuditPage extends ConsumerStatefulWidget {
  const ModerationAuditPage({super.key});

  @override
  ConsumerState<ModerationAuditPage> createState() => _State();
}

class _State extends ConsumerState<ModerationAuditPage> {
  String? _actionFilter;
  String? _resourceFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  void _loadLogs() {
    ref.read(moderationProvider.notifier).loadAuditLogs(
          action: _actionFilter,
          resourceType: _resourceFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Audit Logs',
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: cs.onSurface),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ModerationState state) {
    if (state.isLoading && state.auditLogs.isEmpty) {
      return const AppLoading();
    }

    if (state.error != null && state.auditLogs.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: _loadLogs,
      );
    }

    if (state.auditLogs.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Audit Logs',
        subtitle: 'Communication activity will be logged here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadLogs(),
      child: ListView.separated(
        padding: Spacings.paddingScreen,
        itemCount: state.auditLogs.length,
        separatorBuilder: (_, __) => Divider(height: Spacings.xs),
        itemBuilder: (context, index) {
          final log = state.auditLogs[index];
          return _buildLogTile(context, log);
        },
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, CommunicationAuditLogEntity log) {
    final cs = Theme.of(context).colorScheme;
    final severityColor = _severityColor(log.severity);
    final timeStr = _formatTime(log.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: severityColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Row(
        children: [
          Text(
            log.action.replaceAll('_', ' ').toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: severityColor,
              fontWeight: AppTypography.wBold,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Text(
              log.resourceType,
              style: AppTypography.caption.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacings.xs),
          Text(
            '${log.userName} (${log.userRole})',
            style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          if (log.details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              log.details.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: cs.outline),
            ),
          ],
        ],
      ),
      trailing: Text(
        timeStr,
        style: AppTypography.caption.copyWith(color: cs.outline),
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showFilterDialog() {
    final actions = [
      'sent_message', 'edited_message', 'deleted_message', 'pinned_message',
      'created_announcement', 'reported_message', 'created_forum_post',
      'created_conversation', 'added_participant', 'removed_participant',
    ];
    final resourceTypes = [
      'conversation', 'message', 'announcement', 'forum_post', 'forum_comment',
      'calendar_event', 'notification',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Audit Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action', style: AppTypography.titleSmall),
            const SizedBox(height: Spacings.xs),
            DropdownButton<String>(
              value: _actionFilter,
              hint: const Text('All actions'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All actions')),
                ...actions.map((a) => DropdownMenuItem(
                      value: a,
                      child: Text(a.replaceAll('_', ' ')),
                    )),
              ],
              onChanged: (v) => setState(() => _actionFilter = v),
            ),
            const SizedBox(height: Spacings.lg),
            Text('Resource Type', style: AppTypography.titleSmall),
            const SizedBox(height: Spacings.xs),
            DropdownButton<String>(
              value: _resourceFilter,
              hint: const Text('All types'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All types')),
                ...resourceTypes.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.replaceAll('_', ' ')),
                    )),
              ],
              onChanged: (v) => setState(() => _resourceFilter = v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _actionFilter = null;
                _resourceFilter = null;
              });
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _loadLogs();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
