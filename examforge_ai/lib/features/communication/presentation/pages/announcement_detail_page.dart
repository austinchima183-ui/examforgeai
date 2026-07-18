import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/announcement_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Full announcement view.
///
/// Features:
/// - Title, body, author info, type, priority badge, published date
/// - Attachments list (downloadable)
/// - Acknowledge button
/// - View count
/// - For admin: edit/delete buttons
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class AnnouncementDetailPage extends ConsumerStatefulWidget {
  const AnnouncementDetailPage({super.key, required this.announcementId});

  final String announcementId;

  @override
  ConsumerState<AnnouncementDetailPage> createState() => _State();
}

class _State extends ConsumerState<AnnouncementDetailPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementProvider.notifier).loadAnnouncement(widget.announcementId);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementProvider);
    final ann = state.currentAnnouncement;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Announcement',
        actions: [
          if (ann != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // TODO: navigate to edit
                    break;
                  case 'delete':
                    _showDeleteConfirmation(ann);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: AppColors.errorOf(Theme.of(context).colorScheme.brightness))),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state, ann),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(AnnouncementState state, AnnouncementEntity? ann) {
    if (state.isLoading) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null || ann == null) {
      return AppErrorState.genericError(
        message: state.error ?? 'Announcement not found',
        onRetry: () => ref.read(announcementProvider.notifier).loadAnnouncement(widget.announcementId),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Badges Row ────────────────────────────────────────
          _buildBadgesRow(ann),
          const SizedBox(height: Spacings.lg),

          // ─── Title ─────────────────────────────────────────────
          Text(
            ann.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          // ─── Author & Date ─────────────────────────────────────
          _buildAuthorRow(ann),
          const SizedBox(height: Spacings.xl),

          // ─── Body ──────────────────────────────────────────────
          Text(
            ann.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.6,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ─── Attachments ───────────────────────────────────────
          if (ann.attachments.isNotEmpty) _buildAttachments(ann.attachments),

          // ─── Divider ───────────────────────────────────────────
          const Divider(),
          const SizedBox(height: Spacings.md),

          // ─── Stats Row ─────────────────────────────────────────
          _buildStatsRow(ann),
          const SizedBox(height: Spacings.xl),

          // ─── Acknowledge Button ────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: ann.acknowledgedBy.contains('current_user')
                  ? null
                  : () => ref.read(announcementProvider.notifier).acknowledgeAnnouncement(ann.id),
              child: Text(
                ann.acknowledgedBy.contains('current_user')
                    ? '✓ Acknowledged'
                    : 'Acknowledge Announcement',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BADGES ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBadgesRow(AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final priorityColor = _priorityColor(ann.priority, cs.brightness);
    final typeColor = _typeColor(ann.announcementType, cs.brightness);

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.xs),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.12),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            ann.priority.label,
            style: tt.labelMedium?.copyWith(color: priorityColor, fontWeight: AppTypography.wSemiBold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.xs),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            ann.announcementType.label,
            style: tt.labelMedium?.copyWith(color: typeColor, fontWeight: AppTypography.wMedium),
          ),
        ),
        if (ann.isAiGenerated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.xs),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.2),
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.primary),
                const SizedBox(width: Spacings.xs),
                Text('AI Generated', style: tt.labelMedium?.copyWith(color: cs.primary, fontWeight: AppTypography.wMedium)),
              ],
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUTHOR ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAuthorRow(AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: cs.primaryContainer,
          child: Text(
            ann.authorName.isNotEmpty ? ann.authorName[0].toUpperCase() : '?',
            style: tt.labelLarge?.copyWith(color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ann.authorName, style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
              Text('${ann.authorRole} · ${_formatDate(ann.publishedAt ?? ann.createdAt)}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTACHMENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAttachments(List<Map<String, dynamic>> attachments) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
        const SizedBox(height: Spacings.md),
        ...attachments.map((att) => Card(
          elevation: Spacings.elevationNone,
          color: cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusSm),
          child: ListTile(
            leading: Icon(Icons.insert_drive_file_outlined, color: cs.primary),
            title: Text(att['fileName'] ?? 'Attachment', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.download_outlined, color: cs.primary),
              onPressed: () {/* TODO: download */},
            ),
          ),
        )),
        const SizedBox(height: Spacings.lg),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(Icons.visibility_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text('${ann.viewCount} views', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: Spacings.xl),
        Icon(Icons.check_circle_outline, size: Spacings.smIcon, color: AppColors.successOf(cs.brightness)),
        const SizedBox(width: Spacings.xs),
        Text('${ann.acknowledgedBy.length} acknowledged', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DELETE CONFIRMATION
  // ═══════════════════════════════════════════════════════════════════════

  void _showDeleteConfirmation(AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${ann.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: call delete
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorOf(cs.brightness)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _priorityColor(AnnouncementPriority priority, Brightness brightness) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return AppColors.errorOf(brightness);
      case AnnouncementPriority.high:
        return AppColors.warningOf(brightness);
      case AnnouncementPriority.normal:
        return AppColors.infoOf(brightness);
      case AnnouncementPriority.low:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _typeColor(AnnouncementType type, Brightness brightness) {
    switch (type) {
      case AnnouncementType.emergency:
        return AppColors.errorOf(brightness);
      case AnnouncementType.holiday:
        return AppColors.successOf(brightness);
      case AnnouncementType.examination:
        return const Color(0xFF7C3AED);
      default:
        return AppColors.infoOf(brightness);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
