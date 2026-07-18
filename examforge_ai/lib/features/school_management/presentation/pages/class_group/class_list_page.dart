import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../domain/entities/school_management_entities.dart';
import '../providers/class_provider.dart';
import '../providers/teacher_provider.dart';
import 'class_detail_page.dart';
import 'class_form_page.dart';

// ═══════════════════════════════════════════════════════════════════════
// CLASS LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's class list page with search, academic year filter,
/// grid/list toggle, pull-to-refresh, and FAB to create class.
class ClassListPage extends ConsumerStatefulWidget {
  const ClassListPage({super.key});

  @override
  ConsumerState<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends ConsumerState<ClassListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String? _academicYearFilter;
  bool _showGridView = true;

  static const _academicYears = [
    '2024/2025',
    '2023/2024',
    '2022/2023',
    '2021/2022',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(
            schoolId: 'current-school',
            academicYear: _academicYearFilter,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Pagination support – reload with next page
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ClassEntity> _applySearch(List<ClassEntity> classes) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return classes;
    return classes.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final sectionMatch = c.section?.toLowerCase().contains(query) ?? false;
      final teacherMatch =
          c.teacherName?.toLowerCase().contains(query) ?? false;
      final gradeMatch = c.gradeLevel?.toLowerCase().contains(query) ?? false;
      return nameMatch || sectionMatch || teacherMatch || gradeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(classListProvider);
    final filteredClasses = _applySearch(state.classes);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Classes',
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
            tooltip: _isSearchMode ? 'Close search' : 'Search classes',
          ),
          IconButton(
            icon: Icon(
              _showGridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () =>
                setState(() => _showGridView = !_showGridView),
            tooltip: _showGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter classes',
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
                    hint: 'Search by name, section, teacher...',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(classListProvider.notifier).loadClasses(
              schoolId: 'current-school',
              academicYear: _academicYearFilter,
            ),
        child: _buildBody(context, state, filteredClasses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Class'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }

  // ─── Body Builder ────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    ClassListState state,
    List<ClassEntity> classes,
  ) {
    if (state.isLoading && classes.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && classes.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(classListProvider.notifier).loadClasses(
              schoolId: 'current-school',
              academicYear: _academicYearFilter,
            ),
      );
    }

    if (classes.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.class_outlined,
            title: _isSearchMode ? 'No Matching Classes' : 'No Classes Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Create the first class to get started.',
            actionLabel: _isSearchMode ? null : 'Add Class',
            onAction: _isSearchMode ? null : () => _navigateToForm(context),
          ),
        ],
      );
    }

    return _showGridView
        ? _buildGridView(context, classes)
        : _buildListView(context, classes);
  }

  // ─── Grid View ───────────────────────────────────────────────────────

  Widget _buildGridView(BuildContext context, List<ClassEntity> classes) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return _ClassCard(
          classEntity: classes[index],
          onTap: () => _navigateToDetail(context, classes[index]),
        );
      },
    );
  }

  // ─── List View ───────────────────────────────────────────────────────

  Widget _buildListView(BuildContext context, List<ClassEntity> classes) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _ClassListTile(
            classEntity: classes[index],
            onTap: () => _navigateToDetail(context, classes[index]),
          ),
        );
      },
    );
  }

  // ─── Navigation ──────────────────────────────────────────────────────

  void _navigateToDetail(BuildContext context, ClassEntity classEntity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassDetailPage(classId: classEntity.id),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ClassFormPage(),
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
                'Filter Classes',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              DropdownButtonFormField<String>(
                value: _academicYearFilter,
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Years'),
                  ),
                  ..._academicYears.map(
                    (year) => DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _academicYearFilter = value);
                  setModalState(() => _academicYearFilter = value);
                  ref.read(classListProvider.notifier).setAcademicYearFilter(value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply',
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(classListProvider.notifier).loadClasses(
                          schoolId: 'current-school',
                          academicYear: _academicYearFilter,
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
// CLASS GRID CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classEntity,
    this.onTap,
  });

  final ClassEntity classEntity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final occupancyRate =
        classEntity.capacity > 0 ? classEntity.studentCount / classEntity.capacity : 0.0;
    final isNearFull = occupancyRate >= 0.9;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with name + status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.mdRadius),
                ),
                child: Icon(Icons.class_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classEntity.name,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classEntity.section != null)
                      Text(
                        'Section ${classEntity.section}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Active status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (classEntity.isActive ? AppColors.success : AppColors.warning)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  classEntity.isActive ? 'Active' : 'Inactive',
                  style: tt.labelSmall?.copyWith(
                    color: classEntity.isActive ? AppColors.success : AppColors.warning,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // Grade level
          if (classEntity.gradeLevel != null) ...[
            Row(
              children: [
                Icon(Icons.stairs_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Grade ${classEntity.gradeLevel}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xs),
          ],
          // Teacher
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Expanded(
                child: Text(
                  classEntity.teacherName ?? 'No teacher assigned',
                  style: tt.bodySmall?.copyWith(
                    color: classEntity.teacherName != null
                        ? cs.onSurfaceVariant
                        : cs.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),
          // Student count / capacity with progress bar
          Row(
            children: [
              Icon(Icons.group_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${classEntity.studentCount}/${classEntity.capacity}',
                style: tt.bodySmall?.copyWith(
                  color: isNearFull ? AppColors.warning : cs.onSurfaceVariant,
                  fontWeight: isNearFull ? AppTypography.wSemiBold : AppTypography.wRegular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          // Occupancy progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
            child: LinearProgressIndicator(
              value: occupancyRate.clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isNearFull ? AppColors.warning : cs.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CLASS LIST TILE WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ClassListTile extends StatelessWidget {
  const _ClassListTile({
    required this.classEntity,
    this.onTap,
  });

  final ClassEntity classEntity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(Icons.class_rounded, color: cs.primary),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      classEntity.name,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (classEntity.section != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer,
                          borderRadius:
                              BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          'Sec ${classEntity.section}',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onTertiaryContainer,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    if (classEntity.gradeLevel != null) ...[
                      Icon(Icons.stairs_outlined,
                          size: Spacings.smIcon, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        'Grade ${classEntity.gradeLevel}',
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    Icon(Icons.person_outline_rounded,
                        size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        classEntity.teacherName ?? 'Unassigned',
                        style: tt.bodySmall?.copyWith(
                          color: classEntity.teacherName != null
                              ? cs.onSurfaceVariant
                              : cs.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Student count + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '${classEntity.studentCount}/${classEntity.capacity}',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (classEntity.isActive ? AppColors.success : AppColors.warning)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  classEntity.isActive ? 'Active' : 'Inactive',
                  style: tt.labelSmall?.copyWith(
                    color: classEntity.isActive
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
