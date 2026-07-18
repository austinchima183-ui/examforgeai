import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/workspace_expansion_entities.dart';

/// A reusable widget for displaying and editing a rubric criteria×levels table.
///
/// Shows a [DataTable] with columns for criterion name, weight, the four
/// proficiency levels (Beginning, Developing, Proficient, Exemplary),
/// and an optional actions column. When [isEditable] is `true`, text
/// fields become editable and an "Add Criterion" button appears.
class RubricTable extends StatefulWidget {
  /// The list of rubric criteria to display.
  final List<RubricCriterionEntity> criteria;

  /// Callback invoked when any criterion is modified, added, or removed.
  final ValueChanged<List<RubricCriterionEntity>> onCriteriaChanged;

  /// Whether the table fields are editable.
  final bool isEditable;

  const RubricTable({
    super.key,
    required this.criteria,
    required this.onCriteriaChanged,
    this.isEditable = false,
  });

  @override
  State<RubricTable> createState() => _RubricTableState();
}

class _RubricTableState extends State<RubricTable> {
  late List<RubricCriterionEntity> _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = List.from(widget.criteria);
  }

  @override
  void didUpdateWidget(covariant RubricTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.criteria != widget.criteria) {
      _criteria = List.from(widget.criteria);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    if (_criteria.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Data Table ────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 120,
            columnSpacing: Spacings.lg,
            horizontalMargin: Spacings.md,
            columns: [
              DataColumn(
                label: Text(
                  'Criterion',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Weight',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                numeric: true,
              ),
              ...RubricCriterionLevel.values.map(
                (level) => DataColumn(
                  label: Text(
                    level.label,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (widget.isEditable)
                DataColumn(
                  label: Text(
                    'Actions',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            rows: _criteria.asMap().entries.map((entry) {
              final index = entry.key;
              final criterion = entry.value;
              return _buildCriterionRow(context, index, criterion);
            }).toList(),
          ),
        ),

        // ── Total Points ──────────────────────────────────────────────
        const SizedBox(height: Spacings.md),
        _buildTotalPoints(context),

        // ── Add Criterion Button ──────────────────────────────────────
        if (widget.isEditable) ...[
          const SizedBox(height: Spacings.md),
          _buildAddButton(context),
        ],
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: Spacings.xlIcon,
              color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Spacings.md),
            Text(
              'No criteria defined yet',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.isEditable) ...[
              const SizedBox(height: Spacings.lg),
              _buildAddButton(context),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Criterion Row ───────────────────────────────────────────────────

  DataRow _buildCriterionRow(
    BuildContext context,
    int index,
    RubricCriterionEntity criterion,
  ) {
    final levelsMap = <RubricCriterionLevel, RubricLevelEntity>{};
    for (final level in criterion.levels) {
      levelsMap[level.level] = level;
    }

    return DataRow(
      cells: [
        // Criterion name
        DataCell(
          widget.isEditable
              ? _EditableText(
                  initialValue: criterion.criterion,
                  hintText: 'Criterion name',
                  onChanged: (value) => _updateCriterion(
                    index,
                    criterion.copyWith(criterion: value),
                  ),
                )
              : Text(
                  criterion.criterion,
                  style: context.textTheme.bodyMedium,
                ),
        ),

        // Weight
        DataCell(
          widget.isEditable
              ? _EditableText(
                  initialValue: criterion.weight.toString(),
                  hintText: '0.0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value) ?? criterion.weight;
                    _updateCriterion(
                      index,
                      criterion.copyWith(weight: weight),
                    );
                  },
                )
              : Text(
                  criterion.weight.toStringAsFixed(1),
                  style: context.textTheme.bodyMedium,
                ),
        ),

        // Level cells
        ...RubricCriterionLevel.values.map((level) {
          final levelEntity = levelsMap[level];
          return DataCell(
            widget.isEditable
                ? _LevelCellEditor(
                    description: levelEntity?.description ?? '',
                    score: levelEntity?.score ?? 0.0,
                    onDescriptionChanged: (desc) =>
                        _updateLevel(index, level, desc, null),
                    onScoreChanged: (score) =>
                        _updateLevel(index, level, null, score),
                  )
                : _LevelCellReadonly(
                    description: levelEntity?.description ?? '—',
                    score: levelEntity?.score ?? 0.0,
                  ),
          );
        }),

        // Actions
        if (widget.isEditable)
          DataCell(
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: Spacings.mdIcon - 4,
                color: AppColors.error,
              ),
              tooltip: 'Delete criterion',
              onPressed: () => _deleteCriterion(index),
            ),
          ),
      ],
    );
  }

  // ─── Total Points ────────────────────────────────────────────────────

  Widget _buildTotalPoints(BuildContext context) {
    final total = _criteria.fold<double>(
      0.0,
      (sum, c) {
        final maxScore = c.levels.fold<double>(
          0.0,
          (levelSum, level) => level.score > levelSum ? level.score : levelSum,
        );
        return sum + (maxScore * c.weight);
      },
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Total Points: ',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            total.toStringAsFixed(1),
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add Criterion Button ────────────────────────────────────────────

  Widget _buildAddButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _addCriterion,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Criterion'),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colorScheme.primary,
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
      ),
    );
  }

  // ─── Mutations ───────────────────────────────────────────────────────

  void _updateCriterion(int index, RubricCriterionEntity updated) {
    setState(() {
      _criteria[index] = updated;
    });
    widget.onCriteriaChanged(List.from(_criteria));
  }

  void _updateLevel(
    int criterionIndex,
    RubricCriterionLevel levelKey,
    String? description,
    double? score,
  ) {
    final criterion = _criteria[criterionIndex];
    final levels = List<RubricLevelEntity>.from(criterion.levels);

    final existingIndex = levels.indexWhere((l) => l.level == levelKey);
    if (existingIndex >= 0) {
      final existing = levels[existingIndex];
      levels[existingIndex] = existing.copyWith(
        description: description ?? existing.description,
        score: score ?? existing.score,
      );
    } else {
      levels.add(RubricLevelEntity(
        level: levelKey,
        description: description ?? '',
        score: score ?? 0.0,
      ));
    }

    _updateCriterion(criterionIndex, criterion.copyWith(levels: levels));
  }

  void _addCriterion() {
    setState(() {
      _criteria.add(const RubricCriterionEntity(
        criterion: '',
        weight: 1.0,
        levels: [
          RubricLevelEntity(
            level: RubricCriterionLevel.beginning,
            description: '',
            score: 0.0,
          ),
          RubricLevelEntity(
            level: RubricCriterionLevel.developing,
            description: '',
            score: 1.0,
          ),
          RubricLevelEntity(
            level: RubricCriterionLevel.proficient,
            description: '',
            score: 2.0,
          ),
          RubricLevelEntity(
            level: RubricCriterionLevel.exemplary,
            description: '',
            score: 3.0,
          ),
        ],
      ));
    });
    widget.onCriteriaChanged(List.from(_criteria));
  }

  void _deleteCriterion(int index) {
    setState(() {
      _criteria.removeAt(index);
    });
    widget.onCriteriaChanged(List.from(_criteria));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Editable Text Field
// ═══════════════════════════════════════════════════════════════════════

class _EditableText extends StatelessWidget {
  final String initialValue;
  final String hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _EditableText({
    required this.initialValue,
    required this.hintText,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: context.textTheme.bodySmall,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusSm,
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusSm,
          borderSide: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Spacings.borderRadiusSm,
          borderSide: BorderSide(
            color: context.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Level Cell – Editable
// ═══════════════════════════════════════════════════════════════════════

class _LevelCellEditor extends StatelessWidget {
  final String description;
  final double score;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<double> onScoreChanged;

  const _LevelCellEditor({
    required this.description,
    required this.score,
    required this.onDescriptionChanged,
    required this.onScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: TextEditingController(text: description),
            onChanged: onDescriptionChanged,
            style: context.textTheme.bodySmall,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Description',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              border: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusSm,
                borderSide: BorderSide(
                  color:
                      context.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusSm,
                borderSide: BorderSide(
                  color:
                      context.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusSm,
                borderSide: BorderSide(color: context.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: Spacings.xs),
          SizedBox(
            width: 60,
            child: TextField(
              controller: TextEditingController(text: score.toStringAsFixed(1)),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) onScoreChanged(parsed);
              },
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacings.xs,
                  vertical: Spacings.xs,
                ),
                border: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusSm,
                  borderSide: BorderSide(
                    color: context.colorScheme.outlineVariant
                        .withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusSm,
                  borderSide: BorderSide(
                    color: context.colorScheme.outlineVariant
                        .withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusSm,
                  borderSide: BorderSide(color: context.colorScheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Level Cell – Read-only
// ═══════════════════════════════════════════════════════════════════════

class _LevelCellReadonly extends StatelessWidget {
  final String description;
  final double score;

  const _LevelCellReadonly({
    required this.description,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            description,
            style: context.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            '${score.toStringAsFixed(1)} pts',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
