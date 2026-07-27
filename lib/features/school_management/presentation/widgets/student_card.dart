import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  final StudentProfileEntity student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = student.isActive && !student.isGraduated;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar placeholder
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: student.avatarUrl != null
                    ? ClipOval(child: Image.network(student.avatarUrl!, fit: BoxFit.cover, width: 48, height: 48))
                    : Text(
                        (student.fullName ?? '?').substring(0, 1).toUpperCase(),
                        style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName ?? 'Unknown',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Chip(
                          label: Text(
                            student.isGraduated ? 'Graduated' : (isActive ? 'Active' : 'Inactive'),
                            style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.grey),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Adm: ${student.admissionNumber}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    if (student.currentClassName != null)
                      Text(student.currentClassName!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
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
