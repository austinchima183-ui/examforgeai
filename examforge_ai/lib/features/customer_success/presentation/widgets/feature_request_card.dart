import 'package:flutter/material.dart';
import '../../domain/entities/customer_success_entities.dart';

/// Card widget for displaying a feature request with voting.
///
/// Shows request title, description, status, upvote count,
/// and a vote button. Supports visual feedback for voted state.
class FeatureRequestCard extends StatelessWidget {
  const FeatureRequestCard({
    super.key,
    required this.request,
    required this.hasVoted,
    required this.onVote,
  });

  final FeatureRequest request;
  final bool hasVoted;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVoteButton(context),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusBadge(theme),
                      const SizedBox(width: 8),
                      if (request.isUnderConsideration)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text('Under Review', style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue.shade700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(request.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    request.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(request.category, style: theme.textTheme.labelSmall),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(request.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (request.response != null) ...[
                        const Spacer(),
                        Icon(Icons.comment_outlined, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Has response', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                      ],
                    ],
                  ),
                  if (request.response != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Official Response', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(request.response!, style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onVote,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hasVoted ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasVoted ? theme.colorScheme.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasVoted ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_up_outlined,
              size: 20,
              color: hasVoted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            Text(
              '${request.upvotes}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasVoted ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color color;
    String label;
    switch (request.status) {
      case 'open':
        color = Colors.blue;
        label = 'Open';
        break;
      case 'under_consideration':
        color = Colors.orange;
        label = 'Under Review';
        break;
      case 'planned':
        color = Colors.purple;
        label = 'Planned';
        break;
      case 'in_progress':
        color = Colors.teal;
        label = 'In Progress';
        break;
      case 'implemented':
        color = Colors.green;
        label = 'Implemented';
        break;
      default:
        color = Colors.grey;
        label = request.status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
