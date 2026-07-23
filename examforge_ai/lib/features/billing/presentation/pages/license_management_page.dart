import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/license_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// LICENSE MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// License management page.
///
/// Lists LicenseCard widgets with type filtering, revoke with
/// confirmation dialog, and seat usage overview.
class LicenseManagementPage extends ConsumerStatefulWidget {
  const LicenseManagementPage({
    super.key,
    this.schoolId,
    this.userId,
  });

  final String? schoolId;
  final String? userId;

  @override
  ConsumerState<LicenseManagementPage> createState() =>
      _LicenseManagementPageState();
}

class _LicenseManagementPageState
    extends ConsumerState<LicenseManagementPage> {
  LicenseType? _typeFilter;
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLicenses();
    });
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadLicenses() async {
    await ref.read(licenseProvider.notifier).loadLicenses(
          schoolId: widget.schoolId,
          userId: widget.userId,
          type: _typeFilter,
          activeOnly: _activeOnly,
        );
  }

  Future<void> _refresh() async {
    await _loadLicenses();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final licenseState = ref.watch(licenseProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'License Management'),
      body: Column(
        children: [
          // ── Seat Usage Overview ────────────────────────────────────
          _buildSeatUsageOverview(licenseState),

          // ── Filter Bar ─────────────────────────────────────────────
          _buildFilterBar(),

          // ── License List ───────────────────────────────────────────
          Expanded(
            child: _buildLicenseList(licenseState),
          ),
        ],
      ),
    );
  }

  // ─── Seat Usage Overview ─────────────────────────────────────────────

  Widget _buildSeatUsageOverview(LicenseState licenseState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final licenses = licenseState.licenses;
    final activeLicenses = licenses.where((l) => l.isActive && !l.isExpired).toList();
    final totalSeats = activeLicenses.fold<int>(0, (sum, l) => sum + l.seatsTotal);
    final usedSeats = activeLicenses.fold<int>(0, (sum, l) => sum + l.seatsUsed);
    final usagePercent = totalSeats > 0 ? (usedSeats / totalSeats * 100) : 0.0;

    final Color progressColor;
    if (usagePercent >= 100) {
      progressColor = AppColors.error;
    } else if (usagePercent >= 80) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seat Usage Overview',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              // Circular indicator
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: totalSeats > 0 ? usedSeats / totalSeats : 0,
                      strokeWidth: 5,
                      backgroundColor:
                          progressColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      valueColor: AlwaysStoppedAnimation(progressColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${usagePercent.toStringAsFixed(0)}%',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacings.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$usedSeats / $totalSeats seats used',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wMedium,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      '${licenseState.activeLicenseCount} active license${licenseState.activeLicenseCount == 1 ? '' : 's'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (licenseState.expiredLicenseCount > 0) ...[
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${licenseState.expiredLicenseCount} expired',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ──────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  label: 'All',
                  isSelected: _typeFilter == null,
                  onSelected: () {
                    setState(() => _typeFilter = null);
                    _loadLicenses();
                  },
                ),
                const SizedBox(width: Spacings.xs),
                ...LicenseType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: Spacings.xs),
                    child: _filterChip(
                      label: '${type.label} License',
                      isSelected: _typeFilter == type,
                      onSelected: () {
                        setState(() => _typeFilter = type);
                        _loadLicenses();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Row(
            children: [
              Switch(
                value: _activeOnly,
                onChanged: (value) {
                  setState(() => _activeOnly = value);
                  _loadLicenses();
                },
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                'Active only',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── License List ────────────────────────────────────────────────────

  Widget _buildLicenseList(LicenseState licenseState) {
    if (licenseState.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (licenseState.error != null) {
      return AppErrorState.genericError(
        message: licenseState.error,
        onRetry: _refresh,
      );
    }

    if (licenseState.licenses.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Licenses Found',
        subtitle: _typeFilter != null
            ? 'Try changing the filter.'
            : 'No licenses have been issued yet.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.sm,
        ),
        itemCount: licenseState.licenses.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
        itemBuilder: (context, index) {
          final license = licenseState.licenses[index];
          return LicenseCard(
            license: license,
            onRevoke: license.isActive && !license.isExpired
                ? () => _confirmRevoke(license)
                : null,
          );
        },
      ),
    );
  }

  // ─── Confirm Revoke ──────────────────────────────────────────────────

  Future<void> _confirmRevoke(LicenseEntity license) async {
    final reasonController = TextEditingController();

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Revoke License?',
      message:
          'This will revoke the ${license.licenseType.label} license. This action cannot be undone.',
      confirmText: 'Revoke',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(licenseProvider.notifier).revokeLicense(
            licenseId: license.id,
            reason: 'Revoked by administrator',
          );

      if (mounted) {
        final state = ref.read(licenseProvider);
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('License revoked successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  // ─── Filter Chip ─────────────────────────────────────────────────────

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return ChoiceChip(
      label: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
          fontWeight: isSelected ? AppTypography.wSemiBold : null,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
