import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/question_entities.dart';
import '../providers/question_editor_provider.dart';
import '../widgets/question_type_badge.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/answer_options_editor.dart';
import '../widgets/matching_pairs_editor.dart';
import '../widgets/ordering_items_editor.dart';
import '../widgets/fill_in_blank_editor.dart';
import '../widgets/question_preview_card.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// QUESTION EDITOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Full-featured question editor supporting create and edit modes.
///
/// The form is divided into sections:
/// 1. Question Type selection (grid of selectable type cards)
/// 2. Question Content (multiline text field)
/// 3. Answer Configuration (dynamic based on selected type)
/// 4. Classification (subject, topic, subtopic, class, category)
/// 5. Settings (difficulty, exam type, marks, negative marks, time)
/// 6. Explanation & Notes
/// 7. Attachments
/// 8. Tags
///
/// Supports:
/// - Preview mode toggle
/// - Save Draft / Publish actions
/// - Form validation
/// - Unsaved changes dialog on back
/// - Loading state while saving
class QuestionEditorPage extends ConsumerStatefulWidget {
  const QuestionEditorPage({
    super.key,
    this.questionId,
  });

  /// If provided, the editor loads this question for editing.
  final String? questionId;

  @override
  ConsumerState<QuestionEditorPage> createState() =>
      _QuestionEditorPageState();
}

class _QuestionEditorPageState extends ConsumerState<QuestionEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _explanationController = TextEditingController();
  final _teacherNotesController = TextEditingController();
  final _referenceMaterialsController = TextEditingController();
  final _marksController = TextEditingController();
  final _negativeMarksController = TextEditingController();
  final _timeAllowedController = TextEditingController();
  final _tagSearchController = TextEditingController();

  bool _hasInitialized = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEditor();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _explanationController.dispose();
    _teacherNotesController.dispose();
    _referenceMaterialsController.dispose();
    _marksController.dispose();
    _negativeMarksController.dispose();
    _timeAllowedController.dispose();
    _tagSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeEditor() async {
    if (widget.questionId != null) {
      await ref
          .read(questionEditorProvider.notifier)
          .loadQuestionForEdit(widget.questionId!);
    }
    _syncControllersFromState();
    _hasInitialized = true;
  }

  void _syncControllersFromState() {
    final state = ref.read(questionEditorProvider);
    _contentController.text = state.content;
    _explanationController.text = state.explanation;
    _teacherNotesController.text = state.teacherNotes;
    _referenceMaterialsController.text = state.referenceMaterials;
    _marksController.text = state.marks.toString();
    _negativeMarksController.text = state.negativeMarks.toString();
    if (state.timeAllowedSeconds != null) {
      _timeAllowedController.text = (state.timeAllowedSeconds! ~/ 60).toString();
    }
  }

  void _markUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(questionEditorProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_hasUnsavedChanges) {
          final shouldLeave = await _showUnsavedChangesDialog();
          if (shouldLeave == true && mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: editorState.isEditMode ? 'Edit Question' : 'Create Question',
          actions: [
            // Preview toggle
            AppIconButton(
              icon: editorState.isPreviewMode
                  ? Icons.edit_rounded
                  : Icons.visibility_rounded,
              onPressed: () {
                ref.read(questionEditorProvider.notifier).togglePreviewMode();
              },
              tooltip: editorState.isPreviewMode ? 'Edit' : 'Preview',
            ),
            // Save Draft
            if (!editorState.isPreviewMode)
              AppButton(
                label: 'Save Draft',
                onPressed: editorState.isSaving ? null : _saveDraft,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                isLoading: editorState.isSaving,
              ),
            const SizedBox(width: Spacings.sm),
            // Publish
            AppButton(
              label: 'Publish',
              onPressed: editorState.isSaving ? null : _publish,
              variant: AppButtonVariant.elevated,
              size: AppButtonSize.small,
              isLoading: editorState.isSaving,
            ),
            const SizedBox(width: Spacings.sm),
          ],
        ),
        body: editorState.isLoading
            ? const Center(
                child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
              )
            : editorState.isPreviewMode
                ? _buildPreviewMode(editorState)
                : _buildFormMode(editorState),
      ),
    );
  }

  // ─── Preview Mode ───────────────────────────────────────────────────

  Widget _buildPreviewMode(QuestionEditorState editorState) {
    // Build a temporary QuestionEntity from the current editor state
    final previewQuestion = _buildQuestionFromState(editorState);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: QuestionPreviewCard(
        question: previewQuestion,
      ),
    );
  }

  // ─── Form Mode ──────────────────────────────────────────────────────

  Widget _buildFormMode(QuestionEditorState editorState) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Question Type ──────────────────────────────────
            _buildSectionHeader(
              Icons.category_rounded,
              'Question Type',
            ),
            const SizedBox(height: Spacings.md),
            _buildQuestionTypeGrid(editorState),

            Spacings.sectionGap,

            // ── 2. Question Content ──────────────────────────────
            _buildSectionHeader(
              Icons.edit_note_rounded,
              'Question Content',
            ),
            const SizedBox(height: Spacings.md),
            AppTextField(
              label: 'Question',
              hint: 'Enter the question text…',
              controller: _contentController,
              maxLines: 10,
              minLines: 3,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Question content is required' : null,
              onChanged: (v) {
                ref.read(questionEditorProvider.notifier).setContent(v);
                _markUnsaved();
              },
            ),

            Spacings.sectionGap,

            // ── 3. Answer Configuration ──────────────────────────
            _buildSectionHeader(
              Icons.check_circle_outline_rounded,
              'Answer Configuration',
            ),
            const SizedBox(height: Spacings.md),
            _buildAnswerConfiguration(editorState),

            Spacings.sectionGap,

            // ── 4. Classification ────────────────────────────────
            _buildSectionHeader(
              Icons.folder_outlined,
              'Classification',
            ),
            const SizedBox(height: Spacings.md),
            _buildClassification(editorState),

            Spacings.sectionGap,

            // ── 5. Settings ──────────────────────────────────────
            _buildSectionHeader(
              Icons.settings_outlined,
              'Settings',
            ),
            const SizedBox(height: Spacings.md),
            _buildSettings(editorState),

            Spacings.sectionGap,

            // ── 6. Explanation & Notes ───────────────────────────
            _buildSectionHeader(
              Icons.lightbulb_outline_rounded,
              'Explanation & Notes',
            ),
            const SizedBox(height: Spacings.md),
            _buildExplanationAndNotes(),

            Spacings.sectionGap,

            // ── 7. Attachments ───────────────────────────────────
            _buildSectionHeader(
              Icons.attach_file_rounded,
              'Attachments',
            ),
            const SizedBox(height: Spacings.md),
            _buildAttachments(editorState),

            Spacings.sectionGap,

            // ── 8. Tags ──────────────────────────────────────────
            _buildSectionHeader(
              Icons.label_outline_rounded,
              'Tags',
            ),
            const SizedBox(height: Spacings.md),
            _buildTags(editorState),

            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: cs.primary),
        const SizedBox(width: Spacings.sm),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── 1. Question Type Grid ──────────────────────────────────────────

  Widget _buildQuestionTypeGrid(QuestionEditorState editorState) {
    final cs = context.colorScheme;
    final isDesktop = context.isDesktop;
    final crossAxisCount = isDesktop ? 4 : (context.isTablet ? 3 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 2.8,
      crossAxisSpacing: Spacings.sm,
      mainAxisSpacing: Spacings.sm,
      children: QuestionType.values.map((type) {
        final isSelected = editorState.selectedQuestionType == type;
        return InkWell(
          onTap: () {
            ref.read(questionEditorProvider.notifier).setQuestionType(type);
            _markUnsaved();
          },
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.08)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.5),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                QuestionTypeBadge(
                  type: type,
                  variant: QuestionTypeBadgeVariant.iconOnly,
                  size: QuestionTypeBadgeSize.small,
                ),
                const SizedBox(width: Spacings.sm),
                Flexible(
                  child: Text(
                    type.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isSelected ? cs.primary : cs.onSurface,
                      fontWeight: isSelected
                          ? AppTypography.wSemiBold
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 3. Answer Configuration ────────────────────────────────────────

  Widget _buildAnswerConfiguration(QuestionEditorState editorState) {
    final type = editorState.selectedQuestionType;
    final cs = context.colorScheme;

    switch (type) {
      case QuestionType.multipleChoice:
      case QuestionType.multipleResponse:
      case QuestionType.imageBased:
      case QuestionType.audioBased:
      case QuestionType.videoBased:
        return AnswerOptionsEditor(
          options: editorState.answerOptions,
          isMultiSelect: type == QuestionType.multipleResponse,
          onOptionsChanged: (newOptions) {
            ref.read(questionEditorProvider.notifier).updateAnswerOptions(newOptions);
            _markUnsaved();
          },
        );

      case QuestionType.trueFalse:
        return _buildTrueFalseEditor(editorState);

      case QuestionType.matching:
        return MatchingPairsEditor(
          pairs: editorState.matchingPairs,
          onPairsChanged: (newPairs) {
            ref.read(questionEditorProvider.notifier).updateMatchingPairs(newPairs);
            _markUnsaved();
          },
        );

      case QuestionType.ordering:
        return OrderingItemsEditor(
          items: editorState.orderingItems,
          onItemsChanged: (newItems) {
            ref.read(questionEditorProvider.notifier).updateOrderingItems(newItems);
            _markUnsaved();
          },
        );

      case QuestionType.fillInBlank:
        return FillInBlankEditor(
          blanks: editorState.fillInBlankAnswers,
          onBlanksChanged: (newBlanks) {
            ref.read(questionEditorProvider.notifier).updateFillInBlankAnswers(newBlanks);
            _markUnsaved();
          },
        );

      case QuestionType.shortAnswer:
      case QuestionType.essay:
      case QuestionType.numerical:
      case QuestionType.practical:
      case QuestionType.caseStudy:
        return AppTextField(
          label: 'Model Answer',
          hint: 'Enter the model answer or expected response…',
          controller: _explanationController, // Reuse for model answer
          maxLines: 8,
          minLines: 3,
          onChanged: (v) {
            _markUnsaved();
          },
        );
    }
  }

  // ─── True/False Editor ──────────────────────────────────────────────

  Widget _buildTrueFalseEditor(QuestionEditorState editorState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Check if "True" is the correct answer
    final isTrueCorrect = editorState.answerOptions.any(
      (o) => o.isCorrect && o.content.toLowerCase() == 'true',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the correct answer',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: Spacings.md),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('True'), icon: Icon(Icons.check_rounded)),
            ButtonSegment(value: false, label: Text('False'), icon: Icon(Icons.close_rounded)),
          ],
          selected: {isTrueCorrect},
          onSelectionChanged: (selection) {
            final isTrue = selection.first;
            // Update the state with True/False options
            ref.read(questionEditorProvider.notifier).setCorrectAnswer(isTrue ? 0 : 1);
            _markUnsaved();
          },
        ),
      ],
    );
  }

  // ─── 4. Classification ──────────────────────────────────────────────

  Widget _buildClassification(QuestionEditorState editorState) {
    return Column(
      children: [
        _buildResponsiveRow([
          AppDropdownField<String>(
            label: 'Subject',
            hint: 'Select subject',
            items: const [], // TODO: populate from provider
            selectedItem: editorState.selectedSubjectId,
            onChanged: (v) {
              ref.read(questionEditorProvider.notifier).setSubject(v);
              _markUnsaved();
            },
            prefixIcon: Icons.book_outlined,
            itemLabel: (id) => id,
          ),
          AppDropdownField<String>(
            label: 'Topic',
            hint: 'Select topic',
            items: editorState.availableTopics.map((t) => t.id).toList(),
            selectedItem: editorState.selectedTopicId,
            onChanged: (v) {
              ref.read(questionEditorProvider.notifier).setTopic(v);
              _markUnsaved();
            },
            prefixIcon: Icons.topic_outlined,
            isEnabled: editorState.selectedSubjectId != null,
            itemLabel: (id) {
              final topic = editorState.availableTopics
                  .where((t) => t.id == id)
                  .firstOrNull;
              return topic?.name ?? id;
            },
          ),
        ]),
        const SizedBox(height: Spacings.md),
        _buildResponsiveRow([
          AppDropdownField<String>(
            label: 'Subtopic',
            hint: 'Select subtopic',
            items: editorState.availableSubtopics.map((s) => s.id).toList(),
            selectedItem: editorState.selectedSubtopicId,
            onChanged: (v) {
              ref.read(questionEditorProvider.notifier).setSubtopic(v);
              _markUnsaved();
            },
            prefixIcon: Icons.subdirectory_arrow_right_rounded,
            isEnabled: editorState.selectedTopicId != null,
            itemLabel: (id) {
              final subtopic = editorState.availableSubtopics
                  .where((s) => s.id == id)
                  .firstOrNull;
              return subtopic?.name ?? id;
            },
          ),
          AppDropdownField<String>(
            label: 'Class',
            hint: 'Select class',
            items: const [], // TODO: populate from provider
            selectedItem: editorState.selectedClassId,
            onChanged: (v) {
              ref.read(questionEditorProvider.notifier).setClass(v);
              _markUnsaved();
            },
            prefixIcon: Icons.school_outlined,
            itemLabel: (id) => id,
          ),
        ]),
        const SizedBox(height: Spacings.md),
        AppDropdownField<String>(
          label: 'Category',
          hint: 'Select category',
          items: const [], // TODO: populate from provider
          selectedItem: editorState.selectedCategoryId,
          onChanged: (v) {
            ref.read(questionEditorProvider.notifier).setCategory(v);
            _markUnsaved();
          },
          prefixIcon: Icons.category_outlined,
          itemLabel: (id) => id,
        ),
      ],
    );
  }

  // ─── 5. Settings ────────────────────────────────────────────────────

  Widget _buildSettings(QuestionEditorState editorState) {
    return Column(
      children: [
        _buildResponsiveRow([
          AppDropdownField<DifficultyLevel>(
            label: 'Difficulty',
            items: DifficultyLevel.values,
            selectedItem: editorState.selectedDifficulty,
            onChanged: (v) {
              if (v != null) {
                ref.read(questionEditorProvider.notifier).setDifficulty(v);
                _markUnsaved();
              }
            },
            itemLabel: (d) => d.label,
            prefixIcon: Icons.signal_cellular_alt_rounded,
          ),
          AppDropdownField<ExamType>(
            label: 'Exam Type',
            items: ExamType.values,
            selectedItem: editorState.selectedExamType,
            onChanged: (v) {
              if (v != null) {
                ref.read(questionEditorProvider.notifier).setExamType(v);
                _markUnsaved();
              }
            },
            itemLabel: (e) => e.label,
            prefixIcon: Icons.quiz_outlined,
          ),
        ]),
        const SizedBox(height: Spacings.md),
        _buildResponsiveRow([
          AppTextField(
            label: 'Marks',
            controller: _marksController,
            prefixIcon: Icons.star_outline_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final marks = double.tryParse(v);
              if (marks != null) {
                ref.read(questionEditorProvider.notifier).setMarks(marks);
              }
              _markUnsaved();
            },
          ),
          AppTextField(
            label: 'Negative Marks',
            controller: _negativeMarksController,
            prefixIcon: Icons.remove_circle_outline_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final neg = double.tryParse(v);
              if (neg != null) {
                ref.read(questionEditorProvider.notifier).setNegativeMarks(neg);
              }
              _markUnsaved();
            },
          ),
        ]),
        const SizedBox(height: Spacings.md),
        AppTextField(
          label: 'Time Allowed (minutes)',
          controller: _timeAllowedController,
          prefixIcon: Icons.timer_outlined,
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final minutes = int.tryParse(v);
            ref.read(questionEditorProvider.notifier).setTimeAllowed(
                  minutes != null ? minutes * 60 : null,
                );
            _markUnsaved();
          },
        ),
      ],
    );
  }

  // ─── 6. Explanation & Notes ─────────────────────────────────────────

  Widget _buildExplanationAndNotes() {
    return Column(
      children: [
        AppTextField(
          label: 'Explanation',
          hint: 'Explain the correct answer…',
          controller: _explanationController,
          maxLines: 6,
          minLines: 2,
          onChanged: (v) {
            ref.read(questionEditorProvider.notifier).setExplanation(v);
            _markUnsaved();
          },
        ),
        const SizedBox(height: Spacings.md),
        AppTextField(
          label: 'Teacher Notes',
          hint: 'Internal notes (not visible to students)…',
          controller: _teacherNotesController,
          maxLines: 4,
          minLines: 2,
          onChanged: (v) {
            ref.read(questionEditorProvider.notifier).setTeacherNotes(v);
            _markUnsaved();
          },
        ),
        const SizedBox(height: Spacings.md),
        AppTextField(
          label: 'Reference Materials',
          hint: 'Source or reference information…',
          controller: _referenceMaterialsController,
          maxLines: 3,
          minLines: 1,
          onChanged: (v) {
            ref.read(questionEditorProvider.notifier).setReferenceMaterials(v);
            _markUnsaved();
          },
        ),
      ],
    );
  }

  // ─── 7. Attachments ─────────────────────────────────────────────────

  Widget _buildAttachments(QuestionEditorState editorState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: 'Add Attachment',
          onPressed: () {
            // TODO: file picker
            _markUnsaved();
          },
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.small,
          icon: Icons.attach_file_rounded,
        ),
        if (editorState.attachments.isNotEmpty) ...[
          const SizedBox(height: Spacings.md),
          ...editorState.attachments.map((att) {
            final icon = _attachmentIcon(att.contentType);
            final color = _attachmentColor(att.contentType, cs);
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(context.isDarkMode ? 0.15 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: Spacings.mdIcon, color: color),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.fileName ?? att.contentType,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: AppTypography.wMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (att.fileSize != null)
                            Text(
                              _formatFileSize(att.fileSize!),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: Spacings.smIcon,
                        color: AppColors.errorOf(cs.brightness),
                      ),
                      onPressed: () {
                        ref
                            .read(questionEditorProvider.notifier)
                            .removeAttachment(att.id);
                        _markUnsaved();
                      },
                      tooltip: 'Remove attachment',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // ─── 8. Tags ────────────────────────────────────────────────────────

  Widget _buildTags(QuestionEditorState editorState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Search Tags',
                hint: 'Type to search or add…',
                controller: _tagSearchController,
                prefixIcon: Icons.search_rounded,
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    ref.read(questionEditorProvider.notifier).addTag(
                          QuestionTagEntity(
                            id: 'tag-${DateTime.now().millisecondsSinceEpoch}',
                            name: v.trim(),
                            createdAt: DateTime.now(),
                          ),
                        );
                    _tagSearchController.clear();
                    _markUnsaved();
                  }
                },
              ),
            ),
            const SizedBox(width: Spacings.sm),
            AppButton(
              label: 'Add',
              onPressed: () {
                final v = _tagSearchController.text.trim();
                if (v.isNotEmpty) {
                  ref.read(questionEditorProvider.notifier).addTag(
                        QuestionTagEntity(
                          id: 'tag-${DateTime.now().millisecondsSinceEpoch}',
                          name: v,
                          createdAt: DateTime.now(),
                        ),
                      );
                  _tagSearchController.clear();
                  _markUnsaved();
                }
              },
              variant: AppButtonVariant.tonal,
              size: AppButtonSize.small,
            ),
          ],
        ),
        if (editorState.selectedTags.isNotEmpty) ...[
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.xs,
            runSpacing: Spacings.xs,
            children: editorState.selectedTags.map((tag) {
              return Chip(
                label: Text(
                  tag.name,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: Spacings.smIcon,
                ),
                onDeleted: () {
                  ref
                      .read(questionEditorProvider.notifier)
                      .removeTag(tag.id);
                  _markUnsaved();
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ─── Responsive Row Helper ──────────────────────────────────────────

  Widget _buildResponsiveRow(List<Widget> children) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .expand((w) => [w, const SizedBox(height: Spacings.sm)])
            .toList()
          ..removeLast(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: Spacings.md)])
          .toList()
        ..removeLast(),
    );
  }

  // ─── Save Draft ─────────────────────────────────────────────────────

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(questionEditorProvider.notifier);
    await notifier.saveAsDraft();

    _handleSaveResult();
  }

  // ─── Publish ────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(questionEditorProvider.notifier);
    await notifier.saveAndPublish();

    _handleSaveResult();
  }

  void _handleSaveResult() {
    final state = ref.read(questionEditorProvider);
    if (state.error != null && mounted) {
      AppDialog.showError(
        context: context,
        title: 'Save Failed',
        message: state.error!,
      );
    } else if (state.successMessage != null && mounted) {
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) context.pop();
    }
  }

  // ─── Unsaved Changes Dialog ─────────────────────────────────────────

  Future<bool?> _showUnsavedChangesDialog() {
    return AppDialog.showConfirm(
      context: context,
      title: 'Unsaved Changes',
      message:
          'You have unsaved changes. Are you sure you want to leave? Your changes will be lost.',
      confirmText: 'Leave',
      isDestructive: true,
    );
  }

  // ─── Build QuestionEntity from State ────────────────────────────────

  QuestionEntity _buildQuestionFromState(QuestionEditorState editorState) {
    final now = DateTime.now();
    return QuestionEntity(
      id: editorState.question?.id ?? 'preview',
      subjectId: editorState.selectedSubjectId ?? '',
      topicId: editorState.selectedTopicId,
      subtopicId: editorState.selectedSubtopicId,
      classId: editorState.selectedClassId,
      categoryId: editorState.selectedCategoryId,
      questionType: editorState.selectedQuestionType,
      difficulty: editorState.selectedDifficulty,
      examType: editorState.selectedExamType,
      content: editorState.content,
      explanation: editorState.explanation.isNotEmpty
          ? editorState.explanation
          : null,
      teacherNotes: editorState.teacherNotes.isNotEmpty
          ? editorState.teacherNotes
          : null,
      referenceMaterials: editorState.referenceMaterials.isNotEmpty
          ? editorState.referenceMaterials
          : null,
      marks: editorState.marks,
      negativeMarks: editorState.negativeMarks,
      timeAllowedSeconds: editorState.timeAllowedSeconds,
      isPublished: editorState.question?.isPublished ?? false,
      isArchived: editorState.question?.isArchived ?? false,
      isFeatured: editorState.question?.isFeatured ?? false,
      version: editorState.question?.version ?? 1,
      createdBy: editorState.question?.createdBy,
      usageCount: editorState.question?.usageCount ?? 0,
      avgScore: editorState.question?.avgScore ?? 0.0,
      createdAt: editorState.question?.createdAt ?? now,
      updatedAt: now,
      answerOptions: editorState.answerOptions,
      matchingPairs: editorState.matchingPairs,
      orderingItems: editorState.orderingItems,
      fillInBlankAnswers: editorState.fillInBlankAnswers,
      attachments: editorState.attachments,
      tags: editorState.selectedTags,
    );
  }

  // ─── Attachment Helpers ──────────────────────────────────────────────

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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
