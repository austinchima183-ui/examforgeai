import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/subject_provider.dart';
import 'subject_form_page.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SUBJECT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's subject list page with search, category filter,
/// and FAB to create a new subject.
class SubjectListPage extends ConsumerStatefulWidget {
  const SubjectListPage({super.key});

  @override
  ConsumerState<SubjectListPage> createState() => _SubjectListPageState();
}

class _SubjectListPageState extends ConsumerState<SubjectListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String? _categoryFilter;

  static const _categories = [
    'Science',
    'Arts',
    'Commercial',
    'Languages',
    'Mathematics',
    'Technology',
    'Social Studies',
    'Religious Studies',
    'Physical Education',
    'Vocational',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(subjectListProvider.notifier).loadSubjects(
            schoolId: 'current-school',
            category: _categoryFilter,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Pagination
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SubjectEntity> _applySearch(List<SubjectEntity> subjects) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return subjects;
    return subjects.where((s) {
      final nameMatch = s.name.toLowerCase().contains(query);
      final codeMatch = s.code.toLowerCase().contains(query);
      final categoryMatch =
          s.category?.toLowerCase().contains(query) ?? false;
      return nameMatch || codeMatch || categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(subjectListProvider);
    final filteredSubjects = _applySearch(state.subjects);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Subjects',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() => _isSearchMode = !_isSearchMode);
              if (!_isSearchMode) {
                _searchController.clear();
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search subjects',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter subjects',
          ),
        ],
        bottom: _isSearchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search by name, code, category...',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(subjectListProvider.notifier).loadSubjects(
              schoolId: 'current-school',
              category: _categoryFilter,
            ),
        child: _buildBody(context, state, filteredSubjects),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subject'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }

  // ─── Body Builder ────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    SubjectListState state,
    List<SubjectEntity> subjects,
  ) {
    if (state.isLoading && subjects.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && subjects.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(subjectListProvider.notifier).loadSubjects(
              schoolId: 'current-school',
            ),
      );
    }

    if (subjects.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.menu_book_outlined,
            title:
                _isSearchMode ? 'No Matching Subjects' : 'No Subjects Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Create the first subject to get started.',
            actionLabel: _isSearchMode ? null : 'Add Subject',
            onAction:
                _isSearchMode ? null : () => _navigateToForm(context),
          ),
        ],
      );
    }

    return _buildSubjectList(context, subjects);
  }

  // ─── Subject List ────────────────────────────────────────────────────

  Widget _buildSubjectList(
    BuildContext context,
    List<SubjectEntity> subjects,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _SubjectCard(
            subject: subjects[index],
            onTap: () => _showEditDialog(context, subjects[index]),
          ),
        );
      },
    );
  }

  // ─── Navigation ──────────────────────────────────────────────────────

  void _navigateToForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SubjectFormPage(),
      ),
    );
  }

  // ─── Edit Subject Dialog ─────────────────────────────────────────────

  void _showEditDialog(BuildContext context, SubjectEntity subject) {
    final cs = context.colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: Spacings.xl,
          right: Spacings.xl,
          top: Spacings.xl,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacings.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
              ),
            ),
            const SizedBox(height: Spacings.lg),
            // Subject info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                      Text(
                        '${subject.code} · ${subject.category ?? "No category"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xl),
            // Quick stats
            Row(
              children: [
                _StatChip(
                  label:
                      '${subject.assignedTeacherIds.length} teacher${subject.assignedTeacherIds.length != 1 ? 's' : ''}',
                  icon: Icons.person_outline_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(width: Spacings.sm),
                _StatChip(
                  label:
                      '${subject.assignedClassIds.length} class${subject.assignedClassIds.length != 1 ? 'es' : ''}',
                  icon: Icons.class_outlined,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: Spacings.xl),
            // Actions
            ListTile(
              leading: Icon(Icons.edit_rounded, color: cs.primary),
              title: const Text('Edit Subject'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubjectFormPage(subject: subject),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person_add_rounded, color: cs.primary),
              title: const Text('Assign Teacher'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            if (!subject.isActive)
              ListTile(
                leading: Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                title: const Text('Reactivate Subject'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: const Text('Delete Subject'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, subject);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm Delete ──────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, SubjectEntity subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            onPressed: () {
              Navigator.pop(ctx);
              // Delete subject
            },
            variant: AppButtonVariant.elevated,
          ),
        ],
      ),
    );
  }

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Subjects',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              DropdownButtonFormField<String>(
                value: _categoryFilter,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ..._categories.map(
                    (cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _categoryFilter = value);
                  setModalState(() => _categoryFilter = value);
                  ref.read(subjectListProvider.notifier).setCategoryFilter(value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply',
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(subjectListProvider.notifier).loadSubjects(
                          schoolId: 'current-school',
                          category: _categoryFilter,
                        );
                  },
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUBJECT CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    this.onTap,
  });

  final SubjectEntity subject;
  final VoidCallback? onTap;

  Color _categoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'science':
        return const Color(0xFF22C55E);
      case 'arts':
        return const Color(0xFFEC4899);
      case 'commercial':
        return const Color(0xFFF59E0B);
      case 'languages':
        return const Color(0xFF06B6D4);
      case 'mathematics':
        return const Color(0xFF6366F1);
      case 'technology':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final catColor = _categoryColor(subject.category);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Category icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: catColor,
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    // Code badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        subject.code,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    // Category badge
                    if (subject.category != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              catColor.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius:
                              BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          subject.category!,
                          style: tt.labelSmall?.copyWith(
                            color: catColor,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Compulsory/Elective badge + teacher count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: (subject.isCompulsory
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  subject.isCompulsory ? 'Compulsory' : 'Elective',
                  style: tt.labelSmall?.copyWith(
                    color: subject.isCompulsory
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: Spacings.smIcon,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${subject.assignedTeacherIds.length}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STAT CHIP (for bottom sheet)
// ═══════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: AppTypography.wSemiBold,
                ),
          ),
        ],
      ),
    );
  }
}
