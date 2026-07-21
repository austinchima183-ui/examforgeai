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
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/rubric_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// RUBRIC LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all rubrics with search, filter chips, and CRUD actions.
class RubricListPage extends ConsumerStatefulWidget {
  const RubricListPage({super.key});

  @override
  ConsumerState<RubricListPage> createState() => _RubricListPageState();
}

class _RubricListPageState extends ConsumerState<RubricListPage> {
  final _searchCtrl = TextEditingController();
  _RubricFilter _activeFilter = _RubricFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rubricProvider.notifier).loadRubrics();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(rubricProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(rubricProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(rubricProvider.notifier).clearError();
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

  List<RubricEntity> _applyLocalFilters(List<RubricEntity> rubrics) {
    var filtered = rubrics;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.title.toLowerCase().contains(query) ||
              (r.description?.toLowerCase().contains(query) ?? false) ||
              (r.topic?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Filter chips
    switch (_activeFilter) {
      case _RubricFilter.all:
        break;
      case _RubricFilter.myRubrics:
        // In a real app this would filter by current user's ID
        break;
      case _RubricFilter.templates:
        filtered = filtered.where((r) => r.isTemplate).toList();
        break;
      case _RubricFilter.published:
        filtered = filtered.where((r) => r.isPublished).toList();
        break;
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    await ref.read(rubricProvider.notifier).loadRubrics();
    _listenForMessages();
  }

  void _handleDelete(String rubricId) {
    ref.read(rubricProvider.notifier).deleteRubric(rubricId);
    _listenForMessages();
  }

  void _handleDuplicate(RubricEntity rubric) {
    _showSnackBar('Rubric duplicated', isError: false);
  }

  void _handleExport(RubricEntity rubric) {
    _showSnackBar('Exporting rubric...', isError: false);
  }

  void _navigateToGenerator() {
    context.push('/workspace/rubrics/generator');
  }

  void _navigateToDetail(String rubricId) {
    ref.read(rubricProvider.notifier).setCurrentRubric(
          ref.read(rubricProvider).rubrics.firstWhere((r) => r.id == rubricId),
        );
    context.push('/workspace/rubrics/generator');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rubricProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Rubrics',
        actions: [
          AppIconButton(
            icon: Icons.search_rounded,
            onPressed: () => _showSearchBar(),
            tooltip: 'Search Rubrics',
            variant: AppIconButtonVariant.standard,
          ),
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _navigateToGenerator,
            tooltip: 'New Rubric',
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.rubrics.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Rubric',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(RubricState state) {
    final filteredRubrics = _applyLocalFilters(state.rubrics);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(
            child: _buildResultsCount(filteredRubrics.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Rubric list
          if (filteredRubrics.isEmpty)
            const SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildRubricCard(filteredRubrics[index]),
                  ),
                  childCount: filteredRubrics.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search rubrics...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          contentPadding: Spacings.paddingInput,
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  void _showSearchBar() {
    // Focus the search field
    setState(() {});
  }

  // ─── Filter Chips ────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: _RubricFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _activeFilter = filter),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Results Count ───────────────────────────────────────────────────

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Text(
        '$count rubric${count != 1 ? 's' : ''}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Rubric Card ─────────────────────────────────────────────────────

  Widget _buildRubricCard(RubricEntity rubric) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () => _navigateToDetail(rubric.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + badges
          Row(
            children: [
              Expanded(
                child: Text(
                  rubric.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (rubric.isPublished)
                _buildBadge(
                  icon: Icons.public_rounded,
                  label: 'Published',
                  color: cs.primary,
                  isDark: isDark,
                ),
              if (rubric.isAiGenerated && !rubric.isPublished)
                _buildBadge(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  color: cs.tertiary,
                  isDark: isDark,
                  bgColor: cs.tertiaryContainer,
                ),
              if (rubric.isTemplate)
                _buildBadge(
                  icon: Icons.content_copy_rounded,
                  label: 'Template',
                  color: cs.secondary,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Description
          if (rubric.description != null) ...[
            Text(
              rubric.description!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.sm),
          ],

          // Badges row
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.xs,
            children: [
              _buildChip(
                icon: Icons.star_outline_rounded,
                label: '${rubric.totalPoints.toInt()} pts',
                color: cs.primary,
                isDark: isDark,
              ),
              _buildChip(
                icon: Icons.checklist_rounded,
                label: '${rubric.criteria.length} criteria',
                color: cs.tertiary,
                isDark: isDark,
              ),
              if (rubric.subjectId != null)
                _buildChip(
                  icon: Icons.book_outlined,
                  label: rubric.subjectId!,
                  color: cs.secondary,
                  isDark: isDark,
                ),
              if (rubric.classId != null)
                _buildChip(
                  icon: Icons.school_outlined,
                  label: rubric.classId!,
                  color: cs.primary,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Created date
          Text(
            'Created ${_formatDate(rubric.createdAt)}',
            style: context.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: Spacings.md),

          // Action buttons
          Row(
            children: [
              AppButton(
                label: 'Edit',
                onPressed: () => _navigateToDetail(rubric.id),
                variant: AppButtonVariant.text,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(rubric),
                variant: AppButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Duplicate',
                onPressed: () => _handleDuplicate(rubric),
                variant: AppButtonVariant.text,
                icon: Icons.content_copy_outlined,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              AppButton(
                label: 'Export',
                onPressed: () => _handleExport(rubric),
                variant: AppButtonVariant.tonal,
                icon: Icons.file_download_outlined,
                size: AppButtonSize.small,
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
    required bool isDark,
    Color? bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: Spacings.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(isDark ? 0.20 : 0.10),
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
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
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
        color: color.withOpacity(isDark ? 0.20 : 0.10),
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
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: Spacings.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLoadingShimmer.box(width: 200, height: 16),
                  const Spacer(),
                  const AppLoadingShimmer.box(width: 60, height: 20),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              const AppLoadingShimmer.box(width: 150, height: 14),
              const SizedBox(height: Spacings.sm),
              Row(
                children: const [
                  AppLoadingShimmer.box(width: 80, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 60, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 70, height: 22),
                ],
              ),
              const SizedBox(height: Spacings.md),
              const AppLoadingShimmer.box(width: 120, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.grid_on_outlined,
      title: 'No Rubrics Yet',
      subtitle:
          'Create your first rubric with AI assistance or start from scratch.',
      actionLabel: 'Create Rubric',
      onAction: _navigateToGenerator,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(rubricProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────

  void _confirmDelete(RubricEntity rubric) {
    final cs = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rubric'),
        content: Text(
          'Are you sure you want to delete "${rubric.title}"? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(rubric.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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

/// Filter options for the rubric list.
enum _RubricFilter {
  all('All'),
  myRubrics('My Rubrics'),
  templates('Templates'),
  published('Published');

  const _RubricFilter(this.label);
  final String label;
}
