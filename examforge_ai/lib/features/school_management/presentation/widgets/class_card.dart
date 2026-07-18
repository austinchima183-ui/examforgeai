import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.classEntity,
    required this.onTap,
  });

  final ClassEntity classEntity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillRatio = classEntity.capacity > 0 ? classEntity.studentCount / classEntity.capacity : 0.0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.class_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classEntity.name + (classEntity.section != null ? ' - ${classEntity.section}' : ''),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (classEntity.gradeLevel != null)
                Text('Grade: ${classEntity.gradeLevel}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              if (classEntity.teacherName != null)
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(child: Text(classEntity.teacherName!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${classEntity.studentCount}/${classEntity.capacity}', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillRatio.clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fillRatio > 0.9 ? Colors.red : fillRatio > 0.7 ? Colors.orange : theme.colorScheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
