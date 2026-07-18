import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  final SubjectEntity subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Icon(Icons.menu_book_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(subject.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Code: ${subject.code}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (subject.category != null)
                    Chip(
                      label: Text(subject.category!, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  Chip(
                    label: Text(subject.isCompulsory ? 'Compulsory' : 'Optional', style: TextStyle(fontSize: 10, color: subject.isCompulsory ? Colors.blue : Colors.grey)),
                    avatar: Icon(subject.isCompulsory ? Icons.lock : Icons.lock_open, size: 12),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  if (subject.isElective)
                    Chip(
                      label: const Text('Elective', style: TextStyle(fontSize: 10, color: Colors.purple)),
                      avatar: const Icon(Icons.check_circle_outline, size: 12, color: Colors.purple),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
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
