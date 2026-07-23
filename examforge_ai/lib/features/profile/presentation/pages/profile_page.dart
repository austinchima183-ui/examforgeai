import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_guards.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/profile_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// User profile page — displays and allows editing of the current
/// user's profile information, change password, and account actions.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  // Edit form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();

  // Change password controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    final profileState = ref.read(profileProvider);
    if (!_isEditing) {
      _nameController.text = profileState.displayName;
      _phoneController.text = profileState.phone;
    }
    setState(() => _isEditing = !_isEditing);
    if (_isEditing) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _toggleChangePassword() {
    setState(() {
      _isChangingPassword = !_isChangingPassword;
      if (!_isChangingPassword) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  Future<void> _handleUpdateProfile() async {
    if (!_editFormKey.currentState!.validate()) return;

    await ref.read(profileProvider.notifier).updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    final state = ref.read(profileProvider);
    if (state.updateSuccess) {
      _toggleEdit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        );
      }
    } else if (state.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final success = await ref.read(profileProvider.notifier).changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (success) {
      _toggleChangePassword();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        );
      }
    } else {
      final state = ref.read(profileProvider);
      if (state.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
      if (mounted) {
        context.go(RouteNames.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to sign out. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final profileState = ref.watch(profileProvider);
    final roleAsync = ref.watch(userRoleProvider);

    final userRole = roleAsync.when(
      data: UserRole.fromString,
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      appBar: AppAppBar(
        title: 'Profile',
        actions: [
          AppIconButton(
            icon: _isEditing ? Icons.close : Icons.edit_outlined,
            onPressed: _toggleEdit,
            tooltip: _isEditing ? 'Cancel Editing' : 'Edit Profile',
            variant: AppIconButtonVariant.standard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar & Name Section ───────────────────────────────
            Center(
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.seed.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            profileState.displayName.isNotEmpty
                                ? profileState.displayName[0].toUpperCase()
                                : 'U',
                            style: tt.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.wBold,
                            ),
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(
                                  color: cs.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacings.lg),

                  // Name
                  Text(
                    profileState.displayName,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),

                  // Email
                  Text(
                    profileState.email,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),

                  // Role Chip
                  if (userRole != null)
                    Chip(
                      avatar: Icon(
                        _roleIcon(userRole),
                        size: Spacings.smIcon,
                      ),
                      label: Text(userRole.label),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Edit Profile Form (Expandable) ──────────────────────
            if (_isEditing) ...[
              AppCard(
                child: Form(
                  key: _editFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: cs.primary),
                          const SizedBox(width: Spacings.sm),
                          Text(
                            'Edit Profile',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: Spacings.xxl),
                      AppTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                        isRequired: true,
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: Spacings.lg),
                      AppTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: Spacings.xl),
                      AppButton(
                        label: 'Save Changes',
                        onPressed: _handleUpdateProfile,
                        isLoading: profileState.isUpdating,
                        fullWidth: true,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              Spacings.sectionGap,
            ],

            // ── Account Information Section ──────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        'Account Information',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: Spacings.xxl),
                  _ProfileInfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: profileState.displayName,
                  ),
                  const SizedBox(height: Spacings.md),
                  _ProfileInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: profileState.email,
                  ),
                  const SizedBox(height: Spacings.md),
                  _ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profileState.phone.isEmpty
                        ? 'Not set'
                        : profileState.phone,
                  ),
                  const SizedBox(height: Spacings.md),
                  _ProfileInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: userRole?.label ?? 'Unknown',
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Change Password Section ─────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline, color: cs.primary),
                    title: Text(
                      'Change Password',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    trailing: Icon(
                      _isChangingPassword
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: _toggleChangePassword,
                  ),
                  if (_isChangingPassword) ...[
                    const Divider(height: Spacings.lg),
                    Form(
                      key: _passwordFormKey,
                      child: Column(
                        children: [
                          AppPasswordField(
                            label: 'Current Password',
                            controller: _currentPasswordController,
                            isRequired: true,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Current password is required'
                                : null,
                          ),
                          const SizedBox(height: Spacings.lg),
                          AppPasswordField(
                            label: 'New Password',
                            controller: _newPasswordController,
                            isRequired: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'New password is required';
                              }
                              if (v.length < AppConstants.minPasswordLength) {
                                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacings.lg),
                          AppPasswordField(
                            label: 'Confirm New Password',
                            controller: _confirmPasswordController,
                            isRequired: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: Spacings.xl),
                          AppButton(
                            label: 'Update Password',
                            onPressed: _handleChangePassword,
                            isLoading: profileState.isUpdating,
                            fullWidth: true,
                            icon: Icons.lock_reset_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Activity Summary ─────────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: cs.primary),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        'Activity Summary',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: Spacings.xxl),
                  const Row(
                    children: [
                      Expanded(
                        child: _ActivityStat(
                          icon: Icons.quiz_outlined,
                          label: 'Exams Taken',
                          value: '0',
                          color: AppColors.info,
                        ),
                      ),
                      SizedBox(width: Spacings.md),
                      Expanded(
                        child: _ActivityStat(
                          icon: Icons.library_books_outlined,
                          label: 'Questions',
                          value: '0',
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(width: Spacings.md),
                      Expanded(
                        child: _ActivityStat(
                          icon: Icons.trending_up_rounded,
                          label: 'Avg Score',
                          value: '--',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Sign Out Button ──────────────────────────────────────
            AppButton(
              label: 'Sign Out',
              onPressed: _handleSignOut,
              variant: AppButtonVariant.outlined,
              fullWidth: true,
              icon: Icons.logout_rounded,
            ),

            const SizedBox(height: Spacings.xxxl),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) => switch (role) {
            UserRole.teacher => Icons.school_outlined,
            UserRole.student => Icons.person_outline,
            UserRole.schoolAdmin => Icons.admin_panel_settings_outlined,
            UserRole.superAdmin => Icons.supervisor_account_outlined,
          };
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

/// A single row displaying a label-value pair with an icon.
class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wMedium,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact activity statistic display.
class _ActivityStat extends StatelessWidget {
  const _ActivityStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.20 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: Spacings.mdIcon, color: color),
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          value,
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
