import 'package:flutter/material.dart';
import '../../domain/entities/marketing_entities.dart';

/// Card widget for displaying a blog post summary.
class BlogPostCard extends StatelessWidget {
  const BlogPostCard({super.key, required this.blogPost, required this.onTap});
  final BlogPost blogPost;
  final VoidCallback onTap;

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
                  if (blogPost.isFeatured)
                    Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.star, size: 18, color: Colors.amber.shade700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Text(blogPost.category, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                  ),
                  const Spacer(),
                  Icon(Icons.visibility_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${blogPost.viewsCount}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Icon(Icons.favorite_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${blogPost.likesCount}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(blogPost.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(blogPost.excerpt, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (blogPost.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 4, runSpacing: 2, children: blogPost.tags.take(3).map((tag) => Chip(
                  label: Text('#$tag', style: theme.textTheme.labelSmall),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),).toList(),),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
