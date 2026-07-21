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
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/student_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detailed student profile view with tabbed sections: Info, Parents,
/// Promotion History, and Documents.
class StudentDetailPage extends ConsumerStatefulWidget {
  const StudentDetailPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _DetailTab(label: 'Info', icon: Icons.info_outline_rounded),
    _DetailTab(label: 'Parents', icon: Icons.family_restroom_rounded),
    _DetailTab(label: 'Promotions', icon: Icons.trending_up_rounded),
    _DetailTab(label: 'Documents', icon: Icons.folder_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    Future.microtask(() {
      ref.read(studentDetailProvider.notifier).loadStudent(widget.userId);
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
    final state = ref.watch(studentDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.student?.fullName ?? 'Student Details',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to edit student form
            },
            tooltip: 'Edit student',
          ),
          IconButton(
            icon: Icon(Icons.trending_up_rounded, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to promote student
            },
            tooltip: 'Promote student',
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
                      .read(studentDetailProvider.notifier)
                      .loadStudent(widget.userId),
                )
              : state.student == null
                  ? const AppEmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Student Not Found',
                      subtitle: 'The requested student profile could not be loaded.',
                    )
                  : Column(
                      children: [
                        _ProfileHeader(student: state.student!),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _InfoTab(student: state.student!),
                              _ParentsTab(
                                parentLinks: state.parentLinks,
                                onAddParent: () => _showLinkParentDialog(),
                                onUnlinkParent: (linkId) =>
                                    _showUnlinkConfirmation(linkId),
                              ),
                              _PromotionHistoryTab(
                                history: state.promotionHistory,
                              ),
                              _DocumentsTab(student: state.student!),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _showLinkParentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Parent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Parent ID or Email',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.people_outline_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                DropdownMenuItem(value: 'sponsor', child: Text('Sponsor')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: Spacings.md),
            SwitchListTile(
              title: const Text('Primary Contact'),
              value: false,
              onChanged: (_) {},
              activeColor: cs.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call link parent
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkConfirmation(String linkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Parent'),
        content: const Text(
          'Are you sure you want to unlink this parent from the student? '
          'This action can be reversed by linking them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(studentDetailProvider.notifier).unlinkParent(
                    linkId,
                    state.student!.userId,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROFILE HEADER
// ═══════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final StudentProfileEntity student;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = student.isGraduated
        ? AppColors.info
        : student.isActive
            ? AppColors.success
            : AppColors.warning;
    final statusLabel = student.isGraduated
        ? 'Graduated'
        : student.isActive
            ? 'Active'
            : 'Inactive';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacings.xl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withOpacity(0.5),
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
              color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: student.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      student.avatarUrl!,
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
          // Name, admission number, class, status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName ?? 'Unknown Student',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Text(
                      student.admissionNumber,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                    if (student.currentClassName != null) ...[
                      const SizedBox(width: Spacings.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(isDark ? 0.20 : 0.08),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          student.currentClassName!,
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: Spacings.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        statusLabel,
                        style: tt.labelSmall?.copyWith(
                          color: statusColor,
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
}

// ═══════════════════════════════════════════════════════════════════════
// INFO TAB
// ═══════════════════════════════════════════════════════════════════════

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.student});

  final StudentProfileEntity student;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Details Section
          _SectionHeader(title: 'Personal Information'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(label: 'Date of Birth', value: _formatDate(student.dateOfBirth)),
          _InfoRow(label: 'Gender', value: student.gender ?? '—'),
          _InfoRow(label: 'Religion', value: student.religion ?? '—'),
          _InfoRow(label: 'Nationality', value: student.nationality),
          _InfoRow(label: 'State of Origin', value: student.stateOfOrigin ?? '—'),
          _InfoRow(label: 'LGA', value: student.localGovernment ?? '—'),

          const SizedBox(height: Spacings.xl),

          // Medical Information Section
          _SectionHeader(title: 'Medical Information'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(label: 'Blood Group', value: student.bloodGroup ?? '—'),
          _InfoRow(label: 'Genotype', value: student.genotype ?? '—'),
          _InfoRow(label: 'Medical Conditions', value: student.medicalConditions ?? 'None'),

          const SizedBox(height: Spacings.xl),

          // Emergency Contact Section
          _SectionHeader(title: 'Emergency Contact'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(label: 'Name', value: student.emergencyContactName ?? '—'),
          _InfoRow(label: 'Phone', value: student.emergencyContactPhone ?? '—'),
          _InfoRow(label: 'Relationship', value: student.emergencyContactRelationship ?? '—'),

          const SizedBox(height: Spacings.xl),

          // Admission Information Section
          _SectionHeader(title: 'Admission Information'),
          const SizedBox(height: Spacings.sm),
          _InfoRow(label: 'Admission Number', value: student.admissionNumber),
          _InfoRow(label: 'Admission Date', value: _formatDate(student.admissionDate)),
          _InfoRow(label: 'Current Class', value: student.currentClassName ?? '—'),
          _InfoRow(label: 'Home Address', value: student.homeAddress ?? '—'),

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
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _ParentsTab extends StatelessWidget {
  const _ParentsTab({
    required this.parentLinks,
    this.onAddParent,
    this.onUnlinkParent,
  });

  final List<ParentStudentLinkEntity> parentLinks;
  final VoidCallback? onAddParent;
  final void Function(String linkId)? onUnlinkParent;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (parentLinks.isEmpty) {
      return AppEmptyState(
        icon: Icons.family_restroom_outlined,
        title: 'No Parents Linked',
        subtitle: 'Link a parent or guardian to this student.',
        actionLabel: 'Link Parent',
        onAction: onAddParent,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacings.lg,
            Spacings.lg,
            Spacings.lg,
            Spacings.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Linked Parents (${parentLinks.length})',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              AppButton(
                label: 'Link Parent',
                onPressed: onAddParent,
                variant: AppButtonVariant.tonal,
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            itemCount: parentLinks.length,
            itemBuilder: (context, index) {
              final link = parentLinks[index];
              final isDark = context.isDarkMode;

              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(isDark ? 0.20 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.info,
                          size: Spacings.mdIcon,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              link.parentName ?? 'Unknown Parent',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: Spacings.xs),
                            Row(
                              children: [
                                Text(
                                  link.relationship.toUpperCase(),
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                                if (link.isPrimaryContact) ...[
                                  const SizedBox(width: Spacings.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Spacings.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Spacings.fullRadius,
                                      ),
                                    ),
                                    child: Text(
                                      'PRIMARY',
                                      style: tt.labelSmall?.copyWith(
                                        color: AppColors.success,
                                        fontWeight: AppTypography.wBold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.link_off_rounded,
                          color: AppColors.error,
                          size: Spacings.mdIcon,
                        ),
                        onPressed: () => onUnlinkParent?.call(link.id),
                        tooltip: 'Unlink parent',
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
// PROMOTION HISTORY TAB
// ═══════════════════════════════════════════════════════════════════════

class _PromotionHistoryTab extends StatelessWidget {
  const _PromotionHistoryTab({required this.history});

  final List<PromotionHistoryEntity> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const AppEmptyState(
        icon: Icons.trending_up_outlined,
        title: 'No Promotion History',
        subtitle: 'This student has no promotion records yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final cs = context.colorScheme;
        final tt = context.textTheme;
        final isDark = context.isDarkMode;

        final statusColor = _promotionColor(entry.promotionStatus);
        final isLast = index == history.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: cs.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: Spacings.md),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.lg),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(isDark ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Spacings.fullRadius,
                                ),
                              ),
                              child: Text(
                                entry.promotionStatus.label,
                                style: tt.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (entry.sessionYear != null)
                              Text(
                                entry.sessionYear!,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: Spacings.sm),
                        Text(
                          '${entry.fromClassName ?? '—'} → ${entry.toClassName ?? '—'}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        if (entry.averageScore != null) ...[
                          const SizedBox(height: Spacings.xs),
                          Text(
                            'Average Score: ${entry.averageScore!.toStringAsFixed(1)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (entry.classTeacherComment != null) ...[
                          const SizedBox(height: Spacings.xs),
                          Text(
                            entry.classTeacherComment!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _promotionColor(PromotionStatus status) {
    switch (status) {
      case PromotionStatus.promoted:
        return AppColors.success;
      case PromotionStatus.retained:
        return AppColors.error;
      case PromotionStatus.graduated:
        return AppColors.info;
      case PromotionStatus.transferred:
        return const Color(0xFF3B82F6);
      case PromotionStatus.withdrawn:
        return AppColors.warning;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({required this.student});

  final StudentProfileEntity student;

  @override
  Widget build(BuildContext context) {
    // Placeholder for documents list
    return const AppEmptyState(
      icon: Icons.folder_open_outlined,
      title: 'No Documents',
      subtitle: 'Student documents will appear here once uploaded.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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
            width: 140,
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

class _DetailTab {
  const _DetailTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
