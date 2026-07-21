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
import '../../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/teacher_provider.dart';
import '../../../../../features/school_management/domain/entities/school_management_entities.dart';


// ═══════════════════════════════════════════════════════════════════════
// TEACHER DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detailed teacher profile view with tabbed sections: Info,
/// Assigned Subjects, Assigned Classes, and Timetable.
class TeacherDetailPage extends ConsumerStatefulWidget {
  const TeacherDetailPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends ConsumerState<TeacherDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TeacherTab(label: 'Info', icon: Icons.info_outline_rounded),
    _TeacherTab(label: 'Subjects', icon: Icons.menu_book_outlined),
    _TeacherTab(label: 'Classes', icon: Icons.class_outlined),
    _TeacherTab(label: 'Timetable', icon: Icons.schedule_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    Future.microtask(() {
      ref.read(teacherDetailProvider.notifier).loadTeacher(widget.userId);
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
    final state = ref.watch(teacherDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.teacher?.fullName ?? 'Teacher Details',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to edit teacher form
            },
            tooltip: 'Edit teacher',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          labelStyle: tt.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: tt.labelLarge,
          tabs: _tabs
              .map((tab) => Tab(
                    icon: Icon(tab.icon, size: Spacings.smIcon),
                    text: tab.label,
                  ))
              .toList(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null
              ? AppErrorState.genericError(
                  message: state.error,
                  onRetry: () => ref
                      .read(teacherDetailProvider.notifier)
                      .loadTeacher(widget.userId),
                )
              : state.teacher == null
                  ? const AppEmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Teacher Not Found',
                      subtitle:
                          'The requested teacher profile could not be loaded.',
                    )
                  : Column(
                      children: [
                        _TeacherProfileHeader(teacher: state.teacher!),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _TeacherInfoTab(teacher: state.teacher!),
                              _AssignedSubjectsTab(
                                  teacher: state.teacher!),
                              _AssignedClassesTab(teacher: state.teacher!),
                              _TimetableTab(teacher: state.teacher!),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROFILE HEADER
// ═══════════════════════════════════════════════════════════════════════

class _TeacherProfileHeader extends StatelessWidget {
  const _TeacherProfileHeader({required this.teacher});

  final TeacherProfileEntity teacher;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: teacher.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      teacher.avatarUrl!,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_rounded,
                        color: cs.primary,
                        size: Spacings.xlIcon,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    color: cs.primary,
                    size: Spacings.xlIcon,
                  ),
          ),
          const SizedBox(width: Spacings.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.fullName ?? 'Unknown Teacher',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    if (teacher.qualification != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(
                            alpha: isDark ? 0.20 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          teacher.qualification!,
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.info,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    if (teacher.departmentName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(
                            alpha: isDark ? 0.20 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          teacher.departmentName!,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _employmentTypeColor(teacher.employmentType)
                            .withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        teacher.employmentType.label,
                        style: tt.labelSmall?.copyWith(
                          color: _employmentTypeColor(teacher.employmentType),
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

// ═══════════════════════════════════════════════════════════════════════
// INFO TAB
// ═══════════════════════════════════════════════════════════════════════

class _TeacherInfoTab extends StatelessWidget {
  const _TeacherInfoTab({required this.teacher});

  final TeacherProfileEntity teacher;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Details
          _SectionTitle(title: 'Personal Information'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(label: 'Employee ID', value: teacher.employeeId),
          _InfoRow(
              label: 'Date of Birth', value: _formatDate(teacher.dateOfBirth)),
          _InfoRow(label: 'Gender', value: teacher.gender ?? '—'),
          _InfoRow(
              label: 'Email', value: teacher.email ?? '—'),
          _InfoRow(
              label: 'Phone', value: teacher.phone ?? '—'),

          const SizedBox(height: Spacings.xl),

          // Employment Information
          _SectionTitle(title: 'Employment Information'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(
              label: 'Qualification', value: teacher.qualification ?? '—'),
          _InfoRow(
              label: 'Specialization', value: teacher.specialization ?? '—'),
          _InfoRow(
              label: 'Department', value: teacher.departmentName ?? '—'),
          _InfoRow(
              label: 'Employment Type', value: teacher.employmentType.label),
          _InfoRow(
            label: 'Start Date',
            value: _formatDate(teacher.employmentStartDate),
          ),
          _InfoRow(
            label: 'End Date',
            value: teacher.employmentEndDate != null
                ? _formatDate(teacher.employmentEndDate)
                : '—',
          ),
          _InfoRow(
            label: 'Years of Experience',
            value: '${teacher.yearsOfExperience}',
          ),
          _InfoRow(
            label: 'Head of Department',
            value: teacher.isHeadOfDepartment ? 'Yes' : 'No',
          ),
          _InfoRow(
            label: 'Status',
            value: teacher.isActive ? 'Active' : 'Inactive',
          ),

          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, "0")}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNED SUBJECTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _AssignedSubjectsTab extends StatelessWidget {
  const _AssignedSubjectsTab({required this.teacher});

  final TeacherProfileEntity teacher;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    if (teacher.assignedSubjects.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No Subjects Assigned',
        subtitle: 'This teacher has not been assigned any subjects yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: teacher.assignedSubjects.length,
      itemBuilder: (context, index) {
        final subject = teacher.assignedSubjects[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: AppCard(
            onTap: () {
              // Navigate to subject detail
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    subject,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: Spacings.mdIcon,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNED CLASSES TAB
// ═══════════════════════════════════════════════════════════════════════

class _AssignedClassesTab extends StatelessWidget {
  const _AssignedClassesTab({required this.teacher});

  final TeacherProfileEntity teacher;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    if (teacher.assignedClasses.isEmpty) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'No Classes Assigned',
        subtitle: 'This teacher has not been assigned any classes yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: teacher.assignedClasses.length,
      itemBuilder: (context, index) {
        final className = teacher.assignedClasses[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: AppCard(
            onTap: () {
              // Navigate to class detail
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Icon(
                    Icons.class_rounded,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    className,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: Spacings.mdIcon,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE TAB
// ═══════════════════════════════════════════════════════════════════════

class _TimetableTab extends StatelessWidget {
  const _TimetableTab({required this.teacher});

  final TeacherProfileEntity teacher;

  @override
  Widget build(BuildContext context) {
    // Placeholder — actual timetable data would come from a provider
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    return ListView(
      padding: const EdgeInsets.all(Spacings.lg),
      children: days.map((day) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: Spacings.sm),
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacings.lg),
                    child: Text(
                      'No classes scheduled',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Text(
      title,
      style: tt.titleSmall?.copyWith(
        fontWeight: AppTypography.wBold,
        color: cs.primary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: tt.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherTab {
  const _TeacherTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
