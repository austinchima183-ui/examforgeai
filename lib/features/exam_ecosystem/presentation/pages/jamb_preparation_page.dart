import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/exam_ecosystem_entities.dart';
import '../providers/exam_ecosystem_provider.dart';
import '../widgets/readiness_score_ring.dart';
import '../widgets/study_streak_badge.dart';

/// Dedicated JAMB UTME preparation page with subject combinations.
///
/// Features:
/// - JAMB-specific subject combination selector
/// - Readiness score for JAMB
/// - Subject-by-subject breakdown
/// - JAMB-specific tips and resources
/// - Practice mode shortcuts
/// - Study plan integration
class JambPreparationPage extends ConsumerStatefulWidget {
  const JambPreparationPage({super.key});

  @override
  ConsumerState<JambPreparationPage> createState() =>
      _JambPreparationPageState();
}

class _JambPreparationPageState extends ConsumerState<JambPreparationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Common JAMB subject combinations
  static const _subjectCombinations = [
    _SubjectCombination(
      name: 'Science / Medicine',
      subjects: ['English', 'Physics', 'Chemistry', 'Biology'],
      courses: ['Medicine', 'Pharmacy', 'Nursing', 'Biochemistry'],
      color: Color(0xFF16A34A),
    ),
    _SubjectCombination(
      name: 'Engineering / Technology',
      subjects: ['English', 'Mathematics', 'Physics', 'Chemistry'],
      courses: ['Civil Engineering', 'Electrical Engineering', 'Mechanical Engineering', 'Computer Science'],
      color: Color(0xFF2563EB),
    ),
    _SubjectCombination(
      name: 'Arts / Law',
      subjects: ['English', 'Government', 'Literature', 'CRS/IRS'],
      courses: ['Law', 'Political Science', 'International Relations', 'Mass Communication'],
      color: Color(0xFF8B5CF6),
    ),
    _SubjectCombination(
      name: 'Social Sciences',
      subjects: ['English', 'Mathematics', 'Economics', 'Government'],
      courses: ['Economics', 'Accounting', 'Business Admin', 'Banking & Finance'],
      color: Color(0xFFF59E0B),
    ),
    _SubjectCombination(
      name: 'Management Sciences',
      subjects: ['English', 'Mathematics', 'Economics', 'Accounting'],
      courses: ['Business Admin', 'Accounting', 'Marketing', 'Public Admin'],
      color: Color(0xFFEC4899),
    ),
  ];

  _SubjectCombination? _selectedCombination;
  final Set<String> _selectedSubjects = {'English'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examEcosystemProvider.notifier).loadAll();
      ref.read(readinessProvider.notifier).loadReadiness();
      ref.read(studyPlanProvider.notifier).loadPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ecoState = ref.watch(examEcosystemProvider);
    final readinessState = ref.watch(readinessProvider);
    final planState = ref.watch(studyPlanProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JAMB UTME Prep'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Subjects'),
            Tab(text: 'Practice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── OVERVIEW TAB ──────────────────────────────────────────
          _buildOverviewTab(context, readinessState, planState),

          // ─── SUBJECTS TAB ──────────────────────────────────────────
          _buildSubjectsTab(context),

          // ─── PRACTICE TAB ──────────────────────────────────────────
          _buildPracticeTab(context, ecoState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    ReadinessState readinessState,
    StudyPlanState planState,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── JAMB Info Card ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: Spacings.paddingCard,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: Spacings.borderRadiusLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JAMB UTME',
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: AppTypography.wBold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Unified Tertiary Matriculation Examination',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _JambStat(label: 'Duration', value: '2 hrs'),
                    _JambStat(label: 'Questions', value: '180'),
                    _JambStat(label: 'Subjects', value: '4'),
                    _JambStat(label: 'Format', value: 'CBT'),
                  ],
                ),
              ],
            ),
          ),
          Spacings.sectionGap,

          // ─── Readiness & Streak ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ReadinessScoreRing(
                  score: readinessState.overallReadinessScore,
                  level: readinessState.overallReadinessLevel,
                  size: 120,
                  label: 'JAMB Readiness',
                ),
              ),
              const SizedBox(width: Spacings.lg),
              Expanded(
                child: Column(
                  children: [
                    StudyStreakBadge(
                      streak: planState.currentStreak,
                      label: 'Study Streak',
                    ),
                    const SizedBox(height: Spacings.sm),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        ref.read(readinessProvider.notifier).calculateReadiness(
                              examBodyId: 'jamb',
                            );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Recalculate'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacings.sectionGap,

          // ─── JAMB Tips ───────────────────────────────────────────
          Text(
            'JAMB Preparation Tips',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...[
            'English is compulsory — practice comprehension and lexis',
            'Manage your time: ~40 seconds per question',
            'Use the elimination method for difficult questions',
            'Practice with past questions under timed conditions',
            'Focus on your weak subjects first',
          ].map((tip) => ListTile(
                dense: true,
                leading: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                title: Text(tip, style: tt.bodySmall),
                contentPadding: EdgeInsets.zero,
              ),),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Subject Combination Selector ──────────────────────────
          Text(
            'Select Your Subject Combination',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Choose a preset or select subjects manually. '
            'English Language is compulsory.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Spacings.md),

          // ─── Combination Cards ─────────────────────────────────────
          ..._subjectCombinations.map(
            (combo) => _buildCombinationCard(context, combo),
          ),
          Spacings.sectionGap,

          // ─── Selected Subjects ─────────────────────────────────────
          Text(
            'Your Selected Subjects',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: _selectedSubjects.map((subject) {
              return Chip(
                label: Text(subject),
                deleteIcon: subject != 'English'
                    ? const Icon(Icons.close_rounded, size: 16)
                    : null,
                onDeleted: subject != 'English'
                    ? () {
                        setState(() => _selectedSubjects.remove(subject));
                      }
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          if (_selectedSubjects.length < 4)
            Padding(
              padding: const EdgeInsets.only(top: Spacings.sm),
              child: Text(
                'Select ${4 - _selectedSubjects.length} more subject${4 - _selectedSubjects.length != 1 ? 's' : ''}',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),

          // ─── Available Subjects ────────────────────────────────────
          Spacings.sectionGap,
          Text(
            'Available JAMB Subjects',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              'English',
              'Mathematics',
              'Physics',
              'Chemistry',
              'Biology',
              'Economics',
              'Government',
              'Literature',
              'CRS/IRS',
              'Accounting',
              'Geography',
              'Agricultural Science',
              'Commerce',
              'History',
              'French',
              'Yoruba',
              'Igbo',
              'Hausa',
              'Music',
              'Fine Art',
              'Arabic',
            ].map((subject) {
              final isSelected = _selectedSubjects.contains(subject);
              final isEnglish = subject == 'English';
              return FilterChip(
                label: Text(subject),
                selected: isSelected,
                onSelected: isEnglish
                    ? null
                    : (selected) {
                        setState(() {
                          if (selected && _selectedSubjects.length < 4) {
                            _selectedSubjects.add(subject);
                          } else {
                            _selectedSubjects.remove(subject);
                          }
                        });
                      },
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinationCard(
    BuildContext context,
    _SubjectCombination combo,
  ) {
    final isSelected = _selectedCombination?.name == combo.name;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: isSelected
            ? BorderSide(color: combo.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCombination = combo;
            _selectedSubjects.clear();
            _selectedSubjects.addAll(combo.subjects);
          });
        },
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: combo.color,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      combo.name,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: combo.color),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Wrap(
                spacing: Spacings.xs,
                runSpacing: Spacings.xs,
                children: combo.subjects.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: combo.color.withValues(alpha: 0.1),
                      borderRadius: Spacings.borderRadiusFull,
                    ),
                    child: Text(
                      s,
                      style: tt.labelSmall?.copyWith(
                        color: combo.color,
                        fontWeight: AppTypography.wMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                'Courses: ${combo.courses.take(3).join(', ')}${combo.courses.length > 3 ? '...' : ''}',
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeTab(BuildContext context, ExamEcosystemState ecoState) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Filter JAMB-related mock exams
    final jambExams = ecoState.mockExams
        .where((e) => e.examBodyType == ExamBodyType.jambUme)
        .toList();

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Quick Practice ───────────────────────────────────────
          Text(
            'Quick Practice',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Expanded(
                child: _PracticeCard(
                  icon: Icons.timer_rounded,
                  title: 'Timed Practice',
                  subtitle: '40 min session',
                  color: AppColors.info,
                  onTap: () {/* Navigate to timed practice */},
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: _PracticeCard(
                  icon: Icons.topic_rounded,
                  title: 'Topic Practice',
                  subtitle: 'Focus on weak areas',
                  color: AppColors.success,
                  onTap: () {/* Navigate to topic practice */},
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Expanded(
                child: _PracticeCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI Revision',
                  subtitle: 'Smart review',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {/* Navigate to AI revision */},
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: _PracticeCard(
                  icon: Icons.assignment_rounded,
                  title: 'Full Mock',
                  subtitle: '2 hour exam',
                  color: AppColors.warning,
                  onTap: () {/* Navigate to full mock */},
                ),
              ),
            ],
          ),
          Spacings.sectionGap,

          // ─── Available JAMB Mocks ─────────────────────────────────
          Text(
            'JAMB Mock Exams',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          if (jambExams.isEmpty)
            const AppEmptyState(
              icon: Icons.quiz_outlined,
              title: 'No JAMB Mocks',
              subtitle: 'JAMB mock exams will appear here when available.',
            )
          else
            ...jambExams.map((exam) => Card(
                  margin: const EdgeInsets.only(bottom: Spacings.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.info.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: AppColors.info,
                      ),
                    ),
                    title: Text(exam.title),
                    subtitle: Text(
                      '${exam.totalQuestions} questions · ${exam.durationMinutes} min',
                    ),
                    trailing: exam.isPublished
                        ? FilledButton.tonal(
                            onPressed: () {/* Start exam */},
                            child: const Text('Start'),
                          )
                        : null,
                    onTap: exam.isPublished
                        ? () {/* Navigate to exam */ }
                        : null,
                  ),
                ),),
        ],
      ),
    );
  }
}

class _JambStat extends StatelessWidget {
  const _JambStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wBold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: Spacings.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: Spacings.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCombination {
  const _SubjectCombination({
    required this.name,
    required this.subjects,
    required this.courses,
    required this.color,
  });

  final String name;
  final List<String> subjects;
  final List<String> courses;
  final Color color;
}
