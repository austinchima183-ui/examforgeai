import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/marketing_entities.dart';
import '../providers/marketing_provider.dart';
import '../widgets/blog_post_card.dart';

/// Blog management page for creating, editing, and managing blog posts.
class BlogManagementPage extends StatefulWidget {
  const BlogManagementPage({super.key});
  @override
  State<BlogManagementPage> createState() => _BlogManagementPageState();
}

class _BlogManagementPageState extends State<BlogManagementPage> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingProvider>().loadBlogPosts(status: _filterStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Management'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
      body: Consumer<MarketingProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Filter:', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    ChoiceChip(label: const Text('All'), selected: _filterStatus == null, onSelected: (_) { setState(() => _filterStatus = null); provider.loadBlogPosts(); }),
                    const SizedBox(width: 4),
                    ChoiceChip(label: const Text('Draft'), selected: _filterStatus == 'draft', onSelected: (_) { setState(() => _filterStatus = 'draft'); provider.loadBlogPosts(status: 'draft'); }),
                    const SizedBox(width: 4),
                    ChoiceChip(label: const Text('Published'), selected: _filterStatus == 'published', onSelected: (_) { setState(() => _filterStatus = 'published'); provider.loadBlogPosts(status: 'published'); }),
                  ],
                ),
              ),
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.blogPosts.isEmpty)
                Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('No blog posts yet', style: theme.textTheme.bodyLarge)])))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadBlogPosts(status: _filterStatus),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.blogPosts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => BlogPostCard(
                        blogPost: provider.blogPosts[index],
                        onTap: () => _showPostDetail(context, provider.blogPosts[index]),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final excerptCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'general';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Blog Post'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: excerptCtrl, decoration: const InputDecoration(labelText: 'Excerpt', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()), maxLines: 5),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: ['general', 'product', 'education', 'tips', 'news'].map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                onChanged: (v) => setDialogState(() => category = v ?? 'general'),
              ),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Create'))],
        ),
      ),
    );
  }

  void _showPostDetail(BuildContext context, BlogPost post) {
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
            Text(post.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Text(post.category, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 12),
              Text('${post.viewsCount} views'),
              const SizedBox(width: 12),
              Text('${post.likesCount} likes'),
            ]),
            const Divider(height: 24),
            Text(post.content),
          ]),
        ),
      ),
    );
  }
}
