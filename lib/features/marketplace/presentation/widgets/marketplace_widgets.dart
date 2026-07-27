import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════
//
// Reusable widget library for the ExamForge AI Marketplace feature module.
// All widgets follow the project design system: AppCard, AppButton, Spacings,
// AppTypography, AppColors, and context extensions.
//
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 1. ProductCard ───────────────────────────────────────────────────────────

/// A card showing a marketplace product in a grid or list layout.
///
/// Displays a preview image placeholder, title, seller name, price with
/// optional strikethrough, star rating, and various badges (Free, AI Generated,
/// discount percentage, license type).
///
/// ```dart
/// ProductCard(
///   product: product,
///   onTap: () => navigateToDetail(product.id),
///   onWishlistTap: () => toggleWishlist(product.id),
///   isInWishlist: isWishlisted,
/// )
/// ```
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onWishlistTap,
    this.isInWishlist = false,
  });

  final MarketplaceProductEntity product;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final bool isInWishlist;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Product type colour tint for the preview placeholder.
    final typeColor = _productTypeColor(product.productType, cs);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Preview image placeholder ────────────────────────────────
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Spacings.mdRadius),
                  ),
                ),
                child: Center(
                  child: ProductTypeIcon(
                    type: product.productType,
                    size: Spacings.xlIcon,
                    color: typeColor,
                  ),
                ),
              ),

              // ── Badges overlay ───────────────────────────────────────
              Positioned(
                top: Spacings.sm,
                left: Spacings.sm,
                child: Wrap(
                  spacing: Spacings.xs,
                  runSpacing: Spacings.xs,
                  children: [
                    if (product.isFree)
                      const _Badge(
                        label: 'Free',
                        backgroundColor: AppColors.success,
                        textColor: Colors.white,
                      ),
                    if (product.isAiGenerated)
                      const _Badge(
                        label: 'AI Generated',
                        backgroundColor: AppColors.info,
                        textColor: Colors.white,
                      ),
                    if (product.isDiscounted)
                      _Badge(
                        label: '-${product.discountPercentage.toStringAsFixed(0)}%',
                        backgroundColor: AppColors.error,
                        textColor: Colors.white,
                      ),
                  ],
                ),
              ),

              // ── Wishlist button ──────────────────────────────────────
              Positioned(
                top: Spacings.sm,
                right: Spacings.sm,
                child: GestureDetector(
                  onTap: onWishlistTap,
                  child: Container(
                    padding: const EdgeInsets.all(Spacings.xs),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceCardDark.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isInWishlist
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: Spacings.mdIcon,
                      color: isInWishlist ? AppColors.error : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: Spacings.xs),

                // Seller name placeholder
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Expanded(
                      child: Text(
                        product.sellerId, // Placeholder: replaced by real name in UI
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Spacings.sm),

                // Price row
                Row(
                  children: [
                    PriceDisplay(
                      price: product.price,
                      originalPrice: product.isDiscounted ? product.originalPrice : null,
                      currency: product.currency,
                      isFree: product.isFree,
                    ),
                    const Spacer(),
                    LicenseBadge(licenseType: product.licenseType),
                  ],
                ),

                const SizedBox(height: Spacings.sm),

                // Rating row
                Row(
                  children: [
                    StarRating(
                      rating: product.averageRating,
                      totalReviews: product.totalReviews,
                      starSize: Spacings.smIcon,
                      showCount: true,
                    ),
                    const Spacer(),
                    if (product.downloadCount > 0) ...[
                      Icon(
                        Icons.download_rounded,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        _formatCount(product.downloadCount),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _productTypeColor(MarketplaceProductType type, ColorScheme cs) {
    return switch (type) {
      MarketplaceProductType.questionBank ||
      MarketplaceProductType.examTemplate ||
      MarketplaceProductType.assessmentRubric =>
        AppColors.info,
      MarketplaceProductType.lessonNote ||
      MarketplaceProductType.schemeOfWork ||
      MarketplaceProductType.studyGuide =>
        AppColors.success,
      MarketplaceProductType.powerpoint ||
      MarketplaceProductType.teachingSlides =>
        AppColors.warning,
      MarketplaceProductType.flashcards ||
      MarketplaceProductType.worksheet ||
      MarketplaceProductType.homeworkPack =>
        cs.primary,
      MarketplaceProductType.practicalManual ||
      MarketplaceProductType.laboratoryGuide =>
        cs.tertiary,
      MarketplaceProductType.curriculumPack ||
      MarketplaceProductType.classroomActivity =>
        cs.secondary,
      MarketplaceProductType.educationalImage ||
      MarketplaceProductType.educationalVideo ||
      MarketplaceProductType.educationalAudio =>
        AppColors.error,
      MarketplaceProductType.printableResource => cs.primaryContainer,
      MarketplaceProductType.other => cs.onSurfaceVariant,
    };
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

// ─── Internal badge helper ────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: AppTypography.wBold,
          color: textColor,
          letterSpacing: AppTypography.lsLabel,
          height: 1.4,
        ),
      ),
    );
  }
}

// ─── 2. ProductTypeIcon ───────────────────────────────────────────────────────

/// Returns an icon widget based on [MarketplaceProductType].
///
/// ```dart
/// ProductTypeIcon(type: MarketplaceProductType.questionBank)
/// ```
class ProductTypeIcon extends StatelessWidget {
  const ProductTypeIcon({
    super.key,
    required this.type,
    this.size = Spacings.mdIcon,
    this.color,
  });

  final MarketplaceProductType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colorScheme.primary;
    return Icon(
      _iconData,
      size: size,
      color: effectiveColor,
    );
  }

  IconData get _iconData => switch (type) {
        MarketplaceProductType.questionBank => Icons.quiz_rounded,
        MarketplaceProductType.examTemplate => Icons.assignment_rounded,
        MarketplaceProductType.lessonNote => Icons.note_rounded,
        MarketplaceProductType.schemeOfWork => Icons.map_rounded,
        MarketplaceProductType.worksheet => Icons.table_chart_rounded,
        MarketplaceProductType.powerpoint => Icons.slideshow_rounded,
        MarketplaceProductType.teachingSlides => Icons.present_to_all_rounded,
        MarketplaceProductType.flashcards => Icons.style_rounded,
        MarketplaceProductType.studyGuide => Icons.menu_book_rounded,
        MarketplaceProductType.practicalManual => Icons.science_rounded,
        MarketplaceProductType.laboratoryGuide => Icons.biotech_rounded,
        MarketplaceProductType.curriculumPack => Icons.folder_special_rounded,
        MarketplaceProductType.assessmentRubric => Icons.grading_rounded,
        MarketplaceProductType.homeworkPack => Icons.edit_note_rounded,
        MarketplaceProductType.classroomActivity => Icons.groups_rounded,
        MarketplaceProductType.educationalImage => Icons.image_rounded,
        MarketplaceProductType.educationalVideo => Icons.play_circle_rounded,
        MarketplaceProductType.educationalAudio => Icons.audiotrack_rounded,
        MarketplaceProductType.printableResource => Icons.print_rounded,
        MarketplaceProductType.other => Icons.widgets_rounded,
      };
}

// ─── 3. StarRating ────────────────────────────────────────────────────────────

/// Displays a row of 5 stars (filled, half-filled, or outlined) based on
/// [rating] with an optional review count.
///
/// ```dart
/// StarRating(rating: 4.3, totalReviews: 128, showCount: true)
/// ```
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.totalReviews,
    this.starSize = Spacings.mdIcon,
    this.showCount = true,
  });

  final double rating;
  final int? totalReviews;
  final double starSize;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 5 stars
        for (int i = 1; i <= 5; i++)
          Icon(
            _starIcon(i),
            size: starSize,
            color: AppColors.warning,
          ),
        // Count
        if (showCount && totalReviews != null) ...[
          const SizedBox(width: Spacings.xs),
          Text(
            '($totalReviews)',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  IconData _starIcon(int position) {
    if (rating >= position) return Icons.star_rounded;
    if (rating >= position - 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}

// ─── 4. LicenseBadge ──────────────────────────────────────────────────────────

/// Shows license type as a coloured chip / badge.
///
/// ```dart
/// LicenseBadge(licenseType: MarketplaceLicenseType.teacher)
/// ```
class LicenseBadge extends StatelessWidget {
  const LicenseBadge({
    super.key,
    required this.licenseType,
    this.fontSize = 10,
  });

  final MarketplaceLicenseType licenseType;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final (Color bg, Color fg) = _badgeColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        licenseType.label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: AppTypography.wSemiBold,
          color: fg,
          letterSpacing: AppTypography.lsLabel,
          height: 1.4,
        ),
      ),
    );
  }

  (Color, Color) _badgeColors(bool isDark) {
    return switch (licenseType) {
      MarketplaceLicenseType.personal => (
          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      MarketplaceLicenseType.teacher => (
          isDark ? AppColors.infoDark.withValues(alpha: 0.4) : AppColors.infoLight,
          isDark ? AppColors.infoLight : AppColors.info,
        ),
      MarketplaceLicenseType.school => (
          isDark ? Colors.indigo.shade900.withValues(alpha: 0.5) : Colors.indigo.shade100,
          isDark ? Colors.indigo.shade200 : Colors.indigo.shade700,
        ),
      MarketplaceLicenseType.department => (
          isDark ? Colors.purple.shade900.withValues(alpha: 0.5) : Colors.purple.shade100,
          isDark ? Colors.purple.shade200 : Colors.purple.shade700,
        ),
      MarketplaceLicenseType.enterprise => (
          isDark ? AppColors.warningDark.withValues(alpha: 0.4) : AppColors.warningLight,
          isDark ? AppColors.warningLight : AppColors.warning,
        ),
    };
  }
}

// ─── 5. PriceDisplay ──────────────────────────────────────────────────────────

/// Shows product price with optional original price strikethrough.
///
/// ```dart
/// PriceDisplay(price: 1500, originalPrice: 2500, currency: 'NGN')
/// ```
class PriceDisplay extends StatelessWidget {
  const PriceDisplay({
    super.key,
    required this.price,
    this.originalPrice,
    this.currency = 'NGN',
    this.fontSize = 14,
    this.isFree = false,
  });

  final double price;
  final double? originalPrice;
  final String currency;
  final double fontSize;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    if (isFree) {
      return Text(
        'Free',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: AppTypography.wBold,
          color: AppColors.success,
          letterSpacing: AppTypography.lsLabel,
        ),
      );
    }

    final hasDiscount = originalPrice != null && originalPrice! > price;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatPrice(price, currency),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: fontSize,
            fontWeight: AppTypography.wBold,
            color: cs.primary,
            letterSpacing: AppTypography.lsLabel,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: Spacings.xs),
          Text(
            _formatPrice(originalPrice!, currency),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: fontSize - 2,
              fontWeight: AppTypography.wRegular,
              color: cs.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              decorationColor: cs.onSurfaceVariant,
              letterSpacing: AppTypography.lsLabel,
            ),
          ),
        ],
      ],
    );
  }

  String _formatPrice(double amount, String curr) {
    final symbol = switch (curr) {
      'NGN' => '\u20A6',
      'USD' => '\$',
      'GBP' => '\u00A3',
      'EUR' => '\u20AC',
      _ => '$curr ',
    };
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}

// ─── 6. CategoryChip ──────────────────────────────────────────────────────────

/// Category selection chip used in filter bars and category lists.
///
/// ```dart
/// CategoryChip(
///   category: category,
///   isSelected: selectedCategory?.id == category.id,
///   onTap: () => selectCategory(category),
/// )
/// ```
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final MarketplaceCategoryEntity category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Spacings.fullRadius),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          category.name,
          style: tt.labelMedium?.copyWith(
            fontWeight: isSelected ? AppTypography.wSemiBold : AppTypography.wMedium,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── 7. ReviewCard ────────────────────────────────────────────────────────────

/// Displays a single review with reviewer info, star rating, content,
/// helpful button, and optional seller response.
///
/// ```dart
/// ReviewCard(
///   review: review,
///   onHelpful: () => voteHelpful(review.id),
///   isSeller: true,
///   onRespond: () => respondToReview(review.id),
/// )
/// ```
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
    this.onReport,
    this.onRespond,
    this.isSeller = false,
  });

  final MarketplaceReviewEntity review;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;
  final VoidCallback? onRespond;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reviewer row ─────────────────────────────────────────────
          Row(
            children: [
              // Avatar placeholder
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primary.withValues(alpha: isDark ? 0.30 : 0.15),
                child: Text(
                  review.buyerId.isNotEmpty ? review.buyerId[0].toUpperCase() : '?',
                  style: tt.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.buyerId, // Placeholder for real name
                          style: tt.labelMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: Spacings.xs),
                          const Icon(
                            Icons.verified_rounded,
                            size: Spacings.smIcon,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    StarRating(
                      rating: review.rating.toDouble(),
                      starSize: Spacings.smIcon,
                      showCount: false,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Title ────────────────────────────────────────────────────
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Text(
              review.title!,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
          ],

          // ── Content ──────────────────────────────────────────────────
          if (review.content != null && review.content!.isNotEmpty) ...[
            const SizedBox(height: Spacings.xs),
            Text(
              review.content!,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Action row ───────────────────────────────────────────────
          Row(
            children: [
              // Helpful button
              _ActionChip(
                icon: Icons.thumb_up_outlined,
                label: review.helpfulCount > 0
                    ? 'Helpful (${review.helpfulCount})'
                    : 'Helpful',
                onTap: onHelpful,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.sm),

              // Report button
              if (!isSeller)
                _ActionChip(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  onTap: onReport,
                  color: cs.onSurfaceVariant,
                ),

              const Spacer(),

              // Seller respond button
              if (isSeller && onRespond != null && !review.hasSellerResponse)
                _ActionChip(
                  icon: Icons.reply_rounded,
                  label: 'Respond',
                  onTap: onRespond,
                  color: cs.primary,
                ),
            ],
          ),

          // ── Seller response ──────────────────────────────────────────
          if (review.hasSellerResponse) ...[
            const SizedBox(height: Spacings.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: isDark ? 0.2 : 0.3),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: Spacings.smIcon,
                        color: cs.primary,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Seller Response',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    review.sellerResponse!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Internal action chip ─────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Spacings.smRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Spacings.smIcon, color: color),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 8. QualityScoreCard ──────────────────────────────────────────────────────

/// Shows AI quality check results with overall circular score, individual
/// score bars, reading level, flagged issues, and suggestions.
///
/// ```dart
/// QualityScoreCard(qualityCheck: qualityCheck)
/// ```
class QualityScoreCard extends StatelessWidget {
  const QualityScoreCard({
    super.key,
    required this.qualityCheck,
  });

  final QualityCheckEntity qualityCheck;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final overallColor = _scoreColor(qualityCheck.overallScore);

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Text(
            'Quality Check',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // ── Overall score (circular) ─────────────────────────────────
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: qualityCheck.overallScore / 100,
                        strokeWidth: 8,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: overallColor,
                      ),
                      Center(
                        child: Text(
                          '${qualityCheck.overallScore.toStringAsFixed(0)}%',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: overallColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  qualityCheck.computedStatus.label,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: overallColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacings.xl),

          // ── Individual scores ────────────────────────────────────────
          _ScoreBar(
            label: 'Grammar',
            score: qualityCheck.grammarScore,
            color: _scoreColor(qualityCheck.grammarScore),
          ),
          const SizedBox(height: Spacings.sm),
          _ScoreBar(
            label: 'Spelling',
            score: qualityCheck.spellingScore,
            color: _scoreColor(qualityCheck.spellingScore),
          ),
          const SizedBox(height: Spacings.sm),
          _ScoreBar(
            label: 'Formatting',
            score: qualityCheck.formattingScore,
            color: _scoreColor(qualityCheck.formattingScore),
          ),
          const SizedBox(height: Spacings.sm),
          _ScoreBar(
            label: 'Curriculum Alignment',
            score: qualityCheck.curriculumAlignmentScore,
            color: _scoreColor(qualityCheck.curriculumAlignmentScore),
          ),

          // ── Reading level ────────────────────────────────────────────
          if (qualityCheck.readingLevelLabel != null) ...[
            const SizedBox(height: Spacings.lg),
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: Spacings.mdIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Reading Level: ',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  qualityCheck.readingLevelLabel!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // ── Flagged issues ───────────────────────────────────────────
          if (qualityCheck.hasIssues) ...[
            const SizedBox(height: Spacings.lg),
            Text(
              'Flagged Issues',
              style: tt.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: qualityCheck.flaggedIssues.map((issue) {
                return Chip(
                  label: Text(
                    issue,
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.errorOf(cs.brightness),
                    ),
                  ),
                  avatar: Icon(
                    Icons.warning_amber_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  backgroundColor: AppColors.errorOf(cs.brightness).withValues(alpha: isDark ? 0.15 : 0.1,
                  ),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.only(right: Spacings.sm),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],

          // ── Suggestions ──────────────────────────────────────────────
          if (qualityCheck.hasSuggestions) ...[
            const SizedBox(height: Spacings.lg),
            Text(
              'Suggestions',
              style: tt.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            ...qualityCheck.suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: Spacings.smIcon,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Duplicate detection ──────────────────────────────────────
          if (qualityCheck.duplicateCheckResult != null) ...[
            const SizedBox(height: Spacings.lg),
            Row(
              children: [
                Icon(
                  Icons.content_copy_rounded,
                  size: Spacings.mdIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duplicate Detection',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Similarity: ${(qualityCheck.duplicateCheckResult!['similarity'] as num?)?.toStringAsFixed(1) ?? 'N/A'}%',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Internal score bar ───────────────────────────────────────────────────────

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        SizedBox(
          width: 36,
          child: Text(
            score.toStringAsFixed(0),
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ─── 9. EmptyMarketplaceState ─────────────────────────────────────────────────

/// Custom empty state for marketplace screens.
///
/// Wraps [AppEmptyState] with marketplace-specific styling and defaults.
///
/// ```dart
/// EmptyMarketplaceState(
///   title: 'No Products Found',
///   subtitle: 'Try a different search or category.',
///   icon: Icons.search_off_rounded,
///   actionLabel: 'Browse All',
///   onAction: () => browseAll(),
/// )
/// ```
class EmptyMarketplaceState extends StatelessWidget {
  const EmptyMarketplaceState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.storefront_outlined,
    this.onAction,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

// ─── 10. SellerInfoCard ───────────────────────────────────────────────────────

/// Shows seller profile summary with avatar, verification badge, stats.
///
/// ```dart
/// SellerInfoCard(seller: seller, onTap: () => viewSeller(seller.id))
/// ```
class SellerInfoCard extends StatelessWidget {
  const SellerInfoCard({
    super.key,
    required this.seller,
    this.onTap,
  });

  final SellerProfileEntity seller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // ── Avatar ───────────────────────────────────────────────────
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withValues(alpha: isDark ? 0.30 : 0.15),
            child: seller.avatarUrl != null
                ? ClipOval(
                    child: Icon(
                      Icons.person_rounded,
                      size: Spacings.lgIcon,
                      color: cs.primary,
                    ),
                  )
                : Text(
                    seller.displayName.isNotEmpty
                        ? seller.displayName[0].toUpperCase()
                        : '?',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
          ),
          const SizedBox(width: Spacings.md),

          // ── Info column ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + verified
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.displayName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (seller.isVerified) ...[
                      const SizedBox(width: Spacings.xs),
                      const Icon(
                        Icons.verified_rounded,
                        size: Spacings.mdIcon,
                        color: AppColors.info,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacings.xs),

                // Stats row
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.inventory_2_outlined,
                      value: '${seller.totalProducts}',
                      label: 'Products',
                    ),
                    const SizedBox(width: Spacings.md),
                    _StatItem(
                      icon: Icons.shopping_bag_outlined,
                      value: '${seller.totalSales}',
                      label: 'Sales',
                    ),
                    const SizedBox(width: Spacings.md),
                    _StatItem(
                      icon: Icons.star_outline_rounded,
                      value: seller.averageRating.toStringAsFixed(1),
                      label: 'Rating',
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

// ─── Internal stat item ───────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text(
          value,
          style: tt.labelSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── 11. FilterBottomSheet ────────────────────────────────────────────────────

/// Filter options bottom sheet for marketplace product filtering.
///
/// Shows category, product type, subject, class level, curriculum, and
/// price range filters with Apply/Reset buttons.
///
/// ```dart
/// FilterBottomSheet(
///   categories: categories,
///   selectedCategory: currentCategory,
///   onApply: (cat, type, subject, level, curriculum, min, max) {
///     applyFilters(...);
///   },
/// )
/// ```
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.selectedType,
    this.selectedSubject,
    this.selectedClassLevel,
    this.selectedCurriculum,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  final List<MarketplaceCategoryEntity> categories;
  final MarketplaceCategoryEntity? selectedCategory;
  final MarketplaceProductType? selectedType;
  final String? selectedSubject;
  final String? selectedClassLevel;
  final String? selectedCurriculum;
  final double? minPrice;
  final double? maxPrice;
  final void Function(
    MarketplaceCategoryEntity?,
    MarketplaceProductType?,
    String?,
    String?,
    String?,
    double?,
    double?,
  ) onApply;

  /// Convenience method to show this sheet.
  static Future<void> show(
    BuildContext context, {
    required List<MarketplaceCategoryEntity> categories,
    MarketplaceCategoryEntity? selectedCategory,
    MarketplaceProductType? selectedType,
    String? selectedSubject,
    String? selectedClassLevel,
    String? selectedCurriculum,
    double? minPrice,
    double? maxPrice,
    required void Function(
      MarketplaceCategoryEntity?,
      MarketplaceProductType?,
      String?,
      String?,
      String?,
      double?,
      double?,
    ) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (_) => FilterBottomSheet(
        categories: categories,
        selectedCategory: selectedCategory,
        selectedType: selectedType,
        selectedSubject: selectedSubject,
        selectedClassLevel: selectedClassLevel,
        selectedCurriculum: selectedCurriculum,
        minPrice: minPrice,
        maxPrice: maxPrice,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late MarketplaceCategoryEntity? _category;
  late MarketplaceProductType? _type;
  late TextEditingController _subjectController;
  late String? _classLevel;
  late String? _curriculum;
  late RangeValues _priceRange;

  static const List<String> _classLevels = [
    'JSS1',
    'JSS2',
    'JSS3',
    'SS1',
    'SS2',
    'SS3',
  ];

  static const List<String> _curriculums = [
    'WAEC',
    'NECO',
    'NABTEB',
    'IGCSE',
    'Common Entrance',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _type = widget.selectedType;
    _subjectController = TextEditingController(text: widget.selectedSubject ?? '');
    _classLevel = widget.selectedClassLevel;
    _curriculum = widget.selectedCurriculum;
    _priceRange = RangeValues(
      widget.minPrice ?? 0,
      widget.maxPrice ?? 50000,
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
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
        top: Spacings.lg,
        bottom: math.max(Spacings.lg, bottomInset),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
              ),
            ),
            const SizedBox(height: Spacings.lg),

            // ── Title ───────────────────────────────────────────────────
            Text(
              'Filter Products',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.xl),

            // ── Category dropdown ───────────────────────────────────────
            const _FilterLabel(label: 'Category'),
            const SizedBox(height: Spacings.xs),
            DropdownButtonFormField<MarketplaceCategoryEntity>(
              initialValue: _category,
              decoration: InputDecoration(
                hintText: 'All Categories',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
              ),
              items: [
                const DropdownMenuItem<MarketplaceCategoryEntity>(
                  child: Text('All Categories'),
                ),
                ...widget.categories.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),

            const SizedBox(height: Spacings.lg),

            // ── Product type dropdown ───────────────────────────────────
            const _FilterLabel(label: 'Product Type'),
            const SizedBox(height: Spacings.xs),
            DropdownButtonFormField<MarketplaceProductType>(
              initialValue: _type,
              decoration: InputDecoration(
                hintText: 'All Types',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
              ),
              items: [
                const DropdownMenuItem<MarketplaceProductType>(
                  child: Text('All Types'),
                ),
                ...MarketplaceProductType.values.map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),

            const SizedBox(height: Spacings.lg),

            // ── Subject input ───────────────────────────────────────────
            const _FilterLabel(label: 'Subject'),
            const SizedBox(height: Spacings.xs),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'e.g. Mathematics',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
              ),
            ),

            const SizedBox(height: Spacings.lg),

            // ── Class level dropdown ────────────────────────────────────
            const _FilterLabel(label: 'Class Level'),
            const SizedBox(height: Spacings.xs),
            DropdownButtonFormField<String>(
              initialValue: _classLevel,
              decoration: InputDecoration(
                hintText: 'All Levels',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(child: Text('All Levels')),
                ..._classLevels.map(
                  (l) => DropdownMenuItem(value: l, child: Text(l)),
                ),
              ],
              onChanged: (v) => setState(() => _classLevel = v),
            ),

            const SizedBox(height: Spacings.lg),

            // ── Curriculum dropdown ─────────────────────────────────────
            const _FilterLabel(label: 'Curriculum'),
            const SizedBox(height: Spacings.xs),
            DropdownButtonFormField<String>(
              initialValue: _curriculum,
              decoration: InputDecoration(
                hintText: 'All Curricula',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(child: Text('All Curricula')),
                ..._curriculums.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => setState(() => _curriculum = v),
            ),

            const SizedBox(height: Spacings.lg),

            // ── Price range slider ──────────────────────────────────────
            const _FilterLabel(label: 'Price Range'),
            const SizedBox(height: Spacings.sm),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 50000,
              divisions: 50,
              labels: RangeLabels(
                '\u20A6${_priceRange.start.toStringAsFixed(0)}',
                '\u20A6${_priceRange.end.toStringAsFixed(0)}',
              ),
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u20A6${_priceRange.start.toStringAsFixed(0)}',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  '\u20A6${_priceRange.end.toStringAsFixed(0)}',
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: Spacings.xl),

            // ── Action buttons ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Reset',
                    onPressed: _reset,
                    variant: AppButtonVariant.outlined,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppButton(
                    label: 'Apply',
                    onPressed: _apply,
                    variant: AppButtonVariant.elevated,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _apply() {
    widget.onApply(
      _category,
      _type,
      _subjectController.text.isEmpty ? null : _subjectController.text,
      _classLevel,
      _curriculum,
      _priceRange.start == 0 ? null : _priceRange.start,
      _priceRange.end >= 50000 ? null : _priceRange.end,
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _category = null;
      _type = null;
      _subjectController.clear();
      _classLevel = null;
      _curriculum = null;
      _priceRange = const RangeValues(0, 50000);
    });
  }
}

// ─── Internal filter label ────────────────────────────────────────────────────

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Text(
      label,
      style: tt.labelMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: cs.onSurface,
      ),
    );
  }
}

// ─── 12. NotificationBadge ────────────────────────────────────────────────────

/// Unread notification count badge. Shows a red circle with white text when
/// [count] > 0, invisible otherwise.
///
/// ```dart
/// NotificationBadge(count: 5, size: 20)
/// ```
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
  });

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final displayText = count > 99 ? '99+' : '$count';
    final fontSize = count > 99 ? size * 0.35 : size * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: AppTypography.wBold,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── 13. CommissionBreakdownCard ──────────────────────────────────────────────

/// Shows commission breakdown for an order with itemised amounts.
///
/// ```dart
/// CommissionBreakdownCard(
///   subtotal: 2000,
///   platformFee: 300,
///   sellerRevenue: 1700,
///   currency: 'NGN',
/// )
/// ```
class CommissionBreakdownCard extends StatelessWidget {
  const CommissionBreakdownCard({
    super.key,
    required this.subtotal,
    required this.platformFee,
    required this.sellerRevenue,
    this.currency = 'NGN',
  });

  final double subtotal;
  final double platformFee;
  final double sellerRevenue;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commission Breakdown',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          const Divider(height: 1),
          const SizedBox(height: Spacings.sm),

          // Subtotal
          _BreakdownRow(
            label: 'Subtotal',
            amount: _formatAmount(subtotal),
            labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            amountStyle: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wMedium,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // Platform fee
          _BreakdownRow(
            label: 'Platform Fee',
            amount: _formatAmount(platformFee),
            labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            amountStyle: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wMedium,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: Spacings.sm),

          const Divider(height: 1),
          const SizedBox(height: Spacings.sm),

          // Seller revenue
          _BreakdownRow(
            label: 'Seller Revenue',
            amount: _formatAmount(sellerRevenue),
            labelStyle: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            amountStyle: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final symbol = switch (currency) {
      'NGN' => '\u20A6',
      'USD' => '\$',
      'GBP' => '\u00A3',
      'EUR' => '\u20AC',
      _ => '$currency ',
    };
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

// ─── Internal breakdown row ───────────────────────────────────────────────────

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    this.labelStyle,
    this.amountStyle,
  });

  final String label;
  final String amount;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(amount, style: amountStyle),
      ],
    );
  }
}

// ─── 14. SortDropdown ─────────────────────────────────────────────────────────

/// Sort options selector dropdown for marketplace product lists.
///
/// ```dart
/// SortDropdown(
///   currentSort: 'popular',
///   onChanged: (value) => updateSort(value),
/// )
/// ```
class SortDropdown extends StatelessWidget {
  const SortDropdown({
    super.key,
    required this.currentSort,
    required this.onChanged,
  });

  final String currentSort;
  final ValueChanged<String> onChanged;

  /// Available sort options.
  static const List<MapEntry<String, String>> sortOptions = [
    MapEntry('newest', 'Newest'),
    MapEntry('popular', 'Popular'),
    MapEntry('highest_rated', 'Highest Rated'),
    MapEntry('price_low_high', 'Price: Low to High'),
    MapEntry('price_high_low', 'Price: High to Low'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSort,
          isDense: true,
          icon: Icon(
            Icons.unfold_more_rounded,
            size: Spacings.mdIcon,
            color: cs.onSurfaceVariant,
          ),
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface,
          ),
          items: sortOptions
              .map(
                (option) => DropdownMenuItem(
                  value: option.key,
                  child: Text(option.value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
