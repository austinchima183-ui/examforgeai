import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/communication_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// COMMUNICATION GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Communication Generator page where teachers fill in parameters and AI
/// generates a communication (letter, email, SMS, etc.).
///
/// Has two states: input form (no communication generated yet) and generated
/// result (editable communication with save, send, and copy options).
class CommunicationGeneratorPage extends ConsumerStatefulWidget {
  const CommunicationGeneratorPage({super.key});

  @override
  ConsumerState<CommunicationGeneratorPage> createState() =>
      _CommunicationGeneratorPageState();
}

class _CommunicationGeneratorPageState
    extends ConsumerState<CommunicationGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _classNameCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _customInstructionsCtrl = TextEditingController();

  CommunicationType _communicationType = CommunicationType.parentLetter;
  CommunicationTone _tone = CommunicationTone.formal;
  String _recipientType = 'Class';

  // ─── Edit Controllers (for generated result) ────────────────────────

  final _contentEditCtrl = TextEditingController();
  final _titleEditCtrl = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _classNameCtrl.dispose();
    _purposeCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _contentEditCtrl.dispose();
    _titleEditCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(communicationProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(communicationProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(communicationProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(communicationProvider.notifier).generateCommunication(
          communicationType: _communicationType,
          tone: _tone,
          recipientType: _recipientType,
          subject: _subjectCtrl.text.trim(),
          className: _classNameCtrl.text.trim(),
          purpose: _purposeCtrl.text.trim(),
          customInstructions: _customInstructionsCtrl.text.trim().isNotEmpty
              ? _customInstructionsCtrl.text.trim()
              : null,
        );

    _listenForMessages();

    // Initialize edit controllers from the generated communication
    final communication = ref.read(communicationProvider).currentCommunication;
    if (communication != null) {
      _contentEditCtrl.text = communication.content;
      _titleEditCtrl.text = communication.title;
    }
  }

  void _handleSaveDraft() {
    final communication = ref.read(communicationProvider).currentCommunication;
    if (communication == null) return;

    ref.read(communicationProvider.notifier).saveCommunication(
          _isEditing
              ? communication.copyWith(
                  title: _titleEditCtrl.text.trim().isNotEmpty
                      ? _titleEditCtrl.text.trim()
                      : communication.title,
                  content: _contentEditCtrl.text.trim(),
                )
              : communication,
          isDraft: true,
        );
    _listenForMessages();
  }

  Future<void> _handleSendNow() async {
    final communication = ref.read(communicationProvider).currentCommunication;
    if (communication == null) return;

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Send Communication',
      message:
          'Are you sure you want to send this ${_communicationType.label.toLowerCase()}? This action cannot be undone.',
      confirmText: 'Send',
      isDestructive: false,
    );

    if (confirmed == true) {
      ref.read(communicationProvider.notifier).sendCommunication(
            _isEditing
                ? communication.copyWith(
                    title: _titleEditCtrl.text.trim().isNotEmpty
                        ? _titleEditCtrl.text.trim()
                        : communication.title,
                    content: _contentEditCtrl.text.trim(),
                  )
                : communication,
          );
      _listenForMessages();
    }
  }

  void _handleCopyToClipboard() {
    final communication = ref.read(communicationProvider).currentCommunication;
    if (communication == null) return;

    final textToCopy = _isEditing
        ? _contentEditCtrl.text.trim()
        : communication.content;

    Clipboard.setData(ClipboardData(text: textToCopy));
    _showSnackBar('Copied to clipboard', isError: false);
  }

  void _handleGenerateAnother() {
    ref.read(communicationProvider.notifier).setCurrentCommunication(null);
    _contentEditCtrl.clear();
    _titleEditCtrl.clear();
    setState(() => _isEditing = false);
  }

  void _handleReset() {
    ref.read(communicationProvider.notifier).setCurrentCommunication(null);
    _contentEditCtrl.clear();
    _titleEditCtrl.clear();
    setState(() => _isEditing = false);
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communicationProvider);
    final communication = state.currentCommunication;

    return Scaffold(
      appBar: AppAppBar(
        title: communication != null
            ? 'Generated Communication'
            : 'AI Communication Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (communication != null)
            AppIconButton(
              icon: Icons.restart_alt_rounded,
              onPressed: _handleReset,
              tooltip: 'Start Over',
              variant: AppIconButtonVariant.standard,
            ),
        ],
      ),
      body: state.isGenerating
          ? _buildGeneratingState()
          : communication != null
              ? _buildGeneratedResult(communication)
              : _buildInputForm(),
    );
  }

  // ─── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create a Communication with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate a professional communication tailored to your needs.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Spacings.sectionGap,

            // Communication Type dropdown
            AppDropdownField<CommunicationType>(
              label: 'Communication Type',
              items: CommunicationType.values,
              selectedItem: _communicationType,
              onChanged: (v) {
                if (v != null) setState(() => _communicationType = v);
              },
              itemLabel: (t) => t.label,
              prefixIcon: Icons.mail_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Tone dropdown
            AppDropdownField<CommunicationTone>(
              label: 'Tone',
              items: CommunicationTone.values,
              selectedItem: _tone,
              onChanged: (v) {
                if (v != null) setState(() => _tone = v);
              },
              itemLabel: (t) => t.label,
              prefixIcon: Icons.record_voice_over_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Recipient Type dropdown
            AppDropdownField<String>(
              label: 'Recipient Type',
              items: const ['Class', 'Student', 'Parent', 'All', 'Custom'],
              selectedItem: _recipientType,
              onChanged: (v) {
                if (v != null) setState(() => _recipientType = v);
              },
              itemLabel: (r) => r,
              prefixIcon: Icons.group_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Subject / Class
            AppTextField(
              label: 'Subject / Class',
              hint: 'e.g. Mathematics SS2A',
              controller: _subjectCtrl,
              prefixIcon: Icons.book_outlined,
            ),
            Spacings.itemGap,

            // Purpose / Context
            AppTextField(
              label: 'Purpose / Context',
              hint: 'Describe the purpose of this communication...',
              controller: _purposeCtrl,
              prefixIcon: Icons.lightbulb_outline,
              maxLines: 4,
              minLines: 2,
              isRequired: true,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Purpose is required'
                  : null,
            ),
            Spacings.itemGap,

            // Custom Instructions
            AppTextField(
              label: 'Custom Instructions',
              hint: 'Any specific requirements or preferences for the communication...',
              controller: _customInstructionsCtrl,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Communication',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(communicationProvider).isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xl),
          ],
        ),
      ),
    );
  }

  // ─── Generating State ────────────────────────────────────────────────

  Widget _buildGeneratingState() {
    final cs = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            const SizedBox(height: Spacings.xl),
            Text(
              'Generating Your Communication...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting a ${_communicationType.label.toLowerCase()} with a ${_tone.label.toLowerCase()} tone. This may take a moment.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Generated Result ────────────────────────────────────────────────

  Widget _buildGeneratedResult(CommunicationEntity communication) {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (communication.isAiGenerated) _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Preview card with type badge and tone badge
          _buildPreviewCard(communication),
          Spacings.itemGap,

          // Title section
          _buildSectionCard(
            icon: Icons.title_rounded,
            title: 'Subject Line',
            child: _isEditing
                ? AppTextField(
                    controller: _titleEditCtrl,
                    label: 'Subject Line',
                    isRequired: true,
                  )
                : Text(
                    communication.title,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
          ),
          Spacings.itemGap,

          // Content section
          _buildSectionCard(
            icon: Icons.article_rounded,
            title: 'Content',
            child: _isEditing
                ? AppTextField(
                    controller: _contentEditCtrl,
                    label: 'Communication Content',
                    maxLines: 20,
                    minLines: 10,
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Spacings.lg),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: SelectableText(
                      communication.content,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        height: 1.7,
                      ),
                    ),
                  ),
          ),
          Spacings.sectionGap,

          // Action buttons
          _buildActionButtons(communication),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ─── Section Builders ────────────────────────────────────────────────

  Widget _buildAiBadge() {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.onTertiaryContainer),
          const SizedBox(width: Spacings.xs),
          Text(
            'AI Generated',
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          child,
        ],
      ),
    );
  }

  Widget _buildPreviewCard(CommunicationEntity communication) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _communicationTypeIcon(communication.communicationType),
                size: Spacings.lgIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      communication.communicationType.label,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'To: ${communication.recipientType}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            children: [
              // Type badge
              _buildMetaChip(
                icon: _communicationTypeIcon(communication.communicationType),
                label: communication.communicationType.label,
                color: cs.primary,
              ),
              // Tone badge
              _buildMetaChip(
                icon: Icons.record_voice_over_outlined,
                label: communication.tone.label,
                color: cs.secondary,
              ),
              // Recipient badge
              _buildMetaChip(
                icon: Icons.group_outlined,
                label: communication.recipientType,
                color: cs.tertiary,
              ),
              // Draft / Sent badge
              if (communication.isDraft)
                _buildMetaChip(
                  icon: Icons.edit_outlined,
                  label: 'Draft',
                  color: cs.tertiary,
                ),
              if (communication.isSent)
                _buildMetaChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Sent',
                  color: cs.primary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CommunicationEntity communication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isEditing) ...[
          AppButton(
            label: 'Save Changes',
            onPressed: () {
              setState(() => _isEditing = false);
              _handleSaveDraft();
            },
            variant: AppButtonVariant.elevated,
            icon: Icons.save_rounded,
            isLoading: ref.watch(communicationProvider).isUpdating,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),
          AppButton(
            label: 'Cancel Editing',
            onPressed: () => setState(() => _isEditing = false),
            variant: AppButtonVariant.outlined,
            fullWidth: true,
          ),
        ] else ...[
          // Edit button
          AppButton(
            label: 'Edit Communication',
            onPressed: () => setState(() => _isEditing = true),
            variant: AppButtonVariant.outlined,
            icon: Icons.edit_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),

          // Save as Draft + Copy to Clipboard
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Save as Draft',
                  onPressed: _handleSaveDraft,
                  variant: AppButtonVariant.tonal,
                  icon: Icons.bookmark_add_rounded,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppButton(
                  label: 'Copy',
                  onPressed: _handleCopyToClipboard,
                  variant: AppButtonVariant.outlined,
                  icon: Icons.copy_rounded,
                  fullWidth: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Send Now
          AppButton(
            label: 'Send Now',
            onPressed: _handleSendNow,
            variant: AppButtonVariant.elevated,
            icon: Icons.send_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),

          // Generate Another
          AppButton(
            label: 'Generate Another',
            onPressed: _handleGenerateAnother,
            variant: AppButtonVariant.text,
            icon: Icons.refresh_rounded,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  IconData _communicationTypeIcon(CommunicationType type) {
    switch (type) {
      case CommunicationType.parentLetter:
        return Icons.mail_rounded;
      case CommunicationType.studentFeedback:
        return Icons.feedback_rounded;
      case CommunicationType.email:
        return Icons.email_rounded;
      case CommunicationType.sms:
        return Icons.sms_rounded;
      case CommunicationType.announcement:
        return Icons.campaign_rounded;
      case CommunicationType.meetingInvitation:
        return Icons.event_rounded;
      case CommunicationType.permissionLetter:
        return Icons.description_rounded;
      case CommunicationType.certificate:
        return Icons.workspace_premium_rounded;
    }
  }
}
