import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';

class ContentCollectionsPage extends ConsumerStatefulWidget {
  const ContentCollectionsPage({super.key});

  @override
  ConsumerState<ContentCollectionsPage> createState() =>
      _ContentCollectionsPageState();
}

class _ContentCollectionsPageState
    extends ConsumerState<ContentCollectionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentCollectionProvider.notifier).loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentCollectionProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Collections',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _showCreateDialog,
            tooltip: 'Create Collection',
          ),
        ],
      ),
      body: state.isLoading && state.collections.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null
              ? AppErrorState(
                  message: state.error,
                  onRetry: () => ref
                      .read(contentCollectionProvider.notifier)
                      .loadCollections(),
                )
              : state.collections.isEmpty
                  ? AppEmptyState.noData(
                      subtitle: 'No collections yet',
                      actionLabel: 'Create Collection',
                      onAction: _showCreateDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(contentCollectionProvider.notifier)
                          .loadCollections(),
                      child: GridView.builder(
                        padding: Spacings.paddingScreen,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.isDesktop
                              ? 4
                              : context.isTablet
                                  ? 3
                                  : 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: Spacings.md,
                          mainAxisSpacing: Spacings.md,
                        ),
                        itemCount: state.collections.length,
                        itemBuilder: (context, index) {
                          final collection = state.collections[index];
                          return AppCard(
                            onTap: () =>
                                _showCollectionDetail(collection),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                        Icons.collections_bookmark_rounded,
                                        size: Spacings.lgIcon,
                                        color: cs.primary),
                                    const SizedBox(width: Spacings.sm),
                                    Expanded(
                                      child: Text(collection.name,
                                          style: tt.titleSmall?.copyWith(
                                              fontWeight:
                                                  AppTypography.wSemiBold),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          _showEditDialog(collection);
                                        }
                                        if (v == 'delete') {
                                          _confirmDelete(collection);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit')),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete')),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Spacings.sm),
                                Text('${collection.itemCount} items',
                                    style: tt.bodyMedium?.copyWith(
                                        color: cs.onSurfaceVariant)),
                                if (collection.description != null) ...[
                                  const SizedBox(height: Spacings.xs),
                                  Text(collection.description!,
                                      style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                const Spacer(),
                                Row(
                                  children: [
                                    if (collection.isPublic) ...[
                                      Icon(Icons.public_rounded,
                                          size: 14,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: Spacings.xs),
                                      Text('Public',
                                          style: tt.bodySmall?.copyWith(
                                              color:
                                                  cs.onSurfaceVariant)),
                                    ] else ...[
                                      Icon(Icons.lock_outline_rounded,
                                          size: 14,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: Spacings.xs),
                                      Text('Private',
                                          style: tt.bodySmall?.copyWith(
                                              color:
                                                  cs.onSurfaceVariant)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var isPublic = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                SwitchListTile(
                  value: isPublic,
                  onChanged: (v) =>
                      setDialogState(() => isPublic = v),
                  title: const Text('Public'),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Create',
              onPressed: () {
                ref
                    .read(contentCollectionProvider.notifier)
                    .createCollection(ContentCollection(
                      id: '',
                      name: nameCtrl.text,
                      description: descCtrl.text.isEmpty
                          ? null
                          : descCtrl.text,
                      isPublic: isPublic,
                      itemCount: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ContentCollection collection) {
    final nameCtrl = TextEditingController(text: collection.name);
    final descCtrl =
        TextEditingController(text: collection.description ?? '');
    var isPublic = collection.isPublic;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                SwitchListTile(
                  value: isPublic,
                  onChanged: (v) =>
                      setDialogState(() => isPublic = v),
                  title: const Text('Public'),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Save',
              onPressed: () {
                ref
                    .read(contentCollectionProvider.notifier)
                    .updateCollection(ContentCollection(
                      id: collection.id,
                      name: nameCtrl.text,
                      description: descCtrl.text.isEmpty
                          ? null
                          : descCtrl.text,
                      isPublic: isPublic,
                      itemCount: collection.itemCount,
                      createdAt: collection.createdAt,
                      updatedAt: DateTime.now(),
                    ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ContentCollection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
            'Are you sure you want to delete "${collection.name}"? Items in the collection will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            onPressed: () {
              ref
                  .read(contentCollectionProvider.notifier)
                  .deleteCollection(collection.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCollectionDetail(ContentCollection collection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: Spacings.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(collection.name,
                        style: context.textTheme.headlineSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold)),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (collection.description != null) ...[
                const SizedBox(height: Spacings.sm),
                Text(collection.description!,
                    style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: Spacings.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '${collection.itemCount} items in this collection',
                      style: context.textTheme.bodyLarge),
                  AppButton(
                    label: 'Add Item',
                    onPressed: () {
                      // Add item from content library
                      Navigator.pop(context);
                    },
                    size: AppButtonSize.small,
                    icon: Icons.add_rounded,
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              // Placeholder for content items list with reorder support
              if (collection.itemCount == 0)
                AppEmptyState.noData(
                    subtitle: 'No items in this collection')
              else
                Text('Content items will appear here with drag handles for reordering.',
                    style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
