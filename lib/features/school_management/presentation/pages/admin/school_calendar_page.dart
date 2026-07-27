import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/academic_session_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHOOL CALENDAR PAGE (Admin)
// ═══════════════════════════════════════════════════════════════════════

/// School calendar page with month navigation, event type filters,
/// and event CRUD operations. Shows events as colored chips on calendar
/// days and supports full event management.
class SchoolCalendarPage extends ConsumerStatefulWidget {
  const SchoolCalendarPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<SchoolCalendarPage> createState() =>
      _SchoolCalendarPageState();
}

class _SchoolCalendarPageState extends ConsumerState<SchoolCalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  final Set<CalendarEventType> _selectedEventTypes = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    final now = _focusedMonth;
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    ref.read(calendarProvider.notifier).loadEvents(
          schoolId: widget.schoolId,
          startDate: startDate,
          endDate: endDate,
        );
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadEvents();
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
    });
    _loadEvents();
  }

  List<CalendarEventEntity> _filterEvents(List<CalendarEventEntity> events) {
    if (_selectedEventTypes.isEmpty) return events;
    return events
        .where((e) => _selectedEventTypes.contains(e.eventType))
        .toList();
  }

  Map<int, List<CalendarEventEntity>> _eventsByDay(List<CalendarEventEntity> events) {
    final map = <int, List<CalendarEventEntity>>{};
    for (final event in events) {
      final day = event.startDate.day;
      map.putIfAbsent(day, () => []).add(event);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(calendarProvider);
    final filteredEvents = _filterEvents(state.events);
    final eventsByDay = _eventsByDay(filteredEvents);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Calendar',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.today_rounded, color: cs.onSurfaceVariant),
            onPressed: _goToToday,
            tooltip: 'Go to today',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Month Navigation ───────────────────────────────────────
          _buildMonthNavigation(context),

          // ── Event Type Filters ─────────────────────────────────────
          _buildEventTypeFilters(context),

          // ── Calendar Grid ─────────────────────────────────────────
          Expanded(
            child: state.isLoading && state.events.isEmpty
                ? const Center(
                    child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                  )
                : state.error != null && state.events.isEmpty
                    ? AppErrorState.genericError(
                        message: state.error,
                        onRetry: _loadEvents,
                      )
                    : _buildCalendarGrid(context, eventsByDay),
          ),

          // ── Events List for Selected Day ──────────────────────────
          if (filteredEvents.isNotEmpty)
            _buildEventsList(context, filteredEvents)
          else if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.all(Spacings.xl),
              child: AppEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No Events This Month',
                subtitle: 'Add events to populate the school calendar.',
                actionLabel: 'Add Event',
                onAction: () => _showEventDialog(context),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Event'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(Icons.chevron_left_rounded, color: cs.onSurfaceVariant),
            tooltip: 'Previous month',
          ),
          Text(
            '${months[_focusedMonth.month]} ${_focusedMonth.year}',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeFilters(BuildContext context) {
    final cs = context.colorScheme;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        children: CalendarEventType.values.map((type) {
          final isSelected = _selectedEventTypes.contains(type);
          final color = _eventTypeColor(type);

          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(type.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedEventTypes.add(type);
                  } else {
                    _selectedEventTypes.remove(type);
                  }
                });
              },
              selectedColor: color.withValues(alpha: 0.12),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: isSelected ? color : cs.onSurfaceVariant,
                fontWeight:
                    isSelected ? AppTypography.wSemiBold : AppTypography.wRegular,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    Map<int, List<CalendarEventEntity>> eventsByDay,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        children: [
          // ── Weekday Headers ──────────────────────────────────────
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ),)
                .toList(),
          ),
          const SizedBox(height: Spacings.sm),

          // ── Day Grid ─────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: startWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < startWeekday) {
                  return const SizedBox.shrink();
                }

                final day = index - startWeekday + 1;
                final isToday = today.year == _focusedMonth.year &&
                    today.month == _focusedMonth.month &&
                    today.day == day;
                final dayEvents = eventsByDay[day] ?? [];

                return GestureDetector(
                  onTap: dayEvents.isNotEmpty
                      ? () => _showDayEventsDialog(context, day, dayEvents)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? cs.primary.withValues(alpha: isDark ? 0.20 : 0.08)
                          : null,
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: tt.bodySmall?.copyWith(
                            color: isToday ? cs.primary : cs.onSurface,
                            fontWeight:
                                isToday ? AppTypography.wBold : AppTypography.wRegular,
                          ),
                        ),
                        if (dayEvents.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayEvents
                                .take(3)
                                .map((e) => Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1,),
                                      decoration: BoxDecoration(
                                        color: _eventTypeColor(e.eventType),
                                        shape: BoxShape.circle,
                                      ),
                                    ),)
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    List<CalendarEventEntity> events,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg,
              Spacings.md,
              Spacings.lg,
              Spacings.sm,
            ),
            child: Text(
              'Upcoming Events (${events.length})',
              style: tt.labelLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              itemCount: events.length > 5 ? 5 : events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventListItem(
                  event: event,
                  onTap: () => _showEventDetailDialog(context, event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDayEventsDialog(
    BuildContext context,
    int day,
    List<CalendarEventEntity> events,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${months[_focusedMonth.month]} $day, ${_focusedMonth.year}',
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: events
                .map((event) => _EventListItem(
                      event: event,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showEventDetailDialog(context, event);
                      },
                    ),)
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDetailDialog(BuildContext context, CalendarEventEntity event) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _eventTypeColor(event.eventType),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                event.title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                icon: Icons.category_outlined,
                label: 'Type',
                value: event.eventType.label,
              ),
              const SizedBox(height: Spacings.sm),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: _formatDate(event.startDate),
              ),
              if (event.endDate != null) ...[
                const SizedBox(height: Spacings.sm),
                _DetailRow(
                  icon: Icons.event_outlined,
                  label: 'End Date',
                  value: _formatDate(event.endDate!),
                ),
              ],
              if (event.description != null) ...[
                const SizedBox(height: Spacings.sm),
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: event.description!,
                ),
              ],
              const SizedBox(height: Spacings.sm),
              _DetailRow(
                icon: Icons.group_outlined,
                label: 'Audience',
                value: event.targetAudience,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteEvent(context, event);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEventDialog(context, event: event);
            },
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, CalendarEventEntity event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(calendarProvider.notifier).deleteEvent(event.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(BuildContext context, {CalendarEventEntity? event}) {
    final isEdit = event != null;
    final titleCtrl = TextEditingController(text: event?.title);
    final descCtrl = TextEditingController(text: event?.description);
    CalendarEventType selectedType = event?.eventType ?? CalendarEventType.event;
    DateTime? startDate = event?.startDate;
    DateTime? endDate = event?.endDate;
    String targetAudience = event?.targetAudience ?? 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Event' : 'Add Event'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Event Title',
                  controller: titleCtrl,
                  isRequired: true,
                  prefixIcon: Icons.title_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppDropdownField<CalendarEventType>(
                  label: 'Event Type',
                  items: CalendarEventType.values.toList(),
                  selectedItem: selectedType,
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedType = v);
                    }
                  },
                  itemLabel: (v) => v.label,
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'Start Date',
                  selectedDate: startDate,
                  onDateSelected: (date) {
                    setDialogState(() => startDate = date);
                  },
                  isRequired: true,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'End Date',
                  selectedDate: endDate,
                  onDateSelected: (date) {
                    setDialogState(() => endDate = date);
                  },
                ),
                const SizedBox(height: Spacings.md),
                AppDropdownField<String>(
                  label: 'Target Audience',
                  items: const ['all', 'students', 'teachers', 'parents', 'staff'],
                  selectedItem: targetAudience,
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => targetAudience = v);
                    }
                  },
                  itemLabel: (v) => v[0].toUpperCase() + v.substring(1),
                  prefixIcon: Icons.group_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppTextField(
                  label: 'Description',
                  controller: descCtrl,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || startDate == null) return;
                Navigator.pop(ctx);

                final newEvent = CalendarEventEntity(
                  id: event?.id ?? '',
                  schoolId: widget.schoolId,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  eventType: selectedType,
                  startDate: startDate!,
                  endDate: endDate,
                  targetAudience: targetAudience,
                );

                if (isEdit) {
                  ref.read(calendarProvider.notifier).updateEvent(newEvent);
                } else {
                  ref.read(calendarProvider.notifier).createEvent(newEvent);
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventTypeColor(CalendarEventType type) {
    try {
      return Color(int.parse(type.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EVENT LIST ITEM
// ═══════════════════════════════════════════════════════════════════════

class _EventListItem extends StatelessWidget {
  const _EventListItem({required this.event, this.onTap});

  final CalendarEventEntity event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final eventColor = _parseColor(event.eventType.color);

    return ListTile(
      dense: true,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: eventColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        event.title,
        style: tt.bodyMedium?.copyWith(
          fontWeight: AppTypography.wMedium,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${event.eventType.label} · ${_formatDate(event.startDate)}',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(Spacings.fullRadius),
        ),
        child: Text(
          event.eventType.label,
          style: tt.labelSmall?.copyWith(
            color: eventColor,
            fontWeight: AppTypography.wSemiBold,
            fontSize: 10,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DETAIL ROW
// ═══════════════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}
