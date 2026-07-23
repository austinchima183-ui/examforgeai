import 'package:flutter/material.dart';

import '../../domain/entities/school_management_entities.dart';


class AttendanceTable extends StatelessWidget {
  const AttendanceTable({
    super.key,
    required this.record,
  });

  final AttendanceRecordEntity record;

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
      case AttendanceStatus.sick:
        return Colors.purple;
    }
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.info;
      case AttendanceStatus.sick:
        return Icons.sick;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentCount = record.entries.where((e) => e.status.isPresent).length;
    final total = record.entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('${record.date.day}/${record.date.month}/${record.date.year}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Chip(
                avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                label: Text('$presentCount/$total present', style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Student entries table
        Expanded(
          child: ListView.separated(
            itemCount: record.entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final entry = record.entries[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: entry.userAvatarUrl != null
                      ? ClipOval(child: Image.network(entry.userAvatarUrl!, fit: BoxFit.cover, width: 36, height: 36))
                      : Text((entry.userName ?? '?')[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                title: Text(entry.userName ?? 'Unknown', style: theme.textTheme.bodyMedium),
                subtitle: entry.admissionNumber != null ? Text(entry.admissionNumber!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)) : null,
                trailing: Chip(
                  avatar: Icon(_statusIcon(entry.status), size: 14, color: _statusColor(entry.status)),
                  label: Text(entry.status.label, style: TextStyle(fontSize: 10, color: _statusColor(entry.status))),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
