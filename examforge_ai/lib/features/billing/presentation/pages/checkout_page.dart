import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/coupon_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHECKOUT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Flutterwave Standard Checkout flow.
///
/// Shows the selected plan summary, coupon code input, order total
/// with discount, and a "Pay with Flutterwave" button that
/// initialises payment and opens the checkout URL.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({
    super.key,
    this.plan,
    this.planId,
    this.billingCycle = 'monthly',
    this.email,
    this.userId,
    this.subscriberType = BillingModel.teacherSaas,
    this.schoolId,
  });

  /// The full plan object. If null, the page will load it from [planId].
  final SubscriptionPlanEntity? plan;

  /// Plan ID used to look up the plan when [plan] is not provided.
  final String? planId;

  final String billingCycle;
  final String? email;
  final String? userId;
  final BillingModel subscriberType;
  final String? schoolId;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String? _couponError;
  String? _discountPreview;
  double _discountAmount = 0;
  CouponEntity? _appliedCoupon;

  /// Resolved plan: either provided directly or loaded from planId via provider.
  SubscriptionPlanEntity? _resolvedPlan;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _resolvedPlan = widget.plan;
    } else if (widget.planId != null) {
      // Load plans from the subscription provider and resolve by ID.
      Future.microtask(() {
        ref.read(subscriptionProvider.notifier).loadPlans();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Get the resolved plan, either from widget or from the subscription provider.
  SubscriptionPlanEntity? get _plan {
    if (_resolvedPlan != null) return _resolvedPlan;
    // Try to find the plan by planId from the provider state.
    final plans = ref.read(subscriptionProvider).plans;
    if (widget.planId != null) {
      _resolvedPlan = plans.where((p) => p.id == widget.planId).firstOrNull;
    }
    return _resolvedPlan;
  }

  // ─── Computed Properties ─────────────────────────────────────────────

  double get _basePrice =>
      _plan!.priceForCycle(widget.billingCycle);

  double get _totalPrice => _basePrice - _discountAmount;

  String get _currencySymbol =>
      _plan!.currency == 'NGN' ? '\u20A6' : '\$';

  // ─── Handlers ────────────────────────────────────────────────────────

  Future<void> _applyCoupon(String code) async {
    if (code.isEmpty) return;

    await ref.read(couponProvider.notifier).validateCoupon(
          code: code,
          billingModel: widget.subscriberType,
          planId: _plan!.id,
        );

    final couponState = ref.read(couponProvider);

    if (couponState.error != null) {
      setState(() {
        _couponError = couponState.error;
        _discountPreview = null;
        _discountAmount = 0;
        _appliedCoupon = null;
      });
      return;
    }

    final coupon = couponState.validatedCoupon;
    if (coupon != null) {
      double discount = 0;
      String preview = '';

      switch (coupon.discountType) {
        case CouponDiscountType.percentage:
          final pct = coupon.discountPercent ?? 0;
          discount = _basePrice * (pct / 100);
          if (coupon.maxDiscountAmount != null &&
              discount > coupon.maxDiscountAmount!) {
            discount = coupon.maxDiscountAmount!;
          }
          preview = '${pct.toStringAsFixed(0)}% off';
        case CouponDiscountType.fixedAmount:
          discount = coupon.discountValue;
          preview = '$_currencySymbol${discount.toStringAsFixed(0)} off';
        case CouponDiscountType.freeTrial:
          discount = _basePrice;
          preview = 'Free trial for ${coupon.trialDays ?? 14} days';
        case CouponDiscountType.fixedPerSeat:
          discount = coupon.discountValue;
          preview =
              '$_currencySymbol${discount.toStringAsFixed(0)} off per seat';
      }

      setState(() {
        _couponError = null;
        _discountPreview = preview;
        _discountAmount = discount;
        _appliedCoupon = coupon;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponError = null;
      _discountPreview = null;
      _discountAmount = 0;
      _appliedCoupon = null;
    });
  }

  Future<void> _initiatePayment() async {
    if (widget.email == null || widget.userId == null) {
      _showSnackBar('Missing user information. Please try again.');
      return;
    }

    final txRef =
        'EF-${DateTime.now().millisecondsSinceEpoch}-${widget.userId!.substring(0, 8)}';

    await ref.read(paymentProvider.notifier).initializePayment(
          amount: _totalPrice,
          currency: _plan!.currency,
          email: widget.email!,
          txRef: txRef,
          planId: _plan!.id,
          couponCode: _appliedCoupon?.code,
          metadata: {
            'plan_id': _plan!.id,
            'billing_cycle': widget.billingCycle,
            'subscriber_type': widget.subscriberType.value,
            if (widget.schoolId != null) 'school_id': widget.schoolId,
          },
        );

    final paymentState = ref.read(paymentProvider);

    if (paymentState.error != null) {
      _showSnackBar(paymentState.error!);
      return;
    }

    if (paymentState.checkoutUrl != null) {
      final uri = Uri.parse(paymentState.checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showSnackBar('Could not open payment page. Please try again.');
        }
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final paymentState = ref.watch(paymentProvider);
    final couponState = ref.watch(couponProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Checkout',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Plan Summary Card ─────────────────────────────────────
            _buildPlanSummaryCard(context),

            const SizedBox(height: Spacings.xl),

            // ── Coupon Input ──────────────────────────────────────────
            CouponInputField(
              onApply: _applyCoupon,
              isLoading: couponState.isLoading,
              error: _couponError,
              discountPreview: _discountPreview,
            ),

            if (_appliedCoupon != null) ...[
              const SizedBox(height: Spacings.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _removeCoupon,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Remove coupon'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: Spacings.xl),

            // ── Order Total ───────────────────────────────────────────
            _buildOrderTotal(context, isDark),

            const SizedBox(height: Spacings.xl),

            // ── Pay Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: paymentState.isLoading
                    ? null
                    : _initiatePayment,
                icon: paymentState.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.payment_rounded, size: 20),
                label: Text(
                  paymentState.isLoading
                      ? 'Processing...'
                      : 'Pay with Flutterwave',
                ),
                style: FilledButton.styleFrom(
                  padding: Spacings.paddingButton,
                  shape: const RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: Spacings.md),

            // ── Security Note ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Payments are securely processed by Flutterwave',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Plan Summary Card ───────────────────────────────────────────────

  Widget _buildPlanSummaryCard(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

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
              children: [
                Text(
                  'Plan Summary',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            const Divider(),
            const SizedBox(height: Spacings.md),

            // Plan name
            _summaryRow(
              context,
              label: 'Plan',
              value: _plan!.name,
            ),
            const SizedBox(height: Spacings.sm),

            // Tier badge
            _summaryRow(
              context,
              label: 'Tier',
              value: _plan!.tier.label,
            ),
            const SizedBox(height: Spacings.sm),

            // Billing cycle
            _summaryRow(
              context,
              label: 'Billing',
              value: widget.billingCycle == 'annual'
                  ? 'Annual (billed yearly)'
                  : 'Monthly (billed monthly)',
            ),
            const SizedBox(height: Spacings.sm),

            // Price
            _summaryRow(
              context,
              label: 'Price',
              value: _plan!.isFree
                  ? 'Free'
                  : '$_currencySymbol${_basePrice.toStringAsFixed(0)}/${widget.billingCycle == 'annual' ? 'yr' : 'mo'}',
              isBold: true,
            ),

            if (widget.billingCycle == 'annual' &&
                _plan!.annualSavingsPercent > 0) ...[
              const SizedBox(height: Spacings.sm),
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
                  'Save ${_plan!.annualSavingsPercent.toStringAsFixed(0)}% with annual billing',
                  style: tt.labelSmall?.copyWith(
                    color: isDark ? AppColors.successDark : AppColors.success,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Order Total ─────────────────────────────────────────────────────

  Widget _buildOrderTotal(BuildContext context, bool isDark) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
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
            // Subtotal
            _totalRow(
              context,
              label: 'Subtotal',
              value: '$_currencySymbol${_basePrice.toStringAsFixed(2)}',
            ),

            // Discount
            if (_discountAmount > 0) ...[
              const SizedBox(height: Spacings.sm),
              _totalRow(
                context,
                label: 'Discount',
                value: '-$_currencySymbol${_discountAmount.toStringAsFixed(2)}',
                valueColor: AppColors.success,
              ),
            ],

            const SizedBox(height: Spacings.md),
            const Divider(),
            const SizedBox(height: Spacings.md),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  _plan!.isFree && _discountAmount >= _basePrice
                      ? 'Free'
                      : '$_currencySymbol${_totalPrice.toStringAsFixed(2)}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
            fontWeight: isBold ? AppTypography.wSemiBold : null,
          ),
        ),
      ],
    );
  }

  Widget _totalRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: valueColor ?? cs.onSurface,
            fontWeight: AppTypography.wMedium,
          ),
        ),
      ],
    );
  }
}
