import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../question_bank/domain/entities/question_entities.dart';
import '../../../question_bank/presentation/widgets/difficulty_badge.dart';
import '../../../question_bank/presentation/widgets/question_type_badge.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION SELECTOR WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// Selection mode for importing questions.
enum QuestionSelectionMode {
  /// Manually select individual questions.
  manual,

  /// Select from a pre-built collection.
  fromCollection,

  /// Auto-generate random questions based on criteria.
  random,
}

/// Widget for teachers to select questions from the Question Bank
/// for adding to an exam.
///
/// Supports:
/// - Search bar
/// - Filter by subject, topic, difficulty, type
/// - List of questions with checkboxes
/// - Selected count
/// - Import selected button
/// - Manual, collection, and random generation modes
class QuestionSelectorWidget extends StatefulWidget {
  const QuestionSelectorWidget({
    super.key,
    required this.availableQuestions,
    this.selectedQuestionIds = const {},
    this.onSelectionChanged,
    this.onImportSelected,
    this.isLoading = false,
  });

  /// All available questions from the bank.
  final List<QuestionEntity> availableQuestions;

  /// Currently selected question IDs.
  final Set<String> selectedQuestionIds;

  /// Callback when selection changes.
  final ValueChanged<Set<String>>? onSelectionChanged;

  /// Callback when import button is pressed.
  final VoidCallback? onImportSelected;

  /// Whether questions are being loaded.
  final bool isLoading;

  @override
  State<QuestionSelectorWidget> createState() => _QuestionSelectorWidgetState();
}

class _QuestionSelectorWidgetState extends State<QuestionSelectorWidget> {
  String _searchQuery = '';
  QuestionType? _typeFilter;
  DifficultyLevel? _difficultyFilter;
  QuestionSelectionMode _selectionMode = QuestionSelectionMode.manual;
  int _randomCount = 10;

  List<QuestionEntity> get _filteredQuestions {
    var questions = widget.availableQuestions;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      questions = questions
          .where((q) =>
              q.content.toLowerCase().contains(query) ||
              q.subjectId.toLowerCase().contains(query),)
          .toList();
    }

    // Type filter
    if (_typeFilter != null) {
      questions = questions.where((q) => q.questionType == _typeFilter).toList();
    }

    // Difficulty filter
    if (_difficultyFilter != null) {
      questions = questions.where((q) => q.difficulty == _difficultyFilter).toList();
    }

    return questions;
  }

  void _toggleQuestion(String questionId) {
    final updated = Set<String>.from(widget.selectedQuestionIds);
    if (updated.contains(questionId)) {
      updated.remove(questionId);
    } else {
      updated.add(questionId);
    }
    widget.onSelectionChanged?.call(updated);
  }

  void _selectAll() {
    final allIds = _filteredQuestions.map((q) => q.id).toSet();
    widget.onSelectionChanged?.call(allIds);
  }

  void _deselectAll() {
    widget.onSelectionChanged?.call({});
  }

  void _generateRandom() {
    final shuffled = List<QuestionEntity>.from(_filteredQuestions)..shuffle();
    final count = _randomCount.clamp(0, shuffled.length);
    final selected = shuffled.take(count).map((q) => q.id).toSet();
    widget.onSelectionChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search Bar ──────────────────────────────────────────────
        TextField(
          decoration: InputDecoration(
            hintText: 'Search questions…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),

        const SizedBox(height: Spacings.md),

        // ── Selection Mode Tabs ─────────────────────────────────────
        _buildModeSelector(context, cs, tt),

        const SizedBox(height: Spacings.md),

        // ── Filters Row ─────────────────────────────────────────────
        _buildFilterRow(context, cs, tt),

        const SizedBox(height: Spacings.md),

        // ── Random Generation Controls ──────────────────────────────
        if (_selectionMode == QuestionSelectionMode.random)
          _buildRandomControls(context, cs, tt),

        // ── Select All / Deselect All ───────────────────────────────
        if (_selectionMode == QuestionSelectionMode.manual) ...[
          Row(
            children: [
              TextButton.icon(
                onPressed: _selectAll,
                icon: const Icon(Icons.select_all_rounded, size: 16),
                label: const Text('Select All'),
              ),
              const SizedBox(width: Spacings.sm),
              TextButton.icon(
                onPressed: _deselectAll,
                icon: const Icon(Icons.deselect_rounded, size: 16),
                label: const Text('Deselect All'),
              ),
              const Spacer(),
              // Selected count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '${widget.selectedQuestionIds.length} selected',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
        ],

        // ── Questions List ──────────────────────────────────────────
        if (widget.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacings.xxl),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_filteredQuestions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacings.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: Spacings.xlIcon,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: Spacings.md),
                  Text(
                    'No questions found',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = _filteredQuestions[index];
                final isSelected =
                    widget.selectedQuestionIds.contains(question.id);

                return _buildQuestionItem(
                  context,
                  question: question,
                  index: index,
                  isSelected: isSelected,
                );
              },
            ),
          ),

        const SizedBox(height: Spacings.md),

        // ── Import Button ───────────────────────────────────────────
        AppButton(
          label: 'Import ${widget.selectedQuestionIds.length} Questions',
          onPressed: widget.selectedQuestionIds.isNotEmpty
              ? widget.onImportSelected
              : null,
          variant: AppButtonVariant.elevated,
          icon: Icons.add_circle_rounded,
          fullWidth: true,
          isDisabled: widget.selectedQuestionIds.isEmpty,
        ),
      ],
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return SegmentedButton<QuestionSelectionMode>(
      segments: const [
        ButtonSegment(
          value: QuestionSelectionMode.manual,
          label: Text('Manual'),
          icon: Icon(Icons.checklist_rounded),
        ),
        ButtonSegment(
          value: QuestionSelectionMode.fromCollection,
          label: Text('Collection'),
          icon: Icon(Icons.folder_rounded),
        ),
        ButtonSegment(
          value: QuestionSelectionMode.random,
          label: Text('Random'),
          icon: Icon(Icons.casino_rounded),
        ),
      ],
      selected: {_selectionMode},
      onSelectionChanged: (modes) {
        setState(() => _selectionMode = modes.first);
      },
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Row(
      children: [
        // Type filter
        Expanded(
          child: DropdownButtonFormField<QuestionType?>(
            initialValue: _typeFilter,
            hint: Text('All Types', style: tt.bodySmall),
            items: [
              const DropdownMenuItem<QuestionType?>(
                value: null,
                child: Text('All Types'),
              ),
              ...QuestionType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),),
            ],
            onChanged: (value) {
              setState(() => _typeFilter = value);
            },
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        // Difficulty filter
        Expanded(
          child: DropdownButtonFormField<DifficultyLevel?>(
            initialValue: _difficultyFilter,
            hint: Text('All Levels', style: tt.bodySmall),
            items: [
              const DropdownMenuItem<DifficultyLevel?>(
                value: null,
                child: Text('All Levels'),
              ),
              ...DifficultyLevel.values.map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level.label),
                  ),),
            ],
            onChanged: (value) {
              setState(() => _difficultyFilter = value);
            },
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandomControls(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
      ),
      child: Row(
        children: [
          Text(
            'Generate',
            style: tt.bodyMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: Spacings.sm),
          SizedBox(
            width: 70,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
              ),
              controller: TextEditingController(text: _randomCount.toString()),
              onChanged: (v) {
                final val = int.tryParse(v);
                if (val != null) setState(() => _randomCount = val);
              },
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            'random questions',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: _generateRandom,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
    BuildContext context, {
    required QuestionEntity question,
    required int index,
    required bool isSelected,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Material(
        color: isSelected
            ? cs.primary.withValues(alpha: context.isDarkMode ? 0.12 : 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        child: InkWell(
          onTap: () => _toggleQuestion(question.id),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
          child: Padding(
            padding: const EdgeInsets.all(Spacings.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => _toggleQuestion(question.id),
                  activeColor: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          QuestionTypeBadge(
                            type: question.questionType,
                            variant: QuestionTypeBadgeVariant.iconOnly,
                            size: QuestionTypeBadgeSize.small,
                          ),
                          const SizedBox(width: Spacings.xs),
                          DifficultyBadge(difficulty: question.difficulty),
                          const Spacer(),
                          Text(
                            '${question.answerOptions.length} options',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        question.content,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
