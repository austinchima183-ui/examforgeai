import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PAYMENT CALLBACK PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Payment verification page.
///
/// Reads `tx_ref` from query parameters, shows a loading spinner
/// while verifying payment, then displays a success animation with
/// subscription details or an error with a retry option.
class PaymentCallbackPage extends ConsumerStatefulWidget {
  const PaymentCallbackPage({
    super.key,
    required this.txRef,
    this.status,
  });

  /// The transaction reference from the payment callback.
  final String txRef;

  /// The status returned by Flutterwave (optional).
  final String? status;

  @override
  ConsumerState<PaymentCallbackPage> createState() =>
      _PaymentCallbackPageState();
}

class _PaymentCallbackPageState extends ConsumerState<PaymentCallbackPage>
    with SingleTickerProviderStateMixin {
  bool _hasVerified = false;
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyPayment();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Verify Payment ──────────────────────────────────────────────────

  Future<void> _verifyPayment() async {
    await ref
        .read(paymentProvider.notifier)
        .verifyPayment(txRef: widget.txRef);

    final paymentState = ref.read(paymentProvider);
    final transaction = paymentState.currentTransaction;

    if (mounted) {
      setState(() {
        _hasVerified = true;
        _isSuccess = transaction?.isSuccessful ?? false;
      });

      if (_isSuccess) {
        _animationController.forward();
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Payment Status',
      ),
      body: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Center(
          child: !_hasVerified
              ? _buildVerifyingState(context)
              : _isSuccess
                  ? _buildSuccessState(context)
                  : _buildFailureState(context),
        ),
      ),
    );
  }

  // ─── Verifying State ─────────────────────────────────────────────────

  Widget _buildVerifyingState(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
        const SizedBox(height: Spacings.xl),
        Text(
          'Verifying Payment',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          'Please wait while we confirm your payment...',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.md),
        Text(
          'Reference: ${widget.txRef}',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ─── Success State ───────────────────────────────────────────────────

  Widget _buildSuccessState(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final transaction = ref.read(paymentProvider).currentTransaction;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success
                  .withOpacity(isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          Text(
            'Payment Successful!',
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.sm),

          Text(
            'Your subscription has been activated.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.xl),

          // Transaction details card
          if (transaction != null) ...[
            Card(
              elevation: Spacings.elevationNone,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Column(
                  children: [
                    _detailRow(
                      context,
                      label: 'Amount',
                      value:
                          '${transaction.currency == 'NGN' ? '\u20A6' : '\$'}${transaction.amount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: Spacings.sm),
                    _detailRow(
                      context,
                      label: 'Reference',
                      value: transaction.flutterwaveTxRef ?? widget.txRef,
                    ),
                    const SizedBox(height: Spacings.sm),
                    _detailRow(
                      context,
                      label: 'Method',
                      value: transaction.paymentMethodSummary ?? 'N/A',
                    ),
                    if (transaction.completedAt != null) ...[
                      const SizedBox(height: Spacings.sm),
                      _detailRow(
                        context,
                        label: 'Date',
                        value: _formatDate(transaction.completedAt!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacings.xl),
          ],

          // Go to Dashboard button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.dashboard_rounded, size: 20),
              label: const Text('Go to Dashboard'),
              style: FilledButton.styleFrom(
                padding: Spacings.paddingButton,
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Failure State ───────────────────────────────────────────────────

  Widget _buildFailureState(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final paymentState = ref.read(paymentProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Error icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.error
                .withOpacity(isDark ? 0.20 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AppColors.error,
          ),
        ),
        const SizedBox(height: Spacings.xl),

        Text(
          'Payment Failed',
          style: tt.headlineSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.sm),

        Text(
          paymentState.error ??
              'We could not verify your payment. If you were charged, please contact support.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.sm),

        Text(
          'Reference: ${widget.txRef}',
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: Spacings.xl),

        // Retry button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _verifyPayment,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Retry Verification'),
            style: FilledButton.styleFrom(
              padding: Spacings.paddingButton,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacings.md),

        // Go back button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: Spacings.paddingButton,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
            child: const Text('Go Back'),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wMedium,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
