import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/question_entities.dart';

// ─── QuestionContentRenderer ──────────────────────────────────────────────────

/// Renders question content with support for plain text, basic HTML stripping,
/// LaTeX placeholder rendering, and image/table/attachment display below the
/// main content.
///
/// For now, this widget renders plain text with basic HTML tag stripping and
/// shows attachments (images, audio, video) below the content area.
///
/// ```dart
/// QuestionContentRenderer(content: question.content, maxLines: 3)
/// QuestionContentRenderer(content: question.content, attachments: question.attachments)
/// ```
class QuestionContentRenderer extends StatelessWidget {
  const QuestionContentRenderer({
    super.key,
    required this.content,
    this.contentJson,
    this.attachments = const [],
    this.maxLines,
    this.isPreviewMode = false,
  });

  /// The raw text content (may contain basic HTML or LaTeX).
  final String content;

  /// Optional structured JSON content (reserved for future rich rendering).
  final Map<String, dynamic>? contentJson;

  /// Attachments (images, audio, video) to display below content.
  final List<QuestionAttachmentEntity> attachments;

  /// Maximum lines for preview mode. `null` means unlimited.
  final int? maxLines;

  /// Whether to show content in a full preview layout.
  final bool isPreviewMode;

  // ─── HTML Stripper ──────────────────────────────────────────────────

  /// Strips basic HTML tags from [html] and returns plain text.
  /// Handles: <b>, <i>, <em>, <strong>, <p>, <br>, <div>, <span>,
  /// <sub>, <sup>, <ul>, <ol>, <li>, <table>, <tr>, <td>, <th>, etc.
  String _stripHtml(String html) {
    var text = html;
    // Replace <br>, <br/>, <br /> with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    // Replace </p>, </div>, </li> with newlines
    text = text.replaceAll(RegExp(r'</(?:p|div|li|h[1-6])>'), '\n');
    // Replace </tr> with newline
    text = text.replaceAll(RegExp(r'</tr>'), '\n');
    // Replace </td>, </th> with tab separator
    text = text.replaceAll(RegExp(r'</(?:td|th)>'), '\t');
    // Replace list items with bullet
    text = text.replaceAll(RegExp(r'<li>'), '  • ');
    // Strip all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll('&nbsp;', ' ');
    // Collapse multiple newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  // ─── LaTeX Placeholder Detection ────────────────────────────────────

  /// Returns `true` if the content appears to contain LaTeX math.
  bool _containsLatex(String text) {
    return text.contains(r'\(') ||
        text.contains(r'\)') ||
        text.contains(r'\[') ||
        text.contains(r'\]') ||
        text.contains(r'$$') ||
        text.contains(RegExp(r'\\[a-zA-Z]+'));
  }

  /// Replaces LaTeX delimiters with visual placeholder tokens.
  String _replaceLatexWithPlaceholders(String text) {
    var result = text;
    // Display math: $$...$$ or \[...\]
    result = result.replaceAllMapped(
      RegExp(r'\$\$(.+?)\$\$', dotAll: true),
      (m) => '⟨math: ${m.group(1)!.trim()}⟩',
    );
    result = result.replaceAllMapped(
      RegExp(r'\\\[(.+?)\\\]', dotAll: true),
      (m) => '⟨math: ${m.group(1)!.trim()}⟩',
    );
    // Inline math: \(...\)
    result = result.replaceAllMapped(
      RegExp(r'\\\((.+?)\\\)', dotAll: true),
      (m) => '⟨${m.group(1)!.trim()}⟩',
    );
    return result;
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    var displayContent = _stripHtml(content);
    if (_containsLatex(displayContent)) {
      displayContent = _replaceLatexWithPlaceholders(displayContent);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Content Text ───────────────────────────────────────────
        SelectableText(
          displayContent,
          style: (isPreviewMode ? tt.bodyLarge : tt.bodyMedium)?.copyWith(
            color: cs.onSurface,
            height: 1.6,
          ),
          maxLines: maxLines,
          // ignore: avoid_redundant_argument_values
          minLines: null,
        ),

        if (maxLines != null &&
            displayContent.length > 150 &&
            maxLines! < 5) ...[
          const SizedBox(height: Spacings.xs),
          // No "Read more" in inline mode; handled by parent.
        ],

        // ── Attachments ────────────────────────────────────────────
        if (attachments.isNotEmpty) ...[
          SizedBox(height: isPreviewMode ? Spacings.lg : Spacings.md),
          _AttachmentList(
            attachments: attachments,
            isPreviewMode: isPreviewMode,
          ),
        ],
      ],
    );
  }
}

// ─── Attachment List ──────────────────────────────────────────────────────────

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({
    required this.attachments,
    required this.isPreviewMode,
  });

  final List<QuestionAttachmentEntity> attachments;
  final bool isPreviewMode;

  IconData _attachmentIcon(String contentType) {
    return switch (contentType) {
      'image' => Icons.image_outlined,
      'audio' => Icons.audiotrack_outlined,
      'video' => Icons.videocam_outlined,
      'document' => Icons.description_outlined,
      _ => Icons.attach_file_rounded,
    };
  }

  Color _attachmentColor(String contentType, ColorScheme cs) {
    return switch (contentType) {
      'image' => const Color(0xFF2563EB),
      'audio' => const Color(0xFFCA8A04),
      'video' => const Color(0xFFBE185D),
      'document' => const Color(0xFF059669),
      _ => cs.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Image attachments shown inline
    final imageAttachments =
        attachments.where((a) => a.contentType == 'image').toList();
    // Non-image attachments shown as file chips
    final otherAttachments =
        attachments.where((a) => a.contentType != 'image').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Images ─────────────────────────────────────────────────
        if (imageAttachments.isNotEmpty)
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: imageAttachments.map((attachment) {
              return _ImageAttachment(
                attachment: attachment,
                isPreviewMode: isPreviewMode,
              );
            }).toList(),
          ),

        // ── Other Files ────────────────────────────────────────────
        if (otherAttachments.isNotEmpty) ...[
          if (imageAttachments.isNotEmpty)
            const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: otherAttachments.map((attachment) {
              final color = _attachmentColor(attachment.contentType, cs);
              final icon = _attachmentIcon(attachment.contentType);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.08),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16.0, color: color),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      attachment.fileName ?? attachment.contentType,
                      style: tt.bodySmall?.copyWith(
                        color: color,
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Image Attachment ─────────────────────────────────────────────────────────

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({
    required this.attachment,
    required this.isPreviewMode,
  });

  final QuestionAttachmentEntity attachment;
  final bool isPreviewMode;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final double size = isPreviewMode ? 200.0 : 120.0;
    final borderRadius = isPreviewMode ? Spacings.mdRadius : Spacings.smRadius;

    // Since we can't load actual URLs in this context, we show a placeholder
    return Container(
      width: size,
      height: size * 0.75,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: isPreviewMode ? 40.0 : 28.0,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            attachment.altText ?? attachment.fileName ?? 'Image',
            style: context.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
