import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';

/// Collapsible filter panel with dropdowns and search.
///
/// Features:
/// - Dropdown for Subject
/// - Dropdown for Educational Level
/// - Dropdown for Topic
/// - Dropdown for Content Type
/// - Dropdown for Difficulty
/// - Dropdown for Status
/// - Search text field
/// - Apply / Clear buttons
/// - onFiltersChanged callback
class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.subjects,
    required this.levels,
    required this.topics,
    this.selectedSubjectId,
    this.selectedLevelId,
    this.selectedTopicId,
    this.selectedContentType,
    this.selectedDifficulty,
    this.selectedStatus,
    this.searchQuery,
    this.onSubjectChanged,
    this.onLevelChanged,
    this.onTopicChanged,
    this.onContentTypeChanged,
    this.onDifficultyChanged,
    this.onStatusChanged,
    this.onSearchChanged,
    this.onApplyFilters,
    this.onClearFilters,
  });

  /// Available subjects for the dropdown.
  final List<Subject> subjects;

  /// Available educational levels for the dropdown.
  final List<EducationalLevel> levels;

  /// Available topics for the dropdown.
  final List<Topic> topics;

  /// Currently selected subject ID.
  final String? selectedSubjectId;

  /// Currently selected level ID.
  final String? selectedLevelId;

  /// Currently selected topic ID.
  final String? selectedTopicId;

  /// Currently selected content type.
  final ContentType? selectedContentType;

  /// Currently selected difficulty level.
  final DifficultyLevel? selectedDifficulty;

  /// Currently selected status.
  final ContentStatus? selectedStatus;

  /// Current search query text.
  final String? searchQuery;

  /// Callback when subject filter changes.
  final ValueChanged<String?>? onSubjectChanged;

  /// Callback when level filter changes.
  final ValueChanged<String?>? onLevelChanged;

  /// Callback when topic filter changes.
  final ValueChanged<String?>? onTopicChanged;

  /// Callback when content type filter changes.
  final ValueChanged<ContentType?>? onContentTypeChanged;

  /// Callback when difficulty filter changes.
  final ValueChanged<DifficultyLevel?>? onDifficultyChanged;

  /// Callback when status filter changes.
  final ValueChanged<ContentStatus?>? onStatusChanged;

  /// Callback when search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Callback when the Apply button is pressed.
  final VoidCallback? onApplyFilters;

  /// Callback when the Clear button is pressed.
  final VoidCallback? onClearFilters;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  bool _isExpanded = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Count the number of active filters.
  int get _activeFilterCount {
    int count = 0;
    if (widget.selectedSubjectId != null) count++;
    if (widget.selectedLevelId != null) count++;
    if (widget.selectedTopicId != null) count++;
    if (widget.selectedContentType != null) count++;
    if (widget.selectedDifficulty != null) count++;
    if (widget.selectedStatus != null) count++;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final activeCount = _activeFilterCount;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: Spacings.borderRadiusSm,
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
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
                      borderRadius: Spacings.borderRadiusFull,
                    ),
                    child: Text(
                      '$activeCount',
                      style: AppTypography.labelSmall.copyWith(
                        color: cs.primary,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                // Clear button
                if (widget.onClearFilters != null && activeCount > 0)
                  TextButton(
                    onPressed: widget.onClearFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: tt.labelMedium?.copyWith(color: cs.primary),
                    ),
                  ),

                // Expand/collapse icon
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded content ─────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: Spacings.lg),

                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search content...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged?.call('');
                            },
                          )
                        : null,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: Spacings.paddingInput,
                  ),
                  style: tt.bodyMedium,
                  onChanged: widget.onSearchChanged,
                ),
                const SizedBox(height: Spacings.md),

                // Filter dropdowns
                Wrap(
                  spacing: Spacings.md,
                  runSpacing: Spacings.md,
                  children: [
                    _buildEntityDropdown<Subject>(
                      label: 'Subject',
                      items: widget.subjects,
                      selectedId: widget.selectedSubjectId,
                      labelBuilder: (s) => s.name,
                      onChanged: widget.onSubjectChanged,
                    ),
                    _buildEntityDropdown<EducationalLevel>(
                      label: 'Educational Level',
                      items: widget.levels,
                      selectedId: widget.selectedLevelId,
                      labelBuilder: (l) => l.name,
                      onChanged: widget.onLevelChanged,
                    ),
                    _buildEntityDropdown<Topic>(
                      label: 'Topic',
                      items: widget.topics,
                      selectedId: widget.selectedTopicId,
                      labelBuilder: (t) => t.title,
                      onChanged: widget.onTopicChanged,
                    ),
                    _buildEnumDropdown<ContentType>(
                      label: 'Content Type',
                      values: ContentType.values,
                      selected: widget.selectedContentType,
                      labelBuilder: (t) => t.label,
                      onChanged: widget.onContentTypeChanged,
                    ),
                    _buildEnumDropdown<DifficultyLevel>(
                      label: 'Difficulty',
                      values: DifficultyLevel.values,
                      selected: widget.selectedDifficulty,
                      labelBuilder: (d) => d.label,
                      onChanged: widget.onDifficultyChanged,
                    ),
                    _buildEnumDropdown<ContentStatus>(
                      label: 'Status',
                      values: ContentStatus.values,
                      selected: widget.selectedStatus,
                      labelBuilder: (s) => s.label,
                      onChanged: widget.onStatusChanged,
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.lg),

                // Apply / Clear buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onClearFilters != null)
                      AppButton(
                        label: 'Clear All',
                        onPressed: widget.onClearFilters,
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.small,
                      ),
                    const SizedBox(width: Spacings.sm),
                    if (widget.onApplyFilters != null)
                      AppButton(
                        label: 'Apply Filters',
                        onPressed: widget.onApplyFilters,
                        variant: AppButtonVariant.elevated,
                        icon: Icons.check_rounded,
                        size: AppButtonSize.small,
                      ),
                  ],
                ),
              ],
            ),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ─── Dropdown Builders ──────────────────────────────────────────────────

  Widget _buildEntityDropdown<T>({
    required String label,
    required List<T> items,
    required String? selectedId,
    required String Function(T) labelBuilder,
    required ValueChanged<String?>? onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: Spacings.paddingInput,
        ),
        value: selectedId,
        hint: const Text('All'),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All'),
          ),
          ...items.map(
            (item) => DropdownMenuItem(
              value: (item as dynamic).id as String,
              child: Text(
                labelBuilder(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEnumDropdown<T>({
    required String label,
    required List<T> values,
    required T? selected,
    required String Function(T) labelBuilder,
    required ValueChanged<T?>? onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: Spacings.paddingInput,
        ),
        value: selected,
        hint: const Text('All'),
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: const Text('All'),
          ),
          ...values.map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(labelBuilder(v)),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
