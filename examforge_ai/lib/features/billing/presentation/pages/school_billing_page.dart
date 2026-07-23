import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/invoice_provider.dart';
import '../providers/school_billing_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL BILLING PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School billing management page.
///
/// Shows subscription overview, usage metrics, billing contacts,
/// payment methods, renewal settings, and recent invoices.
class SchoolBillingPage extends ConsumerStatefulWidget {
  const SchoolBillingPage({
    super.key,
    required this.schoolId,
    this.subscriberId,
  });

  final String schoolId;
  final String? subscriberId;

  @override
  ConsumerState<SchoolBillingPage> createState() =>
      _SchoolBillingPageState();
}

class _SchoolBillingPageState extends ConsumerState<SchoolBillingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(schoolBillingProvider.notifier).loadBillingProfile(
            schoolId: widget.schoolId,
          ),
      if (widget.subscriberId != null)
        ref.read(subscriptionProvider.notifier).loadCurrentSubscription(
              subscriberId: widget.subscriberId!,
              subscriberType: BillingModel.schoolSaas,
            ),
      ref.read(invoiceProvider.notifier).loadInvoices(
            schoolId: widget.schoolId,
            page: 1,
            perPage: 5,
          ),
    ]);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(schoolBillingProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final invoiceState = ref.watch(invoiceProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'School Billing'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Current Subscription Overview ───────────────────────
              _buildSubscriptionOverview(subscriptionState),

              const SizedBox(height: Spacings.xl),

              // ── Usage Metrics ───────────────────────────────────────
              _buildUsageMetrics(billingState, subscriptionState),

              const SizedBox(height: Spacings.xl),

              // ── Billing Contacts ────────────────────────────────────
              _buildBillingContacts(billingState),

              const SizedBox(height: Spacings.xl),

              // ── Payment Methods ─────────────────────────────────────
              _buildPaymentMethods(billingState),

              const SizedBox(height: Spacings.xl),

              // ── Renewal Settings ────────────────────────────────────
              _buildRenewalSettings(billingState),

              const SizedBox(height: Spacings.xl),

              // ── Recent Invoices ─────────────────────────────────────
              _buildRecentInvoices(invoiceState),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Subscription Overview ───────────────────────────────────────────

  Widget _buildSubscriptionOverview(SubscriptionState subscriptionState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final subscription = subscriptionState.subscription;

    if (subscriptionState.isLoading && subscription == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(Spacings.xl),
          child: Center(child: AppLoadingSpinner()),
        ),
      );
    }

    if (subscription == null) {
      return Card(
        elevation: Spacings.elevationSm,
        shadowColor: cs.shadow.withValues(alpha: 0.06),
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: Spacings.lgIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: Spacings.md),
              Text(
                'No Active Subscription',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                'Subscribe to a plan to unlock all features.',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.lg),
              FilledButton(
                onPressed: () {
                  // TODO: navigate to subscription plans
                },
                style: FilledButton.styleFrom(
                  padding: Spacings.paddingButton,
                  shape: const RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                ),
                child: const Text('View Plans'),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _parseHexColor(subscription.status.color);
    final symbol = subscription.currency == 'NGN' ? '\u20A6' : '\$';

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: const RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Subscription',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                SubscriptionStatusBadge(status: subscription.status),
              ],
            ),
            const SizedBox(height: Spacings.md),

            if (subscription.plan != null) ...[
              Text(
                subscription.plan!.name,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),
            ],

            Text(
              '$symbol${subscription.priceAtSubscription.toStringAsFixed(0)}/${subscription.billingCycle == 'annual' ? 'yr' : 'mo'}',
              style: tt.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.md),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${_formatDate(subscription.currentPeriodStart)} - ${_formatDate(subscription.currentPeriodEnd)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days Remaining',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${subscription.daysRemaining} days',
                        style: tt.bodySmall?.copyWith(
                          color: subscription.daysRemaining <= 7
                              ? AppColors.warning
                              : cs.onSurface,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (subscription.seatsPurchased > 1) ...[
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seats',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          '${subscription.seatsUsed} / ${subscription.seatsPurchased}',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: AppTypography.wMedium,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Renew',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          subscription.autoRenew ? 'Enabled' : 'Disabled',
                          style: tt.bodySmall?.copyWith(
                            fontWeight: AppTypography.wMedium,
                            color: subscription.autoRenew
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Usage Metrics ───────────────────────────────────────────────────

  Widget _buildUsageMetrics(
    SchoolBillingState billingState,
    SubscriptionState subscriptionState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final profile = billingState.billingProfile;
    final plan = subscriptionState.subscription?.plan;

    final students = profile?.currentStudentCount ?? 0;
    final maxStudents = plan?.maxStudents ?? 0;
    final teachers = profile?.currentTeacherCount ?? 0;
    final maxTeachers = plan?.maxTeachers ?? 0;
    final storageMb = profile?.currentStorageUsedMb ?? 0;
    final maxStorageMb = plan?.maxStorageMb ?? 0;
    final aiCredits = profile?.currentAiCreditsUsed ?? 0;
    final maxAiCredits = plan?.aiCreditsMonthly ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Metrics',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: _usageMetricCard(
                context,
                icon: Icons.people_rounded,
                label: 'Students',
                current: students,
                max: maxStudents,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: _usageMetricCard(
                context,
                icon: Icons.school_rounded,
                label: 'Teachers',
                current: teachers,
                max: maxTeachers,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: _usageMetricCard(
                context,
                icon: Icons.storage_rounded,
                label: 'Storage (MB)',
                current: storageMb.toInt(),
                max: maxStorageMb,
                color: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: _usageMetricCard(
                context,
                icon: Icons.auto_awesome_rounded,
                label: 'AI Credits',
                current: aiCredits,
                max: maxAiCredits,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _usageMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final percent = max > 0 ? current / max : 0.0;
    final isOverLimit = max > 0 && current > max;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              max > 0 ? '$current / $max' : '$current',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wBold,
                color: isOverLimit ? AppColors.error : cs.onSurface,
              ),
            ),
            if (max > 0) ...[
              const SizedBox(height: Spacings.xs),
              ClipRRect(
                borderRadius: Spacings.borderRadiusFull,
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    isOverLimit ? AppColors.error : color,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Billing Contacts ────────────────────────────────────────────────

  Widget _buildBillingContacts(SchoolBillingState billingState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final profile = billingState.billingProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Billing Contacts',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: edit billing contacts
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        Card(
          elevation: Spacings.elevationNone,
          shape: RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusLg,
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: profile == null || profile.billingContactName == null
                ? Center(
                    child: Text(
                      'No billing contacts configured',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _contactRow(
                        Icons.person_outline_rounded,
                        profile.billingContactName ?? 'N/A',
                      ),
                      if (profile.billingContactEmail != null) ...[
                        const SizedBox(height: Spacings.sm),
                        _contactRow(
                          Icons.email_outlined,
                          profile.billingContactEmail!,
                        ),
                      ],
                      if (profile.billingContactPhone != null) ...[
                        const SizedBox(height: Spacings.sm),
                        _contactRow(
                          Icons.phone_outlined,
                          profile.billingContactPhone!,
                        ),
                      ],
                      if (profile.billingAddress != null) ...[
                        const SizedBox(height: Spacings.sm),
                        _contactRow(
                          Icons.location_on_outlined,
                          profile.billingAddress!,
                        ),
                      ],
                      if (profile.taxIdNumber != null) ...[
                        const SizedBox(height: Spacings.sm),
                        _contactRow(
                          Icons.receipt_long_outlined,
                          'Tax ID: ${profile.taxIdNumber!}',
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String value) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: Text(
            value,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Payment Methods ─────────────────────────────────────────────────

  Widget _buildPaymentMethods(SchoolBillingState billingState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final profile = billingState.billingProfile;

    final paymentMethods = profile?.paymentMethods ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: add payment method
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        if (paymentMethods.isEmpty)
          Card(
            elevation: Spacings.elevationNone,
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusLg,
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Center(
                child: Text(
                  'No payment methods on file',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...paymentMethods.map(
            (method) => Card(
              elevation: Spacings.elevationNone,
              margin: const EdgeInsets.only(bottom: Spacings.sm),
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  method['type'] == 'card'
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_rounded,
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
                title: Text(
                  method['label'] ?? 'Payment Method',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: method['last4'] != null
                    ? Text(
                        '****${method['last4']}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: method['is_default'] == true
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          'Default',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: AppTypography.wSemiBold,
                            fontSize: 10,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Renewal Settings ────────────────────────────────────────────────

  Widget _buildRenewalSettings(SchoolBillingState billingState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final profile = billingState.billingProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Renewal Settings',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Card(
          elevation: Spacings.elevationNone,
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
                SwitchListTile.adaptive(
                  value: profile?.autoRenew ?? true,
                  onChanged: (value) {
                    // TODO: toggle auto-renew
                  },
                  title: Text(
                    'Auto-Renew',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically renew subscription at end of period',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Renewal Reminder',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${profile?.renewalReminderDays ?? 14} days before expiry',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () {
                    // TODO: configure reminder days
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Recent Invoices ─────────────────────────────────────────────────

  Widget _buildRecentInvoices(InvoiceState invoiceState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Invoices',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: navigate to full invoice history
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        if (invoiceState.isLoading && invoiceState.invoices.isEmpty)
          const Center(child: AppLoadingSpinner())
        else if (invoiceState.invoices.isEmpty)
          Card(
            elevation: Spacings.elevationNone,
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusLg,
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Center(
                child: Text(
                  'No invoices yet',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...invoiceState.invoices.take(5).map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.md),
                  child: InvoiceCard(
                    invoice: invoice,
                    onTap: () {
                      // TODO: navigate to invoice detail
                    },
                    onDownloadPdf: () {
                      ref
                          .read(invoiceProvider.notifier)
                          .getPdfUrl(invoiceId: invoice.id);
                    },
                  ),
                ),
              ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Color _parseHexColor(String hex) {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexValue', radix: 16));
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
