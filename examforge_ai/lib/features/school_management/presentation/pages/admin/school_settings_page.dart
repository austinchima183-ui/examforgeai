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
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../routing/route_names.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/school_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SCHOOL SETTINGS PAGE (Admin)
// ═══════════════════════════════════════════════════════════════════════

/// School settings page with sections for branding, limits, subscription,
/// and general configuration toggles.
class SchoolSettingsPage extends ConsumerStatefulWidget {
  const SchoolSettingsPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<SchoolSettingsPage> createState() =>
      _SchoolSettingsPageState();
}

class _SchoolSettingsPageState extends ConsumerState<SchoolSettingsPage> {
  bool _isSaving = false;

  // ─── Branding Controllers ────────────────────────────────────────────
  late TextEditingController _primaryColorCtrl;
  late TextEditingController _secondaryColorCtrl;
  late TextEditingController _mottoCtrl;
  late TextEditingController _logoUrlCtrl;

  // ─── Limits Controllers ──────────────────────────────────────────────
  late TextEditingController _maxStudentsCtrl;
  late TextEditingController _maxTeachersCtrl;

  // ─── Toggle States ───────────────────────────────────────────────────
  bool _enableNotifications = true;
  bool _enableAttendance = true;
  bool _enableHomework = true;
  bool _enableAnnouncements = true;
  bool _enableDocumentUpload = true;
  bool _enableParentPortal = true;
  bool _enableStudentPortal = true;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _primaryColorCtrl = TextEditingController();
    _secondaryColorCtrl = TextEditingController();
    _mottoCtrl = TextEditingController();
    _logoUrlCtrl = TextEditingController();
    _maxStudentsCtrl = TextEditingController();
    _maxTeachersCtrl = TextEditingController();

    Future.microtask(() {
      ref.read(schoolDetailProvider.notifier).loadSchool(widget.schoolId);
    });
  }

  @override
  void dispose() {
    _primaryColorCtrl.dispose();
    _secondaryColorCtrl.dispose();
    _mottoCtrl.dispose();
    _logoUrlCtrl.dispose();
    _maxStudentsCtrl.dispose();
    _maxTeachersCtrl.dispose();
    super.dispose();
  }

  void _populateForm(SchoolEntity school) {
    _primaryColorCtrl.text = school.primaryColor;
    _secondaryColorCtrl.text = school.secondaryColor;
    _mottoCtrl.text = school.motto ?? '';
    _logoUrlCtrl.text = school.logoUrl ?? '';
    _maxStudentsCtrl.text = '${school.maxStudents}';
    _maxTeachersCtrl.text = '${school.maxTeachers}';

    // Load settings from school entity's settings map
    final settings = school.settings;
    _enableNotifications = settings['enable_notifications'] as bool? ?? true;
    _enableAttendance = settings['enable_attendance'] as bool? ?? true;
    _enableHomework = settings['enable_homework'] as bool? ?? true;
    _enableAnnouncements = settings['enable_announcements'] as bool? ?? true;
    _enableDocumentUpload = settings['enable_document_upload'] as bool? ?? true;
    _enableParentPortal = settings['enable_parent_portal'] as bool? ?? true;
    _enableStudentPortal = settings['enable_student_portal'] as bool? ?? true;
    _maintenanceMode = settings['maintenance_mode'] as bool? ?? false;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final detailState = ref.read(schoolDetailProvider);
    final school = detailState.school;

    if (school == null) {
      setState(() => _isSaving = false);
      return;
    }

    final updatedSchool = school.copyWith(
      primaryColor: _primaryColorCtrl.text.trim(),
      secondaryColor: _secondaryColorCtrl.text.trim(),
      motto: _mottoCtrl.text.trim().isEmpty ? null : _mottoCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
      maxStudents: int.tryParse(_maxStudentsCtrl.text.trim()) ?? school.maxStudents,
      maxTeachers: int.tryParse(_maxTeachersCtrl.text.trim()) ?? school.maxTeachers,
      settings: {
        ...school.settings,
        'enable_notifications': _enableNotifications,
        'enable_attendance': _enableAttendance,
        'enable_homework': _enableHomework,
        'enable_announcements': _enableAnnouncements,
        'enable_document_upload': _enableDocumentUpload,
        'enable_parent_portal': _enableParentPortal,
        'enable_student_portal': _enableStudentPortal,
        'maintenance_mode': _maintenanceMode,
      },
    );

    await ref.read(schoolDetailProvider.notifier).updateSchool(updatedSchool);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(schoolDetailProvider);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Settings')),
        body: const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Settings')),
        body: AppErrorState.genericError(
          message: state.error,
          onRetry: () =>
              ref.read(schoolDetailProvider.notifier).loadSchool(widget.schoolId),
        ),
      );
    }

    if (state.school == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Settings')),
        body: const AppEmptyState(
          icon: Icons.school_outlined,
          title: 'School Not Found',
          subtitle: 'The school you are looking for does not exist.',
        ),
      );
    }

    // Populate form on first load
    if (_primaryColorCtrl.text.isEmpty) {
      _populateForm(state.school!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Settings',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacings.md),
            child: AppButton(
              label: 'Save',
              onPressed: _isSaving ? null : _saveSettings,
              variant: AppButtonVariant.elevated,
              icon: Icons.save_outlined,
              size: AppButtonSize.small,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── School Branding ────────────────────────────────────
                _SettingsSection(
                  title: 'School Branding',
                  icon: Icons.palette_outlined,
                  children: [
                    // Logo preview and upload
                    _buildLogoSection(context, state.school!),
                    const SizedBox(height: Spacings.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildColorField(
                            context,
                            label: 'Primary Color',
                            controller: _primaryColorCtrl,
                            colorHint: '#4F46E5',
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        Expanded(
                          child: _buildColorField(
                            context,
                            label: 'Secondary Color',
                            controller: _secondaryColorCtrl,
                            colorHint: '#7C3AED',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.md),
                    AppTextField(
                      label: 'School Motto',
                      controller: _mottoCtrl,
                      prefixIcon: Icons.format_quote_outlined,
                      hint: 'e.g., Excellence in Education',
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xl),

                // ── School Limits ──────────────────────────────────────
                _SettingsSection(
                  title: 'School Limits',
                  icon: Icons.tune_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Max Students',
                            controller: _maxStudentsCtrl,
                            prefixIcon: Icons.people_outline_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 1) return 'Enter a valid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        Expanded(
                          child: AppTextField(
                            label: 'Max Teachers',
                            controller: _maxTeachersCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 1) return 'Enter a valid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.md),
                    _buildLimitsInfo(context, state.school!),
                  ],
                ),
                const SizedBox(height: Spacings.xl),

                // ── Subscription Info ──────────────────────────────────
                _SettingsSection(
                  title: 'Subscription',
                  icon: Icons.card_membership_outlined,
                  children: [
                    _buildSubscriptionInfo(context, state.school!),
                  ],
                ),
                const SizedBox(height: Spacings.xl),

                // ── General Settings ───────────────────────────────────
                _SettingsSection(
                  title: 'General Settings',
                  icon: Icons.settings_outlined,
                  children: [
                    _ToggleRow(
                      icon: Icons.notifications_active_outlined,
                      title: 'Enable Notifications',
                      subtitle: 'Allow push and email notifications for users',
                      value: _enableNotifications,
                      onChanged: (v) =>
                          setState(() => _enableNotifications = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.fact_check_outlined,
                      title: 'Enable Attendance',
                      subtitle: 'Allow daily attendance tracking',
                      value: _enableAttendance,
                      onChanged: (v) =>
                          setState(() => _enableAttendance = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.assignment_outlined,
                      title: 'Enable Homework',
                      subtitle: 'Allow homework assignment and submission',
                      value: _enableHomework,
                      onChanged: (v) =>
                          setState(() => _enableHomework = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.campaign_outlined,
                      title: 'Enable Announcements',
                      subtitle: 'Allow school-wide announcements',
                      value: _enableAnnouncements,
                      onChanged: (v) =>
                          setState(() => _enableAnnouncements = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.upload_file_outlined,
                      title: 'Enable Document Upload',
                      subtitle: 'Allow document uploads for students and teachers',
                      value: _enableDocumentUpload,
                      onChanged: (v) =>
                          setState(() => _enableDocumentUpload = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.family_restroom_outlined,
                      title: 'Enable Parent Portal',
                      subtitle: 'Allow parents to view their children\'s data',
                      value: _enableParentPortal,
                      onChanged: (v) =>
                          setState(() => _enableParentPortal = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.school_outlined,
                      title: 'Enable Student Portal',
                      subtitle: 'Allow students to access their portal',
                      value: _enableStudentPortal,
                      onChanged: (v) =>
                          setState(() => _enableStudentPortal = v),
                    ),
                    const Divider(height: Spacings.lg),
                    _ToggleRow(
                      icon: Icons.build_outlined,
                      title: 'Maintenance Mode',
                      subtitle: 'Disable access for all non-admin users',
                      value: _maintenanceMode,
                      onChanged: (v) =>
                          setState(() => _maintenanceMode = v),
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xxl),

                // ── Save Button ────────────────────────────────────────
                AppButton(
                  label: 'Save Settings',
                  onPressed: _isSaving ? null : _saveSettings,
                  variant: AppButtonVariant.elevated,
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  fullWidth: true,
                ),
                const SizedBox(height: Spacings.xxl),

                // ── Danger Zone ────────────────────────────────────────
                _SettingsSection(
                  title: 'Danger Zone',
                  icon: Icons.warning_amber_rounded,
                  titleColor: AppColors.error,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete School',
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: AppColors.error,
                                ),
                              ),
                              Text(
                                'Permanently delete this school and all associated data. This action cannot be undone.',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        AppButton(
                          label: 'Delete',
                          onPressed: () => _confirmDeleteSchool(context),
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, SchoolEntity school) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Row(
      children: [
        // Logo preview
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: school.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(Spacings.lgRadius),
                  child: Image.network(
                    school.logoUrl!,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.school_rounded,
                      size: 32,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : Icon(
                  Icons.school_rounded,
                  size: 32,
                  color: cs.onSurfaceVariant,
                ),
        ),
        const SizedBox(width: Spacings.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School Logo',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                'Upload a logo image or provide a URL. Recommended: 512x512px PNG.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: Spacings.sm),
              Row(
                children: [
                  AppButton(
                    label: 'Upload',
                    onPressed: () {
                      // File picker logic would go here
                    },
                    variant: AppButtonVariant.tonal,
                    icon: Icons.upload_outlined,
                    size: AppButtonSize.small,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'Logo URL',
                      controller: _logoUrlCtrl,
                      hint: 'https://...',
                      keyboardType: TextInputType.url,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String colorHint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: label,
            controller: controller,
            hint: colorHint,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _parseColor(controller.text),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLimitsInfo(BuildContext context, SchoolEntity school) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.info.withOpacity(isDark ? 0.20 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: Spacings.mdIcon, color: AppColors.info),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Text(
              'Current limits: ${school.maxStudents} students, ${school.maxTeachers} teachers. '
              'New users cannot be added beyond these limits.',
              style: tt.bodySmall?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(BuildContext context, SchoolEntity school) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final planColor = _subscriptionColor(school.subscriptionStatus);
    final planLabel = _subscriptionLabel(school.subscriptionStatus);
    final hasExpiry = school.subscriptionExpiresAt != null;
    final isExpiringSoon = hasExpiry &&
        school.subscriptionExpiresAt!.difference(DateTime.now()).inDays < 30;

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: planColor.withOpacity(isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: Spacings.lgIcon,
                color: planColor,
              ),
            ),
            const SizedBox(width: Spacings.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planLabel,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: planColor,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  if (hasExpiry)
                    Text(
                      isExpiringSoon
                          ? 'Expires in ${school.subscriptionExpiresAt!.difference(DateTime.now()).inDays} days'
                          : 'Expires ${_formatDate(school.subscriptionExpiresAt!)}',
                      style: tt.bodySmall?.copyWith(
                        color: isExpiringSoon ? AppColors.error : cs.onSurfaceVariant,
                      ),
                    )
                  else
                    Text(
                      'No expiration date set',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            AppButton(
              label: 'Upgrade',
              onPressed: () {
                // Navigate to upgrade page
              },
              variant: AppButtonVariant.tonal,
              icon: Icons.upgrade_rounded,
              size: AppButtonSize.small,
            ),
          ],
        ),
        if (isExpiringSoon) ...[
          const SizedBox(height: Spacings.md),
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(isDark ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: AppColors.warning.withOpacity(isDark ? 0.20 : 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: Spacings.mdIcon, color: AppColors.warning),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    'Your subscription is expiring soon. Renew to avoid service interruption.',
                    style: tt.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _confirmDeleteSchool(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete School'),
        content: const Text(
          'This will permanently delete the school and all associated data including '
          'students, teachers, classes, and records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(schoolListProvider.notifier).deleteSchool(widget.schoolId);
              context.go(RouteNames.superAdminDashboard);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete School'),
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

  Color _subscriptionColor(String status) {
    switch (status) {
      case 'premium':
        return AppColors.success;
      case 'basic':
        return AppColors.info;
      case 'free':
      default:
        return AppColors.warning;
    }
  }

  String _subscriptionLabel(String status) {
    switch (status) {
      case 'premium':
        return 'Premium Plan';
      case 'basic':
        return 'Basic Plan';
      case 'free':
      default:
        return 'Free Plan';
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
// SETTINGS SECTION WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
    this.titleColor,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: Spacings.mdIcon,
                color: titleColor ?? cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: titleColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          ...children,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TOGGLE ROW WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final activeColor = isDestructive ? AppColors.error : cs.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.sm),
          decoration: BoxDecoration(
            color: (isDestructive ? AppColors.error : cs.primary)
                .withOpacity(isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Icon(
            icon,
            size: Spacings.mdIcon,
            color: isDestructive ? AppColors.error : cs.primary,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}
