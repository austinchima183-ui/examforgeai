import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/product_detail_provider.dart';
import '../widgets/marketplace_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PRODUCT REVIEWS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// All reviews page for a single product. Displays a rating summary at the top,
/// filter chips, sorting options, a scrollable list of reviews, and a
/// "Write a Review" FAB for verified purchasers.
///
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => ProductReviewsPage(productId: '123'),
///   ),
/// );
/// ```
class ProductReviewsPage extends ConsumerStatefulWidget {
  const ProductReviewsPage({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductReviewsPage> createState() =>
      _ProductReviewsPageState();
}

class _ProductReviewsPageState extends ConsumerState<ProductReviewsPage> {
  _ReviewFilter _filter = _ReviewFilter.all;
  _ReviewSort _sort = _ReviewSort.mostRecent;
  bool _hasPurchased = true; // Assumed for demo; real app checks

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    await ref
        .read(productDetailProvider.notifier)
        .loadReviews(productId: widget.productId);
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

  // ─── Filtered & Sorted Reviews ────────────────────────────────────────

  List<MarketplaceReviewEntity> get _filteredReviews {
    var reviews = ref.read(productDetailProvider).reviews;

    // Filter by rating
    if (_filter != _ReviewFilter.all) {
      final rating = _filter.rating;
      reviews = reviews.where((r) => r.rating == rating).toList();
    }

    // Sort
    switch (_sort) {
      case _ReviewSort.mostRecent:
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _ReviewSort.mostHelpful:
        reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
      case _ReviewSort.highestRating:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
      case _ReviewSort.lowestRating:
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
    }

    return reviews;
  }

  // ─── Rating Distribution ──────────────────────────────────────────────

  Map<int, int> get _ratingDistribution {
    final reviews = ref.read(productDetailProvider).reviews;
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      if (r.rating >= 1 && r.rating <= 5) {
        dist[r.rating] = (dist[r.rating] ?? 0) + 1;
      }
    }
    return dist;
  }

  double get _averageRating {
    final reviews = ref.read(productDetailProvider).reviews;
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  // ─── Show Write Review Bottom Sheet ───────────────────────────────────

  void _showWriteReviewSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (_) => _WriteReviewSheet(
        productId: widget.productId,
        onSubmit: (review) async {
          await ref
              .read(productDetailProvider.notifier)
              .createReview(review: review);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider);

    // Listen for errors
    ref.listen<ProductDetailState>(productDetailProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        _showSnackBar(next.error!, isError: true);
        ref.read(productDetailProvider.notifier).clearError();
      }
    });

    final reviews = _filteredReviews;

    return Scaffold(
      appBar: AppAppBar(title: 'Reviews'),
      body: state.isLoading && !state.hasReviews
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && !state.hasReviews
              ? AppErrorState.serverError(onRetry: _loadReviews)
              : !state.hasReviews
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      child: CustomScrollView(
                        slivers: [
                          // ── Rating Summary ───────────────────────────
                          SliverToBoxAdapter(
                            child: _buildRatingSummary(state),
                          ),

                          // ── Filter Chips ────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildFilterChips(),
                          ),

                          // ── Sort Row ────────────────────────────────
                          SliverToBoxAdapter(
                            child: _buildSortRow(),
                          ),

                          // ── Reviews List ────────────────────────────
                          if (reviews.isEmpty)
                            SliverToBoxAdapter(
                              child: AppEmptyState(
                                icon: Icons.rate_review_outlined,
                                title: 'No Reviews Match',
                                subtitle:
                                    'Try a different filter to see reviews.',
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.lg,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final review = reviews[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: Spacings.md,
                                      ),
                                      child: ReviewCard(
                                        review: review,
                                        onHelpful: () {
                                          ref
                                              .read(
                                                  productDetailProvider.notifier)
                                              .voteReviewHelpful(
                                                reviewId: review.id,
                                                userId: 'current_user',
                                              );
                                        },
                                      ),
                                    );
                                  },
                                  childCount: reviews.length,
                                ),
                              ),
                            ),

                          // Bottom padding
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: Spacings.xxl),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: _hasPurchased
          ? AppFloatingActionButton(
              label: 'Write a Review',
              icon: Icons.rate_review_rounded,
              onPressed: _showWriteReviewSheet,
              extended: true,
            )
          : null,
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.rate_review_outlined,
      title: 'No Reviews Yet',
      subtitle: 'Be the first to review!',
      actionLabel: _hasPurchased ? 'Write a Review' : null,
      onAction: _hasPurchased ? _showWriteReviewSheet : null,
    );
  }

  // ─── Rating Summary ─────────────────────────────────────────────────────

  Widget _buildRatingSummary(ProductDetailState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final reviews = state.reviews;
    final totalReviews = reviews.length;
    final distribution = _ratingDistribution;
    final avg = _averageRating;

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: AppCard(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Average rating column ────────────────────────────────
            Column(
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: tt.displaySmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                StarRating(
                  rating: avg,
                  starSize: Spacings.mdIcon,
                  showCount: false,
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: Spacings.xl),

            // ── Rating breakdown bars ────────────────────────────────
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = distribution[star] ?? 0;
                  final percentage =
                      totalReviews > 0 ? count / totalReviews : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.xs),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: Spacings.xs),
                        Icon(
                          Icons.star_rounded,
                          size: Spacings.smIcon,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: Spacings.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: Spacings.borderRadiusSm,
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 6,
                              backgroundColor:
                                  cs.surfaceContainerHighest,
                              color: AppColors.warning,
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${(percentage * 100).toStringAsFixed(0)}%',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips ───────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _ReviewFilter.values.map((filter) {
            final isSelected = _filter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _filter = filter);
                },
                selectedColor: context.colorScheme.primary.withOpacity(context.isDarkMode ? 0.25 : 0.15,
                ),
                checkmarkColor: context.colorScheme.primary,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Sort Row ───────────────────────────────────────────────────────────

  Widget _buildSortRow() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.md,
        Spacings.lg,
        Spacings.sm,
      ),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _ReviewSort.values.map((sort) {
                  final isSelected = _sort == sort;
                  return Padding(
                    padding: const EdgeInsets.only(right: Spacings.sm),
                    child: ChoiceChip(
                      label: Text(sort.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _sort = sort);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEW FILTER ENUM (internal)
// ═══════════════════════════════════════════════════════════════════════════════

enum _ReviewFilter {
  all(label: 'All', rating: 0),
  fiveStar(label: '5 Star', rating: 5),
  fourStar(label: '4 Star', rating: 4),
  threeStar(label: '3 Star', rating: 3),
  twoStar(label: '2 Star', rating: 2),
  oneStar(label: '1 Star', rating: 1);

  const _ReviewFilter({required this.label, required this.rating});

  final String label;
  final int rating;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEW SORT ENUM (internal)
// ═══════════════════════════════════════════════════════════════════════════════

enum _ReviewSort {
  mostRecent(label: 'Most Recent'),
  mostHelpful(label: 'Most Helpful'),
  highestRating(label: 'Highest Rating'),
  lowestRating(label: 'Lowest Rating');

  const _ReviewSort({required this.label});

  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WRITE REVIEW SHEET (internal)
// ═══════════════════════════════════════════════════════════════════════════════

class _WriteReviewSheet extends StatefulWidget {
  const _WriteReviewSheet({
    required this.productId,
    required this.onSubmit,
  });

  final String productId;
  final Future<void> Function(MarketplaceReviewEntity review) onSubmit;

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _rating > 0 &&
        _contentController.text.trim().length >= 20;
  }

  Future<void> _submit() async {
    if (!_isValid) return;

    setState(() => _isSubmitting = true);

    final review = MarketplaceReviewEntity(
      id: '',
      productId: widget.productId,
      buyerId: 'current_user',
      sellerId: '',
      rating: _rating,
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      content: _contentController.text.trim(),
      isVerifiedPurchase: true,
      status: MarketplaceReviewStatus.published,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.onSubmit(review);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacings.lg,
        right: Spacings.lg,
        top: Spacings.xl,
        bottom: math.max(bottomInset, Spacings.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: Spacings.borderRadiusFull,
              ),
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // ── Title ──────────────────────────────────────────────────
          Text(
            'Write a Review',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // ── Star rating selector ───────────────────────────────────
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.xs),
                    child: Icon(
                      starValue <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: Spacings.xlIcon,
                      color: starValue <= _rating
                          ? AppColors.warning
                          : cs.outlineVariant,
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_rating == 0)
            Padding(
              padding: const EdgeInsets.only(top: Spacings.xs),
              child: Center(
                child: Text(
                  'Tap to rate',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const SizedBox(height: Spacings.lg),

          // ── Title field ────────────────────────────────────────────
          AppTextField(
            controller: _titleController,
            label: 'Review Title',
            hint: 'Summarize your experience',
            maxLength: 100,
          ),
          const SizedBox(height: Spacings.md),

          // ── Content field ──────────────────────────────────────────
          AppTextField(
            controller: _contentController,
            label: 'Your Review',
            hint: 'Tell others about your experience (min 20 characters)',
            maxLines: 5,
            minLines: 3,
            maxLength: 1000,
            isRequired: true,
            validator: (v) {
              if (v == null || v.trim().length < 20) {
                return 'Review must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: Spacings.xl),

          // ── Submit button ──────────────────────────────────────────
          AppButton(
            label: 'Submit Review',
            onPressed: _isValid ? _submit : null,
            variant: AppButtonVariant.elevated,
            fullWidth: true,
            isLoading: _isSubmitting,
            isDisabled: !_isValid,
          ),
        ],
      ),
    );
  }
}
