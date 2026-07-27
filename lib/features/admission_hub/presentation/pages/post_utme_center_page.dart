import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/admission_hub_entities.dart';
import '../providers/admission_hub_provider.dart';

/// Post-UTME practice test center page.
///
/// Features:
/// - Filter Post-UTME products by university and department
/// - Year filter
/// - Product cards showing test details (duration, questions, pass mark)
/// - Premium badge for premium content
/// - Start practice button
class PostUtmeCenterPage extends ConsumerStatefulWidget {
  const PostUtmeCenterPage({super.key});

  @override
  ConsumerState<PostUtmeCenterPage> createState() =>
      _PostUtmeCenterPageState();
}

class _PostUtmeCenterPageState extends ConsumerState<PostUtmeCenterPage> {
  String? _selectedUniversityId;
  String? _selectedDepartmentId;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(admissionHubProvider.notifier).loadPostUtmeProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(admissionHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-UTME Practice'),
      ),
      body: Column(
        children: [
          // ─── Filters ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Practice Tests',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUniversityId,
                        decoration: InputDecoration(
                          labelText: 'University',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Universities'),
                          ),
                          ...state.universities.map(
                            (u) => DropdownMenuItem<String>(
                              value: u.id,
                              child: Text(
                                u.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (id) {
                          setState(() => _selectedUniversityId = id);
                          _loadProducts();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Years'),
                          ),
                          ...List.generate(5, (i) {
                            final year = DateTime.now().year - i;
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                        ],
                        onChanged: (year) {
                          setState(() => _selectedYear = year);
                          _loadProducts();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Products List ──────────────────────────────────────────
          Expanded(
            child: state.isLoadingProducts
                ? const Center(child: AppLoadingSpinner())
                : state.error != null && state.postUtmeProducts.isEmpty
                    ? AppErrorState(
                        icon: Icons.error_outline_rounded,
                        title: 'Failed to Load Tests',
                        message: state.error,
                        onRetry: _loadProducts,
                      )
                    : state.postUtmeProducts.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.quiz_outlined,
                            title: 'No Practice Tests Found',
                            subtitle:
                                'Adjust your filters to find Post-UTME practice tests.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.postUtmeProducts.length,
                            itemBuilder: (context, index) {
                              final product = state.postUtmeProducts[index];
                              return _PostUtmeProductCard(
                                product: product,
                                universityName: _getUniversityName(
                                  product.universityId,
                                  state.universities,
                                ),
                                onStart: () => _startPractice(product),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _loadProducts() {
    ref.read(admissionHubProvider.notifier).loadPostUtmeProducts(
          universityId: _selectedUniversityId,
          departmentId: _selectedDepartmentId,
          year: _selectedYear,
        );
  }

  String _getUniversityName(
    String universityId,
    List<University> universities,
  ) {
    try {
      return universities
              .firstWhere((u) => u.id == universityId)
              .name;
    } catch (_) {
      return 'Unknown University';
    }
  }

  void _startPractice(PostUtmeProduct product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting ${product.name} practice test...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    // Navigate to CBT Engine exam take page
  }
}

/// Card displaying a Post-UTME practice test product.
class _PostUtmeProductCard extends StatelessWidget {
  const _PostUtmeProductCard({
    required this.product,
    required this.universityName,
    required this.onStart,
  });

  final PostUtmeProduct product;
  final String universityName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: product.isPremium
            ? const BorderSide(color: AppColors.warning, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (product.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              universityName,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            if (product.description != null) ...[
              const SizedBox(height: 8),
              Text(
                product.description!,
                style: context.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),

            // Stats row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: '${product.durationMinutes} min',
                ),
                _StatChip(
                  icon: Icons.quiz_outlined,
                  label: '${product.totalQuestions} Qs',
                ),
                _StatChip(
                  icon: Icons.grade_outlined,
                  label: 'Pass: ${product.passMark.toInt()}%',
                ),
                _StatChip(
                  icon: Icons.calendar_today,
                  label: product.year.toString(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Start button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start Practice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stat chip for displaying product stats inline.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

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
