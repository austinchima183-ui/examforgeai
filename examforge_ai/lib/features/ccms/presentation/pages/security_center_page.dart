import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../providers/enterprise_provider.dart';

class SecurityCenterPage extends ConsumerStatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  ConsumerState<SecurityCenterPage> createState() =>
      _SecurityCenterPageState();
}

class _SecurityCenterPageState
    extends ConsumerState<SecurityCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enterpriseProvider.notifier).loadMfaConfig('current_user');
      ref.read(enterpriseProvider.notifier).loadApiKeys('current_user');
      ref.read(enterpriseProvider.notifier).loadSecurityEvents();
      ref.read(enterpriseProvider.notifier).loadUserSessions('current_user');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enterpriseProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Security Center',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: 'MFA', icon: Icon(Icons.shield_rounded, size: 18)),
            Tab(text: 'API Keys', icon: Icon(Icons.key_rounded, size: 18)),
            Tab(text: 'Events', icon: Icon(Icons.warning_amber_rounded, size: 18)),
            Tab(text: 'Rate Limits', icon: Icon(Icons.speed_rounded, size: 18)),
            Tab(text: 'Sessions', icon: Icon(Icons.devices_rounded, size: 18)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: AppLoadingSpinner())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMfaTab(state, cs, tt),
                _buildApiKeysTab(state, cs, tt),
                _buildSecurityEventsTab(state, cs, tt),
                _buildRateLimitingTab(state, cs, tt),
                _buildActiveSessionsTab(state, cs, tt),
              ],
            ),
    );
  }

  // ── MFA Tab ────────────────────────────────────────────────────────

  Widget _buildMfaTab(EnterpriseState state, ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MFA Configuration',
              style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.onSurface,),),
          const SizedBox(height: Spacings.md),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: state.mfaConfig?.isEnabled ?? false,
                  onChanged: (v) {
                    if (v) {
                      ref.read(enterpriseProvider.notifier).enableMfa(
                          userId: 'current_user',
                          method: MfaMethod.authenticatorApp,);
                    } else {
                      _showDisableMfaDialog();
                    }
                  },
                  title: const Text('Enable MFA'),
                  subtitle: Text(
                      state.mfaConfig?.mfaMethod.label ?? 'Not configured',),
                  activeThumbColor: cs.primary,
                ),
                if (state.mfaConfig?.isEnabled ?? false) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone_android_rounded),
                    title: const Text('SMS'),
                    trailing: Radio<MfaMethod>(
                      value: MfaMethod.sms,
                      groupValue: state.mfaConfig?.mfaMethod,
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(enterpriseProvider.notifier)
                              .enableMfa(userId: 'current_user', method: v);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_rounded),
                    title: const Text('Email'),
                    trailing: Radio<MfaMethod>(
                      value: MfaMethod.email,
                      groupValue: state.mfaConfig?.mfaMethod,
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(enterpriseProvider.notifier)
                              .enableMfa(userId: 'current_user', method: v);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_rounded),
                    title: const Text('Authenticator App'),
                    trailing: Radio<MfaMethod>(
                      value: MfaMethod.authenticatorApp,
                      groupValue: state.mfaConfig?.mfaMethod,
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(enterpriseProvider.notifier)
                              .enableMfa(userId: 'current_user', method: v);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.usb_rounded),
                    title: const Text('Hardware Key'),
                    trailing: Radio<MfaMethod>(
                      value: MfaMethod.hardwareKey,
                      groupValue: state.mfaConfig?.mfaMethod,
                      onChanged: (v) {
                        if (v != null) {
                          ref
                              .read(enterpriseProvider.notifier)
                              .enableMfa(userId: 'current_user', method: v);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacings.lg),
          // Backup codes
          Text('Backup Codes',
              style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.onSurface,),),
          const SizedBox(height: Spacings.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup codes can be used to access your account if you lose your MFA device. '
                  'Each code can only be used once.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Generate New Backup Codes',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('New backup codes generated'),),
                    );
                  },
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── API Keys Tab ──────────────────────────────────────────────────

  Widget _buildApiKeysTab(EnterpriseState state, ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('API Keys',
                  style: tt.titleLarge?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,),),
              AppButton(
                label: 'Create API Key',
                onPressed: _showCreateApiKeyDialog,
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (state.apiKeys.isEmpty)
            AppEmptyState.noData(subtitle: 'No API keys configured')
          else
            ...state.apiKeys.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.md),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(key.name,
                                  style: tt.titleSmall?.copyWith(
                                      fontWeight:
                                          AppTypography.wSemiBold,),),
                            ),
                            AppIconButton(
                              icon: Icons.delete_outline_rounded,
                              onPressed: () => ref
                                  .read(enterpriseProvider.notifier)
                                  .revokeApiKey(key.id),
                              variant: AppIconButtonVariant.standard,
                              tooltip: 'Revoke Key',
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacings.sm),
                        // Scopes display
                        Text('Scopes',
                            style: tt.labelMedium?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: cs.primary,),),
                        const SizedBox(height: Spacings.xs),
                        Wrap(
                          spacing: Spacings.xs,
                          runSpacing: Spacings.xs,
                          children: (key.scopes ?? <String>[])
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Spacings.sm,
                                        vertical: 2,),
                                    decoration: BoxDecoration(
                                      color:
                                          cs.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius:
                                          Spacings.borderRadiusSm,
                                    ),
                                    child: Text(s,
                                        style: tt.bodySmall?.copyWith(
                                            color: cs.primary,),),
                                  ),)
                              .toList(),
                        ),
                        const SizedBox(height: Spacings.sm),
                        Text(
                            'Created ${_formatDate(key.createdAt)}',
                            style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,),),
                      ],
                    ),
                  ),
                ),),
        ],
      ),
    );
  }

  // ── Security Events Tab ──────────────────────────────────────────

  Widget _buildSecurityEventsTab(
      EnterpriseState state, ColorScheme cs, TextTheme tt,) {
    return state.securityEvents.isEmpty
        ? AppEmptyState.noData(subtitle: 'No security events')
        : ListView.builder(
            padding: Spacings.paddingScreen,
            itemCount: state.securityEvents.length,
            itemBuilder: (context, index) {
              final event = state.securityEvents[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm, vertical: 2,),
                            decoration: BoxDecoration(
                              color: _severityColor(event.severity)
                                  .withValues(alpha: 0.15),
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                            child: Text(event.severity.label,
                                style: AppTypography.labelSmall!.copyWith(
                                    color: _severityColor(event.severity),
                                    fontWeight: AppTypography.wSemiBold,),),
                          ),
                          const SizedBox(width: Spacings.sm),
                          Expanded(
                            child: Text(event.eventType,
                                style: tt.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.sm),
                      Row(
                        children: [
                          Text(event.eventType,
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,),),
                          const Spacer(),
                          Text(_formatDate(event.createdAt),
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,),),
                        ],
                      ),
                      if (!event.isResolved) ...[
                        const SizedBox(height: Spacings.sm),
                        AppButton(
                          label: 'Resolve',
                          onPressed: () {},
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.small,
                          icon: Icons.check_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }

  // ── Rate Limiting Tab ────────────────────────────────────────────

  Widget _buildRateLimitingTab(
      EnterpriseState state, ColorScheme cs, TextTheme tt,) {
    final configs = [
      ('Global', RateLimitScope.global, 1000, 60),
      ('Per User', RateLimitScope.perUser, 100, 60),
      ('Per IP', RateLimitScope.perIp, 200, 60),
      ('Per API Key', RateLimitScope.perApiKey, 500, 60),
      ('Per Endpoint', RateLimitScope.perEndpoint, 300, 60),
    ];

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate Limiting Configuration',
              style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.onSurface,),),
          const SizedBox(height: Spacings.md),
          ...configs.map((config) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed_rounded,
                              color: cs.primary, size: Spacings.mdIcon,),
                          const SizedBox(width: Spacings.sm),
                          Expanded(
                            child: Text(config.$1,
                                style: tt.titleSmall?.copyWith(
                                    fontWeight: AppTypography.wSemiBold,),),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm, vertical: 2,),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                            child: Text(config.$2.label,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.primary,),),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.sm),
                      Text(
                          '${config.$3} requests per ${config.$4} seconds',
                          style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,),),
                      const SizedBox(height: Spacings.sm),
                      AppButton(
                        label: 'Edit Limits',
                        onPressed: () {
                          _showEditRateLimitDialog(config.$1, config.$3, config.$4);
                        },
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.small,
                        icon: Icons.edit_rounded,
                      ),
                    ],
                  ),
                ),
              ),),
        ],
      ),
    );
  }

  // ── Active Sessions Tab ──────────────────────────────────────────

  Widget _buildActiveSessionsTab(
      EnterpriseState state, ColorScheme cs, TextTheme tt,) {
    if (state.userSessions.isEmpty) {
      return AppEmptyState.noData(subtitle: 'No active sessions');
    }
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: state.userSessions.length,
      itemBuilder: (context, index) {
        final session = state.userSessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: AppCard(
            child: Row(
              children: [
                Icon(_deviceIcon(session.deviceName ?? session.deviceType ?? 'Unknown'),
                    color: cs.onSurfaceVariant, size: Spacings.lgIcon,),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.deviceName ?? 'Unknown device',
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,),),
                      const SizedBox(height: Spacings.xs),
                      Text(
                          'IP: ${session.ipAddress} · ${_formatDate(session.lastActivityAt)}',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,),),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Invalidate',
                  onPressed: () => ref
                      .read(enterpriseProvider.notifier)
                      .invalidateSessions(
                          userId: 'current_user',
                          sessionId: session.id,),
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────

  void _showDisableMfaDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable MFA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your verification code to disable MFA. '
              'This will make your account less secure.',
              style: AppTypography.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),
            ),
            const SizedBox(height: Spacings.md),
            TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    border: OutlineInputBorder(),),),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),),
          AppButton(
            label: 'Disable',
            onPressed: () {
              ref.read(enterpriseProvider.notifier).disableMfa(
                  userId: 'current_user',
                  verificationCode: codeCtrl.text,);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCreateApiKeyDialog() {
    final nameCtrl = TextEditingController();
    final scopes = <String>['read', 'write'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create API Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Key Name *',
                        border: OutlineInputBorder(),),),
                const SizedBox(height: Spacings.md),
                Text('Scopes',
                    style: AppTypography.labelMedium!.copyWith(
                        fontWeight: AppTypography.wSemiBold,),),
                const SizedBox(height: Spacings.sm),
                Wrap(
                  spacing: Spacings.sm,
                  children: ['read', 'write', 'admin', 'delete']
                      .map((scope) => FilterChip(
                            label: Text(scope),
                            selected: scopes.contains(scope),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  scopes.add(scope);
                                } else {
                                  scopes.remove(scope);
                                }
                              });
                            },
                          ),)
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),),
            AppButton(
              label: 'Create',
              onPressed: () {
                ref.read(enterpriseProvider.notifier).createApiKey(
                      userId: 'current_user',
                      name: nameCtrl.text,
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRateLimitDialog(
      String name, int currentLimit, int currentWindow,) {
    final limitCtrl = TextEditingController(text: '$currentLimit');
    final windowCtrl = TextEditingController(text: '$currentWindow');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Rate Limit - $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: limitCtrl,
                decoration: const InputDecoration(
                    labelText: 'Max Requests',
                    border: OutlineInputBorder(),),
                keyboardType: TextInputType.number,),
            const SizedBox(height: Spacings.md),
            TextField(
                controller: windowCtrl,
                decoration: const InputDecoration(
                    labelText: 'Window (seconds)',
                    border: OutlineInputBorder(),),
                keyboardType: TextInputType.number,),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),),
          AppButton(
            label: 'Save',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Color _severityColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => AppColors.info,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.critical => AppColors.error,
      AlertSeverity.emergency => const Color(0xFF7F1D1D),
    };
  }

  IconData _deviceIcon(String deviceInfo) {
    if (deviceInfo.toLowerCase().contains('mobile')) {
      return Icons.phone_android_rounded;
    }
    if (deviceInfo.toLowerCase().contains('tablet')) {
      return Icons.tablet_rounded;
    }
    return Icons.computer_rounded;
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
