import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../providers/student_portal_providers.dart';

/// Document upload and chat page.
///
/// Features:
/// - Document list with upload FAB
/// - Upload dialog: File picker, progress indicator
/// - Document chat interface: Similar to AI Tutor but with document context
/// - Document info bar: File name, page count, word count
/// - Chat messages with page references
/// - Quick actions: Summarize, Generate Flashcards, Create Revision Questions
class DocumentChatPage extends ConsumerStatefulWidget {
  const DocumentChatPage({super.key});

  @override
  ConsumerState<DocumentChatPage> createState() =>
      _DocumentChatPageState();
}

class _DocumentChatPageState extends ConsumerState<DocumentChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentChatProvider.notifier).loadDocuments();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(documentChatProvider);

    if (docState.currentDocument != null) {
      return _buildChatView(context, docState);
    }

    return _buildDocumentList(context, docState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOCUMENT LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDocumentList(BuildContext context, DocumentChatState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Document Chat')),
      body: state.isLoading && state.documents.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.documents.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Documents',
                  message: state.error,
                  onRetry: () => ref
                      .read(documentChatProvider.notifier)
                      .loadDocuments(),
                )
              : state.documents.isEmpty
                  ? AppEmptyState(
                      icon: Icons.description_outlined,
                      title: 'No Documents',
                      subtitle:
                          'Upload a document to start chatting with AI about it.',
                      actionLabel: 'Upload Document',
                      onAction: () => _showUploadDialog(context),
                    )
                  : ListView.builder(
                      padding: Spacings.paddingScreen,
                      itemCount: state.documents.length,
                      itemBuilder: (context, index) {
                        final doc = state.documents[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: Spacings.md),
                          child: _DocumentCard(
                            document: doc,
                            onTap: () {
                              ref
                                  .read(documentChatProvider.notifier)
                                  .openDocument(doc.id);
                            },
                            onDelete: () {
                              ref
                                  .read(documentChatProvider.notifier)
                                  .deleteDocument(doc.id);
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAT VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChatView(BuildContext context, DocumentChatState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final doc = state.currentDocument!;

    return Column(
      children: [
        // Document info bar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    ref.read(documentChatProvider.notifier).clearError();
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (doc.pageCount != null)
                            Text(
                              '${doc.pageCount} pages',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          if (doc.pageCount != null && doc.wordCount != null)
                            Text(
                              ' · ',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          if (doc.wordCount != null)
                            Text(
                              '${doc.wordCount} words',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            ' · ',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          _buildStatusChip(context, doc.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick actions
        if (doc.status == DocumentChatStatus.ready)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    icon: Icons.summarize_outlined,
                    label: 'Summarize',
                    onTap: () => _sendQuickAction('Summarize this document'),
                  ),
                  const SizedBox(width: Spacings.sm),
                  _QuickActionButton(
                    icon: Icons.style_outlined,
                    label: 'Flashcards',
                    onTap: () => _sendQuickAction(
                        'Generate flashcards from this document',),
                  ),
                  const SizedBox(width: Spacings.sm),
                  _QuickActionButton(
                    icon: Icons.quiz_outlined,
                    label: 'Questions',
                    onTap: () => _sendQuickAction(
                        'Create revision questions from this document',),
                  ),
                ],
              ),
            ),
          ),

        // Messages
        Expanded(
          child: doc.status == DocumentChatStatus.processing
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLoadingSpinner(),
                      const SizedBox(height: Spacings.lg),
                      Text(
                        'Processing document...',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacings.md),
                      const AppLoadingBar(
                        value: null,
                      ),
                    ],
                  ),
                )
              : doc.status == DocumentChatStatus.failed
                  ? AppErrorState(
                      icon: Icons.error_outline_rounded,
                      title: 'Processing Failed',
                      message:
                          'This document could not be processed. Please try uploading it again.',
                      onRetry: () => ref
                          .read(documentChatProvider.notifier)
                          .deleteDocument(doc.id),
                    )
                  : state.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(Spacings.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: Spacings.xlIcon,
                                  color: cs.primary
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: Spacings.lg),
                                Text(
                                  'Ask questions about this document',
                                  style: tt.titleMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(Spacings.lg),
                          itemCount: state.messages.length +
                              (state.isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.messages.length) {
                              return _buildTypingIndicator(context);
                            }
                            final message = state.messages[index];
                            return _DocMessageBubble(message: message);
                          },
                        ),
        ),

        // Input area
        if (doc.status == DocumentChatStatus.ready)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about this document...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              Spacings.xlRadius,),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Spacings.lg,
                          vertical: Spacings.md,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: state.isSending
                          ? null
                          : (_) => _sendCurrentMessage(),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  IconButton.filled(
                    onPressed: state.isSending
                        ? null
                        : _sendCurrentMessage,
                    icon: state.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildStatusChip(BuildContext context, DocumentChatStatus status) {
    final tt = context.textTheme;
    final (color, label) = switch (status) {
      DocumentChatStatus.processing => (AppColors.warning, 'Processing'),
      DocumentChatStatus.ready => (AppColors.success, 'Ready'),
      DocumentChatStatus.failed => (AppColors.error, 'Failed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final cs = context.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacings.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
        ),
        child: AppLoadingDot(
          color: cs.onSurfaceVariant,
          size: 6,
          spacing: 4,
        ),
      ),
    );
  }

  void _sendCurrentMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(documentChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendQuickAction(String text) {
    _messageController.text = text;
    _sendCurrentMessage();
  }

  void _showUploadDialog(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Upload Document',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: Spacings.xlIcon,
                color: cs.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Spacings.lg),
              Text(
                'Supported formats: PDF, DOCX, TXT',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.xl),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // Simulate upload
                  ref.read(documentChatProvider.notifier).uploadDocument(
                        fileName: 'sample_document.pdf',
                        fileUrl: 'https://example.com/sample.pdf',
                        fileFormat: 'pdf',
                        fileSize: 1024000,
                      );
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Choose File'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  final DocumentChatEntity document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final (statusColor, statusLabel) = switch (document.status) {
      DocumentChatStatus.processing => (AppColors.warning, 'Processing'),
      DocumentChatStatus.ready => (AppColors.success, 'Ready'),
      DocumentChatStatus.failed => (AppColors.error, 'Failed'),
    };

    return AppCard(
      onTap: document.status == DocumentChatStatus.ready ? onTap : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
              ),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              _fileIcon(document.fileFormat),
              size: Spacings.lgIcon,
              color: statusColor,
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
                        ),
                        borderRadius:
                            BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        statusLabel,
                        style: tt.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    if (document.pageCount != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Text(
                        '${document.pageCount} pages',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String format) {
    return switch (format.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'docx' || 'doc' => Icons.description_outlined,
      'txt' => Icons.text_snippet_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

class _DocMessageBubble extends StatelessWidget {
  const _DocMessageBubble({required this.message});

  final DocumentChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isUser = message.role == TutorMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacings.xs),
        constraints: BoxConstraints(
          maxWidth: context.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Spacings.lgRadius),
            topRight: const Radius.circular(Spacings.lgRadius),
            bottomLeft:
                isUser ? const Radius.circular(Spacings.lgRadius) : Radius.zero,
            bottomRight:
                isUser ? Radius.zero : const Radius.circular(Spacings.lgRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.pageReference != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacings.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    'Page ${message.pageReference}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ),
            SelectableText(
              message.content,
              style: tt.bodyMedium?.copyWith(
                color: isUser ? cs.onPrimary : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return ActionChip(
      avatar: Icon(icon, size: 18, color: cs.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
