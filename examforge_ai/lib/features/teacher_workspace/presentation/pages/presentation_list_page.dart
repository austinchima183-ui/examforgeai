import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/presentation_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all presentations with search, filter by type, and
/// responsive grid layout.
class PresentationListPage extends ConsumerStatefulWidget {
  const PresentationListPage({super.key});

  @override
  ConsumerState<PresentationListPage> createState() =>
      _PresentationListPageState();
}

class _PresentationListPageState extends ConsumerState<PresentationListPage> {
  final _searchCtrl = TextEditingController();
  PresentationType? _filterType;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presentationProvider.notifier).loadPresentations();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(presentationProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(presentationProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(presentationProvider.notifier).clearError();
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

  List<PresentationEntity> _applyLocalFilters(
      List<PresentationEntity> presentations) {
    var filtered = presentations;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(query) ||
              (p.topic?.toLowerCase().contains(query) ?? false) ||
              p.presentationType.label.toLowerCase().contains(query))
          .toList();
    }

    // Type filter
    if (_filterType != null) {
      filtered =
          filtered.where((p) => p.presentationType == _filterType).toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    await ref.read(presentationProvider.notifier).loadPresentations();
    _listenForMessages();
  }

  void _handleDelete(String presentationId) {
    ref.read(presentationProvider.notifier).deletePresentation(presentationId);
    _listenForMessages();
  }

  void _handleToggleFavorite(String presentationId) {
    ref.read(presentationProvider.notifier).toggleFavorite(presentationId);
    _listenForMessages();
  }

  void _handleExport(String presentationId, String format) {
    ref
        .read(presentationProvider.notifier)
        .exportPresentation(presentationId: presentationId, format: format);
    _listenForMessages();
  }

  void _navigateToGenerator() {
    context.push('/workspace/presentations/generator');
  }

  void _navigateToDetail(String presentationId) {
    context.push('/workspace/presentations/detail/$presentationId');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presentationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Presentations',
        isSearchMode: _isSearching,
        searchHint: 'Search presentations...',
        searchController: _searchCtrl,
        onSearchToggle: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) _searchCtrl.clear();
        }),
        onSearchChanged: (query) => setState(() {}),
        actions: [
          if (!_isSearching)
            AppIconButton(
              icon: Icons.search_rounded,
              onPressed: () => setState(() => _isSearching = true),
              tooltip: 'Search',
              variant: AppIconButtonVariant.standard,
            ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.presentations.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Presentation',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(PresentationState state) {
    final filteredPresentations = _applyLocalFilters(state.presentations);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Text(
                '${filteredPresentations.length} presentation${filteredPresentations.length != 1 ? 's' : ''}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Grid or empty state
          if (filteredPresentations.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            _buildPresentationGrid(filteredPresentations),
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
          _buildFilterChip(label: 'All', isSelected: _filterType == null, onTap: () => setState(() => _filterType = null)),
          const SizedBox(width: Spacings.sm),
          ...PresentationType.values.map((type) => Padding(
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
        fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
      ),
    );
  }

  // ─── Presentation Grid ──────────────────────────────────────────────

  Widget _buildPresentationGrid(List<PresentationEntity> presentations) {
    final crossAxisCount = context.isDesktop
        ? 4
        : context.isTablet
            ? 3
            : 2;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Spacings.md,
          mainAxisSpacing: Spacings.md,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, index) => _buildPresentationCard(presentations[index]),
          childCount: presentations.length,
        ),
      ),
    );
  }

  Widget _buildPresentationCard(PresentationEntity presentation) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () => _navigateToDetail(presentation.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type icon + AI badge + favorite
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  _presentationTypeIcon(presentation.presentationType),
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
              ),
              const Spacer(),
              if (presentation.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 10, color: cs.onTertiaryContainer),
                      const SizedBox(width: 2),
                      Text(
                        'AI',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: Spacings.xs),
              GestureDetector(
                onTap: () => _handleToggleFavorite(presentation.id),
                child: Icon(
                  presentation.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: Spacings.mdIcon,
                  color: presentation.isFavorite ? cs.error : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Title
          Text(
            presentation.title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.xs),

          // Topic
          if (presentation.topic != null)
            Text(
              presentation.topic!,
              style: context.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: Spacings.sm),

          // Slide count + type badge
          Row(
            children: [
              Icon(Icons.view_carousel_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${presentation.totalSlides} slides',
                style: context.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  presentation.presentationType.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Subject and class badges
          Wrap(
            spacing: Spacings.xs,
            runSpacing: Spacings.xs,
            children: [
              if (presentation.topic != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    presentation.topic!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const Spacer(),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (format) =>
                    _handleExport(presentation.id, format),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                  const PopupMenuItem(value: 'PPTX', child: Text('Export PPTX')),
                  const PopupMenuItem(value: 'HTML', child: Text('Export HTML')),
                ],
                child: Icon(Icons.file_download_outlined, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: Spacings.xs),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: Spacings.mdIcon, color: cs.error),
                onPressed: () async {
                  final confirmed = await AppDialog.showConfirm(
                    context: context,
                    title: 'Delete Presentation',
                    message: 'Are you sure you want to delete "${presentation.title}"? This action cannot be undone.',
                    confirmText: 'Delete',
                    isDestructive: true,
                  );
                  if (confirmed == true) _handleDelete(presentation.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Loading / Error / Empty ─────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    final crossAxisCount = context.isDesktop
        ? 4
        : context.isTablet
            ? 3
            : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppLoadingShimmer.box(width: 40, height: 40),
                const Spacer(),
                AppLoadingShimmer.box(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: Spacings.md),
            AppLoadingShimmer.box(width: 180, height: 16),
            const SizedBox(height: Spacings.sm),
            AppLoadingShimmer.box(width: 120, height: 14),
            const SizedBox(height: Spacings.md),
            AppLoadingShimmer.box(width: 80, height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return AppErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Something Went Wrong',
      message: ref.read(presentationProvider).error ?? 'Failed to load presentations',
      onRetry: _handleRefresh,
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.slideshow_outlined,
      title: _filterType != null || _searchCtrl.text.isNotEmpty
          ? 'No Matching Presentations'
          : 'No Presentations Yet',
      subtitle: _filterType != null || _searchCtrl.text.isNotEmpty
          ? 'Try adjusting your search or filters'
          : 'Create your first AI-powered presentation',
      actionLabel: 'Create Presentation',
      onAction: _navigateToGenerator,
    );
  }

  IconData _presentationTypeIcon(PresentationType type) {
    switch (type) {
      case PresentationType.powerpoint:
        return Icons.slideshow_rounded;
      case PresentationType.teachingSlides:
        return Icons.school_rounded;
      case PresentationType.infographic:
        return Icons.dashboard_rounded;
      case PresentationType.diagram:
        return Icons.account_tree_rounded;
      case PresentationType.flowchart:
        return Icons.alt_route_rounded;
      case PresentationType.mindMap:
        return Icons.hub_rounded;
      case PresentationType.summarySheet:
        return Icons.summarize_rounded;
    }
  }
}
