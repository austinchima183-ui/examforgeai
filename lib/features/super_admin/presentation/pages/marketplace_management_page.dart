import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

Color _statusColor(MarketplaceStatus status) {
  switch (status) {
    case MarketplaceStatus.pendingReview:
      return AppColors.info;
    case MarketplaceStatus.approved:
      return AppColors.success;
    case MarketplaceStatus.rejected:
      return AppColors.error;
    case MarketplaceStatus.featured:
      return const Color(0xFFD97706); // Gold/Amber
    case MarketplaceStatus.archived:
      return Colors.grey;
    case MarketplaceStatus.flagged:
      return Colors.orange;
    case MarketplaceStatus.suspended:
      return Colors.blueGrey;
  }
}

Color _contentTypeColor(MarketplaceContentType type) {
  switch (type) {
    case MarketplaceContentType.resource:
      return AppColors.info;
    case MarketplaceContentType.lessonNote:
      return AppColors.success;
    case MarketplaceContentType.worksheet:
      return const Color(0xFF7C3AED);
    case MarketplaceContentType.questionBank:
      return AppColors.warning;
    case MarketplaceContentType.template:
      return const Color(0xFFEA580C);
    case MarketplaceContentType.examFormat:
      return const Color(0xFF06B6D4);
    case MarketplaceContentType.video:
      return AppColors.error;
    case MarketplaceContentType.document:
      return Colors.blueGrey;
  }
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _formatRating(double rating) {
  return rating.toStringAsFixed(1);
}

String _formatPrice(double price) {
  if (price == 0) return 'Free';
  return '\$${price.toStringAsFixed(2)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin page for moderating marketplace content.
///
/// Features:
/// - 2-tab interface: Pending Review, All Content
/// - Pending Review: cards with Approve/Reject/Feature actions
/// - All Content: searchable DataTable with status/type filters and actions
/// - Status badges with distinct colors per status
/// - Reject and Flag dialogs require reason input
class MarketplaceManagementPage extends ConsumerStatefulWidget {
  const MarketplaceManagementPage({super.key});

  @override
  ConsumerState<MarketplaceManagementPage> createState() =>
      _MarketplaceManagementPageState();
}

class _MarketplaceManagementPageState
    extends ConsumerState<MarketplaceManagementPage>
    with SingleTickerProviderStateMixin {
  // ─── Controllers & State ─────────────────────────────────────────────────

  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _rejectReasonController = TextEditingController();
  final _flagReasonController = TextEditingController();

  MarketplaceStatus? _statusFilter;
  MarketplaceContentType? _contentTypeFilter;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _rejectReasonController.dispose();
    _flagReasonController.dispose();
    super.dispose();
  }

  void _loadData() {
    ref.read(marketplaceManagementProvider.notifier).loadPendingContent();
    ref.read(marketplaceManagementProvider.notifier).loadAllContent(
          status: _statusFilter,
          contentType: _contentTypeFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceManagementProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error messages
    ref.listen<MarketplaceManagementState>(marketplaceManagementProvider,
        (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(marketplaceManagementProvider.notifier).state =
            ref.read(marketplaceManagementProvider).clearSuccess();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(marketplaceManagementProvider.notifier).state =
            ref.read(marketplaceManagementProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Marketplace Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pending Review',
              icon: Badge(
                isLabelVisible: state.pendingContent.isNotEmpty,
                label: Text('${state.pendingContent.length}'),
                child: const Icon(Icons.pending_actions_outlined),
              ),
            ),
            const Tab(
              text: 'All Content',
              icon: Icon(Icons.inventory_2_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingReviewTab(state, cs),
          _buildAllContentTab(state, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // PENDING REVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildPendingReviewTab(MarketplaceManagementState state, ColorScheme cs) {
    if (state.isLoading && state.pendingContent.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),);
    }

    if (state.error != null && state.pendingContent.isEmpty) {
      return Center(
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: Spacings.lg),
              Text(
                state.error!,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.lg),
              FilledButton.tonal(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.pendingContent.isEmpty) {
      return const AdminEmptyState(
        message: 'No content pending review.',
        icon: Icons.check_circle_outline,
      );
    }

    return ListView.separated(
      padding: Spacings.paddingScreen,
      itemCount: state.pendingContent.length,
      separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
      itemBuilder: (context, index) =>
          _buildPendingContentCard(state.pendingContent[index], cs),
    );
  }

  Widget _buildPendingContentCard(MarketplaceContent content, ColorScheme cs) {
    final typeColor = _contentTypeColor(content.contentType);

    return Card(
      elevation: Spacings.elevationSm,
      shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Row 1: Thumbnail + Title/Author ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: content.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: Spacings.borderRadiusMd,
                          child: Image.network(
                            content.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_outlined,
                              color: cs.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          size: Spacings.lgIcon,
                          color: cs.onSurface.withValues(alpha: 0.3),
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
                              content.title,
                              style: AppTypography.wSemiBold.copyWith(
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadge(
                            label: content.contentType.label,
                            color: typeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'Author: ${content.authorId}',
                        style: AppTypography.wRegular.copyWith(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Row 2: Subject, Class Level, Curriculum ────────────────
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: [
                if (content.subject != null)
                  StatusBadge(
                    label: content.subject!,
                    color: cs.primary,
                    icon: Icons.subject_outlined,
                  ),
                if (content.classLevel != null)
                  StatusBadge(
                    label: content.classLevel!,
                    color: AppColors.info,
                    icon: Icons.school_outlined,
                  ),
                if (content.curriculum != null)
                  StatusBadge(
                    label: content.curriculum!,
                    color: AppColors.success,
                    icon: Icons.menu_book_outlined,
                  ),
                StatusBadge(
                  label: _formatPrice(content.price),
                  color: content.isFree ? AppColors.success : AppColors.warning,
                  icon: content.isFree ? Icons.card_giftcard : Icons.attach_money,
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Row 3: Description Preview ─────────────────────────────
            Text(
              content.description,
              style: AppTypography.wRegular.copyWith(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // ─── Row 4: Tags ────────────────────────────────────────────
            if (content.tags != null && content.tags!.isNotEmpty) ...[
              const SizedBox(height: Spacings.sm),
              Wrap(
                spacing: Spacings.xs,
                runSpacing: Spacings.xs,
                children: content.tags!
                    .map((tag) => Chip(
                          label: Text(
                            tag,
                            style: AppTypography.wRegular.copyWith(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.sm,),
                        ),)
                    .toList(),
              ),
            ],
            const SizedBox(height: Spacings.lg),

            // ─── Row 5: Action Buttons ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Approve (green)
                FilledButton.icon(
                  onPressed: () => _approveContent(content.id),
                  icon: const Icon(Icons.check_circle_outline, size: Spacings.mdIcon),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: Spacings.sm),

                // Reject (red)
                FilledButton.icon(
                  onPressed: () => _showRejectDialog(content),
                  icon: const Icon(Icons.cancel_outlined, size: Spacings.mdIcon),
                  label: const Text('Reject'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: Spacings.sm),

                // Feature (gold)
                FilledButton.tonal(
                  onPressed: () => _featureContent(content.id),
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_outline,
                          size: Spacings.mdIcon, color: Color(0xFFD97706),),
                      SizedBox(width: Spacings.xs),
                      Text('Feature'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ALL CONTENT TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAllContentTab(MarketplaceManagementState state, ColorScheme cs) {
    if (state.isLoading && state.allContent.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),);
    }

    if (state.error != null && state.allContent.isEmpty) {
      return Center(
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: Spacings.lg),
              Text(
                state.error!,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.lg),
              FilledButton.tonal(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ─── Search & Filters ───────────────────────────────────────────
        Padding(
          padding: Spacings.paddingScreen,
          child: Column(
            children: [
              AdminSearchBar(
                controller: _searchController,
                hint: 'Search by title, author...',
                onChanged: (_) => _loadData(),
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Text(
                    'Status:',
                    style: AppTypography.wMedium.copyWith(fontSize: 13),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: FilterChipGroup<MarketplaceStatus>(
                      items: MarketplaceStatus.values,
                      selected: _statusFilter,
                      onSelected: (status) {
                        setState(() => _statusFilter = status);
                        _loadData();
                      },
                      labelBuilder: (status) => status.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Row(
                children: [
                  Text(
                    'Type:',
                    style: AppTypography.wMedium.copyWith(fontSize: 13),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: FilterChipGroup<MarketplaceContentType>(
                      items: MarketplaceContentType.values,
                      selected: _contentTypeFilter,
                      onSelected: (type) {
                        setState(() => _contentTypeFilter = type);
                        _loadData();
                      },
                      labelBuilder: (type) => type.label,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─── Data Table ─────────────────────────────────────────────────
        Expanded(
          child: state.allContent.isEmpty
              ? const AdminEmptyState(
                  message: 'No content matches your filters.',
                  icon: Icons.inventory_2_outlined,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        cs.surfaceContainerLow,
                      ),
                      headingTextStyle: AppTypography.wSemiBold.copyWith(
                        fontSize: 12,
                        color: cs.onSurface,
                      ),
                      dataTextStyle: AppTypography.wRegular.copyWith(
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                      columnSpacing: Spacings.lg,
                      horizontalMargin: Spacings.lg,
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Author')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Downloads')),
                        DataColumn(label: Text('Rating')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Reviewed By')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: state.allContent.map((content) {
                        return DataRow(
                          cells: [
                            // Title
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  content.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.wMedium.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            // Author
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(
                                  content.authorId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Type
                            DataCell(
                              StatusBadge(
                                label: content.contentType.label,
                                color: _contentTypeColor(content.contentType),
                              ),
                            ),
                            // Status
                            DataCell(
                              StatusBadge(
                                label: content.status.label,
                                color: _statusColor(content.status),
                              ),
                            ),
                            // Downloads
                            DataCell(Text('${content.downloadCount}')),
                            // Rating
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.warning),
                                const SizedBox(width: Spacings.xs),
                                Text(
                                  _formatRating(content.ratingAverage),
                                  style: AppTypography.wMedium.copyWith(fontSize: 12),
                                ),
                                Text(
                                  ' (${content.ratingCount})',
                                  style: AppTypography.wRegular.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),),
                            // Price
                            DataCell(Text(_formatPrice(content.price))),
                            // Reviewed By
                            DataCell(Text(
                              content.reviewedBy ?? '—',
                              style: AppTypography.wRegular.copyWith(
                                fontSize: 12,
                                color: content.reviewedBy != null
                                    ? cs.onSurface
                                    : cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),),
                            // Created
                            DataCell(Text(_formatDate(content.createdAt))),
                            // Actions
                            DataCell(_buildActionButtons(content, cs)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(MarketplaceContent content, ColorScheme cs) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Actions',
      onSelected: (action) => _handleAction(action, content),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'view', child: Text('View Details')),
        if (content.status == MarketplaceStatus.pendingReview)
          const PopupMenuItem(value: 'approve', child: Text('Approve')),
        if (content.status == MarketplaceStatus.pendingReview)
          const PopupMenuItem(value: 'reject', child: Text('Reject')),
        if (content.status == MarketplaceStatus.approved)
          const PopupMenuItem(value: 'feature', child: Text('Feature')),
        if (!content.isFlagged)
          const PopupMenuItem(value: 'flag', child: Text('Flag')),
        const PopupMenuItem(value: 'remove', child: Text('Remove')),
      ],
    );
  }

  void _handleAction(String action, MarketplaceContent content) {
    switch (action) {
      case 'view':
        _showContentDetailDialog(content);
      case 'approve':
        _approveContent(content.id);
      case 'reject':
        _showRejectDialog(content);
      case 'feature':
        _featureContent(content.id);
      case 'flag':
        _showFlagDialog(content);
      case 'remove':
        _showRemoveConfirmDialog(content);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  void _approveContent(String contentId) {
    ref.read(marketplaceManagementProvider.notifier).approveContent(contentId);
  }

  void _featureContent(String contentId) {
    ref.read(marketplaceManagementProvider.notifier).featureContent(contentId);
  }

  void _showRejectDialog(MarketplaceContent content) {
    _rejectReasonController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Content'),
        shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting: "${content.title}"',
                style: AppTypography.wMedium.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.lg),
              TextField(
                controller: _rejectReasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Provide a clear reason for the content author...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_rejectReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for rejection'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              ref
                  .read(marketplaceManagementProvider.notifier)
                  .rejectContent(
                      content.id, _rejectReasonController.text.trim(),);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(MarketplaceContent content) {
    _flagReasonController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flag_outlined, color: Colors.orange, size: Spacings.lgIcon),
            SizedBox(width: Spacings.sm),
            Text('Flag Content'),
          ],
        ),
        shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Flagging: "${content.title}"',
                style: AppTypography.wMedium.copyWith(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.lg),
              TextField(
                controller: _flagReasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason for flagging *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Describe the issue with this content...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_flagReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for flagging'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              // In production, would call a flag content use case
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Content flagged (mock)'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmDialog(MarketplaceContent content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline,
                color: AppColors.error, size: Spacings.lgIcon,),
            SizedBox(width: Spacings.sm),
            Text('Remove Content'),
          ],
        ),
        shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: Text(
          'Are you sure you want to permanently remove "${content.title}"? '
          'This action cannot be undone.',
          style: AppTypography.wRegular.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // In production, would call a remove content use case
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Content removed (mock)'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showContentDetailDialog(MarketplaceContent content) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(content.title),
        shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status & Type badges
              Wrap(
                spacing: Spacings.sm,
                runSpacing: Spacings.sm,
                children: [
                  StatusBadge(
                    label: content.status.label,
                    color: _statusColor(content.status),
                  ),
                  StatusBadge(
                    label: content.contentType.label,
                    color: _contentTypeColor(content.contentType),
                  ),
                  StatusBadge(
                    label: _formatPrice(content.price),
                    color: content.isFree ? AppColors.success : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: Spacings.lg),

              // Details grid
              _buildDetailRow('Author', content.authorId, cs),
              if (content.subject != null)
                _buildDetailRow('Subject', content.subject!, cs),
              if (content.classLevel != null)
                _buildDetailRow('Class Level', content.classLevel!, cs),
              if (content.curriculum != null)
                _buildDetailRow('Curriculum', content.curriculum!, cs),
              _buildDetailRow('Downloads', '${content.downloadCount}', cs),
              _buildDetailRow(
                  'Rating', '${_formatRating(content.ratingAverage)} (${content.ratingCount} reviews)', cs,),
              if (content.reviewedBy != null)
                _buildDetailRow('Reviewed By', content.reviewedBy!, cs),
              if (content.reviewedAt != null)
                _buildDetailRow('Reviewed At', _formatDate(content.reviewedAt!), cs),
              _buildDetailRow('Created', _formatDate(content.createdAt), cs),

              const SizedBox(height: Spacings.lg),

              // Description
              Text(
                'Description',
                style: AppTypography.wSemiBold.copyWith(fontSize: 13),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                content.description,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),

              // Tags
              if (content.tags != null && content.tags!.isNotEmpty) ...[
                const SizedBox(height: Spacings.md),
                Text(
                  'Tags',
                  style: AppTypography.wSemiBold.copyWith(fontSize: 13),
                ),
                const SizedBox(height: Spacings.xs),
                Wrap(
                  spacing: Spacings.xs,
                  runSpacing: Spacings.xs,
                  children: content.tags!
                      .map((tag) => Chip(
                            label: Text(tag,
                                style: AppTypography.wRegular.copyWith(fontSize: 11),),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),)
                      .toList(),
                ),
              ],

              // Flag info
              if (content.isFlagged) ...[
                const SizedBox(height: Spacings.md),
                Container(
                  padding: Spacings.paddingAllMd,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: Spacings.borderRadiusSm,
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: Spacings.mdIcon, color: Colors.orange),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Flagged Content',
                              style: AppTypography.wSemiBold.copyWith(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            if (content.flagReason != null)
                              Text(
                                content.flagReason!,
                                style: AppTypography.wRegular.copyWith(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.wRegular.copyWith(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.wMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
