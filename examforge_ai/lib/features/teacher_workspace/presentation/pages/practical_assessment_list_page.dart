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
import '../providers/practical_assessment_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRACTICAL ASSESSMENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page showing all practical assessments with search, filter, and CRUD actions.
class PracticalAssessmentListPage extends ConsumerStatefulWidget {
  const PracticalAssessmentListPage({super.key});

  @override
  ConsumerState<PracticalAssessmentListPage> createState() =>
      _PracticalAssessmentListPageState();
}

class _PracticalAssessmentListPageState
    extends ConsumerState<PracticalAssessmentListPage> {
  final _searchCtrl = TextEditingController();
  String? _filterSubject;
  StudentLevel? _filterDifficulty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practicalAssessmentProvider.notifier).loadPracticalAssessments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(practicalAssessmentProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(practicalAssessmentProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(practicalAssessmentProvider.notifier).clearError();
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

  List<PracticalAssessmentEntity> _applyLocalFilters(
    List<PracticalAssessmentEntity> items,
  ) {
    var filtered = items;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.title.toLowerCase().contains(query) ||
              (a.description?.toLowerCase().contains(query) ?? false) ||
              (a.topic?.toLowerCase().contains(query) ?? false),)
          .toList();
    }

    // Subject filter
    if (_filterSubject != null) {
      filtered =
          filtered.where((a) => a.subjectId == _filterSubject).toList();
    }

    // Difficulty filter
    if (_filterDifficulty != null) {
      filtered =
          filtered.where((a) => a.difficulty == _filterDifficulty).toList();
    }

    return filtered;
  }

  List<String> _getUniqueSubjects(List<PracticalAssessmentEntity> items) {
    final subjects = items
        .where((a) => a.subjectId != null)
        .map((a) => a.subjectId!)
        .toSet()
        .toList()
      ..sort();
    return subjects;
  }

  Future<void> _handleRefresh() async {
    await ref.read(practicalAssessmentProvider.notifier).loadPracticalAssessments();
    _listenForMessages();
  }

  void _handleDelete(String id) {
    ref.read(practicalAssessmentProvider.notifier).deletePracticalAssessment(id);
    _listenForMessages();
  }

  void _handleExport(PracticalAssessmentEntity assessment) {
    _showSnackBar('Exporting practical assessment...', isError: false);
  }

  void _navigateToGenerator() {
    context.push('/workspace/practical-assessments/generator');
  }

  void _navigateToDetail(String id) {
    final assessment =
        ref.read(practicalAssessmentProvider).assessments.firstWhere(
              (a) => a.id == id,
            );
    ref.read(practicalAssessmentProvider.notifier).setCurrentAssessment(assessment);
    context.push('/workspace/practical-assessments/generator');
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practicalAssessmentProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Practical Assessments',
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _navigateToGenerator,
            tooltip: 'New Assessment',
            variant: AppIconButtonVariant.filled,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingShimmer()
          : state.error != null && state.assessments.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Assessment',
        icon: Icons.add_rounded,
        onPressed: _navigateToGenerator,
        extended: true,
      ),
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(PracticalAssessmentState state) {
    final filtered = _applyLocalFilters(state.assessments);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: [
          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips(state.assessments)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.md)),

          // Results count
          SliverToBoxAdapter(child: _buildResultsCount(filtered.length)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacings.sm)),

          // Assessment list
          if (filtered.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: Spacings.paddingScreen,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _buildAssessmentCard(filtered[index]),
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
          hintText: 'Search practical assessments...',
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

  Widget _buildFilterChips(List<PracticalAssessmentEntity> items) {
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
        '$count assessment${count != 1 ? 's' : ''}',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Assessment Card ─────────────────────────────────────────────────

  Widget _buildAssessmentCard(PracticalAssessmentEntity assessment) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () => _navigateToDetail(assessment.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + published badge
          Row(
            children: [
              Expanded(
                child: Text(
                  assessment.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (assessment.isPublished)
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
              if (assessment.isAiGenerated && !assessment.isPublished)
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

          // Description
          if (assessment.description != null) ...[
            Text(
              assessment.description!,
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
                icon: Icons.flag_outlined,
                label: '${assessment.objectives.length} objectives',
                color: cs.primary,
                isDark: isDark,
              ),
              _buildChip(
                icon: Icons.inventory_2_outlined,
                label: '${assessment.materialsNeeded.length} materials',
                color: cs.tertiary,
                isDark: isDark,
              ),
              if (assessment.estimatedDurationMinutes != null)
                _buildChip(
                  icon: Icons.timer_outlined,
                  label: '${assessment.estimatedDurationMinutes} min',
                  color: cs.secondary,
                  isDark: isDark,
                ),
              if (assessment.subjectId != null)
                _buildChip(
                  icon: Icons.book_outlined,
                  label: assessment.subjectId!,
                  color: cs.primary,
                  isDark: isDark,
                ),
              if (assessment.difficulty != null)
                _buildChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: assessment.difficulty!.label,
                  color: cs.secondary,
                  isDark: isDark,
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // Created date
          Text(
            'Created ${_formatDate(assessment.createdAt)}',
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
                onPressed: () => _navigateToDetail(assessment.id),
                variant: AppButtonVariant.text,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.xs),
              AppButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(assessment),
                variant: AppButtonVariant.text,
                icon: Icons.delete_outline_rounded,
                size: AppButtonSize.small,
              ),
              const Spacer(),
              AppButton(
                label: 'Export',
                onPressed: () => _handleExport(assessment),
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
      icon: Icons.science_outlined,
      title: 'No Practical Assessments Yet',
      subtitle:
          'Create your first practical assessment with AI assistance or start from scratch.',
      actionLabel: 'Create Assessment',
      onAction: _navigateToGenerator,
    );
  }

  Widget _buildErrorState() {
    return AppErrorState.genericError(
      message: ref.read(practicalAssessmentProvider).error,
      onRetry: _handleRefresh,
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────

  void _confirmDelete(PracticalAssessmentEntity assessment) {
    final cs = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Practical Assessment'),
        content: Text(
          'Are you sure you want to delete "${assessment.title}"? This action cannot be undone.',
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
              _handleDelete(assessment.id);
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
