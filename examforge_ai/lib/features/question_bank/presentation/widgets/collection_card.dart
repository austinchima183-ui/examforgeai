import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/question_entities.dart';

// ─── CollectionCard ───────────────────────────────────────────────────────────

/// A card widget for displaying a question collection. Shows the collection
/// name, description, question count badge, cover image (or placeholder
/// with gradient), shared/official badges, created-by info + date, and
/// callback handlers for tap, edit, and delete.
///
/// ```dart
/// CollectionCard(
///   collection: myCollection,
///   onTap: () => openCollection(collection.id),
///   onEdit: () => editCollection(collection.id),
///   onDelete: () => deleteCollection(collection.id),
/// )
/// ```
class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  /// The collection entity to display.
  final QuestionCollectionEntity collection;

  /// Tap callback for the entire card.
  final VoidCallback? onTap;

  /// Edit callback.
  final VoidCallback? onEdit;

  /// Delete callback.
  final VoidCallback? onDelete;

  // ─── Relative Time Helper ──────────────────────────────────────────

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover Image / Gradient Placeholder ──────────────────
          Stack(
            children: [
              // Cover image or gradient placeholder
              SizedBox(
                height: 120.0,
                width: double.infinity,
                child: collection.coverImageUrl != null &&
                        collection.coverImageUrl!.isNotEmpty
                    ? _CoverImage(url: collection.coverImageUrl!)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(Spacings.mdRadius),
                            topRight: Radius.circular(Spacings.mdRadius),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.collections_bookmark_rounded,
                            size: 40.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
              ),

              // Question count badge overlay
              Positioned(
                top: Spacings.sm,
                right: Spacings.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 14.0,
                        color: Colors.white,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '${collection.questionCount}',
                        style: tt.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.wBold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Shared / Official badges overlay
              Positioned(
                top: Spacings.sm,
                left: Spacings.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (collection.isOfficial)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 12.0,
                              color: Colors.white,
                            ),
                            const SizedBox(width: Spacings.xs),
                            Text(
                              'Official',
                              style: tt.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.wBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (collection.isShared) ...[
                      if (collection.isOfficial)
                        const SizedBox(width: Spacings.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.share_rounded,
                              size: 12.0,
                              color: Colors.white,
                            ),
                            const SizedBox(width: Spacings.xs),
                            Text(
                              'Shared',
                              style: tt.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.wBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Content Area ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collection name
                Text(
                  collection.name,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (collection.description != null &&
                    collection.description!.isNotEmpty) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    collection.description!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: Spacings.md),

                // Footer: Created by + Date + Actions
                Row(
                  children: [
                    // Created by
                    Icon(
                      Icons.person_outline_rounded,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: Spacings.xs),
                    Flexible(
                      child: Text(
                        collection.createdBy ?? 'Unknown',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),

                    // Relative date
                    Icon(
                      Icons.access_time_rounded,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      _relativeTime(collection.createdAt),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),

                    const Spacer(),

                    // Action buttons
                    if (onEdit != null)
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: Spacings.smIcon,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: onEdit,
                        tooltip: 'Edit collection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: Spacings.smIcon,
                          color: AppColors.errorOf(cs.brightness),
                        ),
                        onPressed: onDelete,
                        tooltip: 'Delete collection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
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

// ─── Cover Image ──────────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    // Since we can't load actual URLs in this context, show a placeholder
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.coolGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Spacings.mdRadius),
          topRight: Radius.circular(Spacings.mdRadius),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_rounded,
              size: 32.0,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              'Cover Image',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
