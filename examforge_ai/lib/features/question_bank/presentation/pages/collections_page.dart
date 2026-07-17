import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../domain/entities/question_entities.dart';
import '../providers/collection_provider.dart';
import '../widgets/collection_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// COLLECTIONS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Collections management page with search, filter tabs, grid of
/// CollectionCards, create/edit/delete dialogs, and pull-to-refresh.
class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  _CollectionFilter _filter = _CollectionFilter.all;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _CollectionFilter.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filter = _CollectionFilter.values[_tabController.index];
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(collectionProvider.notifier).loadCollections();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collectionProvider);
    final cs = context.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Collections',
        bottom: TabBar(
          controller: _tabController,
          tabs: _CollectionFilter.values
              .map((f) => Tab(text: _filterLabel(f)))
              .toList(),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          dividerColor: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg,
              Spacings.md,
              Spacings.lg,
              Spacings.sm,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: 'Search collections…',
              onChanged: (query) => setState(() {}),
            ),
          ),

          // ── Collection Grid ────────────────────────────────────────
          Expanded(
            child: _buildCollectionList(context, state),
          ),
        ],
      ),
      floatingActionButton: AppFloatingActionButton(
        label: 'Create',
        icon: Icons.add_rounded,
        extended: context.isDesktop,
        onPressed: _showCreateCollectionDialog,
      ),
    );
  }

  // ─── Collection List ────────────────────────────────────────────────

  Widget _buildCollectionList(BuildContext context, CollectionState state) {
    if (state.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && state.collections.isEmpty) {
      return AppErrorState(
        title: 'Failed to Load Collections',
        message: state.error,
        onRetry: () => ref.read(collectionProvider.notifier).loadCollections(),
      );
    }

    var collections = state.collections;

    // Apply search filter
    collections = _applySearch(collections);

    // Apply tab filter
    collections = _applyFilter(collections);

    if (collections.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Collections',
        subtitle: _filter == _CollectionFilter.all
            ? 'Create your first collection to organize questions.'
            : 'No ${_filterLabel(_filter).toLowerCase()} collections found.',
        actionLabel: 'Create Collection',
        onAction: _showCreateCollectionDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(collectionProvider.notifier).loadCollections(),
      child: GridView.builder(
        padding: const EdgeInsets.all(Spacings.lg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: context.isMobile ? 1 : (context.isTablet ? 2 : 3),
          childAspectRatio: context.isMobile ? 0.72 : 0.78,
          crossAxisSpacing: Spacings.md,
          mainAxisSpacing: Spacings.md,
        ),
        itemCount: collections.length,
        itemBuilder: (context, index) {
          final collection = collections[index];
          return GestureDetector(
            onLongPress: () => _showCollectionOptions(collection),
            child: CollectionCard(
              collection: collection,
              onTap: () => _navigateToDetail(context, collection.id),
              onEdit: () => _showEditCollectionDialog(collection),
              onDelete: () => _confirmDeleteCollection(collection.id),
            ),
          );
        },
      ),
    );
  }

  // ─── Filter Logic ───────────────────────────────────────────────────

  List<QuestionCollectionEntity> _applySearch(
    List<QuestionCollectionEntity> collections,
  ) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return collections;

    return collections
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  List<QuestionCollectionEntity> _applyFilter(
    List<QuestionCollectionEntity> collections,
  ) {
    switch (_filter) {
      case _CollectionFilter.all:
        return collections;
      case _CollectionFilter.my:
        return collections
            .where((c) => !c.isShared && !c.isOfficial)
            .toList();
      case _CollectionFilter.shared:
        return collections.where((c) => c.isShared).toList();
      case _CollectionFilter.official:
        return collections.where((c) => c.isOfficial).toList();
    }
  }

  String _filterLabel(_CollectionFilter f) {
    switch (f) {
      case _CollectionFilter.all:
        return 'All';
      case _CollectionFilter.my:
        return 'My Collections';
      case _CollectionFilter.shared:
        return 'Shared';
      case _CollectionFilter.official:
        return 'Official';
    }
  }

  // ─── Create Collection Dialog ───────────────────────────────────────

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isShared = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  const Text('Create Collection'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Collection Name',
                      hint: 'e.g. Biology Chapter 5',
                      isRequired: true,
                      prefixIcon: Icons.collections_bookmark_outlined,
                    ),
                    const SizedBox(height: Spacings.md),
                    AppTextField(
                      controller: descController,
                      label: 'Description',
                      hint: 'Optional description…',
                      maxLines: 3,
                    ),
                    const SizedBox(height: Spacings.md),
                    SwitchListTile(
                      title: const Text('Share with others'),
                      subtitle: const Text(
                        'Allow other teachers to view this collection',
                      ),
                      value: isShared,
                      onChanged: (v) => setDialogState(() => isShared = v),
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        isShared
                            ? Icons.share_rounded
                            : Icons.share_outlined,
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
                    if (nameController.text.trim().isNotEmpty) {
                      ref.read(collectionProvider.notifier).createCollection(
                            QuestionCollectionEntity(
                              id:
                                  'col_${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              description: descController.text.trim().isNotEmpty
                                  ? descController.text.trim()
                                  : null,
                              isShared: isShared,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Edit Collection Dialog ─────────────────────────────────────────

  void _showEditCollectionDialog(QuestionCollectionEntity collection) {
    final nameController = TextEditingController(text: collection.name);
    final descController =
        TextEditingController(text: collection.description ?? '');
    bool isShared = collection.isShared;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  const Text('Edit Collection'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Collection Name',
                      isRequired: true,
                      prefixIcon: Icons.collections_bookmark_outlined,
                    ),
                    const SizedBox(height: Spacings.md),
                    AppTextField(
                      controller: descController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: Spacings.md),
                    SwitchListTile(
                      title: const Text('Share with others'),
                      subtitle: const Text(
                        'Allow other teachers to view this collection',
                      ),
                      value: isShared,
                      onChanged: (v) => setDialogState(() => isShared = v),
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        isShared
                            ? Icons.share_rounded
                            : Icons.share_outlined,
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
                    if (nameController.text.trim().isNotEmpty) {
                      ref.read(collectionProvider.notifier).updateCollection(
                            collection.copyWith(
                              name: nameController.text.trim(),
                              description: descController.text.trim().isNotEmpty
                                  ? descController.text.trim()
                                  : null,
                              isShared: isShared,
                            ),
                          );
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Long-press Options ─────────────────────────────────────────────

  void _showCollectionOptions(QuestionCollectionEntity collection) {
    final cs = context.colorScheme;

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
              child: Text(
                collection.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('View Details'),
              onTap: () {
                Navigator.of(ctx).pop();
                _navigateToDetail(context, collection.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Collection'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditCollectionDialog(collection);
              },
            ),
            if (collection.isShared)
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Unshare Collection'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(collectionProvider.notifier).updateCollection(
                        collection.copyWith(isShared: false),
                      );
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share Collection'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(collectionProvider.notifier).updateCollection(
                        collection.copyWith(isShared: true),
                      );
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.errorOf(cs.brightness),
              ),
              title: Text(
                'Delete Collection',
                style: TextStyle(color: AppColors.errorOf(cs.brightness)),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteCollection(collection.id);
              },
            ),
            const SizedBox(height: Spacings.md),
          ],
        ),
      ),
    );
  }

  // ─── Confirm Delete ─────────────────────────────────────────────────

  Future<void> _confirmDeleteCollection(String collectionId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Collection?',
      message:
          'This will remove the collection but not the questions inside it. This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref.read(collectionProvider.notifier).deleteCollection(collectionId);
    }
  }

  // ─── Navigation ─────────────────────────────────────────────────────

  void _navigateToDetail(BuildContext context, String collectionId) {
    context.go(
      '${RouteNames.questionBankCollections}/$collectionId',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER ENUMS
// ═══════════════════════════════════════════════════════════════════════

enum _CollectionFilter { all, my, shared, official }
