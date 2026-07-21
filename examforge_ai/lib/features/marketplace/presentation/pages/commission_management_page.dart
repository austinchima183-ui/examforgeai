import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/commission_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COMMISSION MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Super Admin commission management page with tab-based navigation for
/// Commission Rates, Commission Records, and Seller Payouts (future).
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => CommissionManagementPage()),
/// );
/// ```
class CommissionManagementPage extends ConsumerStatefulWidget {
  const CommissionManagementPage({super.key});

  @override
  ConsumerState<CommissionManagementPage> createState() =>
      _CommissionManagementPageState();
}

class _CommissionManagementPageState
    extends ConsumerState<CommissionManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _CommissionTab.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final notifier = ref.read(commissionProvider.notifier);
    await Future.wait([
      notifier.loadCommissionRates(),
      notifier.loadCommissionRecords(),
    ]);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commissionProvider);

    ref.listen<CommissionState>(commissionProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(commissionProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Commission Management',
        bottom: TabBar(
          controller: _tabController,
          tabs: _CommissionTab.values
              .map((tab) => Tab(
                    text: tab.label,
                    icon: Icon(tab.icon),
                  ))
              .toList(),
        ),
      ),
      body: state.isLoading &&
              state.commissionRates.isEmpty &&
              state.commissionRecords.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Commission Rates ───────────────────────────────────
                _CommissionRatesTab(
                  rates: state.commissionRates,
                  isLoading: state.isLoading,
                  onAdd: () => _showAddCommissionRateDialog(),
                  onEdit: (rate) => _showEditCommissionRateDialog(rate),
                ),

                // ── Commission Records ─────────────────────────────────
                _CommissionRecordsTab(
                  records: state.commissionRecords,
                  isLoading: state.isLoading,
                  totalCommission: state.totalCommissionAmount,
                  totalSellerRevenue: state.totalSellerRevenue,
                ),

                // ── Seller Payouts (Coming Soon) ───────────────────────
                const _SellerPayoutsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? AppFloatingActionButton(
              icon: Icons.add,
              label: 'Add Rate',
              extended: true,
              onPressed: () => _showAddCommissionRateDialog(),
            )
          : null,
    );
  }

  // ─── Add Commission Rate Dialog ────────────────────────────────────────

  void _showAddCommissionRateDialog() {
    _showCommissionRateDialog();
  }

  // ─── Edit Commission Rate Dialog ───────────────────────────────────────

  void _showEditCommissionRateDialog(CommissionRateEntity rate) {
    _showCommissionRateDialog(existingRate: rate);
  }

  void _showCommissionRateDialog({CommissionRateEntity? existingRate}) {
    final isEdit = existingRate != null;
    final productTypeNotifier = ValueNotifier<MarketplaceProductType?>(
      existingRate?.productType,
    );
    final licenseTypeNotifier = ValueNotifier<MarketplaceLicenseType?>(
      existingRate?.licenseType,
    );
    final rateController = TextEditingController(
      text: existingRate != null
          ? (existingRate.commissionRate * 100).toStringAsFixed(1)
          : '',
    );
    final isActiveNotifier = ValueNotifier<bool>(
      existingRate?.isActive ?? true,
    );
    final effectiveFromNotifier = ValueNotifier<DateTime?>(
      existingRate?.effectiveFrom,
    );
    final effectiveToNotifier = ValueNotifier<DateTime?>(
      existingRate?.effectiveTo,
    );
    final formKey = GlobalKey<FormState>();

    AppDialog.showCustom(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──────────────────────────────────────────
                Text(
                  isEdit ? 'Edit Commission Rate' : 'Add Commission Rate',
                  style: ctx.textTheme.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: ctx.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xl),

                // ── Product Type Dropdown ───────────────────────────
                ValueListenableBuilder<MarketplaceProductType?>(
                  valueListenable: productTypeNotifier,
                  builder: (_, selected, __) {
                    return AppDropdownField<MarketplaceProductType>(
                      label: 'Product Type',
                      items: MarketplaceProductType.values,
                      selectedItem: selected,
                      onChanged: (v) => productTypeNotifier.value = v,
                      itemLabel: (t) => t.label,
                      isRequired: true,
                      validator: (v) =>
                          v == null ? 'Please select a product type' : null,
                    );
                  },
                ),
                const SizedBox(height: Spacings.md),

                // ── License Type Dropdown ───────────────────────────
                ValueListenableBuilder<MarketplaceLicenseType?>(
                  valueListenable: licenseTypeNotifier,
                  builder: (_, selected, __) {
                    return AppDropdownField<MarketplaceLicenseType>(
                      label: 'License Type',
                      items: MarketplaceLicenseType.values,
                      selectedItem: selected,
                      onChanged: (v) => licenseTypeNotifier.value = v,
                      itemLabel: (t) => t.label,
                      isRequired: true,
                      validator: (v) =>
                          v == null ? 'Please select a license type' : null,
                    );
                  },
                ),
                const SizedBox(height: Spacings.md),

                // ── Commission Rate ─────────────────────────────────
                AppTextField(
                  label: 'Commission Rate',
                  hint: 'e.g. 15.0',
                  controller: rateController,
                  prefixIcon: Icons.percent_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  isRequired: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = double.tryParse(v);
                    if (val == null) return 'Enter a valid number';
                    if (val < 0 || val > 100) return 'Must be 0–100';
                    return null;
                  },
                ),
                const SizedBox(height: Spacings.md),

                // ── Effective Dates ────────────────────────────────
                ValueListenableBuilder<DateTime?>(
                  valueListenable: effectiveFromNotifier,
                  builder: (_, selected, __) {
                    return AppDateField(
                      label: 'Effective From',
                      selectedDate: selected,
                      onDateSelected: (d) => effectiveFromNotifier.value = d,
                      isRequired: true,
                    );
                  },
                ),
                const SizedBox(height: Spacings.md),

                ValueListenableBuilder<DateTime?>(
                  valueListenable: effectiveToNotifier,
                  builder: (_, selected, __) {
                    return AppDateField(
                      label: 'Effective To',
                      selectedDate: selected,
                      onDateSelected: (d) => effectiveToNotifier.value = d,
                    );
                  },
                ),
                const SizedBox(height: Spacings.md),

                // ── Active Toggle ──────────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: isActiveNotifier,
                  builder: (_, isActive, __) {
                    return SwitchListTile(
                      title: Text(
                        'Active',
                        style: ctx.textTheme.bodyLarge?.copyWith(
                          color: ctx.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        isActive
                            ? 'This rate is currently active'
                            : 'This rate is inactive',
                        style: ctx.textTheme.bodySmall?.copyWith(
                          color: ctx.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: isActive,
                      onChanged: (v) => isActiveNotifier.value = v,
                      activeColor: AppColors.success,
                    );
                  },
                ),
                const SizedBox(height: Spacings.xl),

                // ── Actions ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    const SizedBox(width: Spacings.sm),
                    AppButton(
                      label: isEdit ? 'Update' : 'Create',
                      variant: AppButtonVariant.elevated,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (productTypeNotifier.value == null ||
                            licenseTypeNotifier.value == null) return;

                        final rateValue =
                            double.parse(rateController.text) / 100;
                        final now = DateTime.now();

                        final rate = CommissionRateEntity(
                          id: existingRate?.id ?? '',
                          productType: productTypeNotifier.value!,
                          licenseType: licenseTypeNotifier.value!,
                          commissionRate: rateValue,
                          isActive: isActiveNotifier.value,
                          effectiveFrom:
                              effectiveFromNotifier.value ?? now,
                          effectiveTo: effectiveToNotifier.value,
                          createdBy: existingRate?.createdBy ?? 'admin',
                          createdAt: existingRate?.createdAt ?? now,
                          updatedAt: now,
                        );

                        ref
                            .read(commissionProvider.notifier)
                            .upsertCommissionRate(rate: rate);
                        Navigator.of(ctx).pop();
                        _showSnackBar(
                          isEdit
                              ? 'Commission rate updated'
                              : 'Commission rate created',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUMS & HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

enum _CommissionTab {
  rates(label: 'Rates', icon: Icons.settings_outlined),
  records(label: 'Records', icon: Icons.receipt_long_outlined),
  payouts(label: 'Payouts', icon: Icons.account_balance_wallet_outlined);

  const _CommissionTab({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Returns a color representing the commission rate level:
/// green (low) → yellow (medium) → red (high).
Color _commissionRateColor(double rate, Brightness brightness) {
  // Rate is stored as decimal (0.0 – 1.0), so multiply by 100 for percentage
  final pct = (rate * 100).clamp(0, 100);
  if (pct <= 10) {
    return AppColors.successOf(brightness);
  } else if (pct <= 20) {
    return AppColors.warningOf(brightness);
  } else {
    return AppColors.errorOf(brightness);
  }
}

String _formatCurrency(double amount) {
  return '₦${amount.toStringAsFixed(2)}';
}

String _formatDate(DateTime date) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMMISSION RATES TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CommissionRatesTab extends StatelessWidget {
  const _CommissionRatesTab({
    required this.rates,
    required this.isLoading,
    required this.onAdd,
    required this.onEdit,
  });

  final List<CommissionRateEntity> rates;
  final bool isLoading;
  final VoidCallback onAdd;
  final ValueChanged<CommissionRateEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    if (isLoading && rates.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (rates.isEmpty) {
      return AppEmptyState(
        icon: Icons.settings_outlined,
        title: 'No Commission Rates',
        subtitle: 'Add a commission rate to get started.',
        actionLabel: 'Add Rate',
        onAction: onAdd,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: Spacings.paddingScreen,
        itemCount: rates.length,
        itemBuilder: (context, index) {
          final rate = rates[index];
          return _CommissionRateCard(
            rate: rate,
            onEdit: () => onEdit(rate),
          );
        },
      ),
    );
  }
}

class _CommissionRateCard extends StatelessWidget {
  const _CommissionRateCard({
    required this.rate,
    required this.onEdit,
  });

  final CommissionRateEntity rate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final rateColor = _commissionRateColor(
      rate.commissionRate,
      cs.brightness,
    );
    final pct = (rate.commissionRate * 100).toStringAsFixed(1);

    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacings.md),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: product & license type ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rate.productType.label,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Rate badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: rateColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  '$pct%',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: rateColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── License type ─────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                rate.licenseType.label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── Effective dates & status ─────────────────────────────
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '${_formatDate(rate.effectiveFrom)}'
                '${rate.effectiveTo != null ? ' – ${_formatDate(rate.effectiveTo!)}' : ' – Present'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Spacings.md),
              // Active / Inactive badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: rate.isCurrentlyEffective
                      ? AppColors.success.withValues(alpha: context.isDarkMode ? 0.20 : 0.12)
                      : cs.onSurfaceVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  rate.isCurrentlyEffective ? 'Active' : 'Inactive',
                  style: tt.labelSmall?.copyWith(
                    color: rate.isCurrentlyEffective
                        ? AppColors.successOf(cs.brightness)
                        : cs.onSurfaceVariant,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),

          // ── Rate color bar visualization ─────────────────────────
          const SizedBox(height: Spacings.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: rate.commissionRate.clamp(0.0, 1.0),
              minHeight: 6.0,
              backgroundColor: cs.surfaceContainerHighest,
              color: rateColor,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMMISSION RECORDS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _CommissionRecordsTab extends StatefulWidget {
  const _CommissionRecordsTab({
    required this.records,
    required this.isLoading,
    required this.totalCommission,
    required this.totalSellerRevenue,
  });

  final List<CommissionRecordEntity> records;
  final bool isLoading;
  final double totalCommission;
  final double totalSellerRevenue;

  @override
  State<_CommissionRecordsTab> createState() => _CommissionRecordsTabState();
}

class _CommissionRecordsTabState extends State<_CommissionRecordsTab> {
  String _searchQuery = '';

  List<CommissionRecordEntity> get _filteredRecords {
    if (_searchQuery.isEmpty) return widget.records;
    return widget.records
        .where((r) =>
            r.sellerId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.commissionType.label
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            r.orderItemId.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  double get _filteredCommission =>
      _filteredRecords.fold(0.0, (sum, r) => sum + r.commissionAmount);

  double get _filteredRevenue =>
      _filteredRecords.fold(0.0, (sum, r) => sum + r.sellerRevenue);

  double get _averageRate {
    if (_filteredRecords.isEmpty) return 0;
    return _filteredRecords.fold(0.0, (sum, r) => sum + r.commissionRate) /
        _filteredRecords.length;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.records.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (widget.records.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Commission Records',
        subtitle: 'Commission records will appear here once orders are placed.',
      );
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      children: [
        // ── Summary Stats ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          color: cs.surfaceContainerLow,
          child: Row(
            children: [
              _SummaryStat(
                label: 'Total Commission',
                value: _formatCurrency(_filteredCommission),
                icon: Icons.account_balance_outlined,
                color: AppColors.info,
              ),
              const SizedBox(width: Spacings.lg),
              _SummaryStat(
                label: 'Seller Revenue',
                value: _formatCurrency(_filteredRevenue),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              const SizedBox(width: Spacings.lg),
              _SummaryStat(
                label: 'Avg. Rate',
                value: '${(_averageRate * 100).toStringAsFixed(1)}%',
                icon: Icons.speed_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
        ),

        // ── Search & Filter ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hint: 'Search by seller, order, or type…',
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              AppIconButton(
                icon: Icons.file_download_outlined,
                onPressed: () {
                  context.scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Export coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'Export',
                variant: AppIconButtonVariant.outlined,
              ),
            ],
          ),
        ),

        // ── Records List ─────────────────────────────────────────────
        Expanded(
          child: _filteredRecords.isEmpty
              ? AppEmptyState.noResults(
                  subtitle: 'No records match your search.',
                )
              : RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: Spacings.paddingScreen,
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _CommissionRecordCard(record: record);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CommissionRecordCard extends StatelessWidget {
  const _CommissionRecordCard({required this.record});

  final CommissionRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final rateColor = _commissionRateColor(
      record.commissionRate,
      cs.brightness,
    );

    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      child: Row(
        children: [
          // ── Commission type icon ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: rateColor.withValues(
                alpha: context.isDarkMode ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: Spacings.mdIcon,
              color: rateColor,
            ),
          ),
          const SizedBox(width: Spacings.md),

          // ── Details ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.commissionType.label,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _formatCurrency(record.commissionAmount),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: rateColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order: ${record.orderItemId.substring(0, record.orderItemId.length > 8 ? 8 : record.orderItemId.length)}…',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(record.commissionRate * 100).toStringAsFixed(1)}%',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seller: ${record.sellerId.substring(0, record.sellerId.length > 8 ? 8 : record.sellerId.length)}…',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Revenue: ${_formatCurrency(record.sellerRevenue)}',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.successOf(cs.brightness),
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SELLER PAYOUTS TAB (Coming Soon)
// ═══════════════════════════════════════════════════════════════════════════════

class _SellerPayoutsTab extends StatelessWidget {
  const _SellerPayoutsTab();

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Coming Soon Banner ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.xl),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: Spacings.xlIcon,
                  color: Colors.white,
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  'Seller Payouts',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  'Automated seller payout management is coming soon. '
                  'You\'ll be able to process batch payouts, set minimum '
                  'thresholds, and track payment history.',
                  style: tt.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ── Payout Structure Preview ───────────────────────────────
          Text(
            'Planned Payout Structure',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          _PayoutPreviewCard(
            icon: Icons.account_balance_outlined,
            title: 'Bank Transfer',
            subtitle: 'Direct bank transfer to seller accounts',
            status: 'Supported',
            statusColor: AppColors.successOf(cs.brightness),
          ),
          const SizedBox(height: Spacings.sm),

          _PayoutPreviewCard(
            icon: Icons.phone_android_outlined,
            title: 'Mobile Money',
            subtitle: 'Mobile money transfer (MTN, Airtel, etc.)',
            status: 'Supported',
            statusColor: AppColors.successOf(cs.brightness),
          ),
          const SizedBox(height: Spacings.sm),

          _PayoutPreviewCard(
            icon: Icons.currency_bitcoin_outlined,
            title: 'Crypto Wallet',
            subtitle: 'Cryptocurrency wallet transfers',
            status: 'Planned',
            statusColor: AppColors.warningOf(cs.brightness),
          ),
          const SizedBox(height: Spacings.xl),

          // ── Pending Payouts (Placeholder) ──────────────────────────
          Text(
            'Pending Payouts',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          ...List.generate(3, (index) {
            final sellers = [
              ('Dr. Adebayo Ogundimu', '₦45,200.00', 'Bank Transfer'),
              ('Prof. Chika Nwosu', '₦28,750.00', 'Mobile Money'),
              ('Mrs. Funke Alakija', '₦12,300.00', 'Bank Transfer'),
            ];
            final seller = sellers[index];

            return AppCard(
              margin: const EdgeInsets.only(bottom: Spacings.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      seller.$1.substring(0, 1),
                      style: tt.titleSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.$1,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          seller.$3,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    seller.$2,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: AppColors.successOf(cs.brightness),
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
}

class _PayoutPreviewCard extends StatelessWidget {
  const _PayoutPreviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.primary.withValues(
                alpha: context.isDarkMode ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(icon, size: Spacings.lgIcon, color: cs.primary),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: context.isDarkMode ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
            ),
            child: Text(
              status,
              style: tt.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Spacings.smIcon, color: color),
              const SizedBox(width: Spacings.xs),
              Text(
                label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            value,
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
