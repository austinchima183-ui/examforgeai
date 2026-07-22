import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dependency_injection.dart';
import '../../domain/entities/edu_os_entities.dart';
import '../providers/edu_os_provider.dart';
import '../widgets/module_card.dart';
import 'module_detail_page.dart';
import 'school_modules_page.dart';

/// EduOS Module Marketplace dashboard.
///
/// Shows available modules organized by tier with search
/// and filtering capabilities.
class EduOsDashboardPage extends ConsumerStatefulWidget {
  const EduOsDashboardPage({super.key});
  @override
  ConsumerState<EduOsDashboardPage> createState() => _EduOsDashboardPageState();
}

class _EduOsDashboardPageState extends ConsumerState<EduOsDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eduOsProvider).loadModules();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduOS Marketplace'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Modules'),
            Tab(text: 'Core'),
            Tab(text: 'Premium'),
            Tab(text: 'My Modules'),
          ],
        ),
      ),
      body: Consumer(builder: (context, ref, _) {
          final provider = ref.watch(eduOsProvider);
          if (provider.isLoading && provider.modules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search modules...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildModuleList(provider.modules, theme),
                    _buildModuleList(provider.coreModules, theme),
                    _buildModuleList(provider.premiumModules, theme),
                    _buildMyModulesTab(provider, theme),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleList(List<EduosModule> modules, ThemeData theme) {
    final filtered = _searchQuery.isEmpty
        ? modules
        : modules.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || m.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filtered.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.widgets_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('No modules found', style: theme.textTheme.bodyLarge),
      ]));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(eduOsProvider).loadModules(),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) => ModuleCard(
          module: filtered[index],
          onTap: () {
              ref.read(eduOsProvider).selectModule(filtered[index]);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModuleDetailPage()));
          },
        ),
      ),
    );
  }

  Widget _buildMyModulesTab(EduOsProvider provider, ThemeData theme) {
    return SchoolModulesPage(
      schoolId: 'current-school',
      subscriptions: provider.subscriptions,
      allModules: provider.modules,
    );
  }
}
