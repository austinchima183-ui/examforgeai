import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';

// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE CALENDAR
// ═══════════════════════════════════════════════════════════════════════

/// Monthly calendar grid showing attendance status per day.
///
/// Displays a 7-column grid (Mon–Sun) with each cell coloured based on
/// attendance status: present (green), absent (red), late (amber),
/// excused (blue), or unmarked (transparent). Today's cell has a border.
/// Weekends are slightly dimmed. Tapping a day fires [onDaySelected].
///
/// ```dart
/// AttendanceCalendar(
///   year: 2025,
///   month: 3,
///   attendanceMap: {5: 'present', 6: 'absent', 7: 'late'},
///   onDaySelected: (date) => showDayDetail(date),
/// )
/// ```
class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.attendanceMap,
    this.onDaySelected,
  });

  /// The calendar year (e.g. 2025).
  final int year;

  /// The calendar month (1–12).
  final int month;

  /// Map of day → status string.
  /// Accepted values: `'present'`, `'absent'`, `'late'`, `'excused'`.
  final Map<int, String> attendanceMap;

  /// Callback when a day cell is tapped.
  final ValueChanged<DateTime>? onDaySelected;

  // ─── Constants ─────────────────────────────────────────────────────

  static const List<String> _dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstDayOfMonth = DateTime(year, month, 1);
    // Monday = 1 … Sunday = 7  →  convert to 0-based index where Mon = 0
    final startWeekday = (firstDayOfMonth.weekday - 1) % 7;
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Month / Year Header ─────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                _monthLabel(year, month),
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              _buildLegend(cs, tt, isDark),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Day-of-Week Headers ─────────────────────────────────
          Row(
            children: _dayHeaders.map((d) {
              final isWeekend = d == 'Sat' || d == 'Sun';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: isWeekend
                          ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacings.xs),

          // ── Day Grid ────────────────────────────────────────────
          ..._buildWeekRows(
            context: context,
            cs: cs,
            tt: tt,
            isDark: isDark,
            daysInMonth: daysInMonth,
            startWeekday: startWeekday,
            isCurrentMonth: isCurrentMonth,
            todayDay: today.day,
          ),
        ],
      ),
    );
  }

  // ─── Week Row Builder ─────────────────────────────────────────────

  List<Widget> _buildWeekRows({
    required BuildContext context,
    required ColorScheme cs,
    required TextTheme tt,
    required bool isDark,
    required int daysInMonth,
    required int startWeekday,
    required bool isCurrentMonth,
    required int todayDay,
  }) {
    final rows = <Widget>[];
    int dayCounter = 1;

    // Total cells needed: leading blanks + days in month
    final totalCells = startWeekday + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    for (int row = 0; row < totalRows; row++) {
      final cells = <Widget>[];

      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;

        if (cellIndex < startWeekday || dayCounter > daysInMonth) {
          // Empty cell
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final day = dayCounter++;
          final weekday = col + 1; // 1=Mon … 7=Sun
          final isWeekend = weekday >= 6;
          final isToday = isCurrentMonth && day == todayDay;
          final status = attendanceMap[day];

          cells.add(
            Expanded(
              child: _buildDayCell(
                context: context,
                cs: cs,
                tt: tt,
                isDark: isDark,
                day: day,
                status: status,
                isToday: isToday,
                isWeekend: isWeekend,
              ),
            ),
          );
        }
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: Spacings.xs),
          child: Row(children: cells),
        ),
      );
    }

    return rows;
  }

  // ─── Individual Day Cell ──────────────────────────────────────────

  Widget _buildDayCell({
    required BuildContext context,
    required ColorScheme cs,
    required TextTheme tt,
    required bool isDark,
    required int day,
    required String? status,
    required bool isToday,
    required bool isWeekend,
  }) {
    final (bgColor, textColor) = _statusColors(status, cs, isDark);

    final opacity = isWeekend ? 0.6 : 1.0;

    return GestureDetector(
      onTap: () => onDaySelected?.call(DateTime(year, month, day)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: bgColor.a * opacity),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          border: isToday
              ? Border.all(color: cs.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: tt.labelMedium?.copyWith(
              fontWeight: isToday ? AppTypography.wBold : AppTypography.wMedium,
              color: textColor.withValues(alpha: opacity),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Status → Colour Mapping ──────────────────────────────────────

  (Color, Color) _statusColors(String? status, ColorScheme cs, bool isDark) {
    return switch (status?.toLowerCase()) {
      'present' => (
          AppColors.successLight,
          isDark ? AppColors.success : AppColors.successDark,
        ),
      'absent' => (
          AppColors.errorLight,
          isDark ? AppColors.error : AppColors.errorDark,
        ),
      'late' => (
          AppColors.warningLight,
          isDark ? AppColors.warning : AppColors.warningDark,
        ),
      'excused' => (
          AppColors.infoLight,
          isDark ? AppColors.info : AppColors.infoDark,
        ),
      _ => (
          Colors.transparent,
          cs.onSurface.withValues(alpha: isDark ? 0.5 : 0.35),
        ),
    };
  }

  // ─── Legend ────────────────────────────────────────────────────────

  Widget _buildLegend(ColorScheme cs, TextTheme tt, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(AppColors.successLight, 'P', tt),
        const SizedBox(width: Spacings.xs),
        _legendDot(AppColors.errorLight, 'A', tt),
        const SizedBox(width: Spacings.xs),
        _legendDot(AppColors.warningLight, 'L', tt),
        const SizedBox(width: Spacings.xs),
        _legendDot(AppColors.infoLight, 'E', tt),
      ],
    );
  }

  Widget _legendDot(Color color, String label, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _monthLabel(int year, int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month]} $year';
  }
}
