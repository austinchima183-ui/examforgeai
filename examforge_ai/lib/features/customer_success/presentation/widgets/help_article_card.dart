import 'package:flutter/material.dart';
import '../../domain/entities/customer_success_entities.dart';

/// Card widget for displaying a help article summary.
///
/// Shows article title, category, view count, and tags
/// in a compact, tappable card format.
class HelpArticleCard extends StatelessWidget {
  const HelpArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.onMarkHelpful,
  });

  final HelpArticle article;
  final VoidCallback onTap;
  final VoidCallback? onMarkHelpful;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.visibility_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${article.viewsCount}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.thumb_up_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${article.helpfulCount}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                article.title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                article.content,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: article.tags.take(4).map((tag) => Chip(
                    label: Text('#$tag', style: theme.textTheme.labelSmall),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
