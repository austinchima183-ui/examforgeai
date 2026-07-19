import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════

Color _scopeColor(SettingScope scope) {
  switch (scope) {
    case SettingScope.global:
      return AppColors.info;
    case SettingScope.billing:
      return AppColors.success;
    case SettingScope.ai:
      return const Color(0xFF7C3AED); // Violet
    case SettingScope.communication:
      return const Color(0xFF06B6D4); // Cyan
    case SettingScope.security:
      return AppColors.error;
    case SettingScope.infrastructure:
      return const Color(0xFFEA580C); // Orange
    case SettingScope.marketplace:
      return const Color(0xFFD97706); // Amber
    case SettingScope.email:
      return const Color(0xFF0EA5E9); // Sky
    case SettingScope.notification:
      return const Color(0xFF8B5CF6); // Purple
    case SettingScope.featureFlag:
      return AppColors.warning;
  }
}

Color _valueTypeColor(SettingValueType type) {
  switch (type) {
    case SettingValueType.string:
      return AppColors.info;
    case SettingValueType.integer:
      return AppColors.success;
    case SettingValueType.boolean:
      return const Color(0xFF7C3AED);
    case SettingValueType.json:
      return const Color(0xFFEA580C);
    case SettingValueType.float:
      return const Color(0xFF06B6D4);
    case SettingValueType.encrypted:
      return AppColors.error;
  }
}

Color _flagTypeColor(FeatureFlagType type) {
  switch (type) {
    case FeatureFlagType.boolean:
      return AppColors.info;
    case FeatureFlagType.percentage:
      return AppColors.success;
    case FeatureFlagType.userSegment:
      return const Color(0xFF7C3AED);
    case FeatureFlagType.schoolSegment:
      return const Color(0xFFEA580C);
    case FeatureFlagType.gradualRollout:
      return AppColors.warning;
  }
}

String _extractDisplayValue(Map<String, dynamic> value, SettingValueType type) {
  switch (type) {
    case SettingValueType.boolean:
      return value['enabled']?.toString() ?? value.values.first?.toString() ?? '';
    case SettingValueType.integer:
      return value['value']?.toString() ?? value.values.first?.toString() ?? '';
    case SettingValueType.float:
      return value['value']?.toString() ?? value.values.first?.toString() ?? '';
    case SettingValueType.encrypted:
      return '••••••••';
    default:
      final raw = value['value'] ?? value.values.first;
      if (raw is String) return raw;
      return raw?.toString() ?? '';
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL SETTINGS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin page for managing platform-wide configuration, feature flags,
/// policies, email templates, and maintenance windows.
///
/// Features:
/// - 5-tab interface: Settings, Feature Flags, Policies, Email Templates, Maintenance
/// - Settings: filterable by scope, inline editing with type-appropriate inputs
/// - Feature Flags: toggle switches, rollout sliders, create dialog
/// - Policies: list with rich text editor dialog
/// - Email Templates: list with subject + HTML body editor dialog
/// - Maintenance: mode toggle, scheduled windows list
class GlobalSettingsPage extends ConsumerStatefulWidget {
  const GlobalSettingsPage({super.key});

  @override
  ConsumerState<GlobalSettingsPage> createState() => _GlobalSettingsPageState();
}

class _GlobalSettingsPageState extends ConsumerState<GlobalSettingsPage>
    with SingleTickerProviderStateMixin {
  // ─── Controllers & State ─────────────────────────────────────────────────

  late final TabController _tabController;

  SettingScope? _scopeFilter;

  // Mock data for Policies, Email Templates, and Maintenance
  // (these would come from providers in a production build)
  final List<PlatformPolicy> _policies = const [
    PlatformPolicy(
      id: 'pol_1',
      policyKey: 'terms_of_service',
      title: 'Terms of Service',
      content: 'Full terms of service content...',
      version: 3,
      isActive: true,
      effectiveDate: DateTime(2025, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
    PlatformPolicy(
      id: 'pol_2',
      policyKey: 'privacy_policy',
      title: 'Privacy Policy',
      content: 'Full privacy policy content...',
      version: 2,
      isActive: true,
      effectiveDate: DateTime(2025, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 12, 1),
    ),
    PlatformPolicy(
      id: 'pol_3',
      policyKey: 'refund_policy',
      title: 'Refund Policy',
      content: 'Full refund policy content...',
      version: 1,
      isActive: true,
      effectiveDate: DateTime(2024, 6, 1),
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    PlatformPolicy(
      id: 'pol_4',
      policyKey: 'content_guidelines',
      title: 'Marketplace Content Guidelines',
      content: 'Full content guidelines...',
      version: 2,
      isActive: false,
      effectiveDate: DateTime(2024, 3, 1),
      createdAt: DateTime(2024, 3, 1),
      updatedAt: DateTime(2024, 8, 15),
    ),
  ];

  final List<EmailTemplate> _emailTemplates = const [
    EmailTemplate(
      id: 'tmpl_1',
      templateKey: 'welcome_email',
      name: 'Welcome Email',
      subject: 'Welcome to ExamForge AI, {{user_name}}!',
      htmlBody: '<h1>Welcome!</h1><p>Hello {{user_name}}, ...</p>',
      category: 'onboarding',
      variables: ['user_name', 'school_name'],
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    ),
    EmailTemplate(
      id: 'tmpl_2',
      templateKey: 'password_reset',
      name: 'Password Reset',
      subject: 'Reset your ExamForge AI password',
      htmlBody: '<h1>Password Reset</h1><p>Click <a href="{{reset_link}}">here</a>...</p>',
      category: 'authentication',
      variables: ['user_name', 'reset_link', 'expiry_hours'],
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 3, 1),
    ),
    EmailTemplate(
      id: 'tmpl_3',
      templateKey: 'subscription_confirmation',
      name: 'Subscription Confirmation',
      subject: 'Your {{plan_name}} subscription is active!',
      htmlBody: '<h1>Subscription Active</h1><p>Plan: {{plan_name}}...</p>',
      category: 'billing',
      variables: ['user_name', 'plan_name', 'amount', 'next_billing_date'],
      isActive: true,
      createdAt: DateTime(2024, 2, 1),
      updatedAt: DateTime(2024, 7, 1),
    ),
    EmailTemplate(
      id: 'tmpl_4',
      templateKey: 'exam_reminder',
      name: 'Exam Reminder',
      subject: 'Reminder: {{exam_title}} starts {{start_time}}',
      htmlBody: '<h1>Exam Reminder</h1><p>{{exam_title}} at {{start_time}}...</p>',
      category: 'examination',
      variables: ['student_name', 'exam_title', 'start_time', 'duration'],
      isActive: true,
      createdAt: DateTime(2024, 4, 1),
      updatedAt: DateTime(2024, 9, 1),
    ),
  ];

  final List<MaintenanceWindow> _maintenanceWindows = const [
    MaintenanceWindow(
      id: 'mw_1',
      title: 'Database Migration',
      description: 'Upgrading database schema for v2.5',
      status: MaintenanceStatus.scheduled,
      affectedServices: ['Database', 'API'],
      startAt: DateTime(2025, 3, 15, 2, 0),
      endAt: DateTime(2025, 3, 15, 4, 0),
      isPlanned: true,
      notificationSent: true,
      createdBy: 'admin_1',
      createdAt: DateTime(2025, 3, 1),
      updatedAt: DateTime(2025, 3, 1),
    ),
    MaintenanceWindow(
      id: 'mw_2',
      title: 'AI Provider Switch',
      description: 'Switching primary AI provider endpoint',
      status: MaintenanceStatus.completed,
      affectedServices: ['AI Service'],
      startAt: DateTime(2025, 2, 20, 1, 0),
      endAt: DateTime(2025, 2, 20, 1, 30),
      actualStartAt: DateTime(2025, 2, 20, 1, 0),
      actualEndAt: DateTime(2025, 2, 20, 1, 25),
      isPlanned: true,
      notificationSent: true,
      createdBy: 'admin_1',
      createdAt: DateTime(2025, 2, 15),
      updatedAt: DateTime(2025, 2, 20),
    ),
  ];

  bool _maintenanceModeEnabled = false;

  // ─── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    ref.read(platformSettingsProvider.notifier).loadSettings(scope: _scopeFilter);
    ref.read(featureFlagsProvider.notifier).loadFlags();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(platformSettingsProvider);
    final flagsState = ref.watch(featureFlagsProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error from settings
    ref.listen<PlatformSettingsState>(platformSettingsProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(platformSettingsProvider.notifier).state =
            ref.read(platformSettingsProvider).clearSuccess();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(platformSettingsProvider.notifier).state =
            ref.read(platformSettingsProvider).clearError();
      }
    });

    // Listen for success/error from feature flags
    ref.listen<FeatureFlagsState>(featureFlagsProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(featureFlagsProvider.notifier).state =
            ref.read(featureFlagsProvider).clearSuccess();
      }
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(featureFlagsProvider.notifier).state =
            ref.read(featureFlagsProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Global Settings',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Settings'),
            Tab(text: 'Feature Flags'),
            Tab(text: 'Policies'),
            Tab(text: 'Email Templates'),
            Tab(text: 'Maintenance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(settingsState, cs),
          _buildFeatureFlagsTab(flagsState, cs),
          _buildPoliciesTab(cs),
          _buildEmailTemplatesTab(cs),
          _buildMaintenanceTab(cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SETTINGS TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildSettingsTab(PlatformSettingsState state, ColorScheme cs) {
    if (state.isLoading && state.settings.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.settings.isEmpty) {
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

    final filteredSettings = _scopeFilter == null
        ? state.settings
        : state.settings.where((s) => s.scope == _scopeFilter).toList();

    return Column(
      children: [
        // ─── Scope Filter ───────────────────────────────────────────────
        Padding(
          padding: Spacings.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Scope',
                style: AppTypography.wSemiBold.copyWith(fontSize: 13),
              ),
              const SizedBox(height: Spacings.sm),
              FilterChipGroup<SettingScope>(
                items: SettingScope.values,
                selected: _scopeFilter,
                onSelected: (scope) {
                  setState(() => _scopeFilter = scope);
                  ref
                      .read(platformSettingsProvider.notifier)
                      .loadSettings(scope: scope);
                },
                labelBuilder: (scope) => scope.label,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─── Settings List ──────────────────────────────────────────────
        Expanded(
          child: filteredSettings.isEmpty
              ? AdminEmptyState(
                  message: 'No settings found for this scope.',
                  icon: Icons.settings_outlined,
                )
              : ListView.separated(
                  padding: Spacings.paddingScreen,
                  itemCount: filteredSettings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
                  itemBuilder: (context, index) =>
                      _buildSettingCard(filteredSettings[index], cs),
                ),
        ),
      ],
    );
  }

  Widget _buildSettingCard(PlatformSetting setting, ColorScheme cs) {
    final displayValue = _extractDisplayValue(setting.value, setting.valueType);
    final scopeColor = _scopeColor(setting.scope);
    final typeColor = _valueTypeColor(setting.valueType);

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: InkWell(
        onTap: setting.isReadonly
            ? null
            : () => _showEditSettingDialog(setting),
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Key + badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      setting.key,
                      style: AppTypography.wSemiBold.copyWith(
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  StatusBadge(label: setting.valueType.label, color: typeColor),
                  const SizedBox(width: Spacings.sm),
                  StatusBadge(label: setting.scope.label, color: scopeColor),
                  if (setting.isReadonly) ...[
                    const SizedBox(width: Spacings.sm),
                    StatusBadge(
                      label: 'Readonly',
                      color: cs.onSurface.withValues(alpha: 0.4),
                      icon: Icons.lock_outline,
                    ),
                  ],
                  if (setting.isEncrypted) ...[
                    const SizedBox(width: Spacings.sm),
                    StatusBadge(
                      label: 'Encrypted',
                      color: AppColors.error,
                      icon: Icons.enhanced_encryption_outlined,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Spacings.sm),

              // Row 2: Current Value
              Row(
                children: [
                  Text(
                    'Current Value: ',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayValue,
                      style: AppTypography.wMedium.copyWith(
                        fontSize: 13,
                        color: setting.isReadonly
                            ? cs.onSurface.withValues(alpha: 0.4)
                            : cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!setting.isReadonly)
                    Icon(Icons.edit_outlined, size: Spacings.smIcon, color: cs.primary),
                ],
              ),

              // Row 3: Description
              if (setting.description != null) ...[
                const SizedBox(height: Spacings.xs),
                Text(
                  setting.description!,
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSettingDialog(PlatformSetting setting) {
    final controller = TextEditingController();

    // Pre-fill based on type
    if (setting.valueType == SettingValueType.boolean) {
      // handled via switch, not controller
    } else if (setting.valueType == SettingValueType.json) {
      controller.text = const JsonEncoder.withIndent('  ')
          .convert(setting.value);
    } else {
      controller.text = _extractDisplayValue(setting.value, setting.valueType);
    }

    bool? boolValue;
    if (setting.valueType == SettingValueType.boolean) {
      boolValue = setting.value['enabled'] as bool? ??
          setting.value.values.first as bool? ??
          false;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit: ${setting.key}'),
          shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (setting.description != null) ...[
                  Text(
                    setting.description!,
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 13,
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                ],
                StatusBadge(label: setting.valueType.label, color: _valueTypeColor(setting.valueType)),
                const SizedBox(height: Spacings.md),

                // Type-appropriate input
                if (setting.valueType == SettingValueType.boolean)
                  SwitchListTile(
                    title: const Text('Enabled'),
                    value: boolValue ?? false,
                    onChanged: (v) => setDialogState(() => boolValue = v),
                  )
                else if (setting.valueType == SettingValueType.json)
                  TextField(
                    controller: controller,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'JSON Value',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    style: AppTypography.wRegular.copyWith(fontSize: 12, fontFamily: 'monospace'),
                  )
                else
                  TextField(
                    controller: controller,
                    keyboardType: setting.valueType == SettingValueType.integer
                        ? TextInputType.number
                        : setting.valueType == SettingValueType.float
                            ? const TextInputType.numberWithOptions(decimal: true)
                            : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Value (${setting.valueType.label})',
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Map<String, dynamic> newValue;
                if (setting.valueType == SettingValueType.boolean) {
                  newValue = {'enabled': boolValue ?? false};
                } else if (setting.valueType == SettingValueType.json) {
                  try {
                    newValue = jsonDecode(controller.text) as Map<String, dynamic>;
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid JSON format'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                } else if (setting.valueType == SettingValueType.integer) {
                  newValue = {'value': int.tryParse(controller.text) ?? 0};
                } else if (setting.valueType == SettingValueType.float) {
                  newValue = {'value': double.tryParse(controller.text) ?? 0.0};
                } else {
                  newValue = {'value': controller.text};
                }

                final updated = setting.copyWith(
                  value: newValue,
                  updatedAt: DateTime.now(),
                );
                ref.read(platformSettingsProvider.notifier).updateSetting(updated);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // FEATURE FLAGS TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildFeatureFlagsTab(FeatureFlagsState state, ColorScheme cs) {
    if (state.isLoading && state.flags.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.flags.isEmpty) {
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
        // ─── Header with Create Button ──────────────────────────────────
        Padding(
          padding: Spacings.paddingScreen,
          child: Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Feature Flags',
                  subtitle: '${state.flags.length} flags configured',
                ),
              ),
              FilledButton.icon(
                onPressed: _showCreateFlagDialog,
                icon: const Icon(Icons.add, size: Spacings.mdIcon),
                label: const Text('Create Flag'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ─── Flags List ─────────────────────────────────────────────────
        Expanded(
          child: state.flags.isEmpty
              ? const AdminEmptyState(
                  message: 'No feature flags configured.',
                  icon: Icons.flag_outlined,
                )
              : ListView.separated(
                  padding: Spacings.paddingScreen,
                  itemCount: state.flags.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.md),
                  itemBuilder: (context, index) =>
                      _buildFeatureFlagCard(state.flags[index], cs),
                ),
        ),
      ],
    );
  }

  Widget _buildFeatureFlagCard(FeatureFlag flag, ColorScheme cs) {
    final typeColor = _flagTypeColor(flag.flagType);

    return Card(
      elevation: flag.isActive ? Spacings.elevationSm : Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: flag.isActive
            ? BorderSide.none
            : BorderSide(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name + Type badge + Active toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    flag.name,
                    style: AppTypography.wSemiBold.copyWith(
                      fontSize: 14,
                      color: flag.isActive
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                StatusBadge(label: flag.flagType.label, color: typeColor),
                const SizedBox(width: Spacings.md),
                Switch(
                  value: flag.isActive,
                  onChanged: (active) {
                    ref
                        .read(featureFlagsProvider.notifier)
                        .toggleFlag(flag.id, active);
                  },
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // Row 2: Key
            Text(
              flag.key,
              style: AppTypography.wRegular.copyWith(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
                fontFamily: 'monospace',
              ),
            ),

            // Row 3: Description
            if (flag.description != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                flag.description!,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Row 4: Rollout percentage (if applicable)
            if (flag.flagType == FeatureFlagType.percentage ||
                flag.flagType == FeatureFlagType.gradualRollout) ...[
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Text(
                    'Rollout: ',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: flag.rolloutPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${flag.rolloutPercentage}%',
                      onChanged: flag.isActive
                          ? (v) {
                              // In production, this would call an update use case
                            }
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${flag.rolloutPercentage}%',
                      style: AppTypography.wSemiBold.copyWith(
                        fontSize: 12,
                        color: cs.primary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],

            // Row 5: Dates
            if (flag.startsAt != null || flag.expiresAt != null) ...[
              const SizedBox(height: Spacings.sm),
              Row(
                children: [
                  if (flag.startsAt != null) ...[
                    Icon(Icons.play_arrow_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'Starts: ${_formatDate(flag.startsAt)}',
                      style: AppTypography.wRegular.copyWith(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                  ],
                  if (flag.expiresAt != null) ...[
                    Icon(Icons.event_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      'Expires: ${_formatDate(flag.expiresAt)}',
                      style: AppTypography.wRegular.copyWith(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateFlagDialog() {
    final nameController = TextEditingController();
    final keyController = TextEditingController();
    final descController = TextEditingController();
    FeatureFlagType selectedType = FeatureFlagType.boolean;
    int rolloutPercentage = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Feature Flag'),
          shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Flag Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Flag Key',
                    border: OutlineInputBorder(),
                    helperText: 'e.g. enable_new_dashboard',
                  ),
                  style: AppTypography.wRegular.copyWith(fontFamily: 'monospace'),
                ),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<FeatureFlagType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Flag Type',
                    border: OutlineInputBorder(),
                  ),
                  items: FeatureFlagType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                if (selectedType == FeatureFlagType.percentage ||
                    selectedType == FeatureFlagType.gradualRollout) ...[
                  const SizedBox(height: Spacings.md),
                  Row(
                    children: [
                      const Text('Rollout %: '),
                      Expanded(
                        child: Slider(
                          value: rolloutPercentage.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$rolloutPercentage%',
                          onChanged: (v) =>
                              setDialogState(() => rolloutPercentage = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$rolloutPercentage%',
                          style: AppTypography.wSemiBold.copyWith(fontSize: 12),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    keyController.text.trim().isEmpty) {
                  return;
                }
                final now = DateTime.now();
                final flag = FeatureFlag(
                  id: '',
                  key: keyController.text.trim(),
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  flagType: selectedType,
                  value: selectedType == FeatureFlagType.boolean
                      ? {'enabled': true}
                      : {'percentage': rolloutPercentage},
                  isActive: true,
                  rolloutPercentage: rolloutPercentage,
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(featureFlagsProvider.notifier).createFlag(flag);
                Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // POLICIES TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildPoliciesTab(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: Spacings.paddingScreen,
          child: SectionHeader(
            title: 'Platform Policies',
            subtitle: '${_policies.length} policies configured',
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _policies.isEmpty
              ? const AdminEmptyState(
                  message: 'No policies configured.',
                  icon: Icons.policy_outlined,
                )
              : ListView.separated(
                  padding: Spacings.paddingScreen,
                  itemCount: _policies.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.md),
                  itemBuilder: (context, index) =>
                      _buildPolicyCard(_policies[index], cs),
                ),
        ),
      ],
    );
  }

  Widget _buildPolicyCard(PlatformPolicy policy, ColorScheme cs) {
    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          policy.title,
                          style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                        ),
                      ),
                      StatusBadge(
                        label: policy.isActive ? 'Active' : 'Inactive',
                        color: policy.isActive ? AppColors.success : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.sm),
                  Row(
                    children: [
                      Text(
                        policy.policyKey,
                        style: AppTypography.wRegular.copyWith(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: Spacings.lg),
                      StatusBadge(
                        label: 'v${policy.version}',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        'Effective: ${_formatDate(policy.effectiveDate)}',
                        style: AppTypography.wRegular.copyWith(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacings.md),
            FilledButton.tonal(
              onPressed: () => _showEditPolicyDialog(policy),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPolicyDialog(PlatformPolicy policy) {
    final contentController = TextEditingController(text: policy.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${policy.title}'),
        shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: contentController,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Policy Content',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            style: AppTypography.wRegular.copyWith(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // In production, would call a policy update use case
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Policy updated (mock)'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // EMAIL TEMPLATES TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildEmailTemplatesTab(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: Spacings.paddingScreen,
          child: SectionHeader(
            title: 'Email Templates',
            subtitle: '${_emailTemplates.length} templates configured',
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _emailTemplates.isEmpty
              ? const AdminEmptyState(
                  message: 'No email templates configured.',
                  icon: Icons.email_outlined,
                )
              : ListView.separated(
                  padding: Spacings.paddingScreen,
                  itemCount: _emailTemplates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.md),
                  itemBuilder: (context, index) =>
                      _buildEmailTemplateCard(_emailTemplates[index], cs),
                ),
        ),
      ],
    );
  }

  Widget _buildEmailTemplateCard(EmailTemplate template, ColorScheme cs) {
    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                        ),
                      ),
                      StatusBadge(
                        label: template.isActive ? 'Active' : 'Inactive',
                        color: template.isActive ? AppColors.success : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    'Subject: ${template.subject}',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.sm),
                  Row(
                    children: [
                      if (template.category != null) ...[
                        StatusBadge(
                          label: template.category!,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: Spacings.sm),
                      ],
                      if (template.variables != null &&
                          template.variables!.isNotEmpty)
                        Expanded(
                          child: Wrap(
                            spacing: Spacings.xs,
                            runSpacing: Spacings.xs,
                            children: template.variables!
                                .map((v) => Chip(
                                      label: Text(
                                        '{{$v}}',
                                        style: AppTypography.wRegular.copyWith(
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacings.md),
            FilledButton.tonal(
              onPressed: () => _showEditEmailTemplateDialog(template),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmailTemplateDialog(EmailTemplate template) {
    final subjectController = TextEditingController(text: template.subject);
    final bodyController = TextEditingController(text: template.htmlBody);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${template.name}'),
        shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusLg),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: bodyController,
                maxLines: 16,
                decoration: const InputDecoration(
                  labelText: 'HTML Body',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                style: AppTypography.wRegular.copyWith(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              if (template.variables != null &&
                  template.variables!.isNotEmpty) ...[
                const SizedBox(height: Spacings.md),
                Text(
                  'Available variables: ${template.variables!.map((v) => '{{$v}}').join(', ')}',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 11,
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // In production, would call an email template update use case
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email template updated (mock)'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // MAINTENANCE TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildMaintenanceTab(ColorScheme cs) {
    return ListView(
      padding: Spacings.paddingScreen,
      children: [
        // ─── Maintenance Mode Toggle ────────────────────────────────────
        Card(
          elevation: Spacings.elevationSm,
          shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
          color: _maintenanceModeEnabled
              ? AppColors.errorLight
              : cs.surface,
          child: SwitchListTile(
            title: Text(
              'Maintenance Mode',
              style: AppTypography.wSemiBold.copyWith(fontSize: 16),
            ),
            subtitle: Text(
              _maintenanceModeEnabled
                  ? 'Platform is in maintenance mode. Users cannot access the app.'
                  : 'Platform is running normally.',
              style: AppTypography.wRegular.copyWith(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            secondary: Icon(
              _maintenanceModeEnabled
                  ? Icons.build_circle
                  : Icons.check_circle_outline,
              color: _maintenanceModeEnabled ? AppColors.error : AppColors.success,
              size: Spacings.lgIcon,
            ),
            value: _maintenanceModeEnabled,
            onChanged: (v) {
              setState(() => _maintenanceModeEnabled = v);
              // In production, would update the maintenance_mode setting via provider
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    v
                        ? 'Maintenance mode enabled'
                        : 'Maintenance mode disabled',
                  ),
                  backgroundColor: v ? AppColors.warning : AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        Spacings.sectionGap,

        // ─── Scheduled Windows ──────────────────────────────────────────
        SectionHeader(
          title: 'Scheduled Windows',
          subtitle: '${_maintenanceWindows.length} windows',
        ),
        const SizedBox(height: Spacings.md),

        ..._maintenanceWindows.map((window) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: _buildMaintenanceWindowCard(window, cs),
            )),
      ],
    );
  }

  Widget _buildMaintenanceWindowCard(MaintenanceWindow window, ColorScheme cs) {
    Color statusColor;
    IconData statusIcon;
    switch (window.status) {
      case MaintenanceStatus.scheduled:
        statusColor = AppColors.info;
        statusIcon = Icons.schedule;
      case MaintenanceStatus.inProgress:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
      case MaintenanceStatus.completed:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case MaintenanceStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
    }

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: Spacings.mdIcon, color: statusColor),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    window.title,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                ),
                StatusBadge(label: window.status.label, color: statusColor),
              ],
            ),
            if (window.description != null) ...[
              const SizedBox(height: Spacings.sm),
              Text(
                window.description!,
                style: AppTypography.wRegular.copyWith(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: Spacings.smIcon,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${_formatDate(window.startAt)} – ${_formatDate(window.endAt)}',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (window.affectedServices != null &&
                    window.affectedServices!.isNotEmpty) ...[
                  const SizedBox(width: Spacings.lg),
                  ...window.affectedServices!.map((s) => Padding(
                        padding: const EdgeInsets.only(right: Spacings.xs),
                        child: StatusBadge(label: s, color: cs.primary),
                      )),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
