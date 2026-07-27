import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/school_provider.dart';
import '../../providers/teacher_provider.dart';



// ═══════════════════════════════════════════════════════════════════════
// TEACHER LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's teacher list page with search, department filter,
/// pull-to-refresh, pagination, and responsive layout.
class TeacherListPage extends ConsumerStatefulWidget {
  const TeacherListPage({super.key});

  @override
  ConsumerState<TeacherListPage> createState() => _TeacherListPageState();
}

class _TeacherListPageState extends ConsumerState<TeacherListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String? _departmentFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(teacherListProvider.notifier).loadTeachers('current-school');
      ref.read(schoolDetailProvider.notifier).loadSchool('current-school');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(teacherListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _employmentTypeColor(EmploymentType type) {
    switch (type) {
      case EmploymentType.fullTime:
        return AppColors.success;
      case EmploymentType.partTime:
        return AppColors.info;
      case EmploymentType.contract:
        return AppColors.warning;
      case EmploymentType.volunteer:
        return AppColors.info;
      case EmploymentType.intern:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(teacherListProvider);
    final schoolState = ref.watch(schoolDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Teachers',
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
                ref.read(teacherListProvider.notifier).loadTeachers('current-school');
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search teachers',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(
              context,
              schoolState.departments,
            ),
            tooltip: 'Filter teachers',
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
                    hint: 'Search by name or employee ID...',
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        ref.read(teacherListProvider.notifier).loadTeachers('current-school');
                      } else {
                        ref.read(teacherListProvider.notifier).searchTeachers(query);
                      }
                    },
                    onSubmitted: (query) {
                      ref.read(teacherListProvider.notifier).searchTeachers(query);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(teacherListProvider.notifier).refresh(),
        child: _buildBody(context, state, state.teachers),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Navigate to teacher form
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Teacher'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TeacherListState state,
    List<TeacherProfileEntity> teachers,
  ) {
    if (state.isLoading && teachers.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && teachers.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(teacherListProvider.notifier).loadTeachers('current-school'),
      );
    }

    if (teachers.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          AppEmptyState(
            icon: Icons.person_outline_rounded,
            title: _isSearchMode ? 'No Matching Teachers' : 'No Teachers Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Add the first teacher to get started.',
            actionLabel: _isSearchMode ? null : 'Add Teacher',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to teacher form
                  },
          ),
        ],
      );
    }

    return _buildTeacherList(context, teachers, state);
  }

  Widget _buildTeacherList(
    BuildContext context,
    List<TeacherProfileEntity> teachers,
    TeacherListState state,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: teachers.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == teachers.length) {
          return Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Center(
              child: state.isLoading
                  ? const AppLoadingSpinner(size: AppLoadingSpinnerSize.small)
                  : const SizedBox.shrink(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _TeacherCard(
            teacher: teachers[index],
            employmentTypeColor: _employmentTypeColor,
            onTap: () {
              // Navigate to teacher detail
            },
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    List<DepartmentEntity> departments,
  ) {
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
                'Filter Teachers',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              DropdownButtonFormField<String>(
                initialValue: _departmentFilter,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...departments.map((d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.name),
                      ),),
                ],
                onChanged: (value) {
                  setState(() => _departmentFilter = value);
                  setModalState(() => _departmentFilter = value);
                  ref.read(teacherListProvider.notifier).filterByDepartment(value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply',
                  onPressed: () => Navigator.pop(ctx),
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
// TEACHER CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.teacher,
    required this.employmentTypeColor,
    this.onTap,
  });

  final TeacherProfileEntity teacher;
  final Color Function(EmploymentType) employmentTypeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final empColor = employmentTypeColor(teacher.employmentType);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: teacher.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    child: Image.network(
                      teacher.avatarUrl!,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: cs.primary,
                      ),
                    ),
                  )
                : Icon(Icons.person_rounded, color: cs.primary),
          ),
          const SizedBox(width: Spacings.md),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.fullName ?? 'Unknown Teacher',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        teacher.employeeId,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    if (teacher.departmentName != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Icon(
                        Icons.account_tree_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          teacher.departmentName!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (teacher.qualification != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Icon(
                        Icons.school_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          teacher.qualification!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Employment type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: empColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
            ),
            child: Text(
              teacher.employmentType.label,
              style: tt.labelSmall?.copyWith(
                color: empColor,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
