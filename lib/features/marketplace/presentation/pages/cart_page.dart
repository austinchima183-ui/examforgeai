import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/widgets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/cart_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'checkout_page.dart';
import 'marketplace_home_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SHOPPING CART PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Shopping cart page displaying all cart items, promo code input, and order
/// summary with a "Proceed to Checkout" action.
///
/// Supports swipe-to-delete with SnackBar undo, quantity controls for eligible
/// license types, and promo code validation.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => CartPage()));
/// ```
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCart());
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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

  // ─── Remove Item with Undo ────────────────────────────────────────────

  void _removeItem(CartItemEntity item) {
    final cartNotifier = ref.read(cartProvider.notifier);

    // Optimistically remove from local state
    cartNotifier.removeFromCart(cartItemId: item.id);

    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Item removed from cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Re-add the item
            cartNotifier.addToCart(
              userId: 'current_user',
              item: item,
            );
          },
        ),
      ),
    );
  }

  // ─── Apply Promo Code ─────────────────────────────────────────────────

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    await ref.read(cartProvider.notifier).applyPromoCode(code: code);
    _promoController.clear();
  }

  // ─── Navigate to Checkout ─────────────────────────────────────────────

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  // ─── Navigate to Marketplace ──────────────────────────────────────────

  void _navigateToMarketplace() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MarketplaceHomePage()),
    );
  }

  // ─── Format Currency ──────────────────────────────────────────────────

  String _formatPrice(double amount, [String currency = 'NGN']) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  // ─── Check if license type supports quantity ──────────────────────────

  bool _supportsQuantity(MarketplaceLicenseType type) {
    return type == MarketplaceLicenseType.teacher ||
        type == MarketplaceLicenseType.school ||
        type == MarketplaceLicenseType.department ||
        type == MarketplaceLicenseType.enterprise;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);

    // Listen for error/success messages
    ref.listen<CartState>(cartProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(cartProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        _showSnackBar(next.successMessage!);
        ref.read(cartProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Shopping Cart',
        actions: [
          if (state.hasItems)
            AppIconButton(
              icon: Icons.delete_sweep_outlined,
              onPressed: () async {
                final confirmed = await AppDialog.showConfirm(
                  context: context,
                  title: 'Clear Cart?',
                  message:
                      'All items will be removed from your cart. This action cannot be undone.',
                  confirmText: 'Clear All',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  ref
                      .read(cartProvider.notifier)
                      .clearCart(userId: 'current_user');
                }
              },
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: state.isLoading && !state.hasItems
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && !state.hasItems
              ? AppErrorState.serverError(onRetry: _loadCart)
              : !state.hasItems
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        // Item count badge
                        if (state.itemCount > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Spacings.lg,
                              Spacings.sm,
                              Spacings.lg,
                              0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${state.itemCount} item${state.itemCount != 1 ? 's' : ''} in cart',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Scrollable content
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadCart,
                            child: ListView(
                              padding: const EdgeInsets.all(Spacings.lg),
                              children: [
                                // ── Cart Items ──────────────────────────
                                ...state.cart!.items.map(
                                  (item) => _CartItemTile(
                                    item: item,
                                    onRemove: () => _removeItem(item),
                                    onQuantityChanged: (qty) {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateCartItem(
                                            item: item.copyWith(quantity: qty),
                                          );
                                    },
                                    supportsQuantity:
                                        _supportsQuantity(item.licenseType),
                                    formatPrice: _formatPrice,
                                  ),
                                ),

                                const SizedBox(height: Spacings.xl),

                                // ── Promo Code Section ──────────────────
                                _buildPromoSection(state),

                                const SizedBox(height: Spacings.xl),

                                // ── Order Summary ──────────────────────
                                _buildOrderSummary(state),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: state.hasItems ? _buildBottomBar(state) : null,
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Your Cart is Empty',
      subtitle: 'Browse the marketplace to find educational resources.',
      actionLabel: 'Browse Marketplace',
      onAction: _navigateToMarketplace,
    );
  }

  // ─── Promo Code Section ─────────────────────────────────────────────────

  Widget _buildPromoSection(CartState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Promo Code',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Applied promo display
          if (state.hasPromoCode) ...[
            Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: AppColors.successLight.withValues(alpha: isDark ? 0.15 : 1.0),
                borderRadius: Spacings.borderRadiusSm,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: Spacings.mdIcon,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.promoCode!.code.toUpperCase(),
                          style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: AppColors.success,
                          ),
                        ),
                        if (state.promoCode!.description != null) ...[
                          const SizedBox(height: Spacings.xs),
                          Text(
                            state.promoCode!.description!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '-${_formatPrice(state.discount)}',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: () {
                      ref.read(cartProvider.notifier).removePromoCode();
                    },
                    size: AppButtonSize.small,
                    tooltip: 'Remove promo',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Promo code input
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _promoController,
                    hint: 'Enter promo code',
                    prefixIcon: Icons.confirmation_number_outlined,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _applyPromoCode(),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                AppButton(
                  label: 'Apply',
                  onPressed: _applyPromoCode,
                  variant: AppButtonVariant.tonal,
                  isLoading: state.isApplyingPromo,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Order Summary ──────────────────────────────────────────────────────

  Widget _buildOrderSummary(CartState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final platformFee = state.subtotal * 0.05; // 5% platform fee
    final total = state.subtotal - state.discount + platformFee;

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
          _summaryRow('Subtotal', _formatPrice(state.subtotal)),
          if (state.hasPromoCode) ...[
            const SizedBox(height: Spacings.sm),
            _summaryRow(
              'Discount',
              '-${_formatPrice(state.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: Spacings.sm),
          _summaryRow('Platform Fee (5%)', _formatPrice(platformFee)),
          const Divider(height: Spacings.xl),
          _summaryRow(
            'Total',
            _formatPrice(total),
            isBold: true,
          ),
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
            fontWeight: isBold ? AppTypography.wBold : AppTypography.wRegular,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: (isBold ? tt.titleSmall : tt.bodyMedium)?.copyWith(
            fontWeight: isBold ? AppTypography.wBold : AppTypography.wMedium,
            color: valueColor ?? (isBold ? cs.onSurface : cs.onSurface),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(CartState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final platformFee = state.subtotal * 0.05;
    final total = state.subtotal - state.discount + platformFee;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatPrice(total),
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppButton(
                label: 'Proceed to Checkout',
                onPressed: _navigateToCheckout,
                variant: AppButtonVariant.elevated,
                fullWidth: true,
                icon: Icons.lock_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CART ITEM TILE (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.supportsQuantity,
    required this.formatPrice,
  });

  final CartItemEntity item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final bool supportsQuantity;
  final String Function(double, [String]) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Spacings.xl),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
          size: Spacings.lgIcon,
        ),
      ),
      child: AppCard(
        margin: const EdgeInsets.only(bottom: Spacings.md),
        padding: const EdgeInsets.all(Spacings.md),
        child: Row(
          children: [
            // ── Product type icon ─────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
                ),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Center(
                child: ProductTypeIcon(
                  type: item.product?.productType ??
                      MarketplaceProductType.other,
                  size: Spacings.mdIcon,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: Spacings.md),

            // ── Info column ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.product?.title ?? 'Product',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: context.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacings.xs),

                  // Seller name
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: Spacings.smIcon,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        item.product?.sellerId ?? 'Seller',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),

                  // License badge
                  LicenseBadge(licenseType: item.licenseType),
                ],
              ),
            ),
            const SizedBox(width: Spacings.md),

            // ── Price & controls column ───────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                PriceDisplay(
                  price: item.unitPrice,
                  currency: item.product?.currency ?? 'NGN',
                  isFree: item.product?.isFree ?? false,
                ),
                const SizedBox(height: Spacings.sm),

                // Quantity controls or remove button
                if (supportsQuantity)
                  _QuantityControl(
                    quantity: item.quantity,
                    onChanged: onQuantityChanged,
                  )
                else
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: onRemove,
                    size: AppButtonSize.small,
                    tooltip: 'Remove',
                    variant: AppIconButtonVariant.tonal,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QUANTITY CONTROL (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove_rounded, () {
            if (quantity > 1) onChanged(quantity - 1);
          }),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ),
          _qtyButton(Icons.add_rounded, () => onChanged(quantity + 1)),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: Spacings.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xs),
        child: Icon(icon, size: Spacings.mdIcon),
      ),
    );
  }
}
