import 'package:flutter/material.dart';
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
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../providers/presentation_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// PRESENTATION GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Presentation Generator page where teachers fill in parameters and AI
/// generates a complete presentation with slides.
///
/// Has two states: input form (no presentation generated yet) and generated
/// result (editable presentation with slide cards, export, and save options).
class PresentationGeneratorPage extends ConsumerStatefulWidget {
  const PresentationGeneratorPage({super.key});

  @override
  ConsumerState<PresentationGeneratorPage> createState() =>
      _PresentationGeneratorPageState();
}

class _PresentationGeneratorPageState
    extends ConsumerState<PresentationGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _classNameCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _customInstructionsCtrl = TextEditingController();

  PresentationType _presentationType = PresentationType.teachingSlides;
  CurriculumType _curriculum = CurriculumType.nigerian;
  StudentLevel _difficulty = StudentLevel.intermediate;
  double _slideCount = 10;

  // ─── Edit Controllers (for generated result) ────────────────────────

  final _titleEditCtrl = TextEditingController();
  final List<TextEditingController> _slideTitleControllers = [];
  final List<TextEditingController> _slideBodyControllers = [];
  final List<TextEditingController> _slideNotesControllers = [];
  bool _isEditing = false;
  String _exportFormat = 'PDF';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _classNameCtrl.dispose();
    _topicCtrl.dispose();
    _customInstructionsCtrl.dispose();
    _titleEditCtrl.dispose();
    for (final c in _slideTitleControllers) {
      c.dispose();
    }
    for (final c in _slideBodyControllers) {
      c.dispose();
    }
    for (final c in _slideNotesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(presentationProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(presentationProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(presentationProvider.notifier).clearError();
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

    await ref.read(presentationProvider.notifier).generatePresentation(
          subject: _subjectCtrl.text.trim(),
          className: _classNameCtrl.text.trim(),
          topic: _topicCtrl.text.trim(),
          presentationType: _presentationType,
          curriculum: _curriculum,
          difficulty: _difficulty,
          slideCount: _slideCount.round(),
          customInstructions: _customInstructionsCtrl.text.trim().isNotEmpty
              ? _customInstructionsCtrl.text.trim()
              : null,
        );

    _listenForMessages();

    // Initialize edit controllers from the generated presentation
    final presentation = ref.read(presentationProvider).currentPresentation;
    if (presentation != null) {
      _titleEditCtrl.text = presentation.title;
      _initSlideControllers(presentation.slides);
    }
  }

  void _initSlideControllers(List<Map<String, dynamic>> slides) {
    for (final c in _slideTitleControllers) {
      c.dispose();
    }
    _slideTitleControllers.clear();
    for (final c in _slideBodyControllers) {
      c.dispose();
    }
    _slideBodyControllers.clear();
    for (final c in _slideNotesControllers) {
      c.dispose();
    }
    _slideNotesControllers.clear();

    for (final slide in slides) {
      _slideTitleControllers.add(
        TextEditingController(text: slide['title'] as String? ?? ''),
      );
      _slideBodyControllers.add(
        TextEditingController(text: slide['body'] as String? ?? ''),
      );
      _slideNotesControllers.add(
        TextEditingController(text: slide['speaker_notes'] as String? ?? ''),
      );
    }
  }

  void _handleSave() {
    final presentation = ref.read(presentationProvider).currentPresentation;
    if (presentation == null) return;

    final updatedSlides = List<Map<String, dynamic>>.generate(
      _slideTitleControllers.length,
      (i) => {
        'title': _slideTitleControllers[i].text.trim(),
        'body': _slideBodyControllers[i].text.trim(),
        'speaker_notes': _slideNotesControllers[i].text.trim(),
      },
    );

    ref.read(presentationProvider.notifier).updatePresentation(
          presentation.copyWith(
            title: _titleEditCtrl.text.trim().isNotEmpty
                ? _titleEditCtrl.text.trim()
                : presentation.title,
            slides: updatedSlides,
            totalSlides: updatedSlides.length,
          ),
        );

    setState(() => _isEditing = false);
    _listenForMessages();
  }

  void _handleReset() {
    ref.read(presentationProvider.notifier).setCurrentPresentation(null);
    _titleEditCtrl.clear();
    for (final c in _slideTitleControllers) {
      c.dispose();
    }
    _slideTitleControllers.clear();
    for (final c in _slideBodyControllers) {
      c.dispose();
    }
    _slideBodyControllers.clear();
    for (final c in _slideNotesControllers) {
      c.dispose();
    }
    _slideNotesControllers.clear();
    setState(() => _isEditing = false);
  }

  void _handleExport(String format) {
    final presentation = ref.read(presentationProvider).currentPresentation;
    if (presentation == null) return;

    ref.read(presentationProvider.notifier).exportPresentation(
          presentationId: presentation.id,
          format: format,
        );
    _listenForMessages();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presentationProvider);
    final presentation = state.currentPresentation;

    return Scaffold(
      appBar: AppAppBar(
        title: presentation != null
            ? 'Generated Presentation'
            : 'AI Presentation Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (presentation != null)
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
          : presentation != null
              ? _buildGeneratedResult(presentation)
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
              'Create a Presentation with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate a comprehensive presentation tailored to your needs.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Spacings.sectionGap,

            // Subject
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Mathematics, English, Physics',
              controller: _subjectCtrl,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required' : null,
            ),
            Spacings.itemGap,

            // Class Name
            AppTextField(
              label: 'Class',
              hint: 'e.g. SS2, JSS3, Primary 5',
              controller: _classNameCtrl,
              prefixIcon: Icons.school_outlined,
            ),
            Spacings.itemGap,

            // Topic
            AppTextField(
              label: 'Topic',
              hint: 'e.g. Quadratic Equations, Photosynthesis',
              controller: _topicCtrl,
              prefixIcon: Icons.topic_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Topic is required' : null,
            ),
            Spacings.itemGap,

            // Presentation Type dropdown
            AppDropdownField<PresentationType>(
              label: 'Presentation Type',
              items: PresentationType.values,
              selectedItem: _presentationType,
              onChanged: (v) {
                if (v != null) setState(() => _presentationType = v);
              },
              itemLabel: (t) => t.label,
              prefixIcon: Icons.slideshow_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Curriculum dropdown
            AppDropdownField<CurriculumType>(
              label: 'Curriculum',
              items: CurriculumType.values,
              selectedItem: _curriculum,
              onChanged: (v) {
                if (v != null) setState(() => _curriculum = v);
              },
              itemLabel: (c) => c.label,
              prefixIcon: Icons.curriculum_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Difficulty dropdown
            AppDropdownField<StudentLevel>(
              label: 'Difficulty',
              items: StudentLevel.values,
              selectedItem: _difficulty,
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
              itemLabel: (l) => l.label,
              prefixIcon: Icons.signal_cellular_alt_rounded,
            ),
            Spacings.itemGap,

            // Number of Slides Slider
            _buildSlideCountSlider(),
            Spacings.itemGap,

            // Custom Instructions
            AppTextField(
              label: 'Custom Instructions',
              hint: 'Any specific requirements or preferences for the presentation...',
              controller: _customInstructionsCtrl,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Presentation',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(presentationProvider).isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideCountSlider() {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.view_carousel_outlined, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.sm),
            Text(
              'Number of Slides',
              style: context.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                '${_slideCount.round()}',
                style: context.textTheme.labelLarge?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _slideCount,
          min: 3,
          max: 30,
          divisions: 27,
          label: '${_slideCount.round()}',
          onChanged: (v) => setState(() => _slideCount = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '3',
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              '30',
              style: context.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
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
              'Generating Your Presentation...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting ${_slideCount.round()} slides based on your parameters. This may take a moment.',
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

  Widget _buildGeneratedResult(PresentationEntity presentation) {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (presentation.isAiGenerated) _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Title section
          _buildSectionCard(
            icon: Icons.title_rounded,
            title: 'Title',
            child: _isEditing
                ? AppTextField(
                    controller: _titleEditCtrl,
                    label: 'Presentation Title',
                    isRequired: true,
                  )
                : Text(
                    presentation.title,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
          ),
          Spacings.itemGap,

          // Preview card with meta info
          _buildPreviewCard(presentation),
          Spacings.itemGap,

          // Slides
          ...List.generate(presentation.slides.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: _buildSlideCard(presentation.slides[i], i),
            );
          }),
          Spacings.sectionGap,

          // Generate Questions button (prominent)
          GenerateQuestionsButton(
            resourceType: 'presentation',
            resourceId: presentation.id,
            resourceName: presentation.title,
            subject: presentation.topic,
            topic: presentation.topic,
          ),
          Spacings.sectionGap,

          // Action buttons
          _buildActionButtons(presentation),
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

  Widget _buildPreviewCard(PresentationEntity presentation) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _presentationTypeIcon(presentation.presentationType),
                size: Spacings.lgIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presentation.presentationType.label,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      '${presentation.totalSlides} slides',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  presentation.presentationType.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.md,
            runSpacing: Spacings.sm,
            children: [
              if (presentation.topic != null)
                _buildMetaChip(
                  icon: Icons.topic_outlined,
                  label: presentation.topic!,
                  color: cs.primary,
                ),
              if (presentation.curriculum != null)
                _buildMetaChip(
                  icon: Icons.curriculum_outlined,
                  label: presentation.curriculum!.label,
                  color: cs.secondary,
                ),
              if (presentation.difficulty != null)
                _buildMetaChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: presentation.difficulty!.label,
                  color: cs.tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(Map<String, dynamic> slide, int index) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final title = slide['title'] as String? ?? 'Slide ${index + 1}';
    final body = slide['body'] as String? ?? '';
    final speakerNotes = slide['speaker_notes'] as String? ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: _isEditing
                    ? AppTextField(
                        controller: _slideTitleControllers[index],
                        hint: 'Slide Title',
                      )
                    : Text(
                        title,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
              ),
              // Edit toggle for individual slide
              if (!_isEditing)
                AppIconButton(
                  icon: Icons.edit_outlined,
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Slide',
                  variant: AppIconButtonVariant.standard,
                  size: AppButtonSize.small,
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Slide body
          if (_isEditing)
            AppTextField(
              controller: _slideBodyControllers[index],
              hint: 'Slide Content',
              maxLines: 5,
              minLines: 2,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.smRadius),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                body,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          const SizedBox(height: Spacings.md),

          // Speaker notes
          if (speakerNotes.isNotEmpty || _isEditing) ...[
            Row(
              children: [
                Icon(Icons.record_voice_over_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Speaker Notes',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xs),
            if (_isEditing)
              AppTextField(
                controller: _slideNotesControllers[index],
                hint: 'Speaker notes for this slide...',
                maxLines: 3,
                minLines: 1,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  speakerNotes,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
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
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
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

  Widget _buildActionButtons(PresentationEntity presentation) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isEditing) ...[
          AppButton(
            label: 'Save Changes',
            onPressed: _handleSave,
            variant: AppButtonVariant.elevated,
            icon: Icons.save_rounded,
            isLoading: ref.watch(presentationProvider).isUpdating,
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
            label: 'Edit Presentation',
            onPressed: () => setState(() => _isEditing = true),
            variant: AppButtonVariant.outlined,
            icon: Icons.edit_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: Spacings.sm),

          // Export dropdown
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Save as Draft',
                  onPressed: () {
                    ref.read(presentationProvider.notifier).savePresentation(
                          presentation,
                          isDraft: true,
                        );
                    _listenForMessages();
                  },
                  variant: AppButtonVariant.tonal,
                  icon: Icons.bookmark_add_rounded,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: AppButton(
                  label: 'Save & Publish',
                  onPressed: () {
                    ref.read(presentationProvider.notifier).savePresentation(
                          presentation,
                          isDraft: false,
                        );
                    _listenForMessages();
                  },
                  variant: AppButtonVariant.elevated,
                  icon: Icons.publish_rounded,
                  fullWidth: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // Export section
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Share with Colleagues',
                  onPressed: () {
                    ref.read(presentationProvider.notifier).sharePresentation(
                          presentation.id,
                        );
                    _listenForMessages();
                  },
                  variant: AppButtonVariant.outlined,
                  icon: Icons.share_rounded,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: PopupMenuButton<String>(
                  onSelected: _handleExport,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
                    const PopupMenuItem(value: 'PPTX', child: Text('Export as PPTX')),
                    const PopupMenuItem(value: 'HTML', child: Text('Export as HTML')),
                  ],
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.xl,
                        vertical: Spacings.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Spacings.lgRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _presentationTypeIcon(PresentationType type) {
    switch (type) {
      case PresentationType.powerpoint:
        return Icons.slideshow_rounded;
      case PresentationType.teachingSlides:
        return Icons.school_rounded;
      case PresentationType.infographic:
        return Icons.dashboard_rounded;
      case PresentationType.diagram:
        return Icons.account_tree_rounded;
      case PresentationType.flowchart:
        return Icons.alt_route_rounded;
      case PresentationType.mindMap:
        return Icons.hub_rounded;
      case PresentationType.summarySheet:
        return Icons.summarize_rounded;
    }
  }
}
