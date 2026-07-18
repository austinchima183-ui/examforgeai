import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/communication_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all communications with tabs (All, Drafts, Sent, Templates),
/// filter chips by type, and list of communication cards.
class CommunicationListPage extends ConsumerStatefulWidget {
  const CommunicationListPage({super.key});

  @override
  ConsumerState<CommunicationListPage> createState() =>
      _CommunicationListPageState();
}

class _CommunicationListPageState
    extends ConsumerState<CommunicationListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CommunicationType? _filterType;

  static const _tabs = [
    Tab(text: 'All'),
    Tab(text: 'Drafts'),
    Tab(text: 'Sent'),
    Tab(text: 'Templates'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communicationProvider.notifier).loadCommunications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(communicationProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(communicationProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(communicationProvider.notifier).clearError();
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

  List<CommunicationEntity> _applyFilters(
      List<CommunicationEntity> communications) {
    var filtered = communications;

    // Tab filter
    final tabIndex = _tabController.index;
    switch (tabIndex) {
      case 1: // Drafts
        filtered = filtered.where((c) => c.isDraft).toList();
        break;
      case 2: // Sent
        filtered = filtered.where((c) => c.isSent).toList();
        break;
      case 3: // Templates
        filtered = filtered.where((c) => c.isTemplate).toList();
        break;
    }

    // Type filter
    if (_filterType != null) {
      filtered = filtered
          .where((c) => c.communicationType == _filterType)
          .toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    await ref.read(communicationProvider.notifier).loadCommunications();
    _listenForMessages();
  }

  void _handleDelete(String communicationId) {
    ref.read(communicationProvider.notifier).deleteCommunication(communicationId);
    _listenForMessages();
  }

  void _handleCopyContent(CommunicationEntity communication) {
    // Navigate to generator with pre-filled content
    context.push('/workspace/communications/generator');
  }

  void _navigateToGenerator() {
    context.push('/workspace/communications/generator');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communicationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Communications',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: context.textTheme.labelLarge?.copyWith(
            fontWeight: AppTypography.wMedium,
          ),
        ),
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.communications.isEmpty
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(
                    _tabs.length,
                    (_) => _buildTabContent(state),
                  ),
                ),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Communication',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Tab Content ─────────────────────────────────────────────────────

  Widget _buildTabContent(CommunicationState state) {
    final filteredCommunications = _applyFilters(state.communications);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Filter chips by communication type
          SliverToBoxAdapter(child: _buildFilterChips()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Text(
                '${filteredCommunications.length} communication${filteredCommunications.length != 1 ? 's' : ''}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // List or empty state
          if (filteredCommunications.isEmpty)
            SliverFillRemaining(child: _buildEmptyStateForTab())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildCommunicationCard(filteredCommunications[index]),
                  ),
                  childCount: filteredCommunications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: [
          _buildFilterChip(
            label: 'All Types',
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          const SizedBox(width: Spacings.sm),
          ...CommunicationType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: Spacings.sm),
                child: _buildFilterChip(
                  label: type.label,
                  isSelected: _filterType == type,
                  onTap: () => setState(() => _filterType = type),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: cs.primaryContainer,
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        fontWeight:
            isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
      ),
    );
  }

  // ─── Communication Card ──────────────────────────────────────────────

  Widget _buildCommunicationCard(CommunicationEntity communication) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () {
        // Navigate to detail or generator for editing
        context.push('/workspace/communications/generator');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type icon + title + status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  _communicationTypeIcon(communication.communicationType),
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      communication.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: communication.isDraft
                      ? cs.tertiaryContainer
                      : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  communication.isDraft ? 'Draft' : 'Sent',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: communication.isDraft
                        ? cs.onTertiaryContainer
                        : cs.onPrimaryContainer,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Content preview (2 lines max)
          Text(
            communication.content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.md),

          // Badges row: tone + recipient type
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              _buildBadge(
                icon: Icons.record_voice_over_outlined,
                label: communication.tone.label,
                color: cs.secondary,
              ),
              _buildBadge(
                icon: Icons.group_outlined,
                label: communication.recipientType,
                color: cs.tertiary,
              ),
              if (communication.isAiGenerated)
                _buildBadge(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  color: cs.primary,
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Bottom row: date + actions
          Row(
            children: [
              Text(
                _formatDate(communication.createdAt),
                style: context.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Edit (if draft)
              if (communication.isDraft)
                AppIconButton(
                  icon: Icons.edit_outlined,
                  onPressed: _navigateToGenerator,
                  tooltip: 'Edit',
                  variant: AppIconButtonVariant.standard,
                  size: AppButtonSize.small,
                ),
              // Copy
              AppIconButton(
                icon: Icons.copy_rounded,
                onPressed: () => _handleCopyContent(communication),
                tooltip: 'Copy',
                variant: AppIconButtonVariant.standard,
                size: AppButtonSize.small,
              ),
              // Delete
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                onPressed: () async {
                  final confirmed = await AppDialog.showConfirm(
                    context: context,
                    title: 'Delete Communication',
                    message:
                        'Are you sure you want to delete "${communication.title}"? This action cannot be undone.',
                    confirmText: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed == true) _handleDelete(communication.id);
                },
                tooltip: 'Delete',
                variant: AppIconButtonVariant.standard,
                size: AppButtonSize.small,
                color: cs.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading / Error / Empty ─────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: 5,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppLoadingShimmer.box(width: 40, height: 40),
                  const SizedBox(width: Spacings.md),
                  Expanded(child: AppLoadingShimmer.box(width: double.infinity, height: 16)),
                ],
              ),
              const SizedBox(height: Spacings.md),
              AppLoadingShimmer.box(width: double.infinity, height: 14),
              const SizedBox(height: Spacings.sm),
              AppLoadingShimmer.box(width: 200, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AppErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Something Went Wrong',
      message: ref.read(communicationProvider).error ??
          'Failed to load communications',
      onRetry: _handleRefresh,
    );
  }

  Widget _buildEmptyStateForTab() {
    final tabIndex = _tabController.index;
    String title;
    String subtitle;
    IconData icon;

    switch (tabIndex) {
      case 1: // Drafts
        icon = Icons.drafts_outlined;
        title = 'No Drafts';
        subtitle = 'Saved communications will appear here as drafts';
        break;
      case 2: // Sent
        icon = Icons.send_outlined;
        title = 'No Sent Communications';
        subtitle = 'Sent communications will appear here';
        break;
      case 3: // Templates
        icon = Icons.description_outlined;
        title = 'No Templates';
        subtitle = 'Save a communication as a template for reuse';
        break;
      default: // All
        icon = Icons.mail_outlined;
        title = _filterType != null
            ? 'No Matching Communications'
            : 'No Communications Yet';
        subtitle = _filterType != null
            ? 'Try adjusting your filters'
            : 'Create your first AI-powered communication';
    }

    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: 'Create Communication',
      onAction: _navigateToGenerator,
    );
  }

  // ─── Utilities ───────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _communicationTypeIcon(CommunicationType type) {
    switch (type) {
      case CommunicationType.parentLetter:
        return Icons.mail_rounded;
      case CommunicationType.studentFeedback:
        return Icons.feedback_rounded;
      case CommunicationType.email:
        return Icons.email_rounded;
      case CommunicationType.sms:
        return Icons.sms_rounded;
      case CommunicationType.announcement:
        return Icons.campaign_rounded;
      case CommunicationType.meetingInvitation:
        return Icons.event_rounded;
      case CommunicationType.permissionLetter:
        return Icons.description_rounded;
      case CommunicationType.certificate:
        return Icons.workspace_premium_rounded;
    }
  }
}
