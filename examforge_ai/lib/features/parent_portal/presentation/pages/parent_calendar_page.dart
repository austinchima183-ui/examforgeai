import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_calendar_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT CALENDAR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Calendar page showing school events and important dates.
///
/// Displays a month-view calendar with event dot indicators, a selected-date
/// event list below, upcoming events section, and a child filter dropdown.
/// Supports month/week view toggle and pull-to-refresh.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentCalendarPage extends ConsumerStatefulWidget {
  const ParentCalendarPage({super.key});

  @override
  ConsumerState<ParentCalendarPage> createState() => _State();
}

class _State extends ConsumerState<ParentCalendarPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// The focused month in the calendar.
  DateTime _focusedMonth = DateTime.now();

  /// The currently selected date.
  DateTime _selectedDate = DateTime.now();

  /// Whether the calendar is in month view (vs week view).
  bool _isMonthView = true;

  /// The selected child filter, or `null` for all children.
  String? _selectedChildId;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(parentCalendarProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Calendar',
        actions: [
          // Child selector dropdown
          _buildChildSelector(context),
        ],
      ),
      body: _buildBody(context, calendarState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(BuildContext context, ParentCalendarState state) {
    // Error state with no data
    if (state.error != null && state.events.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => _loadEvents(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadEvents(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── View Toggle + Month Navigation ────────────────────
            _buildCalendarHeader(context),

            // ─── Calendar Grid ─────────────────────────────────────
            _isMonthView
                ? _buildMonthCalendar(context, state)
                : _buildWeekCalendar(context, state),

            const SizedBox(height: Spacings.lg),

            // ─── Selected Date Events ──────────────────────────────
            _buildSelectedDateEvents(context, state),

            const SizedBox(height: Spacings.xl),

            // ─── Upcoming Events Section ───────────────────────────
            _buildUpcomingEvents(context, state),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChildSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: Spacings.sm),
      child: DropdownButton<String>(
        value: _selectedChildId,
        icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurface, size: Spacings.mdIcon),
        underline: const SizedBox.shrink(),
        style: tt.labelMedium?.copyWith(color: cs.onSurface),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Children'),
          ),
          // TODO: Populate with actual children from dashboard state
        ],
        onChanged: (value) {
          setState(() => _selectedChildId = value);
          _loadEvents();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CALENDAR HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildCalendarHeader(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      child: Row(
        children: [
          // Previous month
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
              _loadEvents();
            },
            iconSize: Spacings.lgIcon,
            color: cs.onSurface,
          ),
          // Month/Year label
          Expanded(
            child: Text(
              '${months[_focusedMonth.month]} ${_focusedMonth.year}',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Next month
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
              _loadEvents();
            },
            iconSize: Spacings.lgIcon,
            color: cs.onSurface,
          ),
          // View toggle
          const SizedBox(width: Spacings.sm),
          _buildViewToggle(context),
        ],
      ),
    );
  }

  // ─── View Toggle ────────────────────────────────────────────────────

  Widget _buildViewToggle(BuildContext context) {
    final cs = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            context,
            label: 'Month',
            isSelected: _isMonthView,
            onTap: () => setState(() => _isMonthView = true),
          ),
          _toggleButton(
            context,
            label: 'Week',
            isSelected: !_isMonthView,
            onTap: () => setState(() => _isMonthView = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: Spacings.borderRadiusSm,
        ),
        child: Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected
                ? AppTypography.wSemiBold
                : AppTypography.wRegular,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTH CALENDAR GRID
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMonthCalendar(
    BuildContext context,
    ParentCalendarState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7; // Sun=0
    final today = DateTime.now();

    // Build day cells
    final cells = <Widget>[];

    // Weekday headers
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (final day in weekdays) {
      cells.add(
        Center(
          child: Text(
            day,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      );
    }

    // Empty cells before the first day
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final hasEvents = _hasEventsOnDate(state.events, date);

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDate = date);
            ref.read(parentCalendarProvider.notifier).selectDate(date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : isToday
                      ? cs.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$day',
                    style: tt.bodySmall?.copyWith(
                      color: isSelected
                          ? cs.onPrimary
                          : isToday
                              ? cs.primary
                              : cs.onSurface,
                      fontWeight: isToday || isSelected
                          ? AppTypography.wBold
                          : AppTypography.wRegular,
                    ),
                  ),
                  if (hasEvents)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.onPrimary
                            : cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacings.xs,
            crossAxisSpacing: Spacings.xs,
            childAspectRatio: 1.0,
            children: cells,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEEK CALENDAR GRID
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWeekCalendar(
    BuildContext context,
    ParentCalendarState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final today = DateTime.now();

    // Get the start of the week containing the selected date
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday % 7),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final hasEvents = _hasEventsOnDate(state.events, date);
              const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                  ref.read(parentCalendarProvider.notifier).selectDate(date);
                },
                child: Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary
                        : isToday
                            ? cs.primaryContainer.withValues(alpha: 0.3)
                            : Colors.transparent,
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weekdays[index],
                        style: tt.labelSmall?.copyWith(
                          color: isSelected
                              ? cs.onPrimary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${date.day}',
                        style: tt.bodySmall?.copyWith(
                          color: isSelected
                              ? cs.onPrimary
                              : isToday
                                  ? cs.primary
                                  : cs.onSurface,
                          fontWeight: isToday || isSelected
                              ? AppTypography.wBold
                              : AppTypography.wRegular,
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          margin: const EdgeInsets.only(top: Spacings.xs),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.onPrimary
                                : cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SELECTED DATE EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSelectedDateEvents(
    BuildContext context,
    ParentCalendarState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selectedEvents = _eventsForDate(state.events, _selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            _formatSelectedDateHeader(_selectedDate),
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          // Events list
          if (selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
              child: Center(
                child: Text(
                  'No events on this day',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...selectedEvents.map((event) => _buildEventCard(context, event)),
        ],
      ),
    );
  }

  // ─── Event Card ─────────────────────────────────────────────────────

  Widget _buildEventCard(
    BuildContext context,
    ParentCalendarEventEntity event,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final typeColor = _eventTypeColor(event.eventType, cs.brightness);
    final typeIcon = _eventTypeIcon(event.eventType);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
          side: BorderSide(
            color: typeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            // TODO: Navigate to event detail
          },
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: Spacings.mdIcon,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacings.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: Spacings.smIcon,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: Spacings.xs),
                          Text(
                            event.isAllDay
                                ? 'All Day'
                                : '${_formatEventTime(event.startTime)} – ${_formatEventTime(event.endTime)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (event.location != null) ...[
                        const SizedBox(height: Spacings.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: Spacings.smIcon,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: Spacings.xs),
                            Text(
                              event.location!,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildUpcomingEvents(
    BuildContext context,
    ParentCalendarState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    final upcomingEvents = state.events.where((event) {
      return event.startTime.isAfter(now) &&
          event.startTime.isBefore(sevenDaysFromNow);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming (Next 7 Days)',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          if (upcomingEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.lg),
              child: Center(
                child: Text(
                  'No upcoming events',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...upcomingEvents.map(
              (event) => _buildEventCard(context, event),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Loads calendar events for the current focused month range.
  void _loadEvents() {
    final startDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    ref.read(parentCalendarProvider.notifier).loadEvents(
      startDate,
      endDate,
      _selectedChildId,
    );
  }

  /// Whether any events fall on the given [date].
  bool _hasEventsOnDate(
    List<ParentCalendarEventEntity> events,
    DateTime date,
  ) {
    return events.any((event) =>
        event.startTime.year == date.year &&
        event.startTime.month == date.month &&
        event.startTime.day == date.day);
  }

  /// Returns the events that fall on the given [date].
  List<ParentCalendarEventEntity> _eventsForDate(
    List<ParentCalendarEventEntity> events,
    DateTime date,
  ) {
    return events
        .where((event) =>
            event.startTime.year == date.year &&
            event.startTime.month == date.month &&
            event.startTime.day == date.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Returns the colour for a calendar event type.
  Color _eventTypeColor(CalendarEventType type, Brightness brightness) {
    switch (type) {
      case CalendarEventType.school:
        return AppColors.infoOf(brightness);
      case CalendarEventType.holiday:
        return AppColors.successOf(brightness);
      case CalendarEventType.meeting:
        return const Color(0xFF7C3AED); // Purple
      case CalendarEventType.exam:
        return AppColors.errorOf(brightness);
      case CalendarEventType.event:
        return const Color(0xFFF97316); // Orange
      case CalendarEventType.deadline:
        return AppColors.warningOf(brightness);
    }
  }

  /// Returns the icon for a calendar event type.
  IconData _eventTypeIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.school:
        return Icons.school_outlined;
      case CalendarEventType.holiday:
        return Icons.celebration_outlined;
      case CalendarEventType.meeting:
        return Icons.people_outlined;
      case CalendarEventType.exam:
        return Icons.quiz_outlined;
      case CalendarEventType.event:
        return Icons.event_outlined;
      case CalendarEventType.deadline:
        return Icons.schedule_outlined;
    }
  }

  /// Formats the selected date header.
  String _formatSelectedDateHeader(DateTime date) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  /// Formats a [DateTime] as a short time string.
  String _formatEventTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}
