import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// STUDENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's student list page with search, class filter, active/graduated
/// toggle, pull-to-refresh, pagination, and responsive layout.
class StudentListPage extends ConsumerStatefulWidget {
  const StudentListPage({super.key});

  @override
  ConsumerState<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends ConsumerState<StudentListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String? _selectedClassId;
  bool _showGraduated = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(studentListProvider.notifier).loadStudents('current-school');
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(studentListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<StudentProfileEntity> _applyFilters(List<StudentProfileEntity> students) {
    var filtered = students;
    if (!_showGraduated) {
      filtered = filtered.where((s) => s.isActive && !s.isGraduated).toList();
    }
    return filtered;
  }

  Color _statusColor(StudentProfileEntity student) {
    if (student.isGraduated) return AppColors.info;
    if (!student.isActive) return AppColors.warning;
    return AppColors.success;
  }

  String _statusLabel(StudentProfileEntity student) {
    if (student.isGraduated) return 'Graduated';
    if (!student.isActive) return 'Inactive';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(studentListProvider);
    final classState = ref.watch(classListProvider);
    final filteredStudents = _applyFilters(state.students);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Students',
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
                ref.read(studentListProvider.notifier).loadStudents('current-school');
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search students',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(context, classState.classes),
            tooltip: 'Filter students',
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
                    hint: 'Search by name or admission number...',
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        ref.read(studentListProvider.notifier).loadStudents('current-school');
                      } else {
                        ref.read(studentListProvider.notifier).searchStudents(query);
                      }
                    },
                    onSubmitted: (query) {
                      ref.read(studentListProvider.notifier).searchStudents(query);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentListProvider.notifier).refresh(),
        child: _buildBody(context, state, filteredStudents),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Navigate to student form
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Student'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    StudentListState state,
    List<StudentProfileEntity> students,
  ) {
    if (state.isLoading && students.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && students.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(studentListProvider.notifier).loadStudents('current-school'),
      );
    }

    if (students.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          AppEmptyState(
            icon: Icons.school_outlined,
            title: _isSearchMode ? 'No Matching Students' : 'No Students Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Add the first student to get started.',
            actionLabel: _isSearchMode ? null : 'Add Student',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to student form
                  },
          ),
        ],
      );
    }

    return _buildStudentList(context, students, state);
  }

  Widget _buildStudentList(
    BuildContext context,
    List<StudentProfileEntity> students,
    StudentListState state,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: students.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == students.length) {
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
          child: _StudentCard(
            student: students[index],
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            onTap: () {
              // Navigate to student detail
            },
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    List<ClassEntity> classes,
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
                'Filter Students',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Class filter dropdown
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Classes'),
                  ),
                  ...classes.map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedClassId = value);
                  setModalState(() => _selectedClassId = value);
                  ref.read(studentListProvider.notifier).filterByClass(value);
                },
              ),
              const SizedBox(height: Spacings.lg),
              // Active / Graduated toggle
              SwitchListTile(
                title: const Text('Show Graduated'),
                subtitle: const Text('Include graduated students'),
                value: _showGraduated,
                onChanged: (value) {
                  setState(() => _showGraduated = value);
                  setModalState(() => _showGraduated = value);
                },
                activeColor: cs.primary,
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
// STUDENT CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.statusColor,
    required this.statusLabel,
    this.onTap,
  });

  final StudentProfileEntity student;
  final Color Function(StudentProfileEntity) statusColor;
  final String Function(StudentProfileEntity) statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = statusColor(student);

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
            child: student.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    child: Image.network(
                      student.avatarUrl!,
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
                  student.fullName ?? 'Unknown Student',
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
                        student.admissionNumber,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    if (student.currentClassName != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Icon(
                        Icons.class_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        student.currentClassName!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
            ),
            child: Text(
              statusLabel(student),
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
