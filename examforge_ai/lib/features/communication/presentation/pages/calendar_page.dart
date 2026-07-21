import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/calendar_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Monthly calendar view with event indicators.
///
/// Features:
/// - Switch between Month/Week/Day views
/// - Event list for selected day
/// - Each event: title, time, type badge, location, RSVP status
/// - FAB to create event
/// - Filter by type
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _State();
}

class _State extends ConsumerState<CalendarPage> {
  // ─── State ──────────────────────────────────────────────────────────

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  CalendarEventType? _typeFilter;
  String _viewMode = 'month'; // month, week, day

  static const _viewModes = ['month', 'week', 'day'];
  static const _viewLabels = ['Month', 'Week', 'Day'];

  static const _typeFilters = <_TypeFilter>[
    _TypeFilter(label: 'All', type: null),
    _TypeFilter(label: 'Meetings', type: CalendarEventType.meeting),
    _TypeFilter(label: 'Academic', type: CalendarEventType.academic),
    _TypeFilter(label: 'Exams', type: CalendarEventType.exam),
    _TypeFilter(label: 'Events', type: CalendarEventType.event),
    _TypeFilter(label: 'Holidays', type: CalendarEventType.holiday),
    _TypeFilter(label: 'Deadlines', type: CalendarEventType.deadline),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  void _loadEvents() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 2, 0);
    ref.read(calendarProvider.notifier).loadEvents(
      GetCalendarEventsParams(
        startDate: start.toIso8601String(),
        endDate: end.toIso8601String(),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Calendar',
        actions: [
          // View mode toggle
          SegmentedButton<String>(
            segments: _viewModes.asMap().entries.map((e) => ButtonSegment(value: e.value, label: Text(_viewLabels[e.key]))).toList(),
            selected: {_viewMode},
            onSelectionChanged: (s) => setState(() => _viewMode = s.first),
            style: ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall)),
          ),
          const SizedBox(width: Spacings.sm),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: navigate to create event */},
        tooltip: 'New Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(CalendarState state) {
    if (state.isLoading && state.events.isEmpty) {
      return const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.events.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: _loadEvents,
      );
    }

    return Column(
      children: [
        // ─── Type Filter Chips ───────────────────────────────────
        _buildTypeFilters(),

        // ─── Calendar / View ────────────────────────────────────
        if (_viewMode == 'month') _buildMonthView(state),
        if (_viewMode == 'week') _buildWeekView(state),
        if (_viewMode == 'day') _buildDayHeader(),

        // ─── Events List ────────────────────────────────────────
        Expanded(child: _buildEventsList(state)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPE FILTERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.xs),
        children: _typeFilters.map((f) {
          final isSelected = _typeFilter == f.type;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _typeFilter = isSelected ? null : f.type),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTH VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMonthView(CalendarState state) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: TableCalendar(
        focusedDay: _focusedMonth,
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2026, 12, 31),
        selectedDayPredicate: (d) => _isSameDay(d, _selectedDate),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDate = selected;
            _focusedMonth = focused;
          });
        },
        eventLoader: (day) => _eventsForDay(day, state.events),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: cs.primary.withOpacity(0.3), shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: cs.tertiary, shape: BoxShape.circle),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: AppTypography.wSemiBold),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEEK VIEW (Simplified)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWeekView(CalendarState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      child: Row(
        children: List.generate(7, (i) {
          final day = startOfWeek.add(Duration(days: i));
          final isSelected = _isSameDay(day, _selectedDate);
          final isToday = _isSameDay(day, DateTime.now());
          final hasEvents = _eventsForDay(day, state.events).isNotEmpty;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = day),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: Spacings.xs),
                padding: const EdgeInsets.symmetric(vertical: Spacings.md),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : (isToday ? cs.primaryContainer.withOpacity(0.3) : Colors.transparent),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Column(
                  children: [
                    Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i], style: tt.labelSmall?.copyWith(color: isSelected ? cs.onPrimary : cs.onSurfaceVariant)),
                    const SizedBox(height: Spacings.xs),
                    Text('${day.day}', style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: isSelected ? cs.onPrimary : cs.onSurface)),
                    if (hasEvents)
                      Container(
                        margin: const EdgeInsets.only(top: Spacings.xs),
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: isSelected ? cs.onPrimary : cs.tertiary, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DAY HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDayHeader() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
          Expanded(
            child: Center(
              child: Text(
                '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EVENTS LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEventsList(CalendarState state) {
    final events = _eventsForDay(_selectedDate, state.events);
    final filtered = _typeFilter != null ? events.where((e) => e.eventType == _typeFilter).toList() : events;

    if (filtered.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Events',
        subtitle: 'No events scheduled for this day.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadEvents(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (_, i) => _buildEventCard(filtered[i] as CalendarEventEntity),
      ),
    );
  }

  Widget _buildEventCard(CalendarEventEntity event) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final typeColor = _eventTypeColor(event.eventType, cs.brightness);

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(color: typeColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {/* TODO: navigate to event detail */},
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              // Time column
              Container(
                width: 56,
                child: Column(
                  children: [
                    Text(
                      '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}',
                      style: tt.labelLarge?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
                    ),
                    Text(
                      event.isAllDay ? 'All Day' : '${event.endTime.hour.toString().padLeft(2, '0')}:${event.endTime.minute.toString().padLeft(2, '0')}',
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacings.md),
              // Color bar
              Container(width: 3, height: 40, decoration: BoxDecoration(color: typeColor, borderRadius: Spacings.borderRadiusFull)),
              const SizedBox(width: Spacings.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Spacings.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                          decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: Spacings.borderRadiusSm),
                          child: Text(event.eventType.label, style: tt.labelSmall?.copyWith(color: typeColor)),
                        ),
                        if (event.location != null) ...[
                          const SizedBox(width: Spacings.sm),
                          Icon(Icons.location_on_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                          const SizedBox(width: Spacings.xs),
                          Flexible(child: Text(event.location!, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ],
                    ),
                    if (event.rsvpRequired) ...[
                      const SizedBox(height: Spacings.xs),
                      Row(
                        children: [
                          Icon(Icons.event_available_outlined, size: Spacings.smIcon, color: cs.primary),
                          const SizedBox(width: Spacings.xs),
                          Text('RSVP Required', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wMedium)),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<dynamic> _eventsForDay(DateTime day, List<CalendarEventEntity> events) {
    return events.where((e) => _isSameDay(e.startTime, day) || (e.isAllDay && _isSameDay(e.startTime, day))).toList();
  }

  Color _eventTypeColor(CalendarEventType type, Brightness brightness) {
    switch (type) {
      case CalendarEventType.meeting:
        return AppColors.infoOf(brightness);
      case CalendarEventType.parentTeacher:
        return const Color(0xFF7C3AED);
      case CalendarEventType.academic:
        return AppColors.seed;
      case CalendarEventType.exam:
        return AppColors.errorOf(brightness);
      case CalendarEventType.holiday:
        return AppColors.successOf(brightness);
      case CalendarEventType.event:
        return const Color(0xFF06B6D4);
      case CalendarEventType.deadline:
        return AppColors.warningOf(brightness);
      case CalendarEventType.custom:
        return const Color(0xFF9CA3AF);
    }
  }

  String _monthName(int month) {
    const names = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return names[month];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _TypeFilter {
  const _TypeFilter({required this.label, this.type});
  final String label;
  final CalendarEventType? type;
}

/// Minimal table calendar widget for the calendar page.
/// Uses Material 3 date picker internally.
class TableCalendar extends StatelessWidget {
  const TableCalendar({
    super.key,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    this.selectedDayPredicate,
    this.onDaySelected,
    this.eventLoader,
    this.calendarStyle,
    this.headerStyle,
  });

  final DateTime focusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final bool Function(DateTime)? selectedDayPredicate;
  final void Function(DateTime, DateTime)? onDaySelected;
  final List<dynamic> Function(DateTime)? eventLoader;
  final CalendarStyle? calendarStyle;
  final HeaderStyle? headerStyle;

  @override
  Widget build(BuildContext context) {
    // Simplified calendar using CalendarDatePicker
    return CalendarDatePicker(
      initialDate: focusedDay,
      firstDate: firstDay,
      lastDate: lastDay,
      onDateChanged: (date) {
        onDaySelected?.call(date, date);
      },
    );
  }
}

class CalendarStyle {
  final Decoration? selectedDecoration;
  final Decoration? todayDecoration;
  final Decoration? markerDecoration;
  const CalendarStyle({this.selectedDecoration, this.todayDecoration, this.markerDecoration});
}

class HeaderStyle {
  final bool formatButtonVisible;
  final bool titleCentered;
  final TextStyle? titleTextStyle;
  const HeaderStyle({this.formatButtonVisible = true, this.titleCentered = false, this.titleTextStyle});
}
