import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.slots,
    this.isReadOnly = true,
    this.onSlotTap,
  });

  final List<TimetableSlotEntity> slots;
  final bool isReadOnly;
  final ValueChanged<TimetableSlotEntity>? onSlotTap;

  static const _days = [DayOfWeek.monday, DayOfWeek.tuesday, DayOfWeek.wednesday, DayOfWeek.thursday, DayOfWeek.friday];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  Color _subjectColor(int index) {
    const colors = [0xFF4F46E5, 0xFF0EA5E9, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444, 0xFF8B5CF6, 0xFFEC4899, 0xFF14B8A6];
    return Color(colors[index % colors.length]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxPeriod = slots.isEmpty ? 0 : slots.map((s) => s.periodNumber).reduce((a, b) => a > b ? a : b);
    final periodCount = List.generate(maxPeriod, (i) => i + 1);
    final subjectColorMap = <String, int>{};
    var colorIdx = 0;
    for (final s in slots) {
      if (s.subjectId != null && !subjectColorMap.containsKey(s.subjectId)) {
        subjectColorMap[s.subjectId!] = colorIdx++;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              SizedBox(width: 56, child: Center(child: Text('Period', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)))),
              ..._dayLabels.map((d) => SizedBox(width: 120, child: Center(child: Text(d, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold))))),
            ],
          ),
          const Divider(height: 1),
          // Period rows
          ...periodCount.map((period) {
            return Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 56, child: Center(child: Text('P$period', style: theme.textTheme.labelSmall))),
                    ..._days.map((day) {
                      final slot = slots.where((s) => s.dayOfWeek == day && s.periodNumber == period).firstOrNull;
                      return _buildCell(context, slot, subjectColorMap);
                    }),
                  ],
                ),
                const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, TimetableSlotEntity? slot, Map<String, int> colorMap) {
    final theme = Theme.of(context);
    if (slot == null) {
      return GestureDetector(
        onTap: isReadOnly ? null : () {},
        child: SizedBox(width: 120, height: 48, child: Container(margin: const EdgeInsets.all(2), decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant, style: BorderStyle.solid), borderRadius: BorderRadius.circular(6)))),
      );
    }
    if (slot.isBreak) {
      return SizedBox(
        width: 120,
        height: 48,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: Text(slot.breakLabel ?? 'Break', style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic)),
        ),
      );
    }
    final color = slot.subjectId != null ? _subjectColor(colorMap[slot.subjectId] ?? 0) : theme.colorScheme.primary;
    return GestureDetector(
      onTap: () => onSlotTap?.call(slot),
      child: SizedBox(
        width: 120,
        height: 48,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4))),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slot.subjectName ?? '', style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (slot.classroom != null) Text(slot.classroom!, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
