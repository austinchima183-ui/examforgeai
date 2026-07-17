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
import '../widgets/question_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// COLLECTION DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Collection detail page showing the collection header, question list
/// with drag handles for reordering, swipe-to-remove, add questions
/// dialog, share dialog, and edit bottom sheet.
class CollectionDetailPage extends ConsumerStatefulWidget {
  const CollectionDetailPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState extends ConsumerState<CollectionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(collectionProvider.notifier)
          .loadCollectionQuestions(widget.collectionId);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collectionProvider);
    final collection = state.currentCollection;
    final questions = state.collectionQuestions;

    return Scaffold(
      appBar: AppAppBar(
        title: collection?.name ?? 'Collection',
        actions: [
          if (collection != null) ...[
            AppIconButton(
              icon: Icons.edit_outlined,
              onPressed: () => _showEditBottomSheet(collection),
              tooltip: 'Edit Collection',
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: Spacings.mdIcon,
                color: context.colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              position: PopupMenuPosition.under,
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    _showShareDialog(collection);
                  case 'delete':
                    _confirmDeleteCollection();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded),
                      SizedBox(width: Spacings.md),
                      Text('Share Collection'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      const SizedBox(width: Spacings.md),
                      Text('Delete Collection',
                          style:
                              TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null && collection == null
              ? AppErrorState(
                  title: 'Failed to Load Collection',
                  message: state.error,
                  onRetry: () => ref
                      .read(collectionProvider.notifier)
                      .loadCollectionQuestions(widget.collectionId),
                )
              : _buildContent(context, state, collection, questions),
    );
  }

  // ─── Main Content ───────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    CollectionState state,
    QuestionCollectionEntity? collection,
    List<QuestionEntity> questions,
  ) {
    if (collection == null) {
      return AppEmptyState.noData(
        title: 'Collection Not Found',
        subtitle: 'This collection may have been deleted.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionProvider.notifier)
          .loadCollectionQuestions(widget.collectionId),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Collection Header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, collection, questions.length),
          ),

          // ── Add Questions Button ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Add Questions',
                      onPressed: _showAddQuestionsDialog,
                      variant: AppButtonVariant.tonal,
                      fullWidth: true,
                      icon: Icons.add_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  AppIconButton(
                    icon: Icons.share_rounded,
                    onPressed: () => _showShareDialog(collection),
                    tooltip: 'Share Collection',
                    variant: AppIconButtonVariant.tonal,
                  ),
                ],
              ),
            ),
          ),

          // ── Questions List ─────────────────────────────────────────
          if (questions.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState.noData(
                title: 'No Questions in Collection',
                subtitle: 'Add questions to this collection to get started.',
                actionLabel: 'Add Questions',
                onAction: _showAddQuestionsDialog,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
              ),
              sliver: SliverReorderableList(
                onReorder: (oldIndex, newIndex) {
                  // Reorder logic — handled locally for now
                  // In production, persist the new order via the repository
                },
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Padding(
                    key: ValueKey(question.id),
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildQuestionItem(
                      context,
                      question,
                      index,
                    ),
                  );
                },
              ),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: Spacings.xxl),
          ),
        ],
      ),
    );
  }

  // ─── Collection Header ──────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    QuestionCollectionEntity collection,
    int questionCount,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(Spacings.xlRadius),
          bottomRight: Radius.circular(Spacings.xlRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            collection.name,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: Colors.white,
            ),
          ),

          // Description
          if (collection.description != null &&
              collection.description!.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Text(
              collection.description!,
              style: tt.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: Spacings.lg),

          // Badges row
          Row(
            children: [
              _buildHeaderStat(
                context,
                icon: Icons.quiz_outlined,
                value: '$questionCount',
                label: questionCount == 1 ? 'Question' : 'Questions',
              ),
              if (collection.isShared) ...[
                const SizedBox(width: Spacings.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.share_rounded,
                        size: 14.0,
                        color: Colors.white,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Shared',
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (collection.isOfficial) ...[
                const SizedBox(width: Spacings.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14.0,
                        color: Colors.white,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Official',
                        style: tt.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Created info
              _buildHeaderStat(
                context,
                icon: Icons.person_outline_rounded,
                value: collection.createdBy ?? 'Unknown',
                label: 'Created by',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: Colors.white70),
        const SizedBox(width: Spacings.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: AppTypography.wSemiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: Colors.white60,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Question Item ──────────────────────────────────────────────────

  Widget _buildQuestionItem(
    BuildContext context,
    QuestionEntity question,
    int index,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Dismissible(
      key: ValueKey(question.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_circle_outline_rounded,
                color: AppColors.errorOf(cs.brightness)),
            Text(
              'Remove',
              style: tt.labelSmall?.copyWith(
                color: AppColors.errorOf(cs.brightness),
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => _confirmRemoveFromCollection(question),
      onDismissed: (_) {
        ref
            .read(collectionProvider.notifier)
            .removeQuestionFromCollection(
              widget.collectionId,
              question.id,
            );
      },
      child: AppCard(
        padding: const EdgeInsets.all(Spacings.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle + position number
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(Spacings.xs),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.drag_indicator_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    Text(
                      '${index + 1}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),

            // Question card in compact mode
            Expanded(
              child: QuestionCard(
                question: question,
                mode: QuestionCardMode.compact,
                onTap: () => _navigateToDetail(context, question.id),
                onEdit: () => _navigateToEditor(context, question.id),
              ),
            ),

            // Remove button
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
              onPressed: () => _removeFromCollection(question.id),
              tooltip: 'Remove from collection',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edit Collection Bottom Sheet ───────────────────────────────────

  void _showEditBottomSheet(QuestionCollectionEntity collection) {
    final nameController = TextEditingController(text: collection.name);
    final descController =
        TextEditingController(text: collection.description ?? '');
    bool isShared = collection.isShared;

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
            return Padding(
              padding: EdgeInsets.only(
                left: Spacings.lg,
                right: Spacings.lg,
                top: Spacings.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacings.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),

                  // Title
                  Text(
                    'Edit Collection',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xl),

                  // Name field
                  AppTextField(
                    controller: nameController,
                    label: 'Collection Name',
                    isRequired: true,
                    prefixIcon: Icons.collections_bookmark_outlined,
                  ),
                  const SizedBox(height: Spacings.md),

                  // Description field
                  AppTextField(
                    controller: descController,
                    label: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: Spacings.md),

                  // Shared toggle
                  SwitchListTile(
                    title: const Text('Share with others'),
                    subtitle: const Text(
                      'Allow other teachers to view this collection',
                    ),
                    value: isShared,
                    onChanged: (v) => setSheetState(() => isShared = v),
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      isShared ? Icons.share_rounded : Icons.share_outlined,
                      color: isShared
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.xl),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Save Changes',
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          ref
                              .read(collectionProvider.notifier)
                              .updateCollection(
                                collection.copyWith(
                                  name: nameController.text.trim(),
                                  description:
                                      descController.text.trim().isNotEmpty
                                          ? descController.text.trim()
                                          : null,
                                  isShared: isShared,
                                ),
                              );
                          Navigator.of(ctx).pop();
                        }
                      },
                      variant: AppButtonVariant.elevated,
                      fullWidth: true,
                      icon: Icons.check_rounded,
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Share Dialog ───────────────────────────────────────────────────

  void _showShareDialog(QuestionCollectionEntity collection) {
    final emailController = TextEditingController();
    String permission = 'read';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.share_rounded,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  const Text('Share Collection'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share "${collection.name}" with other teachers:',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacings.lg),
                    AppTextField(
                      controller: emailController,
                      label: 'Email Address',
                      hint: 'teacher@school.edu',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: Spacings.md),
                    Text(
                      'Permission',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.sm),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'read',
                          label: Text('View'),
                          icon: Icon(Icons.visibility_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: 'edit',
                          label: Text('Edit'),
                          icon: Icon(Icons.edit_outlined, size: 16),
                        ),
                      ],
                      selected: {permission},
                      onSelectionChanged: (selected) {
                        setDialogState(() => permission = selected.first);
                      },
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
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Collection shared successfully!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Spacings.mdRadius),
                        ),
                      ),
                    );
                  },
                  child: const Text('Share'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Add Questions Dialog ───────────────────────────────────────────

  void _showAddQuestionsDialog() {
    final searchController = TextEditingController();
    final Set<String> selectedIds = {};

    // Simulated list of available questions
    final availableQuestions = List.generate(
      10,
      (i) => QuestionEntity(
        id: 'q_$i',
        subjectId: 'sub_1',
        questionType: QuestionType.multipleChoice,
        difficulty: DifficultyLevel.medium,
        content: 'Sample question ${i + 1} for adding to collection',
        marks: 2.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.isDesktop ? 600 : double.infinity,
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(Spacings.lg),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: context.colorScheme.primary,
                          ),
                          const SizedBox(width: Spacings.sm),
                          Expanded(
                            child: Text(
                              'Add Questions',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                          ),
                          if (selectedIds.isNotEmpty)
                            Text(
                              '${selectedIds.length} selected',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.primary,
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Search
                    Padding(
                      padding: const EdgeInsets.all(Spacings.lg),
                      child: AppSearchField(
                        controller: searchController,
                        hint: 'Search questions…',
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),

                    // Question list
                    Flexible(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.lg,
                        ),
                        itemCount: availableQuestions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacings.sm),
                        itemBuilder: (context, index) {
                          final question = availableQuestions[index];
                          final isSelected =
                              selectedIds.contains(question.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  selectedIds.add(question.id);
                                } else {
                                  selectedIds.remove(question.id);
                                }
                              });
                            },
                            title: Text(
                              question.content,
                              style: context.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${question.questionType.label} • ${question.difficulty.label} • ${question.marks.toInt()} marks',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(Spacings.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.of(ctx).pop(),
                            variant: AppButtonVariant.text,
                          ),
                          const SizedBox(width: Spacings.sm),
                          AppButton(
                            label: 'Add Selected',
                            onPressed: selectedIds.isEmpty
                                ? null
                                : () {
                                    for (final id in selectedIds) {
                                      ref
                                          .read(collectionProvider.notifier)
                                          .addQuestionToCollection(
                                            widget.collectionId,
                                            id,
                                          );
                                    }
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${selectedIds.length} question${selectedIds.length == 1 ? '' : 's'} added to collection',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              Spacings.mdRadius),
                                        ),
                                      ),
                                    );
                                  },
                            variant: AppButtonVariant.elevated,
                            isDisabled: selectedIds.isEmpty,
                            icon: Icons.add_rounded,
                          ),
                        ],
                      ),
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

  // ─── Remove from Collection ─────────────────────────────────────────

  Future<bool?> _confirmRemoveFromCollection(QuestionEntity question) {
    return AppDialog.showConfirm(
      context: context,
      title: 'Remove from Collection?',
      message:
          'This will remove the question from this collection. The question itself will not be deleted.',
      confirmText: 'Remove',
    );
  }

  void _removeFromCollection(String questionId) {
    ref.read(collectionProvider.notifier).removeQuestionFromCollection(
          widget.collectionId,
          questionId,
        );
  }

  // ─── Confirm Delete Collection ──────────────────────────────────────

  Future<void> _confirmDeleteCollection() async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Collection?',
      message:
          'This will permanently delete this collection. The questions inside will not be deleted. This cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref
          .read(collectionProvider.notifier)
          .deleteCollection(widget.collectionId);
      Navigator.of(context).pop();
    }
  }

  // ─── Navigation ─────────────────────────────────────────────────────

  void _navigateToDetail(BuildContext context, String questionId) {
    context.go(
      '${RouteNames.questionBankDetail}?id=$questionId',
    );
  }

  void _navigateToEditor(BuildContext context, String questionId) {
    context.go(
      '${RouteNames.questionBankEdit}?id=$questionId',
    );
  }
}
