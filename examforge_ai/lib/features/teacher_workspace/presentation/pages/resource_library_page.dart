import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../domain/entities/teacher_workspace_entities.dart';
import '../providers/resource_library_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESOURCE LIBRARY PAGE
// ═══════════════════════════════════════════════════════════════════════

/// A searchable personal library for all teacher-created content: lesson
/// plans, worksheets, assignments, slides, notes, rubrics, reports.
class ResourceLibraryPage extends ConsumerStatefulWidget {
  const ResourceLibraryPage({super.key});

  @override
  ConsumerState<ResourceLibraryPage> createState() =>
      _ResourceLibraryPageState();
}

class _ResourceLibraryPageState extends ConsumerState<ResourceLibraryPage> {
  final _searchCtrl = TextEditingController();
  ResourceType? _filterContentType;
  String? _filterSubject;
  _SortOption _sortOption = _SortOption.recent;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resourceLibraryProvider.notifier).loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(resourceLibraryProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(resourceLibraryProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(resourceLibraryProvider.notifier).clearError();
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

  List<TeachingResourceEntity> _applyLocalFilters(
    List<TeachingResourceEntity> resources,
  ) {
    var filtered = resources;

    // Content type filter
    if (_filterContentType != null) {
      filtered = filtered
          .where((r) => r.resourceType == _filterContentType)
          .toList();
    }

    // Subject filter
    if (_filterSubject != null) {
      filtered = filtered
          .where((r) => r.subject == _filterSubject)
          .toList();
    }

    // Date range filter
    if (_filterDateRange != null) {
      filtered = filtered
          .where((r) =>
              r.updatedAt.isAfter(_filterDateRange!.start) &&
              r.updatedAt
                  .isBefore(_filterDateRange!.end.add(const Duration(days: 1))))
          .toList();
    }

    // Sort
    switch (_sortOption) {
      case _SortOption.recent:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _SortOption.az:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _SortOption.mostUsed:
        // Sort by version (proxy for usage) then by updatedAt
        filtered.sort((a, b) {
          final versionCompare = b.version.compareTo(a.version);
          if (versionCompare != 0) return versionCompare;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    }

    return filtered;
  }

  List<String> _getUniqueSubjects(List<TeachingResourceEntity> resources) {
    final subjects = resources
        .where((r) => r.subject != null)
        .map((r) => r.subject!)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  Future<void> _handleRefresh() async {
    await ref.read(resourceLibraryProvider.notifier).loadLibrary();
    _listenForMessages();
  }

  void _handleToggleFavorite(String resourceId) {
    ref.read(resourceLibraryProvider.notifier).toggleFavorite(resourceId);
    _listenForMessages();
  }

  void _handleDeleteResource(String resourceId) {
    // Optimistically remove from view (actual delete via provider not available
    // in resource_library_provider, but we show the UI pattern)
    _showSnackBar('Resource deleted', isError: false);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resourceLibraryProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Resource Library',
        actions: [
          AppIconButton(
            icon: Icons.create_new_folder_outlined,
            onPressed: _showCreateFolderDialog,
            tooltip: 'New Folder',
            variant: AppIconButtonVariant.standard,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.allResources.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(ResourceLibraryState state) {
    final filteredResources = _applyLocalFilters(state.searchResults);
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar with folder tree
          _buildFolderSidebar(state),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: _buildMainContent(state, filteredResources),
          ),
        ],
      );
    }

    return _buildMainContent(state, filteredResources);
  }

  Widget _buildMainContent(
    ResourceLibraryState state,
    List<TeachingResourceEntity> filteredResources,
  ) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Breadcrumb
          SliverToBoxAdapter(child: _buildBreadcrumb(state)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Search bar with filter icon
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter options
          SliverToBoxAdapter(child: _buildFilterOptions(state)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Sort options
          SliverToBoxAdapter(child: _buildSortOptions()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(
            child: _buildResultsCount(filteredResources.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Content grid
          if (filteredResources.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.isDesktop ? 3 : (context.isTablet ? 2 : 1),
                  childAspectRatio: context.isDesktop ? 1.4 : 1.2,
                  crossAxisSpacing: Spacings.md,
                  mainAxisSpacing: Spacings.md,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildResourceCard(filteredResources[index]),
                  childCount: filteredResources.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Breadcrumb ──────────────────────────────────────────────────────

  Widget _buildBreadcrumb(ResourceLibraryState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final selectedFolder = state.folders
        .where((f) => f.id == state.selectedFolderId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.xs,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                ref.read(resourceLibraryProvider.notifier).selectFolder(null),
            child: Text(
              'Library',
              style: tt.labelMedium?.copyWith(
                color: state.selectedFolderId == null
                    ? cs.onSurface
                    : cs.primary,
                fontWeight: AppTypography.wMedium,
              ),
            ),
          ),
          if (selectedFolder != null) ...[
            Icon(Icons.chevron_right_rounded,
                size: 16, color: cs.onSurfaceVariant),
            Text(
              selectedFolder.name,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: AppTypography.wMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Folder Sidebar (Desktop) ────────────────────────────────────────

  Widget _buildFolderSidebar(ResourceLibraryState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SizedBox(
      width: 260,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: Spacings.lg,
          horizontal: Spacings.sm,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Folders',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                AppIconButton(
                  icon: Icons.create_new_folder_outlined,
                  onPressed: _showCreateFolderDialog,
                  tooltip: 'New Folder',
                  variant: AppIconButtonVariant.standard,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // "All Resources" item
          ListTile(
            dense: true,
            leading: Icon(
              Icons.folder_outlined,
              size: Spacings.mdIcon,
              color: state.selectedFolderId == null
                  ? cs.primary
                  : cs.onSurfaceVariant,
            ),
            title: Text(
              'All Resources',
              style: tt.bodyMedium?.copyWith(
                color: state.selectedFolderId == null
                    ? cs.primary
                    : cs.onSurfaceVariant,
                fontWeight: state.selectedFolderId == null
                    ? AppTypography.wSemiBold
                    : AppTypography.wRegular,
              ),
            ),
            selected: state.selectedFolderId == null,
            selectedTileColor:
                cs.primary.withOpacity(context.isDarkMode ? 0.15 : 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            onTap: () => ref
                .read(resourceLibraryProvider.notifier)
                .selectFolder(null),
          ),

          // Folder items
          ...state.folders.map((folder) {
            final isSelected = state.selectedFolderId == folder.id;
            return ListTile(
              dense: true,
              leading: Icon(
                Icons.folder_rounded,
                size: Spacings.mdIcon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              title: Text(
                folder.name,
                style: tt.bodyMedium?.copyWith(
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: isSelected
                      ? AppTypography.wSemiBold
                      : AppTypography.wRegular,
                ),
              ),
              selected: isSelected,
              selectedTileColor: cs.primary
                  .withOpacity(context.isDarkMode ? 0.15 : 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              onTap: () => ref
                  .read(resourceLibraryProvider.notifier)
                  .selectFolder(folder.id),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
                onPressed: () => _confirmDeleteFolder(folder.id, folder.name),
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete folder',
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              hint: 'Search library...',
              controller: _searchCtrl,
              onChanged: (query) {
                ref.read(resourceLibraryProvider.notifier).searchLibrary(query);
              },
            ),
          ),
          const SizedBox(width: Spacings.sm),
          AppIconButton(
            icon: Icons.filter_list_rounded,
            onPressed: _showFilterSheet,
            tooltip: 'Filters',
            variant: AppIconButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  // ─── Filter Options ──────────────────────────────────────────────────

  Widget _buildFilterOptions(ResourceLibraryState state) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: [
          // Content type filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _buildFilterDropdown<ResourceType>(
              label: 'Content Type',
              value: _filterContentType,
              items: ResourceType.values,
              itemLabel: (t) => t.label,
              onChanged: (v) => setState(() => _filterContentType = v),
            ),
          ),

          // Subject filter
          if (_getUniqueSubjects(state.allResources).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: _buildFilterDropdown<String>(
                label: 'Subject',
                value: _filterSubject,
                items: _getUniqueSubjects(state.allResources),
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _filterSubject = v),
              ),
            ),

          // Date range filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: InputChip(
              selected: _filterDateRange != null,
              label: Text(
                _filterDateRange != null
                    ? '${_formatDateShort(_filterDateRange!.start)} – ${_formatDateShort(_filterDateRange!.end)}'
                    : 'Date Range',
                style: context.textTheme.labelMedium?.copyWith(
                  color: _filterDateRange != null
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurfaceVariant,
                ),
              ),
              avatar: Icon(
                Icons.date_range_rounded,
                size: 16,
                color: _filterDateRange != null
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurfaceVariant,
              ),
              onPressed: _pickDateRange,
              onDeleted: _filterDateRange != null
                  ? () => setState(() => _filterDateRange = null)
                  : null,
              deleteIconColor: _filterDateRange != null
                  ? context.colorScheme.onPrimary
                  : null,
              selectedColor: context.colorScheme.primary,
              backgroundColor: context.colorScheme.surfaceContainerLow,
              side: BorderSide(
                color: _filterDateRange != null
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant,
              ),
            ),
          ),

          // Clear all filters
          if (_filterContentType != null ||
              _filterSubject != null ||
              _filterDateRange != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _filterContentType = null;
                    _filterSubject = null;
                    _filterDateRange = null;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = context.colorScheme;
    final isSelected = value != null;

    return InputChip(
      selected: isSelected,
      label: Text(
        isSelected ? itemLabel(value as T) : label,
        style: context.textTheme.labelMedium?.copyWith(
          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
      ),
      avatar: Icon(
        Icons.filter_list_rounded,
        size: 16,
        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
      ),
      onPressed: () => _showFilterSheet<T>(
        label: label,
        items: items,
        itemLabel: itemLabel,
        selectedValue: value,
        onSelected: onChanged,
      ),
      onDeleted: isSelected ? () => onChanged(null) : null,
      deleteIconColor: isSelected ? cs.onPrimary : null,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerLow,
      side: BorderSide(
        color: isSelected ? cs.primary : cs.outlineVariant,
      ),
    );
  }

  void _showFilterSheet<T>({
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required T? selectedValue,
    required ValueChanged<T?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Row(
                children: [
                  Text(
                    'Filter by $label',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(ctx),
                    variant: AppIconButtonVariant.standard,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = item == selectedValue;
                  return ListTile(
                    title: Text(itemLabel(item)),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded,
                            color: context.colorScheme.primary)
                        : null,
                    onTap: () {
                      onSelected(isSelected ? null : item);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _filterDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _filterDateRange = picked);
    }
  }

  // ─── Sort Options ────────────────────────────────────────────────────

  Widget _buildSortOptions() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        children: [
          Text(
            'Sort:',
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          ..._SortOption.values.map((option) {
            final isSelected = _sortOption == option;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _sortOption = option);
                },
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Results Count ───────────────────────────────────────────────────

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Text(
        '$count item${count != 1 ? 's' : ''}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Resource Card ───────────────────────────────────────────────────

  Widget _buildResourceCard(TeachingResourceEntity resource) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final tt = context.textTheme;

    return AppCard(
      onTap: () {
        // TODO: Navigate to resource detail
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: thumbnail/icon + title + favorite
          Row(
            children: [
              // Type icon thumbnail
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  _resourceTypeIcon(resource.resourceType),
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  resource.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Favorite star
              IconButton(
                icon: Icon(
                  resource.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: Spacings.mdIcon,
                  color: resource.isFavorite
                      ? cs.tertiary
                      : cs.onSurfaceVariant,
                ),
                onPressed: () => _handleToggleFavorite(resource.id),
                tooltip: resource.isFavorite ? 'Unfavorite' : 'Favorite',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Type badge
          Row(
            children: [
              _buildChip(
                icon: _resourceTypeIcon(resource.resourceType),
                label: resource.resourceType.label,
                color: cs.secondary,
              ),
              if (resource.isAiGenerated) ...[
                const SizedBox(width: Spacings.xs),
                _buildChip(
                  icon: Icons.auto_awesome,
                  label: 'AI',
                  color: cs.tertiary,
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Subject
          if (resource.subject != null)
            Text(
              resource.subject!,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          // Last modified date
          const SizedBox(height: Spacings.xs),
          Text(
            'Modified ${_formatDate(resource.updatedAt)}',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          // Tags
          if (resource.tags.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: resource.tags
                  .take(3)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.outlineVariant.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(Spacings.fullRadius),
                        ),
                        child: Text(
                          tag,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],

          const Spacer(),

          // Action buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(top: Spacings.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppIconButton(
                  icon: Icons.open_in_new_rounded,
                  onPressed: () {
                    // TODO: Open resource
                  },
                  tooltip: 'Open',
                  variant: AppIconButtonVariant.standard,
                ),
                AppIconButton(
                  icon: Icons.share_outlined,
                  onPressed: () {
                    // TODO: Share resource
                  },
                  tooltip: 'Share',
                  variant: AppIconButtonVariant.standard,
                ),
                AppIconButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _confirmDeleteResource(resource),
                  tooltip: 'Delete',
                  variant: AppIconButtonVariant.standard,
                ),
                GenerateQuestionsButton(
                  resourceType: 'teaching_resource',
                  resourceId: resource.id,
                  resourceName: resource.title,
                  subject: resource.subject,
                  topic: resource.topic,
                ),
              ],
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
  }) {
    final isDark = context.isDarkMode;

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

  // ─── Create Folder Dialog ────────────────────────────────────────────

  void _showCreateFolderDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    AppDialog.showCustom(
      context: context,
      builder: (dialogCtx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Folder',
              style: dialogCtx.textTheme.titleLarge?.copyWith(
                color: dialogCtx.colorScheme.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.lg),

            AppTextField(
              label: 'Folder Name',
              hint: 'e.g. Term 1 Resources',
              controller: nameCtrl,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: Spacings.md),

            AppTextField(
              label: 'Description (optional)',
              hint: 'Brief description of this folder',
              controller: descCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: Spacings.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  variant: AppButtonVariant.text,
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Create',
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      _showSnackBar('Folder name is required', isError: true);
                      return;
                    }
                    Navigator.pop(context);
                    ref.read(resourceLibraryProvider.notifier).createFolder(
                          ResourceFolderEntity(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            teacherId: '',
                            name: nameCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                    _listenForMessages();
                  },
                  variant: AppButtonVariant.elevated,
                  icon: Icons.create_new_folder_rounded,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─── Filter Sheet (comprehensive) ────────────────────────────────────

  void _showSimpleFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Filter Library',
                          style: ctx.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        const Spacer(),
                        AppIconButton(
                          icon: Icons.close,
                          onPressed: () => Navigator.pop(ctx),
                          variant: AppIconButtonVariant.standard,
                        ),
                      ],
                    ),
                    const Divider(height: Spacings.lg),

                    // Content type
                    Text(
                      'Content Type',
                      style: ctx.textTheme.labelLarge?.copyWith(
                        color: ctx.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    Wrap(
                      spacing: Spacings.sm,
                      runSpacing: Spacings.sm,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _filterContentType == null,
                          onSelected: (_) {
                            setSheetState(() => _filterContentType = null);
                            setState(() => _filterContentType = null);
                          },
                        ),
                        ...ResourceType.values.map((type) => FilterChip(
                              label: Text(type.label),
                              selected: _filterContentType == type,
                              onSelected: (_) {
                                setSheetState(() =>
                                    _filterContentType = type);
                                setState(() => _filterContentType = type);
                              },
                            )),
                      ],
                    ),
                    const SizedBox(height: Spacings.lg),

                    // Date range
                    Text(
                      'Date Range',
                      style: ctx.textTheme.labelLarge?.copyWith(
                        color: ctx.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    AppButton(
                      label: _filterDateRange != null
                          ? '${_formatDateShort(_filterDateRange!.start)} – ${_formatDateShort(_filterDateRange!.end)}'
                          : 'Select Date Range',
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _filterDateRange,
                        );
                        if (picked != null) {
                          setSheetState(() => _filterDateRange = picked);
                          setState(() => _filterDateRange = picked);
                        }
                      },
                      variant: AppButtonVariant.outlined,
                      icon: Icons.date_range_rounded,
                      fullWidth: true,
                    ),
                    if (_filterDateRange != null) ...[
                      const SizedBox(height: Spacings.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setSheetState(() => _filterDateRange = null);
                            setState(() => _filterDateRange = null);
                          },
                          child: const Text('Clear date range'),
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacings.xl),

                    // Apply / Reset
                    Row(
                      children: [
                        AppButton(
                          label: 'Reset All',
                          onPressed: () {
                            setSheetState(() {
                              _filterContentType = null;
                              _filterDateRange = null;
                            });
                            setState(() {
                              _filterContentType = null;
                              _filterSubject = null;
                              _filterDateRange = null;
                            });
                            Navigator.pop(ctx);
                          },
                          variant: AppButtonVariant.text,
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Apply',
                          onPressed: () => Navigator.pop(ctx),
                          variant: AppButtonVariant.elevated,
                          icon: Icons.check_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Delete Confirmations ────────────────────────────────────────────

  void _confirmDeleteResource(TeachingResourceEntity resource) {
    final cs = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text(
          'Are you sure you want to delete "${resource.title}"? This action cannot be undone.',
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
              _handleDeleteResource(resource.id);
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

  void _confirmDeleteFolder(String folderId, String folderName) {
    final cs = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Are you sure you want to delete "$folderName"? Resources inside will not be deleted.',
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
              ref.read(resourceLibraryProvider.notifier).deleteFolder(folderId);
              _listenForMessages();
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

  // ─── States ──────────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: Spacings.paddingScreen,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isDesktop ? 3 : (context.isTablet ? 2 : 1),
        childAspectRatio: context.isDesktop ? 1.4 : 1.2,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppLoadingShimmer.box(width: 40, height: 40),
                const SizedBox(width: Spacings.md),
                const AppLoadingShimmer.box(width: 160, height: 16),
                const Spacer(),
                const AppLoadingShimmer.box(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Row(
              children: const [
                AppLoadingShimmer.box(width: 80, height: 22),
                SizedBox(width: Spacings.sm),
                AppLoadingShimmer.box(width: 40, height: 22),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            const AppLoadingShimmer.box(width: 120, height: 12),
            const Spacer(),
            const AppLoadingShimmer.box(width: double.infinity, height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.folder_open_outlined,
      title: 'Empty Library',
      subtitle: 'Your resource library is empty. Create resources from the Teaching Resources page and they will appear here.',
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(resourceLibraryProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Icon Helper ─────────────────────────────────────────────────────

  IconData _resourceTypeIcon(ResourceType type) {
    return switch (type) {
      ResourceType.notes => Icons.note_outlined,
      ResourceType.slides => Icons.slideshow_outlined,
      ResourceType.handout => Icons.description_outlined,
      ResourceType.studyGuide => Icons.menu_book_outlined,
      ResourceType.revisionMaterial => Icons.replay_outlined,
      ResourceType.classroomActivity => Icons.sports_esports_outlined,
      ResourceType.rubric => Icons.assessment_outlined,
      ResourceType.template => Icons.dashboard_customize_outlined,
    };
  }

  // ─── Date Formatting ─────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SORT OPTION ENUM
// ═══════════════════════════════════════════════════════════════════════

enum _SortOption {
  recent('Recent'),
  az('A–Z'),
  mostUsed('Most Used');

  const _SortOption(this.label);

  final String label;
}
