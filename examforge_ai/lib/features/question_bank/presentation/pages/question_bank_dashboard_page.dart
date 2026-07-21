import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../domain/entities/question_entities.dart';
import '../providers/question_provider.dart';
import '../providers/question_bank_stats_provider.dart';
import '../providers/collection_provider.dart';
import '../widgets/stats_overview.dart';
import '../widgets/question_card.dart';
import '../widgets/collection_card.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// QUESTION BANK DASHBOARD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Landing page for the Question Bank module.
///
/// Displays an overview of statistics, quick-action cards, recent questions,
/// favorites, and collections. Supports pull-to-refresh and responsive
/// two-column layout on desktop.
class QuestionBankDashboardPage extends ConsumerStatefulWidget {
  const QuestionBankDashboardPage({super.key});

  @override
  ConsumerState<QuestionBankDashboardPage> createState() =>
      _QuestionBankDashboardPageState();
}

class _QuestionBankDashboardPageState
    extends ConsumerState<QuestionBankDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    ref.read(questionBankStatsProvider.notifier).loadStats();
    ref.read(questionBankProvider.notifier).loadQuestions();
    ref.read(collectionProvider.notifier).loadCollections();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(questionBankStatsProvider.notifier).refreshStats(),
      ref.read(questionBankProvider.notifier).refreshQuestions(),
      ref.read(collectionProvider.notifier).loadCollections(),
    ]);
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(questionBankStatsProvider);
    final questionState = ref.watch(questionBankProvider);
    final collectionState = ref.watch(collectionProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Question Bank',
        actions: [
          AppIconButton(
            icon: Icons.notifications_outlined,
            onPressed: () {},
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Error Banner ────────────────────────────────────────
            if (statsState.error != null)
              SliverToBoxAdapter(
                child: _ErrorBanner(
                  message: statsState.error!,
                  onRetry: _refresh,
                ),
              ),

            // ── Stats Overview ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildStatsSection(statsState),
            ),

            // ── Quick Actions ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),

            // ── Main Content: Responsive Two-Column ─────────────────
            if (context.isDesktop)
              SliverToBoxAdapter(
                child: _buildDesktopLayout(
                  context,
                  questionState,
                  collectionState,
                ),
              )
            else ...[
              // ── Recent Questions ──────────────────────────────────
              _buildRecentQuestionsSection(context, questionState),

              // ── My Favorites ─────────────────────────────────────
              _buildFavoritesSection(context, questionState),

              // ── My Collections ───────────────────────────────────
              _buildCollectionsSection(context, collectionState),
            ],

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: Spacings.xxl),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats Section ──────────────────────────────────────────────────

  Widget _buildStatsSection(QuestionBankStatsState statsState) {
    if (statsState.isLoading && statsState.stats == null) {
      return _buildStatsSkeleton();
    }

    return StatsOverview(
      stats: statsState.stats,
      isLoading: statsState.isLoading,
      onRefresh: _refresh,
    );
  }

  // ─── Stats Loading Skeleton ─────────────────────────────────────────

  Widget _buildStatsSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLoadingShimmer(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: context.isMobile ? 2 : 4,
              childAspectRatio: context.isMobile ? 0.85 : 1.1,
              crossAxisSpacing: Spacings.md,
              mainAxisSpacing: Spacings.md,
              children: List.generate(
                4,
                (_) => AppLoadingShimmer.box(height: 120),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final actions = [
      _QuickActionData(
        title: 'Create Question',
        subtitle: 'Build a new question',
        icon: Icons.add_circle_outline_rounded,
        color: cs.primary,
        onTap: () => context.go(RouteNames.questionBankCreate),
      ),
      _QuickActionData(
        title: 'Import Questions',
        subtitle: 'Bulk upload from file',
        icon: Icons.upload_file_rounded,
        color: AppColors.success,
        onTap: () => context.go(RouteNames.questionBankImport),
      ),
      _QuickActionData(
        title: 'Browse Collections',
        subtitle: 'Organize your questions',
        icon: Icons.collections_bookmark_outlined,
        color: const Color(0xFF7C3AED),
        onTap: () => context.go(RouteNames.questionBankCollections),
      ),
      _QuickActionData(
        title: 'Search Questions',
        subtitle: 'Find what you need',
        icon: Icons.search_rounded,
        color: const Color(0xFF0891B2),
        onTap: () => context.go(RouteNames.questionBankList),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: context.isMobile ? 2 : 4,
            childAspectRatio: context.isMobile ? 1.2 : 1.5,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
            children: actions.map((action) {
              return AppActionCard(
                title: action.title,
                subtitle: action.subtitle,
                icon: action.icon,
                color: action.color,
                onTap: action.onTap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    QuestionBankState questionState,
    CollectionState collectionState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Recent + Favorites
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecentQuestionsContent(context, questionState),
                const SizedBox(height: Spacings.xl),
                _buildFavoritesContent(context, questionState),
              ],
            ),
          ),
          const SizedBox(width: Spacings.xl),
          // Right column: Collections
          Expanded(
            child: _buildCollectionsContent(context, collectionState),
          ),
        ],
      ),
    );
  }

  // ─── Recent Questions Section ───────────────────────────────────────

  Widget _buildRecentQuestionsSection(
    BuildContext context,
    QuestionBankState questionState,
  ) {
    return SliverToBoxAdapter(
      child: _buildRecentQuestionsContent(context, questionState),
    );
  }

  Widget _buildRecentQuestionsContent(
    BuildContext context,
    QuestionBankState questionState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final recentQuestions = questionState.questions.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Questions',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => context.go(RouteNames.questionBankList),
                child: Text(
                  'View All',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (questionState.isLoading)
            const Center(child: AppLoadingSpinner())
          else if (recentQuestions.isEmpty)
            AppEmptyState.noData(
              title: 'No Questions Yet',
              subtitle: 'Create your first question to get started.',
              actionLabel: 'Create Question',
              onAction: () => context.go(RouteNames.questionBankCreate),
            )
          else
            ...recentQuestions.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: QuestionCard(
                  question: q,
                  mode: QuestionCardMode.compact,
                  onTap: () => context.go(
                    '${RouteNames.questionBankDetail}?id=${q.id}',
                  ),
                  onEdit: () => context.go(
                    '${RouteNames.questionBankEdit}?id=${q.id}',
                  ),
                  onDuplicate: () => ref
                      .read(questionBankProvider.notifier)
                      .duplicateQuestion(q.id),
                  onArchive: () => ref
                      .read(questionBankProvider.notifier)
                      .archiveQuestion(q.id),
                  onDelete: () => _confirmDelete(q.id),
                  onFavouriteToggle: () {
                    // TODO: toggle favourite
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Favorites Section ──────────────────────────────────────────────

  Widget _buildFavoritesSection(
    BuildContext context,
    QuestionBankState questionState,
  ) {
    return SliverToBoxAdapter(
      child: _buildFavoritesContent(context, questionState),
    );
  }

  Widget _buildFavoritesContent(
    BuildContext context,
    QuestionBankState questionState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // For now, filter questions that are featured as favorites.
    final favoriteQuestions =
        questionState.questions.where((q) => q.isFeatured).take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: Spacings.mdIcon,
                    color: const Color(0xFFE11D48),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'My Favorites',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              if (favoriteQuestions.isNotEmpty)
                TextButton(
                  onPressed: () => context.go(RouteNames.questionBankList),
                  child: Text(
                    'View All',
                    style: tt.labelMedium?.copyWith(color: cs.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (favoriteQuestions.isEmpty)
            AppEmptyState.noData(
              title: 'No Favorites',
              subtitle: 'Mark questions as favorites to see them here.',
            )
          else
            ...favoriteQuestions.map(
              (q) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: QuestionCard(
                  question: q,
                  mode: QuestionCardMode.compact,
                  isFavorited: true,
                  onTap: () => context.go(
                    '${RouteNames.questionBankDetail}?id=${q.id}',
                  ),
                  onFavouriteToggle: () {
                    // TODO: toggle favourite
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Collections Section ────────────────────────────────────────────

  Widget _buildCollectionsSection(
    BuildContext context,
    CollectionState collectionState,
  ) {
    return SliverToBoxAdapter(
      child: _buildCollectionsContent(context, collectionState),
    );
  }

  Widget _buildCollectionsContent(
    BuildContext context,
    CollectionState collectionState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Collections',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.go(RouteNames.questionBankCollections),
                child: Text(
                  'View All',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          if (collectionState.isLoading)
            const Center(child: AppLoadingSpinner())
          else if (collectionState.collections.isEmpty)
            AppEmptyState.noData(
              title: 'No Collections',
              subtitle: 'Create a collection to organize your questions.',
              actionLabel: 'Create Collection',
              onAction: () {
                // TODO: navigate to create collection
              },
            )
          else
            SizedBox(
              height: 260.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: collectionState.collections.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: Spacings.md),
                itemBuilder: (context, index) {
                  final collection = collectionState.collections[index];
                  return SizedBox(
                    width: context.isMobile
                        ? context.width - Spacings.lg * 2
                        : 300.0,
                    child: CollectionCard(
                      collection: collection,
                      onTap: () => context.go(
                        '${RouteNames.questionBankCollections}?id=${collection.id}',
                      ),
                      onEdit: () {
                        // TODO: edit collection
                      },
                      onDelete: () => _confirmDeleteCollection(collection.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Confirm Delete Question ────────────────────────────────────────

  Future<void> _confirmDelete(String questionId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Question?',
      message:
          'This action cannot be undone. The question will be permanently removed.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref.read(questionBankProvider.notifier).deleteQuestion(questionId);
    }
  }

  // ─── Confirm Delete Collection ──────────────────────────────────────

  Future<void> _confirmDeleteCollection(String collectionId) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Collection?',
      message:
          'This will remove the collection. Questions inside will not be deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      ref.read(collectionProvider.notifier).deleteCollection(collectionId);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _QuickActionData {
  const _QuickActionData({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      margin: const EdgeInsets.all(Spacings.lg),
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: Spacings.mdIcon,
            color: AppColors.errorOf(cs.brightness),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(
                color: AppColors.errorOf(cs.brightness),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: tt.labelMedium?.copyWith(
                color: AppColors.errorOf(cs.brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
