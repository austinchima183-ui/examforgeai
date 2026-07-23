import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart' hide questionFilterProvider;
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/question_entities.dart';
import '../providers/question_filter_provider.dart';
import '../providers/question_provider.dart';
import '../widgets/question_card.dart';
import '../widgets/question_filter_panel.dart';


// ═══════════════════════════════════════════════════════════════════════
// QUESTION LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Question list page with search, filters, bulk selection, and pagination.
///
/// Supports:
/// - Search with debounced query
/// - Expandable filter panel with active filter chips
/// - Paginated list of QuestionCards (grid on desktop)
/// - Bulk selection mode with action toolbar
/// - FAB to create new question
/// - Pull-to-refresh
class QuestionListPage extends ConsumerStatefulWidget {
  const QuestionListPage({super.key});

  @override
  ConsumerState<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends ConsumerState<QuestionListPage> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  // Bulk selection state
  bool _isBulkMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    ref.read(questionBankProvider.notifier).loadQuestions();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(questionBankProvider);
      if (state.hasMore && !state.isLoadingMore) {
        ref.read(questionBankProvider.notifier).loadMoreQuestions();
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.isEmpty) {
        ref.read(questionBankProvider.notifier).loadQuestions();
      } else {
        ref.read(questionBankProvider.notifier).searchQuestions(query);
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(questionBankProvider.notifier).refreshQuestions();
  }

  void _toggleBulkMode() {
    setState(() {
      _isBulkMode = !_isBulkMode;
      if (!_isBulkMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<QuestionEntity> questions) {
    setState(() {
      if (_selectedIds.length == questions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(questions.map((q) => q.id));
      }
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questionState = ref.watch(questionBankProvider);
    final filterState = ref.watch(questionFilterProvider);
    final cs = context.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: _isBulkMode
            ? '${_selectedIds.length} Selected'
            : 'Questions',
        isSearchMode: _isSearchActive,
        searchController: _searchController,
        searchHint: 'Search questions…',
        onSearchToggle: () {
          setState(() => _isSearchActive = !_isSearchActive);
          if (!_isSearchActive) {
            _searchController.clear();
            ref.read(questionBankProvider.notifier).loadQuestions();
          }
        },
        onSearchChanged: _onSearchChanged,
        onSearchSubmitted: (query) {
          ref.read(questionBankProvider.notifier).searchQuestions(query);
        },
        actions: [
          if (!_isBulkMode)
            AppIconButton(
              icon: Icons.checklist_outlined,
              onPressed: _toggleBulkMode,
              tooltip: 'Bulk select',
            ),
          if (_isBulkMode)
            AppIconButton(
              icon: Icons.close_rounded,
              onPressed: _toggleBulkMode,
              tooltip: 'Exit bulk mode',
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: Spacings.mdIcon,
              color: cs.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            onSelected: (value) {
              switch (value) {
                case 'sort_newest':
                  ref
                      .read(questionFilterProvider.notifier)
                      .updateSortBy('newest');
                  _refresh();
                case 'sort_oldest':
                  ref
                      .read(questionFilterProvider.notifier)
                      .updateSortBy('oldest');
                  _refresh();
                case 'sort_most_used':
                  ref
                      .read(questionFilterProvider.notifier)
                      .updateSortBy('most_used');
                  _refresh();
                case 'sort_a_z':
                  ref
                      .read(questionFilterProvider.notifier)
                      .updateSortBy('a_z');
                  _refresh();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sort_newest',
                child: Row(children: [
                  Icon(Icons.schedule_rounded),
                  SizedBox(width: Spacings.md),
                  Text('Newest First'),
                ],),
              ),
              const PopupMenuItem(
                value: 'sort_oldest',
                child: Row(children: [
                  Icon(Icons.history_rounded),
                  SizedBox(width: Spacings.md),
                  Text('Oldest First'),
                ],),
              ),
              const PopupMenuItem(
                value: 'sort_most_used',
                child: Row(children: [
                  Icon(Icons.bar_chart_rounded),
                  SizedBox(width: Spacings.md),
                  Text('Most Used'),
                ],),
              ),
              const PopupMenuItem(
                value: 'sort_a_z',
                child: Row(children: [
                  Icon(Icons.sort_by_alpha_rounded),
                  SizedBox(width: Spacings.md),
                  Text('A → Z'),
                ],),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Panel ────────────────────────────────────────
          const QuestionFilterPanel(),

          // ── Active Filter Chips ─────────────────────────────────
          _buildActiveFilterChips(filterState),

          // ── Result Count + Sort ─────────────────────────────────
          _buildResultHeader(questionState, filterState),

          // ── Question List ───────────────────────────────────────
          Expanded(
            child: _buildQuestionList(context, questionState),
          ),
        ],
      ),
      // ── Bulk Action Toolbar ──────────────────────────────────────
      bottomNavigationBar: _isBulkMode && _selectedIds.isNotEmpty
          ? _buildBulkToolbar()
          : null,
      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: !_isBulkMode
          ? AppFloatingActionButton(
              label: 'New Question',
              icon: Icons.add_rounded,
              extended: context.isDesktop,
              onPressed: () =>
                  context.go(RouteNames.questionBankCreate),
            )
          : null,
    );
  }

  // ─── Active Filter Chips ────────────────────────────────────────────

  Widget _buildActiveFilterChips(QuestionFilterState filterState) {
    final filter = filterState.filter;
    final chips = <_FilterChipData>[];

    if (filter.difficulty != null) {
      chips.add(_FilterChipData(
        label: 'Difficulty: ${filter.difficulty!.label}',
        onRemove: () =>
            ref.read(questionFilterProvider.notifier).updateDifficulty(null),
      ),);
    }
    if (filter.questionType != null) {
      chips.add(_FilterChipData(
        label: 'Type: ${filter.questionType!.label}',
        onRemove: () => ref
            .read(questionFilterProvider.notifier)
            .updateQuestionType(null),
      ),);
    }
    if (filter.examType != null) {
      chips.add(_FilterChipData(
        label: 'Exam: ${filter.examType!.label}',
        onRemove: () =>
            ref.read(questionFilterProvider.notifier).updateExamType(null),
      ),);
    }
    for (final tag in filter.tags) {
      chips.add(_FilterChipData(
        label: '#$tag',
        onRemove: () =>
            ref.read(questionFilterProvider.notifier).removeTag(tag),
      ),);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: Spacings.xs),
              itemBuilder: (context, index) {
                final chip = chips[index];
                return Chip(
                  label: Text(
                    chip.label,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  deleteIcon: const Icon(
                    Icons.close_rounded,
                    size: Spacings.smIcon,
                  ),
                  onDeleted: chip.onRemove,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(questionFilterProvider.notifier).clearAllFilters(),
            child: Text(
              'Clear All',
              style: tt.labelSmall?.copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Result Header ──────────────────────────────────────────────────

  Widget _buildResultHeader(
    QuestionBankState questionState,
    QuestionFilterState filterState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final count = questionState.totalCount > 0
        ? questionState.totalCount
        : questionState.questions.length;
    final hasActiveFilters = filterState.hasActiveFilters;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          Text(
            '$count question${count == 1 ? '' : 's'}${hasActiveFilters ? ' found' : ''}',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (_isBulkMode && questionState.questions.isNotEmpty)
            TextButton(
              onPressed: () => _selectAll(questionState.questions),
              child: Text(
                _selectedIds.length == questionState.questions.length
                    ? 'Deselect All'
                    : 'Select All',
                style: tt.labelSmall?.copyWith(color: cs.primary),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Question List ──────────────────────────────────────────────────

  Widget _buildQuestionList(
    BuildContext context,
    QuestionBankState questionState,
  ) {
    if (questionState.isLoading) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (questionState.error != null) {
      return AppErrorState.genericError(
        message: questionState.error,
        onRetry: _refresh,
      );
    }

    if (questionState.questions.isEmpty) {
      final filterState = ref.read(questionFilterProvider);
      return filterState.hasActiveFilters
          ? AppEmptyState.noResults(
              title: 'No Questions Match Your Filters',
              subtitle:
                  'Try adjusting your search or filters to find what you\'re looking for.',
              actionLabel: 'Clear Filters',
              onAction: () {
                ref.read(questionFilterProvider.notifier).clearAllFilters();
                _refresh();
              },
            )
          : AppEmptyState.noData(
              title: 'No Questions Yet',
              subtitle: 'Create your first question to get started.',
              actionLabel: 'Create Question',
              onAction: () =>
                  context.go(RouteNames.questionBankCreate),
            );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: context.isDesktop
          ? _buildDesktopGrid(questionState)
          : _buildMobileList(questionState),
    );
  }

  // ─── Mobile List ────────────────────────────────────────────────────

  Widget _buildMobileList(QuestionBankState questionState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      itemCount: questionState.questions.length + 1,
      itemBuilder: (context, index) {
        if (index == questionState.questions.length) {
          return _buildLoadMoreIndicator(questionState);
        }

        final question = questionState.questions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _buildQuestionItem(question),
        );
      },
    );
  }

  // ─── Desktop Grid ───────────────────────────────────────────────────

  Widget _buildDesktopGrid(QuestionBankState questionState) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: questionState.questions.length + 1,
      itemBuilder: (context, index) {
        if (index == questionState.questions.length) {
          return _buildLoadMoreIndicator(questionState);
        }

        final question = questionState.questions[index];
        return _buildQuestionItem(question);
      },
    );
  }

  // ─── Question Item ──────────────────────────────────────────────────

  Widget _buildQuestionItem(QuestionEntity question) {
    if (_isBulkMode) {
      return Row(
        children: [
          Checkbox(
            value: _selectedIds.contains(question.id),
            onChanged: (_) => _toggleSelection(question.id),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: QuestionCard(
              question: question,
              mode: QuestionCardMode.compact,
              onTap: () => _toggleSelection(question.id),
            ),
          ),
        ],
      );
    }

    return QuestionCard(
      question: question,
      mode: QuestionCardMode.compact,
      onTap: () => context.go(
        '${RouteNames.questionBankDetail}?id=${question.id}',
      ),
      onEdit: () => context.go(
        '${RouteNames.questionBankEdit}?id=${question.id}',
      ),
      onDuplicate: () => ref
          .read(questionBankProvider.notifier)
          .duplicateQuestion(question.id),
      onArchive: () => ref
          .read(questionBankProvider.notifier)
          .archiveQuestion(question.id),
      onDelete: () => _confirmDelete(question.id),
      onFavouriteToggle: () {
        // TODO: toggle favourite
      },
    );
  }

  // ─── Load More Indicator ────────────────────────────────────────────

  Widget _buildLoadMoreIndicator(QuestionBankState questionState) {
    if (questionState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(Spacings.xl),
        child: Center(child: AppLoadingSpinner()),
      );
    }

    if (questionState.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Center(
          child: AppButton(
            label: 'Load More',
            onPressed: () =>
                ref.read(questionBankProvider.notifier).loadMoreQuestions(),
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: Text(
          'No more questions',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ─── Bulk Toolbar ───────────────────────────────────────────────────

  Widget _buildBulkToolbar() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BulkAction(
              icon: Icons.archive_outlined,
              label: 'Archive',
              onTap: _selectedIds.isNotEmpty
                  ? () {
                      for (final id in _selectedIds) {
                        ref
                            .read(questionBankProvider.notifier)
                            .archiveQuestion(id);
                      }
                      _toggleBulkMode();
                    }
                  : null,
            ),
            _BulkAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.errorOf(cs.brightness),
              onTap: _selectedIds.isNotEmpty
                  ? () async {
                      final confirmed = await AppDialog.showConfirm(
                        context: context,
                        title: 'Delete ${_selectedIds.length} Questions?',
                        message:
                            'This action cannot be undone. All selected questions will be permanently removed.',
                        confirmText: 'Delete All',
                        isDestructive: true,
                      );
                      if (confirmed == true && mounted) {
                        for (final id in _selectedIds) {
                          ref
                              .read(questionBankProvider.notifier)
                              .deleteQuestion(id);
                        }
                        _toggleBulkMode();
                      }
                    }
                  : null,
            ),
            _BulkAction(
              icon: Icons.folder_outlined,
              label: 'Move',
              onTap: _selectedIds.isNotEmpty
                  ? () {
                      // TODO: show move-to-collection dialog
                    }
                  : null,
            ),
            _BulkAction(
              icon: Icons.file_download_outlined,
              label: 'Export',
              onTap: _selectedIds.isNotEmpty
                  ? () {
                      // TODO: export selected questions
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm Delete ─────────────────────────────────────────────────

  Future<void> _confirmDelete(String questionId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Question?',
      message:
          'This action cannot be undone. The question will be permanently removed.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref.read(questionBankProvider.notifier).deleteQuestion(questionId);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _FilterChipData {
  const _FilterChipData({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;
}

class _BulkAction extends StatelessWidget {
  const _BulkAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Spacings.mdIcon, color: effectiveColor),
              const SizedBox(height: Spacings.xs),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: effectiveColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
