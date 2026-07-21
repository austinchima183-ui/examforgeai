import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/subscription_provider.dart';
import '../providers/ai_credits_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/billing_notification_provider.dart';
import '../widgets/billing_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// BILLING DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// The main Billing Dashboard page.
///
/// This is the entry point for the billing feature, presenting a modern
/// SaaS-style billing dashboard with:
/// - Current subscription overview (plan name, status, period end)
/// - AI credit balance card
/// - Quick actions (Upgrade, Manage, View Invoices, Buy Credits)
/// - Recent transactions list
/// - Billing alerts/notifications
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [SingleChildScrollView] with
/// vertically arranged Card sections.
class BillingDashboardPage extends ConsumerStatefulWidget {
  const BillingDashboardPage({super.key});

  @override
  ConsumerState<BillingDashboardPage> createState() => _State();
}

class _State extends ConsumerState<BillingDashboardPage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Loads all billing data in parallel.
  void _loadData() {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    final subscriberType = BillingModel.teacherSaas;

    ref.read(subscriptionProvider.notifier).loadCurrentSubscription(
          subscriberId: userId,
          subscriberType: subscriberType,
        );

    ref.read(aiCreditsProvider.notifier).loadCreditBalance(
          ownerId: userId,
          ownerType: subscriberType,
        );

    ref.read(paymentProvider.notifier).loadTransactions(
          userId: userId,
          page: 1,
          perPage: 5,
        );

    ref.read(billingNotificationProvider.notifier).loadNotifications(
          userId: userId,
          unreadOnly: false,
          page: 1,
          perPage: 10,
        );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final creditsState = ref.watch(aiCreditsProvider);
    final paymentState = ref.watch(paymentProvider);
    final notificationState = ref.watch(billingNotificationProvider);

    final isLoading = subscriptionState.isLoading ||
        creditsState.isLoading ||
        (paymentState.isLoading && paymentState.transactions.isEmpty) ||
        (notificationState.isLoading && notificationState.notifications.isEmpty);

    final hasError = subscriptionState.error != null &&
        subscriptionState.subscription == null;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Billing',
        actions: [
          if (notificationState.hasUnread)
            IconButton(
              icon: Badge(
                label: Text('${notificationState.unreadCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => context.go(RouteNames.billingNotifications),
              tooltip: 'Notifications',
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go(RouteNames.billingNotifications),
              tooltip: 'Notifications',
            ),
        ],
      ),
      body: _buildBody(
        context,
        isLoading: isLoading,
        hasError: hasError,
        subscriptionState: subscriptionState,
        creditsState: creditsState,
        paymentState: paymentState,
        notificationState: notificationState,
      ),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context, {
    required bool isLoading,
    required bool hasError,
    required SubscriptionState subscriptionState,
    required AiCreditsState creditsState,
    required PaymentState paymentState,
    required BillingNotificationState notificationState,
  }) {
    // Loading state — initial load with no data
    if (isLoading &&
        subscriptionState.subscription == null &&
        creditsState.creditBalance == null &&
        paymentState.transactions.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    // Error state — no subscription data available
    if (hasError) {
      return AppErrorState.genericError(
        message: subscriptionState.error,
        onRetry: _loadData,
      );
    }

    // Success — render dashboard
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Subscription Overview ────────────────────────────
            _buildSubscriptionOverview(context, subscriptionState),

            const SizedBox(height: Spacings.lg),

            // ─── AI Credit Balance Card ───────────────────────────
            _buildCreditBalanceCard(context, creditsState),

            const SizedBox(height: Spacings.lg),

            // ─── Quick Actions ────────────────────────────────────
            _buildQuickActions(context),

            const SizedBox(height: Spacings.lg),

            // ─── Billing Alerts / Notifications ───────────────────
            _buildBillingAlerts(context, notificationState),

            const SizedBox(height: Spacings.lg),

            // ─── Recent Transactions ──────────────────────────────
            _buildRecentTransactions(context, paymentState),

            // Bottom padding
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSubscriptionOverview(
    BuildContext context,
    SubscriptionState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final subscription = state.subscription;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.card_membership_outlined,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    'Current Subscription',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (subscription != null)
                  _SubscriptionStatusBadge(status: subscription.status),
              ],
            ),

            const SizedBox(height: Spacings.lg),

            if (subscription != null) ...[
              // Plan name
              Text(
                subscription.plan?.name ?? 'Unknown Plan',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),

              // Billing cycle
              Text(
                '${_capitalize(subscription.billingCycle)} billing',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacings.md),

              // Period info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: Spacings.smIcon + 2,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'Renews ${_formatDate(subscription.currentPeriodEnd)}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Icon(
                    Icons.timer_outlined,
                    size: Spacings.smIcon + 2,
                    color: subscription.daysRemaining <= 7
                        ? AppColors.warningOf(cs.brightness)
                        : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '${subscription.daysRemaining} days remaining',
                    style: tt.bodySmall?.copyWith(
                      color: subscription.daysRemaining <= 7
                          ? AppColors.warningOf(cs.brightness)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.md),

              // Price info
              if (subscription.priceAtSubscription > 0)
                Row(
                  children: [
                    Text(
                      '${subscription.currency} ${subscription.priceAtSubscription.toStringAsFixed(2)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '/ ${subscription.billingCycle == 'annual' ? 'year' : 'month'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ] else ...[
              // No active subscription
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: Spacings.xlIcon,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      'No Active Subscription',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Subscribe to a plan to unlock all features',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI CREDIT BALANCE CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCreditBalanceCard(
    BuildContext context,
    AiCreditsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final balance = state.creditBalance;

    final isLow = state.isLowOnCredits;
    final isExhausted = state.isExhausted;

    // Determine the accent colour based on credit status
    Color accentColor;
    if (isExhausted) {
      accentColor = AppColors.errorOf(cs.brightness);
    } else if (isLow) {
      accentColor = AppColors.warningOf(cs.brightness);
    } else {
      accentColor = AppColors.successOf(cs.brightness);
    }

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    'AI Credits',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (isExhausted || isLow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(context.isDarkMode ? 0.20 : 0.10,
                      ),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text(
                      isExhausted ? 'EXHAUSTED' : 'LOW',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: Spacings.lg),

            if (balance != null) ...[
              // Credit count
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${balance.remainingCredits}',
                    style: tt.displaySmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '/ ${balance.totalCredits} credits',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.md),

              // Usage progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Used: ${balance.usedCredits}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${balance.usagePercent.toStringAsFixed(0)}%',
                        style: tt.bodySmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  ClipRRect(
                    borderRadius: Spacings.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: balance.usagePercent / 100,
                      minHeight: 8,
                      backgroundColor:
                          cs.surfaceContainerHighest,
                      color: accentColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.sm),

              // Cycle end date
              Text(
                'Resets on ${_formatDate(balance.currentCycleEnd)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ] else ...[
              // No credit balance loaded
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bolt_outlined,
                      size: Spacings.xlIcon,
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      'Credit Balance Unavailable',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDesktop = context.isDesktop;
    final crossAxisCount = isDesktop ? 4 : 2;

    final actions = [
      _QuickAction(
        icon: Icons.arrow_upward_outlined,
        label: 'Upgrade',
        color: cs.primary,
        onTap: () => context.go(RouteNames.billingUpgrade),
      ),
      _QuickAction(
        icon: Icons.settings_outlined,
        label: 'Manage',
        color: AppColors.infoOf(cs.brightness),
        onTap: () => context.go(RouteNames.billingManage),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Invoices',
        color: AppColors.successOf(cs.brightness),
        onTap: () => context.go(RouteNames.billingInvoices),
      ),
      _QuickAction(
        icon: Icons.add_shopping_cart_outlined,
        label: 'Buy Credits',
        color: AppColors.warningOf(cs.brightness),
        onTap: () => context.go(RouteNames.billingBuyCredits),
      ),
    ];

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.flash_on_outlined,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Quick Actions',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // Action grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isDesktop ? 2.2 : 1.5,
                mainAxisSpacing: Spacings.md,
                crossAxisSpacing: Spacings.md,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _QuickActionTile(action: action);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BILLING ALERTS / NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBillingAlerts(
    BuildContext context,
    BillingNotificationState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final notifications = state.notifications;
    final unreadNotifications =
        notifications.where((n) => !n.isRead).toList();

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.notification_important_outlined,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    'Billing Alerts',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (unreadNotifications.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningOf(cs.brightness).withOpacity(context.isDarkMode ? 0.20 : 0.10,
                      ),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text(
                      '${unreadNotifications.length} new',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: AppColors.warningOf(cs.brightness),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: Spacings.md),

            if (unreadNotifications.isEmpty) ...[
              AppEmptyState.noNotifications(
                title: 'No Alerts',
                subtitle: 'You\'re all caught up! No billing alerts right now.',
              ),
            ] else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unreadNotifications.length > 5
                      ? 5
                      : unreadNotifications.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: Spacings.sm,
                  ),
                  itemBuilder: (context, index) {
                    final notification = unreadNotifications[index];
                    return _BillingAlertTile(
                      notification: notification,
                      onDismiss: () {
                        ref
                            .read(billingNotificationProvider.notifier)
                            .markAsRead(notificationId: notification.id);
                      },
                    );
                  },
                ),
              ),

              if (unreadNotifications.length > 5) ...[
                const SizedBox(height: Spacings.sm),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        context.go(RouteNames.billingNotifications),
                    child: Text(
                      'View All Alerts (${unreadNotifications.length})',
                      style: tt.labelLarge?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RECENT TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildRecentTransactions(
    BuildContext context,
    PaymentState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final transactions = state.transactions;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.go(RouteNames.billingInvoices),
                  child: Text(
                    'View All',
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: Spacings.md),

            if (transactions.isEmpty) ...[
              AppEmptyState.noData(
                title: 'No Transactions',
                subtitle: 'Your transaction history will appear here.',
              ),
            ] else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: Spacings.sm,
                  ),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _TransactionTile(transaction: tx);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Formats a [DateTime] to a short readable date string.
  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  /// Returns the month name for the given [month] number (1-12).
  String _monthName(int month) {
    const names = [
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
    return names[month];
  }

  /// Capitalizes the first letter of [text].
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

/// Badge displaying the current subscription status with a coloured chip.
class _SubscriptionStatusBadge extends StatelessWidget {
  const _SubscriptionStatusBadge({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    Color badgeColor;
    switch (status) {
      case SubscriptionStatus.active:
        badgeColor = AppColors.successOf(cs.brightness);
      case SubscriptionStatus.trial:
        badgeColor = AppColors.infoOf(cs.brightness);
      case SubscriptionStatus.pastDue:
        badgeColor = AppColors.errorOf(cs.brightness);
      case SubscriptionStatus.paused:
        badgeColor = AppColors.warningOf(cs.brightness);
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        badgeColor = cs.onSurfaceVariant;
      case SubscriptionStatus.pendingActivation:
        badgeColor = cs.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wBold,
          color: badgeColor,
        ),
      ),
    );
  }
}

/// Data class for a quick action tile.
class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Tile for a single quick action.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return InkWell(
      onTap: action.onTap,
      borderRadius: Spacings.borderRadiusMd,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(isDark ? 0.10 : 0.06),
          borderRadius: Spacings.borderRadiusMd,
          border: Border.all(
            color: action.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action.icon,
              size: Spacings.lgIcon,
              color: action.color,
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              action.label,
              style: tt.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: action.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile for a single billing alert/notification.
class _BillingAlertTile extends StatelessWidget {
  const _BillingAlertTile({
    required this.notification,
    required this.onDismiss,
  });

  final BillingNotificationEntity notification;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Determine icon and colour based on notification type
    IconData icon;
    Color iconColor;
    switch (notification.notificationType) {
      case BillingNotificationType.paymentSuccess:
        icon = Icons.check_circle_outline;
        iconColor = AppColors.successOf(cs.brightness);
      case BillingNotificationType.paymentFailed:
        icon = Icons.error_outline;
        iconColor = AppColors.errorOf(cs.brightness);
      case BillingNotificationType.trialEnding:
      case BillingNotificationType.planExpiring:
        icon = Icons.timer_outlined;
        iconColor = AppColors.warningOf(cs.brightness);
      case BillingNotificationType.lowAiCredits:
        icon = Icons.bolt_outlined;
        iconColor = AppColors.warningOf(cs.brightness);
      case BillingNotificationType.subscriptionRenewal:
        icon = Icons.autorenew_outlined;
        iconColor = AppColors.infoOf(cs.brightness);
      case BillingNotificationType.invoiceGenerated:
        icon = Icons.receipt_outlined;
        iconColor = AppColors.infoOf(cs.brightness);
      case BillingNotificationType.refundStatus:
        icon = Icons.assignment_return_outlined;
        iconColor = AppColors.infoOf(cs.brightness);
      case BillingNotificationType.cardExpiring:
        icon = Icons.credit_card_outlined;
        iconColor = AppColors.warningOf(cs.brightness);
      case BillingNotificationType.subscriptionCancelled:
        icon = Icons.cancel_outlined;
        iconColor = AppColors.errorOf(cs.brightness);
      case BillingNotificationType.upgradeAvailable:
        icon = Icons.trending_up_outlined;
        iconColor = AppColors.successOf(cs.brightness);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacings.xs,
        vertical: Spacings.xs,
      ),
      leading: Icon(icon, color: iconColor, size: Spacings.mdIcon + 4),
      title: Text(
        notification.title,
        style: tt.bodyMedium?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        notification.message,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.close_outlined,
          size: Spacings.mdIcon - 4,
          color: cs.onSurfaceVariant,
        ),
        onPressed: onDismiss,
        tooltip: 'Dismiss',
      ),
    );
  }
}

/// Tile for a single recent transaction.
class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Determine icon and colour based on status
    Color statusColor;
    IconData statusIcon;
    switch (transaction.status) {
      case TransactionStatus.successful:
        statusColor = AppColors.successOf(cs.brightness);
        statusIcon = Icons.check_circle_outline;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        statusColor = AppColors.warningOf(cs.brightness);
        statusIcon = Icons.schedule_outlined;
      case TransactionStatus.failed:
        statusColor = AppColors.errorOf(cs.brightness);
        statusIcon = Icons.error_outline;
      case TransactionStatus.refunded:
      case TransactionStatus.partiallyRefunded:
        statusColor = const Color(0xFF8B5CF6); // Violet
        statusIcon = Icons.assignment_return_outlined;
      case TransactionStatus.disputed:
        statusColor = AppColors.errorOf(cs.brightness);
        statusIcon = Icons.gavel_outlined;
      case TransactionStatus.voided:
        statusColor = cs.onSurfaceVariant;
        statusIcon = Icons.block_outlined;
    }

    final isDebit = transaction.amount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacings.xs,
        vertical: Spacings.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(statusIcon, color: statusColor, size: Spacings.mdIcon),
      ),
      title: Text(
        transaction.description ?? transaction.channel.label,
        style: tt.bodyMedium?.copyWith(
          fontWeight: AppTypography.wMedium,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatTransactionDate(transaction.initiatedAt),
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isDebit ? '-' : '+'}${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
            style: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isDebit ? cs.onSurface : AppColors.successOf(cs.brightness),
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Text(
              transaction.status.label,
              style: tt.labelSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: statusColor,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a [DateTime] for display in the transaction list.
  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'Just now';
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
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
      return '${months[date.month]} ${date.day}, ${date.year}';
    }
  }
}
