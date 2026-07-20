import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../providers/customer_success_provider.dart';

/// Submit and track feedback page.
///
/// Allows users to submit bug reports, feature requests, and general feedback,
/// and view the status of their previous submissions.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeedbackType _selectedType = FeedbackType.generalFeedback;
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerSuccessProvider>().loadFeedbackSubmissions('current-user');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Submit', icon: Icon(Icons.edit_outlined)), Tab(text: 'My Submissions', icon: Icon(Icons.list_alt))],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(theme),
          _buildSubmissionsTab(theme),
        ],
      ),
    );
  }

  Widget _buildSubmitTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Feedback', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Help us improve ExamForge AI', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Text('Feedback Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: FeedbackType.values.map((type) => ChoiceChip(
              label: Text(type.label),
              selected: _selectedType == type,
              onSelected: (_) => setState(() => _selectedType = type),
              selectedColor: theme.colorScheme.primaryContainer,
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Priority', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'low', label: Text('Low')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'high', label: Text('High')),
              ButtonSegment(value: 'critical', label: Text('Critical')),
            ],
            selected: {_selectedPriority},
            onSelectionChanged: (selection) => setState(() => _selectedPriority = selection.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'Brief summary of your feedback',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Tell us more about it...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          Consumer<CustomerSuccessProvider>(
            builder: (context, provider, _) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submitFeedback,
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Submit Feedback'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(ThemeData theme) {
    return Consumer<CustomerSuccessProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.feedbackSubmissions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.feedbackSubmissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No feedback submissions yet', style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadFeedbackSubmissions('current-user'),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.feedbackSubmissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final submission = provider.feedbackSubmissions[index];
              return _buildSubmissionCard(theme, submission);
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionCard(ThemeData theme, FeedbackSubmission submission) {
    final statusColor = _getStatusColor(submission.status);
    final priorityColor = _getPriorityColor(submission.priority);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(submission.status.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(submission.priority.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: priorityColor, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Icon(_getTypeIcon(submission.feedbackType), size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Text(submission.subject, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(submission.description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (submission.resolution != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(submission.resolution!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade800))),
                ]),
              ),
            ],
            const SizedBox(height: 8),
            Text('Submitted ${_formatDate(submission.createdAt)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_subjectController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }
    final provider = context.read<CustomerSuccessProvider>();
    final success = await provider.submitFeedback(
      userId: 'current-user',
      feedbackType: _selectedType,
      subject: _subjectController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
    );
    if (success && mounted) {
      _subjectController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedType = FeedbackType.generalFeedback;
        _selectedPriority = 'medium';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted successfully!')));
      _tabController.animateTo(1);
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'critical': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport: return Icons.bug_report_outlined;
      case FeedbackType.featureRequest: return Icons.lightbulb_outline;
      case FeedbackType.generalFeedback: return Icons.chat_outlined;
      case FeedbackType.complaint: return Icons.report_problem_outlined;
      case FeedbackType.praise: return Icons.favorite_outline;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
