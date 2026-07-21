import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/invoice_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// INVOICE DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Invoice detail view.
///
/// Shows invoice header, bill-to section, line items table,
/// totals, PDF download button, and email delivery status.
class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
  });

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailPage> createState() =>
      _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceProvider.notifier).loadInvoice(
            invoiceId: widget.invoiceId,
          );
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final invoiceState = ref.watch(invoiceProvider);

    if (invoiceState.isLoading) {
      return Scaffold(
        appBar: AppAppBar(title: 'Invoice'),
        body: const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
        ),
      );
    }

    if (invoiceState.error != null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Invoice'),
        body: AppErrorState.genericError(
          message: invoiceState.error,
          onRetry: () => ref.read(invoiceProvider.notifier).loadInvoice(
                invoiceId: widget.invoiceId,
              ),
        ),
      );
    }

    final invoice = invoiceState.currentInvoice;
    if (invoice == null) {
      return Scaffold(
        appBar: AppAppBar(title: 'Invoice'),
        body: AppErrorState.genericError(
          message: 'Invoice not found.',
          onRetry: () => ref.read(invoiceProvider.notifier).loadInvoice(
                invoiceId: widget.invoiceId,
              ),
        ),
      );
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppAppBar(title: 'Invoice ${invoice.invoiceNumber}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Invoice Header ────────────────────────────────────────
            _buildInvoiceHeader(context, invoice),

            const SizedBox(height: Spacings.xl),

            // ── Bill To Section ───────────────────────────────────────
            _buildBillToSection(context, invoice),

            const SizedBox(height: Spacings.xl),

            // ── Line Items Table ──────────────────────────────────────
            _buildLineItemsTable(context, invoice),

            const SizedBox(height: Spacings.xl),

            // ── Totals ────────────────────────────────────────────────
            _buildTotals(context, invoice),

            const SizedBox(height: Spacings.xl),

            // ── Email Delivery Status ─────────────────────────────────
            _buildEmailStatus(context, invoice),

            const SizedBox(height: Spacings.xl),

            // ── PDF Download Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ref
                      .read(invoiceProvider.notifier)
                      .getPdfUrl(invoiceId: invoice.id);
                },
                icon: invoiceState.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text('Download PDF'),
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
      ),
    );
  }

  // ─── Invoice Header ──────────────────────────────────────────────────

  Widget _buildInvoiceHeader(BuildContext context, InvoiceEntity invoice) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _invoiceStatusColor(invoice.invoiceType);

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.06),
      shape: RoundedRectangleBorder(
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
                  invoice.invoiceNumber,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        statusColor.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text(
                    invoice.invoiceType.label,
                    style: tt.labelMedium?.copyWith(
                      color: isDark
                          ? _lightenColor(statusColor)
                          : _darkenColor(statusColor),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issue Date',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        _formatDate(invoice.issueDate),
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Due Date',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (invoice.isOverdue) ...[
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
                        style: tt.bodyMedium?.copyWith(
                          color: invoice.isOverdue ? AppColors.error : cs.onSurface,
                          fontWeight: AppTypography.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bill To Section ─────────────────────────────────────────────────

  Widget _buildBillToSection(BuildContext context, InvoiceEntity invoice) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill To',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              invoice.billToName,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            if (invoice.billToEmail != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                invoice.billToEmail!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            if (invoice.billToAddress != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                invoice.billToAddress!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (invoice.billToTaxId != null) ...[
              const SizedBox(height: Spacings.xs),
              Text(
                'Tax ID: ${invoice.billToTaxId!}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Line Items Table ────────────────────────────────────────────────

  Widget _buildLineItemsTable(BuildContext context, InvoiceEntity invoice) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Description',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qty',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Unit Price',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // Line items
          ...invoice.lineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.description,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatCurrency(item.unitPrice, invoice.currency),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatCurrency(item.total, invoice.currency),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: AppTypography.wMedium,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (invoice.lineItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(Spacings.xl),
              child: Text(
                'No line items',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Totals ──────────────────────────────────────────────────────────

  Widget _buildTotals(BuildContext context, InvoiceEntity invoice) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final symbol = invoice.currency == 'NGN' ? '\u20A6' : '\$';

    return Card(
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
            _totalRow(context, label: 'Subtotal', value: '$symbol${invoice.subtotal.toStringAsFixed(2)}'),
            if (invoice.taxAmount > 0) ...[
              const SizedBox(height: Spacings.sm),
              _totalRow(context, label: 'Tax', value: '$symbol${invoice.taxAmount.toStringAsFixed(2)}'),
            ],
            if (invoice.discountAmount > 0) ...[
              const SizedBox(height: Spacings.sm),
              _totalRow(context, label: 'Discount', value: '-$symbol${invoice.discountAmount.toStringAsFixed(2)}', valueColor: AppColors.success),
            ],
            const SizedBox(height: Spacings.md),
            const Divider(),
            const SizedBox(height: Spacings.md),
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
                  '$symbol${invoice.totalAmount.toStringAsFixed(2)}',
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

  // ─── Email Status ────────────────────────────────────────────────────

  Widget _buildEmailStatus(BuildContext context, InvoiceEntity invoice) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Icon(
              invoice.emailSent
                  ? Icons.mark_email_read_rounded
                  : Icons.markunread_rounded,
              size: Spacings.mdIcon,
              color: invoice.emailSent ? AppColors.success : cs.onSurfaceVariant,
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.emailSent ? 'Email Sent' : 'Email Not Sent',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                      color: cs.onSurface,
                    ),
                  ),
                  if (invoice.emailSentAt != null) ...[
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Sent on ${_formatDate(invoice.emailSentAt!)}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

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

  Color _invoiceStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.overdue:
        return AppColors.error;
      case InvoiceStatus.issued:
        return AppColors.info;
      case InvoiceStatus.draft:
        return AppColors.warning;
      case InvoiceStatus.cancelled:
      case InvoiceStatus.void_:
        return const Color(0xFF6B7280);
      case InvoiceStatus.partiallyPaid:
        return const Color(0xFFF97316);
      case InvoiceStatus.creditNote:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatCurrency(double amount, String currency) {
    final symbol = currency == 'NGN' ? '\u20A6' : '\$';
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  Color _darkenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }

  Color _lightenColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }
}
