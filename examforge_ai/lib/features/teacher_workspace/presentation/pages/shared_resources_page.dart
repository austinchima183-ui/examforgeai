import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/collaboration_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// SHARED RESOURCES PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page showing resources shared with the teacher and by the teacher,
/// with tabs for Shared With Me, Shared By Me, and Pending invitations.
class SharedResourcesPage extends ConsumerStatefulWidget {
  const SharedResourcesPage({super.key});

  @override
  ConsumerState<SharedResourcesPage> createState() =>
      _SharedResourcesPageState();
}

class _SharedResourcesPageState extends ConsumerState<SharedResourcesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _SharedResourceTab.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collaborationProvider.notifier).loadSharedResources();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(collaborationProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(collaborationProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(collaborationProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(collaborationProvider.notifier).loadSharedResources();
    _listenForMessages();
  }

  void _handleAccept(String id) {
    ref.read(collaborationProvider.notifier).acceptSharedResource(id);
    _listenForMessages();
  }

  void _handleDecline(String id) {
    ref.read(collaborationProvider.notifier).declineSharedResource(id);
    _listenForMessages();
  }

  void _handleOpenResource(SharedResourceEntity resource) {
    _showSnackBar('Opening resource...', isError: false);
  }

  void _handleAddComment(SharedResourceEntity resource) {
    _showSnackBar('Opening comment dialog...', isError: false);
  }

  List<SharedResourceEntity> _filterByTab(
    List<SharedResourceEntity> resources,
    _SharedResourceTab tab,
  ) {
    // In a real app, we'd filter by current user ID.
    // For now, split based on isAccepted state as a proxy.
    switch (tab) {
      case _SharedResourceTab.sharedWithMe:
        return resources.where((r) => r.isAccepted == true).toList();
      case _SharedResourceTab.sharedByMe:
        // In a real app, filter by sharedBy == current user
        return resources
            .where((r) => r.isAccepted == true)
            .take((resources.length / 2).floor())
            .toList();
      case _SharedResourceTab.pending:
        return resources.where((r) => r.isAccepted == null).toList();
    }
  }

  IconData _getResourceTypeIcon(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'lesson_plan':
        return Icons.description_outlined;
      case 'worksheet':
        return Icons.assignment_outlined;
      case 'rubric':
        return Icons.grid_on_outlined;
      case 'oral_question':
        return Icons.quiz_outlined;
      case 'practical_assessment':
        return Icons.science_outlined;
      case 'presentation':
        return Icons.slideshow_outlined;
      case 'assignment':
        return Icons.task_outlined;
      case 'communication':
        return Icons.mail_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  String _getResourceTypeLabel(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'lesson_plan':
        return 'Lesson Plan';
      case 'worksheet':
        return 'Worksheet';
      case 'rubric':
        return 'Rubric';
      case 'oral_question':
        return 'Oral Questions';
      case 'practical_assessment':
        return 'Practical Assessment';
      case 'presentation':
        return 'Presentation';
      case 'assignment':
        return 'Assignment';
      case 'communication':
        return 'Communication';
      default:
        return 'Resource';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Shared Resources',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _SharedResourceTab.values
              .map((tab) => Tab(
                    icon: Icon(tab.icon),
                    text: tab.label,
                  ),)
              .toList(),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
        ),
      ),
      body: ref.watch(collaborationProvider).isLoading
          ? _buildLoadingShimmer()
          : TabBarView(
              controller: _tabController,
              children: _SharedResourceTab.values
                  .map((tab) => _buildTabContent(tab))
                  .toList(),
            ),
    );
  }

  // ─── Tab Content ─────────────────────────────────────────────────────

  Widget _buildTabContent(_SharedResourceTab tab) {
    final state = ref.watch(collaborationProvider);
    final filtered = _filterByTab(state.sharedResources, tab);

    if (state.error != null && filtered.isEmpty) {
      return _buildErrorState();
    }

    if (filtered.isEmpty) {
      return _buildEmptyState(tab);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: Spacings.paddingScreen,
        itemCount: filtered.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _buildSharedResourceCard(filtered[index], tab),
        ),
      ),
    );
  }

  // ─── Shared Resource Card ────────────────────────────────────────────

  Widget _buildSharedResourceCard(
    SharedResourceEntity resource,
    _SharedResourceTab tab,
  ) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final isPending = tab == _SharedResourceTab.pending;
    final typeIcon = _getResourceTypeIcon(resource.resourceType);
    final typeLabel = _getResourceTypeLabel(resource.resourceType);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + type + date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(typeIcon, size: Spacings.mdIcon, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'ID: ${resource.resourceId.substring(0, resource.resourceId.length > 8 ? 8 : resource.resourceId.length)}...',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Date
              Text(
                _formatDate(resource.createdAt),
                style: context.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Shared by/with
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                tab == _SharedResourceTab.sharedByMe
                    ? 'Shared with: ${resource.sharedWith}'
                    : 'Shared by: ${resource.sharedBy}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ],
          ),

          // Message
          if (resource.message != null && resource.message!.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: Spacings.smIcon, color: cs.onSurfaceVariant,),
                  const SizedBox(width: Spacings.xs),
                  Expanded(
                    child: Text(
                      resource.message!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spacings.md),

          // Permission badges
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.xs,
            children: [
              if (resource.canView)
                _buildPermissionChip(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  color: cs.primary,
                  isDark: isDark,
                ),
              if (resource.canEdit)
                _buildPermissionChip(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: cs.tertiary,
                  isDark: isDark,
                ),
              if (resource.canComment)
                _buildPermissionChip(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: cs.secondary,
                  isDark: isDark,
                ),
              if (resource.canDownload)
                _buildPermissionChip(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  color: cs.primary,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Action buttons
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Accept',
                    onPressed: () => _handleAccept(resource.id),
                    variant: AppButtonVariant.elevated,
                    icon: Icons.check_rounded,
                    size: AppButtonSize.small,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    onPressed: () => _handleDecline(resource.id),
                    variant: AppButtonVariant.outlined,
                    icon: Icons.close_rounded,
                    size: AppButtonSize.small,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                AppButton(
                  label: 'Open',
                  onPressed: () => _handleOpenResource(resource),
                  variant: AppButtonVariant.tonal,
                  icon: Icons.open_in_new_rounded,
                  size: AppButtonSize.small,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Comment',
                  onPressed: () => _handleAddComment(resource),
                  variant: AppButtonVariant.text,
                  icon: Icons.comment_outlined,
                  size: AppButtonSize.small,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── States ──────────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: 5,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppLoadingShimmer.box(width: 40, height: 40),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 150, height: 16),
                  Spacer(),
                  AppLoadingShimmer.box(width: 80, height: 12),
                ],
              ),
              SizedBox(height: Spacings.sm),
              AppLoadingShimmer.box(width: 200, height: 14),
              SizedBox(height: Spacings.sm),
              Row(
                children: [
                  AppLoadingShimmer.box(width: 60, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 50, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 70, height: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(_SharedResourceTab tab) {
    return AppEmptyState(
      icon: tab.icon,
      title: tab.emptyTitle,
      subtitle: tab.emptySubtitle,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(collaborationProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Date Formatting ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER ENUMS
// ═══════════════════════════════════════════════════════════════════════

/// Tabs for the shared resources page.
enum _SharedResourceTab {
  sharedWithMe(
    label: 'Shared With Me',
    icon: Icons.inbox_outlined,
    emptyTitle: 'No Shared Resources',
    emptySubtitle: 'Resources shared with you by colleagues will appear here.',
  ),
  sharedByMe(
    label: 'Shared By Me',
    icon: Icons.outbox_outlined,
    emptyTitle: 'No Shared Resources',
    emptySubtitle: 'Resources you share with colleagues will appear here.',
  ),
  pending(
    label: 'Pending',
    icon: Icons.pending_outlined,
    emptyTitle: 'No Pending Invitations',
    emptySubtitle: 'Pending share invitations will appear here.',
  );

  const _SharedResourceTab({
    required this.label,
    required this.icon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String label;
  final IconData icon;
  final String emptyTitle;
  final String emptySubtitle;
}
