import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class SchoolCard extends StatelessWidget {
  const SchoolCard({
    super.key,
    required this.school,
    required this.onTap,
  });

  final SchoolEntity school;
  final VoidCallback onTap;

  Color _subscriptionColor() {
    switch (school.subscriptionStatus) {
      case 'premium':
        return Colors.amber;
      case 'basic':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _subscriptionLabel() {
    switch (school.subscriptionStatus) {
      case 'premium':
        return 'Premium';
      case 'basic':
        return 'Basic';
      default:
        return 'Free';
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
              // Logo placeholder
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: school.logoUrl != null
                    ? ClipOval(child: Image.network(school.logoUrl!, fit: BoxFit.cover, width: 56, height: 56))
                    : Icon(Icons.school, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(school.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Chip(
                          label: Text(_subscriptionLabel(), style: const TextStyle(fontSize: 10)),
                          avatar: Icon(Icons.workspace_premium, size: 12, color: _subscriptionColor()),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Code: ${school.code}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    if (school.city != null || school.state != null)
                      Text([school.city, school.state].whereType<String>().join(', '), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${school.maxStudents} students', style: theme.textTheme.labelSmall),
                        const SizedBox(width: 12),
                        Icon(Icons.person_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${school.maxTeachers} teachers', style: theme.textTheme.labelSmall),
                      ],
                    ),
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
