import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../providers/admission_hub_provider.dart';
import '../widgets/admission_hub_widgets.dart';

/// University search page with filters by name, state, and type.
///
/// Features:
/// - Real-time search as you type
/// - Filter by university type (Federal, State, Private, etc.)
/// - Filter by state
/// - University cards with key info
/// - Infinite scroll pagination
/// - Compare universities option
class UniversitySearchPage extends ConsumerStatefulWidget {
  const UniversitySearchPage({super.key});

  @override
  ConsumerState<UniversitySearchPage> createState() =>
      _UniversitySearchPageState();
}

class _UniversitySearchPageState extends ConsumerState<UniversitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedState;
  UniversityType? _selectedType;
  final List<String> _selectedForComparison = [];

  // Nigerian states for the filter dropdown
  static const _nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi',
    'Bayelsa', 'Benue', 'Borno', 'Cross River', 'Delta',
    'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'FCT',
    'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano',
    'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
    'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun',
    'Oyo', 'Plateau', 'Rivers', 'Sokoto', 'Taraba',
    'Yobe', 'Zamfara',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(admissionHubProvider.notifier).loadMoreUniversities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(admissionHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Universities'),
        actions: [
          if (_selectedForComparison.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => _compareSelected(),
              tooltip: 'Compare selected',
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search & Filters ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by university name...',
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
                  onChanged: (query) => setState(() {}),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      ref
                          .read(admissionHubProvider.notifier)
                          .searchUniversities(query.trim());
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Filter row
                Row(
                  children: [
                    // University type dropdown
                    Expanded(
                      child: DropdownButtonFormField<UniversityType?>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<UniversityType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...UniversityType.values.map(
                            (type) => DropdownMenuItem<UniversityType?>(
                              value: type,
                              child: Text(type.label),
                            ),
                          ),
                        ],
                        onChanged: (type) {
                          setState(() => _selectedType = type);
                          ref
                              .read(admissionHubProvider.notifier)
                              .setUniversityType(type);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // State dropdown
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedState,
                        decoration: InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All States'),
                          ),
                          ..._nigerianStates.map(
                            (s) => DropdownMenuItem<String?>(
                              value: s,
                              child: Text(s),
                            ),
                          ),
                        ],
                        onChanged: (state) {
                          setState(() => _selectedState = state);
                          ref
                              .read(admissionHubProvider.notifier)
                              .setStateFilter(state);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Results ───────────────────────────────────────────────
          Expanded(
            child: state.isLoading && state.universities.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : state.error != null && state.universities.isEmpty
                    ? AppErrorState(
                        icon: Icons.error_outline_rounded,
                        title: 'Search Failed',
                        message: state.error,
                        onRetry: () => ref
                            .read(admissionHubProvider.notifier)
                            .loadUniversities(),
                      )
                    : state.universities.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.school_outlined,
                            title: 'No Universities Found',
                            message:
                                'Try adjusting your search or filters.',
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.universities.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= state.universities.length) {
                                return state.hasMoreUniversities
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: AppLoadingSpinner(),
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }

                              final university = state.universities[index];
                              final isSelected = _selectedForComparison
                                  .contains(university.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: UniversityCard(
                                  university: university,
                                  isSelected: isSelected,
                                  onTap: () => _onUniversityTapped(university),
                                  onLongPress: () =>
                                      _toggleComparison(university),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _selectedForComparison.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _selectedForComparison.length >= 2
                  ? _compareSelected
                  : null,
              icon: const Icon(Icons.compare_arrows),
              label: Text(
                'Compare (${_selectedForComparison.length})',
              ),
              backgroundColor: _selectedForComparison.length >= 2
                  ? AppColors.primary
                  : Colors.grey,
            )
          : null,
    );
  }

  void _onUniversityTapped(University university) {
    // Navigate to university detail / eligibility checker
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                university.name,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: university.universityType.label,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: '${university.city}, ${university.state}',
                  ),
                ],
              ),
              if (university.rankingNational != null) ...[
                const SizedBox(height: 8),
                _InfoChip(
                  icon: Icons.emoji_events_outlined,
                  label:
                      'National Ranking: #${university.rankingNational}',
                ),
              ],
              if (university.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  university.description!,
                  style: context.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdmissionCheckerPage(
                          preselectedUniversityId: university.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Check Eligibility'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleComparison(University university) {
    setState(() {
      if (_selectedForComparison.contains(university.id)) {
        _selectedForComparison.remove(university.id);
      } else if (_selectedForComparison.length < 4) {
        _selectedForComparison.add(university.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can compare up to 4 universities at a time.'),
          ),
        );
      }
    });
  }

  void _compareSelected() {
    ref
        .read(admissionHubProvider.notifier)
        .compareUniversities(_selectedForComparison);
  }
}

/// Small chip for displaying info inline.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
