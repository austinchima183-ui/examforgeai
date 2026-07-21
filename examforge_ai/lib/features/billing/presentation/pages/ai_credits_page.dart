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
import '../providers/ai_credits_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI CREDITS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Credit management page.
///
/// Shows credit balance, purchasable credit packs, and transaction
/// history with type filtering.
class AiCreditsPage extends ConsumerStatefulWidget {
  const AiCreditsPage({
    super.key,
    this.ownerId,
    this.ownerType = BillingModel.teacherSaas,
  });

  final String? ownerId;
  final BillingModel ownerType;

  @override
  ConsumerState<AiCreditsPage> createState() => _AiCreditsPageState();
}

class _AiCreditsPageState extends ConsumerState<AiCreditsPage> {
  CreditTransactionType? _transactionFilter;
  int _transactionPage = 1;
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
    if (widget.ownerId == null) return;

    await Future.wait([
      ref.read(aiCreditsProvider.notifier).loadCreditBalance(
            ownerId: widget.ownerId!,
            ownerType: widget.ownerType,
          ),
      ref.read(aiCreditsProvider.notifier).loadCreditPacks(
            billingModel: widget.ownerType,
          ),
      ref.read(aiCreditsProvider.notifier).loadCreditTransactions(
            ownerId: widget.ownerId!,
            ownerType: widget.ownerType,
            type: _transactionFilter,
            page: _transactionPage,
            perPage: _perPage,
          ),
    ]);
  }

  Future<void> _refresh() async {
    setState(() => _transactionPage = 1);
    await _loadData();
  }

  Future<void> _purchasePack(AiCreditPackEntity pack) async {
    if (widget.ownerId == null) return;

    await ref.read(aiCreditsProvider.notifier).purchaseCredits(
          ownerId: widget.ownerId!,
          ownerType: widget.ownerType,
          creditPackId: pack.id,
        );

    final state = ref.read(aiCreditsProvider);
    if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credit pack purchased successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Reload balance
      ref.read(aiCreditsProvider.notifier).loadCreditBalance(
            ownerId: widget.ownerId!,
            ownerType: widget.ownerType,
          );
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final creditsState = ref.watch(aiCreditsProvider);

    return Scaffold(
      appBar: AppAppBar(title: 'AI Credits'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Credit Balance Card ─────────────────────────────────
              if (creditsState.creditBalance != null)
                CreditBalanceCard(
                  balance: creditsState.creditBalance!,
                  onPurchaseMore: () {
                    // Scroll to the credit packs section
                  },
                )
              else if (creditsState.isLoading)
                const Center(
                  child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                )
              else if (creditsState.error != null)
                AppErrorState.genericError(
                  message: creditsState.error,
                  onRetry: _refresh,
                ),

              const SizedBox(height: Spacings.xl),

              // ── Buy Credits Section ─────────────────────────────────
              _buildCreditPacksSection(creditsState),

              const SizedBox(height: Spacings.xl),

              // ── Transaction History ─────────────────────────────────
              _buildTransactionHistory(creditsState),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Credit Packs Section ────────────────────────────────────────────

  Widget _buildCreditPacksSection(AiCreditsState creditsState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Buy Credits',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        if (creditsState.creditPacks.isEmpty && !creditsState.isLoading)
          AppEmptyState.noData(
            title: 'No Credit Packs Available',
            subtitle: 'Check back later for available credit packs.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: Spacings.md,
              mainAxisSpacing: Spacings.md,
            ),
            itemCount: creditsState.creditPacks.length,
            itemBuilder: (context, index) {
              final pack = creditsState.creditPacks[index];
              return CreditPackCard(
                pack: pack,
                onPurchase: () => _purchasePack(pack),
              );
            },
          ),
      ],
    );
  }

  // ─── Transaction History ─────────────────────────────────────────────

  Widget _buildTransactionHistory(AiCreditsState creditsState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Transaction History',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // ── Filter Chips ─────────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(
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
              ...CreditTransactionType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: Spacings.xs),
                  child: _filterChip(
                    label: type.label,
                    isSelected: _transactionFilter == type,
                    onSelected: () {
                      setState(() {
                        _transactionFilter = type;
                        _transactionPage = 1;
                      });
                      _loadData();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacings.md),

        // ── Transaction List ─────────────────────────────────────────
        if (creditsState.creditTransactions.isEmpty)
          AppEmptyState.noData(
            title: 'No Transactions',
            subtitle: 'Your credit transactions will appear here.',
          )
        else
          ...creditsState.creditTransactions.map(
            (transaction) => _buildTransactionTile(transaction),
          ),

        // ── Load More ────────────────────────────────────────────────
        if (creditsState.creditTransactions.length >= _perPage)
          Padding(
            padding: const EdgeInsets.only(top: Spacings.md),
            child: Center(
              child: OutlinedButton(
                onPressed: creditsState.isLoading
                    ? null
                    : () {
                        setState(() => _transactionPage++);
                        _loadData();
                      },
                child: creditsState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small),
                      )
                    : const Text('Load More'),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Transaction Tile ────────────────────────────────────────────────

  Widget _buildTransactionTile(AiCreditTransactionEntity transaction) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final isCredit = transaction.isCredit;
    final typeIcon = _transactionTypeIcon(transaction.transactionType);
    final typeColor = isCredit ? AppColors.success : AppColors.error;

    return Card(
      elevation: Spacings.elevationNone,
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
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
            color: typeColor.withOpacity(isDark ? 0.20 : 0.12),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: Icon(
            typeIcon,
            color: typeColor,
            size: Spacings.mdIcon - 4,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.transactionType.label,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${isCredit ? '+' : ''}${transaction.credits} credits',
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: typeColor,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (transaction.featureName != null) ...[
              Expanded(
                child: Text(
                  transaction.featureName!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
            ] else
              const Spacer(),
            Text(
              _formatDate(transaction.createdAt),
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chip ─────────────────────────────────────────────────────

  Widget _filterChip({
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

  // ─── Helpers ─────────────────────────────────────────────────────────

  IconData _transactionTypeIcon(CreditTransactionType type) {
    switch (type) {
      case CreditTransactionType.monthlyAllocation:
        return Icons.calendar_month_rounded;
      case CreditTransactionType.purchase:
        return Icons.shopping_cart_rounded;
      case CreditTransactionType.usage:
        return Icons.auto_awesome_rounded;
      case CreditTransactionType.expiration:
        return Icons.timer_off_rounded;
      case CreditTransactionType.bonus:
        return Icons.card_giftcard_rounded;
      case CreditTransactionType.referralReward:
        return Icons.people_rounded;
      case CreditTransactionType.adminAdjustment:
        return Icons.admin_panel_settings_rounded;
      case CreditTransactionType.refund:
        return Icons.replay_rounded;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
