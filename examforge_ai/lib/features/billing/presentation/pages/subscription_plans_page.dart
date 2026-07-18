import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../routing/route_names.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/subscription_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUBSCRIPTION PLANS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Displays all available subscription plans and lets users select one
/// to subscribe to.
///
/// Features:
/// - [BillingModelSelector] at the top (Teacher / School / Enterprise tabs)
/// - Monthly / Annual toggle switch
/// - Responsive grid of [PlanCard] widgets (2 columns on tablet, 1 on mobile)
/// - Current plan highlighted with a distinct border
/// - "Contact Sales" CTA for the Enterprise billing model
/// - Navigation to [RouteNames.billingCheckout] on plan selection
class SubscriptionPlansPage extends ConsumerStatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  ConsumerState<SubscriptionPlansPage> createState() =>
      _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState
    extends ConsumerState<SubscriptionPlansPage> {
  // ─── Local State ─────────────────────────────────────────────────────

  /// Currently selected billing cycle: `'monthly'` or `'annual'`.
  String _billingCycle = 'monthly';

  /// Currently selected billing model.
  BillingModel _billingModel = BillingModel.teacherSaas;

  // ─── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await ref.read(subscriptionProvider.notifier).loadPlans(
          billingModel: _billingModel,
        );
    _listenForMessages();
  }

  Future<void> _handleRefresh() async {
    await ref.read(subscriptionProvider.notifier).loadPlans(
          billingModel: _billingModel,
        );
    _listenForMessages();
  }

  // ─── Messages ────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(subscriptionProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(subscriptionProvider.notifier).clearSuccess();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(subscriptionProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Handlers ────────────────────────────────────────────────────────

  void _onBillingModelChanged(BillingModel model) {
    if (model == _billingModel) return;
    setState(() => _billingModel = model);
    ref.read(subscriptionProvider.notifier).setBillingModel(model);
    ref.read(subscriptionProvider.notifier).loadPlans(billingModel: model);
  }

  void _onBillingCycleChanged(bool isAnnual) {
    setState(() => _billingCycle = isAnnual ? 'annual' : 'monthly');
    ref.read(subscriptionProvider.notifier).setBillingCycle(_billingCycle);
  }

  void _onPlanSelected(SubscriptionPlanEntity plan) {
    context.push(
      '${RouteNames.billingCheckout}?planId=${plan.id}&billingCycle=$_billingCycle',
    );
  }

  void _onContactSales() {
    // Could open an email client, navigate to a contact form, etc.
    context.push(
      '${RouteNames.billingCheckout}?billingModel=${_billingModel.value}&billingCycle=$_billingCycle&contactSales=true',
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Subscription Plans',
      ),
      body: state.isLoading
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.plans.isEmpty
              ? _buildErrorState()
              : _buildContent(state),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return AppErrorState(
      icon: Icons.cloud_off_rounded,
      title: 'Could Not Load Plans',
      message: 'We were unable to fetch the available subscription plans. '
          'Please check your connection and try again.',
      onRetry: _handleRefresh,
    );
  }

  // ─── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(SubscriptionState state) {
    final plans = state.plans;
    final currentPlanId = state.subscription?.planId;
    final isEnterprise = _billingModel == BillingModel.enterpriseSaas;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Billing Model Selector ──────────────────────────────────
          SliverToBoxAdapter(child: _buildBillingModelSelector()),
          const SliverToBoxAdapter(
            child: SizedBox(height: Spacings.md),
          ),

          // ── Billing Cycle Toggle ────────────────────────────────────
          SliverToBoxAdapter(child: _buildBillingCycleToggle()),
          const SliverToBoxAdapter(
            child: SizedBox(height: Spacings.lg),
          ),

          // ── Plans Grid ──────────────────────────────────────────────
          if (plans.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else ...[
            _buildPlanGrid(plans, currentPlanId),

            // ── Contact Sales CTA for Enterprise ─────────────────────
            if (isEnterprise) ...[
              const SliverToBoxAdapter(
                child: SizedBox(height: Spacings.lg),
              ),
              SliverToBoxAdapter(child: _buildContactSalesCard()),
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: Spacings.xl),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Billing Model Selector ──────────────────────────────────────────

  Widget _buildBillingModelSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Center(
        child: BillingModelSelector(
          selectedModel: _billingModel,
          onChanged: _onBillingModelChanged,
        ),
      ),
    );
  }

  // ─── Billing Cycle Toggle ────────────────────────────────────────────

  Widget _buildBillingCycleToggle() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isAnnual = _billingCycle == 'annual';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Monthly',
            style: tt.bodyMedium?.copyWith(
              fontWeight:
                  !isAnnual ? AppTypography.wSemiBold : AppTypography.wRegular,
              color: !isAnnual ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Switch(
            value: isAnnual,
            onChanged: _onBillingCycleChanged,
            activeColor: cs.primary,
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            'Annual',
            style: tt.bodyMedium?.copyWith(
              fontWeight:
                  isAnnual ? AppTypography.wSemiBold : AppTypography.wRegular,
              color: isAnnual ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          if (isAnnual)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.successLight.withValues(alpha: 0.2),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Text(
                'Save up to 20%',
                style: tt.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Plan Grid ───────────────────────────────────────────────────────

  Widget _buildPlanGrid(
    List<SubscriptionPlanEntity> plans,
    String? currentPlanId,
  ) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Determine cross-axis count based on screen width
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Spacings.md,
          mainAxisSpacing: Spacings.md,
          // Plan cards have variable height; use a reasonable ratio
          childAspectRatio: crossAxisCount == 1 ? 0.72 : 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final plan = plans[index];
            final isCurrentPlan = plan.id == currentPlanId;

            return PlanCard(
              plan: plan,
              billingCycle: _billingCycle,
              isSelected: isCurrentPlan,
              isCurrentPlan: isCurrentPlan,
              onSelect: () => _onPlanSelected(plan),
            );
          },
          childCount: plans.length,
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.card_membership_outlined,
      title: 'No Plans Available',
      subtitle:
          'There are no subscription plans available for the selected '
          'billing model at the moment. Please try a different model or '
          'check back later.',
      actionLabel: 'Retry',
      onAction: _handleRefresh,
    );
  }

  // ─── Contact Sales Card ──────────────────────────────────────────────

  Widget _buildContactSalesCard() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationSm,
        shadowColor: cs.shadow.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(Spacings.xl),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      cs.primaryContainer.withValues(alpha: 0.3),
                      cs.tertiaryContainer.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      cs.primaryContainer.withValues(alpha: 0.5),
                      cs.tertiaryContainer.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.business_center_rounded,
                size: Spacings.xlIcon,
                color: cs.primary,
              ),
              const SizedBox(height: Spacings.md),
              Text(
                'Need a Custom Enterprise Plan?',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                'Get tailored pricing, dedicated support, SLA guarantees, '
                'white-label options, and on-premise deployment for your '
                'institution.',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onContactSales,
                  icon: const Icon(Icons.mail_outline_rounded, size: 20),
                  label: const Text('Contact Sales'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacings.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: Spacings.borderRadiusMd,
                    ),
                    textStyle: tt.labelLarge?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
