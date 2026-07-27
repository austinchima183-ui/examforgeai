import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';

/// List of mock exams filtered by exam body, level, and subject.
///
/// Features:
/// - Filter chips for exam body type
/// - Search bar for exam title
/// - Mock exam cards with status, duration, question count
/// - Pull-to-refresh
class MockExamListPage extends ConsumerStatefulWidget {
  const MockExamListPage({super.key});

  @override
  ConsumerState<MockExamListPage> createState() => _MockExamListPageState();
}

class _MockExamListPageState extends ConsumerState<MockExamListPage> {
  ExamBodyType? _selectedBodyType;
  MockExamStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examEcosystemProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ecoState = ref.watch(examEcosystemProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final filteredExams = _applyFilters(ecoState.mockExams);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Exams'),
      ),
      body: Column(
        children: [
          // ─── Search Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search mock exams...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                ),
                contentPadding: Spacings.paddingInput,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // ─── Filter Chips ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Body',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        selected: _selectedBodyType == null,
                        onSelected: () {
                          setState(() => _selectedBodyType = null);
                        },
                      ),
                      ...ExamBodyType.values.map(
                        (type) => _buildFilterChip(
                          label: type.label,
                          selected: _selectedBodyType == type,
                          onSelected: () {
                            setState(() => _selectedBodyType = type);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        label: 'All Status',
                        selected: _selectedStatus == null,
                        onSelected: () {
                          setState(() => _selectedStatus = null);
                        },
                      ),
                      ...MockExamStatus.values.map(
                        (status) => _buildFilterChip(
                          label: status.label,
                          selected: _selectedStatus == status,
                          onSelected: () {
                            setState(() => _selectedStatus = status);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Results Count ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredExams.length} mock exam${filteredExams.length != 1 ? 's' : ''}',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Exam List ──────────────────────────────────────────────
          Expanded(
            child: ecoState.isLoading && ecoState.mockExams.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : filteredExams.isEmpty
                    ? AppEmptyState(
                        icon: Icons.quiz_outlined,
                        title: 'No Mock Exams',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'Try a different search term'
                            : 'No exams match your current filters',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.lg,
                          vertical: Spacings.sm,
                        ),
                        itemCount: filteredExams.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacings.sm),
                        itemBuilder: (context, index) {
                          return _buildMockExamCard(
                            context,
                            filteredExams[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<MockExam> _applyFilters(List<MockExam> exams) {
    var filtered = exams;

    if (_selectedBodyType != null) {
      filtered = filtered
          .where((e) => e.examBodyType == _selectedBodyType)
          .toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered
          .where((e) => e.status == _selectedStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(query) ||
              (e.description?.toLowerCase().contains(query) ?? false),)
          .toList();
    }

    return filtered;
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Spacings.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildMockExamCard(BuildContext context, MockExam exam) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: exam.isPublished
            ? () {/* Navigate to take exam */}
            : null,
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(exam.status),
                ],
              ),
              if (exam.description != null) ...[
                const SizedBox(height: Spacings.xs),
                Text(
                  exam.description!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: Spacings.md),
              Wrap(
                spacing: Spacings.md,
                runSpacing: Spacings.xs,
                children: [
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${exam.durationMinutes} min',
                  ),
                  _InfoChip(
                    icon: Icons.help_outline_rounded,
                    label: '${exam.totalQuestions} Qs',
                  ),
                  _InfoChip(
                    icon: Icons.stars_outlined,
                    label: '${exam.totalMarks} marks',
                  ),
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: exam.examBodyType.label,
                  ),
                ],
              ),
              if (exam.isPublished) ...[
                const SizedBox(height: Spacings.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {/* Start exam */},
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Exam'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(MockExamStatus status) {
    Color color;
    switch (status) {
      case MockExamStatus.published:
        color = AppColors.success;
        break;
      case MockExamStatus.inProgress:
        color = AppColors.info;
        break;
      case MockExamStatus.completed:
        color = AppColors.warning;
        break;
      case MockExamStatus.draft:
        color = Colors.grey;
        break;
      case MockExamStatus.archived:
        color = Colors.grey.shade600;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: Spacings.borderRadiusFull,
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
