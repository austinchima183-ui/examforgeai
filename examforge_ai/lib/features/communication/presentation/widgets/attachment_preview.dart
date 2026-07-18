import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/communication_entities.dart';

// ─── AttachmentPreview ─────────────────────────────────────────────────────────

/// File attachment preview widget showing a file icon (by type), file name,
/// file size, thumbnail for images, and a download indicator.
///
/// ```dart
/// AttachmentPreview(
///   attachment: msgAttachment,
///   onTap: () => downloadFile(attachment.fileUrl),
/// )
/// ```
class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.textColor,
    this.onTap,
  });

  /// The attachment entity to display.
  final MessageAttachmentEntity attachment;

  /// Optional text color override (useful inside message bubbles).
  final Color? textColor;

  /// Tap callback for opening/downloading the attachment.
  final VoidCallback? onTap;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.pdf => Icons.picture_as_pdf_rounded,
      AttachmentType.docx => Icons.description_rounded,
      AttachmentType.pptx => Icons.slideshow_rounded,
      AttachmentType.xlsx => Icons.table_chart_rounded,
      AttachmentType.image => Icons.image_outlined,
      AttachmentType.video => Icons.videocam_outlined,
      AttachmentType.audio => Icons.audiotrack_rounded,
      AttachmentType.other => Icons.insert_drive_file_outlined,
    };
  }

  Color _fileColor(AttachmentType type) {
    return switch (type) {
      AttachmentType.pdf => const Color(0xFFDC2626),
      AttachmentType.docx => const Color(0xFF2563EB),
      AttachmentType.pptx => const Color(0xFFEA580C),
      AttachmentType.xlsx => const Color(0xFF16A34A),
      AttachmentType.image => const Color(0xFF7C3AED),
      AttachmentType.video => const Color(0xFF0891B2),
      AttachmentType.audio => const Color(0xFFCA8A04),
      AttachmentType.other => const Color(0xFF6B7280),
    };
  }

  // ─── Image Thumbnail Builder ──────────────────────────────────────────

  Widget _buildImageThumbnail(BuildContext context) {
    if (attachment.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        child: Image.network(
          attachment.thumbnailUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFileIconPlaceholder(context),
        ),
      );
    }
    return _buildFileIconPlaceholder(context);
  }

  Widget _buildFileIconPlaceholder(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final color = _fileColor(attachment.fileType);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Center(
        child: Icon(
          _fileIcon(attachment.fileType),
          size: Spacings.mdIcon,
          color: color,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = textColor ?? cs.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacings.xs),
        padding: const EdgeInsets.all(Spacings.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or icon
            if (attachment.fileType == AttachmentType.image)
              _buildImageThumbnail(context)
            else
              _buildFileIconPlaceholder(context),
            const SizedBox(width: Spacings.md),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: tt.bodySmall?.copyWith(
                      color: color,
                      fontWeight: AppTypography.wMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        attachment.fileType.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 9,
                          fontWeight: AppTypography.wSemiBold,
                          letterSpacing: 0.5,
                          color: _fileColor(attachment.fileType),
                        ),
                      ),
                      if (attachment.fileSizeBytes != null) ...[
                        Text(
                          ' · ${_formatFileSize(attachment.fileSizeBytes)}',
                          style: tt.labelSmall?.copyWith(
                            color: color.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Download indicator
            Icon(
              Icons.download_rounded,
              size: Spacings.mdIcon,
              color: color.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
