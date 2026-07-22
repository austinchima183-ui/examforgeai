import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/get_knowledge_documents_usecase.dart';
import '../providers/knowledge_assistant_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// KNOWLEDGE ASSISTANT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI School Knowledge Assistant interface.
///
/// Features:
/// - Chat-like interface for Q&A
/// - User asks questions about school policies, calendar, etc.
/// - AI responds with grounded answers from school documents
/// - Source citations shown (document title, relevance score)
/// - "Not found in school records" fallback message
/// - Suggested questions chips
/// - Admin: manage knowledge documents section (upload, list, delete)
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class KnowledgeAssistantPage extends ConsumerStatefulWidget {
  const KnowledgeAssistantPage({super.key});

  @override
  ConsumerState<KnowledgeAssistantPage> createState() => _State();
}

class _State extends ConsumerState<KnowledgeAssistantPage> {
  // ─── State ──────────────────────────────────────────────────────────

  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showAdminPanel = false;

  static const _suggestedQuestions = [
    'What is the school uniform policy?',
    'When is the next parent-teacher conference?',
    'What are the school hours?',
    'How do I apply for leave?',
    'What is the grading system?',
    'What are the exam rules?',
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(knowledgeAssistantProvider.notifier).loadDocuments(
        const GetKnowledgeDocumentsParams(page: 1, perPage: 50),
      );
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(knowledgeAssistantProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'School Knowledge Assistant',
        actions: [
          IconButton(
            icon: Icon(_showAdminPanel ? Icons.chat_outlined : Icons.admin_panel_settings_outlined),
            onPressed: () => setState(() => _showAdminPanel = !_showAdminPanel),
            tooltip: _showAdminPanel ? 'Chat Mode' : 'Admin Mode',
          ),
        ],
      ),
      body: _showAdminPanel ? _buildAdminPanel(state) : _buildChatInterface(state),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHAT INTERFACE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChatInterface(KnowledgeAssistantState state) {
    return Column(
      children: [
        // ─── Messages Area ────────────────────────────────────────
        Expanded(
          child: state.searchHistory.isEmpty && state.response == null
              ? _buildWelcome()
              : _buildChatMessages(state),
        ),

        // ─── Input Area ──────────────────────────────────────────
        _buildInputArea(state),
      ],
    );
  }

  // ─── Welcome / Suggested Questions ──────────────────────────────────

  Widget _buildWelcome() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: Spacings.xlIcon, color: cs.primary.withOpacity(0.5)),
            const SizedBox(height: Spacings.lg),
            Text('School Knowledge Assistant', style: tt.headlineSmall?.copyWith(fontWeight: AppTypography.wBold, color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Text('Ask questions about school policies, calendar, rules, and more.', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: Spacings.xl),
            Text('Try asking:', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.md),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              alignment: WrapAlignment.center,
              children: _suggestedQuestions.map((q) => ActionChip(
                label: Text(q, style: tt.labelSmall),
                onPressed: () {
                  _questionController.text = q;
                  _askQuestion();
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Chat Messages ─────────────────────────────────────────────────

  Widget _buildChatMessages(KnowledgeAssistantState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.lg),
      itemCount: state.searchHistory.length + (state.response != null && state.isLoading == false ? 1 : 0),
      itemBuilder: (_, index) {
        if (index < state.searchHistory.length) {
          final entry = state.searchHistory[index];
          return _buildExchange(query: entry.query, response: entry.response, responseEntity: null);
        }
        // Current response
        return _buildCurrentResponse(state);
      },
    );
  }

  Widget _buildExchange({required String query, required String response, required AiSchoolKnowledgeResponseEntity? responseEntity}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── User Question ────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.md),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(Spacings.mdRadius),
              topRight: const Radius.circular(Spacings.mdRadius),
              bottomLeft: const Radius.circular(Spacings.mdRadius),
              bottomRight: Radius.circular(Spacings.xs),
            )),
            child: Text(query, style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
          ),
        ),
        const SizedBox(height: Spacings.md),

        // ─── AI Response ──────────────────────────────────────
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(Spacings.mdRadius),
              topRight: const Radius.circular(Spacings.mdRadius),
              bottomRight: const Radius.circular(Spacings.mdRadius),
              bottomLeft: Radius.circular(Spacings.xs),
            )),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.primary),
                    const SizedBox(width: Spacings.xs),
                    Text('AI Assistant', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wSemiBold)),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                SelectableText(response, style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacings.lg),
      ],
    );
  }

  Widget _buildCurrentResponse(KnowledgeAssistantState state) {
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacings.md),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoadingDot(),
              const SizedBox(width: Spacings.md),
              Text('Searching school records…', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    if (state.response == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resp = state.response!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: Spacings.borderRadiusMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Response header
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.primary),
                    const SizedBox(width: Spacings.xs),
                    Text('AI Assistant', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wSemiBold)),
                    const Spacer(),
                    // Grounded indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: resp.isGrounded ? AppColors.successOf(cs.brightness).withOpacity(0.12) : AppColors.warningOf(cs.brightness).withOpacity(0.12),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(
                        resp.isGrounded ? 'Verified' : 'Not Found in Records',
                        style: tt.labelSmall?.copyWith(
                          color: resp.isGrounded ? AppColors.successOf(cs.brightness) : AppColors.warningOf(cs.brightness),
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),

                // Response text
                if (!resp.isGrounded)
                  Text('⚠️ This information was not found in school records. The answer may not be accurate.', style: tt.bodySmall?.copyWith(color: AppColors.warningOf(cs.brightness), fontStyle: FontStyle.italic)),
                if (!resp.isGrounded) const SizedBox(height: Spacings.sm),
                SelectableText(resp.answer, style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5)),

                // Source citations
                if (resp.sources.isNotEmpty) ...[
                  const SizedBox(height: Spacings.md),
                  Text('Sources', style: tt.labelMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
                  const SizedBox(height: Spacings.sm),
                  ...resp.sources.map((src) => Container(
                    margin: const EdgeInsets.only(bottom: Spacings.xs),
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.5), borderRadius: Spacings.borderRadiusSm),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, size: Spacings.smIcon, color: cs.primary),
                        const SizedBox(width: Spacings.sm),
                        Expanded(child: Text(src.title, style: tt.labelSmall?.copyWith(color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: Spacings.sm),
                        Text('${(src.relevance * 100).toInt()}%', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wSemiBold)),
                      ],
                    ),
                  )),
                ],

                // Confidence
                const SizedBox(height: Spacings.sm),
                Text('Confidence: ${(resp.confidence * 100).toInt()}%', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Input Area ────────────────────────────────────────────────────

  Widget _buildInputArea(KnowledgeAssistantState state) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.md),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Ask about school policies, rules…',
                  border: OutlineInputBorder(borderRadius: Spacings.borderRadiusXl, borderSide: BorderSide.none),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _askQuestion(),
              ),
            ),
            const SizedBox(width: Spacings.sm),
            IconButton(
              icon: state.isLoading
                  ? const SizedBox(width: 24, height: 24, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small))
                  : const Icon(Icons.send_rounded),
              onPressed: state.isLoading ? null : _askQuestion,
              color: cs.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ADMIN PANEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAdminPanel(KnowledgeAssistantState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        // ─── Upload Section ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage Knowledge Documents', style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
              const SizedBox(height: Spacings.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {/* TODO: file picker + upload */},
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload Document'),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ─── Documents List ─────────────────────────────────────
        Expanded(
          child: state.isLoading && state.documents.isEmpty
              ? const Center(child: AppLoadingSpinner())
              : state.documents.isEmpty
                  ? AppEmptyState.noData(title: 'No Documents', subtitle: 'Upload documents to build the knowledge base.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(Spacings.lg),
                      itemCount: state.documents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
                      itemBuilder: (_, i) => _buildDocumentCard(state.documents[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(SchoolKnowledgeDocumentEntity doc) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final statusColor = doc.status == 'processed'
        ? AppColors.successOf(cs.brightness)
        : doc.status == 'pending'
            ? AppColors.warningOf(cs.brightness)
            : AppColors.errorOf(cs.brightness);

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: cs.primary, size: Spacings.lgIcon),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title, style: tt.titleSmall?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Spacings.xs),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: Spacings.borderRadiusSm),
                        child: Text(doc.status, style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: AppTypography.wMedium)),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Text('${doc.chunkCount} chunks', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.errorOf(cs.brightness)),
              onPressed: () => _confirmDelete(doc),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void _askQuestion() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    ref.read(knowledgeAssistantProvider.notifier).askQuestion(question);
    _questionController.clear();

    // Scroll to bottom after message
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

  void _confirmDelete(SchoolKnowledgeDocumentEntity doc) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(knowledgeAssistantProvider.notifier).deleteDocument(doc.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorOf(cs.brightness)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
