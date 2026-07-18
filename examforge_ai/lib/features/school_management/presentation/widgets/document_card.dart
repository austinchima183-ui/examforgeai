import 'package:flutter/material.dart';
import '../../domain/entities/school_management_entities.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDownload,
  });

  final DocumentEntity document;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  IconData _fileTypeIcon() {
    final mime = document.mimeType ?? '';
    if (mime.contains('pdf')) return Icons.picture_as_pdf;
    if (mime.contains('image')) return Icons.image;
    if (mime.contains('word') || mime.contains('document')) return Icons.description;
    if (mime.contains('sheet') || mime.contains('excel')) return Icons.table_chart;
    if (mime.contains('presentation')) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Icon(_fileTypeIcon(), color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(document.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Chip(
                          label: Text(document.isPublic ? 'Public' : 'Private', style: TextStyle(fontSize: 10, color: document.isPublic ? Colors.green : Colors.grey)),
                          avatar: Icon(document.isPublic ? Icons.public : Icons.lock, size: 12),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (document.category != null) ...[
                          Text(document.category!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(width: 8),
                        ],
                        Text(_formatSize(document.fileSize), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        const SizedBox(width: 8),
                        Text(_formatDate(document.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.download, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${document.downloadCount}', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: onDownload,
                tooltip: 'Download',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
