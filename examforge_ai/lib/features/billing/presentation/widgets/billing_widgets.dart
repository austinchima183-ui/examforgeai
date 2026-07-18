import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/billing_entities.dart';

// ============================================================================
// 1. PLAN CARD
// ============================================================================

/// Displays a subscription plan with pricing, features, and selection state.
///
/// Shows the plan name, a tier badge, price for the chosen billing cycle,
/// a list of features, a "Most Popular" badge when [SubscriptionPlanEntity.isPopular]
/// is true, and either a select or current-plan button at the bottom.
///
/// The card gets a coloured border when [isSelected] is true.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.isCurrentPlan = false,
    this.billingCycle = 'monthly',
    this.onSelect,
  });

  final SubscriptionPlanEntity plan;
  final bool isSelected;
  final bool isCurrentPlan;
  final String billingCycle;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final price = plan.priceForCycle(billingCycle);

    return Card(
      elevation: isSelected ? Spacings.elevationMd : Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: isSelected
            ? BorderSide(color: cs.primary, width: 2)
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row: Name + Tier Badge ────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    PlanTierBadge(tier: plan.tier),
                  ],
                ),
                const SizedBox(height: Spacings.sm),

                // ── Description ───────────────────────────────────────
                if (plan.description != null) ...[
                  Text(
                    plan.description!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.md),
                ],

                // ── Price ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.isFree
                          ? 'Free'
                          : _formatCurrency(price, plan.currency),
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.onSurface,
                        height: 1.0,
                      ),
                    ),
                    if (!plan.isFree) ...[
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '/${billingCycle == 'annual' ? 'yr' : 'mo'}',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Annual savings ─────────────────────────────────────
                if (billingCycle == 'annual' &&
                    plan.annualSavingsPercent > 0) ...[
                  const SizedBox(height: Spacings.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text(
                      'Save ${plan.annualSavingsPercent.toStringAsFixed(0)}%',
                      style: tt.labelSmall?.copyWith(
                        color: isDark ? AppColors.successDark : AppColors.success,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: Spacings.lg),

                // ── Features List ─────────────────────────────────────
                ...plan.featuresList.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: Spacings.mdIcon - 4,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: Spacings.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: Spacings.lg),

                // ── CTA Button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: isCurrentPlan
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: Spacings.paddingButton,
                            shape: RoundedRectangleBorder(
                              borderRadius: Spacings.borderRadiusMd,
                            ),
                          ),
                          child: const Text('Current Plan'),
                        )
                      : FilledButton(
                          onPressed: onSelect,
                          style: FilledButton.styleFrom(
                            padding: Spacings.paddingButton,
                            shape: RoundedRectangleBorder(
                              borderRadius: Spacings.borderRadiusMd,
                            ),
                            backgroundColor:
                                isSelected ? cs.primary : cs.surface,
                            foregroundColor:
                                isSelected ? cs.onPrimary : cs.primary,
                          ),
                          child: Text(isSelected ? 'Selected' : 'Select Plan'),
                        ),
                ),
              ],
            ),
          ),

          // ── "Most Popular" Badge ────────────────────────────────────
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(Spacings.mdRadius),
                  ),
                ),
                child: Text(
                  'Most Popular',
                  style: tt.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = currency == 'NGN' ? '\u20A6' : '\$';
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}

// ============================================================================
// 2. CREDIT BALANCE CARD
// ============================================================================

/// Shows AI credit balance with a circular progress ring.
///
/// Displays remaining / total credits, a circular progress indicator
/// representing usage percentage, and a "Purchase More" button when credits
/// are running low.
class CreditBalanceCard extends StatelessWidget {
  const CreditBalanceCard({
    super.key,
    required this.balance,
    this.onPurchaseMore,
  });

  final AiCreditBalanceEntity balance;
  final VoidCallback? onPurchaseMore;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final usagePercent = balance.usagePercent;
    final remainingPercent = 100 - usagePercent;

    // Choose colour based on credit health
    final Color progressColor;
    if (balance.isExhausted) {
      progressColor = AppColors.error;
    } else if (balance.isLow) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          children: [
            // ── Top Row: Progress Ring + Info ────────────────────────
            Row(
              children: [
                // Circular progress ring
                SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: balance.totalCredits > 0
                            ? remainingPercent / 100
                            : 0,
                        strokeWidth: 6,
                        backgroundColor:
                            progressColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        valueColor: AlwaysStoppedAnimation(progressColor),
                        strokeCap: StrokeCap.round,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${remainingPercent.toStringAsFixed(0)}%',
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wBold,
                              color: cs.onSurface,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'remaining',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacings.lg),

                // Credit numbers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Credits',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacings.sm),
                      Text(
                        '${balance.remainingCredits} / ${balance.totalCredits}',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${balance.usedCredits} used this cycle',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Warning / Exhausted indicator ─────────────────────────
            if (balance.isExhausted || balance.isLow) ...[
              const SizedBox(height: Spacings.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: (balance.isExhausted ? AppColors.error : AppColors.warning)
                      .withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Row(
                  children: [
                    Icon(
                      balance.isExhausted
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: Spacings.mdIcon,
                      color: balance.isExhausted
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        balance.isExhausted
                            ? 'Credits exhausted. Purchase more to continue using AI features.'
                            : 'Credits running low. Consider purchasing more.',
                        style: tt.bodySmall?.copyWith(
                          color: balance.isExhausted
                              ? (isDark ? AppColors.errorDark : AppColors.error)
                              : (isDark ? AppColors.warningDark : AppColors.warning),
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Purchase More Button ──────────────────────────────────
            if (onPurchaseMore != null) ...[
              const SizedBox(height: Spacings.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPurchaseMore,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Purchase More Credits'),
                  style: OutlinedButton.styleFrom(
                    padding: Spacings.paddingButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: Spacings.borderRadiusMd,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TRANSACTION LIST TILE
// ============================================================================

/// Displays a transaction in a list.
///
/// Shows the amount, a status badge with colour coding, date,
/// payment method, a channel icon, and an arrow indicator.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final TransactionEntity transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _parseHexColor(transaction.status.color);
    final channelIcon = _channelIcon(transaction.channel);
    final isSuccessful = transaction.isSuccessful;
    final isRefund = transaction.status == TransactionStatus.refunded ||
        transaction.status == TransactionStatus.partiallyRefunded;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isRefund ? AppColors.info : (isSuccessful ? AppColors.success : statusColor))
              .withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Icon(
          isRefund ? Icons.replay_rounded : channelIcon,
          color: isRefund ? AppColors.info : (isSuccessful ? AppColors.success : statusColor),
          size: Spacings.mdIcon - 4,
        ),
      ),
      title: Row(
        children: [
          Text(
            _formatCurrency(
              isRefund ? transaction.refundAmount : transaction.amount,
              transaction.currency,
            ),
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          _TransactionStatusBadge(status: transaction.status),
        ],
      ),
      subtitle: Text(
        _formatDate(transaction.initiatedAt),
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (transaction.paymentMethodSummary != null)
            Flexible(
              child: Text(
                transaction.paymentMethodSummary!,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: Spacings.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: Spacings.lgIcon,
              color: cs.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }

  IconData _channelIcon(PaymentChannel channel) {
    switch (channel) {
      case PaymentChannel.card:
        return Icons.credit_card_rounded;
      case PaymentChannel.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentChannel.ussd:
        return Icons.phone_android_rounded;
      case PaymentChannel.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentChannel.qrCode:
        return Icons.qr_code_rounded;
      case PaymentChannel.credit:
        return Icons.auto_awesome_rounded;
      case PaymentChannel.coupon:
        return Icons.confirmation_number_rounded;
      case PaymentChannel.refund:
        return Icons.replay_rounded;
    }
  }
}

/// Private helper badge for transaction status inside the tile.
class _TransactionStatusBadge extends StatelessWidget {
  const _TransactionStatusBadge({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _parseHexColor(status.color);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: isDark
              ? _lightenColor(color)
              : _darkenColor(color),
          fontWeight: AppTypography.wSemiBold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================================================
// 4. INVOICE CARD
// ============================================================================

/// Displays an invoice summary.
///
/// Shows invoice number, total amount, status badge, issue date,
/// due date (with an overdue indicator when applicable), and a download
/// PDF button.
class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onDownloadPdf,
  });

  final InvoiceEntity invoice;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final isOverdue = invoice.isOverdue;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: isOverdue
            ? BorderSide(color: AppColors.error.withValues(alpha: 0.5))
            : BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row: Invoice Number + Status Badge ─────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  _InvoiceStatusBadge(status: invoice.invoiceType),
                ],
              ),
              const SizedBox(height: Spacings.md),

              // ── Amount ─────────────────────────────────────────────
              Text(
                _formatCurrency(invoice.totalAmount, invoice.currency),
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.md),

              // ── Dates Row ──────────────────────────────────────────
              Row(
                children: [
                  // Issue date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issued',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          _formatDate(invoice.issueDate),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Due date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Due',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (isOverdue) ...[
                              const SizedBox(width: Spacings.xs),
                              Icon(
                                Icons.error_rounded,
                                size: 12,
                                color: AppColors.error,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          _formatDate(invoice.dueDate),
                          style: tt.bodySmall?.copyWith(
                            color: isOverdue ? AppColors.error : cs.onSurface,
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Overdue banner ──────────────────────────────────────
              if (isOverdue) ...[
                const SizedBox(height: Spacings.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error
                        .withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: isDark ? AppColors.errorDark : AppColors.error,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Overdue',
                        style: tt.labelSmall?.copyWith(
                          color: isDark ? AppColors.errorDark : AppColors.error,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Actions Row ─────────────────────────────────────────
              if (onDownloadPdf != null) ...[
                const SizedBox(height: Spacings.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDownloadPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Download PDF'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.md,
                          vertical: Spacings.sm,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Private status badge for invoices.
class _InvoiceStatusBadge extends StatelessWidget {
  const _InvoiceStatusBadge({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppColors.success;
        break;
      case InvoiceStatus.overdue:
        color = AppColors.error;
        break;
      case InvoiceStatus.issued:
        color = AppColors.info;
        break;
      case InvoiceStatus.draft:
        color = AppColors.warning;
        break;
      case InvoiceStatus.cancelled:
      case InvoiceStatus.void_:
        color = const Color(0xFF6B7280);
        break;
      case InvoiceStatus.partiallyPaid:
        color = const Color(0xFFF97316);
        break;
      case InvoiceStatus.creditNote:
        color = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: isDark ? _lightenColor(color) : _darkenColor(color),
          fontWeight: AppTypography.wSemiBold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================================================
// 5. COUPON INPUT FIELD
// ============================================================================

/// Input field for coupon codes with validation.
///
/// Provides a text field with an "Apply" button, and shows either an error
/// message or a discount preview below the field.
class CouponInputField extends StatefulWidget {
  const CouponInputField({
    super.key,
    this.onApply,
    this.isLoading = false,
    this.error,
    this.discountPreview,
  });

  final Function(String)? onApply;
  final bool isLoading;
  final String? error;
  final String? discountPreview;

  @override
  State<CouponInputField> createState() => _CouponInputFieldState();
}

class _CouponInputFieldState extends State<CouponInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleApply() {
    final code = _controller.text.trim();
    if (code.isNotEmpty && widget.onApply != null) {
      widget.onApply!(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ────────────────────────────────────────────────────
        Text(
          'Have a coupon code?',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),

        // ── Input Row ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _handleApply(),
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                    borderSide: BorderSide(
                      color: cs.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                    borderSide: BorderSide(
                      color: cs.outlineVariant,
                    ),
                  ),
                  errorBorder: widget.error != null
                      ? OutlineInputBorder(
                          borderRadius: Spacings.borderRadiusMd,
                          borderSide: BorderSide(color: AppColors.error),
                        )
                      : null,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                  UpperCaseTextFormatter(),
                ],
              ),
            ),
            const SizedBox(width: Spacings.sm),
            FilledButton(
              onPressed: widget.isLoading ? null : _handleApply,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xl,
                  vertical: Spacings.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Text('Apply'),
            ),
          ],
        ),

        // ── Error Message ────────────────────────────────────────────
        if (widget.error != null) ...[
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: Spacings.xs),
              Expanded(
                child: Text(
                  widget.error!,
                  style: tt.bodySmall?.copyWith(
                    color: isDark ? AppColors.errorDark : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],

        // ── Discount Preview ─────────────────────────────────────────
        if (widget.discountPreview != null) ...[
          const SizedBox(height: Spacings.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: AppColors.success
                  .withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: Spacings.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    widget.discountPreview!,
                    style: tt.bodySmall?.copyWith(
                      color: isDark ? AppColors.successDark : AppColors.success,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Helper input formatter that converts text to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ============================================================================
// 6. REFERRAL CARD
// ============================================================================

/// Displays referral code and statistics.
///
/// Shows the referral code in a styled box, total/successful referrals,
/// rewards earned, and copy/share action buttons.
class ReferralCard extends StatelessWidget {
  const ReferralCard({
    super.key,
    required this.referralCode,
    this.onCopyCode,
    this.onShareCode,
  });

  final ReferralCodeEntity referralCode;
  final VoidCallback? onCopyCode;
  final VoidCallback? onShareCode;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ─────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: cs.primary,
                  size: Spacings.mdIcon,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Refer & Earn',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.lg),

            // ── Referral Code Box ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: Spacings.borderRadiusMd,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    referralCode.code,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.primary,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  IconButton(
                    onPressed: onCopyCode,
                    icon: Icon(
                      Icons.copy_rounded,
                      color: cs.primary,
                      size: Spacings.mdIcon,
                    ),
                    tooltip: 'Copy code',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.primary.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(Spacings.sm),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacings.lg),

            // ── Stats Row ────────────────────────────────────────────
            Row(
              children: [
                _referralStat(
                  context,
                  label: 'Total Referrals',
                  value: '${referralCode.totalReferrals}',
                  icon: Icons.people_outline_rounded,
                ),
                const SizedBox(width: Spacings.lg),
                _referralStat(
                  context,
                  label: 'Successful',
                  value: '${referralCode.successfulReferrals}',
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(width: Spacings.lg),
                _referralStat(
                  context,
                  label: 'Rewards Earned',
                  value: _formatRewardValue(),
                  icon: Icons.stars_rounded,
                ),
              ],
            ),

            // ── Share Button ──────────────────────────────────────────
            if (onShareCode != null) ...[
              const SizedBox(height: Spacings.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onShareCode,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Referral Link'),
                  style: FilledButton.styleFrom(
                    padding: Spacings.paddingButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: Spacings.borderRadiusMd,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _referralStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: Spacings.mdIcon - 4,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            value,
            style: tt.titleMedium?.copyWith(
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
    );
  }

  String _formatRewardValue() {
    if (referralCode.rewardType == ReferralRewardType.creditDays) {
      return '${referralCode.rewardValue.toInt()} days';
    }
    if (referralCode.rewardType == ReferralRewardType.aiCredits) {
      return '${referralCode.rewardValue.toInt()} credits';
    }
    return referralCode.rewardValue.toStringAsFixed(0);
  }
}

// ============================================================================
// 7. LICENSE CARD
// ============================================================================

/// Displays license information.
///
/// Shows the license type, a masked key, seats used/total, expiry date,
/// a status badge, and an optional revoke button.
class LicenseCard extends StatelessWidget {
  const LicenseCard({
    super.key,
    required this.license,
    this.onRevoke,
  });

  final LicenseEntity license;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final isExpired = license.isExpired;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: isExpired
              ? AppColors.error.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: License Type + Status ────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Icon(
                    Icons.vpn_key_rounded,
                    size: Spacings.mdIcon - 4,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    '${license.licenseType.label} License',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                _LicenseStatusBadge(license: license),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ── Masked Key ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Text(
                _maskKey(license.licenseKey),
                style: tt.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: Spacings.md),

            // ── Details Grid ─────────────────────────────────────────
            Row(
              children: [
                // Seats
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
                      Row(
                        children: [
                          Text(
                            '${license.seatsUsed}',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: AppTypography.wBold,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            ' / ${license.seatsTotal}',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                      ClipRRect(
                        borderRadius: Spacings.borderRadiusFull,
                        child: LinearProgressIndicator(
                          value: license.seatsTotal > 0
                              ? license.seatsUsed / license.seatsTotal
                              : 0,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            license.seatsUsed >= license.seatsTotal
                                ? AppColors.error
                                : cs.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacings.xl),

                // Expiry
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expires',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        _formatDate(license.expiresAt),
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wMedium,
                          color: isExpired ? AppColors.error : cs.onSurface,
                        ),
                      ),
                      if (!isExpired && license.daysUntilExpiry <= 30) ...[
                        const SizedBox(height: Spacings.xs),
                        Text(
                          '${license.daysUntilExpiry} days left',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ── Revoke Button ────────────────────────────────────────
            if (onRevoke != null && license.isActive && !isExpired) ...[
              const SizedBox(height: Spacings.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Revoke'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.md,
                        vertical: Spacings.sm,
                      ),
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

  String _maskKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }
}

/// Private badge for license status.
class _LicenseStatusBadge extends StatelessWidget {
  const _LicenseStatusBadge({required this.license});

  final LicenseEntity license;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final Color color;
    final String label;

    if (!license.isActive) {
      color = const Color(0xFF6B7280);
      label = 'Revoked';
    } else if (license.isExpired) {
      color = AppColors.error;
      label = 'Expired';
    } else if (license.daysUntilExpiry <= 30) {
      color = AppColors.warning;
      label = 'Expiring Soon';
    } else {
      color = AppColors.success;
      label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: isDark ? _lightenColor(color) : _darkenColor(color),
          fontWeight: AppTypography.wSemiBold,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ============================================================================
// 8. REVENUE METRIC CARD
// ============================================================================

/// Displays a single revenue metric.
///
/// Shows an icon, title, large value, subtitle, and an optional trend
/// indicator (positive or negative percentage).
class RevenueMetricCard extends StatelessWidget {
  const RevenueMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.trend,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final effectiveColor = color ?? cs.primary;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon + Title Row ──────────────────────────────────────
            Row(
              children: [
                if (icon != null)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: effectiveColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: Spacings.mdIcon - 4,
                      color: effectiveColor,
                    ),
                  ),
                if (icon != null) const SizedBox(width: Spacings.md),
                Expanded(
                  child: Text(
                    title,
                    style: tt.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ── Value + Trend Row ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trend != null) _TrendIndicator(trend: trend!),
              ],
            ),

            // ── Subtitle ─────────────────────────────────────────────
            if (subtitle != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                subtitle!,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Private trend indicator chip.
class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.trend});

  final double trend;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isPositive = trend >= 0;
    final color =
        isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
            style: context.textTheme.labelSmall?.copyWith(
              color: isDark ? _lightenColor(color) : _darkenColor(color),
              fontWeight: AppTypography.wSemiBold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. BILLING MODEL SELECTOR
// ============================================================================

/// Tab selector for Teacher / School / Enterprise billing models.
///
/// Displays three segmented tabs that map to [BillingModel] values.
class BillingModelSelector extends StatelessWidget {
  const BillingModelSelector({
    super.key,
    required this.selectedModel,
    this.onChanged,
  });

  final BillingModel selectedModel;
  final ValueChanged<BillingModel>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return SegmentedButton<BillingModel>(
      segments: [
        ButtonSegment<BillingModel>(
          value: BillingModel.teacherSaas,
          label: const Text('Teacher'),
          icon: const Icon(Icons.person_rounded, size: 18),
          tooltip: 'Teacher SaaS',
        ),
        ButtonSegment<BillingModel>(
          value: BillingModel.schoolSaas,
          label: const Text('School'),
          icon: const Icon(Icons.school_rounded, size: 18),
          tooltip: 'School SaaS',
        ),
        ButtonSegment<BillingModel>(
          value: BillingModel.enterpriseSaas,
          label: const Text('Enterprise'),
          icon: const Icon(Icons.business_rounded, size: 18),
          tooltip: 'Enterprise SaaS',
        ),
      ],
      selected: {selectedModel},
      onSelectionChanged: (selection) {
        if (onChanged != null && selection.isNotEmpty) {
          onChanged!(selection.first);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.comfortable,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: Spacings.borderRadiusMd,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          AppTypography.buttonSmall.copyWith(fontFamily: AppTypography.fontFamily),
        ),
      ),
    );
  }
}

// ============================================================================
// 10. SUBSCRIPTION STATUS BADGE
// ============================================================================

/// Small coloured badge showing the subscription status label.
class SubscriptionStatusBadge extends StatelessWidget {
  const SubscriptionStatusBadge({super.key, required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _parseHexColor(status.color);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: isDark ? _lightenColor(color) : _darkenColor(color),
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

// ============================================================================
// 11. PLAN TIER BADGE
// ============================================================================

/// Small coloured badge showing the plan tier label.
///
/// Tier colours follow the [PlanTier.color] hex values defined in
/// the billing entities.
class PlanTierBadge extends StatelessWidget {
  const PlanTierBadge({super.key, required this.tier});

  final PlanTier tier;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _parseHexColor(tier.color);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        tier.label,
        style: context.textTheme.labelSmall?.copyWith(
          color: isDark ? _lightenColor(color) : _darkenColor(color),
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

// ============================================================================
// 12. CREDIT PACK CARD
// ============================================================================

/// Displays a purchasable AI credit pack.
///
/// Shows the pack name, credit count, price, price per credit,
/// and a "Buy" button.
class CreditPackCard extends StatelessWidget {
  const CreditPackCard({
    super.key,
    required this.pack,
    this.onPurchase,
  });

  final AiCreditPackEntity pack;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Icon + Name ──────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.coolGradient,
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: Spacings.mdIcon - 4,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${pack.credits} AI Credits',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Description ──────────────────────────────────────────
            if (pack.description != null) ...[
              const SizedBox(height: Spacings.sm),
              Text(
                pack.description!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: Spacings.lg),

            // ── Pricing ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatCurrency(pack.price, pack.currency),
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  '${_formatCurrency(pack.pricePerCredit, pack.currency)}/credit',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // ── Validity ─────────────────────────────────────────────
            if (pack.validityDays < 365) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                'Valid for ${pack.validityDays} days',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: Spacings.lg),

            // ── Buy Button ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPurchase,
                style: FilledButton.styleFrom(
                  padding: Spacings.paddingButton,
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                ),
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED UTILITIES
// ============================================================================

/// Parses a hex colour string (e.g. '#EF4444') into a [Color].
Color _parseHexColor(String hex) {
  final hexValue = hex.replaceFirst('#', '');
  return Color(int.parse('FF$hexValue', radix: 16));
}

/// Returns a darker variant of [color] for text on light backgrounds.
Color _darkenColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
}

/// Returns a lighter variant of [color] for text on dark backgrounds.
Color _lightenColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
}

/// Formats a date as 'dd MMM yyyy' (e.g. '12 Mar 2025').
String _formatDate(DateTime date) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}

/// Formats an amount with the appropriate currency symbol.
String _formatCurrency(double amount, String currency) {
  final symbol = currency == 'NGN' ? '\u20A6' : '\$';
  if (amount == amount.roundToDouble()) {
    return '$symbol${amount.toStringAsFixed(0)}';
  }
  return '$symbol${amount.toStringAsFixed(2)}';
}
