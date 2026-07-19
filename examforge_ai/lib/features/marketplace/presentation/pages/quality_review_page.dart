import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/seller_provider.dart';
import '../providers/quality_check_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'create_product_page.dart';
import 'product_detail_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AI QUALITY REVIEW PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// AI Quality Review Dashboard for reviewing product quality scores,
/// flagged issues, duplicate detection, and improvement suggestions.
///
/// If [productId] is provided, shows quality review for that specific product.
/// Otherwise, shows a product selector and all products that need review.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => QualityReviewPage(productId: 'abc123'),
/// ));
/// ```
class QualityReviewPage extends ConsumerStatefulWidget {
  const QualityReviewPage({super.key, this.productId});

  /// Optional product ID to show quality review for a specific product.
  final String? productId;

  @override
  ConsumerState<QualityReviewPage> createState() => _QualityReviewPageState();
}

class _QualityReviewPageState extends ConsumerState<QualityReviewPage> {
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.productId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // ─── Load initial data ───────────────────────────────────────────────

  void _loadInitialData() {
    final sellerState = ref.read(sellerProvider);

    // If no specific product, try to select the first one
    if (_selectedProductId == null && sellerState.hasProducts) {
      setState(() {
        _selectedProductId = sellerState.products.first.id;
      });
    }

    // Load quality check if we have a product
    if (_selectedProductId != null) {
      ref
          .read(qualityCheckProvider.notifier)
          .loadQualityCheck(productId: _selectedProductId!);
    }
  }

  // ─── Run quality check ───────────────────────────────────────────────

  void _runQualityCheck() {
    if (_selectedProductId == null) return;
    ref
        .read(qualityCheckProvider.notifier)
        .runQualityCheck(productId: _selectedProductId!);
  }

  // ─── Navigate to edit product ────────────────────────────────────────

  void _navigateToEditProduct() {
    if (_selectedProductId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProductPage(productId: _selectedProductId),
      ),
    );
  }

  // ─── Navigate to view product ────────────────────────────────────────

  void _navigateToViewProduct() {
    if (_selectedProductId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: _selectedProductId!),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final sellerState = ref.watch(sellerProvider);
    final qualityState = ref.watch(qualityCheckProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Quality Review',
        actions: [
          AppIconButton(
            icon: Icons.refresh,
            onPressed: _selectedProductId != null ? _runQualityCheck : null,
            variant: AppIconButtonVariant.standard,
            tooltip: 'Run Quality Check',
            isLoading: qualityState.isRunningCheck,
          ),
          const SizedBox(width: Spacings.sm),
        ],
      ),
      body: _buildBody(cs, tt, sellerState, qualityState),
    );
  }

  // ─── Body builder ────────────────────────────────────────────────────

  Widget _buildBody(
    ColorScheme cs,
    TextTheme tt,
    SellerState sellerState,
    QualityCheckState qualityState,
  ) {
    // Loading state
    if (qualityState.isLoading && !qualityState.hasQualityCheck) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    // Error state
    if (qualityState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Spacings.xlIcon,
              color: AppColors.error,
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              'Failed to load quality data',
              style: tt.titleMedium?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              qualityState.error!,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.lg),
            AppButton(
              label: 'Retry',
              onPressed: () {
                ref.read(qualityCheckProvider.notifier).clearError();
                if (_selectedProductId != null) {
                  ref
                      .read(qualityCheckProvider.notifier)
                      .loadQualityCheck(productId: _selectedProductId!);
                }
              },
              variant: AppButtonVariant.elevated,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product selector
          _buildProductSelector(cs, tt, sellerState),
          Spacings.sectionGap,

          // If no product selected, show empty state
          if (_selectedProductId == null)
            _buildNoProductSelected(cs, tt)
          else ...[
            // Quality overview card
            _buildQualityOverview(cs, tt, qualityState),
            Spacings.sectionGap,

            // Detailed scores
            if (qualityState.qualityCheck != null) ...[
              _buildDetailedScores(cs, tt, qualityState.qualityCheck!),
              Spacings.sectionGap,

              // Duplicate detection
              _buildDuplicateDetection(cs, tt, qualityState.qualityCheck!),
              Spacings.sectionGap,

              // Accuracy check
              _buildAccuracyCheck(cs, tt, qualityState.qualityCheck!),
              Spacings.sectionGap,

              // Flagged issues
              _buildFlaggedIssues(cs, tt, qualityState.qualityCheck!),
              Spacings.sectionGap,

              // Suggestions
              _buildSuggestions(cs, tt, qualityState.qualityCheck!),
              Spacings.sectionGap,

              // Quality history
              _buildQualityHistory(cs, tt, qualityState),
              Spacings.sectionGap,

              // Action buttons
              _buildActionButtons(cs, tt, qualityState),
            ] else ...[
              _buildNoQualityCheck(cs, tt),
            ],
          ],

          // Bottom padding
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRODUCT SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildProductSelector(
    ColorScheme cs,
    TextTheme tt,
    SellerState sellerState,
  ) {
    if (!sellerState.hasProducts) {
      return AppCard(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: Spacings.xlIcon,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'No products found',
              style: tt.titleMedium?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Create a product first to run quality checks.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return AppDropdownField<String>(
      label: 'Select Product',
      hint: 'Choose a product to review',
      items: sellerState.products.map((p) => p.id).toList(),
      selectedItem: _selectedProductId,
      onChanged: (id) {
        if (id != null) {
          setState(() => _selectedProductId = id);
          ref.read(qualityCheckProvider.notifier).loadQualityCheck(productId: id);
        }
      },
      itemLabel: (id) {
        final product = sellerState.products.firstWhere(
          (p) => p.id == id,
          orElse: () => MarketplaceProductEntity(
            id: id,
            sellerId: '',
            categoryId: '',
            title: 'Unknown',
            slug: '',
            productType: MarketplaceProductType.other,
            licenseType: MarketplaceLicenseType.personal,
            status: MarketplaceProductStatus.draft,
            qualityCheckStatus: QualityCheckStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return product.title;
      },
      prefixIcon: Icons.inventory_2_outlined,
      isRequired: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NO PRODUCT / NO QUALITY CHECK STATES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildNoProductSelected(ColorScheme cs, TextTheme tt) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: Spacings.xlIcon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacings.md),
          Text(
            'Select a product to review',
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Choose a product from the dropdown above to view its quality review.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoQualityCheck(ColorScheme cs, TextTheme tt) {
    return AppCard(
      child: Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: Spacings.xlIcon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacings.md),
          Text(
            'No quality check yet',
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Run a quality check to see the AI analysis of this product.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.lg),
          AppButton(
            label: 'Run Quality Check',
            onPressed: _runQualityCheck,
            variant: AppButtonVariant.elevated,
            icon: Icons.play_arrow,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUALITY OVERVIEW CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQualityOverview(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckState qualityState,
  ) {
    final check = qualityState.qualityCheck;
    if (check == null) return const SizedBox.shrink();

    final scoreColor = check.overallScore >= 80
        ? AppColors.success
        : check.overallScore >= 50
            ? AppColors.warning
            : AppColors.error;

    final statusLabel = check.computedStatus.label;
    final statusIcon = switch (check.computedStatus) {
      QualityCheckStatus.passed => Icons.check_circle,
      QualityCheckStatus.needsImprovement => Icons.warning_amber,
      QualityCheckStatus.failed => Icons.cancel,
      QualityCheckStatus.pending => Icons.hourglass_empty,
    };

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular score indicator
              _buildCircularScore(cs, tt, check.overallScore, scoreColor),
              const SizedBox(width: Spacings.xl),

              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Overview',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.md),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.md,
                        vertical: Spacings.sm,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(
                          alpha: context.isDarkMode ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: Spacings.mdIcon, color: scoreColor),
                          const SizedBox(width: Spacings.sm),
                          Text(
                            statusLabel,
                            style: tt.labelLarge?.copyWith(
                              color: scoreColor,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacings.md),

                    // Quick stats
                    Text(
                      '${check.flaggedIssues.length} issues · '
                      '${check.suggestions.length} suggestions',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacings.md),

                    // Run new check button
                    AppButton(
                      label: 'Run New Check',
                      onPressed: _runQualityCheck,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      icon: Icons.refresh,
                      isLoading: qualityState.isRunningCheck,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore(
    ColorScheme cs,
    TextTheme tt,
    double score,
    Color color,
  ) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              color: cs.surfaceContainerHighest,
            ),
          ),
          // Score circle
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.toStringAsFixed(0)}',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: color,
                  height: 1.0,
                ),
              ),
              Text(
                '%',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: color,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DETAILED SCORES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDetailedScores(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Scores',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        // Grammar Score
        _buildScoreBar(cs, tt, 'Grammar', check.grammarScore, Icons.spellcheck),
        Spacings.itemGap,

        // Spelling Score
        _buildScoreBar(cs, tt, 'Spelling', check.spellingScore, Icons.text_fields),
        Spacings.itemGap,

        // Formatting Score
        _buildScoreBar(cs, tt, 'Formatting', check.formattingScore, Icons.format_paint),
        Spacings.itemGap,

        // Curriculum Alignment Score
        _buildScoreBar(cs, tt, 'Curriculum Alignment', check.curriculumAlignmentScore, Icons.school_outlined),
        Spacings.itemGap,

        // Reading Level
        _buildReadingLevelBadge(cs, tt, check),
      ],
    );
  }

  Widget _buildScoreBar(
    ColorScheme cs,
    TextTheme tt,
    String label,
    double score,
    IconData icon,
  ) {
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Spacings.mdIcon, color: color),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  label,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingLevelBadge(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    final readingLevel = check.readingLevelLabel ?? 'Unknown';
    final icon = switch (readingLevel.toLowerCase()) {
      'elementary' => Icons.child_care,
      'middle school' => Icons.psychology,
      'high school' => Icons.school,
      'college' => Icons.military_tech,
      _ => Icons.auto_stories,
    };
    final color = switch (readingLevel.toLowerCase()) {
      'elementary' => AppColors.success,
      'middle school' => AppColors.info,
      'high school' => AppColors.warning,
      'college' => AppColors.seed,
      _ => cs.onSurfaceVariant,
    };

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(icon, size: Spacings.mdIcon, color: color),
          ),
          const SizedBox(width: Spacings.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Level',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                readingLevel,
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (check.readingLevel > 0)
            Text(
              'Score: ${check.readingLevel.toStringAsFixed(1)}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DUPLICATE DETECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDuplicateDetection(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    final hasDuplicates = check.duplicateCheckResult != null &&
        check.duplicateCheckResult!['hasDuplicates'] == true;

    final similarProducts = hasDuplicates
        ? (check.duplicateCheckResult!['similarProducts'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            []
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duplicate Detection',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDuplicates
                        ? Icons.content_copy
                        : Icons.verified_user_outlined,
                    size: Spacings.mdIcon,
                    color: hasDuplicates ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      hasDuplicates
                          ? 'Potential Duplicates Found'
                          : 'No Duplicates Found',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: hasDuplicates ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              if (!hasDuplicates) ...[
                const SizedBox(height: Spacings.sm),
                Text(
                  'Your product appears to be original. No similar content '
                  'was detected in the marketplace.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],

              if (hasDuplicates && similarProducts.isNotEmpty) ...[
                const SizedBox(height: Spacings.md),
                Text(
                  'The following products may be similar to yours:',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacings.sm),
                ...similarProducts.map((product) {
                  final similarity = (product['similarity'] as num?)?.toDouble() ?? 0;
                  final title = product['title'] as String? ?? 'Unknown Product';
                  final similarityColor = similarity >= 80
                      ? AppColors.error
                      : similarity >= 50
                          ? AppColors.warning
                          : AppColors.success;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.sm),
                    child: AppInfoCard(
                      title: title,
                      subtitle: 'Similarity: ${similarity.toStringAsFixed(0)}%',
                      icon: Icons.content_copy,
                      iconColor: similarityColor,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: Spacings.xs,
                        ),
                        decoration: BoxDecoration(
                          color: similarityColor.withValues(
                            alpha: context.isDarkMode ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          '${similarity.toStringAsFixed(0)}%',
                          style: tt.labelSmall?.copyWith(
                            color: similarityColor,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACCURACY CHECK
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAccuracyCheck(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accuracy Check',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    check.accuracyFlag
                        ? Icons.report_problem
                        : Icons.verified_outlined,
                    size: Spacings.mdIcon,
                    color: check.accuracyFlag ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      check.accuracyFlag
                          ? 'Accuracy Issues Detected'
                          : 'No Accuracy Issues',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: check.accuracyFlag ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              if (!check.accuracyFlag) ...[
                const SizedBox(height: Spacings.sm),
                Text(
                  'No factual accuracy issues were detected in this product.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],

              if (check.accuracyFlag && check.accuracyDetails != null) ...[
                const SizedBox(height: Spacings.md),
                ...() {
                  final items = <Widget>[];
                  final details = check.accuracyDetails!;

                  // Handle flagged items
                  final flaggedItems = details['flaggedItems'];
                  if (flaggedItems is List) {
                    for (var i = 0; i < flaggedItems.length; i++) {
                      final item = flaggedItems[i];
                      if (item is Map<String, dynamic>) {
                        items.add(Padding(
                          padding: const EdgeInsets.only(bottom: Spacings.sm),
                          child: AppInfoCard(
                            title: item['section'] as String? ?? 'Section ${i + 1}',
                            subtitle: item['issue'] as String? ?? 'Potential inaccuracy detected',
                            icon: Icons.warning_amber,
                            iconColor: AppColors.warning,
                          ),
                        ));
                      }
                    }
                  }

                  if (items.isEmpty) {
                    items.add(Text(
                      'Accuracy details are available but no specific items were flagged.',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ));
                  }

                  return items;
                }(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FLAGGED ISSUES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFlaggedIssues(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    if (!check.hasIssues) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flagged Issues',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        ...check.flaggedIssues.asMap().entries.map((entry) {
          final index = entry.key;
          final issue = entry.value;

          // Determine severity based on position (simulated)
          final severity = index < 2 ? _Severity.high : _Severity.medium;
          final severityColor = severity.color;

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: AppCard(
              borderColor: severityColor.withValues(alpha: 0.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity indicator
                  Container(
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(
                        alpha: context.isDarkMode ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Icon(
                      severity.icon,
                      size: Spacings.mdIcon,
                      color: severityColor,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Issue ${index + 1}',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: AppTypography.wSemiBold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: Spacings.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: Spacings.xs,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(
                                  alpha: context.isDarkMode ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(Spacings.smRadius),
                              ),
                              child: Text(
                                severity.label,
                                style: tt.labelSmall?.copyWith(
                                  color: severityColor,
                                  fontWeight: AppTypography.wSemiBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          issue,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSuggestions(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    if (!check.hasSuggestions) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Improvement Suggestions',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        ...check.suggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final suggestion = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(
                        alpha: context.isDarkMode ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: Spacings.mdIcon,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggestion ${index + 1}',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          suggestion,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacings.sm),
                        Row(
                          children: [
                            AppButton(
                              label: 'Apply',
                              onPressed: () {
                                context.scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Suggestion "$suggestion" noted for application'),
                                    backgroundColor: AppColors.info,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              variant: AppButtonVariant.tonal,
                              size: AppButtonSize.small,
                              icon: Icons.check,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUALITY HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQualityHistory(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckState qualityState,
  ) {
    if (qualityState.qualityHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality History',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),

        // Score trend
        if (qualityState.qualityHistory.length > 1)
          _buildScoreTrend(cs, tt, qualityState.qualityHistory),

        // Timeline
        ...qualityState.qualityHistory.map((check) {
          final scoreColor = check.overallScore >= 80
              ? AppColors.success
              : check.overallScore >= 50
                  ? AppColors.warning
                  : AppColors.error;

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scoreColor,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: Spacings.md),

                  // Content
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(Spacings.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatDate(check.checkedAt),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.sm,
                                  vertical: Spacings.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(
                                    alpha: context.isDarkMode ? 0.20 : 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(Spacings.smRadius),
                                ),
                                child: Text(
                                  '${check.overallScore.toStringAsFixed(0)}%',
                                  style: tt.labelSmall?.copyWith(
                                    color: scoreColor,
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacings.xs),
                          Text(
                            check.computedStatus.label,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: AppTypography.wMedium,
                            ),
                          ),
                          if (check.flaggedIssues.isNotEmpty) ...[
                            const SizedBox(height: Spacings.xs),
                            Text(
                              '${check.flaggedIssues.length} issue(s) · '
                              '${check.suggestions.length} suggestion(s)',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScoreTrend(
    ColorScheme cs,
    TextTheme tt,
    List<QualityCheckEntity> history,
  ) {
    // Simple text-based trend display
    final scores = history.reversed.map((h) => h.overallScore).toList();
    final latestScore = scores.last;
    final previousScore = scores.length > 1 ? scores[scores.length - 2] : latestScore;
    final difference = latestScore - previousScore;
    final isImproving = difference > 0;
    final isDeclining = difference < 0;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        children: [
          Icon(
            isImproving
                ? Icons.trending_up
                : isDeclining
                    ? Icons.trending_down
                    : Icons.trending_flat,
            color: isImproving
                ? AppColors.success
                : isDeclining
                    ? AppColors.error
                    : cs.onSurfaceVariant,
            size: Spacings.lgIcon,
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Trend',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  isImproving
                      ? 'Improved by ${difference.abs().toStringAsFixed(1)} points from last check'
                      : isDeclining
                          ? 'Declined by ${difference.abs().toStringAsFixed(1)} points from last check'
                          : 'Score unchanged from last check',
                  style: tt.bodySmall?.copyWith(
                    color: isImproving
                        ? AppColors.success
                        : isDeclining
                            ? AppColors.error
                            : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${latestScore.toStringAsFixed(0)}%',
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: isImproving
                  ? AppColors.success
                  : isDeclining
                      ? AppColors.error
                      : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckState qualityState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Run Quality Check',
                onPressed: _runQualityCheck,
                variant: AppButtonVariant.elevated,
                icon: Icons.fact_check_outlined,
                isLoading: qualityState.isRunningCheck,
                fullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'View Product',
                onPressed: _navigateToViewProduct,
                variant: AppButtonVariant.outlined,
                icon: Icons.visibility_outlined,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppButton(
                label: 'Edit Product',
                onPressed: _navigateToEditProduct,
                variant: AppButtonVariant.outlined,
                icon: Icons.edit_outlined,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Date formatting helper ──────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Severity level for flagged issues.
enum _Severity {
  high(label: 'High', icon: Icons.error, color: AppColors.error),
  medium(label: 'Medium', icon: Icons.warning_amber, color: AppColors.warning),
  low(label: 'Low', icon: Icons.info_outline, color: AppColors.info);

  const _Severity({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
