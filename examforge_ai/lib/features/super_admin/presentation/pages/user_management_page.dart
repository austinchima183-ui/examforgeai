import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../routing/route_names.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

const List<MapEntry<String, String>> _kRoleOptions = [
  MapEntry('super_admin', 'Super Admin'),
  MapEntry('school_admin', 'School Admin'),
  MapEntry('teacher', 'Teacher'),
  MapEntry('student', 'Student'),
  MapEntry('parent', 'Parent'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

String _roleLabel(String role) {
  for (final entry in _kRoleOptions) {
    if (entry.key == role) return entry.value;
  }
  return role;
}

Color _roleColor(String role) {
  switch (role) {
    case 'super_admin':
      return AppColors.error;
    case 'school_admin':
      return AppColors.info;
    case 'teacher':
      return AppColors.success;
    case 'student':
      return AppColors.seed;
    case 'parent':
      return AppColors.warning;
    default:
      return Colors.grey;
  }
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'super_admin':
      return Icons.admin_panel_settings_outlined;
    case 'school_admin':
      return Icons.domain_outlined;
    case 'teacher':
      return Icons.school_outlined;
    case 'student':
      return Icons.person_outline_rounded;
    case 'parent':
      return Icons.family_restroom_outlined;
    default:
      return Icons.person_outline;
  }
}

String _formatLastLogin(DateTime? lastLoginAt) {
  if (lastLoginAt == null) return 'Never';
  final now = DateTime.now();
  final diff = now.difference(lastLoginAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${lastLoginAt.day}/${lastLoginAt.month}/${lastLoginAt.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin page for managing all users across the platform.
///
/// Features:
/// - Search bar for filtering users by name/email
/// - Filter chips for role: Super Admin, School Admin, Teacher, Student, Parent
/// - Filter for: Active/Inactive
/// - DataTable/ListView showing: Name, Email, Role, School, Status, Last Login, Actions
/// - Actions per user: Suspend/Activate, Reset Password, Change Role, Impersonate
/// - Suspend dialog with reason
/// - Impersonate dialog with reason + confirmation warning
/// - Change Role dialog with dropdown
class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() =>
      _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  // ─── Controllers & State ─────────────────────────────────────────────────

  final _searchController = TextEditingController();
  final _suspendReasonController = TextEditingController();
  final _impersonateReasonController = TextEditingController();

  String? _roleFilter;
  bool? _activeFilter;

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
    _impersonateReasonController.dispose();
    super.dispose();
  }

  void _loadData() {
    ref.read(userManagementProvider.notifier).loadUsers(
          role: _roleFilter,
          isActive: _activeFilter,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error messages
    ref.listen<UserManagementState>(userManagementProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(userManagementProvider.notifier).state =
            ref.read(userManagementProvider).clearSuccess();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(userManagementProvider.notifier).state =
            ref.read(userManagementProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'User Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(context, state, cs),
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(
      BuildContext context, UserManagementState state, ColorScheme cs) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.users.isEmpty) {
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
                hint: 'Search users by name or email...',
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
                '${state.totalCount} user${state.totalCount == 1 ? '' : 's'}',
                style: AppTypography.wMedium.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacings.sm),

        // ─── User List ───────────────────────────────────────────────────
        Expanded(
          child: state.users.isEmpty
              ? const AdminEmptyState(
                  message: 'No users found',
                  icon: Icons.people_outline_rounded,
                )
              : _buildUserList(context, state, cs),
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
        // Role filters
        ..._kRoleOptions.map(
          (role) => FilterChip(
            label: Text(role.value),
            selected: _roleFilter == role.key,
            onSelected: (selected) {
              setState(() => _roleFilter = selected ? role.key : null);
              _loadData();
            },
          ),
        ),
        const SizedBox(width: Spacings.xs),
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
      ],
    );
  }

  // ─── User List ───────────────────────────────────────────────────────────

  Widget _buildUserList(
      BuildContext context, UserManagementState state, ColorScheme cs) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Spacings.paddingScreen,
        itemCount: state.users.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (context, index) {
          final user = state.users[index];
          return _UserManagementCard(
            user: user,
            onSuspend: user.isActive
                ? () => _showSuspendDialog(user)
                : () => _activateUser(user.id),
            onResetPassword: () => _resetPassword(user.id),
            onChangeRole: () => _showChangeRoleDialog(user),
            onImpersonate: () => _showImpersonateDialog(user),
          );
        },
      ),
    );
  }

  // ─── Suspend Dialog ─────────────────────────────────────────────────────

  void _showSuspendDialog(UserManagementDetail user) {
    _suspendReasonController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Suspend User',
          style: AppTypography.wSemiBold.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to suspend "${user.fullName}" (${user.email}). This will revoke their access to the platform.',
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
              decoration: InputDecoration(
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
                  .read(userManagementProvider.notifier)
                  .suspendUser(user.id, reason);
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

  // ─── Impersonate Dialog ──────────────────────────────────────────────────

  void _showImpersonateDialog(UserManagementDetail user) {
    _impersonateReasonController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: Spacings.sm),
            Text(
              'Impersonate User',
              style: AppTypography.wSemiBold.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: Spacings.paddingAll,
              decoration: BoxDecoration(
                color: AppColors.warningLight.withValues(alpha: 0.3),
                borderRadius: Spacings.borderRadiusMd,
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: Spacings.mdIcon, color: AppColors.warning),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      'Warning: Impersonation grants full access to this user\'s account. All actions will be logged and auditable.',
                      style: AppTypography.wMedium.copyWith(
                        fontSize: 12,
                        color: AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              'You are about to impersonate "${user.fullName}" (${user.email}) with role ${_roleLabel(user.role)}.',
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
              controller: _impersonateReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for impersonation',
                hintText: 'Provide a justified reason...',
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
              final reason = _impersonateReasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please provide a reason for impersonation'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              ref
                  .read(userManagementProvider.notifier)
                  .startImpersonation(user.id, reason);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: Text(
              'Confirm Impersonation',
              style: AppTypography.wSemiBold.copyWith(
                fontSize: 14,
                color: AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Change Role Dialog ──────────────────────────────────────────────────

  void _showChangeRoleDialog(UserManagementDetail user) {
    String? selectedRole = user.role;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                'Change Role',
                style: AppTypography.wSemiBold.copyWith(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change role for "${user.fullName}" (${user.email}).',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'New Role',
                      border: OutlineInputBorder(
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                    items: _kRoleOptions
                        .map(
                          (role) => DropdownMenuItem(
                            value: role.key,
                            child: Text(role.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value);
                    },
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
                    if (selectedRole == null || selectedRole == user.role) {
                      Navigator.of(dialogContext).pop();
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    ref
                        .read(userManagementProvider.notifier)
                        .changeRole(user.id, selectedRole!);
                  },
                  child: const Text('Update Role'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void _activateUser(String userId) {
    ref.read(userManagementProvider.notifier).activateUser(userId);
  }

  void _resetPassword(String userId) {
    ref.read(userManagementProvider.notifier).resetPassword(userId);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _UserManagementCard extends StatelessWidget {
  const _UserManagementCard({
    required this.user,
    required this.onSuspend,
    required this.onResetPassword,
    required this.onChangeRole,
    required this.onImpersonate,
  });

  final UserManagementDetail user;
  final VoidCallback onSuspend;
  final VoidCallback onResetPassword;
  final VoidCallback onChangeRole;
  final VoidCallback onImpersonate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleClr = _roleColor(user.role);

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Row ────────────────────────────────────────────────
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleClr.withValues(alpha: 0.12),
                  child: Icon(
                    _roleIcon(user.role),
                    size: Spacings.mdIcon,
                    color: roleClr,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: AppTypography.wSemiBold.copyWith(
                                fontSize: 15,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isEmailVerified) ...[
                            const SizedBox(width: Spacings.xs),
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
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
                // Role badge
                StatusBadge(
                  label: _roleLabel(user.role),
                  color: roleClr,
                  icon: _roleIcon(user.role),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Info Row ──────────────────────────────────────────────────
            Row(
              children: [
                // Status badge
                StatusBadge(
                  label: user.isActive ? 'Active' : 'Inactive',
                  color: user.isActive ? AppColors.success : AppColors.error,
                  icon: user.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                ),
                const SizedBox(width: Spacings.lg),
                // School
                if (user.schoolName != null) ...[
                  Icon(
                    Icons.domain_outlined,
                    size: Spacings.smIcon,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Flexible(
                    child: Text(
                      user.schoolName!,
                      style: AppTypography.wRegular.copyWith(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacings.lg),
                ],
                // Last login
                Icon(
                  Icons.access_time_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  _formatLastLogin(user.lastLoginAt),
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
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
                  label: user.isActive ? 'Suspend' : 'Activate',
                  icon: user.isActive
                      ? Icons.block_outlined
                      : Icons.play_arrow_outlined,
                  onPressed: onSuspend,
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  label: 'Reset Password',
                  icon: Icons.lock_reset_outlined,
                  onPressed: onResetPassword,
                  color: AppColors.info,
                ),
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  label: 'Change Role',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: onChangeRole,
                ),
                const SizedBox(width: Spacings.sm),
                _actionButton(
                  label: 'Impersonate',
                  icon: Icons.login_rounded,
                  onPressed: onImpersonate,
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
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
}
