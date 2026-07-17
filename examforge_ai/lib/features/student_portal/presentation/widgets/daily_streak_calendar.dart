import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/student_portal_entities.dart';

// ═══════════════════════════════════════════════════════════════════════
// DAILY STREAK CALENDAR
// ═══════════════════════════════════════════════════════════════════════

/// Calendar heatmap showing the last 30 days of study activity.
///
/// Displays a grid of colored squares: green for active days, gray for
/// inactive days. The current streak is highlighted. A month/year header
/// appears at the top.
///
/// ```dart
/// DailyStreakCalendar(activities: myActivities)
/// ```
class DailyStreakCalendar extends StatelessWidget {
  const DailyStreakCalendar({
    super.key,
    required this.activities,
  });

  /// List of daily activity records.
  final List<StudentDailyActivityEntity> activities;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 29));

    // Build a map of date → activity for quick lookup
    final activityMap = <String, StudentDailyActivityEntity>{};
    for (final a in activities) {
      final key = _dateKey(a.activityDate);
      activityMap[key] = a;
    }

    // Compute current streak (consecutive active days from today backwards)
    final streakDays = _computeCurrentStreak(activityMap, now);

    // Build 30-day grid
    final days = List.generate(30, (i) {
      final date = startDate.add(Duration(days: i));
      final key = _dateKey(date);
      final activity = activityMap[key];
      final isActive = activity?.isActiveDay ?? false;
      final isToday = _dateKey(date) == _dateKey(now);
      final isStreakDay = streakDays.contains(key);
      final studyMin = activity?.studyTimeMin ?? 0;

      return _DayInfo(
        date: date,
        isActive: isActive,
        isToday: isToday,
        isStreakDay: isStreakDay,
        studyMinutes: studyMin,
      );
    });

    // Week rows (7 columns)
    final weeks = <List<_DayInfo>>[];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
    }

    // Month labels
    final monthLabels = <String>{};
    for (final d in days) {
      final label = _monthYear(d.date);
      monthLabels.add(label);
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                monthLabels.join(' – '),
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              // Legend
              _buildLegend(context, tt, cs),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ── Day-of-week headers ────────────────────────────────────
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacings.xs),

          // ── Day Grid ───────────────────────────────────────────────
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.xs),
              child: Row(
                children: List.generate(7, (colIndex) {
                  if (colIndex < week.length) {
                    return Expanded(
                      child: _buildDayCell(context, week[colIndex], tt, cs),
                    );
                  }
                  return const Expanded(child: SizedBox.shrink());
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    _DayInfo day,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final isDark = context.isDarkMode;

    Color bgColor;
    Color? borderColor;

    if (day.isActive) {
      // Intensity based on study minutes
      if (day.studyMinutes >= 120) {
        bgColor = AppColors.success;
      } else if (day.studyMinutes >= 60) {
        bgColor = AppColors.success.withValues(alpha: 0.7);
      } else {
        bgColor = AppColors.success.withValues(alpha: 0.4);
      }
    } else {
      bgColor = isDark
          ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
          : cs.surfaceContainerHighest;
    }

    if (day.isToday) {
      borderColor = cs.primary;
    } else if (day.isStreakDay && day.isActive) {
      borderColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Tooltip(
        message: _dayTooltip(day),
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
          child: day.isToday
              ? Center(
                  child: Text(
                    '${day.date.day}',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: day.isActive ? Colors.white : cs.primary,
                      fontSize: 9,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, TextTheme tt, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendBox(cs.surfaceContainerHighest, 'None', tt),
        const SizedBox(width: Spacings.xs),
        _legendBox(AppColors.success.withValues(alpha: 0.4), 'Low', tt),
        const SizedBox(width: Spacings.xs),
        _legendBox(AppColors.success.withValues(alpha: 0.7), 'Mid', tt),
        const SizedBox(width: Spacings.xs),
        _legendBox(AppColors.success, 'High', tt),
      ],
    );
  }

  Widget _legendBox(Color color, String label, TextTheme tt) {
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
        const SizedBox(width: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }

  String _dayTooltip(_DayInfo day) {
    final dateStr = '${day.date.day}/${day.date.month}/${day.date.year}';
    if (day.isActive) {
      return '$dateStr – ${day.studyMinutes} min studied';
    }
    return '$dateStr – No activity';
  }

  // ─── Helpers ───────────────────────────────────────────────────────

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  String _monthYear(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.year}';
  }

  Set<String> _computeCurrentStreak(
    Map<String, StudentDailyActivityEntity> map,
    DateTime now,
  ) {
    final streak = <String>{};
    var checkDate = now;

    while (true) {
      final key = _dateKey(checkDate);
      final activity = map[key];
      if (activity?.isActiveDay == true) {
        streak.add(key);
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

class _DayInfo {
  const _DayInfo({
    required this.date,
    required this.isActive,
    required this.isToday,
    required this.isStreakDay,
    required this.studyMinutes,
  });

  final DateTime date;
  final bool isActive;
  final bool isToday;
  final bool isStreakDay;
  final int studyMinutes;
}
