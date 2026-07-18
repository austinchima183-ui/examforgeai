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
import '../providers/child_attendance_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD ATTENDANCE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Attendance viewer page for a specific child in the Parent Portal.
///
/// Displays comprehensive attendance information including:
/// - Attendance summary card with rate and day breakdown
/// - Month selector with navigation arrows
/// - Monthly attendance calendar with colour-coded days
/// - Attendance trends card
/// - Late arrivals section
/// - Download attendance report button
///
/// Receives [studentId] as a route parameter and loads attendance
/// data using [childAttendanceProvider].
class ChildAttendancePage extends ConsumerStatefulWidget {
  const ChildAttendancePage({
    super.key,
    required this.studentId,
  });

  /// Unique identifier of the student whose attendance is displayed.
  final String studentId;

  @override
  ConsumerState<ChildAttendancePage> createState() => _State();
}

class _State extends ConsumerState<ChildAttendancePage> {
  /// The currently selected month for the calendar view.
  DateTime _selectedMonth = DateTime.now();

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceForMonth();
    });
  }

  // ─── Load Attendance ────────────────────────────────────────────────

  /// Loads attendance data for the currently selected month.
  void _loadAttendanceForMonth() {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    ref.read(childAttendanceProvider.notifier).loadAttendance(
          widget.studentId,
          startDate: start,
          endDate: end,
        );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(childAttendanceProvider);

    return Scaffold(
      appBar: const AppAppBar(title: 'Attendance Record'),
      body: _buildBody(context, attendanceState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ChildAttendanceState state) {
    // Loading state
    if (state.isLoading && state.attendance == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.attendance == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => _loadAttendanceForMonth(),
      );
    }

    // Empty state
    final attendance = state.attendance;
    if (attendance == null) {
      return AppEmptyState.noData(
        title: 'No Attendance Data',
        subtitle:
            'Attendance records will appear here once available.',
        actionLabel: 'Retry',
        onAction: () => _loadAttendanceForMonth(),
      );
    }

    // Success — render attendance
    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(childAttendanceProvider.notifier)
            .refreshAttendance(
              widget.studentId,
              startDate: DateTime(
                  _selectedMonth.year, _selectedMonth.month, 1),
              endDate: DateTime(
                  _selectedMonth.year, _selectedMonth.month + 1, 0),
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Attendance Summary Card ────────────────────────────
            _buildAttendanceSummaryCard(context, attendance),

            const SizedBox(height: Spacings.xl),

            // ─── Month Selector ─────────────────────────────────────
            _buildMonthSelector(context),

            const SizedBox(height: Spacings.md),

            // ─── Monthly Attendance Calendar ────────────────────────
            _buildMonthlyCalendar(context, attendance),

            const SizedBox(height: Spacings.xl),

            // ─── Attendance Trends Card ─────────────────────────────
            _buildTrendsCard(context, attendance),

            const SizedBox(height: Spacings.xl),

            // ─── Late Arrivals Section ──────────────────────────────
            _buildLateArrivalsSection(context, attendance),

            const SizedBox(height: Spacings.xl),

            // ─── Download Report Button ─────────────────────────────
            _buildDownloadReportButton(context),

            const SizedBox(height: Spacings.lg),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: [
              // Summary card shimmer
              AppLoadingShimmer.box(
                height: 180,
                borderRadius: Spacings.borderRadiusLg,
              ),
              const SizedBox(height: Spacings.xl),
              // Month selector shimmer
              AppLoadingShimmer.box(
                height: 48,
                borderRadius: Spacings.borderRadiusMd,
              ),
              const SizedBox(height: Spacings.md),
              // Calendar shimmer
              AppLoadingShimmer.box(
                height: 280,
                borderRadius: Spacings.borderRadiusLg,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAttendanceSummaryCard(
    BuildContext context,
    ChildAttendanceEntity attendance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Parse attendance summary from records
    final summary = _parseAttendanceSummary(attendance.records);
    final ratePct = (summary.rate * 100).round();
    final rateColor = _attendanceRateColor(summary.rate, cs.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            children: [
              Text(
                'Attendance Summary',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Circular progress with rate
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: summary.rate,
                      strokeWidth: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: rateColor,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$ratePct%',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: AppTypography.wBold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Rate',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Day breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDayStat(
                    context,
                    label: 'Present',
                    value: summary.present,
                    color: AppColors.successOf(cs.brightness),
                  ),
                  _buildDayStat(
                    context,
                    label: 'Absent',
                    value: summary.absent,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  _buildDayStat(
                    context,
                    label: 'Late',
                    value: summary.late,
                    color: AppColors.warningOf(cs.brightness),
                  ),
                  _buildDayStat(
                    context,
                    label: 'Excused',
                    value: summary.excused,
                    color: AppColors.infoOf(cs.brightness),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayStat(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    final tt = context.textTheme;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$value',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTH SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMonthSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final monthName = _monthName(_selectedMonth.month);
    final year = _selectedMonth.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                  _loadAttendanceForMonth();
                },
                tooltip: 'Previous month',
              ),
              Text(
                '$monthName $year',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                  _loadAttendanceForMonth();
                },
                tooltip: 'Next month',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MONTHLY ATTENDANCE CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMonthlyCalendar(
    BuildContext context,
    ChildAttendanceEntity attendance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Build a map of date -> status from records
    final attendanceMap = <int, String>{};
    for (final record in attendance.records) {
      final dateStr = record['date'] as String?;
      final status = record['status'] as String?;
      if (dateStr != null && status != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null &&
            date.year == _selectedMonth.year &&
            date.month == _selectedMonth.month) {
          attendanceMap[date.day] = status;
        }
      }
    }

    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    // Convert Monday=1 to Monday=0 for our grid
    final startOffset = firstWeekday - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationSm,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            children: [
              // Weekday headers
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
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
                        ))
                    .toList(),
              ),
              const SizedBox(height: Spacings.sm),
              // Day grid
              Wrap(
                spacing: 0,
                runSpacing: 0,
                children: [
                  // Empty cells for offset
                  for (int i = 0; i < startOffset; i++)
                    SizedBox(
                      width: (MediaQuery.of(context).size.width -
                              Spacings.lg * 2 -
                              Spacings.lg * 2) /
                          7,
                      height: 36,
                    ),
                  // Day cells
                  for (int day = 1; day <= daysInMonth; day++)
                    _buildCalendarDay(
                      context,
                      day: day,
                      status: attendanceMap[day],
                      isWeekend: (startOffset + day - 1) % 7 >= 5,
                    ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              // Legend
              _buildCalendarLegend(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(
    BuildContext context, {
    required int day,
    String? status,
    required bool isWeekend,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final brightness = cs.brightness;

    Color bgColor;
    Color textColor;
    switch (status?.toLowerCase()) {
      case 'present':
        bgColor = AppColors.successLight;
        textColor = AppColors.successOf(brightness);
        break;
      case 'absent':
        bgColor = AppColors.errorLight;
        textColor = AppColors.errorOf(brightness);
        break;
      case 'late':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warningOf(brightness);
        break;
      case 'excused':
        bgColor = AppColors.infoLight;
        textColor = AppColors.infoOf(brightness);
        break;
      default:
        bgColor = isWeekend
            ? cs.surfaceContainerHighest
            : Colors.transparent;
        textColor = isWeekend
            ? cs.onSurfaceVariant
            : cs.onSurface;
    }

    final width = (MediaQuery.of(context).size.width -
            Spacings.lg * 2 -
            Spacings.lg * 2) /
        7;

    return SizedBox(
      width: width,
      height: 36,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: Spacings.borderRadiusSm,
        ),
        child: Center(
          child: Text(
            '$day',
            style: tt.labelMedium?.copyWith(
              color: textColor,
              fontWeight: status != null
                  ? AppTypography.wSemiBold
                  : AppTypography.wRegular,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final brightness = cs.brightness;

    final legends = [
      _LegendEntry('Present', AppColors.successOf(brightness), AppColors.successLight),
      _LegendEntry('Absent', AppColors.errorOf(brightness), AppColors.errorLight),
      _LegendEntry('Late', AppColors.warningOf(brightness), AppColors.warningLight),
      _LegendEntry('Excused', AppColors.infoOf(brightness), AppColors.infoLight),
    ];

    return Wrap(
      spacing: Spacings.md,
      runSpacing: Spacings.xs,
      alignment: WrapAlignment.center,
      children: legends.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: entry.bgColor,
                borderRadius: Spacings.borderRadiusSm,
                border: Border.all(
                  color: entry.color.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: Spacings.xs),
            Text(
              entry.label,
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ATTENDANCE TRENDS CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTrendsCard(
    BuildContext context,
    ChildAttendanceEntity attendance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final summary = _parseAttendanceSummary(attendance.records);
    final rate = summary.rate;

    String trendText;
    IconData trendIcon;
    Color trendColor;
    if (rate >= 0.9) {
      trendText = 'Attendance is excellent this month. Keep it up!';
      trendIcon = Icons.trending_up;
      trendColor = AppColors.successOf(cs.brightness);
    } else if (rate >= 0.75) {
      trendText =
          'Attendance is acceptable but could be improved.';
      trendIcon = Icons.trending_flat;
      trendColor = AppColors.warningOf(cs.brightness);
    } else {
      trendText =
          'Attendance has declined this month. Please ensure regular attendance.';
      trendIcon = Icons.trending_down;
      trendColor = AppColors.errorOf(cs.brightness);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              Icon(trendIcon, color: trendColor, size: Spacings.lgIcon),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  trendText,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LATE ARRIVALS SECTION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildLateArrivalsSection(
    BuildContext context,
    ChildAttendanceEntity attendance,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Filter late records
    final lateRecords = attendance.records
        .where((r) => (r['status'] as String?)?.toLowerCase() == 'late')
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Late Arrivals',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          if (lateRecords.isEmpty)
            Card(
              elevation: Spacings.elevationNone,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: Center(
                  child: Text(
                    'No late arrivals this month',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            ...lateRecords.map((record) {
              final dateStr = record['date'] as String? ?? '';
              final timeStr = record['arrival_time'] as String? ??
                  record['time'] as String? ??
                  '';
              final date = DateTime.tryParse(dateStr);

              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Card(
                  elevation: Spacings.elevationNone,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.access_time,
                      color: AppColors.warningOf(cs.brightness),
                      size: Spacings.mdIcon,
                    ),
                    title: Text(
                      date != null
                          ? '${_monthAbbr(date.month)} ${date.day}, ${date.year}'
                          : dateStr,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wMedium,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: timeStr.isNotEmpty
                        ? Text(
                            'Arrived at $timeStr',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOWNLOAD REPORT BUTTON
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDownloadReportButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // TODO: Trigger attendance report download
          },
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download Attendance Report'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: Spacings.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: Spacings.borderRadiusMd,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Parses attendance records into a summary with counts and rate.
  _AttendanceSummary _parseAttendanceSummary(
    List<Map<String, dynamic>> records,
  ) {
    int present = 0;
    int absent = 0;
    int late = 0;
    int excused = 0;

    for (final record in records) {
      final status = (record['status'] as String?)?.toLowerCase();
      switch (status) {
        case 'present':
          present++;
          break;
        case 'absent':
          absent++;
          break;
        case 'late':
          late++;
          break;
        case 'excused':
          excused++;
          break;
      }
    }

    final total = present + absent + late + excused;
    final rate = total > 0 ? (present + late) / total : 0.0;

    return _AttendanceSummary(
      present: present,
      absent: absent,
      late: late,
      excused: excused,
      total: total,
      rate: rate,
    );
  }

  /// Returns the colour for an attendance rate.
  ///
  /// Green if >90%, amber if 75–90%, red if <75%.
  Color _attendanceRateColor(double rate, Brightness brightness) {
    if (rate > 0.9) return AppColors.successOf(brightness);
    if (rate >= 0.75) return AppColors.warningOf(brightness);
    return AppColors.errorOf(brightness);
  }

  /// Returns the month name for the given [month] (1 = January).
  String _monthName(int month) {
    const names = [
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
    return names[month];
  }

  /// Returns the abbreviated month name for the given [month].
  String _monthAbbr(int month) {
    const abbrs = [
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
    return abbrs[month];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// Parsed attendance summary with counts and rate.
class _AttendanceSummary {
  const _AttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.total,
    required this.rate,
  });

  final int present;
  final int absent;
  final int late;
  final int excused;
  final int total;
  final double rate;
}

/// A legend entry for the calendar colour coding.
class _LegendEntry {
  const _LegendEntry(this.label, this.color, this.bgColor);

  final String label;
  final Color color;
  final Color bgColor;
}
