import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/widgets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/quality_check_provider.dart';
import '../providers/seller_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE / EDIT PRODUCT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Multi-step form for creating or editing a marketplace product.
///
/// - **Step 1**: Basic Info (title, description, type, category, etc.)
/// - **Step 2**: Pricing & License (price, license type, AI toggle)
/// - **Step 3**: Media & Preview (uploads, AI summary, quality check)
///
/// If [productId] is provided the form is pre-populated for editing.
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => CreateProductPage(productId: 'abc123'),
/// ));
/// ```
class CreateProductPage extends ConsumerStatefulWidget {
  const CreateProductPage({super.key, this.productId});

  /// When provided, the form loads the existing product for editing.
  final String? productId;

  @override
  ConsumerState<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends ConsumerState<CreateProductPage> {
  // ─── Form key & controllers ──────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 – Basic Info
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _versionCtrl = TextEditingController(text: '1.0');
  final _tagsCtrl = TextEditingController();

  MarketplaceProductType? _selectedProductType;
  MarketplaceCategoryEntity? _selectedCategory;
  String? _selectedClassLevel;
  String? _selectedCurriculum;
  String? _selectedLanguage;
  final List<String> _tags = [];

  // Step 2 – Pricing & License
  final _priceCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  bool _isFree = false;
  MarketplaceLicenseType _selectedLicenseType =
      MarketplaceLicenseType.personal;
  final _maxUsesCtrl = TextEditingController();
  final _maxUsersCtrl = TextEditingController();
  bool _isAiGenerated = false;

  // Step 3 – Media & Preview
  final List<String> _previewImages = [];
  final List<String> _previewDocuments = [];
  final List<String> _fullDocuments = [];
  final _aiSummaryCtrl = TextEditingController();

  // State flags
  bool _isSaving = false;
  bool _isGeneratingSummary = false;

  // ─── Constants ───────────────────────────────────────────────────────

  static const _classLevels = [
    'Primary 1', 'Primary 2', 'Primary 3', 'Primary 4',
    'Primary 5', 'Primary 6', 'JSS1', 'JSS2', 'JSS3',
    'SS1', 'SS2', 'SS3', 'All Levels',
  ];

  static const _curricula = [
    'Nigerian', 'British', 'American', 'International', 'Other',
  ];

  static const _languages = [
    'English', 'French', 'Yoruba', 'Hausa', 'Igbo', 'Other',
  ];

  static const _licenseDescriptions = {
    MarketplaceLicenseType.personal:
        'For individual use only. Cannot be shared or redistributed.',
    MarketplaceLicenseType.teacher:
        'Single teacher use. May use with their own students.',
    MarketplaceLicenseType.school:
        'School-wide license. All teachers in the school may use it.',
    MarketplaceLicenseType.department:
        'Department-wide license. All teachers in a department may use it.',
    MarketplaceLicenseType.enterprise:
        'Enterprise-wide license. Unlimited distribution within the organisation.',
  };

  // ─── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      // Load existing product for editing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductForEditing();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _subjectCtrl.dispose();
    _versionCtrl.dispose();
    _tagsCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _maxUsesCtrl.dispose();
    _maxUsersCtrl.dispose();
    _aiSummaryCtrl.dispose();
    super.dispose();
  }

  // ─── Load product for editing ────────────────────────────────────────

  void _loadProductForEditing() {
    final sellerState = ref.read(sellerProvider);
    final product = sellerState.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => MarketplaceProductEntity(
        id: '',
        sellerId: '',
        categoryId: '',
        title: '',
        slug: '',
        productType: MarketplaceProductType.other,
        licenseType: MarketplaceLicenseType.personal,
        status: MarketplaceProductStatus.draft,
        qualityCheckStatus: QualityCheckStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (product.id.isEmpty) return;

    _titleCtrl.text = product.title;
    _descriptionCtrl.text = product.description ?? '';
    _subjectCtrl.text = product.subject ?? '';
    _versionCtrl.text = product.version;
    _selectedProductType = product.productType;
    _selectedClassLevel = product.classLevel;
    _selectedCurriculum = product.curriculum;
    _selectedLanguage = product.language;
    _tags.addAll(product.tags);

    _priceCtrl.text = product.price > 0 ? product.price.toStringAsFixed(2) : '';
    _originalPriceCtrl.text =
        product.originalPrice > 0 ? product.originalPrice.toStringAsFixed(2) : '';
    _isFree = product.isFree;
    _selectedLicenseType = product.licenseType;
    _isAiGenerated = product.isAiGenerated;

    _previewImages.addAll(product.previewImages);
    _previewDocuments.addAll(product.previewDocuments);
    _fullDocuments.addAll(product.fullDocumentUrls);
    _aiSummaryCtrl.text = product.aiGeneratedSummary ?? '';

    if (product.licenseConfig != null) {
      _maxUsesCtrl.text = product.licenseConfig!['maxUses']?.toString() ?? '';
      _maxUsersCtrl.text = product.licenseConfig!['maxUsers']?.toString() ?? '';
    }

    setState(() {});
  }

  // ─── Validation helpers ──────────────────────────────────────────────

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) {
          _showError('Title is required');
          return false;
        }
        if (_titleCtrl.text.trim().length > 200) {
          _showError('Title must be 200 characters or less');
          return false;
        }
        if (_descriptionCtrl.text.trim().isEmpty) {
          _showError('Description is required');
          return false;
        }
        if (_descriptionCtrl.text.trim().length > 5000) {
          _showError('Description must be 5,000 characters or less');
          return false;
        }
        if (_selectedProductType == null) {
          _showError('Product type is required');
          return false;
        }
        return true;

      case 1:
        if (!_isFree) {
          final price = double.tryParse(_priceCtrl.text);
          if (price == null || price < 0) {
            _showError('Please enter a valid price');
            return false;
          }
        }
        final origPrice = double.tryParse(_originalPriceCtrl.text);
        if (_originalPriceCtrl.text.isNotEmpty && (origPrice == null || origPrice < 0)) {
          _showError('Original price must be a valid positive number');
          return false;
        }
        return true;

      case 2:
        if (_fullDocuments.isEmpty && widget.productId == null) {
          _showError('At least one full document is required');
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Tag management ──────────────────────────────────────────────────

  void _addTag() {
    final tag = _tagsCtrl.text.trim();
    if (tag.isEmpty) return;
    if (_tags.length >= 10) {
      _showError('Maximum 10 tags allowed');
      return;
    }
    if (_tags.contains(tag)) {
      _showError('Tag already exists');
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagsCtrl.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  // ─── Save / Submit ───────────────────────────────────────────────────

  Future<void> _saveAsDraft() async {
    if (!_validateStep(_currentStep)) return;
    await _performSave(isDraft: true);
  }

  Future<void> _submitForReview() async {
    // Validate all steps before submitting
    for (var i = 0; i < 3; i++) {
      if (!_validateStep(i)) {
        setState(() => _currentStep = i);
        return;
      }
    }
    await _performSave(isDraft: false);
  }

  Future<void> _performSave({required bool isDraft}) async {
    setState(() => _isSaving = true);

    final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text) ?? 0);
    final originalPrice =
        double.tryParse(_originalPriceCtrl.text) ?? 0;

    final licenseConfig = <String, dynamic>{};
    if (_maxUsesCtrl.text.isNotEmpty) {
      licenseConfig['maxUses'] = int.tryParse(_maxUsesCtrl.text) ?? 0;
    }
    if (_maxUsersCtrl.text.isNotEmpty) {
      licenseConfig['maxUsers'] = int.tryParse(_maxUsersCtrl.text) ?? 0;
    }

    final product = MarketplaceProductEntity(
      id: widget.productId ?? '',
      sellerId: '',
      categoryId: _selectedCategory?.id ?? '',
      title: _titleCtrl.text.trim(),
      slug: _titleCtrl.text.trim().toLowerCase().replaceAll(' ', '-'),
      description: _descriptionCtrl.text.trim(),
      productType: _selectedProductType ?? MarketplaceProductType.other,
      subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
      classLevel: _selectedClassLevel,
      curriculum: _selectedCurriculum,
      language: _selectedLanguage,
      previewImages: _previewImages,
      previewDocuments: _previewDocuments,
      fullDocumentUrls: _fullDocuments,
      price: price,
      originalPrice: originalPrice,
      licenseType: _selectedLicenseType,
      licenseConfig: licenseConfig.isEmpty ? null : licenseConfig,
      version: _versionCtrl.text.trim().isEmpty
          ? '1.0'
          : _versionCtrl.text.trim(),
      tags: _tags,
      aiGeneratedSummary: _aiSummaryCtrl.text.trim().isEmpty
          ? null
          : _aiSummaryCtrl.text.trim(),
      isAiGenerated: _isAiGenerated,
      isFree: _isFree,
      status: isDraft
          ? MarketplaceProductStatus.draft
          : MarketplaceProductStatus.pendingReview,
      qualityCheckStatus: QualityCheckStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.productId != null) {
        await ref.read(sellerProvider.notifier).updateProduct(product: product);
      } else {
        await ref.read(sellerProvider.notifier).createProduct(product: product);
      }

      if (mounted) {
        _showSuccess(isDraft
            ? 'Draft saved successfully'
            : 'Product submitted for review',);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save product. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── AI Summary generation (simulated) ───────────────────────────────

  Future<void> _generateAiSummary() async {
    setState(() => _isGeneratingSummary = true);
    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _aiSummaryCtrl.text =
          'AI-generated summary for "${_titleCtrl.text.trim()}". '
          'This ${_selectedProductType?.label ?? 'resource'} covers '
          '${_subjectCtrl.text.trim()} for $_selectedClassLevel students '
          'following the $_selectedCurriculum curriculum. '
          'The material is designed to provide comprehensive coverage '
          'of the topic with clear explanations and practice exercises.';
      setState(() => _isGeneratingSummary = false);
      _showSuccess('AI summary generated');
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isEditing = widget.productId != null;

    return Scaffold(
      appBar: AppAppBar(
        title: isEditing ? 'Edit Product' : 'Create Product',
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: Spacings.sm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Step indicator ───────────────────────────────────────
            _buildStepIndicator(cs, tt),

            // ── Step content ─────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1(cs, tt),
                  _buildStep2(cs, tt),
                  _buildStep3(cs, tt),
                ],
              ),
            ),

            // ── Bottom navigation ────────────────────────────────────
            _buildBottomActions(cs, tt),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ──────────────────────────────────────────────────

  Widget _buildStepIndicator(ColorScheme cs, TextTheme tt) {
    const stepLabels = ['Basic Info', 'Pricing & License', 'Media & Preview'];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: List.generate(stepLabels.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (index < _currentStep || (index == _currentStep + 1 && _validateStep(_currentStep))) {
                  setState(() => _currentStep = index);
                }
              },
              child: Row(
                children: [
                  // Step circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isActive
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: tt.labelSmall?.copyWith(
                                color: isActive
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                                fontWeight: AppTypography.wSemiBold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  // Label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepLabels[index],
                          style: tt.bodySmall?.copyWith(
                            color: isActive
                                ? cs.primary
                                : isCompleted
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                            fontWeight: isActive
                                ? AppTypography.wSemiBold
                                : AppTypography.wRegular,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Connector line
                  if (index < stepLabels.length - 1) ...[
                    const SizedBox(width: Spacings.sm),
                    Container(
                      height: 2,
                      width: 24,
                      color: isCompleted
                          ? AppColors.success
                          : cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: Spacings.sm),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 1 — Basic Info
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep1(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            'Provide the essential details about your product.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          Spacings.sectionGap,

          // Title
          AppTextField(
            label: 'Title',
            hint: 'e.g. SS2 Physics Question Bank',
            controller: _titleCtrl,
            isRequired: true,
            maxLength: 200,
            prefixIcon: Icons.title,
          ),
          Spacings.itemGap,

          // Description
          AppTextField(
            label: 'Description',
            hint: 'Describe your product in detail...',
            controller: _descriptionCtrl,
            isRequired: true,
            maxLength: 5000,
            maxLines: 5,
            minLines: 3,
          ),
          Spacings.itemGap,

          // Product Type
          AppDropdownField<MarketplaceProductType>(
            label: 'Product Type',
            hint: 'Select a product type',
            items: MarketplaceProductType.values,
            selectedItem: _selectedProductType,
            onChanged: (v) => setState(() => _selectedProductType = v),
            itemLabel: (type) => type.label,
            isRequired: true,
            prefixIcon: Icons.category_outlined,
          ),
          Spacings.itemGap,

          // Category (simplified – would normally load from provider)
          AppDropdownField<String>(
            label: 'Category',
            hint: 'Select a category',
            items: const [
              'Examinations', 'Lesson Materials', 'Teaching Aids',
              'Curriculum', 'Assessment', 'Media', 'Other',
            ],
            selectedItem: null,
            onChanged: (v) {},
            itemLabel: (c) => c,
            prefixIcon: Icons.folder_outlined,
          ),
          Spacings.itemGap,

          // Subject
          AppTextField(
            label: 'Subject',
            hint: 'e.g. Mathematics, Physics, English',
            controller: _subjectCtrl,
            prefixIcon: Icons.book_outlined,
          ),
          Spacings.itemGap,

          // Class Level
          AppDropdownField<String>(
            label: 'Class Level',
            hint: 'Select class level',
            items: _classLevels,
            selectedItem: _selectedClassLevel,
            onChanged: (v) => setState(() => _selectedClassLevel = v),
            itemLabel: (l) => l,
            prefixIcon: Icons.school_outlined,
          ),
          Spacings.itemGap,

          // Curriculum
          AppDropdownField<String>(
            label: 'Curriculum',
            hint: 'Select curriculum',
            items: _curricula,
            selectedItem: _selectedCurriculum,
            onChanged: (v) => setState(() => _selectedCurriculum = v),
            itemLabel: (c) => c,
            prefixIcon: Icons.menu_book_outlined,
          ),
          Spacings.itemGap,

          // Language
          AppDropdownField<String>(
            label: 'Language',
            hint: 'Select language',
            items: _languages,
            selectedItem: _selectedLanguage,
            onChanged: (v) => setState(() => _selectedLanguage = v),
            itemLabel: (l) => l,
            prefixIcon: Icons.language,
          ),
          Spacings.itemGap,

          // Tags
          Text(
            'Tags',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wMedium,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Add a tag and press Enter',
                  controller: _tagsCtrl,
                  onFieldSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              AppIconButton(
                icon: Icons.add,
                onPressed: _addTag,
                variant: AppIconButtonVariant.tonal,
                tooltip: 'Add tag',
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                  deleteIconColor: cs.onSurfaceVariant,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              '${_tags.length}/10 tags',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          Spacings.itemGap,

          // Version
          AppTextField(
            label: 'Version',
            hint: 'e.g. 1.0',
            controller: _versionCtrl,
            prefixIcon: Icons.info_outline,
          ),

          // Bottom padding for scroll
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 2 — Pricing & License
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep2(ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & License',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            'Set your pricing and choose a license type.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          Spacings.sectionGap,

          // Is Free toggle
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Product',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'Enable this to offer the product for free.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isFree,
                  onChanged: (v) => setState(() => _isFree = v),
                ),
              ],
            ),
          ),
          Spacings.itemGap,

          // Price (hidden if free)
          if (!_isFree) ...[
            AppTextField(
              label: 'Price (NGN)',
              hint: '0.00',
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.payments_outlined,
              isRequired: true,
            ),
            Spacings.itemGap,

            // Original Price (for discount display)
            AppTextField(
              label: 'Original Price (optional)',
              hint: '0.00',
              controller: _originalPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.sell_outlined,
            ),
            Spacings.itemGap,
          ],

          // License Type selector
          Text(
            'License Type',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...MarketplaceLicenseType.values.map((type) {
            final isSelected = _selectedLicenseType == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppCard(
                borderColor: isSelected ? cs.primary : null,
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.05)
                    : null,
                onTap: () => setState(() => _selectedLicenseType = type),
                child: Row(
                  children: [
                    Radio<MarketplaceLicenseType>(
                      value: type,
                      groupValue: _selectedLicenseType,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedLicenseType = v);
                        }
                      },
                      activeColor: cs.primary,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacings.xs),
                          Text(
                            _licenseDescriptions[type] ?? '',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Conditional license config
          if (_selectedLicenseType != MarketplaceLicenseType.personal) ...[
            Spacings.itemGap,
            Text(
              'License Configuration',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            AppTextField(
              label: 'Maximum Uses (optional)',
              hint: 'Leave empty for unlimited',
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.repeat,
            ),
            Spacings.itemGap,
            AppTextField(
              label: 'Maximum Users (optional)',
              hint: 'Leave empty for unlimited',
              controller: _maxUsersCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.group_outlined,
            ),
          ],

          Spacings.sectionGap,

          // AI Generated toggle
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: context.isDarkMode ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: Spacings.mdIcon,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Generated',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        'Mark this product as AI-generated content.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAiGenerated,
                  onChanged: (v) => setState(() => _isAiGenerated = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEP 3 — Media & Preview
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStep3(ColorScheme cs, TextTheme tt) {
    final qualityState = ref.watch(qualityCheckProvider);

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media & Preview',
            style: tt.titleLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            'Upload files and generate an AI summary for your product.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          Spacings.sectionGap,

          // Preview Images
          Text(
            'Preview Images (max 5)',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _previewImages.length < 5
                  ? _previewImages.length + 1
                  : _previewImages.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: Spacings.sm),
              itemBuilder: (context, index) {
                if (index == _previewImages.length && _previewImages.length < 5) {
                  return _buildUploadZone(
                    cs,
                    tt,
                    onTap: () {
                      // Simulated upload
                      setState(() {
                        _previewImages.add('preview_image_${_previewImages.length + 1}.png');
                      });
                    },
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Add Image',
                    width: 100,
                    height: 100,
                  );
                }
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(Spacings.mdRadius),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: cs.onSurfaceVariant,
                            size: Spacings.lgIcon,
                          ),
                          const SizedBox(height: Spacings.xs),
                          Text(
                            'Image ${index + 1}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _previewImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Spacings.itemGap,

          // Preview Documents
          Text(
            'Preview Documents (max 3, PDF only)',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ..._previewDocuments.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppInfoCard(
                title: entry.value,
                subtitle: 'PDF Document',
                icon: Icons.picture_as_pdf_outlined,
                iconColor: AppColors.error,
                trailing: AppIconButton(
                  icon: Icons.close,
                  onPressed: () => setState(() => _previewDocuments.removeAt(entry.key)),
                  variant: AppIconButtonVariant.standard,
                  size: AppButtonSize.small,
                ),
              ),
            );
          }),
          if (_previewDocuments.length < 3)
            _buildUploadZone(
              cs,
              tt,
              onTap: () {
                setState(() {
                  _previewDocuments.add('preview_doc_${_previewDocuments.length + 1}.pdf');
                });
              },
              icon: Icons.upload_file,
              label: 'Upload Preview Document (PDF)',
              width: double.infinity,
              height: 80,
            ),
          Spacings.itemGap,

          // Full Document
          Text(
            'Full Document *',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ..._fullDocuments.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppInfoCard(
                title: entry.value,
                subtitle: 'Full Document',
                icon: Icons.description_outlined,
                iconColor: AppColors.info,
                trailing: AppIconButton(
                  icon: Icons.close,
                  onPressed: () => setState(() => _fullDocuments.removeAt(entry.key)),
                  variant: AppIconButtonVariant.standard,
                  size: AppButtonSize.small,
                ),
              ),
            );
          }),
          _buildUploadZone(
            cs,
            tt,
            onTap: () {
              setState(() {
                _fullDocuments.add('full_document_${_fullDocuments.length + 1}.pdf');
              });
            },
            icon: Icons.cloud_upload_outlined,
            label: 'Upload Full Document',
            width: double.infinity,
            height: 80,
          ),
          Spacings.sectionGap,

          // AI Summary
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: Spacings.mdIcon, color: AppColors.info),
              const SizedBox(width: Spacings.sm),
              Text(
                'AI Summary',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              AppButton(
                label: _isGeneratingSummary ? 'Generating...' : 'Generate AI Summary',
                onPressed: _isGeneratingSummary ? null : _generateAiSummary,
                variant: AppButtonVariant.tonal,
                size: AppButtonSize.small,
                icon: Icons.auto_awesome,
                isLoading: _isGeneratingSummary,
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          AppTextField(
            hint: 'AI-generated summary will appear here. You can also edit it manually.',
            controller: _aiSummaryCtrl,
            maxLines: 6,
            minLines: 4,
          ),
          Spacings.sectionGap,

          // Run Quality Check
          if (widget.productId != null) ...[
            Row(
              children: [
                const Icon(Icons.fact_check_outlined, size: Spacings.mdIcon, color: AppColors.success),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Quality Check',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: qualityState.isRunningCheck ? 'Checking...' : 'Run Quality Check',
                  onPressed: qualityState.isRunningCheck
                      ? null
                      : () {
                          ref
                              .read(qualityCheckProvider.notifier)
                              .runQualityCheck(productId: widget.productId!);
                        },
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.small,
                  icon: Icons.play_arrow,
                  isLoading: qualityState.isRunningCheck,
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // Quality check results preview
            if (qualityState.qualityCheck != null)
              _buildQualityCheckPreview(cs, tt, qualityState.qualityCheck!),
          ],

          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ─── Upload zone helper ──────────────────────────────────────────────

  Widget _buildUploadZone(
    ColorScheme cs,
    TextTheme tt, {
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: Spacings.lgIcon),
            const SizedBox(height: Spacings.xs),
            Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quality check preview ───────────────────────────────────────────

  Widget _buildQualityCheckPreview(
    ColorScheme cs,
    TextTheme tt,
    QualityCheckEntity check,
  ) {
    final statusColor = check.overallScore >= 80
        ? AppColors.success
        : check.overallScore >= 50
            ? AppColors.warning
            : AppColors.error;

    return AppCard(
      color: statusColor.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, color: statusColor, size: Spacings.mdIcon),
              const SizedBox(width: Spacings.sm),
              Text(
                'Quality Score: ${check.overallScore.toStringAsFixed(0)}%',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (check.hasIssues) ...[
            const SizedBox(height: Spacings.sm),
            Text(
              '${check.flaggedIssues.length} issue(s) found',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom actions ──────────────────────────────────────────────────

  Widget _buildBottomActions(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.md,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back
            if (_currentStep > 0)
              AppButton(
                label: 'Back',
                onPressed: () => setState(() => _currentStep--),
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                icon: Icons.arrow_back,
              )
            else
              const SizedBox.shrink(),

            const Spacer(),

            // Save as Draft
            AppButton(
              label: 'Save Draft',
              onPressed: _isSaving ? null : _saveAsDraft,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              isLoading: _isSaving,
            ),
            const SizedBox(width: Spacings.sm),

            // Next / Submit
            if (_currentStep < 2)
              AppButton(
                label: 'Next',
                onPressed: () {
                  if (_validateStep(_currentStep)) {
                    setState(() => _currentStep++);
                  }
                },
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                icon: Icons.arrow_forward,
                iconAlignment: IconAlignment.end,
              )
            else
              AppButton(
                label: 'Submit for Review',
                onPressed: _isSaving ? null : _submitForReview,
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                icon: Icons.send,
                isLoading: _isSaving,
              ),
          ],
        ),
      ),
    );
  }
}
