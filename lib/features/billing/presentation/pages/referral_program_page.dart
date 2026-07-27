import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/referral_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// REFERRAL PROGRAM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Referral program page.
///
/// Shows referral code card, stats, tracking list, and a share button.
class ReferralProgramPage extends ConsumerStatefulWidget {
  const ReferralProgramPage({
    super.key,
    this.referrerId,
    this.referrerType = BillingModel.teacherSaas,
    this.schoolId,
  });

  final String? referrerId;
  final BillingModel referrerType;
  final String? schoolId;

  @override
  ConsumerState<ReferralProgramPage> createState() =>
      _ReferralProgramPageState();
}

class _ReferralProgramPageState extends ConsumerState<ReferralProgramPage> {
  int _trackingPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (widget.referrerId == null) return;

    await Future.wait([
      ref.read(referralProvider.notifier).loadOrCreateReferralCode(
            referrerId: widget.referrerId!,
            referrerType: widget.referrerType,
            schoolId: widget.schoolId,
          ),
      ref.read(referralProvider.notifier).loadReferralTracking(
            referrerId: widget.referrerId!,
            page: _trackingPage,
            perPage: _perPage,
          ),
    ]);
  }

  Future<void> _refresh() async {
    setState(() => _trackingPage = 1);
    await _loadData();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final referralState = ref.watch(referralProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: const AppAppBar(title: 'Referral Program'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Referral Card ───────────────────────────────────────
              if (referralState.referralCode != null)
                ReferralCard(
                  referralCode: referralState.referralCode!,
                  onCopyCode: () {
                    Clipboard.setData(
                      ClipboardData(text: referralState.referralCode!.code),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Referral code copied!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onShareCode: () {
                    _shareReferralCode(referralState.referralCode!.code);
                  },
                )
              else if (referralState.isLoading)
                const Center(
                  child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                )
              else if (referralState.error != null)
                AppErrorState.genericError(
                  message: referralState.error,
                  onRetry: _refresh,
                ),

              const SizedBox(height: Spacings.xl),

              // ── Stats Section ───────────────────────────────────────
              _buildStatsSection(referralState),

              const SizedBox(height: Spacings.xl),

              // ── Referral Tracking List ──────────────────────────────
              _buildTrackingList(referralState),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats Section ───────────────────────────────────────────────────

  Widget _buildStatsSection(ReferralState referralState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final totalReferrals = referralState.referralCode?.totalReferrals ?? 0;
    final successful = referralState.referralCode?.successfulReferrals ?? 0;
    final rewardsEarned = referralState.referralCode?.totalRewardsEarned ?? 0;
    final rewardType = referralState.referralCode?.rewardType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            _buildStatCard(
              context,
              icon: Icons.people_outline_rounded,
              label: 'Total Referrals',
              value: '$totalReferrals',
              color: AppColors.info,
            ),
            const SizedBox(width: Spacings.md),
            _buildStatCard(
              context,
              icon: Icons.check_circle_outline_rounded,
              label: 'Successful',
              value: '$successful',
              color: AppColors.success,
            ),
            const SizedBox(width: Spacings.md),
            _buildStatCard(
              context,
              icon: Icons.stars_rounded,
              label: 'Rewards Earned',
              value: _formatRewardValue(rewardsEarned, rewardType),
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Expanded(
      child: Card(
        elevation: Spacings.elevationSm,
        shadowColor: cs.shadow.withValues(alpha: 0.06),
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                value,
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tracking List ───────────────────────────────────────────────────

  Widget _buildTrackingList(ReferralState referralState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Tracking',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),

        if (referralState.referralTracking.isEmpty)
          AppEmptyState.noData(
            title: 'No Referrals Yet',
            subtitle: 'Share your referral code to start earning rewards!',
          )
        else
          ...referralState.referralTracking.map(
            (referral) => _buildReferralTile(context, referral),
          ),
      ],
    );
  }

  Widget _buildReferralTile(BuildContext context, Map<String, dynamic> referral) {
    // ReferralEntity doesn't exist in billing_entities.dart directly,
    // but the provider returns it. We'll use a generic approach.
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationNone,
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.success,
            size: Spacings.mdIcon - 4,
          ),
        ),
        title: Text(
          'Referral',
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wMedium,
            color: cs.onSurface,
          ),
        ),
        subtitle: Text(
          'Tracked',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _shareReferralCode(String code) {
    // In production, use the share_plus package or similar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share referral code: $code'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRewardValue(double value, ReferralRewardType? type) {
    if (type == null) return value.toStringAsFixed(0);
    switch (type) {
      case ReferralRewardType.creditDays:
        return '${value.toInt()} days';
      case ReferralRewardType.aiCredits:
        return '${value.toInt()} credits';
      case ReferralRewardType.percentageDiscount:
        return '${value.toStringAsFixed(0)}%';
      case ReferralRewardType.fixedCredit:
        return value.toStringAsFixed(0);
    }
  }
}
