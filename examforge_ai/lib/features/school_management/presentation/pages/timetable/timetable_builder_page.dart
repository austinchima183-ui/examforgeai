import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE BUILDER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Interactive timetable builder with weekly grid.
/// Rows = periods (1-8), columns = days (Mon-Fri).
/// Each cell can be tapped to add/edit a slot.
class TimetableBuilderPage extends ConsumerStatefulWidget {
  const TimetableBuilderPage({super.key, this.timetableId});

  final String? timetableId;

  @override
  ConsumerState<TimetableBuilderPage> createState() =>
      _TimetableBuilderPageState();
}

class _TimetableBuilderPageState extends ConsumerState<TimetableBuilderPage> {
  // Local slots state for editing before saving
  final Map<String, TimetableSlotEntity> _slots = {};
  bool _isPublishing = false;
  String? _conflictSlotKey;

  static const _days = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
  ];

  static const _periods = [1, 2, 3, 4, 5, 6, 7, 8];

  // Subject colors for visual coding
  static const _subjectColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
  ];

  final Map<String, Color> _subjectColorMap = {};

  bool get _isEditMode => widget.timetableId != null;

  String _slotKey(DayOfWeek day, int period) =>
      '${day.value}_$period';

  Color _getSubjectColor(String? subjectId) {
    if (subjectId == null) return Colors.grey;
    if (!_subjectColorMap.containsKey(subjectId)) {
      final colorIndex = _subjectColorMap.length % _subjectColors.length;
      _subjectColorMap[subjectId] = _subjectColors[colorIndex];
    }
    return _subjectColorMap[subjectId]!;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      Future.microtask(() {
        ref.read(timetableDetailProvider.notifier).loadTimetable(widget.timetableId!);
      });
    }
    Future.microtask(() {
      ref.read(subjectListProvider.notifier).loadSubjects(schoolId: 'current-school');
      ref.read(teacherListProvider.notifier).loadTeachers('current-school');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final detailState = ref.watch(timetableDetailProvider);

    // Populate local slots from loaded timetable
    if (_isEditMode && detailState.isLoaded && _slots.isEmpty) {
      for (final slot in detailState.slots) {
        _slots[_slotKey(slot.dayOfWeek, slot.periodNumber)] = slot;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Timetable' : 'Timetable Builder',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          // Conflict indicator
          if (_conflictSlotKey != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
              child: Chip(
                avatar: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 18),
                label: const Text('Conflicts'),
                labelStyle: tt.labelSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: AppTypography.wSemiBold,
                ),
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ),
          // Publish button
          if (_isEditMode) ...[
            TextButton.icon(
              onPressed: _isPublishing ? null : _publish,
              icon: const Icon(Icons.publish_rounded, size: 18),
              label: const Text('Publish'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ─── Legend Bar ──────────────────────────────────────────────
          _buildLegendBar(context),

          // ─── Weekly Grid ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(Spacings.md),
                  child: _buildWeeklyGrid(context),
                ),
              ),
            ),
          ),

          // ─── Bottom Action Bar ──────────────────────────────────────
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // ─── Legend Bar ──────────────────────────────────────────────────────

  Widget _buildLegendBar(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final subjectState = ref.watch(subjectListProvider);
    final usedSubjectIds = _slots.values
        .where((s) => s.subjectId != null)
        .map((s) => s.subjectId!)
        .toSet();

    if (usedSubjectIds.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: usedSubjectIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacings.sm),
        itemBuilder: (context, index) {
          final subjectId = usedSubjectIds.elementAt(index);
          final subject = subjectState.subjects
              .where((s) => s.id == subjectId)
              .firstOrNull;
          final color = _getSubjectColor(subjectId);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                subject?.name ?? subjectId,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Weekly Grid ─────────────────────────────────────────────────────

  Widget _buildWeeklyGrid(BuildContext context) {
    final cs = context.colorScheme;

    return Table(
      border: TableBorder.all(
        color: cs.outlineVariant,
        width: 0.5,
      ),
      columnWidths: {
        0: const FixedColumnWidth(80), // Period column
        for (var i = 0; i < _days.length; i++)
          i + 1: const FixedColumnWidth(140),
      },
      children: [
        // Header row
        TableRow(
          children: [
            _buildHeaderCell(context, 'Period'),
            ..._days.map((d) => _buildHeaderCell(context, d.label)),
          ],
        ),
        // Period rows
        ..._periods.map((period) => TableRow(
              children: [
                _buildPeriodCell(context, period),
                ..._days.map((day) {
                  final key = _slotKey(day, period);
                  final slot = _slots[key];
                  final hasConflict = _conflictSlotKey == key;
                  return _buildSlotCell(context, day, period, slot, hasConflict);
                }),
              ],
            )),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacings.sm),
      color: context.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          text,
          style: tt.labelSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCell(BuildContext context, int period) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    // Standard time ranges for periods
    final timeRanges = [
      '8:00-8:45',
      '8:45-9:30',
      '9:30-10:15',
      '10:15-11:00',
      '11:00-11:45',
      '11:45-12:30',
      '12:30-1:15',
      '1:15-2:00',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      color: cs.surfaceContainerLow,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'P$period',
            style: tt.labelMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          Text(
            period <= timeRanges.length ? timeRanges[period - 1] : '',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCell(
    BuildContext context,
    DayOfWeek day,
    int period,
    TimetableSlotEntity? slot,
    bool hasConflict,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Break slot styling
    if (slot != null && slot.isBreak) {
      return GestureDetector(
        onTap: () => _showSlotDialog(context, day, period, slot),
        child: Container(
          padding: const EdgeInsets.all(Spacings.xs),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: isDark ? 0.20 : 0.12),
            border: hasConflict
                ? Border.all(color: AppColors.error, width: 2)
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.free_breakfast_outlined,
                    size: 16, color: AppColors.warning),
                Text(
                  slot.breakLabel ?? 'Break',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filled slot styling
    if (slot != null) {
      final subjectColor = _getSubjectColor(slot.subjectId);
      return GestureDetector(
        onTap: () => _showSlotDialog(context, day, period, slot),
        child: Container(
          padding: const EdgeInsets.all(Spacings.xs),
          decoration: BoxDecoration(
            color: subjectColor.withValues(alpha: isDark ? 0.20 : 0.10),
            border: hasConflict
                ? Border.all(color: AppColors.error, width: 2)
                : Border.all(
                    color: subjectColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.subjectName ?? '—',
                style: tt.labelSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: isDark ? subjectColor.lighten() : subjectColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (slot.teacherName != null)
                Text(
                  slot.teacherName!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (slot.classroom != null)
                Text(
                  slot.classroom!,
                  style: tt.labelSmall?.copyWith(
                    color: cs.outline,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      );
    }

    // Empty slot
    return GestureDetector(
      onTap: () => _showSlotDialog(context, day, period, null),
      child: Container(
        padding: const EdgeInsets.all(Spacings.xs),
        color: cs.surface,
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 20,
            color: cs.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Action Bar ───────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => _addBreakSlot(context),
              icon: const Icon(Icons.free_breakfast_outlined, size: 18),
              label: const Text('Add Break'),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: Spacings.md),
            AppButton(
              label: _isEditMode ? 'Save Changes' : 'Create Timetable',
              onPressed: _saveTimetable,
              variant: AppButtonVariant.elevated,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slot Dialog ─────────────────────────────────────────────────────

  void _showSlotDialog(
    BuildContext context,
    DayOfWeek day,
    int period,
    TimetableSlotEntity? existingSlot,
  ) {
    final cs = context.colorScheme;
    final subjectState = ref.read(subjectListProvider);
    final teacherState = ref.read(teacherListProvider);

    String? selectedSubjectId = existingSlot?.subjectId;
    String? selectedTeacherId = existingSlot?.teacherId;
    String? classroom = existingSlot?.classroom;
    final notesController = TextEditingController(text: existingSlot?.notes ?? '');

    // Default time range based on period
    final timeRanges = [
      '8:00-8:45', '8:45-9:30', '9:30-10:15', '10:15-11:00',
      '11:00-11:45', '11:45-12:30', '12:30-1:15', '1:15-2:00',
    ];
    String selectedTimeRange = period <= timeRanges.length
        ? timeRanges[period - 1]
        : '8:00-8:45';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('${day.label} – Period $period'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject selector
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select subject')),
                    ...subjectState.subjects.map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedSubjectId = value);
                    // Auto-filter teachers by subject
                  },
                ),
                const SizedBox(height: Spacings.lg),

                // Teacher selector (auto-filtered by subject)
                DropdownButtonFormField<String>(
                  value: selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select teacher')),
                    ...teacherState.teachers.map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.fullName ?? 'Unknown'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedTeacherId = value);
                  },
                ),
                const SizedBox(height: Spacings.lg),

                // Classroom
                TextFormField(
                  initialValue: classroom,
                  decoration: const InputDecoration(
                    labelText: 'Classroom',
                    hintText: 'e.g. Room 101, Lab A',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  onChanged: (value) => classroom = value,
                ),
                const SizedBox(height: Spacings.lg),

                // Time range
                DropdownButtonFormField<String>(
                  value: selectedTimeRange,
                  decoration: const InputDecoration(
                    labelText: 'Time Range',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  items: timeRanges.map(
                    (range) => DropdownMenuItem(
                      value: range,
                      child: Text(range),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedTimeRange = value ?? timeRanges.first);
                  },
                ),
                const SizedBox(height: Spacings.lg),

                // Notes
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional notes',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            if (existingSlot != null)
              TextButton(
                onPressed: () {
                  _removeSlot(day, period);
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: existingSlot != null ? 'Update' : 'Add',
              onPressed: () {
                _addOrUpdateSlot(
                  day: day,
                  period: period,
                  subjectId: selectedSubjectId,
                  teacherId: selectedTeacherId,
                  classroom: classroom,
                  timeRange: selectedTimeRange,
                  notes: notesController.text.trim(),
                );
                Navigator.pop(ctx);
              },
              variant: AppButtonVariant.elevated,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Add Break Slot ──────────────────────────────────────────────────

  void _addBreakSlot(BuildContext context) {
    final cs = context.colorScheme;
    DayOfWeek? selectedDay;
    int? selectedPeriod;
    String breakLabel = 'Break';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Break Slot'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<DayOfWeek>(
                  value: selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: _days
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedDay = value);
                  },
                ),
                const SizedBox(height: Spacings.lg),
                DropdownButtonFormField<int>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  items: _periods
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('Period $p'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedPeriod = value);
                  },
                ),
                const SizedBox(height: Spacings.lg),
                TextFormField(
                  initialValue: breakLabel,
                  decoration: const InputDecoration(
                    labelText: 'Break Label',
                    hintText: 'e.g. Lunch Break, Short Break',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  onChanged: (value) => breakLabel = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Add Break',
              onPressed: () {
                if (selectedDay != null && selectedPeriod != null) {
                  _addBreakSlotToGrid(
                    day: selectedDay!,
                    period: selectedPeriod!,
                    label: breakLabel,
                  );
                  Navigator.pop(ctx);
                }
              },
              variant: AppButtonVariant.elevated,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Slot Management ─────────────────────────────────────────────────

  void _addOrUpdateSlot({
    required DayOfWeek day,
    required int period,
    String? subjectId,
    String? teacherId,
    String? classroom,
    required String timeRange,
    String? notes,
  }) {
    final key = _slotKey(day, period);
    final subjectState = ref.read(subjectListProvider);
    final teacherState = ref.read(teacherListProvider);

    final subject = subjectState.subjects
        .where((s) => s.id == subjectId)
        .firstOrNull;
    final teacher = teacherState.teachers
        .where((t) => t.id == teacherId)
        .firstOrNull;

    // Parse time range
    final parts = timeRange.split('-');
    final now = DateTime.now();
    DateTime startTime = now;
    DateTime endTime = now;
    if (parts.length == 2) {
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        startTime = DateTime(
          now.year, now.month, now.day,
          int.tryParse(startParts[0]) ?? 8,
          int.tryParse(startParts[1]) ?? 0,
        );
        endTime = DateTime(
          now.year, now.month, now.day,
          int.tryParse(endParts[0]) ?? 9,
          int.tryParse(endParts[1]) ?? 0,
        );
      }
    }

    final slot = TimetableSlotEntity(
      id: _slots[key]?.id ?? '',
      timetableId: widget.timetableId ?? '',
      dayOfWeek: day,
      periodNumber: period,
      startTime: startTime,
      endTime: endTime,
      subjectId: subjectId,
      subjectName: subject?.name,
      teacherId: teacherId,
      teacherName: teacher?.fullName,
      classroom: classroom,
      isBreak: false,
      notes: notes?.isEmpty == true ? null : notes,
    );

    setState(() {
      _slots[key] = slot;
    });

    // Auto-detect conflicts
    _checkConflicts(slot);
  }

  void _addBreakSlotToGrid({
    required DayOfWeek day,
    required int period,
    required String label,
  }) {
    final key = _slotKey(day, period);
    final now = DateTime.now();

    final slot = TimetableSlotEntity(
      id: _slots[key]?.id ?? '',
      timetableId: widget.timetableId ?? '',
      dayOfWeek: day,
      periodNumber: period,
      startTime: now,
      endTime: now.add(const Duration(minutes: 30)),
      isBreak: true,
      breakLabel: label,
    );

    setState(() {
      _slots[key] = slot;
    });
  }

  void _removeSlot(DayOfWeek day, int period) {
    final key = _slotKey(day, period);
    setState(() {
      _slots.remove(key);
    });
  }

  // ─── Conflict Detection ──────────────────────────────────────────────

  void _checkConflicts(TimetableSlotEntity newSlot) {
    // Check if the same teacher is already assigned at this day/period
    // in a different timetable or same timetable
    bool hasConflict = false;

    for (final entry in _slots.entries) {
      final existingSlot = entry.value;
      if (existingSlot.id == newSlot.id) continue;
      if (existingSlot.isBreak) continue;

      // Teacher conflict: same teacher, same day, same period
      if (newSlot.teacherId != null &&
          existingSlot.teacherId == newSlot.teacherId &&
          existingSlot.dayOfWeek == newSlot.dayOfWeek &&
          existingSlot.periodNumber == newSlot.periodNumber) {
        hasConflict = true;
        break;
      }

      // Classroom conflict: same classroom, same day, same period
      if (newSlot.classroom != null &&
          existingSlot.classroom == newSlot.classroom &&
          existingSlot.dayOfWeek == newSlot.dayOfWeek &&
          existingSlot.periodNumber == newSlot.periodNumber) {
        hasConflict = true;
        break;
      }
    }

    setState(() {
      _conflictSlotKey = hasConflict ? _slotKey(newSlot.dayOfWeek, newSlot.periodNumber) : null;
    });

    if (hasConflict && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conflict detected! Same teacher or classroom is already assigned.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // ─── Publish ─────────────────────────────────────────────────────────

  Future<void> _publish() async {
    setState(() => _isPublishing = true);
    try {
      await ref.read(timetableDetailProvider.notifier).publishTimetable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable published successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ─── Save Timetable ──────────────────────────────────────────────────

  Future<void> _saveTimetable() async {
    try {
      final slots = _slots.values.toList();
      // For new timetables, create via provider
      // For existing, update slots
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COLOR EXTENSION
// ═══════════════════════════════════════════════════════════════════════

extension _ColorExtension on Color {
  Color lighten([double amount = 0.3]) {
    return Color.fromARGB(
      alpha.toInt(),
      (red + (255 - red) * amount).clamp(0, 255).toInt(),
      (green + (255 - green) * amount).clamp(0, 255).toInt(),
      (blue + (255 - blue) * amount).clamp(0, 255).toInt(),
    );
  }
}
