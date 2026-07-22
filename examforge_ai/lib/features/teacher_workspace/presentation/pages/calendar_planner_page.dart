import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_planner_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR VIEW MODE
// ═══════════════════════════════════════════════════════════════════════

/// The calendar display mode.
enum CalendarViewMode {
  monthly,
  weekly,
  daily;

  String get label => switch (this) {
        monthly => 'Monthly',
        weekly => 'Weekly',
        daily => 'Daily',
      };

  IconData get icon => switch (this) {
        monthly => Icons.calendar_month_rounded,
        weekly => Icons.view_week_rounded,
        daily => Icons.view_day_rounded,
      };
}

// ═══════════════════════════════════════════════════════════════════════
// REMINDER OPTION
// ═══════════════════════════════════════════════════════════════════════

/// Reminder preset options for the event form.
enum ReminderOption {
  none(label: 'None', minutes: null),
  five(label: '5 min before', minutes: 5),
  fifteen(label: '15 min before', minutes: 15),
  thirty(label: '30 min before', minutes: 30),
  oneHour(label: '1 hour before', minutes: 60);

  const ReminderOption({required this.label, required this.minutes});

  final String label;
  final int? minutes;
}

// ═══════════════════════════════════════════════════════════════════════
// PRESET EVENT COLORS
// ═══════════════════════════════════════════════════════════════════════

const _kPresetColors = <Color>[
  Color(0xFF4F46E5), // Indigo 600
  Color(0xFF7C3AED), // Violet 600
  Color(0xFF06B6D4), // Cyan 500
  Color(0xFF16A34A), // Green 600
  Color(0xFFF59E0B), // Amber 500
  Color(0xFFDC2626), // Red 600
];

// ═══════════════════════════════════════════════════════════════════════
// CALENDAR PLANNER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// A comprehensive calendar and planner page for teachers with daily, weekly,
/// and monthly views, event CRUD, and AI schedule suggestions.
class CalendarPlannerPage extends ConsumerStatefulWidget {
  const CalendarPlannerPage({super.key});

  @override
  ConsumerState<CalendarPlannerPage> createState() =>
      _CalendarPlannerPageState();
}

class _CalendarPlannerPageState extends ConsumerState<CalendarPlannerPage>
    with SingleTickerProviderStateMixin {
  // ─── State ─────────────────────────────────────────────────────────

  CalendarViewMode _viewMode = CalendarViewMode.monthly;
  DateTime _focusedDate = DateTime.now();
  late DateTime _selectedDate;

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  // Form state
  EventType _eventType = EventType.class_;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: 0,
  );
  bool _isAllDay = false;
  Color _selectedColor = _kPresetColors.first;
  ReminderOption _reminder = ReminderOption.none;

  // Editing state
  CalendarEventEntity? _editingEvent;

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarPlannerProvider.notifier).loadEvents();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _locationCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatMonthYear(DateTime d) {
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
    return '${months[d.month]} ${d.year}';
  }

  String _formatWeekRange(DateTime focused) {
    // Week starts on Monday
    final weekday = focused.weekday;
    final monday = focused.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[monday.month]} ${monday.day} – ${months[sunday.month]} ${sunday.day}, ${sunday.year}';
  }

  String _colorToHex(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return _kPresetColors.first;
    final code = hex.replaceFirst('#', '');
    if (code.length != 6) return _kPresetColors.first;
    return Color(int.parse('FF$code', radix: 16));
  }

  IconData _iconForEventType(EventType type) => switch (type) {
        EventType.class_ => Icons.school_rounded,
        EventType.meeting => Icons.groups_rounded,
        EventType.deadline => Icons.flag_rounded,
        EventType.reminder => Icons.notifications_active_rounded,
        EventType.exam => Icons.quiz_rounded,
        EventType.holiday => Icons.celebration_rounded,
        EventType.personal => Icons.person_rounded,
        EventType.other => Icons.event_rounded,
      };

  Color _colorForEventType(EventType type) => switch (type) {
        EventType.class_ => const Color(0xFF4F46E5),
        EventType.meeting => const Color(0xFF7C3AED),
        EventType.deadline => const Color(0xFFDC2626),
        EventType.reminder => const Color(0xFFF59E0B),
        EventType.exam => const Color(0xFF06B6D4),
        EventType.holiday => const Color(0xFF16A34A),
        EventType.personal => const Color(0xFFEC4899),
        EventType.other => const Color(0xFF6B7280),
      };

  void _listenForMessages() {
    final state = ref.read(calendarPlannerProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(calendarPlannerProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(calendarPlannerProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Navigation ─────────────────────────────────────────────────────

  void _goToPrevious() {
    setState(() {
      switch (_viewMode) {
        case CalendarViewMode.monthly:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
        case CalendarViewMode.weekly:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
        case CalendarViewMode.daily:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
      }
      _selectedDate = _normalizeDate(_focusedDate);
    });
    ref.read(calendarPlannerProvider.notifier).selectDate(_selectedDate);
  }

  void _goToNext() {
    setState(() {
      switch (_viewMode) {
        case CalendarViewMode.monthly:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
        case CalendarViewMode.weekly:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
        case CalendarViewMode.daily:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
      }
      _selectedDate = _normalizeDate(_focusedDate);
    });
    ref.read(calendarPlannerProvider.notifier).selectDate(_selectedDate);
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
      _selectedDate = _normalizeDate(DateTime.now());
    });
    ref.read(calendarPlannerProvider.notifier).selectDate(_selectedDate);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _normalizeDate(date);
      _focusedDate = _selectedDate;
    });
    ref.read(calendarPlannerProvider.notifier).selectDate(_selectedDate);
  }

  // ─── Event CRUD ─────────────────────────────────────────────────────

  void _openAddEventSheet() {
    _resetForm();
    _editingEvent = null;
    _showEventBottomSheet();
  }

  void _openEditEventSheet(CalendarEventEntity event) {
    _titleCtrl.text = event.title;
    _subjectCtrl.text = event.subject ?? '';
    _locationCtrl.text = event.location ?? '';
    _eventType = event.eventType;
    _startTime = TimeOfDay.fromDateTime(event.startTime);
    _endTime = TimeOfDay.fromDateTime(event.endTime);
    _isAllDay = event.isAllDay;
    _selectedColor = _hexToColor(event.color);
    _reminder = ReminderOption.values.firstWhere(
      (r) => r.minutes == event.reminderMinutesBefore,
      orElse: () => ReminderOption.none,
    );
    _editingEvent = event;
    _showEventBottomSheet();
  }

  void _resetForm() {
    _titleCtrl.clear();
    _subjectCtrl.clear();
    _locationCtrl.clear();
    _eventType = EventType.class_;
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(
      hour: (TimeOfDay.now().hour + 1) % 24,
      minute: 0,
    );
    _isAllDay = false;
    _selectedColor = _kPresetColors.first;
    _reminder = ReminderOption.none;
  }

  void _handleSaveEvent() {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackBar('Event title is required', isError: true);
      return;
    }

    final now = DateTime.now();
    final eventDate = _selectedDate;
    final startDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    var endDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (!endDateTime.isAfter(startDateTime)) {
      endDateTime = startDateTime.add(const Duration(hours: 1));
    }

    final event = CalendarEventEntity(
      id: _editingEvent?.id ?? '',
      teacherId: _editingEvent?.teacherId ?? '',
      title: _titleCtrl.text.trim(),
      description: _editingEvent?.description,
      eventType: _eventType,
      subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
      subjectId: _editingEvent?.subjectId,
      classId: _editingEvent?.classId,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      isRecurring: _editingEvent?.isRecurring ?? false,
      recurrenceRule: _editingEvent?.recurrenceRule,
      color: _colorToHex(_selectedColor),
      reminderMinutesBefore: _reminder.minutes,
      relatedResourceType: _editingEvent?.relatedResourceType,
      relatedResourceId: _editingEvent?.relatedResourceId,
      metadata: _editingEvent?.metadata ?? {},
      createdAt: _editingEvent?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.pop(context); // Close bottom sheet first

    if (_editingEvent != null) {
      ref.read(calendarPlannerProvider.notifier).updateEvent(event);
    } else {
      ref.read(calendarPlannerProvider.notifier).createEvent(
            CreateEventParams(event: event),
          );
    }
    _listenForMessages();
  }

  void _handleDeleteEvent(String eventId) {
    AppDialog.showConfirm(
      context: context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete this event? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(calendarPlannerProvider.notifier).deleteEvent(eventId);
        _listenForMessages();
      }
    });
  }

  // ─── AI Schedule Suggestions ────────────────────────────────────────

  void _openAiSuggestions() {
    ref.read(calendarPlannerProvider.notifier).suggestSchedule({
      'selectedDate': _selectedDate.toIso8601String(),
      'viewMode': _viewMode.name,
    });
    _listenForMessages();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarPlannerProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Calendar & Planner',
        actions: [
          AppIconButton(
            icon: Icons.auto_awesome_rounded,
            onPressed: state.isSuggesting ? null : _openAiSuggestions,
            tooltip: 'AI Schedule Suggestions',
            variant: AppIconButtonVariant.tonal,
          ),
          AppIconButton(
            icon: Icons.today_rounded,
            onPressed: _goToToday,
            tooltip: 'Go to Today',
            variant: AppIconButtonVariant.standard,
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : state.error != null && state.events.isEmpty
              ? _buildErrorState(state)
              : _buildContent(state),
      floatingActionButton: AppFloatingActionButton(
        label: 'Add Event',
        icon: Icons.add_rounded,
        onPressed: _openAddEventSheet,
        extended: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildContent(CalendarPlannerState state) {
    return Column(
      children: [
        // View mode toggle
        _buildViewToggle(),

        // Navigation bar
        _buildNavigationBar(),

        // Calendar view
        Expanded(
          flex: 3,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCalendarView(state),
          ),
        ),

        // Divider
        Divider(
          height: 1,
          thickness: 1,
          color: context.colorScheme.outlineVariant.withOpacity(0.3),
        ),

        // Events for selected date
        Expanded(
          flex: 2,
          child: _buildSelectedDateEvents(state),
        ),
      ],
    );
  }

  // ─── View Toggle ────────────────────────────────────────────────────

  Widget _buildViewToggle() {
    final cs = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        Spacings.md,
        Spacings.lg,
        Spacings.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        padding: const EdgeInsets.all(Spacings.xs),
        child: Row(
          children: CalendarViewMode.values.map((mode) {
            final isSelected = _viewMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _viewMode = mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: Spacings.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode.icon,
                        size: Spacings.smIcon + 2,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        mode.label,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? cs.onPrimary
                              : cs.onSurfaceVariant,
                          fontWeight: isSelected
                              ? AppTypography.wSemiBold
                              : AppTypography.wMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Navigation Bar ─────────────────────────────────────────────────

  Widget _buildNavigationBar() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final title = switch (_viewMode) {
      CalendarViewMode.monthly => _formatMonthYear(_focusedDate),
      CalendarViewMode.weekly => _formatWeekRange(_focusedDate),
      CalendarViewMode.daily => _formatDateTime(_selectedDate).split(' ').take(3).join(' '),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _goToPrevious,
            variant: AppIconButtonVariant.standard,
            size: AppButtonSize.small,
            tooltip: 'Previous',
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.chevron_right_rounded,
            onPressed: _goToNext,
            variant: AppIconButtonVariant.standard,
            size: AppButtonSize.small,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  // ─── Calendar View Switch ───────────────────────────────────────────

  Widget _buildCalendarView(CalendarPlannerState state) {
    return switch (_viewMode) {
      CalendarViewMode.monthly => _buildMonthlyView(state),
      CalendarViewMode.weekly => _buildWeeklyView(state),
      CalendarViewMode.daily => _buildDailyView(state),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTHLY VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMonthlyView(CalendarPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sun = 0

    // Build a set of dates that have events
    final eventDates = <DateTime>{};
    for (final e in state.events) {
      eventDates.add(_normalizeDate(e.startTime));
    }

    // Build grid cells
    final cells = <Widget>[];

    // Day-of-week headers
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    for (final label in dayLabels) {
      cells.add(
        Center(
          child: Text(
            label,
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
    final today = _normalizeDate(DateTime.now());
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDate.year, _focusedDate.month, day);
      final isToday = date == today;
      final isSelected = date == _selectedDate;
      final hasEvents = eventDates.contains(date);
      final dayEvents = state.events
          .where((e) => _normalizeDate(e.startTime) == date)
          .toList();
      final dotColors = dayEvents
          .take(3)
          .map((e) => _hexToColor(e.color))
          .toList();

      cells.add(
        GestureDetector(
          onTap: () => _selectDate(date),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : isToday
                      ? cs.primary.withOpacity(0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              border: isToday && !isSelected
                  ? Border.all(color: cs.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        dotColors.length.clamp(0, 3),
                        (i) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.onPrimary
                                : dotColors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Pad remaining cells to fill the grid
    final totalCells = 7 + startWeekday + daysInMonth;
    final remainder = totalCells % 7;
    if (remainder > 0) {
      for (var i = 0; i < 7 - remainder; i++) {
        cells.add(const SizedBox.shrink());
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEEKLY VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWeeklyView(CalendarPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Calculate the week's Monday
    final weekday = _focusedDate.weekday;
    final monday = _focusedDate.subtract(Duration(days: weekday - 1));
    final today = _normalizeDate(DateTime.now());

    final weekDays = List.generate(
      7,
      (i) => _normalizeDate(monday.add(Duration(days: i))),
    );

    // Hourly slots 7am - 9pm
    const startHour = 7;
    const endHour = 21;

    return Column(
      children: [
        // Day headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
          child: Row(
            children: [
              // Time gutter header
              const SizedBox(width: 48),
              ...weekDays.map((date) {
                final isToday = date == today;
                final isSelected = date == _selectedDate;
                final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][
                    date.weekday - 1];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(date),
                    child: Column(
                      children: [
                        Text(
                          dayName,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary
                                : isToday
                                    ? cs.primary.withOpacity(0.12)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: tt.bodySmall?.copyWith(
                                color: isSelected
                                    ? cs.onPrimary
                                    : isToday
                                        ? cs.primary
                                        : cs.onSurface,
                                fontWeight:
                                    isToday || isSelected
                                        ? AppTypography.wBold
                                        : AppTypography.wRegular,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: Spacings.sm),

        // Time grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time gutter
                SizedBox(
                  width: 48,
                  child: Column(
                    children: List.generate(
                      endHour - startHour,
                      (i) {
                        final hour = startHour + i;
                        return SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Day columns
                ...weekDays.map((date) {
                  final dayEvents = state.events
                      .where((e) => _normalizeDate(e.startTime) == date)
                      .toList();

                  return Expanded(
                    child: Column(
                      children: List.generate(
                        endHour - startHour,
                        (i) {
                          final hour = startHour + i;
                          final slotEvents = dayEvents
                              .where((e) => e.startTime.hour == hour)
                              .toList();

                          return GestureDetector(
                            onTap: () {
                              _selectDate(date);
                              setState(() {
                                _startTime = TimeOfDay(hour: hour, minute: 0);
                                _endTime = TimeOfDay(
                                  hour: hour + 1,
                                  minute: 0,
                                );
                              });
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: cs.outlineVariant
                                        .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                  right: BorderSide(
                                    color: cs.outlineVariant
                                        .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: slotEvents.map((event) {
                                  final eventColor = _hexToColor(event.color);
                                  return Positioned(
                                    top: 1,
                                    left: 1,
                                    right: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: eventColor.withOpacity(context.isDarkMode ? 0.30 : 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Spacings.xs,
                                        ),
                                        border: Border.all(
                                          color: eventColor.withOpacity(0.5,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        event.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.labelSmall?.copyWith(
                                          color: eventColor,
                                          fontWeight: AppTypography.wSemiBold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DAILY VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDailyView(CalendarPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    const startHour = 6;
    const endHour = 22;

    final dayEvents = state.events
        .where((e) => _normalizeDate(e.startTime) == _selectedDate)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // All-day events
    final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
    final timedEvents = dayEvents.where((e) => !e.isAllDay).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All-day section
          if (allDayEvents.isNotEmpty) ...[
            Text(
              'All Day',
              style: tt.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            ...allDayEvents.map((e) => _buildDailyEventBlock(e)),
            const SizedBox(height: Spacings.md),
          ],

          // Hourly timeline
          ...List.generate(endHour - startHour, (i) {
            final hour = startHour + i;
            final hourEvents = timedEvents
                .where((e) => e.startTime.hour == hour)
                .toList();

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time label
                  SizedBox(
                    width: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: hourEvents.isNotEmpty
                              ? cs.primary
                              : cs.outlineVariant.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: cs.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: Spacings.sm),

                  // Events for this hour
                  Expanded(
                    child: hourEvents.isEmpty
                        ? SizedBox(
                            height: 48,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _startTime = TimeOfDay(
                                    hour: hour,
                                    minute: 0,
                                  );
                                  _endTime = TimeOfDay(
                                    hour: hour + 1,
                                    minute: 0,
                                  );
                                });
                                _openAddEventSheet();
                              },
                            ),
                          )
                        : Column(
                            children: hourEvents
                                .map((e) => _buildDailyEventBlock(e))
                                .toList(),
                          ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: Spacings.xl),
        ],
      ),
    );
  }

  Widget _buildDailyEventBlock(CalendarEventEntity event) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final eventColor = _hexToColor(event.color);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => _openEditEventSheet(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacings.sm),
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: eventColor.withOpacity(isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          border: Border.all(
            color: eventColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: eventColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  if (!event.isAllDay)
                    Text(
                      '${_formatTime(TimeOfDay.fromDateTime(event.startTime))} – '
                      '${_formatTime(TimeOfDay.fromDateTime(event.endTime))}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SELECTED DATE EVENTS LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSelectedDateEvents(CalendarPlannerState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final events = state.eventsForSelectedDate;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacings.lg,
            Spacings.md,
            Spacings.lg,
            Spacings.sm,
          ),
          child: Row(
            children: [
              Text(
                '${events.length} Event${events.length != 1 ? 's' : ''}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                _formatMonthYear(_selectedDate).split(' ').first +
                    ' ${_selectedDate.day}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Events list
        Expanded(
          child: events.isEmpty
              ? AppEmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'No Events',
                  subtitle: 'No events scheduled for this day. Tap + to add one.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    Spacings.lg,
                    0,
                    Spacings.lg,
                    Spacings.xxl,
                  ),
                  itemCount: events.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Spacings.sm),
                  itemBuilder: (context, index) =>
                      _buildEventCard(events[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEventCard(CalendarEventEntity event) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final eventColor = _hexToColor(event.color);

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacings.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + event type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    _buildEventTypeBadge(event.eventType),
                  ],
                ),
                const SizedBox(height: Spacings.xs),

                // Time range
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      event.isAllDay
                          ? 'All Day'
                          : '${_formatTime(TimeOfDay.fromDateTime(event.startTime))} – '
                              '${_formatTime(TimeOfDay.fromDateTime(event.endTime))}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (event.location != null &&
                        event.location!.isNotEmpty) ...[
                      const SizedBox(width: Spacings.md),
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Flexible(
                        child: Text(
                          event.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Subject
                if (event.subject != null && event.subject!.isNotEmpty) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    event.subject!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                onPressed: () => _openEditEventSheet(event),
                variant: AppIconButtonVariant.standard,
                size: AppButtonSize.small,
                tooltip: 'Edit',
              ),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                onPressed: () => _handleDeleteEvent(event.id),
                variant: AppIconButtonVariant.standard,
                size: AppButtonSize.small,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeBadge(EventType type) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final color = _colorForEventType(type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForEventType(type), size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            type.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADD / EDIT EVENT BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════

  void _showEventBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: Spacings.lg,
              right: Spacings.lg,
              top: Spacings.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + Spacings.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: Spacings.lg),
                      decoration: BoxDecoration(
                        color: ctx.colorScheme.onSurfaceVariant
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    _editingEvent != null ? 'Edit Event' : 'New Event',
                    style: ctx.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: ctx.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xl),

                  // Title field
                  AppTextField(
                    label: 'Title',
                    hint: 'Enter event title',
                    controller: _titleCtrl,
                    isRequired: true,
                    prefixIcon: Icons.title_rounded,
                  ),
                  const SizedBox(height: Spacings.md),

                  // Event type dropdown
                  AppDropdownField<EventType>(
                    label: 'Event Type',
                    items: EventType.values,
                    selectedItem: _eventType,
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => _eventType = v);
                      }
                    },
                    itemLabel: (t) => t.label,
                    prefixIcon: _iconForEventType(_eventType),
                    isRequired: true,
                  ),
                  const SizedBox(height: Spacings.md),

                  // Subject field
                  AppTextField(
                    label: 'Subject',
                    hint: 'e.g. Mathematics',
                    controller: _subjectCtrl,
                    prefixIcon: Icons.book_outlined,
                  ),
                  const SizedBox(height: Spacings.md),

                  // Location field
                  AppTextField(
                    label: 'Location',
                    hint: 'e.g. Room 204',
                    controller: _locationCtrl,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: Spacings.md),

                  // All day toggle
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: Spacings.mdIcon,
                        color: ctx.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: Text(
                          'All Day',
                          style: ctx.textTheme.bodyLarge?.copyWith(
                            color: ctx.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isAllDay,
                        onChanged: (v) {
                          setModalState(() => _isAllDay = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.md),

                  // Start / End time pickers
                  if (!_isAllDay)
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePickerField(
                            context: ctx,
                            label: 'Start Time',
                            time: _startTime,
                            onPicked: (t) {
                              setModalState(() => _startTime = t);
                            },
                          ),
                        ),
                        const SizedBox(width: Spacings.md),
                        Expanded(
                          child: _buildTimePickerField(
                            context: ctx,
                            label: 'End Time',
                            time: _endTime,
                            onPicked: (t) {
                              setModalState(() => _endTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                  if (!_isAllDay) const SizedBox(height: Spacings.md),

                  // Color picker
                  Text(
                    'Color',
                    style: ctx.textTheme.bodyMedium?.copyWith(
                      color: ctx.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Row(
                    children: _kPresetColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedColor = color);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: Spacings.sm),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: ctx.colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: Spacings.md),

                  // Reminder dropdown
                  AppDropdownField<ReminderOption>(
                    label: 'Reminder',
                    items: ReminderOption.values,
                    selectedItem: _reminder,
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => _reminder = v);
                      }
                    },
                    itemLabel: (r) => r.label,
                    prefixIcon: Icons.notifications_outlined,
                  ),
                  const SizedBox(height: Spacings.xl),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _editingEvent != null ? 'Update Event' : 'Save Event',
                      onPressed: _handleSaveEvent,
                      variant: AppButtonVariant.elevated,
                      icon: Icons.check_rounded,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePickerField({
    required BuildContext context,
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPicked,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(ctx).copyWith(
                dialogTheme: DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacings.lgRadius),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.schedule_rounded, size: Spacings.mdIcon),
        ),
        child: Text(
          _formatTime(time),
          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI SUGGESTIONS DIALOG
  // ═══════════════════════════════════════════════════════════════════════

  // The AI suggestion button is in the app bar; the provider call is made
  // in _openAiSuggestions(). We show suggestions as a dialog when they
  // arrive. The listener in the build method will pick up changes.

  // ═══════════════════════════════════════════════════════════════════════
  // LOADING / ERROR STATES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
          const SizedBox(height: Spacings.lg),
          Text(
            'Loading calendar…',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(CalendarPlannerState state) {
    return AppErrorState.genericError(
      message: state.error,
      onRetry: () => ref.read(calendarPlannerProvider.notifier).loadEvents(),
    );
  }
}
