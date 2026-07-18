import 'package:flutter/material.dart';

import '../../../../core/themes/spacings.dart';

/// A timeline widget showing today's schedule and upcoming events from the
/// dashboard data.
///
/// Renders a vertical timeline with a time column, coloured indicator bar,
/// and event details. Supports different event types with colour coding:
/// - `class` → primary colour
/// - `exam` → red
/// - `meeting` → orange
/// - `deadline` → purple
/// - default → tertiary colour
class ScheduleTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final String title;

  const ScheduleTimeline({
    super.key,
    required this.events,
    this.title = "Today's Schedule",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Text(
                  'No events scheduled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...events.map((event) => _EventTile(event: event)),
          ],
        ),
      ),
    );
  }
}

/// A single event tile within the schedule timeline.
class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventType = event['event_type'] as String? ?? 'class';
    final color = _getEventColor(eventType, theme);

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              _formatTime(event['start_time']),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] as String? ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event['location'] != null)
                    Text(
                      event['location'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a colour based on the event type.
  Color _getEventColor(String type, ThemeData theme) {
    switch (type) {
      case 'class':
        return theme.colorScheme.primary;
      case 'exam':
        return Colors.red;
      case 'meeting':
        return Colors.orange;
      case 'deadline':
        return Colors.purple;
      default:
        return theme.colorScheme.tertiary;
    }
  }

  /// Formats a dynamic time value into `HH:mm` format.
  String _formatTime(dynamic time) {
    if (time == null) return '';
    final dt = DateTime.tryParse(time.toString());
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
