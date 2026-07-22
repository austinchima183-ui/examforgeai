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
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../routing/route_names.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/school_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SCHOOL DETAIL PAGE (Admin)
// ═══════════════════════════════════════════════════════════════════════

/// School detail page with tab view: Overview, Branches, Departments, Settings.
/// Takes a [schoolId] parameter to load the specific school.
class SchoolDetailPage extends ConsumerStatefulWidget {
  const SchoolDetailPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends ConsumerState<SchoolDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _DetailTab(label: 'Overview', icon: Icons.dashboard_outlined),
    _DetailTab(label: 'Branches', icon: Icons.account_tree_outlined),
    _DetailTab(label: 'Departments', icon: Icons.business_outlined),
    _DetailTab(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    Future.microtask(() {
      ref.read(schoolDetailProvider.notifier).loadSchool(widget.schoolId);
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
    final state = ref.watch(schoolDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.school?.name ?? 'School Detail',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to school form for editing
              context.go(RouteNames.schoolAdminDashboard);
            },
            tooltip: 'Edit School',
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showMoreOptions(context, state.school),
            tooltip: 'More options',
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
                    icon: Icon(tab.icon, size: Spacings.mdIcon),
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
                      .read(schoolDetailProvider.notifier)
                      .loadSchool(widget.schoolId),
                )
              : state.school == null
                  ? AppEmptyState(
                      icon: Icons.school_outlined,
                      title: 'School Not Found',
                      subtitle: 'The school you are looking for does not exist.',
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(school: state.school!),
                        _BranchesTab(
                          branches: state.branches,
                          schoolId: widget.schoolId,
                        ),
                        _DepartmentsTab(
                          departments: state.departments,
                          schoolId: widget.schoolId,
                        ),
                        _SettingsTab(school: state.school!),
                      ],
                    ),
    );
  }

  void _showMoreOptions(BuildContext context, SchoolEntity? school) {
    if (school == null) return;
    final cs = context.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Spacings.lgRadius)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy_rounded, color: cs.onSurfaceVariant),
              title: const Text('Duplicate School'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.download_rounded, color: cs.onSurfaceVariant),
              title: const Text('Export Data'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading:
                  Icon(Icons.toggle_on_rounded, color: cs.onSurfaceVariant),
              title: Text(school.isActive ? 'Deactivate School' : 'Activate School'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: Text(
                'Delete School',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.school});

  final SchoolEntity school;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── School Branding Card ───────────────────────────────────
          _buildBrandingCard(context),
          const SizedBox(height: Spacings.xl),

          // ── Stats Cards ────────────────────────────────────────────
          _buildStatsRow(context),
          const SizedBox(height: Spacings.xl),

          // ── Contact Information ────────────────────────────────────
          _buildContactInfo(context),
        ],
      ),
    );
  }

  Widget _buildBrandingCard(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Row(
        children: [
          // School logo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
            child: school.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.lgRadius),
                    child: Image.network(
                      school.logoUrl!,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.school_rounded, size: 32, color: cs.primary),
                    ),
                  )
                : Icon(Icons.school_rounded, size: 32, color: cs.primary),
          ),
          const SizedBox(width: Spacings.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.name,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (school.motto != null) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '"${school.motto}"',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: Spacings.sm),
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
                        school.code,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: school.isActive
                            ? AppColors.success.withOpacity(isDark ? 0.20 : 0.12)
                            : AppColors.error.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        school.isActive ? 'Active' : 'Inactive',
                        style: tt.labelSmall?.copyWith(
                          color: school.isActive ? AppColors.success : AppColors.error,
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

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: Spacings.md,
          runSpacing: Spacings.md,
          children: [
            _StatCard(
              title: 'Students',
              value: '${school.maxStudents}',
              icon: Icons.people_outline_rounded,
              color: AppColors.info,
              width: isWide ? (constraints.maxWidth - Spacings.md * 3) / 4 : null,
            ),
            _StatCard(
              title: 'Teachers',
              value: '${school.maxTeachers}',
              icon: Icons.person_outline_rounded,
              color: AppColors.success,
              width: isWide ? (constraints.maxWidth - Spacings.md * 3) / 4 : null,
            ),
            _StatCard(
              title: 'Classes',
              value: '${school.branches.length}',
              icon: Icons.class_outlined,
              color: AppColors.warning,
              width: isWide ? (constraints.maxWidth - Spacings.md * 3) / 4 : null,
            ),
            _StatCard(
              title: 'Subjects',
              value: '--',
              icon: Icons.book_outlined,
              color: cs(context).primary,
              width: isWide ? (constraints.maxWidth - Spacings.md * 3) / 4 : null,
            ),
          ],
        );
      },
    );
  }

  ColorScheme cs(BuildContext context) => context.colorScheme;

  Widget _buildContactInfo(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: _formatAddress(school),
            iconColor: cs.primary,
          ),
          if (school.phone != null)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: school.phone!,
              iconColor: cs.primary,
            ),
          if (school.email != null)
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: school.email!,
              iconColor: cs.primary,
            ),
          if (school.website != null)
            _InfoRow(
              icon: Icons.language_rounded,
              label: 'Website',
              value: school.website!,
              iconColor: cs.primary,
            ),
          if (school.principalName != null)
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Principal',
              value: school.principalName!,
              iconColor: cs.primary,
            ),
        ],
      ),
    );
  }

  String _formatAddress(SchoolEntity school) {
    final parts = [
      school.address,
      school.city,
      school.state,
      school.country,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BRANCHES TAB
// ═══════════════════════════════════════════════════════════════════════

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab({
    required this.branches,
    required this.schoolId,
  });

  final List<SchoolBranchEntity> branches;
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

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
                'Branches (${branches.length})',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              AppButton(
                label: 'Add Branch',
                onPressed: () => _showBranchDialog(context, ref),
                variant: AppButtonVariant.tonal,
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
              ),
            ],
          ),
        ),
        Expanded(
          child: branches.isEmpty
              ? AppEmptyState(
                  icon: Icons.account_tree_outlined,
                  title: 'No Branches',
                  subtitle: 'Add a branch to organize this school.',
                  actionLabel: 'Add Branch',
                  onAction: () => _showBranchDialog(context, ref),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.md),
                      child: AppInfoCard(
                        title: branch.name,
                        subtitle: _branchSubtitle(branch),
                        icon: branch.isMainCampus
                            ? Icons.star_rounded
                            : Icons.account_tree_outlined,
                        iconColor: branch.isMainCampus
                            ? AppColors.warning
                            : cs.primary,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (branch.isMainCampus)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(context.isDarkMode ? 0.20 : 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(Spacings.fullRadius),
                                ),
                                child: Text(
                                  'Main',
                                  style: tt.labelSmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: Spacings.mdIcon,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  _showBranchDialog(context, ref, branch: branch),
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

  String _branchSubtitle(SchoolBranchEntity branch) {
    final parts = [branch.city, branch.state].whereType<String?>().where((s) => s != null && s.isNotEmpty);
    final location = parts.isNotEmpty ? ' · ${parts.join(', ')}' : '';
    final head = branch.headName != null ? 'Head: ${branch.headName}' : 'No head assigned';
    return '$head$location';
  }

  void _showBranchDialog(BuildContext context, WidgetRef ref, {SchoolBranchEntity? branch}) {
    final isEdit = branch != null;
    final nameCtrl = TextEditingController(text: branch?.name);
    final codeCtrl = TextEditingController(text: branch?.code);
    final cityCtrl = TextEditingController(text: branch?.city);
    final headCtrl = TextEditingController(text: branch?.headName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Branch' : 'Add Branch'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Branch Name', controller: nameCtrl, isRequired: true),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'Branch Code', controller: codeCtrl, isRequired: true),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'City', controller: cityCtrl),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'Head Name', controller: headCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Create or update branch via provider
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DEPARTMENTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _DepartmentsTab extends ConsumerWidget {
  const _DepartmentsTab({
    required this.departments,
    required this.schoolId,
  });

  final List<DepartmentEntity> departments;
  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

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
                'Departments (${departments.length})',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              AppButton(
                label: 'Add Department',
                onPressed: () => _showDepartmentDialog(context, ref),
                variant: AppButtonVariant.tonal,
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
              ),
            ],
          ),
        ),
        Expanded(
          child: departments.isEmpty
              ? AppEmptyState(
                  icon: Icons.business_outlined,
                  title: 'No Departments',
                  subtitle: 'Add departments to organize subjects and staff.',
                  actionLabel: 'Add Department',
                  onAction: () => _showDepartmentDialog(context, ref),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
                  itemCount: departments.length,
                  itemBuilder: (context, index) {
                    final dept = departments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.md),
                      child: AppInfoCard(
                        title: dept.name,
                        subtitle: dept.headTeacherName ?? 'No head teacher assigned',
                        icon: Icons.business_outlined,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: dept.isActive
                                    ? AppColors.success.withOpacity(context.isDarkMode ? 0.20 : 0.12)
                                    : cs.onSurface.withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(Spacings.fullRadius),
                              ),
                              child: Text(
                                dept.isActive ? 'Active' : 'Inactive',
                                style: tt.labelSmall?.copyWith(
                                  color:
                                      dept.isActive ? AppColors.success : cs.onSurfaceVariant,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: Spacings.mdIcon,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () => _showDepartmentDialog(
                                context,
                                ref,
                                department: dept,
                              ),
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

  void _showDepartmentDialog(BuildContext context, WidgetRef ref,
      {DepartmentEntity? department}) {
    final isEdit = department != null;
    final nameCtrl = TextEditingController(text: department?.name);
    final codeCtrl = TextEditingController(text: department?.code);
    final headCtrl = TextEditingController(text: department?.headTeacherName);
    final descCtrl = TextEditingController(text: department?.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Department' : 'Add Department'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Department Name', controller: nameCtrl, isRequired: true),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'Department Code', controller: codeCtrl, isRequired: true),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'Head Teacher', controller: headCtrl),
              const SizedBox(height: Spacings.md),
              AppTextField(label: 'Description', controller: descCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Create or update department via provider
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SETTINGS TAB
// ═══════════════════════════════════════════════════════════════════════

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.school});

  final SchoolEntity school;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── School Branding ────────────────────────────────────────
          Text(
            'School Branding',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  label: 'Primary Color',
                  value: school.primaryColor,
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _parseColor(school.primaryColor),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                ),
                const Divider(height: Spacings.lg),
                _SettingsRow(
                  icon: Icons.colorize_outlined,
                  label: 'Secondary Color',
                  value: school.secondaryColor,
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _parseColor(school.secondaryColor),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                  ),
                ),
                const Divider(height: Spacings.lg),
                _SettingsRow(
                  icon: Icons.format_quote_outlined,
                  label: 'Motto',
                  value: school.motto ?? 'Not set',
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ── School Limits ──────────────────────────────────────────
          Text(
            'School Limits',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.people_outline_rounded,
                  label: 'Max Students',
                  value: '${school.maxStudents}',
                ),
                const Divider(height: Spacings.lg),
                _SettingsRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Max Teachers',
                  value: '${school.maxTeachers}',
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ── Subscription ───────────────────────────────────────────
          Text(
            'Subscription',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          AppCard(
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.card_membership_outlined,
                  label: 'Plan',
                  value: school.subscriptionStatus.toUpperCase(),
                ),
                const Divider(height: Spacings.lg),
                _SettingsRow(
                  icon: Icons.event_outlined,
                  label: 'Expires',
                  value: school.subscriptionExpiresAt != null
                      ? _formatDate(school.subscriptionExpiresAt!)
                      : 'N/A',
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ── Quick Actions ──────────────────────────────────────────
          AppButton(
            label: 'Edit School Settings',
            onPressed: () {
              context.go(RouteNames.schoolAdminDashboard);
            },
            variant: AppButtonVariant.elevated,
            icon: Icons.edit_outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.seed;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _DetailTab {
  const _DetailTab({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Icon(icon, size: Spacings.mdIcon, color: color),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              value,
              style: tt.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              title,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: Spacings.mdIcon, color: iconColor ?? cs.onSurfaceVariant),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
