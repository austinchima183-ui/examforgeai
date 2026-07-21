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
import '../providers/ai_assistant_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI ASSISTANT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Communication Assistant interface.
///
/// Features:
/// - Tool selector: Draft Announcement, Rewrite, Summarize, Translate,
///   Suggest Reply, Grammar, Tone
/// - Input area for text/topic
/// - Tone selector dropdown (Professional, Casual, Formal, Friendly)
/// - Language selector for translation
/// - Generate button
/// - Response display with copy button
/// - "Use this" button to apply AI-generated content
/// - History of recent AI requests
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _State();
}

class _State extends ConsumerState<AiAssistantPage> {
  // ─── State ──────────────────────────────────────────────────────────

  final _inputController = TextEditingController();
  String _selectedTool = 'draft_announcement';
  String _selectedTone = 'Professional';
  String _selectedLanguage = 'Spanish';

  static const _tools = [
    _Tool(key: 'draft_announcement', label: 'Draft Announcement', icon: Icons.campaign_outlined),
    _Tool(key: 'rewrite', label: 'Rewrite', icon: Icons.edit_outlined),
    _Tool(key: 'summarize', label: 'Summarize', icon: Icons.summarize_outlined),
    _Tool(key: 'translate', label: 'Translate', icon: Icons.translate_outlined),
    _Tool(key: 'suggest_reply', label: 'Suggest Reply', icon: Icons.reply_outlined),
    _Tool(key: 'grammar', label: 'Grammar', icon: Icons.spellcheck_outlined),
    _Tool(key: 'tone_adjust', label: 'Tone', icon: Icons.tune_outlined),
  ];

  static const _tones = ['Professional', 'Casual', 'Formal', 'Friendly'];
  static const _languages = ['Spanish', 'French', 'German', 'Portuguese', 'Arabic', 'Chinese', 'Japanese', 'Hindi'];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);

    return Scaffold(
      appBar: AppAppBar(title: 'AI Assistant'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Tool Selector ────────────────────────────────
                  _buildToolSelector(),
                  const SizedBox(height: Spacings.xl),

                  // ─── Input Area ───────────────────────────────────
                  _buildInputArea(),
                  const SizedBox(height: Spacings.lg),

                  // ─── Options Row ──────────────────────────────────
                  _buildOptionsRow(),
                  const SizedBox(height: Spacings.lg),

                  // ─── Generate Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.isLoading ? null : _generate,
                      icon: state.isLoading
                          ? const SizedBox(width: 20, height: 20, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small, color: Colors.white))
                          : const Icon(Icons.auto_awesome),
                      label: Text(state.isLoading ? 'Generating…' : 'Generate'),
                    ),
                  ),

                  // ─── Error ────────────────────────────────────────
                  if (state.error != null) ...[
                    const SizedBox(height: Spacings.md),
                    AppErrorState.genericError(message: state.error),
                  ],

                  // ─── Response ─────────────────────────────────────
                  if (state.response != null) ...[
                    const SizedBox(height: Spacings.xl),
                    _buildResponse(state.response!),
                  ],

                  // ─── History ──────────────────────────────────────
                  if (state.conversationHistory.isNotEmpty) ...[
                    const SizedBox(height: Spacings.xl),
                    _buildHistory(state),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOOL SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildToolSelector() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Tool', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: _tools.map((tool) {
            final isSelected = _selectedTool == tool.key;
            return ChoiceChip(
              avatar: Icon(tool.icon, size: Spacings.smIcon),
              label: Text(tool.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedTool = tool.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INPUT AREA
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildInputArea() {
    return TextField(
      controller: _inputController,
      decoration: InputDecoration(
        labelText: _inputLabel(),
        hintText: _inputHint(),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.newline,
    );
  }

  String _inputLabel() {
    switch (_selectedTool) {
      case 'draft_announcement':
        return 'Topic / Description';
      case 'rewrite':
      case 'grammar':
      case 'tone_adjust':
        return 'Text to process';
      case 'summarize':
        return 'Text to summarize';
      case 'translate':
        return 'Text to translate';
      case 'suggest_reply':
        return 'Message to reply to';
      default:
        return 'Input';
    }
  }

  String _inputHint() {
    switch (_selectedTool) {
      case 'draft_announcement':
        return 'Describe the announcement you want to create…';
      case 'rewrite':
        return 'Paste the text you want to rewrite…';
      case 'summarize':
        return 'Paste the text you want summarized…';
      case 'translate':
        return 'Paste the text you want translated…';
      case 'suggest_reply':
        return 'Paste the message you want to reply to…';
      case 'grammar':
        return 'Paste the text for grammar correction…';
      case 'tone_adjust':
        return 'Paste the text to adjust tone…';
      default:
        return 'Enter your text…';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OPTIONS ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Tone selector (for rewrite, tone_adjust, draft)
        if (['rewrite', 'tone_adjust', 'draft_announcement', 'suggest_reply'].contains(_selectedTool))
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTone,
              decoration: const InputDecoration(
                labelText: 'Tone',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _tones.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTone = v ?? 'Professional'),
            ),
          ),
        if (_selectedTool == 'translate') ...[
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Target Language',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v ?? 'Spanish'),
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESPONSE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResponse(AiCommunicationAssistantEntity response) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: Spacings.mdIcon, color: cs.primary),
            const SizedBox(width: Spacings.sm),
            Text('AI Response', style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
            const Spacer(),
            // Copy button
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: 'Copy',
              onPressed: () {
                // TODO: copy to clipboard
              },
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.1),
            borderRadius: Spacings.borderRadiusMd,
            border: Border.all(color: cs.primary.withOpacity(0.2)),
          ),
          child: SelectableText(
            response.content,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.6),
          ),
        ),
        if (response.suggestions.isNotEmpty) ...[
          const SizedBox(height: Spacings.md),
          Text('Suggestions', style: tt.labelLarge?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
          const SizedBox(height: Spacings.sm),
          ...response.suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: Spacings.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: tt.bodySmall?.copyWith(color: cs.primary)),
                Expanded(child: Text(s, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
              ],
            ),
          )),
        ],
        const SizedBox(height: Spacings.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () {/* TODO: apply AI content */},
            child: const Text('Use This'),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHistory(AiAssistantState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Requests', style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
        const SizedBox(height: Spacings.md),
        ...state.conversationHistory.reversed.take(5).map((entry) {
          final toolLabel = _tools.firstWhere((t) => t.key == entry.type, orElse: () => _tools.first).label;
          return Card(
            elevation: Spacings.elevationNone,
            color: cs.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: Spacings.sm),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
                        decoration: BoxDecoration(color: cs.primaryContainer.withOpacity(0.3), borderRadius: Spacings.borderRadiusSm),
                        child: Text(toolLabel, style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: AppTypography.wMedium)),
                      ),
                      const Spacer(),
                      Text(_formatTimeAgo(entry.timestamp), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(entry.input, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: Spacings.xs),
                  Text(entry.response, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERATE
  // ═══════════════════════════════════════════════════════════════════════

  void _generate() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter some text first.')));
      return;
    }

    final notifier = ref.read(aiAssistantProvider.notifier);

    switch (_selectedTool) {
      case 'draft_announcement':
        notifier.draftAnnouncement(AiDraftAnnouncementParams(topic: input, tone: _selectedTone.toLowerCase()));
      case 'rewrite':
        notifier.rewriteMessage(AiRewriteMessageParams(text: input, tone: _selectedTone.toLowerCase()));
      case 'summarize':
        notifier.summarizeConversation(input); // Using conversationId param as text placeholder
      case 'translate':
        notifier.translateMessage(AiTranslateMessageParams(text: input, targetLanguage: _selectedLanguage));
      case 'suggest_reply':
        notifier.suggestReply(AiSuggestReplyParams(messageId: input, tone: _selectedTone.toLowerCase()));
      case 'grammar':
        notifier.correctGrammar(AiCorrectGrammarParams(text: input));
      case 'tone_adjust':
        notifier.adjustTone(AiAdjustToneParams(text: input, targetTone: _selectedTone.toLowerCase()));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _Tool {
  const _Tool({required this.key, required this.label, required this.icon});
  final String key;
  final String label;
  final IconData icon;
}
