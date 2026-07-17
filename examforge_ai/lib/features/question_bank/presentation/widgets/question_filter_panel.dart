import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/repositories/question_bank_repository.dart';
import '../providers/question_filter_provider.dart';

// ─── QuestionFilterPanel ──────────────────────────────────────────────────────

/// An expandable/collapsible filter panel for the question bank. Provides
/// dropdowns for subject, topic, subtopic, difficulty, question type, exam
/// type, academic session, category, tags multi-select, and sort-by.
///
/// Shows an active filters count badge, a clear-all button, and an apply
/// button. Uses [QuestionFilterNotifier] from the provider layer.
///
/// ```dart
/// QuestionFilterPanel()
/// ```
class QuestionFilterPanel extends ConsumerStatefulWidget {
  const QuestionFilterPanel({super.key});

  @override
  ConsumerState<QuestionFilterPanel> createState() =>
      _QuestionFilterPanelState();
}

class _QuestionFilterPanelState extends ConsumerState<QuestionFilterPanel> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Load filter metadata on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionFilterProvider.notifier).loadFilterMetadata();
    });
  }

  QuestionFilterNotifier get _notifier =>
      ref.read(questionFilterProvider.notifier);

  QuestionFilterState get _state => ref.read(questionFilterProvider);

  int get _activeFilterCount {
    final f = _state.filter;
    int count = 0;
    if (f.subjectId != null) count++;
    if (f.topicId != null) count++;
    if (f.subtopicId != null) count++;
    if (f.difficulty != null) count++;
    if (f.questionType != null) count++;
    if (f.examType != null) count++;
    if (f.academicSessionId != null) count++;
    if (f.categoryId != null) count++;
    if (f.tags.isNotEmpty) count++;
    if (f.sortBy != 'newest') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final activeCount = _activeFilterCount;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle Header ────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Padding(
              padding: const EdgeInsets.all(Spacings.md),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Filters',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: Spacings.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        '$activeCount',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: AppTypography.wBold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable Body ──────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFilterBody(),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ─── Filter Body ──────────────────────────────────────────────────

  Widget _buildFilterBody() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final filter = _state.filter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacings.lg,
        0,
        Spacings.lg,
        Spacings.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: Spacings.lg),

          // ── Subject & Topic Row ───────────────────────────────────
          _buildResponsiveRow([
            _buildSubjectDropdown(),
            _buildTopicDropdown(),
          ]),

          const SizedBox(height: Spacings.md),

          // ── Subtopic & Category Row ───────────────────────────────
          _buildResponsiveRow([
            _buildSubtopicDropdown(),
            _buildCategoryDropdown(),
          ]),

          const SizedBox(height: Spacings.md),

          // ── Difficulty & Question Type Row ────────────────────────
          _buildResponsiveRow([
            _buildDifficultyDropdown(),
            _buildQuestionTypeDropdown(),
          ]),

          const SizedBox(height: Spacings.md),

          // ── Exam Type & Session Row ───────────────────────────────
          _buildResponsiveRow([
            _buildExamTypeDropdown(),
            _buildSessionDropdown(),
          ]),

          const SizedBox(height: Spacings.md),

          // ── Sort By ───────────────────────────────────────────────
          _buildSortByDropdown(),

          const SizedBox(height: Spacings.md),

          // ── Tags Multi-Select ─────────────────────────────────────
          _buildTagsSection(),

          const SizedBox(height: Spacings.xl),

          // ── Action Buttons ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Clear All',
                onPressed: () => _notifier.clearAllFilters(),
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: 'Apply Filters',
                onPressed: () {
                  // The filter is already applied reactively via the provider.
                  // This button can close the panel.
                  setState(() => _isExpanded = false);
                },
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Responsive Row Helper ────────────────────────────────────────

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

  // ─── Dropdown Builders ────────────────────────────────────────────

  Widget _buildSubjectDropdown() {
    return AppDropdownField<TopicEntity>(
      label: 'Subject',
      items: _state.availableSubjects,
      selectedItem: _state.availableSubjects.any((s) => s.id == _state.filter.subjectId)
          ? _state.availableSubjects.firstWhere((s) => s.id == _state.filter.subjectId)
          : null,
      onChanged: (item) => _notifier.updateSubject(item?.id),
      itemLabel: (s) => s.name,
      prefixIcon: Icons.book_outlined,
    );
  }

  Widget _buildTopicDropdown() {
    return AppDropdownField<TopicEntity>(
      label: 'Topic',
      items: _state.availableTopics,
      selectedItem: _state.availableTopics.any((t) => t.id == _state.filter.topicId)
          ? _state.availableTopics.firstWhere((t) => t.id == _state.filter.topicId)
          : null,
      onChanged: (item) => _notifier.updateTopic(item?.id),
      itemLabel: (t) => t.name,
      prefixIcon: Icons.topic_outlined,
      isEnabled: _state.filter.subjectId != null,
    );
  }

  Widget _buildSubtopicDropdown() {
    return AppDropdownField<SubtopicEntity>(
      label: 'Subtopic',
      items: _state.availableSubtopics,
      selectedItem: _state.availableSubtopics.any((s) => s.id == _state.filter.subtopicId)
          ? _state.availableSubtopics.firstWhere((s) => s.id == _state.filter.subtopicId)
          : null,
      onChanged: (item) => _notifier.updateSubtopic(item?.id),
      itemLabel: (s) => s.name,
      prefixIcon: Icons.subdirectory_arrow_right_rounded,
      isEnabled: _state.filter.topicId != null,
    );
  }

  Widget _buildCategoryDropdown() {
    return AppDropdownField<QuestionCategoryEntity>(
      label: 'Category',
      items: _state.availableCategories,
      selectedItem: _state.availableCategories.any((c) => c.id == _state.filter.categoryId)
          ? _state.availableCategories.firstWhere((c) => c.id == _state.filter.categoryId)
          : null,
      onChanged: (item) => _notifier.updateCategory(item?.id),
      itemLabel: (c) => c.name,
      prefixIcon: Icons.category_outlined,
    );
  }

  Widget _buildDifficultyDropdown() {
    return AppDropdownField<DifficultyLevel>(
      label: 'Difficulty',
      items: DifficultyLevel.values,
      selectedItem: _state.filter.difficulty,
      onChanged: (d) => _notifier.updateDifficulty(d),
      itemLabel: (d) => d.label,
      prefixIcon: Icons.signal_cellular_alt_rounded,
    );
  }

  Widget _buildQuestionTypeDropdown() {
    return AppDropdownField<QuestionType>(
      label: 'Question Type',
      items: QuestionType.values,
      selectedItem: _state.filter.questionType,
      onChanged: (t) => _notifier.updateQuestionType(t),
      itemLabel: (t) => t.label,
      prefixIcon: Icons.quiz_outlined,
    );
  }

  Widget _buildExamTypeDropdown() {
    return AppDropdownField<ExamType>(
      label: 'Exam Type',
      items: ExamType.values,
      selectedItem: _state.filter.examType,
      onChanged: (e) => _notifier.updateExamType(e),
      itemLabel: (e) => e.label,
      prefixIcon: Icons.school_outlined,
    );
  }

  Widget _buildSessionDropdown() {
    return AppDropdownField<AcademicSessionEntity>(
      label: 'Academic Session',
      items: _state.availableSessions,
      selectedItem: _state.availableSessions.any((s) => s.id == _state.filter.academicSessionId)
          ? _state.availableSessions.firstWhere((s) => s.id == _state.filter.academicSessionId)
          : null,
      onChanged: (item) => _notifier.updateAcademicSession(item?.id),
      itemLabel: (s) => s.name,
      prefixIcon: Icons.calendar_today_outlined,
    );
  }

  Widget _buildSortByDropdown() {
    const sortOptions = [
      ('newest', 'Newest First'),
      ('oldest', 'Oldest First'),
      ('most_used', 'Most Used'),
      ('least_used', 'Least Used'),
      ('highest_rated', 'Highest Rated'),
      ('a_z', 'A → Z'),
      ('z_a', 'Z → A'),
    ];

    final currentSort = _state.filter.sortBy;
    final selectedItem = sortOptions
        .where((o) => o.$1 == currentSort)
        .firstOrNull;

    return AppDropdownField<String>(
      label: 'Sort By',
      items: sortOptions.map((o) => o.$1).toList(),
      selectedItem: selectedItem?.$1,
      onChanged: (v) {
        if (v != null) _notifier.updateSortBy(v);
      },
      itemLabel: (key) => sortOptions.firstWhere((o) => o.$1 == key).$2,
      prefixIcon: Icons.sort_rounded,
    );
  }

  // ─── Tags Section ─────────────────────────────────────────────────

  Widget _buildTagsSection() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selectedTags = _state.filter.tags;
    final availableTags = _state.availableTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: AppTypography.wMedium,
          ),
        ),
        const SizedBox(height: Spacings.sm),

        // Selected tags as chips
        if (selectedTags.isNotEmpty)
          Wrap(
            spacing: Spacings.xs,
            runSpacing: Spacings.xs,
            children: selectedTags.map((tag) {
              return Chip(
                label: Text(tag, style: tt.bodySmall),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: Spacings.smIcon,
                ),
                onDeleted: () => _notifier.removeTag(tag),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),

        const SizedBox(height: Spacings.sm),

        // Available tags to add
        if (availableTags.isNotEmpty)
          Wrap(
            spacing: Spacings.xs,
            runSpacing: Spacings.xs,
            children: availableTags
                .where((t) => !selectedTags.contains(t.name))
                .map((tag) {
              return ActionChip(
                label: Text(
                  tag.name,
                  style: tt.bodySmall?.copyWith(color: cs.primary),
                ),
                onPressed: () => _notifier.addTag(tag.name),
                avatar: Icon(
                  Icons.add_rounded,
                  size: Spacings.smIcon,
                  color: cs.primary,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─── Provider Placeholder ─────────────────────────────────────────────────────
//
/// Riverpod provider for the question filter state.
/// This must be overridden in the DI / provider setup with a real
/// [QuestionBankRepository] dependency. Using an override:
///
/// ```dart
/// overrides: [
///   questionFilterProvider.overrideWithValue(
///     QuestionFilterNotifier(repository: myRepo),
///   ),
/// ]
/// ```
final questionFilterProvider =
    StateNotifierProvider<QuestionFilterNotifier, QuestionFilterState>(
  (ref) => QuestionFilterNotifier(
    repository: _PlaceholderRepository(),
  ),
);

/// Minimal placeholder repository so the provider can compile.
/// Override [questionFilterProvider] in your app's provider scope.
class _PlaceholderRepository implements QuestionBankRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
