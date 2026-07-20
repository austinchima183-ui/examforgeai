import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../providers/admission_hub_provider.dart';
import '../widgets/admission_hub_widgets.dart';

/// Admission eligibility checker page.
///
/// Features:
/// - Select university and department
/// - Input JAMB score
/// - Input O'Level results (subject + grade)
/// - Select UTME subject combination
/// - Run eligibility check
/// - Display eligibility result with recommendations
class AdmissionCheckerPage extends ConsumerStatefulWidget {
  const AdmissionCheckerPage({super.key, this.preselectedUniversityId});

  final String? preselectedUniversityId;

  @override
  ConsumerState<AdmissionCheckerPage> createState() =>
      _AdmissionCheckerPageState();
}

class _AdmissionCheckerPageState
    extends ConsumerState<AdmissionCheckerPage> {
  final _formKey = GlobalKey<FormState>();
  final _jambScoreController = TextEditingController();

  String? _selectedUniversityId;
  String? _selectedDepartmentId;
  final List<Map<String, dynamic>> _oLevelResults = [];
  final List<String> _selectedSubjects = [];

  // O'Level subjects and grades
  static const _oLevelSubjects = [
    'Mathematics', 'English Language', 'Physics', 'Chemistry',
    'Biology', 'Economics', 'Government', 'Literature in English',
    'Geography', 'History', 'Agricultural Science', 'Computer Studies',
    'Further Mathematics', 'Technical Drawing', 'Commerce',
    'Accounting', 'Yoruba', 'Igbo', 'Hausa', 'French',
    'Christian Religious Studies', 'Islamic Religious Studies',
    'Civic Education', 'Visual Art', 'Music',
  ];

  static const _oLevelGrades = [
    'A1', 'B2', 'B3', 'C4', 'C5', 'C6', 'D7', 'E8', 'F9',
  ];

  static const _utmeSubjects = [
    'English Language', 'Mathematics', 'Physics', 'Chemistry',
    'Biology', 'Economics', 'Government', 'Literature in English',
    'Geography', 'History', 'Agricultural Science', 'Computer Studies',
    'Further Mathematics', 'Commerce', 'Accounting',
    'Christian Religious Studies', 'Islamic Religious Studies',
    'Yoruba', 'Igbo', 'Hausa', 'French',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(admissionHubProvider.notifier).loadUniversities();
      if (widget.preselectedUniversityId != null) {
        setState(() {
          _selectedUniversityId = widget.preselectedUniversityId;
        });
        _loadDepartments(widget.preselectedUniversityId!);
      }
    });
  }

  @override
  void dispose() {
    _jambScoreController.dispose();
    super.dispose();
  }

  void _loadDepartments(String universityId) {
    ref.read(admissionHubProvider.notifier).loadDepartments(universityId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(admissionHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Checker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Info Banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter your details to check your admission eligibility for a specific university and department.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── University Selection ─────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedUniversityId,
                decoration: InputDecoration(
                  labelText: 'University',
                  prefixIcon: const Icon(Icons.school_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: state.universities.map((u) {
                  return DropdownMenuItem<String>(
                    value: u.id,
                    child: Text(
                      u.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedUniversityId = id;
                    _selectedDepartmentId = null;
                  });
                  if (id != null) _loadDepartments(id);
                },
                validator: (v) =>
                    v == null ? 'Please select a university' : null,
              ),
              const SizedBox(height: 16),

              // ─── Department Selection ─────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedDepartmentId,
                decoration: InputDecoration(
                  labelText: 'Department / Course',
                  prefixIcon: const Icon(Icons.book_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: state.departments.map((d) {
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(
                      '${d.name} (${d.degreeType ?? "B.Sc"})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  setState(() => _selectedDepartmentId = id);
                },
                validator: (v) =>
                    v == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 16),

              // ─── JAMB Score ───────────────────────────────────────────
              TextFormField(
                controller: _jambScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'JAMB Score',
                  prefixIcon: const Icon(Icons.score_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your JAMB score (0-400)',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter JAMB score';
                  final score = double.tryParse(v);
                  if (score == null) return 'Enter a valid number';
                  if (score < 0 || score > 400) return 'Score must be 0-400';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── UTME Subject Combination ─────────────────────────────
              Text(
                'UTME Subject Combination',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _utmeSubjects.map((subject) {
                  final isSelected = _selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedSubjects.length < 4) {
                            _selectedSubjects.add(subject);
                          }
                        } else {
                          _selectedSubjects.remove(subject);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ─── O'Level Results ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "O'Level Results",
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addOLevelResult,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Subject'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_oLevelResults.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "No O'Level subjects added yet. Tap 'Add Subject' to begin.",
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._oLevelResults.asMap().entries.map((entry) {
                  final index = entry.key;
                  final result = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(result['subject'] as String),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(result['grade'] as String)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result['grade'] as String,
                              style: context.textTheme.labelLarge?.copyWith(
                                color: _getGradeColor(result['grade'] as String),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() => _oLevelResults.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // ─── Check Eligibility Button ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: state.isCheckingEligibility ? null : _checkEligibility,
                  icon: state.isCheckingEligibility
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: Text(
                    state.isCheckingEligibility
                        ? 'Checking...'
                        : 'Check Eligibility',
                  ),
                ),
              ),

              // ─── Eligibility Result ───────────────────────────────────
              if (state.eligibilityResult != null) ...[
                const SizedBox(height: 24),
                EligibilityResultCard(
                  result: state.eligibilityResult!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _addOLevelResult() {
    String? subject;
    String? grade;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add O'Level Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: subject,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                ),
                items: _oLevelSubjects.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (v) => setDialogState(() => subject = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: grade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                ),
                items: _oLevelGrades.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (v) => setDialogState(() => grade = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (subject != null && grade != null) {
                  setState(() {
                    _oLevelResults.add({
                      'subject': subject,
                      'grade': grade,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkEligibility() {
    if (!_formKey.currentState!.validate()) return;

    final jambScore = double.tryParse(_jambScoreController.text) ?? 0;

    ref.read(admissionHubProvider.notifier).checkEligibility(
          universityId: _selectedUniversityId!,
          departmentId: _selectedDepartmentId!,
          jambScore: jambScore,
          oLevelResults: _oLevelResults,
          selectedSubjects:
              _selectedSubjects.isNotEmpty ? _selectedSubjects : null,
        );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A1':
      case 'B2':
      case 'B3':
        return AppColors.success;
      case 'C4':
      case 'C5':
      case 'C6':
        return AppColors.warning;
      case 'D7':
      case 'E8':
        return AppColors.error;
      case 'F9':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
