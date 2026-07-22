import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../providers/admission_hub_provider.dart';
import '../widgets/admission_hub_widgets.dart';

/// Dashboard page for the Admission Hub feature.
///
/// Features:
/// - University search with quick filter chips
/// - Eligibility checker shortcut card
/// - Quick actions grid (search, checker, post-UTME, checklist)
/// - Recent applications summary
/// - University type distribution overview
class AdmissionHubDashboardPage extends ConsumerStatefulWidget {
  const AdmissionHubDashboardPage({super.key});

  @override
  ConsumerState<AdmissionHubDashboardPage> createState() =>
      _AdmissionHubDashboardPageState();
}

class _AdmissionHubDashboardPageState
    extends ConsumerState<AdmissionHubDashboardPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(admissionHubProvider.notifier).loadUniversities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(admissionHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admission Hub'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(admissionHubProvider.notifier).loadUniversities(),
        child: CustomScrollView(
          slivers: [
            // ─── Search Bar ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search universities...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(admissionHubProvider.notifier)
                                  .clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      ref
                          .read(admissionHubProvider.notifier)
                          .searchUniversities(query.trim());
                    }
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // ─── University Type Filter Chips ────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      isSelected: state.selectedUniversityType == null,
                      onSelected: () => ref
                          .read(admissionHubProvider.notifier)
                          .setUniversityType(null),
                    ),
                    ...UniversityType.values.map(
                      (type) => _buildFilterChip(
                        label: type.label,
                        isSelected:
                            state.selectedUniversityType == type,
                        onSelected: () => ref
                            .read(admissionHubProvider.notifier)
                            .setUniversityType(type),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ─── Quick Actions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: context.isMobile ? 2 : 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _QuickActionCard(
                          icon: Icons.school_outlined,
                          title: 'Search\nUniversities',
                          color: AppColors.primary,
                          onTap: () => _navigateToSearch(context),
                        ),
                        _QuickActionCard(
                          icon: Icons.fact_check_outlined,
                          title: 'Check\nEligibility',
                          color: AppColors.success,
                          onTap: () => _navigateToChecker(context),
                        ),
                        _QuickActionCard(
                          icon: Icons.quiz_outlined,
                          title: 'Post-UTME\nPractice',
                          color: AppColors.warning,
                          onTap: () => _navigateToPostUtme(context),
                        ),
                        _QuickActionCard(
                          icon: Icons.checklist_outlined,
                          title: 'Admission\nChecklist',
                          color: AppColors.info,
                          onTap: () => _navigateToChecklist(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Universities List ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Universities',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${state.universities.length} found',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Loading State ──────────────────────────────────────────
            if (state.isLoading && state.universities.isEmpty)
              const SliverFillRemaining(
                child: Center(child: AppLoadingSpinner()),
              )
            else if (state.error != null && state.universities.isEmpty)
              SliverFillRemaining(
                child: AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Universities',
                  message: state.error,
                  onRetry: () => ref
                      .read(admissionHubProvider.notifier)
                      .loadUniversities(),
                ),
              )
            else if (state.universities.isEmpty)
              const SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No Universities Found',
                  subtitle:
                      'Try adjusting your search or filter criteria.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.universities.length) return null;
                      final university = state.universities[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: UniversityCard(
                          university: university,
                          onTap: () => _navigateToSearch(context),
                        ),
                      );
                    },
                    childCount: state.universities.length,
                  ),
                ),
              ),

            // ─── Load More ──────────────────────────────────────────────
            if (state.hasMoreUniversities && state.universities.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(admissionHubProvider.notifier)
                          .loadMoreUniversities(),
                      child: const Text('Load More'),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: context.colorScheme.surface,
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : context.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const UniversitySearchPage(),
      ),
    );
  }

  void _navigateToChecker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdmissionCheckerPage(),
      ),
    );
  }

  void _navigateToPostUtme(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PostUtmeCenterPage(),
      ),
    );
  }

  void _navigateToChecklist(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdmissionChecklistPage(),
      ),
    );
  }
}

/// Quick action card widget.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
