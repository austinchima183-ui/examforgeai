import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../domain/entities/ai_entities.dart';
import 'bloom_taxonomy_selector.dart';

// ═══════════════════════════════════════════════════════════════════════
// GENERATION INPUT FORM
// ═══════════════════════════════════════════════════════════════════════

/// Teacher input form for AI question generation. Includes subject, topic,
/// subtopic (cascading), class, curriculum, question type, difficulty,
/// Bloom's Taxonomy, number of questions, language, exam type, keywords,
/// custom instructions, AI provider, and prompt template selection.
///
/// ```dart
/// GenerationInputForm(
///   input: currentInput,
///   onInputChanged: (input) => provider.setInput(input),
///   onGenerate: () => provider.generateQuestions(),
///   isGenerating: false,
///   availableSubjects: subjects,
///   availableTopics: topics,
///   availableSubtopics: subtopics,
///   promptTemplates: templates,
/// )
/// ```
class GenerationInputForm extends StatefulWidget {
  const GenerationInputForm({
    super.key,
    this.input,
    required this.onInputChanged,
    this.onGenerate,
    this.isGenerating = false,
    this.availableSubjects = const [],
    this.availableTopics = const [],
    this.availableSubtopics = const [],
    this.availableClasses = const [],
    this.promptTemplates = const [],
  });

  /// Current generation input state.
  final GenerationInputEntity? input;

  /// Callback fired when any field changes.
  final ValueChanged<GenerationInputEntity> onInputChanged;

  /// Callback when the Generate button is pressed.
  final VoidCallback? onGenerate;

  /// Whether generation is in progress.
  final bool isGenerating;

  /// Available subjects for the subject dropdown.
  final List<DropdownItem> availableSubjects;

  /// Available topics (cascading from subject).
  final List<DropdownItem> availableTopics;

  /// Available subtopics (cascading from topic).
  final List<DropdownItem> availableSubtopics;

  /// Available class levels.
  final List<DropdownItem> availableClasses;

  /// Available prompt templates.
  final List<PromptTemplateEntity> promptTemplates;

  @override
  State<GenerationInputForm> createState() => _GenerationInputFormState();
}

/// Simple data class for dropdown items.
class DropdownItem {
  const DropdownItem({required this.id, required this.label});
  final String id;
  final String label;
}

class _GenerationInputFormState extends State<GenerationInputForm> {
  late TextEditingController _customInstructionsController;
  late TextEditingController _keywordsController;
  late SliderController _numQuestionsController;

  @override
  void initState() {
    super.initState();
    _customInstructionsController = TextEditingController(
      text: widget.input?.customInstructions ?? '',
    );
    _keywordsController = TextEditingController();
    _numQuestionsController = SliderController(
      initialValue: widget.input?.numQuestions.toDouble() ?? 5.0,
    );
  }

  @override
  void didUpdateWidget(covariant GenerationInputForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.input?.customInstructions != oldWidget.input?.customInstructions) {
      final newText = widget.input?.customInstructions ?? '';
      if (_customInstructionsController.text != newText) {
        _customInstructionsController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _customInstructionsController.dispose();
    _keywordsController.dispose();
    _numQuestionsController.dispose();
    super.dispose();
  }

  void _updateInput(GenerationInputEntity newInput) {
    widget.onInputChanged(newInput);
  }

  void _addKeyword(String keyword) {
    if (keyword.trim().isEmpty) return;
    final current = widget.input ?? const GenerationInputEntity(
      subjectId: '',
      topicId: '',
      difficulty: DifficultyLevel.medium,
    );
    if (current.keywords.contains(keyword.trim())) return;
    _updateInput(current.copyWith(
      keywords: [...current.keywords, keyword.trim()],
    ));
    _keywordsController.clear();
  }

  void _removeKeyword(String keyword) {
    final current = widget.input ?? const GenerationInputEntity(
      subjectId: '',
      topicId: '',
      difficulty: DifficultyLevel.medium,
    );
    _updateInput(current.copyWith(
      keywords: current.keywords.where((k) => k != keyword).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;
    final input = widget.input;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section: Subject & Topic ────────────────────────────────
          _sectionHeader('Subject & Topic', Icons.school_outlined),
          const SizedBox(height: Spacings.md),

          // Subject dropdown
          AppDropdownField<DropdownItem>(
            label: 'Subject',
            items: widget.availableSubjects,
            selectedItem: widget.availableSubjects.isNotEmpty
                ? widget.availableSubjects.where(
                    (s) => s.id == input?.subjectId,
                  ).firstOrNull
                : null,
            onChanged: (item) {
              if (item != null && input != null) {
                _updateInput(input.copyWith(
                  subjectId: item.id,
                  topicId: '',
                  subtopicId: null,
                ));
              }
            },
            itemLabel: (item) => item.label,
            prefixIcon: Icons.book_outlined,
            isRequired: true,
          ),
          const SizedBox(height: Spacings.md),

          // Topic dropdown (cascading)
          AppDropdownField<DropdownItem>(
            label: 'Topic',
            items: widget.availableTopics,
            selectedItem: widget.availableTopics.isNotEmpty
                ? widget.availableTopics.where(
                    (t) => t.id == input?.topicId,
                  ).firstOrNull
                : null,
            onChanged: (item) {
              if (item != null && input != null) {
                _updateInput(input.copyWith(
                  topicId: item.id,
                  subtopicId: null,
                ));
              }
            },
            itemLabel: (item) => item.label,
            prefixIcon: Icons.topic_outlined,
            isRequired: true,
          ),
          const SizedBox(height: Spacings.md),

          // Subtopic dropdown (cascading)
          AppDropdownField<DropdownItem>(
            label: 'Subtopic',
            items: widget.availableSubtopics,
            selectedItem: widget.availableSubtopics.isNotEmpty && input?.subtopicId != null
                ? widget.availableSubtopics.where(
                    (s) => s.id == input!.subtopicId,
                  ).firstOrNull
                : null,
            onChanged: (item) {
              if (input != null) {
                _updateInput(input.copyWith(subtopicId: item?.id));
              }
            },
            itemLabel: (item) => item.label,
            prefixIcon: Icons.subdirectory_arrow_right_rounded,
          ),
          const SizedBox(height: Spacings.md),

          // Class & Curriculum row
          if (isMobile) ...[
            AppDropdownField<DropdownItem>(
              label: 'Class',
              items: widget.availableClasses,
              selectedItem: widget.availableClasses.isNotEmpty && input?.classId != null
                  ? widget.availableClasses.where(
                      (c) => c.id == input!.classId,
                    ).firstOrNull
                  : null,
              onChanged: (item) {
                if (input != null) {
                  _updateInput(input.copyWith(classId: item?.id));
                }
              },
              itemLabel: (item) => item.label,
              prefixIcon: Icons.class_outlined,
            ),
            const SizedBox(height: Spacings.md),
            AppDropdownField<CurriculumType>(
              label: 'Curriculum',
              items: CurriculumType.values,
              selectedItem: input?.curriculum,
              onChanged: (val) {
                if (input != null) {
                  _updateInput(input.copyWith(curriculum: val));
                }
              },
              itemLabel: (c) => c.label,
              prefixIcon: Icons.menu_book_outlined,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: AppDropdownField<DropdownItem>(
                    label: 'Class',
                    items: widget.availableClasses,
                    selectedItem: widget.availableClasses.isNotEmpty && input?.classId != null
                        ? widget.availableClasses.where(
                            (c) => c.id == input!.classId,
                          ).firstOrNull
                        : null,
                    onChanged: (item) {
                      if (input != null) {
                        _updateInput(input.copyWith(classId: item?.id));
                      }
                    },
                    itemLabel: (item) => item.label,
                    prefixIcon: Icons.class_outlined,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppDropdownField<CurriculumType>(
                    label: 'Curriculum',
                    items: CurriculumType.values,
                    selectedItem: input?.curriculum,
                    onChanged: (val) {
                      if (input != null) {
                        _updateInput(input.copyWith(curriculum: val));
                      }
                    },
                    itemLabel: (c) => c.label,
                    prefixIcon: Icons.menu_book_outlined,
                  ),
                ),
              ],
            ),

          Spacings.sectionGap,

          // ── Section: Question Configuration ─────────────────────────
          _sectionHeader('Question Configuration', Icons.tune_rounded),
          const SizedBox(height: Spacings.md),

          // Question type selector (grid of chips)
          Text(
            'Question Type',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: AppTypography.wMedium,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: QuestionType.values.map((type) {
              final isSelected = input?.questionType == type;
              return ChoiceChip(
                label: Text(type.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (input != null) {
                    _updateInput(input.copyWith(
                      questionType: selected ? type : null,
                    ));
                  }
                },
                selectedColor: cs.primary.withValues(
                  alpha: context.isDarkMode ? 0.25 : 0.15,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacings.md),

          // Difficulty selector
          AppDropdownField<DifficultyLevel>(
            label: 'Difficulty',
            items: DifficultyLevel.values,
            selectedItem: input?.difficulty,
            onChanged: (val) {
              if (input != null && val != null) {
                _updateInput(input.copyWith(difficulty: val));
              }
            },
            itemLabel: (d) => d.label,
            prefixIcon: Icons.signal_cellular_alt_rounded,
            isRequired: true,
          ),
          const SizedBox(height: Spacings.md),

          // Bloom's Taxonomy selector
          BloomTaxonomySelector(
            selectedLevel: input?.bloomLevel,
            onLevelSelected: (level) {
              if (input != null) {
                _updateInput(input.copyWith(bloomLevel: level));
              }
            },
            isCompact: isMobile,
          ),
          const SizedBox(height: Spacings.md),

          // Number of questions slider
          Row(
            children: [
              Text(
                'Number of Questions',
                style: tt.bodyMedium?.copyWith(
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
                  color: cs.primary.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '${input?.numQuestions ?? 5}',
                  style: tt.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: (input?.numQuestions ?? 5).toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: '${input?.numQuestions ?? 5}',
            onChanged: (val) {
              if (input != null) {
                _updateInput(input.copyWith(numQuestions: val.round()));
              }
            },
          ),

          Spacings.sectionGap,

          // ── Section: Language & Exam ────────────────────────────────
          _sectionHeader('Language & Exam', Icons.language_rounded),
          const SizedBox(height: Spacings.md),

          if (isMobile) ...[
            AppDropdownField<String>(
              label: 'Language',
              items: const ['en', 'fr', 'ha', 'yo', 'ig', 'pt'],
              selectedItem: input?.language ?? 'en',
              onChanged: (val) {
                if (input != null && val != null) {
                  _updateInput(input.copyWith(language: val));
                }
              },
              itemLabel: (l) => _languageLabel(l),
              prefixIcon: Icons.translate_rounded,
            ),
            const SizedBox(height: Spacings.md),
            AppDropdownField<ExamType>(
              label: 'Exam Type',
              items: ExamType.values,
              selectedItem: input?.examType,
              onChanged: (val) {
                if (input != null) {
                  _updateInput(input.copyWith(examType: val));
                }
              },
              itemLabel: (e) => e.label,
              prefixIcon: Icons.assignment_outlined,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: AppDropdownField<String>(
                    label: 'Language',
                    items: const ['en', 'fr', 'ha', 'yo', 'ig', 'pt'],
                    selectedItem: input?.language ?? 'en',
                    onChanged: (val) {
                      if (input != null && val != null) {
                        _updateInput(input.copyWith(language: val));
                      }
                    },
                    itemLabel: (l) => _languageLabel(l),
                    prefixIcon: Icons.translate_rounded,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppDropdownField<ExamType>(
                    label: 'Exam Type',
                    items: ExamType.values,
                    selectedItem: input?.examType,
                    onChanged: (val) {
                      if (input != null) {
                        _updateInput(input.copyWith(examType: val));
                      }
                    },
                    itemLabel: (e) => e.label,
                    prefixIcon: Icons.assignment_outlined,
                  ),
                ),
              ],
            ),

          Spacings.sectionGap,

          // ── Section: Keywords ───────────────────────────────────────
          _sectionHeader('Keywords', Icons.tag_rounded),
          const SizedBox(height: Spacings.md),

          // Keywords chip input
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _keywordsController,
                  label: 'Add keyword',
                  hint: 'Type a keyword and press Enter',
                  prefixIcon: Icons.add_rounded,
                  onFieldSubmitted: (val) => _addKeyword(val),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              AppIconButton(
                icon: Icons.add_circle_rounded,
                onPressed: () => _addKeyword(_keywordsController.text),
                variant: AppIconButtonVariant.tonal,
                tooltip: 'Add keyword',
              ),
            ],
          ),
          if (input?.keywords.isNotEmpty == true) ...[
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: input!.keywords.map((kw) {
                return Chip(
                  label: Text(kw),
                  onDeleted: () => _removeKeyword(kw),
                  deleteIconColor: cs.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],

          Spacings.sectionGap,

          // ── Section: Custom Instructions ────────────────────────────
          _sectionHeader('Custom Instructions', Icons.edit_note_rounded),
          const SizedBox(height: Spacings.md),
          AppTextField(
            controller: _customInstructionsController,
            label: 'Custom Instructions',
            hint: 'Any additional instructions for the AI...',
            maxLines: 3,
            minLines: 2,
            onChanged: (val) {
              if (input != null) {
                _updateInput(input.copyWith(customInstructions: val.isEmpty ? null : val));
              }
            },
          ),

          Spacings.sectionGap,

          // ── Section: AI Provider & Prompt Template ──────────────────
          _sectionHeader('AI Provider', Icons.smart_toy_outlined),
          const SizedBox(height: Spacings.md),

          AppDropdownField<AiProvider>(
            label: 'AI Provider',
            items: AiProvider.values,
            selectedItem: input?.provider,
            onChanged: (val) {
              if (input != null) {
                _updateInput(input.copyWith(provider: val));
              }
            },
            itemLabel: (p) => p.displayName,
            prefixIcon: Icons.psychology_outlined,
          ),
          const SizedBox(height: Spacings.md),

          if (widget.promptTemplates.isNotEmpty)
            AppDropdownField<String>(
              label: 'Prompt Template',
              items: widget.promptTemplates.map((t) => t.id).toList(),
              selectedItem: input?.promptTemplateId,
              onChanged: (val) {
                if (input != null) {
                  _updateInput(input.copyWith(promptTemplateId: val));
                }
              },
              itemLabel: (id) {
                final template = widget.promptTemplates.where(
                  (t) => t.id == id,
                ).firstOrNull;
                return template?.name ?? id;
              },
              prefixIcon: Icons.description_outlined,
            ),

          Spacings.sectionGap,

          // ── Generate button ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Generate Questions',
              onPressed: widget.onGenerate,
              variant: AppButtonVariant.elevated,
              size: AppButtonSize.large,
              icon: Icons.auto_awesome_rounded,
              isLoading: widget.isGenerating,
              isDisabled: widget.isGenerating ||
                  input?.subjectId.isEmpty != false ||
                  input?.topicId.isEmpty != false,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: context.colorScheme.primary),
        const SizedBox(width: Spacings.sm),
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: context.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _languageLabel(String code) {
    return switch (code) {
      'en' => 'English',
      'fr' => 'French',
      'ha' => 'Hausa',
      'yo' => 'Yoruba',
      'ig' => 'Igbo',
      'pt' => 'Portuguese',
      _ => code.toUpperCase(),
    };
  }
}

/// Simple controller for slider values.
class SliderController {
  SliderController({required this.initialValue});
  final double initialValue;
}
