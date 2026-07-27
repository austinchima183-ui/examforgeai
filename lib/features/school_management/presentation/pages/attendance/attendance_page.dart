import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/class_provider.dart';
import 'attendance_report_page.dart';



// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Attendance recording page for a class on a specific date.
/// Supports quick actions: Mark All Present, Mark All Absent.
/// Status options: Present, Absent, Late, Excused, Sick.
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  String? _selectedClassId;
  String? _selectedTermId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // Local attendance entries state
  final Map<String, AttendanceStatus> _entryStatuses = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);
    final attendanceState = ref.watch(attendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AttendanceReportPage(),
                ),
              );
            },
            tooltip: 'View reports',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Selector Bar ────────────────────────────────────────────
          _buildSelectorBar(context, classState),

          // ─── Quick Actions ───────────────────────────────────────────
          if (_selectedClassId != null) _buildQuickActions(context),

          // ─── Student List ────────────────────────────────────────────
          Expanded(
            child: _selectedClassId == null
                ? _buildClassSelector(context, classState)
                : attendanceState.isLoading
                    ? const Center(
                        child: AppLoadingSpinner(
                            size: AppLoadingSpinnerSize.large,),
                      )
                    : attendanceState.error != null
                        ? AppErrorState.genericError(
                            message: attendanceState.error,
                            onRetry: () => _loadRecord(),
                          )
                        : attendanceState.record == null ||
                                attendanceState.entries.isEmpty
                            ? const AppEmptyState(
                                icon: Icons.group_outlined,
                                title: 'No Students',
                                subtitle:
                                    'No students found for this class.',
                              )
                            : _buildStudentList(
                                context, attendanceState,),
          ),

          // ─── Summary & Save ──────────────────────────────────────────
          if (_selectedClassId != null &&
              attendanceState.record != null &&
              attendanceState.entries.isNotEmpty)
            _buildSummaryAndSave(context, attendanceState),
        ],
      ),
    );
  }

  // ─── Selector Bar ────────────────────────────────────────────────────

  Widget _buildSelectorBar(BuildContext context, ClassListState classState) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Class selector
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.class_outlined, size: 20),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select class'),
                ),
                ...classState.classes.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedClassId = value);
                if (value != null) _loadRecord();
              },
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Date picker
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  isDense: true,
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Term selector
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTermId ?? 'current-term',
              decoration: const InputDecoration(
                labelText: 'Term',
                prefixIcon: Icon(Icons.calendar_view_week_outlined, size: 20),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'current-term', child: Text('Current')),
              ],
              onChanged: (value) {
                setState(() => _selectedTermId = value);
                if (_selectedClassId != null) _loadRecord();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          Text(
            'Quick Actions:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: Spacings.sm),
          ActionChip(
            avatar: const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: AppColors.success,),
            label: const Text('All Present'),
            onPressed: () => _markAll(AttendanceStatus.present),
          ),
          const SizedBox(width: Spacings.sm),
          ActionChip(
            avatar: const Icon(Icons.cancel_outlined,
                size: 16, color: AppColors.error,),
            label: const Text('All Absent'),
            onPressed: () => _markAll(AttendanceStatus.absent),
          ),
        ],
      ),
    );
  }

  // ─── Class Selector (when no class is selected) ──────────────────────

  Widget _buildClassSelector(BuildContext context, ClassListState classState) {
    final cs = context.colorScheme;
    if (classState.isLoading) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (classState.classes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'No Classes',
        subtitle: 'Create a class first to record attendance.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(Spacings.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: classState.classes.length,
      itemBuilder: (context, index) {
        final cls = classState.classes[index];
        return AppCard(
          onTap: () {
            setState(() => _selectedClassId = cls.id);
            _loadRecord();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_rounded, color: cs.primary, size: 32),
              const SizedBox(height: Spacings.sm),
              Text(
                cls.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${cls.studentCount} students',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Student List ────────────────────────────────────────────────────

  Widget _buildStudentList(BuildContext context, AttendanceState state) {
    final entries = state.entries;
    // Initialize local statuses from the loaded entries
    if (_entryStatuses.isEmpty) {
      for (final entry in entries) {
        _entryStatuses[entry.id] = entry.status;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final currentStatus = _entryStatuses[entry.id] ?? entry.status;

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: _AttendanceEntryCard(
            entry: entry,
            currentStatus: currentStatus,
            onStatusChanged: (status) {
              setState(() {
                _entryStatuses[entry.id] = status;
              });
            },
          ),
        );
      },
    );
  }

  // ─── Summary & Save ──────────────────────────────────────────────────

  Widget _buildSummaryAndSave(BuildContext context, AttendanceState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final entries = state.entries;

    // Calculate summary
    int present = 0, absent = 0, late = 0, excused = 0, sick = 0;
    for (final entry in entries) {
      final status = _entryStatuses[entry.id] ?? entry.status;
      switch (status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.excused:
          excused++;
        case AttendanceStatus.sick:
          sick++;
      }
    }

    final total = entries.length;
    final attendanceRate = total > 0
        ? ((present + late) / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SummaryChip(
                  label: 'Present',
                  count: present,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                _SummaryChip(
                  label: 'Absent',
                  count: absent,
                  color: AppColors.error,
                  isDark: isDark,
                ),
                _SummaryChip(
                  label: 'Late',
                  count: late,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                _SummaryChip(
                  label: 'Excused',
                  count: excused,
                  color: AppColors.info,
                  isDark: isDark,
                ),
                _SummaryChip(
                  label: 'Sick',
                  count: sick,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            // Rate + Save
            Row(
              children: [
                // Attendance rate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$attendanceRate%',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: double.parse(attendanceRate) >= 75
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    Text(
                      'Attendance Rate',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Save button
                AppButton(
                  label: 'Save Attendance',
                  onPressed: _isSaving ? null : _saveAttendance,
                  variant: AppButtonVariant.elevated,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────

  void _loadRecord() {
    if (_selectedClassId == null) return;
    ref.read(attendanceProvider.notifier).loadRecord(
          classId: _selectedClassId!,
          termId: _selectedTermId ?? 'current-term',
          date: _selectedDate,
        );
    _entryStatuses.clear();
  }

  void _markAll(AttendanceStatus status) {
    final state = ref.read(attendanceProvider);
    setState(() {
      for (final entry in state.entries) {
        _entryStatuses[entry.id] = status;
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedClassId != null) _loadRecord();
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      final state = ref.read(attendanceProvider);
      final updatedEntries = state.entries.map((entry) {
        final newStatus = _entryStatuses[entry.id];
        if (newStatus != null && newStatus != entry.status) {
          return entry.copyWith(status: newStatus);
        }
        return entry;
      }).toList();

      await ref.read(attendanceProvider.notifier).markAttendance(updatedEntries);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE ENTRY CARD
// ═══════════════════════════════════════════════════════════════════════

class _AttendanceEntryCard extends StatelessWidget {
  const _AttendanceEntryCard({
    required this.entry,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  final AttendanceEntryEntity entry;
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.excused:
        return AppColors.info;
      case AttendanceStatus.sick:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.late:
        return Icons.schedule_rounded;
      case AttendanceStatus.excused:
        return Icons.description_rounded;
      case AttendanceStatus.sick:
        return Icons.sick_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final statusColor = _statusColor(currentStatus);

    return AppCard(
      child: Row(
        children: [
          // Student avatar + name
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(_statusIcon(currentStatus), color: statusColor, size: 22),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName ?? 'Unknown Student',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.admissionNumber != null)
                  Text(
                    entry.admissionNumber!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Status toggle buttons
          _StatusToggleGroup(
            currentStatus: currentStatus,
            onStatusChanged: onStatusChanged,
            statusColor: _statusColor,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATUS TOGGLE GROUP
// ═══════════════════════════════════════════════════════════════════════

class _StatusToggleGroup extends StatelessWidget {
  const _StatusToggleGroup({
    required this.currentStatus,
    required this.onStatusChanged,
    required this.statusColor,
  });

  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final Color Function(AttendanceStatus) statusColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AttendanceStatus.values.map((status) {
          final isSelected = status == currentStatus;
          final color = statusColor(status);
          return GestureDetector(
            onTap: () => onStatusChanged(status),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.30 : 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: status == AttendanceStatus.present
                      ? const Radius.circular(Spacings.smRadius)
                      : Radius.zero,
                  right: status == AttendanceStatus.sick
                      ? const Radius.circular(Spacings.smRadius)
                      : Radius.zero,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _statusIcon(status),
                    size: 16,
                    color: isSelected ? color : cs.outline,
                  ),
                  Text(
                    status.label.substring(0, 1),
                    style: tt.labelSmall?.copyWith(
                      color: isSelected ? color : cs.outline,
                      fontWeight: isSelected
                          ? AppTypography.wSemiBold
                          : AppTypography.wRegular,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_rounded;
      case AttendanceStatus.absent:
        return Icons.close_rounded;
      case AttendanceStatus.late:
        return Icons.schedule_rounded;
      case AttendanceStatus.excused:
        return Icons.description_rounded;
      case AttendanceStatus.sick:
        return Icons.sick_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUMMARY CHIP
// ═══════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int count;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Text(
            count.toString(),
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
