import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_resource_usecase.dart';
import '../../domain/usecases/generate_resource_usecase.dart';
import '../providers/teaching_resource_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHING RESOURCES PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page where teachers can create and manage teaching resources: notes,
/// slides, handouts, study guides, revision materials, classroom
/// activities, rubrics, and templates.
class TeachingResourcesPage extends ConsumerStatefulWidget {
  const TeachingResourcesPage({super.key});

  @override
  ConsumerState<TeachingResourcesPage> createState() =>
      _TeachingResourcesPageState();
}

class _TeachingResourcesPageState
    extends ConsumerState<TeachingResourcesPage> {
  final _searchCtrl = TextEditingController();
  ResourceType? _filterResourceType;
  bool _favoritesOnly = false;

  // Folder tree sample data (in production this would come from provider)
  final List<_FolderNode> _folders = [
    const _FolderNode(id: 'all', name: 'All Resources', icon: Icons.folder_outlined),
    const _FolderNode(id: 'notes', name: 'Notes', icon: Icons.note_outlined),
    const _FolderNode(id: 'slides', name: 'Slides', icon: Icons.slideshow_outlined),
    const _FolderNode(id: 'handouts', name: 'Handouts', icon: Icons.description_outlined),
    const _FolderNode(id: 'guides', name: 'Study Guides', icon: Icons.menu_book_outlined),
    const _FolderNode(id: 'revision', name: 'Revision', icon: Icons.replay_outlined),
    const _FolderNode(id: 'activities', name: 'Activities', icon: Icons.sports_esports_outlined),
    const _FolderNode(id: 'rubrics', name: 'Rubrics', icon: Icons.assessment_outlined),
    const _FolderNode(id: 'templates', name: 'Templates', icon: Icons.dashboard_customize_outlined),
  ];

  String _selectedFolderId = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teachingResourceProvider.notifier).loadResources();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(teachingResourceProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(teachingResourceProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(teachingResourceProvider.notifier).clearError();
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

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.title.toLowerCase().contains(query) ||
              (r.subject?.toLowerCase().contains(query) ?? false) ||
              (r.description?.toLowerCase().contains(query) ?? false) ||
              (r.topic?.toLowerCase().contains(query) ?? false),)
          .toList();
    }

    // Resource type filter
    if (_filterResourceType != null) {
      filtered = filtered
          .where((r) => r.resourceType == _filterResourceType)
          .toList();
    }

    // Favorites only
    if (_favoritesOnly) {
      filtered = filtered.where((r) => r.isFavorite).toList();
    }

    return filtered;
  }

  Future<void> _handleRefresh() async {
    await ref.read(teachingResourceProvider.notifier).loadResources();
    _listenForMessages();
  }

  void _handleDelete(String resourceId) {
    ref.read(teachingResourceProvider.notifier).deleteResource(resourceId);
    _listenForMessages();
  }

  void _handleToggleFavorite(String resourceId) {
    ref.read(teachingResourceProvider.notifier).toggleFavorite(resourceId);
    _listenForMessages();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teachingResourceProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Teaching Resources',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _showCreateResourceDialog,
            tooltip: 'New Resource',
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.resources.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Resource',
        icon: Icons.add_rounded,
        onPressed: _showCreateResourceDialog,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(TeachingResourceState state) {
    final filteredResources = _applyLocalFilters(state.resources);
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar with folder tree
          _buildFolderSidebar(),
          // Vertical divider
          const VerticalDivider(width: 1),
          // Main content
          Expanded(
            child: _buildMainContent(state, filteredResources),
          ),
        ],
      );
    }

    // Mobile layout
    return _buildMainContent(state, filteredResources);
  }

  Widget _buildMainContent(
    TeachingResourceState state,
    List<TeachingResourceEntity> filteredResources,
  ) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Search bar + folder dropdown (mobile)
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Mobile folder dropdown
          if (!context.isDesktop)
            SliverToBoxAdapter(child: _buildFolderDropdown()),
          if (!context.isDesktop)
            const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(
            child: _buildResultsCount(filteredResources.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Resource grid/list
          if (filteredResources.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildResourceCard(filteredResources[index]),
                  ),
                  childCount: filteredResources.length,
                ),
              ),
            ),

          // Load more trigger
          if (state.hasMore && filteredResources.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Center(
                  child: AppButton(
                    label: 'Load More',
                    onPressed: () => ref
                        .read(teachingResourceProvider.notifier)
                        .loadResources(),
                    variant: AppButtonVariant.text,
                    isLoading: state.isLoadingMore,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Folder Sidebar (Desktop) ────────────────────────────────────────

  Widget _buildFolderSidebar() {
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
            child: Text(
              'Folders',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ..._folders.map((folder) => _buildFolderTile(folder)),
        ],
      ),
    );
  }

  Widget _buildFolderTile(_FolderNode folder) {
    final cs = context.colorScheme;
    final isSelected = _selectedFolderId == folder.id;

    return ListTile(
      dense: true,
      leading: Icon(
        folder.icon,
        size: Spacings.mdIcon,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        folder.name,
        style: context.textTheme.bodyMedium?.copyWith(
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
          fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
        ),
      ),
      selected: isSelected,
      selectedTileColor: cs.primary.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      onTap: () => setState(() => _selectedFolderId = folder.id),
    );
  }

  // ─── Folder Dropdown (Mobile) ────────────────────────────────────────

  Widget _buildFolderDropdown() {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedFolderId,
        decoration: InputDecoration(
          prefixIcon: Icon(
            _folders.firstWhere((f) => f.id == _selectedFolderId).icon,
            color: cs.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
        ),
        items: _folders
            .map((f) => DropdownMenuItem(
                  value: f.id,
                  child: Row(
                    children: [
                      Icon(f.icon, size: Spacings.smIcon),
                      const SizedBox(width: Spacings.sm),
                      Text(f.name),
                    ],
                  ),
                ),)
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _selectedFolderId = v);
        },
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
      child: AppSearchField(
        hint: 'Search resources...',
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
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
          // Resource type filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _buildFilterDropdown<ResourceType>(
              label: 'Resource Type',
              value: _filterResourceType,
              items: ResourceType.values,
              itemLabel: (t) => t.label,
              onChanged: (v) => setState(() => _filterResourceType = v),
            ),
          ),

          // Favorites only toggle
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: const Text('Favorites'),
              avatar: Icon(
                _favoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
              ),
              selected: _favoritesOnly,
              onSelected: (selected) =>
                  setState(() => _favoritesOnly = selected),
            ),
          ),

          // Clear all filters
          if (_filterResourceType != null || _favoritesOnly)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _filterResourceType = null;
                    _favoritesOnly = false;
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
                            color: context.colorScheme.primary,)
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

  // ─── Results Count ───────────────────────────────────────────────────

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Text(
        '$count resource${count != 1 ? 's' : ''}',
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: type icon + title + badges + favorite
          Row(
            children: [
              // Resource type icon/badge
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
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
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // AI badge
              if (resource.isAiGenerated)
                Container(
                  margin: const EdgeInsets.only(left: Spacings.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: cs.onTertiaryContainer),
                      const SizedBox(width: 2),
                      Text(
                        'AI',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
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

          // Resource type badge
          _buildChip(
            icon: _resourceTypeIcon(resource.resourceType),
            label: resource.resourceType.label,
            color: cs.secondary,
          ),

          // Subject + Class + Topic
          const SizedBox(height: Spacings.sm),
          Text(
            [
              if (resource.subject != null) resource.subject,
              if (resource.className != null) resource.className,
              if (resource.topic != null) resource.topic,
            ].join(' · '),
            style: context.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Tags
          if (resource.tags.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: resource.tags
                  .take(4)
                  .map((tag) => Chip(
                        label: Text(
                          tag,
                          style: context.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),)
                  .toList(),
            ),
          ],

          // Created date
          const SizedBox(height: Spacings.md),
          Text(
            'Created ${_formatDate(resource.createdAt)}',
            style: context.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: Spacings.md),

          // Action buttons row
          Row(
            children: [
              AppButton(
                label: 'Edit',
                onPressed: () {
                  // TODO: Navigate to edit resource
                },
                variant: AppButtonVariant.text,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(resource),
                variant: AppButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              GenerateQuestionsButton(
                resourceType: 'teaching_resource',
                resourceId: resource.id,
                resourceName: resource.title,
                subject: resource.subject,
                topic: resource.topic,
              ),
            ],
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

  // ─── Create Resource Dialog ──────────────────────────────────────────

  void _showCreateResourceDialog() {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    ResourceType selectedType = ResourceType.notes;
    final formKey = GlobalKey<FormState>();

    AppDialog.showCustom(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog title
                Text(
                  'New Resource',
                  style: dialogCtx.textTheme.titleLarge?.copyWith(
                    color: dialogCtx.colorScheme.onSurface,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
                const SizedBox(height: Spacings.lg),

                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title (required)
                      AppTextField(
                        label: 'Title',
                        hint: 'Enter resource title',
                        controller: titleCtrl,
                        isRequired: true,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: Spacings.md),

                      // Resource Type dropdown
                      DropdownButtonFormField<ResourceType>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Resource Type',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(Spacings.mdRadius),
                          ),
                        ),
                        items: ResourceType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Icon(_resourceTypeIcon(t), size: 16),
                                      const SizedBox(width: Spacings.sm),
                                      Text(t.label),
                                    ],
                                  ),
                                ),)
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedType = v);
                          }
                        },
                      ),
                      const SizedBox(height: Spacings.md),

                      // Subject
                      AppTextField(
                        label: 'Subject',
                        hint: 'e.g. Mathematics',
                        controller: subjectCtrl,
                      ),
                      const SizedBox(height: Spacings.md),

                      // Class
                      AppTextField(
                        label: 'Class',
                        hint: 'e.g. SS2',
                        controller: classCtrl,
                      ),
                      const SizedBox(height: Spacings.md),

                      // Topic
                      AppTextField(
                        label: 'Topic',
                        hint: 'e.g. Quadratic Equations',
                        controller: topicCtrl,
                      ),
                      const SizedBox(height: Spacings.md),

                      // Content
                      AppTextField(
                        label: 'Content',
                        hint: 'Enter or paste content here...',
                        controller: contentCtrl,
                        maxLines: 5,
                        minLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacings.xl),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Create',
                        onPressed: () => _handleCreateResource(
                          titleCtrl.text.trim(),
                          selectedType,
                          subjectCtrl.text.trim(),
                          classCtrl.text.trim(),
                          topicCtrl.text.trim(),
                          contentCtrl.text.trim(),
                        ),
                        variant: AppButtonVariant.elevated,
                        icon: Icons.check_rounded,
                        isLoading:
                            ref.read(teachingResourceProvider).isCreating,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: AppButton(
                        label: 'Generate with AI',
                        onPressed: () => _handleGenerateWithAI(
                          titleCtrl.text.trim(),
                          selectedType,
                          subjectCtrl.text.trim(),
                          classCtrl.text.trim(),
                          topicCtrl.text.trim(),
                        ),
                        variant: AppButtonVariant.tonal,
                        icon: Icons.auto_awesome,
                        isLoading:
                            ref.read(teachingResourceProvider).isGenerating,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreateResource(
    String title,
    ResourceType type,
    String subject,
    String className,
    String topic,
    String content,
  ) async {
    if (title.isEmpty) {
      _showSnackBar('Title is required', isError: true);
      return;
    }

    Navigator.pop(context); // Close dialog

    final now = DateTime.now();
    await ref.read(teachingResourceProvider.notifier).createResource(
          CreateResourceParams(
            resource: TeachingResourceEntity(
              id: '',
              teacherId: '',
              title: title,
              resourceType: type,
              subject: subject.isEmpty ? null : subject,
              className: className.isEmpty ? null : className,
              topic: topic.isEmpty ? null : topic,
              content: content.isEmpty ? null : content,
              createdAt: now,
              updatedAt: now,
            ),
          ),
        );

    _listenForMessages();
  }

  Future<void> _handleGenerateWithAI(
    String title,
    ResourceType type,
    String subject,
    String className,
    String topic,
  ) async {
    Navigator.pop(context); // Close dialog

    await ref.read(teachingResourceProvider.notifier).generateResource(
          GenerateResourceParams(
            resourceType: type,
            subject: subject.isEmpty ? title : subject,
            topic: topic.isEmpty ? null : topic,
            className: className.isEmpty ? null : className,
          ),
        );

    _listenForMessages();
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
                  SizedBox(width: Spacings.md),
                  AppLoadingShimmer.box(width: 200, height: 16),
                  Spacer(),
                  AppLoadingShimmer.box(width: 24, height: 24),
                ],
              ),
              SizedBox(height: Spacings.sm),
              AppLoadingShimmer.box(width: 150, height: 14),
              SizedBox(height: Spacings.sm),
              Row(
                children: [
                  AppLoadingShimmer.box(width: 80, height: 22),
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 60, height: 22),
                ],
              ),
              SizedBox(height: Spacings.md),
              AppLoadingShimmer.box(width: 120, height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.folder_open_outlined,
      title: 'No Resources Yet',
      subtitle:
          'Create your first teaching resource with AI assistance or start from scratch.',
      actionLabel: 'Create Resource',
      onAction: _showCreateResourceDialog,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(teachingResourceProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Delete Confirmation ─────────────────────────────────────────────

  void _confirmDelete(TeachingResourceEntity resource) {
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
              _handleDelete(resource.id);
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
}

// ═══════════════════════════════════════════════════════════════════════
// FOLDER NODE HELPER
// ═══════════════════════════════════════════════════════════════════════

class _FolderNode {
  const _FolderNode({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}
