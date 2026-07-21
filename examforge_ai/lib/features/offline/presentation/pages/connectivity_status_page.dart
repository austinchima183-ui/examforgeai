import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/offline_entities.dart';
import '../providers/offline_provider.dart';
import '../widgets/offline_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// CONNECTIVITY STATUS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detailed connectivity information page.
///
/// Shows:
/// - Current connection quality with large indicator
/// - Connection type, latency, bandwidth
/// - Adaptive behavior adjustments (image quality, sync interval, batch size)
/// - Connection quality history chart placeholder
/// - Tips for improving connection
class ConnectivityStatusPage extends ConsumerStatefulWidget {
  const ConnectivityStatusPage({super.key});

  @override
  ConsumerState<ConnectivityStatusPage> createState() => _State();
}

class _State extends ConsumerState<ConnectivityStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offlineProvider.notifier).loadConnectivityInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final offlineState = ref.watch(offlineProvider);
    final info = offlineState.connectivityInfo;

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Connection Status',
      ),
      body: info == null
          ? const Center(child: AppLoadingSpinner())
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(offlineProvider.notifier).loadConnectivityInfo();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.lg,
                  vertical: Spacings.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Large Connection Indicator ──────────────────────
                    _buildLargeIndicator(context, info),
                    const SizedBox(height: Spacings.xl),

                    // ─── Connection Details ─────────────────────────────
                    _buildSectionHeader(context, 'Connection Details'),
                    const SizedBox(height: Spacings.sm),
                    _buildDetailsCard(context, info),
                    const SizedBox(height: Spacings.xl),

                    // ─── Adaptive Behavior ──────────────────────────────
                    _buildSectionHeader(context, 'Adaptive Behavior'),
                    const SizedBox(height: Spacings.sm),
                    _buildAdaptiveCard(context, info),
                    const SizedBox(height: Spacings.xl),

                    // ─── Connection Quality History ─────────────────────
                    _buildSectionHeader(context, 'Quality History'),
                    const SizedBox(height: Spacings.sm),
                    _buildHistoryPlaceholder(context),
                    const SizedBox(height: Spacings.xl),

                    // ─── Tips ───────────────────────────────────────────
                    _buildSectionHeader(context, 'Tips'),
                    const SizedBox(height: Spacings.sm),
                    _buildTipsCard(context, info),
                    const SizedBox(height: Spacings.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Large Connection Indicator ─────────────────────────────────────

  Widget _buildLargeIndicator(BuildContext context, ConnectivityInfo info) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final qualityColor = _qualityColor(info.connectionQuality);

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusXl,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              qualityColor.withValues(alpha: 0.1),
              qualityColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: Spacings.borderRadiusXl,
        ),
        child: Column(
          children: [
            ConnectionQualityIndicator(
              quality: info.connectionQuality,
              size: 80,
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              info.connectionQuality.label,
              style: tt.headlineMedium?.copyWith(
                fontWeight: AppTypography.wBold,
                color: qualityColor,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              info.isOnline ? 'Connected via ${info.connectionType.label}' : 'No connection',
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Connection Details Card ────────────────────────────────────────

  Widget _buildDetailsCard(BuildContext context, ConnectivityInfo info) {
    final cs = context.colorScheme;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          children: [
            _buildDetailRow(
              context,
              icon: Icons.wifi,
              label: 'Connection Type',
              value: info.connectionType.label,
            ),
            const Divider(height: Spacings.lg),
            _buildDetailRow(
              context,
              icon: Icons.speed_outlined,
              label: 'Latency',
              value: info.latencyMs != null ? '${info.latencyMs} ms' : '—',
            ),
            const Divider(height: Spacings.lg),
            _buildDetailRow(
              context,
              icon: Icons.download_outlined,
              label: 'Bandwidth',
              value: info.bandwidthKbps != null
                  ? '${(info.bandwidthKbps! / 1000).toStringAsFixed(1)} Mbps'
                  : '—',
            ),
            const Divider(height: Spacings.lg),
            _buildDetailRow(
              context,
              icon: Icons.signal_cellular_alt,
              label: 'Quality',
              value: info.connectionQuality.label,
              valueColor: _qualityColor(info.connectionQuality),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Adaptive Behavior Card ─────────────────────────────────────────

  Widget _buildAdaptiveCard(BuildContext context, ConnectivityInfo info) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          children: [
            _buildAdaptiveRow(
              context,
              icon: Icons.image_outlined,
              label: 'Image Quality',
              value: info.shouldReduceQuality ? 'Reduced' : 'Full',
              isActive: info.shouldReduceQuality,
            ),
            const Divider(height: Spacings.lg),
            _buildAdaptiveRow(
              context,
              icon: Icons.sync_outlined,
              label: 'Sync Interval',
              value: info.shouldDelaySync ? 'Delayed' : 'Real-time',
              isActive: info.shouldDelaySync,
            ),
            const Divider(height: Spacings.lg),
            _buildAdaptiveRow(
              context,
              icon: Icons.upload_outlined,
              label: 'Upload Compression',
              value: info.shouldCompressUploads ? 'Compressed' : 'Original',
              isActive: info.shouldCompressUploads,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isActive,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: Spacings.mdIcon,
          color: isActive ? AppColors.warning : AppColors.success,
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            value,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isActive ? AppColors.warning : AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  // ─── History Placeholder ────────────────────────────────────────────

  Widget _buildHistoryPlaceholder(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: Spacings.xlIcon,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'Connection quality over time',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              'Chart will appear as data is collected',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tips Card ──────────────────────────────────────────────────────

  Widget _buildTipsCard(BuildContext context, ConnectivityInfo info) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final tips = _getTips(info);

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  tip.icon,
                  size: Spacings.mdIcon - 4,
                  color: AppColors.info,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.title,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        tip.description,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title) {
    final tt = context.textTheme;
    return Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  Color _qualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return AppColors.success;
      case ConnectionQuality.good:
        return AppColors.info;
      case ConnectionQuality.limited:
        return AppColors.warning;
      case ConnectionQuality.offline:
        return AppColors.error;
    }
  }

  List<_ConnectionTip> _getTips(ConnectivityInfo info) {
    if (!info.isOnline) {
      return [
        _ConnectionTip(
          icon: Icons.wifi_off,
          title: 'Check your connection',
          description: 'Make sure Wi-Fi or mobile data is turned on and you have a stable connection.',
        ),
        _ConnectionTip(
          icon: Icons.airplanemode_active,
          title: 'Airplane mode',
          description: 'If airplane mode is on, turn it off to restore connectivity.',
        ),
        _ConnectionTip(
          icon: Icons.cloud_off,
          title: 'Work offline',
          description: 'Your downloaded resources and saved drafts are still available offline.',
        ),
      ];
    }

    if (info.connectionQuality == ConnectionQuality.limited) {
      return [
        _ConnectionTip(
          icon: Icons.signal_cellular_alt,
          title: 'Weak signal',
          description: 'Try moving closer to your Wi-Fi router or to an area with better mobile coverage.',
        ),
        _ConnectionTip(
          icon: Icons.image_outlined,
          title: 'Reduced quality mode',
          description: 'Images and media are being served in reduced quality to save bandwidth.',
        ),
        _ConnectionTip(
          icon: Icons.download_for_offline,
          title: 'Download for later',
          description: 'Download resources while on a strong connection for seamless offline access.',
        ),
      ];
    }

    return [
      _ConnectionTip(
        icon: Icons.download_for_offline,
        title: 'Download resources',
        description: 'Great connection! Now is a good time to download resources for offline use.',
      ),
      _ConnectionTip(
        icon: Icons.sync,
        title: 'Sync pending items',
        description: 'Sync any pending exam attempts or drafts while you have a strong connection.',
      ),
    ];
  }
}

class _ConnectionTip {
  const _ConnectionTip({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
