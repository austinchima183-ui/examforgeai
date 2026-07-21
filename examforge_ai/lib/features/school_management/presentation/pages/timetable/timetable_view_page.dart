import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/subject_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE VIEW PAGE (Read-Only)
// ═══════════════════════════════════════════════════════════════════════

/// Read-only view of a published timetable with color-coded subjects,
/// print, and share buttons.
class TimetableViewPage extends ConsumerStatefulWidget {
  const TimetableViewPage({super.key, required this.timetableId});

  final String timetableId;

  @override
  ConsumerState<TimetableViewPage> createState() => _TimetableViewPageState();
}

class _TimetableViewPageState extends ConsumerState<TimetableViewPage> {
  static const _days = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
  ];

  static const _periods = [1, 2, 3, 4, 5, 6, 7, 8];

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
    Future.microtask(() {
      ref.read(timetableDetailProvider.notifier).loadTimetable(widget.timetableId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(timetableDetailProvider);
    final subjectState = ref.watch(subjectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.timetable?.name ?? 'Timetable',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          // Print button
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: _printTimetable,
            tooltip: 'Print timetable',
          ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareTimetable,
            tooltip: 'Share timetable',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null
              ? AppErrorState.genericError(
                  message: state.error,
                  onRetry: () => ref
                      .read(timetableDetailProvider.notifier)
                      .loadTimetable(widget.timetableId),
                )
              : state.timetable == null
                  ? const SizedBox.shrink()
                  : _buildContent(context, state.timetable!, subjectState),
    );
  }

  // ─── Content Builder ─────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    TimetableEntity timetable,
    SubjectListState subjectState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      children: [
        // ─── Timetable Info Header ────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timetable.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.md,
                      vertical: Spacings.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Published',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Row(
                children: [
                  if (timetable.className != null) ...[
                    Icon(Icons.class_outlined,
                        size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      timetable.className!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                  ],
                  Icon(Icons.calendar_view_week_outlined,
                      size: Spacings.smIcon, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'Term: ${timetable.termId}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Icon(Icons.grid_view_outlined,
                      size: Spacings.smIcon, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    '${timetable.slots.length} slots',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── Color Legend ─────────────────────────────────────────────
        _buildColorLegend(context, timetable, subjectState),

        // ─── Weekly Grid ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.md),
                child: _buildWeeklyGrid(context, timetable.slots),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Color Legend ────────────────────────────────────────────────────

  Widget _buildColorLegend(
    BuildContext context,
    TimetableEntity timetable,
    SubjectListState subjectState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final usedSubjectIds = timetable.slots
        .where((s) => s.subjectId != null)
        .map((s) => s.subjectId!)
        .toSet();

    if (usedSubjectIds.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: usedSubjectIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: Spacings.md),
        itemBuilder: (context, index) {
          final subjectId = usedSubjectIds.elementAt(index);
          final subject = subjectState.subjects
              .where((s) => s.id == subjectId)
              .firstOrNull;
          final color = _getSubjectColor(subjectId);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Row(
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
                  subject?.name ?? subjectId,
                  style: tt.labelSmall?.copyWith(
                    color: isDark ? color.lighten() : color,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Weekly Grid ─────────────────────────────────────────────────────

  Widget _buildWeeklyGrid(
    BuildContext context,
    List<TimetableSlotEntity> slots,
  ) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return Table(
      border: TableBorder.all(
        color: cs.outlineVariant,
        width: 0.5,
      ),
      columnWidths: {
        0: const FixedColumnWidth(80),
        for (var i = 0; i < _days.length; i++)
          i + 1: const FixedColumnWidth(130),
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
        ..._periods.map((period) {
          return TableRow(
            children: [
              _buildPeriodCell(context, period),
              ..._days.map((day) {
                final slot = slots.where(
                  (s) =>
                      s.dayOfWeek == day && s.periodNumber == period,
                );
                if (slot.isEmpty) {
                  return _buildEmptyCell(context);
                }
                return _buildSlotCell(context, slot.first, isDark);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    final tt = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.md,
      ),
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
    final timeRanges = [
      '8:00-8:45', '8:45-9:30', '9:30-10:15', '10:15-11:00',
      '11:00-11:45', '11:45-12:30', '12:30-1:15', '1:15-2:00',
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
          const SizedBox(height: 2),
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

  Widget _buildEmptyCell(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacings.sm),
      color: context.colorScheme.surface,
    );
  }

  Widget _buildSlotCell(
    BuildContext context,
    TimetableSlotEntity slot,
    bool isDark,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Break slot
    if (slot.isBreak) {
      return Container(
        padding: const EdgeInsets.all(Spacings.sm),
        color: AppColors.warning.withOpacity(isDark ? 0.20 : 0.12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.free_breakfast_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(height: 2),
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
      );
    }

    // Subject slot with color coding
    final subjectColor = _getSubjectColor(slot.subjectId);

    return Container(
      padding: const EdgeInsets.all(Spacings.xs),
      decoration: BoxDecoration(
        color: subjectColor.withOpacity(isDark ? 0.20 : 0.10),
        border: Border(
          left: BorderSide(color: subjectColor, width: 3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.subjectName ?? '—',
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isDark ? subjectColor.lighten() : subjectColor.darken(),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (slot.teacherName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 10, color: cs.onSurfaceVariant),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    slot.teacherName!,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (slot.classroom != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.meeting_room_outlined,
                    size: 10, color: cs.outline),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    slot.classroom!,
                    style: tt.labelSmall?.copyWith(
                      color: cs.outline,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Print & Share ───────────────────────────────────────────────────

  void _printTimetable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareTimetable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Color darken([double amount = 0.2]) {
    return Color.fromARGB(
      alpha.toInt(),
      (red * (1 - amount)).clamp(0, 255).toInt(),
      (green * (1 - amount)).clamp(0, 255).toInt(),
      (blue * (1 - amount)).clamp(0, 255).toInt(),
    );
  }
}
