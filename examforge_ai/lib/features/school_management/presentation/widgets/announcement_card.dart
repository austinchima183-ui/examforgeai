import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
  });

  final AnnouncementEntity announcement;
  final VoidCallback onTap;

  IconData _typeIcon(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.notice:
        return Icons.info_outline;
      case AnnouncementType.event:
        return Icons.event;
      case AnnouncementType.circular:
        return Icons.description_outlined;
      case AnnouncementType.holiday:
        return Icons.beach_access;
      case AnnouncementType.emergency:
        return Icons.warning_amber;
    }
  }

  Color _priorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Colors.grey;
      case AnnouncementPriority.normal:
        return Colors.blue;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: theme.colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 12, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text('Pinned', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_typeIcon(announcement.announcementType), size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(announcement.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Chip(
                        label: Text(announcement.priority.label, style: TextStyle(fontSize: 10, color: _priorityColor(announcement.priority))),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(announcement.content, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_formatDate(announcement.publishedAt ?? announcement.createdAt), style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
