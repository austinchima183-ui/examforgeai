import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/oral_question_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all oral question sets with search, filter, and CRUD actions.
class OralQuestionListPage extends ConsumerStatefulWidget {
  const OralQuestionListPage({super.key});

  @override
  ConsumerState<OralQuestionListPage> createState() =>
      _OralQuestionListPageState();
}

class _OralQuestionListPageState extends ConsumerState<OralQuestionListPage> {
  final _searchCtrl = TextEditingController();
  String? _filterSubject;
  StudentLevel? _filterDifficulty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(oralQuestionProvider.notifier).loadOralQuestions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(oralQuestionProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(oralQuestionProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(oralQuestionProvider.notifier).clearError();
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

  List<OralQuestionEntity> _applyLocalFilters(List<OralQuestionEntity> items) {
    var filtered = items;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((oq) =>
              oq.title.toLowerCase().contains(query) ||
              (oq.description?.toLowerCase().contains(query) ?? false) ||
              (oq.topic?.toLowerCase().contains(query) ?? false),)
          .toList();
    }

    // Subject filter
    if (_filterSubject != null) {
      filtered =
          filtered.where((oq) => oq.subjectId == _filterSubject).toList();
    }

    // Difficulty filter
    if (_filterDifficulty != null) {
      filtered =
          filtered.where((oq) => oq.difficulty == _filterDifficulty).toList();
    }

    return filtered;
  }

  List<String> _getUniqueSubjects(List<OralQuestionEntity> items) {
    final subjects = items
        .where((oq) => oq.subjectId != null)
        .map((oq) => oq.subjectId!)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  Future<void> _handleRefresh() async {
    await ref.read(oralQuestionProvider.notifier).loadOralQuestions();
    _listenForMessages();
  }

  void _handleDelete(String id) {
    ref.read(oralQuestionProvider.notifier).deleteOralQuestions(id);
    _listenForMessages();
  }

  void _handleExport(OralQuestionEntity oralQuestion) {
    _showSnackBar('Exporting oral questions...', isError: false);
  }

  void _navigateToGenerator() {
    context.push('/workspace/oral-questions/generator');
  }

  void _navigateToDetail(String id) {
    final oq = ref.read(oralQuestionProvider).oralQuestions.firstWhere(
          (o) => o.id == id,
        );
    ref.read(oralQuestionProvider.notifier).setCurrentOralQuestion(oq);
    context.push('/workspace/oral-questions/generator');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oralQuestionProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Oral Questions',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _navigateToGenerator,
            tooltip: 'New Oral Questions',
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.oralQuestions.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Oral Questions',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(OralQuestionState state) {
    final filtered = _applyLocalFilters(state.oralQuestions);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips(state.oralQuestions)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(child: _buildResultsCount(filtered.length)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Oral question list
          if (filtered.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildOralQuestionCard(filtered[index]),
                  ),
                  childCount: filtered.length,
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
          hintText: 'Search oral questions...',
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

  // ─── Filter Chips ────────────────────────────────────────────────────

  Widget _buildFilterChips(List<OralQuestionEntity> items) {
    final subjects = _getUniqueSubjects(items);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: [
          // Subject filter
          if (subjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: _buildFilterDropdown<String>(
                label: 'Subject',
                value: _filterSubject,
                items: subjects,
                itemLabel: (s) => s,
                onChanged: (v) => setState(() => _filterSubject = v),
              ),
            ),

          // Difficulty filter
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: _buildFilterDropdown<StudentLevel>(
              label: 'Difficulty',
              value: _filterDifficulty,
              items: StudentLevel.values,
              itemLabel: (l) => l.label,
              onChanged: (v) => setState(() => _filterDifficulty = v),
            ),
          ),

          // Clear all filters
          if (_filterSubject != null || _filterDifficulty != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: ActionChip(
                label: const Text('Clear'),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _filterSubject = null;
                    _filterDifficulty = null;
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
        '$count oral question set${count != 1 ? 's' : ''}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Oral Question Card ──────────────────────────────────────────────

  Widget _buildOralQuestionCard(OralQuestionEntity oq) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () => _navigateToDetail(oq.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + published badge
          Row(
            children: [
              Expanded(
                child: Text(
                  oq.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (oq.isPublished)
                Container(
                  margin: const EdgeInsets.only(left: Spacings.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded, size: 12, color: cs.primary),
                      const SizedBox(width: 2),
                      Text(
                        'Published',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (oq.isAiGenerated && !oq.isPublished)
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
                      Icon(Icons.auto_awesome,
                          size: 12, color: cs.onTertiaryContainer,),
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
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Stats
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.xs,
            children: [
              _buildChip(
                icon: Icons.help_outline_rounded,
                label: '${oq.questions.length} questions',
                color: cs.primary,
                isDark: isDark,
              ),
              _buildChip(
                icon: Icons.star_outline_rounded,
                label: '${oq.totalMarks.toInt()} marks',
                color: cs.tertiary,
                isDark: isDark,
              ),
              if (oq.estimatedDurationMinutes != null)
                _buildChip(
                  icon: Icons.timer_outlined,
                  label: '${oq.estimatedDurationMinutes} min',
                  color: cs.secondary,
                  isDark: isDark,
                ),
              if (oq.subjectId != null)
                _buildChip(
                  icon: Icons.book_outlined,
                  label: oq.subjectId!,
                  color: cs.primary,
                  isDark: isDark,
                ),
              if (oq.difficulty != null)
                _buildChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: oq.difficulty!.label,
                  color: cs.secondary,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Created date
          Text(
            'Created ${_formatDate(oq.createdAt)}',
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
                onPressed: () => _navigateToDetail(oq.id),
                variant: AppButtonVariant.text,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(oq),
                variant: AppButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              AppButton(
                label: 'Export',
                onPressed: () => _handleExport(oq),
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
                  AppLoadingShimmer.box(width: 200, height: 16),
                  Spacer(),
                  AppLoadingShimmer.box(width: 60, height: 20),
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
                  SizedBox(width: Spacings.sm),
                  AppLoadingShimmer.box(width: 70, height: 22),
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
      icon: Icons.quiz_outlined,
      title: 'No Oral Questions Yet',
      subtitle:
          'Create your first set of oral questions with AI assistance or start from scratch.',
      actionLabel: 'Create Oral Questions',
      onAction: _navigateToGenerator,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(oralQuestionProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────

  void _confirmDelete(OralQuestionEntity oq) {
    final cs = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Oral Questions'),
        content: Text(
          'Are you sure you want to delete "${oq.title}"? This action cannot be undone.',
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
              _handleDelete(oq.id);
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
