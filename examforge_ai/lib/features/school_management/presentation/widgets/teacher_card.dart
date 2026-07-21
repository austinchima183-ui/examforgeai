import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart';


class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onTap,
  });

  final TeacherProfileEntity teacher;
  final VoidCallback onTap;

  Color _employmentColor() {
    switch (teacher.employmentType) {
      case EmploymentType.fullTime:
        return Colors.green;
      case EmploymentType.partTime:
        return Colors.blue;
      case EmploymentType.contract:
        return Colors.orange;
      case EmploymentType.intern:
        return Colors.purple;
      case EmploymentType.volunteer:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: teacher.avatarUrl != null
                    ? ClipOval(child: Image.network(teacher.avatarUrl!, fit: BoxFit.cover, width: 48, height: 48))
                    : Icon(Icons.person, color: theme.colorScheme.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(teacher.fullName ?? 'Unknown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Chip(
                          label: Text(teacher.employmentType.label, style: TextStyle(fontSize: 10, color: _employmentColor())),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('ID: ${teacher.employeeId}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    if (teacher.departmentName != null)
                      Text(teacher.departmentName!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    if (teacher.qualification != null)
                      Text(teacher.qualification!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
