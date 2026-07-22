import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_success_entities.dart';
import '../providers/customer_success_provider.dart';

/// Knowledge base / Help Center page.
///
/// Shows searchable help articles organized by category.
class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _isSearching = false;

  static const _categories = ['Getting Started', 'Account', 'Billing', 'Content', 'Exams', 'Integrations', 'Troubleshooting'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerSuccessProvider).loadHelpArticles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        centerTitle: true,
      ),
      body: Consumer(builder: (context, ref, child) {
        final provider = ref.watch(customerSuccessProvider);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search help articles...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _isSearching = false);
                              provider.loadHelpArticles(category: _selectedCategory);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      setState(() => _isSearching = true);
                      provider.searchHelpArticles(query.trim());
                    }
                  },
                ),
              ),
              if (!_isSearching)
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('All', _selectedCategory == null, () {
                        setState(() => _selectedCategory = null);
                        provider.loadHelpArticles();
                      }),
                      ..._categories.map((cat) => _buildCategoryChip(cat, _selectedCategory == cat, () {
                        setState(() => _selectedCategory = cat);
                        provider.loadHelpArticles(category: cat);
                      })),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.helpArticles.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(_isSearching ? 'No articles found' : 'No help articles yet', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.loadHelpArticles(category: _selectedCategory),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.helpArticles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final article = provider.helpArticles[index];
                        return _buildArticleCard(context, article);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, HelpArticle article) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showArticleDetail(context, article),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(article.category, style: theme.textTheme.labelSmall),
                  ),
                  const Spacer(),
                  Text('${article.viewsCount} views', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Text(article.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                article.content.length > 120 ? '${article.content.substring(0, 120)}...' : article.content,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (article.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: article.tags.take(3).map((tag) => Chip(
                    label: Text(tag, style: theme.textTheme.labelSmall),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleDetail(BuildContext context, HelpArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(article.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Text(article.category, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 12),
                  Text('${article.helpfulCount} found helpful', style: Theme.of(context).textTheme.bodySmall),
                ]),
                const Divider(height: 24),
                Text(article.content, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: const Text('Helpful'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.thumb_down_outlined),
                      label: const Text('Not Helpful'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
