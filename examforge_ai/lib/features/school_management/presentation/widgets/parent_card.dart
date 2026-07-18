import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class ParentCard extends StatelessWidget {
  const ParentCard({
    super.key,
    required this.parent,
    required this.onTap,
  });

  final ParentProfileEntity parent;
  final VoidCallback onTap;

  bool get _isPrimaryContact => parent.children.any((c) => c.isPrimaryContact);

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
                backgroundColor: theme.colorScheme.primaryContainer,
                child: parent.avatarUrl != null
                    ? ClipOval(child: Image.network(parent.avatarUrl!, fit: BoxFit.cover, width: 48, height: 48))
                    : Icon(Icons.family_restroom, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(parent.fullName ?? 'Unknown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (_isPrimaryContact)
                          Chip(
                            avatar: const Icon(Icons.star, size: 12, color: Colors.amber),
                            label: const Text('Primary', style: TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (parent.occupation != null)
                      Text(parent.occupation!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    Row(
                      children: [
                        Icon(Icons.child_care, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${parent.children.length} ${parent.children.length == 1 ? 'child' : 'children'}', style: theme.textTheme.labelSmall),
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
