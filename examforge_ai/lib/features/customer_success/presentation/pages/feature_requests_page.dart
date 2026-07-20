import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../providers/customer_success_provider.dart';
import '../widgets/feature_request_card.dart';

/// Community feature requests page with voting.
///
/// Displays a list of feature requests that users can upvote,
/// and allows users to submit new feature requests.
class FeatureRequestsPage extends StatefulWidget {
  const FeatureRequestsPage({super.key});

  @override
  State<FeatureRequestsPage> createState() => _FeatureRequestsPageState();
}

class _FeatureRequestsPageState extends State<FeatureRequestsPage> {
  String? _selectedStatus;
  String _sortBy = 'upvotes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerSuccessProvider>();
      provider.loadFeatureRequests(sortBy: _sortBy);
      provider.loadUserVotes('current-user');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: Consumer<CustomerSuccessProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.featureRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.featureRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No feature requests yet', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Be the first to suggest a feature!', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadFeatureRequests(status: _selectedStatus, sortBy: _sortBy),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text('Sort by:', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      ChoiceChip(label: const Text('Most Votes'), selected: _sortBy == 'upvotes', onSelected: (_) => _changeSortBy('upvotes')),
                      const SizedBox(width: 4),
                      ChoiceChip(label: const Text('Newest'), selected: _sortBy == 'newest', onSelected: (_) => _changeSortBy('newest')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: provider.featureRequests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final request = provider.featureRequests[index];
                      final hasVoted = provider.userVotes.contains(request.id);
                      return FeatureRequestCard(
                        request: request,
                        hasVoted: hasVoted,
                        onVote: () => provider.voteForFeatureRequest(request.id, 'current-user'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _changeSortBy(String sortBy) {
    setState(() => _sortBy = sortBy);
    context.read<CustomerSuccessProvider>().loadFeatureRequests(status: _selectedStatus, sortBy: sortBy);
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter by Status'),
        children: [
          SimpleDialogOption(child: const Text('All'), onPressed: () { Navigator.pop(context); setState(() => _selectedStatus = null); context.read<CustomerSuccessProvider>().loadFeatureRequests(sortBy: _sortBy); }),
          SimpleDialogOption(child: const Text('Open'), onPressed: () { Navigator.pop(context); setState(() => _selectedStatus = 'open'); context.read<CustomerSuccessProvider>().loadFeatureRequests(status: 'open', sortBy: _sortBy); }),
          SimpleDialogOption(child: const Text('Under Consideration'), onPressed: () { Navigator.pop(context); setState(() => _selectedStatus = 'under_consideration'); context.read<CustomerSuccessProvider>().loadFeatureRequests(status: 'under_consideration', sortBy: _sortBy); }),
          SimpleDialogOption(child: const Text('Planned'), onPressed: () { Navigator.pop(context); setState(() => _selectedStatus = 'planned'); context.read<CustomerSuccessProvider>().loadFeatureRequests(status: 'planned', sortBy: _sortBy); }),
          SimpleDialogOption(child: const Text('Implemented'), onPressed: () { Navigator.pop(context); setState(() => _selectedStatus = 'implemented'); context.read<CustomerSuccessProvider>().loadFeatureRequests(status: 'implemented', sortBy: _sortBy); }),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'general';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Feature Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 4),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: ['general', 'content', 'exams', 'ui', 'performance', 'integration'].map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? 'general'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context);
                final provider = context.read<CustomerSuccessProvider>();
                final success = await provider.createFeatureRequest(
                  userId: 'current-user',
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  category: category,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature request created!')));
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
