import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/theme_provider.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/widgets.dart';
import 'providers/settings_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// SETTINGS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Application settings page with sections for appearance, notifications,
/// account, about, and danger zone. Uses Material 3 styling throughout.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings'),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance Section ──────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.palette_outlined,
              title: 'Appearance',
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Column(
                children: [
                  // Theme Mode Selector
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _themeIcon(settingsState.themeMode),
                      color: cs.primary,
                    ),
                    title: Text(
                      'Theme Mode',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    subtitle: Text(
                      settingsState.themeLabel,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () => _showThemePicker(context, ref),
                  ),
                  const Divider(height: 1),
                  // Theme Preview Segmented Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacings.md,
                    ),
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {settingsState.themeMode},
                      onSelectionChanged: (modes) {
                        final mode = modes.first;
                        ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(mode);
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(mode);
                      },
                    ),
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Notifications Section ────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Push Notifications',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    subtitle: Text(
                      'Receive exam reminders and updates',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    secondary: Icon(
                      Icons.notifications_active_outlined,
                      color: cs.primary,
                    ),
                    value: settingsState.notificationsEnabled,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setNotificationsEnabled(value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Email Notifications',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    subtitle: Text(
                      'Receive email updates and reports',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    secondary: Icon(
                      Icons.email_outlined,
                      color: cs.primary,
                    ),
                    value: settingsState.emailNotificationsEnabled,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setEmailNotificationsEnabled(value);
                    },
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Account Section ──────────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.manage_accounts_outlined,
              title: 'Account',
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.lock_outline,
                      color: cs.primary,
                    ),
                    title: Text(
                      'Change Password',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      // Navigate to profile page's change password
                      context.go(RouteNames.profile);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.email_outlined,
                      color: cs.primary,
                    ),
                    title: Text(
                      'Email Preferences',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    subtitle: Text(
                      settingsState.emailNotificationsEnabled
                          ? 'Receiving email updates'
                          : 'Email updates disabled',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      // Toggle email notifications
                      ref
                          .read(settingsProvider.notifier)
                          .setEmailNotificationsEnabled(
                            !settingsState.emailNotificationsEnabled,
                          );
                    },
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Language Section ─────────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.language_outlined,
              title: 'Language',
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.language_outlined,
                  color: cs.primary,
                ),
                title: Text(
                  'Language',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  settingsState.languageLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
                onTap: () => _showLanguagePicker(context, ref),
              ),
            ),

            Spacings.sectionGap,

            // ── About Section ────────────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.info_outline,
              title: 'About',
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.info_outline,
                      color: cs.primary,
                    ),
                    title: Text(
                      'App Version',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    trailing: Text(
                      AppConstants.appVersion,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.description_outlined,
                      color: cs.primary,
                    ),
                    title: Text(
                      'Terms of Service',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      // In production, open the terms of service URL
                      AppDialog.showInfo(
                        context: context,
                        title: 'Terms of Service',
                        message:
                            'By using ExamForge AI, you agree to our Terms of Service. Visit examforge.ai/terms for the full document.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: cs.primary,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      // In production, open the privacy policy URL
                      AppDialog.showInfo(
                        context: context,
                        title: 'Privacy Policy',
                        message:
                            'Your privacy is important to us. Visit examforge.ai/privacy for the full privacy policy.',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.gavel_outlined,
                      color: cs.primary,
                    ),
                    title: Text(
                      'Open Source Licenses',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: AppConstants.appName,
                        applicationVersion: AppConstants.appVersion,
                      );
                    },
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Danger Zone ──────────────────────────────────────────
            _SettingsSectionHeader(
              icon: Icons.warning_amber_rounded,
              title: 'Danger Zone',
              color: AppColors.error,
            ),
            const SizedBox(height: Spacings.sm),
            AppCard(
              borderColor: AppColors.error.withValues(alpha: 0.3),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: AppTypography.wMedium,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and all data',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.error,
                    ),
                    onTap: () => _handleDeleteAccount(context),
                  ),
                ],
              ),
            ),

            Spacings.sectionGap,

            // ── Sign Out Button ──────────────────────────────────────
            AppButton(
              label: 'Sign Out',
              onPressed: () => _handleSignOut(context, ref),
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

  // ─── Theme Picker ────────────────────────────────────────────────

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacings.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Theme',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                      variant: AppIconButtonVariant.standard,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacings.md),
              ListTile(
                leading: const Icon(Icons.brightness_auto_outlined),
                title: const Text('System Default'),
                subtitle: const Text('Follow your device settings'),
                trailing: ref.read(settingsProvider).themeMode ==
                        ThemeMode.system
                    ? Icon(Icons.check_circle, color: cs.primary)
                    : null,
                onTap: () {
                  final mode = ThemeMode.system;
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Light'),
                subtitle: const Text('Always use light theme'),
                trailing:
                    ref.read(settingsProvider).themeMode == ThemeMode.light
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                onTap: () {
                  final mode = ThemeMode.light;
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark'),
                subtitle: const Text('Always use dark theme'),
                trailing:
                    ref.read(settingsProvider).themeMode == ThemeMode.dark
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                onTap: () {
                  final mode = ThemeMode.dark;
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                  ref.read(themeProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Language Picker ─────────────────────────────────────────────

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    const languages = [
      ('en', 'English', '🇬🇧'),
      ('fr', 'French', '🇫🇷'),
      ('es', 'Spanish', '🇪🇸'),
      ('ar', 'Arabic', '🇸🇦'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacings.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Language',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                      variant: AppIconButtonVariant.standard,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacings.md),
              ...languages.map((lang) {
                final isSelected =
                    ref.read(settingsProvider).language == lang.$1;
                return ListTile(
                  leading: Text(lang.$3, style: const TextStyle(fontSize: 24)),
                  title: Text(lang.$2),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: cs.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setLanguage(lang.$1);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sign Out ────────────────────────────────────────────────────

  Future<void> _handleSignOut(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your account?',
      confirmText: 'Sign Out',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
      if (context.mounted) {
        context.go(RouteNames.login);
      }
    } catch (e) {
      if (context.mounted) {
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

  // ─── Delete Account ──────────────────────────────────────────────

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Account',
      message:
          'This action is permanent and cannot be undone. All your data, '
          'exams, questions, and results will be permanently deleted.',
      confirmText: 'Delete Account',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true || !context.mounted) return;

    // Second confirmation
    final doubleConfirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Are You Absolutely Sure?',
      message:
          'This is your last chance. Your account and all associated data '
          'will be permanently deleted. This cannot be reversed.',
      confirmText: 'Yes, Delete Everything',
      cancelText: 'Keep My Account',
      isDestructive: true,
    );

    if (doubleConfirmed != true || !context.mounted) return;

    // In production, call the API to delete the account
    AppDialog.showInfo(
      context: context,
      title: 'Account Deletion Requested',
      message:
          'Your account deletion has been requested. You will receive a '
          'confirmation email. Your data will be deleted within 30 days.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

/// Section header for the settings page.
class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveColor = color ?? cs.primary;

    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: effectiveColor),
        const SizedBox(width: Spacings.sm),
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: effectiveColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
