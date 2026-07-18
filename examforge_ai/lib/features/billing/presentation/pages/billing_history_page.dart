import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/payment_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// BILLING HISTORY PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Transaction & invoice history page.
///
/// Features a tab bar (Transactions | Invoices), status filtering,
/// pull-to-refresh, pagination, and empty states for each tab.
class BillingHistoryPage extends ConsumerStatefulWidget {
  const BillingHistoryPage({
    super.key,
    this.userId,
    this.schoolId,
  });

  final String? userId;
  final String? schoolId;

  @override
  ConsumerState<BillingHistoryPage> createState() =>
      _BillingHistoryPageState();
}

class _BillingHistoryPageState extends ConsumerState<BillingHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionStatus? _transactionFilter;
  InvoiceStatus? _invoiceFilter;
  int _transactionPage = 1;
  int _invoicePage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(paymentProvider.notifier).loadTransactions(
            userId: widget.userId,
            schoolId: widget.schoolId,
            status: _transactionFilter,
            page: _transactionPage,
            perPage: _perPage,
          ),
      ref.read(invoiceProvider.notifier).loadInvoices(
            userId: widget.userId,
            schoolId: widget.schoolId,
            status: _invoiceFilter,
            page: _invoicePage,
            perPage: _perPage,
          ),
    ]);
  }

  Future<void> _refresh() async {
    setState(() {
      _transactionPage = 1;
      _invoicePage = 1;
    });
    await _loadData();
  }

  Future<void> _loadMoreTransactions() async {
    setState(() => _transactionPage++);
    await ref.read(paymentProvider.notifier).loadTransactions(
          userId: widget.userId,
          schoolId: widget.schoolId,
          status: _transactionFilter,
          page: _transactionPage,
          perPage: _perPage,
        );
  }

  Future<void> _loadMoreInvoices() async {
    setState(() => _invoicePage++);
    await ref.read(invoiceProvider.notifier).loadInvoices(
          userId: widget.userId,
          schoolId: widget.schoolId,
          status: _invoiceFilter,
          page: _invoicePage,
          perPage: _perPage,
        );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Billing History',
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          labelStyle: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: tt.titleSmall,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildInvoicesTab(),
        ],
      ),
    );
  }

  // ─── Transactions Tab ────────────────────────────────────────────────

  Widget _buildTransactionsTab() {
    final paymentState = ref.watch(paymentProvider);

    if (paymentState.isLoading && paymentState.transactions.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (paymentState.error != null && paymentState.transactions.isEmpty) {
      return AppErrorState.genericError(
        message: paymentState.error,
        onRetry: _refresh,
      );
    }

    if (paymentState.transactions.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Transactions',
        subtitle: 'Your payment transactions will appear here.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    return Column(
      children: [
        // Filter bar
        _buildTransactionFilterBar(),

        // Transaction list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              itemCount: paymentState.transactions.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: Spacings.xs),
              itemBuilder: (context, index) {
                if (index == paymentState.transactions.length) {
                  return _buildLoadMore(
                    isLoading: paymentState.isLoading,
                    onLoadMore: _loadMoreTransactions,
                  );
                }

                final transaction = paymentState.transactions[index];
                return TransactionListTile(
                  transaction: transaction,
                  onTap: () {
                    // TODO: navigate to transaction detail
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Invoices Tab ────────────────────────────────────────────────────

  Widget _buildInvoicesTab() {
    final invoiceState = ref.watch(invoiceProvider);

    if (invoiceState.isLoading && invoiceState.invoices.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (invoiceState.error != null && invoiceState.invoices.isEmpty) {
      return AppErrorState.genericError(
        message: invoiceState.error,
        onRetry: _refresh,
      );
    }

    if (invoiceState.invoices.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Invoices',
        subtitle: 'Your invoices will appear here.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    return Column(
      children: [
        // Filter bar
        _buildInvoiceFilterBar(),

        // Invoice list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.sm,
              ),
              itemCount: invoiceState.invoices.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
              itemBuilder: (context, index) {
                if (index == invoiceState.invoices.length) {
                  return _buildLoadMore(
                    isLoading: invoiceState.isLoading,
                    onLoadMore: _loadMoreInvoices,
                  );
                }

                final invoice = invoiceState.invoices[index];
                return InvoiceCard(
                  invoice: invoice,
                  onTap: () {
                    // TODO: navigate to invoice detail
                  },
                  onDownloadPdf: () {
                    ref
                        .read(invoiceProvider.notifier)
                        .getPdfUrl(invoiceId: invoice.id);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Transaction Filter Bar ──────────────────────────────────────────

  Widget _buildTransactionFilterBar() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.xs,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip<TransactionStatus?>(
            context: context,
            label: 'All',
            isSelected: _transactionFilter == null,
            onSelected: () {
              setState(() {
                _transactionFilter = null;
                _transactionPage = 1;
              });
              _loadData();
            },
          ),
          const SizedBox(width: Spacings.xs),
          ...TransactionStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: Spacings.xs),
              child: _filterChip<TransactionStatus?>(
                context: context,
                label: status.label,
                isSelected: _transactionFilter == status,
                onSelected: () {
                  setState(() {
                    _transactionFilter = status;
                    _transactionPage = 1;
                  });
                  _loadData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Invoice Filter Bar ──────────────────────────────────────────────

  Widget _buildInvoiceFilterBar() {
    final cs = context.colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.xs,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip<InvoiceStatus?>(
            context: context,
            label: 'All',
            isSelected: _invoiceFilter == null,
            onSelected: () {
              setState(() {
                _invoiceFilter = null;
                _invoicePage = 1;
              });
              _loadData();
            },
          ),
          const SizedBox(width: Spacings.xs),
          ...InvoiceStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: Spacings.xs),
              child: _filterChip<InvoiceStatus?>(
                context: context,
                label: status.label,
                isSelected: _invoiceFilter == status,
                onSelected: () {
                  setState(() {
                    _invoiceFilter = status;
                    _invoicePage = 1;
                  });
                  _loadData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Load More ───────────────────────────────────────────────────────

  Widget _buildLoadMore({
    required bool isLoading,
    required VoidCallback onLoadMore,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(Spacings.lg),
        child: Center(child: AppLoadingSpinner()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: OutlinedButton(
          onPressed: onLoadMore,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusMd,
            ),
          ),
          child: const Text('Load More'),
        ),
      ),
    );
  }

  // ─── Filter Chip ─────────────────────────────────────────────────────

  Widget _filterChip<T>({
    required BuildContext context,
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
