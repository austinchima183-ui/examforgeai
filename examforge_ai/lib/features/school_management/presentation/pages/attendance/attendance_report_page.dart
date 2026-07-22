import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/class_provider.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../features/school_management/domain/entities/school_management_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE REPORT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Attendance overview dashboard with class filter, date range filter,
/// summary cards, per-class attendance rate bar chart, and student table.
class AttendanceReportPage extends ConsumerStatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  ConsumerState<AttendanceReportPage> createState() =>
      _AttendanceReportPageState();
}

class _AttendanceReportPageState extends ConsumerState<AttendanceReportPage> {
  String? _selectedClassId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTermId = 'current-term';

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();

    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
      _loadReport();
    });
  }

  void _loadReport() {
    ref.read(attendanceReportProvider.notifier).loadRecords(
          schoolId: 'current-school',
          termId: _selectedTermId,
          classId: _selectedClassId,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);
    final reportState = ref.watch(attendanceReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Report',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportReport,
            tooltip: 'Export report',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Bar ──────────────────────────────────────────────
          _buildFilterBar(context, classState),

          // ─── Report Content ──────────────────────────────────────────
          Expanded(
            child: reportState.isLoading
                ? const Center(
                    child: AppLoadingSpinner(
                        size: AppLoadingSpinnerSize.large),
                  )
                : reportState.error != null
                    ? AppErrorState.genericError(
                        message: reportState.error,
                        onRetry: _loadReport,
                      )
                    : reportState.records.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.assessment_outlined,
                            title: 'No Data',
                            subtitle:
                                'No attendance records found for the selected period.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadReport(),
                            child: ListView(
                              padding: const EdgeInsets.all(Spacings.md),
                              children: [
                                // Summary cards
                                _buildSummaryCards(context, reportState),
                                const SizedBox(height: Spacings.xl),

                                // Bar chart
                                _buildAttendanceBarChart(context, reportState),
                                const SizedBox(height: Spacings.xl),

                                // Student table
                                _buildStudentTable(context, reportState),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Bar ──────────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, ClassListState classState) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Class filter
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Class',
                prefixIcon: Icon(Icons.class_outlined, size: 20),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Classes'),
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
                _loadReport();
              },
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Date range
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date Range',
                  prefixIcon: Icon(Icons.date_range_rounded, size: 20),
                  isDense: true,
                ),
                child: Text(
                  _startDate != null && _endDate != null
                      ? '${_formatDate(_startDate!)} – ${_formatDate(_endDate!)}'
                      : 'Select range',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Cards ───────────────────────────────────────────────────

  Widget _buildSummaryCards(
    BuildContext context,
    AttendanceReportState reportState,
  ) {
    final summary = reportState.summary;
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Calculate totals from records when summary is null
    final totalDays = summary?.totalDays ?? reportState.records.length;
    final avgRate = summary?.averageAttendanceRate ?? 0.0;
    final highestClass = summary?.className ?? '—';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.calendar_month_rounded,
            label: 'Total Days',
            value: totalDays.toString(),
            color: AppColors.info,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: _SummaryCard(
            icon: Icons.trending_up_rounded,
            label: 'Avg. Rate',
            value: '${avgRate.toStringAsFixed(1)}%',
            color: avgRate >= 75 ? AppColors.success : AppColors.warning,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: _SummaryCard(
            icon: Icons.emoji_events_rounded,
            label: 'Top Class',
            value: highestClass,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─── Attendance Bar Chart (Simple Container-based) ───────────────────

  Widget _buildAttendanceBarChart(
    BuildContext context,
    AttendanceReportState reportState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Group attendance by class
    final Map<String, _ClassAttendanceStats> classStats = {};
    for (final record in reportState.records) {
      final classId = record.classId;
      if (!classStats.containsKey(classId)) {
        classStats[classId] = _ClassAttendanceStats(classId: classId);
      }
      final stats = classStats[classId]!;
      for (final entry in record.entries) {
        switch (entry.status) {
          case AttendanceStatus.present:
            stats.present++;
          case AttendanceStatus.late:
            stats.late++;
          case AttendanceStatus.absent:
            stats.absent++;
          case AttendanceStatus.excused:
            stats.excused++;
          case AttendanceStatus.sick:
            stats.sick++;
        }
        stats.total++;
      }
    }

    // Get class names from provider
    final classState = ref.read(classListProvider);
    for (final stats in classStats.values) {
      final cls = classState.classes.where((c) => c.id == stats.classId).firstOrNull;
      stats.className = cls?.name ?? stats.classId;
    }

    if (classStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxTotal = classStats.values
        .map((s) => s.total)
        .fold(0, (a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: cs.primary, size: 20),
              const SizedBox(width: Spacings.sm),
              Text(
                'Per-Class Attendance Rate',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xl),
          // Bar chart
          ...classStats.values.map((stats) {
            final presentRate = stats.total > 0
                ? stats.present / stats.total
                : 0.0;
            final lateRate = stats.total > 0
                ? stats.late / stats.total
                : 0.0;
            final absentRate = stats.total > 0
                ? stats.absent / stats.total
                : 0.0;
            final attendanceRate = stats.total > 0
                ? ((stats.present + stats.late) / stats.total * 100)
                    .toStringAsFixed(1)
                : '0.0';

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stats.className ?? '',
                        style: tt.bodySmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '$attendanceRate%',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  // Stacked bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          // Present (green)
                          Expanded(
                            flex: (presentRate * 100).round().clamp(1, 100),
                            child: Container(
                              color: AppColors.success,
                            ),
                          ),
                          // Late (amber)
                          Expanded(
                            flex: (lateRate * 100).round().clamp(0, 100),
                            child: Container(
                              color: AppColors.warning,
                            ),
                          ),
                          // Absent (red)
                          Expanded(
                            flex: (absentRate * 100).round().clamp(1, 100),
                            child: Container(
                              color: AppColors.error.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Legend
          const SizedBox(height: Spacings.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(color: AppColors.success, label: 'Present', isDark: isDark),
              const SizedBox(width: Spacings.md),
              _ChartLegend(color: AppColors.warning, label: 'Late', isDark: isDark),
              const SizedBox(width: Spacings.md),
              _ChartLegend(color: AppColors.error, label: 'Absent', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Student Attendance Table ────────────────────────────────────────

  Widget _buildStudentTable(
    BuildContext context,
    AttendanceReportState reportState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final summary = reportState.summary;

    // Use summary data if available, otherwise compute from records
    final List<_StudentAttendanceRow> rows = [];

    if (summary != null) {
      for (final detail in [...summary.topAttendees, ...summary.lowAttendees]) {
        rows.add(_StudentAttendanceRow(
          studentId: detail.studentId,
          name: detail.studentName ?? 'Unknown',
          admissionNumber: detail.admissionNumber ?? '-',
          presentDays: detail.presentDays,
          absentDays: detail.absentDays,
          lateDays: detail.lateDays,
          excusedDays: detail.excusedDays,
          rate: detail.attendanceRate,
        ));
      }
    } else {
      // Fallback: aggregate from records
      final Map<String, _StudentAttendanceRow> studentMap = {};
      for (final record in reportState.records) {
        for (final entry in record.entries) {
          if (!studentMap.containsKey(entry.userId)) {
            studentMap[entry.userId] = _StudentAttendanceRow(
              studentId: entry.userId,
              name: entry.userName ?? 'Unknown',
              admissionNumber: entry.admissionNumber ?? '-',
            );
          }
          final row = studentMap[entry.userId]!;
          switch (entry.status) {
            case AttendanceStatus.present:
              row.presentDays++;
            case AttendanceStatus.absent:
              row.absentDays++;
            case AttendanceStatus.late:
              row.lateDays++;
            case AttendanceStatus.excused:
              row.excusedDays++;
            case AttendanceStatus.sick:
              row.excusedDays++;
          }
          row.rate = row.totalDays > 0
              ? (row.presentDays + row.lateDays) / row.totalDays * 100
              : 0.0;
        }
      }
      rows.addAll(studentMap.values);
    }

    // Sort by rate descending
    rows.sort((a, b) => b.rate.compareTo(a.rate));

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart_rounded, color: cs.primary, size: 20),
              const SizedBox(width: Spacings.sm),
              Text(
                'Student Attendance',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Spacings.smRadius),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Student')),
                _tableHeaderCell('Present', flex: 1),
                _tableHeaderCell('Absent', flex: 1),
                _tableHeaderCell('Late', flex: 1),
                _tableHeaderCell('Rate', flex: 1),
              ],
            ),
          ),
          // Table rows
          ...rows.map((row) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: cs.outlineVariant.withOpacity(0.3), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.name,
                            style: tt.bodySmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            row.admissionNumber,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        row.presentDays.toString(),
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        row.absentDays.toString(),
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        row.lateDays.toString(),
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _rateColor(row.rate)
                              .withOpacity(isDark ? 0.20 : 0.12),
                          borderRadius:
                              BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          '${row.rate.toStringAsFixed(1)}%',
                          style: tt.labelSmall?.copyWith(
                            color: _rateColor(row.rate),
                            fontWeight: AppTypography.wSemiBold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String text, {int flex = 1}) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 90) return AppColors.success;
    if (rate >= 75) return AppColors.info;
    if (rate >= 50) return AppColors.warning;
    return AppColors.error;
  }

  // ─── Date Range Picker ───────────────────────────────────────────────

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  // ─── Export ──────────────────────────────────────────────────────────

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: Spacings.md),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHART LEGEND
// ═══════════════════════════════════════════════════════════════════════

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    required this.isDark,
  });

  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _ClassAttendanceStats {
  _ClassAttendanceStats({required this.classId});

  final String classId;
  String? className;
  int present = 0;
  int absent = 0;
  int late = 0;
  int excused = 0;
  int sick = 0;
  int total = 0;
}

class _StudentAttendanceRow {
  _StudentAttendanceRow({
    required this.studentId,
    required this.name,
    required this.admissionNumber,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.excusedDays = 0,
    this.rate = 0.0,
  });

  final String studentId;
  final String name;
  final String admissionNumber;
  int presentDays;
  int absentDays;
  int lateDays;
  int excusedDays;
  double rate;

  int get totalDays => presentDays + absentDays + lateDays + excusedDays;
}
