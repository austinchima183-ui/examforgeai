import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../providers/admission_hub_provider.dart';

/// Admission checklist page for tracking application progress.
///
/// Features:
/// - Checklist items with toggleable completion state
/// - Document tracking (uploaded, pending)
/// - Deadline reminders with countdown
/// - Overall readiness score ring
/// - Status indicators for each item
class AdmissionChecklistPage extends ConsumerStatefulWidget {
  const AdmissionChecklistPage({super.key});

  @override
  ConsumerState<AdmissionChecklistPage> createState() =>
      _AdmissionChecklistPageState();
}

class _AdmissionChecklistPageState
    extends ConsumerState<AdmissionChecklistPage> {
  String? _selectedUniversityId;
  String? _selectedDepartmentId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(admissionHubProvider);
    final checklist = state.checklist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Checklist'),
      ),
      body: Column(
        children: [
          // ─── Selection Row ────────────────────────────────────────────
          if (_selectedUniversityId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a university and department to view your checklist',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      if (id != null) {
                        ref
                            .read(admissionHubProvider.notifier)
                            .loadDepartments(id);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      prefixIcon: const Icon(Icons.book_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: state.departments.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() => _selectedDepartmentId = id);
                      if (id != null && _selectedUniversityId != null) {
                        ref.read(admissionHubProvider.notifier).loadChecklist(
                              universityId: _selectedUniversityId!,
                              departmentId: id,
                            );
                      }
                    },
                  ),
                ],
              ),
            ),

          // ─── Checklist Content ────────────────────────────────────────
          Expanded(
            child: _selectedUniversityId == null || _selectedDepartmentId == null
                ? const AppEmptyState(
                    icon: Icons.checklist_outlined,
                    title: 'Select a University',
                    message:
                        'Choose a university and department to see your admission checklist.',
                  )
                : state.isLoadingChecklist
                    ? const Center(child: AppLoadingSpinner())
                    : checklist == null
                        ? _buildDefaultChecklist(context)
                        : _buildChecklist(context, checklist),
          ),
        ],
      ),
    );
  }

  /// Builds a default checklist when none exists yet.
  Widget _buildDefaultChecklist(BuildContext context) {
    final defaultItems = [
      {'title': 'JAMB Registration', 'category': 'examination', 'is_required': true},
      {'title': 'JAMB Result', 'category': 'examination', 'is_required': true},
      {'title': 'Post-UTME Registration', 'category': 'examination', 'is_required': true},
      {'title': 'Post-UTME Result', 'category': 'examination', 'is_required': true},
      {'title': "O'Level Result (WAEC/NECO)", 'category': 'documents', 'is_required': true},
      {'title': 'Birth Certificate', 'category': 'documents', 'is_required': true},
      {'title': 'Passport Photograph', 'category': 'documents', 'is_required': true},
      {'title': 'Certificate of Origin', 'category': 'documents', 'is_required': true},
      {'title': 'JAMB Admission Letter', 'category': 'documents', 'is_required': false},
      {'title': 'Acceptance Fee Payment', 'category': 'payment', 'is_required': true},
      {'title': 'School Fees Payment', 'category': 'payment', 'is_required': true},
      {'title': 'Medical Clearance', 'category': 'clearance', 'is_required': true},
      {'title': 'Accommodation Application', 'category': 'other', 'is_required': false},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Readiness header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                '0%',
                style: context.textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admission Readiness',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${defaultItems.length} items to complete',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Checklist items
        ...defaultItems.map((item) => _ChecklistItemTile(
              title: item['title'] as String,
              category: item['category'] as String,
              isRequired: item['is_required'] as bool,
              isCompleted: false,
              onToggle: () {
                // Toggle completion via provider
              },
            )),
      ],
    );
  }

  /// Builds the checklist from loaded data.
  Widget _buildChecklist(BuildContext context, AdmissionChecklist checklist) {
    final completedIds = checklist.completedItems
        .map((item) => item['id'] as String?)
        .where((id) => id != null)
        .toSet();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Readiness Score
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${checklist.overallReadinessScore.toInt()}%',
                      style: context.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admission Readiness',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${checklist.completedItems.length} of ${checklist.checklistItems.length} completed',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: checklist.completionPct / 100,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      strokeWidth: 6,
                    ),
                    Center(
                      child: Icon(
                        checklist.overallReadinessScore >= 80
                            ? Icons.check_circle
                            : checklist.overallReadinessScore >= 50
                                ? Icons.trending_up
                                : Icons.pending_actions,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Deadlines section
        if (checklist.deadlines.isNotEmpty) ...[
          Text(
            'Upcoming Deadlines',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...checklist.deadlines.map((deadline) => _DeadlineCard(
                deadline: deadline,
              )),
          const SizedBox(height: 20),
        ],

        // Documents section
        if (checklist.documents.isNotEmpty) ...[
          Text(
            'Documents',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...checklist.documents.map((doc) => _DocumentTile(
                document: doc,
              )),
          const SizedBox(height: 20),
        ],

        // Checklist items
        Text(
          'Checklist Items',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...checklist.checklistItems.map((item) {
          final itemId = item['id'] as String?;
          final isCompleted =
              itemId != null && completedIds.contains(itemId);
          return _ChecklistItemTile(
            title: item['title'] as String? ?? 'Untitled',
            category: item['category'] as String? ?? 'other',
            isRequired: item['is_required'] as bool? ?? false,
            isCompleted: isCompleted,
            onToggle: () {
              _toggleItem(checklist, item);
            },
          );
        }),
      ],
    );
  }

  void _toggleItem(AdmissionChecklist checklist, Map<String, dynamic> item) {
    final itemId = item['id'] as String?;
    if (itemId == null) return;

    final completedItems = List<Map<String, dynamic>>.from(
      checklist.completedItems,
    );
    final existingIndex = completedItems.indexWhere(
      (ci) => ci['id'] == itemId,
    );

    if (existingIndex >= 0) {
      completedItems.removeAt(existingIndex);
    } else {
      completedItems.add(item);
    }

    final newScore = checklist.checklistItems.isEmpty
        ? 0.0
        : (completedItems.length / checklist.checklistItems.length) * 100;

    ref.read(admissionHubProvider.notifier).updateChecklist(
          checklistId: checklist.id,
          completedItems: completedItems,
          overallReadinessScore: newScore,
          status: newScore >= 100 ? 'completed' : 'in_progress',
        );
  }
}

/// Checklist item tile widget.
class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.title,
    required this.category,
    required this.isRequired,
    required this.isCompleted,
    required this.onToggle,
  });

  final String title;
  final String category;
  final bool isRequired;
  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isCompleted
            ? BorderSide(color: AppColors.success.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: AppColors.success,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          title,
          style: context.textTheme.bodyMedium?.copyWith(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted
                ? context.colorScheme.onSurfaceVariant
                : context.colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            _CategoryBadge(category: category),
            if (isRequired) ...[
              const SizedBox(width: 8),
              Text(
                'Required',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: isCompleted
            ? Icon(Icons.check_circle, color: AppColors.success, size: 20)
            : null,
      ),
    );
  }
}

/// Category badge widget.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  Color _getColor() {
    switch (category) {
      case 'examination':
        return AppColors.primary;
      case 'documents':
        return AppColors.info;
      case 'payment':
        return AppColors.warning;
      case 'clearance':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (category) {
      case 'examination':
        return Icons.quiz_outlined;
      case 'documents':
        return Icons.description_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'clearance':
        return Icons.verified_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deadline card widget.
class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.deadline});

  final Map<String, dynamic> deadline;

  @override
  Widget build(BuildContext context) {
    final title = deadline['title'] as String? ?? 'Deadline';
    final dateStr = deadline['date'] as String?;
    final isPast = dateStr != null &&
        DateTime.tryParse(dateStr)?.isBefore(DateTime.now()) == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPast ? AppColors.error.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          isPast ? Icons.event_busy : Icons.event_outlined,
          color: isPast ? AppColors.error : AppColors.warning,
        ),
        title: Text(title),
        subtitle: dateStr != null
            ? Text(
                dateStr,
                style: context.textTheme.bodySmall?.copyWith(
                  color: isPast ? AppColors.error : AppColors.warning,
                ),
              )
            : null,
        trailing: isPast
            ? Text(
                'Past',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

/// Document tile widget.
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final Map<String, dynamic> document;

  @override
  Widget build(BuildContext context) {
    final name = document['name'] as String? ?? 'Document';
    final status = document['status'] as String? ?? 'pending';
    final isUploaded = status == 'uploaded';

    return ListTile(
      dense: true,
      leading: Icon(
        isUploaded ? Icons.check_circle : Icons.upload_file,
        color: isUploaded ? AppColors.success : AppColors.warning,
        size: 20,
      ),
      title: Text(
        name,
        style: context.textTheme.bodySmall,
      ),
      trailing: Text(
        isUploaded ? 'Uploaded' : 'Pending',
        style: context.textTheme.labelSmall?.copyWith(
          color: isUploaded ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
