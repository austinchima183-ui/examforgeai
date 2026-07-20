import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import 'learning_objective_chip.dart';

/// Expandable tree node for curriculum hierarchy.
///
/// Features:
/// - Topic title with expand/collapse icon
/// - Depth indentation based on depth level
/// - Subtopics listed under expanded topic
/// - Learning objectives as chips under each node
/// - Add/edit/delete icon buttons
/// - Estimated duration display
class TopicTreeNode extends StatefulWidget {
  const TopicTreeNode({
    super.key,
    required this.topic,
    this.subtopics = const [],
    this.learningObjectives = const [],
    this.onEdit,
    this.onDelete,
    this.onAddSubtopic,
    this.onAddObjective,
    this.depth = 0,
  });

  /// The topic data to display.
  final Topic topic;

  /// Child subtopics.
  final List<Subtopic> subtopics;

  /// Learning objectives associated with this topic.
  final List<LearningObjective> learningObjectives;

  /// Callback when edit is tapped.
  final VoidCallback? onEdit;

  /// Callback when delete is tapped.
  final VoidCallback? onDelete;

  /// Callback when add subtopic is tapped.
  final VoidCallback? onAddSubtopic;

  /// Callback when add learning objective is tapped.
  final VoidCallback? onAddObjective;

  /// Nesting depth level (0 = root).
  final int depth;

  @override
  State<TopicTreeNode> createState() => _TopicTreeNodeState();
}

class _TopicTreeNodeState extends State<TopicTreeNode> {
  bool _isExpanded = false;

  // ─── Color based on depth ─────────────────────────────────────────────

  Color _depthColor() {
    final colors = [
      const Color(0xFF4F46E5), // indigo (root)
      const Color(0xFF7C3AED), // violet
      const Color(0xFF2563EB), // blue
      const Color(0xFF0891B2), // cyan
      const Color(0xFF059669), // emerald
    ];
    return colors[widget.depth % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final depthColor = _depthColor();
    final leftPadding = Spacings.lg * widget.depth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Topic row ─────────────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: Spacings.borderRadiusSm,
          child: Padding(
            padding: EdgeInsets.only(left: leftPadding),
            child: Row(
              children: [
                // Expand/collapse icon
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: Spacings.mdIcon,
                    color: depthColor,
                  ),
                ),
                const SizedBox(width: Spacings.sm),

                // Depth indicator line
                if (widget.depth > 0)
                  Container(
                    width: 2,
                    height: 20,
                    margin: const EdgeInsets.only(right: Spacings.sm),
                    decoration: BoxDecoration(
                      color: depthColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                // Topic title and duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.topic.title,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.topic.estimatedDurationMinutes != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.topic.estimatedDurationMinutes} min',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (widget.learningObjectives.isNotEmpty) ...[
                              const SizedBox(width: Spacings.sm),
                              Icon(
                                Icons.flag_outlined,
                                size: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.learningObjectives.length} objectives',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                // Action icon buttons
                _ActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit Topic',
                  color: cs.onSurfaceVariant,
                  onTap: widget.onEdit,
                ),
                _ActionButton(
                  icon: Icons.add_circle_outline_rounded,
                  tooltip: 'Add Subtopic',
                  color: depthColor,
                  onTap: widget.onAddSubtopic,
                ),
                _ActionButton(
                  icon: Icons.flag_outlined,
                  tooltip: 'Add Objective',
                  color: depthColor,
                  onTap: widget.onAddObjective,
                ),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Topic',
                  color: AppColors.error,
                  onTap: widget.onDelete,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded content ──────────────────────────────────────────
        if (_isExpanded) ...[
          // Learning objectives as chips
          if (widget.learningObjectives.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: leftPadding + Spacings.xl + Spacings.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 14,
                        color: depthColor,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Learning Objectives',
                        style: tt.labelMedium?.copyWith(
                          color: depthColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Wrap(
                    spacing: Spacings.xs,
                    runSpacing: Spacings.xs,
                    children: widget.learningObjectives
                        .map((obj) => LearningObjectiveChip(objective: obj))
                        .toList(),
                  ),
                ],
              ),
            ),

          // Subtopics
          ...widget.subtopics.map(
            (subtopic) => _SubtopicRow(
              subtopic: subtopic,
              leftPadding: leftPadding + Spacings.xl,
              depthColor: depthColor,
            ),
          ),

          const SizedBox(height: Spacings.xs),
        ],
      ],
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16, color: color),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        splashRadius: 16,
      ),
    );
  }
}

// ─── Subtopic Row ─────────────────────────────────────────────────────────────

class _SubtopicRow extends StatelessWidget {
  const _SubtopicRow({
    required this.subtopic,
    required this.leftPadding,
    required this.depthColor,
  });

  final Subtopic subtopic;
  final double leftPadding;
  final Color depthColor;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        children: [
          // Subtopic connector
          Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: Spacings.mdIcon,
            color: depthColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtopic.title,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                ),
                if (subtopic.estimatedDurationMinutes != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${subtopic.estimatedDurationMinutes} min',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
