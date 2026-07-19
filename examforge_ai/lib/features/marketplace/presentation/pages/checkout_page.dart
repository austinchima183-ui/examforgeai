import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'marketplace_home_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHECKOUT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Checkout page for finalizing a purchase. Reads cart state from the
/// [cartProvider] and creates an order via the [orderProvider].
///
/// Supports Card (Flutterwave), Bank Transfer, and USSD payment methods.
/// Displays a success dialog with order number upon completed payment.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage()));
/// ```
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  _PaymentMethod _selectedPayment = _PaymentMethod.card;
  bool _termsAccepted = false;
  bool _paymentSucceeded = false;
  String? _orderNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCart());
  }

  Future<void> _loadCart() async {
    await ref.read(cartProvider.notifier).loadCart(userId: 'current_user');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Format Currency ──────────────────────────────────────────────────

  String _formatPrice(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  // ─── Process Payment ──────────────────────────────────────────────────

  Future<void> _processPayment() async {
    if (!_termsAccepted) {
      _showSnackBar('Please accept the terms & conditions', isError: true);
      return;
    }

    final cartState = ref.read(cartProvider);
    if (!cartState.hasItems) return;

    final platformFee = cartState.subtotal * 0.05;
    final total = cartState.subtotal - cartState.discount + platformFee;

    // Build order entity from cart
    final order = MarketplaceOrderEntity(
      id: '',
      buyerId: 'current_user',
      sellerId: cartState.cart!.items.first.product?.sellerId ?? '',
      orderNumber: '',
      status: MarketplaceOrderStatus.pending,
      subtotal: cartState.subtotal,
      platformFee: platformFee,
      discountAmount: cartState.discount,
      totalAmount: total,
      currency: 'NGN',
      promoCodeId: cartState.promoCode?.id,
      paymentMethod: _selectedPayment.name,
      items: cartState.cart!.items.map((item) {
        return OrderItemEntity(
          id: '',
          orderId: '',
          productId: item.productId,
          sellerId: item.product?.sellerId ?? '',
          licenseType: item.licenseType,
          priceAtPurchase: item.unitPrice,
          platformFee: item.unitPrice * 0.05,
          sellerRevenue: item.unitPrice * 0.95,
          createdAt: DateTime.now(),
        );
      }).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(orderProvider.notifier).createOrder(order: order);

    final orderState = ref.read(orderProvider);
    if (orderState.error != null) {
      _showSnackBar('Payment failed: ${orderState.error}', isError: true);
    } else if (orderState.currentOrder != null) {
      setState(() {
        _paymentSucceeded = true;
        _orderNumber = orderState.currentOrder!.orderNumber.isNotEmpty
            ? orderState.currentOrder!.orderNumber
            : 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      });
    }
  }

  // ─── Navigate Home ────────────────────────────────────────────────────

  void _navigateHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);

    // Listen for error messages from order provider
    ref.listen<OrderState>(orderProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(orderProvider.notifier).clearError();
      }
    });

    // Show success dialog if payment succeeded
    if (_paymentSucceeded) {
      return _buildSuccessPage();
    }

    return Scaffold(
      appBar: AppAppBar(title: 'Checkout'),
      body: cartState.isLoading && !cartState.hasItems
          ? const Center(child: AppLoadingSpinner())
          : !cartState.hasItems
              ? AppEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Cart is Empty',
                  subtitle: 'Add items to your cart before checking out.',
                  actionLabel: 'Browse Marketplace',
                  onAction: _navigateHome,
                )
              : ListView(
                  padding: const EdgeInsets.all(Spacings.lg),
                  children: [
                    // ── Order Items (compact) ──────────────────────────
                    _buildOrderItemsSection(cartState),
                    const SizedBox(height: Spacings.xl),

                    // ── Promo Code (if not already applied) ───────────
                    if (cartState.hasPromoCode) _buildPromoApplied(cartState),
                    const SizedBox(height: Spacings.xl),

                    // ── Order Summary ─────────────────────────────────
                    _buildOrderSummary(cartState),
                    const SizedBox(height: Spacings.xl),

                    // ── Payment Method ────────────────────────────────
                    _buildPaymentMethodSection(),
                    const SizedBox(height: Spacings.xl),

                    // ── Terms & Conditions ────────────────────────────
                    _buildTermsSection(),
                    const SizedBox(height: Spacings.xl),

                    // ── Security Badges ───────────────────────────────
                    _buildSecurityBadges(),
                    const SizedBox(height: Spacings.xxl),
                  ],
                ),
      bottomNavigationBar: cartState.hasItems
          ? _buildBottomBar(orderState.isProcessingPayment)
          : null,
    );
  }

  // ─── Order Items Section ────────────────────────────────────────────────

  Widget _buildOrderItemsSection(CartState cartState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${cartState.itemCount})',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          ...cartState.cart!.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Row(
                children: [
                  ProductTypeIcon(
                    type: item.product?.productType ??
                        MarketplaceProductType.other,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      item.product?.title ?? 'Product',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  LicenseBadge(licenseType: item.licenseType),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    _formatPrice(item.lineTotal),
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Promo Applied ──────────────────────────────────────────────────────

  Widget _buildPromoApplied(CartState cartState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, size: Spacings.mdIcon, color: AppColors.success),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Text(
              '${cartState.promoCode!.code.toUpperCase()} applied',
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: AppColors.success,
              ),
            ),
          ),
          Text(
            '-${_formatPrice(cartState.discount)}',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order Summary ──────────────────────────────────────────────────────

  Widget _buildOrderSummary(CartState cartState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final platformFee = cartState.subtotal * 0.05;
    final total = cartState.subtotal - cartState.discount + platformFee;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          _summaryRow('Subtotal', _formatPrice(cartState.subtotal)),
          if (cartState.hasPromoCode) ...[
            const SizedBox(height: Spacings.sm),
            _summaryRow(
              'Discount',
              '-${_formatPrice(cartState.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: Spacings.sm),
          _summaryRow('Platform Fee (5%)', _formatPrice(platformFee)),
          const Divider(height: Spacings.xl),
          _summaryRow('Total', _formatPrice(total), isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? tt.titleSmall : tt.bodyMedium)?.copyWith(
            fontWeight:
                isBold ? AppTypography.wBold : AppTypography.wRegular,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: (isBold ? tt.titleSmall : tt.bodyMedium)?.copyWith(
            fontWeight:
                isBold ? AppTypography.wBold : AppTypography.wMedium,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Payment Method Section ─────────────────────────────────────────────

  Widget _buildPaymentMethodSection() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),
          ..._PaymentMethod.values.map(
            (method) => _PaymentMethodCard(
              method: method,
              isSelected: _selectedPayment == method,
              onSelect: () => setState(() => _selectedPayment = method),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Terms & Conditions ─────────────────────────────────────────────────

  Widget _buildTermsSection() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: cs.primary,
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            child: RichText(
              text: TextSpan(
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Security Badges ────────────────────────────────────────────────────

  Widget _buildSecurityBadges() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SecurityBadge(
          icon: Icons.lock_rounded,
          label: 'SSL Encrypted',
        ),
        const SizedBox(width: Spacings.xl),
        _SecurityBadge(
          icon: Icons.shield_rounded,
          label: 'Powered by Flutterwave',
        ),
      ],
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isProcessing) {
    final cs = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(Spacings.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: AppButton(
          label: 'Secure Checkout',
          onPressed: _processPayment,
          variant: AppButtonVariant.elevated,
          fullWidth: true,
          icon: Icons.lock_outline,
          isLoading: isProcessing,
          isDisabled: !_termsAccepted,
        ),
      ),
    );
  }

  // ─── Success Page ───────────────────────────────────────────────────────

  Widget _buildSuccessPage() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.successLight.withValues(
                      alpha: context.isDarkMode ? 0.15 : 1.0,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: Spacings.xlIcon,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: Spacings.xxl),

                Text(
                  'Payment Successful!',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.md),

                Text(
                  'Your order has been placed successfully.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.lg),

                // Order number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.md,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order Number: ',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _orderNumber ?? 'N/A',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacings.xxl),

                // Action buttons
                AppButton(
                  label: 'View Purchases',
                  onPressed: _navigateHome,
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Continue Shopping',
                  onPressed: _navigateHome,
                  variant: AppButtonVariant.outlined,
                  fullWidth: true,
                  icon: Icons.storefront_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAYMENT METHOD ENUM (internal)
// ═══════════════════════════════════════════════════════════════════════════════

enum _PaymentMethod {
  card(label: 'Card Payment', icon: Icons.credit_card_rounded, subtitle: 'Pay with Flutterwave'),
  bankTransfer(label: 'Bank Transfer', icon: Icons.account_balance_rounded, subtitle: 'Direct bank transfer'),
  ussd(label: 'USSD', icon: Icons.phone_android_rounded, subtitle: 'Pay via USSD code');

  const _PaymentMethod({
    required this.label,
    required this.icon,
    required this.subtitle,
  });

  final String label;
  final IconData icon;
  final String subtitle;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAYMENT METHOD CARD (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isSelected,
    required this.onSelect,
  });

  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacings.md),
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: Spacings.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Radio<_PaymentMethod>(
              value: method,
              groupValue: isSelected ? method : null,
              onChanged: (_) => onSelect(),
              activeColor: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),

            // Icon
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(
                method.icon,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: Spacings.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    method.subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY BADGE (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: Spacings.smIcon,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
