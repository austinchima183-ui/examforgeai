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
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/class_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/timetable_provider.dart';
import 'class_form_page.dart';


// ═══════════════════════════════════════════════════════════════════════
// CLASS DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detail page for a class with tabs: Students, Subjects, Timetable.
class ClassDetailPage extends ConsumerStatefulWidget {
  const ClassDetailPage({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends ConsumerState<ClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      ref.read(classDetailProvider.notifier).loadClass(widget.classId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(classDetailProvider);
    final classEntity = state.classEntity;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Class Header ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            actions: [
              if (classEntity != null)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _navigateToEdit(context, classEntity),
                  tooltip: 'Edit class',
                ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showOptionsDialog(context),
                tooltip: 'More options',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacings.xl, Spacings.xxl + 16, Spacings.xl, Spacings.md,
                    ),
                    child: classEntity == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                classEntity.name,
                                style: tt.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: AppTypography.wBold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Spacings.xs),
                              Row(
                                children: [
                                  if (classEntity.section != null) ...[
                                    _HeaderChip(
                                      icon: Icons.category_outlined,
                                      label: 'Sec ${classEntity.section}',
                                    ),
                                    const SizedBox(width: Spacings.sm),
                                  ],
                                  if (classEntity.teacherName != null) ...[
                                    _HeaderChip(
                                      icon: Icons.person_outline_rounded,
                                      label: classEntity.teacherName!,
                                    ),
                                    const SizedBox(width: Spacings.sm),
                                  ],
                                  _HeaderChip(
                                    icon: Icons.group_outlined,
                                    label:
                                        '${classEntity.studentCount} students',
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Tab Bar ──────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Students', icon: Icon(Icons.group_outlined)),
                  Tab(text: 'Subjects', icon: Icon(Icons.menu_book_outlined)),
                  Tab(text: 'Timetable', icon: Icon(Icons.schedule_outlined)),
                ],
              ),
            ),
          ),

          // ─── Tab Content ──────────────────────────────────────────────
          SliverFillRemaining(
            child: state.isLoading
                ? const Center(
                    child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                  )
                : state.error != null
                    ? AppErrorState.genericError(
                        message: state.error,
                        onRetry: () => ref
                            .read(classDetailProvider.notifier)
                            .loadClass(widget.classId),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _StudentsTab(classId: widget.classId),
                          _SubjectsTab(
                            classId: widget.classId,
                            subjects: state.subjects,
                          ),
                          _TimetableTab(classId: widget.classId),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, ClassEntity classEntity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassFormPage(classEntity: classEntity),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final cs = context.colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person_add_rounded, color: cs.primary),
                title: const Text('Assign Students'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAssignStudentsDialog(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.book_outlined, color: cs.primary),
                title: const Text('Add Subject'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddSubjectDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: AppColors.warning),
                title: const Text('Deactivate Class'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignStudentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Students'),
        content: const Text(
          'Select students to assign to this class. '
          'This feature will be connected to the student picker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Assign',
            onPressed: () => Navigator.pop(ctx),
            variant: AppButtonVariant.elevated,
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: const Text(
          'Select a subject to add to this class. '
          'This feature will be connected to the subject picker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Add',
            onPressed: () => Navigator.pop(ctx),
            variant: AppButtonVariant.elevated,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HEADER CHIP
// ═══════════════════════════════════════════════════════════════════════

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TAB BAR DELEGATE
// ═══════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _StudentsTab extends ConsumerStatefulWidget {
  const _StudentsTab({required this.classId});

  final String classId;

  @override
  ConsumerState<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends ConsumerState<_StudentsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studentListProvider.notifier).loadStudents('current-school');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final studentState = ref.watch(studentListProvider);
    final students = studentState.students
        .where((s) => s.currentClassId == widget.classId)
        .toList();

    if (students.isEmpty) {
      return AppEmptyState(
        icon: Icons.group_outlined,
        title: 'No Students',
        subtitle: 'Assign students to this class.',
        actionLabel: 'Assign Students',
        onAction: () {
          // Open assign dialog
        },
      );
    }

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.sm,
          ),
          child: Row(
            children: [
              Text(
                '${students.length} student${students.length != 1 ? 's' : ''}',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Assign students
                },
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Assign'),
              ),
            ],
          ),
        ),
        // Student list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius:
                              BorderRadius.circular(Spacings.mdRadius),
                        ),
                        child: Icon(Icons.person_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName ?? 'Unknown',
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              student.admissionNumber,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: cs.error, size: 20,),
                        onPressed: () => _confirmRemoveStudent(student),
                        tooltip: 'Remove from class',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmRemoveStudent(StudentProfileEntity student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove ${student.fullName ?? "this student"} '
          'from this class?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Remove',
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(classListProvider.notifier)
                  .removeStudent(widget.classId, student.id);
            },
            variant: AppButtonVariant.elevated,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUBJECTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _SubjectsTab extends ConsumerWidget {
  const _SubjectsTab({
    required this.classId,
    required this.subjects,
  });

  final String classId;
  final List<SubjectEntity> subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    if (subjects.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No Subjects',
        subtitle: 'Add subjects to this class.',
        actionLabel: 'Add Subject',
        onAction: () {
          // Add subject dialog
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.sm,
          ),
          child: Row(
            children: [
              Text(
                '${subjects.length} subject${subjects.length != 1 ? 's' : ''}',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Add subject
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Subject'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (subject.isCompulsory
                                  ? AppColors.info
                                  : AppColors.warning)
                              .withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius:
                              BorderRadius.circular(Spacings.mdRadius),
                        ),
                        child: Icon(
                          Icons.book_outlined,
                          color: subject.isCompulsory
                              ? AppColors.info
                              : AppColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  subject.name,
                                  style: tt.bodyMedium?.copyWith(
                                    fontWeight: AppTypography.wSemiBold,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(width: Spacings.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacings.sm,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (subject.isCompulsory
                                            ? AppColors.success
                                            : AppColors.warning)
                                        .withValues(alpha: isDark ? 0.20 : 0.12),
                                    borderRadius: BorderRadius.circular(
                                        Spacings.fullRadius,),
                                  ),
                                  child: Text(
                                    subject.isCompulsory
                                        ? 'Compulsory'
                                        : 'Elective',
                                    style: tt.labelSmall?.copyWith(
                                      color: subject.isCompulsory
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontWeight: AppTypography.wSemiBold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subject.code,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: cs.error, size: 20,),
                        onPressed: () {
                          // Remove subject
                        },
                        tooltip: 'Remove subject',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE TAB
// ═══════════════════════════════════════════════════════════════════════

class _TimetableTab extends ConsumerWidget {
  const _TimetableTab({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final timetableState = ref.watch(timetableDetailProvider);

    if (timetableState.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.medium),
      );
    }

    if (timetableState.timetable == null) {
      return AppEmptyState(
        icon: Icons.schedule_outlined,
        title: 'No Timetable',
        subtitle: 'Create a timetable for this class.',
        actionLabel: 'Create Timetable',
        onAction: () {
          // Navigate to timetable builder
        },
      );
    }

    final timetable = timetableState.timetable!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.sm,
          ),
          child: Row(
            children: [
              Text(
                timetable.name,
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (timetable.isPublished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    'Published',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: TimetableWeeklyView(
            slots: timetable.slots,
            isReadOnly: true,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE WEEKLY VIEW (Simple inline version for detail tab)
// ═══════════════════════════════════════════════════════════════════════

class TimetableWeeklyView extends StatelessWidget {
  const TimetableWeeklyView({
    super.key,
    required this.slots,
    this.isReadOnly = false,
  });

  final List<TimetableSlotEntity> slots;
  final bool isReadOnly;

  static const _days = DayOfWeek.values;
  static const _periods = [1, 2, 3, 4, 5, 6, 7, 8];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Table(
            border: TableBorder.all(
              color: cs.outlineVariant,
              width: 0.5,
            ),
            columnWidths: {
              0: const FixedColumnWidth(72),
              for (var i = 1; i <= _days.length; i++)
                i: const FixedColumnWidth(100),
            },
            children: [
              // Header row
              TableRow(
                children: [
                  _buildHeaderCell(context, 'Period'),
                  ..._days.map((d) => _buildHeaderCell(
                        context,
                        d.label.substring(0, 3),
                      ),),
                ],
              ),
              // Period rows
              ..._periods.map((period) => TableRow(
                    children: [
                      _buildPeriodCell(context, period),
                      ..._days.map((day) {
                        final slot = slots.where(
                          (s) =>
                              s.dayOfWeek == day &&
                              s.periodNumber == period,
                        );
                        if (slot.isEmpty) {
                          return _buildEmptySlotCell(context);
                        }
                        return _buildSlotCell(context, slot.first);
                      }),
                    ],
                  ),),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacings.sm),
      color: context.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          text,
          style: tt.labelSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCell(BuildContext context, int period) {
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacings.sm),
      color: context.colorScheme.surfaceContainerLow,
      child: Center(
        child: Text(
          'P$period',
          style: tt.labelSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotCell(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacings.xs),
      color: context.colorScheme.surface,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildSlotCell(BuildContext context, TimetableSlotEntity slot) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (slot.isBreak) {
      return Container(
        padding: const EdgeInsets.all(Spacings.xs),
        color: AppColors.warning.withValues(alpha: 0.12),
        child: Center(
          child: Text(
            slot.breakLabel ?? 'Break',
            style: tt.labelSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: AppTypography.wSemiBold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacings.xs),
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            slot.subjectName ?? '—',
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (slot.teacherName != null)
            Text(
              slot.teacherName!,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
