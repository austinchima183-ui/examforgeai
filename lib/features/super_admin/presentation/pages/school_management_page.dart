import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin page for managing all schools on the platform.
///
/// Features:
/// - Search bar for filtering schools by name/domain
/// - Filter chips: Active/Inactive, Verified/Unverified, Subscription status
/// - DataTable showing: Name, Domain, Status, Verified, Students, Teachers,
///   Subscription, Storage, Actions
/// - Actions per school: View, Suspend/Reactivate, Verify, Edit
/// - FAB for "Create School" with dialog
/// - Suspend dialog with reason text field
class SchoolManagementPage extends ConsumerStatefulWidget {
  const SchoolManagementPage({super.key});

  @override
  ConsumerState<SchoolManagementPage> createState() =>
      _SchoolManagementPageState();
}

class _SchoolManagementPageState extends ConsumerState<SchoolManagementPage> {
  // ─── Controllers & State ─────────────────────────────────────────────────

  final _searchController = TextEditingController();
  final _suspendReasonController = TextEditingController();
  final _createSchoolNameController = TextEditingController();
  final _createSchoolDomainController = TextEditingController();

  bool? _activeFilter;
  bool? _verifiedFilter;
  String? _subscriptionFilter;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _suspendReasonController.dispose();
    _createSchoolNameController.dispose();
    _createSchoolDomainController.dispose();
    super.dispose();
  }

  void _loadData() {
    ref.read(schoolManagementProvider.notifier).loadSchools(
          isActive: _activeFilter,
          isVerified: _verifiedFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          subscriptionStatus: _subscriptionFilter,
        );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schoolManagementProvider);
    final cs = Theme.of(context).colorScheme;

    // Success snackbar
    ref.listen<SchoolManagementState>(schoolManagementProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(schoolManagementProvider.notifier).state =
            ref.read(schoolManagementProvider).clearSuccess();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(schoolManagementProvider.notifier).state =
            ref.read(schoolManagementProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'School Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(context, state, cs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSchoolDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Create School',
          style: AppTypography.wSemiBold.copyWith(fontSize: 14),
        ),
      ),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, SchoolManagementState state, ColorScheme cs,) {
    if (state.isLoading && state.schools.isEmpty) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.schools.isEmpty) {
      return Center(
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: Spacings.lg),
              Text(
                state.error!,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.lg),
              FilledButton.tonal(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ─── Search & Filters ────────────────────────────────────────────
        Padding(
          padding: Spacings.paddingScreen,
          child: Column(
            children: [
              AdminSearchBar(
                controller: _searchController,
                hint: 'Search schools by name or domain...',
                onChanged: (value) => _loadData(),
              ),
              const SizedBox(height: Spacings.md),
              _buildFilterChips(cs),
            ],
          ),
        ),

        // ─── Count Label ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          child: Row(
            children: [
              Text(
                '${state.totalCount} school${state.totalCount == 1 ? '' : 's'}',
                style: AppTypography.wMedium.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacings.sm),

        // ─── School List ─────────────────────────────────────────────────
        Expanded(
          child: state.schools.isEmpty
              ? AdminEmptyState(
                  message: 'No schools found',
                  icon: Icons.domain_outlined,
                  action: FilledButton.tonal(
                    onPressed: _showCreateSchoolDialog,
                    child: const Text('Create School'),
                  ),
                )
              : _buildSchoolList(context, state, cs),
        ),
      ],
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────────────

  Widget _buildFilterChips(ColorScheme cs) {
    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: [
        // Active / Inactive
        FilterChip(
          label: const Text('Active'),
          selected: _activeFilter == true,
          onSelected: (selected) {
            setState(() => _activeFilter = selected ? true : null);
            _loadData();
          },
        ),
        FilterChip(
          label: const Text('Inactive'),
          selected: _activeFilter == false,
          onSelected: (selected) {
            setState(() => _activeFilter = selected ? false : null);
            _loadData();
          },
        ),
        const SizedBox(width: Spacings.xs),
        // Verified / Unverified
        FilterChip(
          label: const Text('Verified'),
          selected: _verifiedFilter == true,
          onSelected: (selected) {
            setState(() => _verifiedFilter = selected ? true : null);
            _loadData();
          },
        ),
        FilterChip(
          label: const Text('Unverified'),
          selected: _verifiedFilter == false,
          onSelected: (selected) {
            setState(() => _verifiedFilter = selected ? false : null);
            _loadData();
          },
        ),
        const SizedBox(width: Spacings.xs),
        // Subscription status
        FilterChip(
          label: const Text('Active Subscription'),
          selected: _subscriptionFilter == 'active',
          onSelected: (selected) {
            setState(() =>
                _subscriptionFilter = selected ? 'active' : null,);
            _loadData();
          },
        ),
        FilterChip(
          label: const Text('Trial'),
          selected: _subscriptionFilter == 'trial',
          onSelected: (selected) {
            setState(() =>
                _subscriptionFilter = selected ? 'trial' : null,);
            _loadData();
          },
        ),
        FilterChip(
          label: const Text('Expired'),
          selected: _subscriptionFilter == 'expired',
          onSelected: (selected) {
            setState(() =>
                _subscriptionFilter = selected ? 'expired' : null,);
            _loadData();
          },
        ),
      ],
    );
  }

  // ─── School List ─────────────────────────────────────────────────────────

  Widget _buildSchoolList(
      BuildContext context, SchoolManagementState state, ColorScheme cs,) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        itemCount: state.schools.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (context, index) {
          final school = state.schools[index];
          return _SchoolManagementCard(
            school: school,
            onView: () => context.push(RouteNames.schoolDetail),
            onSuspend: school.isActive
                ? () => _showSuspendDialog(school)
                : () => _reactivateSchool(school.id),
            onVerify: !school.isVerified
                ? () => _verifySchool(school.id)
                : null,
            onEdit: () => context.push(RouteNames.schoolForm),
          );
        },
      ),
    );
  }

  // ─── Suspend Dialog ─────────────────────────────────────────────────────

  void _showSuspendDialog(SchoolManagementDetail school) {
    _suspendReasonController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Suspend School',
          style: AppTypography.wSemiBold.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to suspend "${school.name}". This will deactivate the school and restrict access for all its users.',
              style: AppTypography.wRegular.copyWith(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: Spacings.lg),
            TextField(
              controller: _suspendReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for suspension',
                hintText: 'Provide a reason...',
                border: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = _suspendReasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for suspension'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              ref
                  .read(schoolManagementProvider.notifier)
                  .suspendSchool(school.id, reason);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  // ─── Create School Dialog ────────────────────────────────────────────────

  void _showCreateSchoolDialog() {
    _createSchoolNameController.clear();
    _createSchoolDomainController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Create New School',
          style: AppTypography.wSemiBold.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _createSchoolNameController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                hintText: 'Enter school name',
                border: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
            ),
            const SizedBox(height: Spacings.md),
            TextField(
              controller: _createSchoolDomainController,
              decoration: const InputDecoration(
                labelText: 'Domain',
                hintText: 'e.g. school.examforge.ai',
                border: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = _createSchoolNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('School name is required'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              ref.read(schoolManagementProvider.notifier).createSchool({
                'name': name,
                'domain': _createSchoolDomainController.text.trim(),
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _reactivateSchool(String schoolId) {
    ref.read(schoolManagementProvider.notifier).reactivateSchool(schoolId);
  }

  void _verifySchool(String schoolId) {
    ref.read(schoolManagementProvider.notifier).verifySchool(schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCHOOL MANAGEMENT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SchoolManagementCard extends StatelessWidget {
  const _SchoolManagementCard({
    required this.school,
    required this.onView,
    required this.onSuspend,
    this.onVerify,
    required this.onEdit,
  });

  final SchoolManagementDetail school;
  final VoidCallback onView;
  final VoidCallback onSuspend;
  final VoidCallback? onVerify;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: Spacings.elevationSm,
      shape: const RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Row ────────────────────────────────────────────────
            Row(
              children: [
                // School icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Center(
                    child: Text(
                      school.name.substring(0, 1).toUpperCase(),
                      style: AppTypography.wBold.copyWith(
                        fontSize: 18,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                // Name & domain
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (school.domain != null)
                        Text(
                          school.domain!,
                          style: AppTypography.wRegular.copyWith(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Status badge
                StatusBadge(
                  label: school.isActive ? 'Active' : 'Inactive',
                  color: school.isActive ? AppColors.success : AppColors.error,
                  icon: school.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Info Row: Verified, Students, Teachers ───────────────────
            Wrap(
              spacing: Spacings.lg,
              runSpacing: Spacings.sm,
              children: [
                _infoItem(
                  icon: school.isVerified
                      ? Icons.verified_rounded
                      : Icons.verified_outlined,
                  label: school.isVerified ? 'Verified' : 'Unverified',
                  color: school.isVerified ? AppColors.success : AppColors.warning,
                ),
                _infoItem(
                  icon: Icons.school_outlined,
                  label: '${school.studentCount} students',
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                _infoItem(
                  icon: Icons.person_outline_rounded,
                  label: '${school.teacherCount} teachers',
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Subscription & Storage ────────────────────────────────────
            Row(
              children: [
                // Subscription status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription',
                        style: AppTypography.wRegular.copyWith(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      StatusBadge(
                        label: _subscriptionLabel(school.subscriptionStatus),
                        color: _subscriptionColor(school.subscriptionStatus),
                      ),
                    ],
                  ),
                ),
                // Storage usage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage',
                        style: AppTypography.wRegular.copyWith(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      _buildStorageBar(school, cs),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Action Buttons ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  label: 'View',
                  icon: Icons.visibility_outlined,
                  onPressed: onView,
                ),
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  label: school.isActive ? 'Suspend' : 'Reactivate',
                  icon: school.isActive
                      ? Icons.block_outlined
                      : Icons.play_arrow_outlined,
                  onPressed: onSuspend,
                  color: school.isActive ? AppColors.error : AppColors.success,
                ),
                if (onVerify != null) ...[
                  const SizedBox(width: Spacings.sm),
                  _actionButton(
                    label: 'Verify',
                    icon: Icons.verified_outlined,
                    onPressed: onVerify,
                    color: AppColors.info,
                  ),
                ],
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────

  Widget _infoItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: AppTypography.wMedium.copyWith(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildStorageBar(SchoolManagementDetail school, ColorScheme cs) {
    final utilization = school.storageUtilization;
    final color = utilization > 90
        ? AppColors.error
        : utilization > 70
            ? AppColors.warning
            : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: Spacings.borderRadiusSm,
          child: LinearProgressIndicator(
            value: utilization / 100,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          '${school.storageUsedMb.toInt()} / ${school.storageLimitMb.toInt()} MB',
          style: AppTypography.wRegular.copyWith(
            fontSize: 10,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: Spacings.smIcon, color: color),
      label: Text(
        label,
        style: AppTypography.wMedium.copyWith(fontSize: 12, color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _subscriptionLabel(String? status) {
    if (status == null) return 'None';
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'trial':
        return 'Trial';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _subscriptionColor(String? status) {
    if (status == null) return AppColors.error;
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'trial':
        return AppColors.info;
      case 'expired':
        return AppColors.warning;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
