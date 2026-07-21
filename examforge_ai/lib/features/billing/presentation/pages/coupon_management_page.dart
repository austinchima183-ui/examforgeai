import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../domain/entities/billing_entities.dart';
import '../providers/coupon_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// COUPON MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Coupon management page (Super Admin).
///
/// Lists coupons with status, code, discount, and usage count.
/// Supports creating new coupons, editing/deactivating, and
/// searching by code.
class CouponManagementPage extends ConsumerStatefulWidget {
  const CouponManagementPage({super.key});

  @override
  ConsumerState<CouponManagementPage> createState() =>
      _CouponManagementPageState();
}

class _CouponManagementPageState extends ConsumerState<CouponManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _activeOnly = true;
  int _page = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoupons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data Loading ────────────────────────────────────────────────────

  Future<void> _loadCoupons() async {
    await ref.read(couponProvider.notifier).loadCoupons(
          activeOnly: _activeOnly,
          page: _page,
          perPage: _perPage,
        );
  }

  Future<void> _refresh() async {
    setState(() => _page = 1);
    await _loadCoupons();
  }

  List<CouponEntity> get _filteredCoupons {
    final query = _searchController.text.trim().toUpperCase();
    final coupons = ref.read(couponProvider).coupons;
    if (query.isEmpty) return coupons;
    return coupons.where((c) => c.code.contains(query)).toList();
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final couponState = ref.watch(couponProvider);
    final filtered = _filteredCoupons;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Coupon Management',
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ────────────────────────────────────
          _buildSearchBar(),

          // ── Coupon List ────────────────────────────────────────────
          Expanded(
            child: _buildCouponList(couponState, filtered),
          ),
        ],
      ),
      // ── FAB: Create Coupon ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCouponDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Coupon'),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by coupon code...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
                vertical: Spacings.md,
              ),
              border: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusMd,
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusMd,
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: Spacings.borderRadiusMd,
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // Active only toggle
          Row(
            children: [
              Switch.adapted(
                value: _activeOnly,
                onChanged: (value) {
                  setState(() => _activeOnly = value);
                  _loadCoupons();
                },
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                'Active only',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${filtered.length} coupon${filtered.length == 1 ? '' : 's'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Coupon List ─────────────────────────────────────────────────────

  Widget _buildCouponList(CouponState couponState, List<CouponEntity> filtered) {
    if (couponState.isLoading && filtered.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (couponState.error != null && filtered.isEmpty) {
      return AppErrorState.genericError(
        message: couponState.error,
        onRetry: _refresh,
      );
    }

    if (filtered.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Coupons Found',
        subtitle: _searchController.text.isNotEmpty
            ? 'Try a different search term.'
            : 'Create your first coupon to get started.',
        actionLabel: _searchController.text.isNotEmpty ? null : 'Create Coupon',
        onAction: _searchController.text.isNotEmpty ? null : _showCreateCouponDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (context, index) {
          final coupon = filtered[index];
          return _CouponListTile(
            coupon: coupon,
            onEdit: () => _showEditCouponDialog(coupon),
            onDeactivate: () => _confirmDeactivate(coupon),
          );
        },
      ),
    );
  }

  // ─── Create Coupon Dialog ────────────────────────────────────────────

  Future<void> _showCreateCouponDialog() async {
    final result = await showDialog<_CouponFormData>(
      context: context,
      builder: (ctx) => const _CouponFormDialog(),
    );

    if (result != null && mounted) {
      final coupon = CouponEntity(
        id: '',
        code: result.code,
        name: result.name,
        description: result.description,
        discountType: result.discountType,
        discountValue: result.discountValue,
        discountPercent: result.discountType == CouponDiscountType.percentage
            ? result.discountValue
            : null,
        maxRedemptions: result.maxRedemptions,
        maxRedemptionsPerUser: result.maxRedemptionsPerUser,
        durationMonths: result.durationMonths,
        validFrom: result.validFrom,
        validUntil: result.validUntil,
        trialDays: result.discountType == CouponDiscountType.freeTrial
            ? result.discountValue.toInt()
            : null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(couponProvider.notifier).createCoupon(coupon: coupon);

      if (mounted) {
        final state = ref.read(couponProvider);
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), behavior: SnackBarBehavior.floating),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon created successfully!'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  // ─── Edit Coupon Dialog ──────────────────────────────────────────────

  Future<void> _showEditCouponDialog(CouponEntity coupon) async {
    final result = await showDialog<_CouponFormData>(
      context: context,
      builder: (ctx) => _CouponFormDialog(existingCoupon: coupon),
    );

    if (result != null && mounted) {
      final updated = coupon.copyWith(
        name: result.name,
        description: result.description,
        discountValue: result.discountValue,
        maxRedemptions: result.maxRedemptions,
        maxRedemptionsPerUser: result.maxRedemptionsPerUser,
        validUntil: result.validUntil,
      );

      await ref.read(couponProvider.notifier).updateCoupon(coupon: updated);

      if (mounted) {
        final state = ref.read(couponProvider);
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), behavior: SnackBarBehavior.floating),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coupon updated!'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  // ─── Confirm Deactivate ──────────────────────────────────────────────

  Future<void> _confirmDeactivate(CouponEntity coupon) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Deactivate Coupon?',
      message: 'This will deactivate "${coupon.code}". Existing users who already redeemed it will keep their discount.',
      confirmText: 'Deactivate',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(couponProvider.notifier).updateCoupon(
            coupon: coupon.copyWith(isActive: false),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon deactivated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COUPON LIST TILE
// ═══════════════════════════════════════════════════════════════════════

class _CouponListTile extends StatelessWidget {
  const _CouponListTile({
    required this.coupon,
    this.onEdit,
    this.onDeactivate,
  });

  final CouponEntity coupon;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = coupon.isActive ? AppColors.success : const Color(0xFF6B7280);
    final discountLabel = _discountLabel();

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.4),
                    borderRadius: Spacings.borderRadiusSm,
                    border: Border.all(
                      color: cs.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    coupon.code,
                    style: tt.labelMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: Spacings.borderRadiusSm,
                  ),
                  child: Text(
                    coupon.isActive ? 'Active' : 'Inactive',
                    style: tt.labelSmall?.copyWith(
                      color: isDark ? _lighten(statusColor) : statusColor,
                      fontWeight: AppTypography.wSemiBold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                // Actions
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: Spacings.mdIcon - 4,
                      color: cs.onSurfaceVariant,
                    ),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                if (onDeactivate != null && coupon.isActive)
                  IconButton(
                    onPressed: onDeactivate,
                    icon: Icon(
                      Icons.block_rounded,
                      size: Spacings.mdIcon - 4,
                      color: AppColors.error,
                    ),
                    tooltip: 'Deactivate',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // Name
            Text(
              coupon.name,
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: Spacings.sm),

            // Discount + Usage
            Row(
              children: [
                Expanded(
                  child: Text(
                    discountLabel,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${coupon.currentRedemptions}/${coupon.maxRedemptions > 0 ? coupon.maxRedemptions : '\u221E'} used',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _discountLabel() {
    switch (coupon.discountType) {
      case CouponDiscountType.percentage:
        return '${coupon.discountPercent?.toStringAsFixed(0) ?? coupon.discountValue.toStringAsFixed(0)}% off';
      case CouponDiscountType.fixedAmount:
        return '${coupon.discountValue.toStringAsFixed(0)} off';
      case CouponDiscountType.freeTrial:
        return 'Free trial (${coupon.trialDays ?? 14} days)';
      case CouponDiscountType.fixedPerSeat:
        return '${coupon.discountValue.toStringAsFixed(0)} off per seat';
    }
  }

  Color _lighten(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COUPON FORM DATA
// ═══════════════════════════════════════════════════════════════════════

class _CouponFormData {
  final String code;
  final String name;
  final String? description;
  final CouponDiscountType discountType;
  final double discountValue;
  final int maxRedemptions;
  final int maxRedemptionsPerUser;
  final int durationMonths;
  final DateTime validFrom;
  final DateTime? validUntil;

  const _CouponFormData({
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxRedemptions = 0,
    this.maxRedemptionsPerUser = 1,
    this.durationMonths = 1,
    required this.validFrom,
    this.validUntil,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// COUPON FORM DIALOG
// ═══════════════════════════════════════════════════════════════════════

class _CouponFormDialog extends StatefulWidget {
  const _CouponFormDialog({this.existingCoupon});

  final CouponEntity? existingCoupon;

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _valueController;
  late TextEditingController _maxRedemptionsController;
  CouponDiscountType _discountType = CouponDiscountType.percentage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCoupon;
    _codeController = TextEditingController(text: existing?.code ?? '');
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _valueController = TextEditingController(
      text: existing != null
          ? existing.discountType == CouponDiscountType.percentage
              ? (existing.discountPercent?.toStringAsFixed(0) ?? '')
              : existing.discountValue.toStringAsFixed(0)
          : '',
    );
    _maxRedemptionsController = TextEditingController(
      text: existing != null ? '${existing.maxRedemptions}' : '0',
    );
    if (existing != null) {
      _discountType = existing.discountType;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _maxRedemptionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _valueController.text.trim().isEmpty) {
      return;
    }

    Navigator.of(context).pop(_CouponFormData(
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      discountType: _discountType,
      discountValue: double.tryParse(_valueController.text.trim()) ?? 0,
      maxRedemptions:
          int.tryParse(_maxRedemptionsController.text.trim()) ?? 0,
      validFrom: DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 90)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isEdit = widget.existingCoupon != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Coupon' : 'Create Coupon'),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  prefixIcon: Icon(Icons.confirmation_number_outlined, size: 20),
                ),
                textCapitalization: TextCapitalization.characters,
                enabled: !isEdit,
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: Spacings.md),
              DropdownButtonFormField<CouponDiscountType>(
                value: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Discount Type',
                  prefixIcon: Icon(Icons.discount_outlined, size: 20),
                ),
                items: CouponDiscountType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _discountType = v);
                },
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _discountType == CouponDiscountType.percentage
                      ? 'Discount %'
                      : _discountType == CouponDiscountType.freeTrial
                          ? 'Trial Days'
                          : 'Discount Value',
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: _maxRedemptionsController,
                decoration: const InputDecoration(
                  labelText: 'Max Redemptions (0 = unlimited)',
                  prefixIcon: Icon(Icons.repeat_rounded, size: 20),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
