import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/communication_entities.dart';

// ─── EventCard ────────────────────────────────────────────────────────────────

/// A card widget for displaying a calendar event with title, time range,
/// type badge, location, RSVP status, and attendee count.
///
/// ```dart
/// EventCard(
///   event: calendarEvent,
///   onTap: () => openEvent(calendarEvent.id),
/// )
/// ```
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final CalendarEventEntity event;
  final VoidCallback? onTap;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]}';
  }

  Color _typeColor(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.meeting => AppColors.seed,
      CalendarEventType.parentTeacher => const Color(0xFFEA580C),
      CalendarEventType.academic => const Color(0xFF7C3AED),
      CalendarEventType.exam => const Color(0xFFDC2626),
      CalendarEventType.holiday => const Color(0xFF16A34A),
      CalendarEventType.event => const Color(0xFF0891B2),
      CalendarEventType.deadline => const Color(0xFFCA8A04),
      CalendarEventType.custom => const Color(0xFF6B7280),
    };
  }

  IconData _typeIcon(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.meeting => Icons.groups_rounded,
      CalendarEventType.parentTeacher => Icons.family_restroom_rounded,
      CalendarEventType.academic => Icons.school_outlined,
      CalendarEventType.exam => Icons.quiz_outlined,
      CalendarEventType.holiday => Icons.beach_access_rounded,
      CalendarEventType.event => Icons.celebration_outlined,
      CalendarEventType.deadline => Icons.alarm_rounded,
      CalendarEventType.custom => Icons.event_outlined,
    };
  }

  Color _rsvpColor(MeetingStatus status) {
    return switch (status) {
      MeetingStatus.confirmed => AppColors.success,
      MeetingStatus.cancelled => AppColors.error,
      MeetingStatus.inProgress => AppColors.seed,
      MeetingStatus.rescheduled => AppColors.warning,
      _ => const Color(0xFF6B7280),
    };
  }

  // ─── Type Badge Builder ───────────────────────────────────────────────

  Widget _buildTypeBadge(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _typeColor(event.eventType);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_typeIcon(event.eventType), size: 12, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            event.eventType.label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: AppTypography.wSemiBold,
              letterSpacing: AppTypography.lsCaption,
              color: isDark ? color.withOpacity(0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── RSVP Status Badge ────────────────────────────────────────────────

  Widget _buildRsvpBadge(BuildContext context) {
    if (!event.rsvpRequired) return const SizedBox.shrink();
    final isDark = context.isDarkMode;
    final color = _rsvpColor(event.meetingStatus);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        event.meetingStatus.label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: AppTypography.wSemiBold,
          color: isDark ? color.withOpacity(0.9) : color,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _typeColor(event.eventType);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Type badge + RSVP ────────────────────────────
          Row(
            children: [
              _buildTypeBadge(context),
              const SizedBox(width: Spacings.sm),
              _buildRsvpBadge(context),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Title ─────────────────────────────────────────────────
          Text(
            event.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Spacings.md),

          // ── Time Range ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: Spacings.smIcon, color: typeColor),
              const SizedBox(width: Spacings.xs),
              Text(
                event.isAllDay
                    ? '${_formatDate(event.startTime)} · All day'
                    : '${_formatDate(event.startTime)}, '
                        '${_formatTime(event.startTime)} – '
                        '${_formatTime(event.endTime)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // ── Location ──────────────────────────────────────────────
          if (event.location != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Expanded(
                  child: Text(
                    event.location!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // ── Meeting Link ──────────────────────────────────────────
          if (event.meetingLink != null) ...[
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(Icons.videocam_outlined,
                    size: Spacings.smIcon, color: AppColors.seed),
                const SizedBox(width: Spacings.xs),
                Expanded(
                  child: Text(
                    'Online meeting',
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.seed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: Spacings.md),

          // ── Footer: Attendees ─────────────────────────────────────
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${event.currentAttendees ?? event.attendeeIds.length}'
                '${event.maxAttendees != null ? ' / ${event.maxAttendees}' : ''}'
                ' attendees',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (event.isRecurring) ...[
                const SizedBox(width: Spacings.md),
                Icon(Icons.repeat_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Recurring',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
