import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_dashboard_entities.dart';
import '../providers/analytics_dashboard_provider.dart';

/// Release notes page showing product updates and changelog.
class ReleaseNotesPage extends ConsumerStatefulWidget {
  const ReleaseNotesPage({super.key});
  @override
  ConsumerState<ReleaseNotesPage> createState() => _ReleaseNotesPageState();
}

class _ReleaseNotesPageState extends ConsumerState<ReleaseNotesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsDashboardProvider).loadReleaseNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Release Notes'), centerTitle: true),
      body: Consumer(builder: (context, ref, _) {
          final provider = ref.watch(analyticsDashboardProvider);
          if (provider.isLoading && provider.releaseNotes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.releaseNotes.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.new_releases_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No release notes yet', style: theme.textTheme.bodyLarge),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadReleaseNotes(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.releaseNotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildReleaseNoteCard(context, provider.releaseNotes[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReleaseNoteCard(BuildContext context, ReleaseNote note) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildReleaseTypeBadge(theme, note.releaseType),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('v${note.version}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                Text(_formatDate(note.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Text(note.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(note.content, style: theme.textTheme.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showFullReleaseNote(context, note),
              child: Text('Read more', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReleaseTypeBadge(ThemeData theme, String releaseType) {
    Color color;
    String label;
    switch (releaseType) {
      case 'major': color = Colors.red; label = 'MAJOR'; break;
      case 'minor': color = Colors.orange; label = 'MINOR'; break;
      case 'patch': color = Colors.green; label = 'PATCH'; break;
      case 'hotfix': color = Colors.purple; label = 'HOTFIX'; break;
      default: color = Colors.grey; label = releaseType.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showFullReleaseNote(BuildContext context, ReleaseNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(note.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Text('v${note.version}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text(_formatDate(note.createdAt)),
            ]),
            const Divider(height: 24),
            Text(note.content, style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
