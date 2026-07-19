import 'package:equatable/equatable.dart';

// ═══════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════

/// Product types available in the marketplace.
enum MarketplaceProductType {
  questionBank(value: 'question_bank', label: 'Question Bank'),
  examTemplate(value: 'exam_template', label: 'Exam Template'),
  lessonNote(value: 'lesson_note', label: 'Lesson Note'),
  schemeOfWork(value: 'scheme_of_work', label: 'Scheme of Work'),
  worksheet(value: 'worksheet', label: 'Worksheet'),
  powerpoint(value: 'powerpoint', label: 'PowerPoint'),
  teachingSlides(value: 'teaching_slides', label: 'Teaching Slides'),
  flashcards(value: 'flashcards', label: 'Flashcards'),
  studyGuide(value: 'study_guide', label: 'Study Guide'),
  practicalManual(value: 'practical_manual', label: 'Practical Manual'),
  laboratoryGuide(value: 'laboratory_guide', label: 'Laboratory Guide'),
  curriculumPack(value: 'curriculum_pack', label: 'Curriculum Pack'),
  assessmentRubric(value: 'assessment_rubric', label: 'Assessment Rubric'),
  homeworkPack(value: 'homework_pack', label: 'Homework Pack'),
  classroomActivity(value: 'classroom_activity', label: 'Classroom Activity'),
  educationalImage(value: 'educational_image', label: 'Educational Image'),
  educationalVideo(value: 'educational_video', label: 'Educational Video'),
  educationalAudio(value: 'educational_audio', label: 'Educational Audio'),
  printableResource(value: 'printable_resource', label: 'Printable Resource'),
  other(value: 'other', label: 'Other');

  const MarketplaceProductType({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceProductType? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceProductType.values.cast<MarketplaceProductType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Product lifecycle status.
enum MarketplaceProductStatus {
  draft(value: 'draft', label: 'Draft'),
  pendingReview(value: 'pending_review', label: 'Pending Review'),
  approved(value: 'approved', label: 'Approved'),
  rejected(value: 'rejected', label: 'Rejected'),
  suspended(value: 'suspended', label: 'Suspended'),
  archived(value: 'archived', label: 'Archived');

  const MarketplaceProductStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceProductStatus? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceProductStatus.values.cast<MarketplaceProductStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// License type for marketplace products.
enum MarketplaceLicenseType {
  personal(value: 'personal', label: 'Personal'),
  teacher(value: 'teacher', label: 'Teacher'),
  school(value: 'school', label: 'School'),
  department(value: 'department', label: 'Department'),
  enterprise(value: 'enterprise', label: 'Enterprise');

  const MarketplaceLicenseType({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceLicenseType? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceLicenseType.values.cast<MarketplaceLicenseType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Order status lifecycle.
enum MarketplaceOrderStatus {
  pending(value: 'pending', label: 'Pending'),
  completed(value: 'completed', label: 'Completed'),
  failed(value: 'failed', label: 'Failed'),
  refunded(value: 'refunded', label: 'Refunded'),
  partiallyRefunded(value: 'partially_refunded', label: 'Partially Refunded');

  const MarketplaceOrderStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceOrderStatus? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceOrderStatus.values.cast<MarketplaceOrderStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Review visibility status.
enum MarketplaceReviewStatus {
  published(value: 'published', label: 'Published'),
  hidden(value: 'hidden', label: 'Hidden'),
  underReview(value: 'under_review', label: 'Under Review'),
  reported(value: 'reported', label: 'Reported');

  const MarketplaceReviewStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceReviewStatus? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceReviewStatus.values.cast<MarketplaceReviewStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Seller account status.
enum MarketplaceSellerStatus {
  active(value: 'active', label: 'Active'),
  suspended(value: 'suspended', label: 'Suspended'),
  pendingVerification(value: 'pending_verification', label: 'Pending Verification'),
  deactivated(value: 'deactivated', label: 'Deactivated');

  const MarketplaceSellerStatus({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceSellerStatus? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceSellerStatus.values.cast<MarketplaceSellerStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Commission type classification.
enum CommissionType {
  platform(value: 'platform', label: 'Platform'),
  promotional(value: 'promotional', label: 'Promotional'),
  referral(value: 'referral', label: 'Referral'),
  tax(value: 'tax', label: 'Tax');

  const CommissionType({required this.value, required this.label});
  final String value;
  final String label;

  static CommissionType? fromString(String? value) {
    if (value == null) return null;
    return CommissionType.values.cast<CommissionType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Quality check outcome.
enum QualityCheckStatus {
  pending(value: 'pending', label: 'Pending'),
  passed(value: 'passed', label: 'Passed'),
  failed(value: 'failed', label: 'Failed'),
  needsImprovement(value: 'needs_improvement', label: 'Needs Improvement');

  const QualityCheckStatus({required this.value, required this.label});
  final String value;
  final String label;

  static QualityCheckStatus? fromString(String? value) {
    if (value == null) return null;
    return QualityCheckStatus.values.cast<QualityCheckStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Discount type for promo codes.
enum DiscountType {
  percentage(value: 'percentage', label: 'Percentage'),
  fixed(value: 'fixed', label: 'Fixed');

  const DiscountType({required this.value, required this.label});
  final String value;
  final String label;

  static DiscountType? fromString(String? value) {
    if (value == null) return null;
    return DiscountType.values.cast<DiscountType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Dispute resolution status.
enum DisputeStatus {
  open(value: 'open', label: 'Open'),
  underReview(value: 'under_review', label: 'Under Review'),
  resolved(value: 'resolved', label: 'Resolved'),
  closed(value: 'closed', label: 'Closed');

  const DisputeStatus({required this.value, required this.label});
  final String value;
  final String label;

  static DisputeStatus? fromString(String? value) {
    if (value == null) return null;
    return DisputeStatus.values.cast<DisputeStatus?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

/// Marketplace notification type.
enum MarketplaceNotificationType {
  purchaseSuccess(value: 'purchase_success', label: 'Purchase Success'),
  newSale(value: 'new_sale', label: 'New Sale'),
  productReview(value: 'product_review', label: 'Product Review'),
  productApproval(value: 'product_approval', label: 'Product Approval'),
  productRejection(value: 'product_rejection', label: 'Product Rejection'),
  featuredProduct(value: 'featured_product', label: 'Featured Product'),
  priceChange(value: 'price_change', label: 'Price Change'),
  wishlistDiscount(value: 'wishlist_discount', label: 'Wishlist Discount'),
  commissionPaid(value: 'commission_paid', label: 'Commission Paid'),
  qualityCheckComplete(value: 'quality_check_complete', label: 'Quality Check Complete'),
  disputeUpdate(value: 'dispute_update', label: 'Dispute Update'),
  sellerVerified(value: 'seller_verified', label: 'Seller Verified');

  const MarketplaceNotificationType({required this.value, required this.label});
  final String value;
  final String label;

  static MarketplaceNotificationType? fromString(String? value) {
    if (value == null) return null;
    return MarketplaceNotificationType.values.cast<MarketplaceNotificationType?>().firstWhere(
      (e) => e?.value == value,
      orElse: () => null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ENTITIES
// ═══════════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────────
// Category
// ───────────────────────────────────────────────────────────────────

class MarketplaceCategoryEntity extends Equatable {
  const MarketplaceCategoryEntity({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTopLevel => parentId == null;

  @override
  List<Object?> get props => [
        id,
        parentId,
        name,
        slug,
        description,
        icon,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];

  MarketplaceCategoryEntity copyWith({
    String? id,
    String? parentId,
    String? name,
    String? slug,
    String? description,
    String? icon,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceCategoryEntity(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Seller Profile
// ───────────────────────────────────────────────────────────────────

class SellerProfileEntity extends Equatable {
  const SellerProfileEntity({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.status,
    this.verificationLevel = 0,
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalProducts = 0,
    this.bankAccountEncrypted,
    this.payoutMethod,
    this.payoutDetailsEncrypted,
    this.isVerified = false,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final MarketplaceSellerStatus status;
  final int verificationLevel;
  final int totalSales;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int totalProducts;
  final String? bankAccountEncrypted;
  final String? payoutMethod;
  final String? payoutDetailsEncrypted;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == MarketplaceSellerStatus.active;
  bool get isPendingVerification =>
      status == MarketplaceSellerStatus.pendingVerification;

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        bio,
        avatarUrl,
        status,
        verificationLevel,
        totalSales,
        totalRevenue,
        averageRating,
        totalReviews,
        totalProducts,
        bankAccountEncrypted,
        payoutMethod,
        payoutDetailsEncrypted,
        isVerified,
        verifiedAt,
        createdAt,
        updatedAt,
      ];

  SellerProfileEntity copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    MarketplaceSellerStatus? status,
    int? verificationLevel,
    int? totalSales,
    double? totalRevenue,
    double? averageRating,
    int? totalReviews,
    int? totalProducts,
    String? bankAccountEncrypted,
    String? payoutMethod,
    String? payoutDetailsEncrypted,
    bool? isVerified,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      totalSales: totalSales ?? this.totalSales,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalProducts: totalProducts ?? this.totalProducts,
      bankAccountEncrypted: bankAccountEncrypted ?? this.bankAccountEncrypted,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutDetailsEncrypted:
          payoutDetailsEncrypted ?? this.payoutDetailsEncrypted,
      isVerified: isVerified ?? this.isVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Product
// ───────────────────────────────────────────────────────────────────

class MarketplaceProductEntity extends Equatable {
  const MarketplaceProductEntity({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.slug,
    this.description,
    required this.productType,
    this.subject,
    this.classLevel,
    this.curriculum,
    this.language,
    this.previewImages = const [],
    this.previewDocuments = const [],
    this.fullDocumentUrls = const [],
    this.price = 0,
    this.originalPrice = 0,
    this.currency = 'NGN',
    required this.licenseType,
    this.licenseConfig,
    this.version = '1.0.0',
    this.tags = const [],
    this.aiGeneratedSummary,
    this.isAiGenerated = false,
    this.isFeatured = false,
    this.isFree = false,
    required this.status,
    this.qualityScore = 0,
    required this.qualityCheckStatus,
    this.qualityCheckDetails,
    this.totalSales = 0,
    this.totalRevenue = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String slug;
  final String? description;
  final MarketplaceProductType productType;
  final String? subject;
  final String? classLevel;
  final String? curriculum;
  final String? language;
  final List<String> previewImages;
  final List<String> previewDocuments;
  final List<String> fullDocumentUrls;
  final double price;
  final double originalPrice;
  final String currency;
  final MarketplaceLicenseType licenseType;
  final Map<String, dynamic>? licenseConfig;
  final String version;
  final List<String> tags;
  final String? aiGeneratedSummary;
  final bool isAiGenerated;
  final bool isFeatured;
  final bool isFree;
  final MarketplaceProductStatus status;
  final double qualityScore;
  final QualityCheckStatus qualityCheckStatus;
  final Map<String, dynamic>? qualityCheckDetails;
  final int totalSales;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;
  final int downloadCount;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Computed getters
  bool get isDiscounted => originalPrice > price;
  double get discountPercentage =>
      isDiscounted ? ((originalPrice - price) / originalPrice * 100) : 0;
  bool get isPublished => status == MarketplaceProductStatus.approved;

  @override
  List<Object?> get props => [
        id,
        sellerId,
        categoryId,
        title,
        slug,
        description,
        productType,
        subject,
        classLevel,
        curriculum,
        language,
        previewImages,
        previewDocuments,
        fullDocumentUrls,
        price,
        originalPrice,
        currency,
        licenseType,
        licenseConfig,
        version,
        tags,
        aiGeneratedSummary,
        isAiGenerated,
        isFeatured,
        isFree,
        status,
        qualityScore,
        qualityCheckStatus,
        qualityCheckDetails,
        totalSales,
        totalRevenue,
        averageRating,
        totalReviews,
        downloadCount,
        viewCount,
        publishedAt,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  MarketplaceProductEntity copyWith({
    String? id,
    String? sellerId,
    String? categoryId,
    String? title,
    String? slug,
    String? description,
    MarketplaceProductType? productType,
    String? subject,
    String? classLevel,
    String? curriculum,
    String? language,
    List<String>? previewImages,
    List<String>? previewDocuments,
    List<String>? fullDocumentUrls,
    double? price,
    double? originalPrice,
    String? currency,
    MarketplaceLicenseType? licenseType,
    Map<String, dynamic>? licenseConfig,
    String? version,
    List<String>? tags,
    String? aiGeneratedSummary,
    bool? isAiGenerated,
    bool? isFeatured,
    bool? isFree,
    MarketplaceProductStatus? status,
    double? qualityScore,
    QualityCheckStatus? qualityCheckStatus,
    Map<String, dynamic>? qualityCheckDetails,
    int? totalSales,
    double? totalRevenue,
    double? averageRating,
    int? totalReviews,
    int? downloadCount,
    int? viewCount,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MarketplaceProductEntity(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      productType: productType ?? this.productType,
      subject: subject ?? this.subject,
      classLevel: classLevel ?? this.classLevel,
      curriculum: curriculum ?? this.curriculum,
      language: language ?? this.language,
      previewImages: previewImages ?? this.previewImages,
      previewDocuments: previewDocuments ?? this.previewDocuments,
      fullDocumentUrls: fullDocumentUrls ?? this.fullDocumentUrls,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      currency: currency ?? this.currency,
      licenseType: licenseType ?? this.licenseType,
      licenseConfig: licenseConfig ?? this.licenseConfig,
      version: version ?? this.version,
      tags: tags ?? this.tags,
      aiGeneratedSummary: aiGeneratedSummary ?? this.aiGeneratedSummary,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      isFeatured: isFeatured ?? this.isFeatured,
      isFree: isFree ?? this.isFree,
      status: status ?? this.status,
      qualityScore: qualityScore ?? this.qualityScore,
      qualityCheckStatus: qualityCheckStatus ?? this.qualityCheckStatus,
      qualityCheckDetails: qualityCheckDetails ?? this.qualityCheckDetails,
      totalSales: totalSales ?? this.totalSales,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Product Version
// ───────────────────────────────────────────────────────────────────

class ProductVersionEntity extends Equatable {
  const ProductVersionEntity({
    required this.id,
    required this.productId,
    required this.version,
    this.changelog,
    this.documentUrls = const [],
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String version;
  final String? changelog;
  final List<String> documentUrls;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        productId,
        version,
        changelog,
        documentUrls,
        createdAt,
      ];

  ProductVersionEntity copyWith({
    String? id,
    String? productId,
    String? version,
    String? changelog,
    List<String>? documentUrls,
    DateTime? createdAt,
  }) {
    return ProductVersionEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      version: version ?? this.version,
      changelog: changelog ?? this.changelog,
      documentUrls: documentUrls ?? this.documentUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Cart & Cart Item
// ───────────────────────────────────────────────────────────────────

class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.licenseType,
    this.quantity = 1,
    required this.addedAt,
    this.product,
  });

  final String id;
  final String cartId;
  final String productId;
  final MarketplaceLicenseType licenseType;
  final int quantity;
  final DateTime addedAt;
  final MarketplaceProductEntity? product;

  double get unitPrice => product?.price ?? 0;
  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [
        id,
        cartId,
        productId,
        licenseType,
        quantity,
        addedAt,
        product,
      ];

  CartItemEntity copyWith({
    String? id,
    String? cartId,
    String? productId,
    MarketplaceLicenseType? licenseType,
    int? quantity,
    DateTime? addedAt,
    MarketplaceProductEntity? product,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      licenseType: licenseType ?? this.licenseType,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      product: product ?? this.product,
    );
  }
}

class CartEntity extends Equatable {
  const CartEntity({
    required this.id,
    required this.userId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final List<CartItemEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed getters
  double get totalPrice => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        createdAt,
        updatedAt,
      ];

  CartEntity copyWith({
    String? id,
    String? userId,
    List<CartItemEntity>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Order & Order Item
// ───────────────────────────────────────────────────────────────────

class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.licenseType,
    required this.priceAtPurchase,
    required this.platformFee,
    required this.sellerRevenue,
    this.currency = 'NGN',
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final MarketplaceLicenseType licenseType;
  final double priceAtPurchase;
  final double platformFee;
  final double sellerRevenue;
  final String currency;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        orderId,
        productId,
        sellerId,
        licenseType,
        priceAtPurchase,
        platformFee,
        sellerRevenue,
        currency,
        createdAt,
      ];

  OrderItemEntity copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? sellerId,
    MarketplaceLicenseType? licenseType,
    double? priceAtPurchase,
    double? platformFee,
    double? sellerRevenue,
    String? currency,
    DateTime? createdAt,
  }) {
    return OrderItemEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      licenseType: licenseType ?? this.licenseType,
      priceAtPurchase: priceAtPurchase ?? this.priceAtPurchase,
      platformFee: platformFee ?? this.platformFee,
      sellerRevenue: sellerRevenue ?? this.sellerRevenue,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MarketplaceOrderEntity extends Equatable {
  const MarketplaceOrderEntity({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.orderNumber,
    required this.status,
    this.subtotal = 0,
    this.platformFee = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.currency = 'NGN',
    this.promoCodeId,
    this.flutterwaveTxRef,
    this.flutterwaveFlwRef,
    this.paymentMethod,
    this.paidAt,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final String orderNumber;
  final MarketplaceOrderStatus status;
  final double subtotal;
  final double platformFee;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final String? promoCodeId;
  final String? flutterwaveTxRef;
  final String? flutterwaveFlwRef;
  final String? paymentMethod;
  final DateTime? paidAt;
  final List<OrderItemEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPaid => paidAt != null;
  bool get isRefunded =>
      status == MarketplaceOrderStatus.refunded ||
      status == MarketplaceOrderStatus.partiallyRefunded;

  @override
  List<Object?> get props => [
        id,
        buyerId,
        sellerId,
        orderNumber,
        status,
        subtotal,
        platformFee,
        taxAmount,
        discountAmount,
        totalAmount,
        currency,
        promoCodeId,
        flutterwaveTxRef,
        flutterwaveFlwRef,
        paymentMethod,
        paidAt,
        items,
        createdAt,
        updatedAt,
      ];

  MarketplaceOrderEntity copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? orderNumber,
    MarketplaceOrderStatus? status,
    double? subtotal,
    double? platformFee,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    String? currency,
    String? promoCodeId,
    String? flutterwaveTxRef,
    String? flutterwaveFlwRef,
    String? paymentMethod,
    DateTime? paidAt,
    List<OrderItemEntity>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceOrderEntity(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      platformFee: platformFee ?? this.platformFee,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      promoCodeId: promoCodeId ?? this.promoCodeId,
      flutterwaveTxRef: flutterwaveTxRef ?? this.flutterwaveTxRef,
      flutterwaveFlwRef: flutterwaveFlwRef ?? this.flutterwaveFlwRef,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Purchase
// ───────────────────────────────────────────────────────────────────

class MarketplacePurchaseEntity extends Equatable {
  const MarketplacePurchaseEntity({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.orderItemId,
    required this.licenseType,
    this.licenseKey,
    this.isActive = true,
    this.expiresAt,
    this.downloadCount = 0,
    this.lastDownloadedAt,
    required this.createdAt,
  });

  final String id;
  final String buyerId;
  final String productId;
  final String orderItemId;
  final MarketplaceLicenseType licenseType;
  final String? licenseKey;
  final bool isActive;
  final DateTime? expiresAt;
  final int downloadCount;
  final DateTime? lastDownloadedAt;
  final DateTime createdAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isAccessible => isActive && !isExpired;

  @override
  List<Object?> get props => [
        id,
        buyerId,
        productId,
        orderItemId,
        licenseType,
        licenseKey,
        isActive,
        expiresAt,
        downloadCount,
        lastDownloadedAt,
        createdAt,
      ];

  MarketplacePurchaseEntity copyWith({
    String? id,
    String? buyerId,
    String? productId,
    String? orderItemId,
    MarketplaceLicenseType? licenseType,
    String? licenseKey,
    bool? isActive,
    DateTime? expiresAt,
    int? downloadCount,
    DateTime? lastDownloadedAt,
    DateTime? createdAt,
  }) {
    return MarketplacePurchaseEntity(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      orderItemId: orderItemId ?? this.orderItemId,
      licenseType: licenseType ?? this.licenseType,
      licenseKey: licenseKey ?? this.licenseKey,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      downloadCount: downloadCount ?? this.downloadCount,
      lastDownloadedAt: lastDownloadedAt ?? this.lastDownloadedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Review & Review Helpful
// ───────────────────────────────────────────────────────────────────

class MarketplaceReviewEntity extends Equatable {
  const MarketplaceReviewEntity({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.rating,
    this.title,
    this.content,
    this.isVerifiedPurchase = false,
    required this.status,
    this.sellerResponse,
    this.sellerRespondedAt,
    this.helpfulCount = 0,
    this.reportCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final int rating;
  final String? title;
  final String? content;
  final bool isVerifiedPurchase;
  final MarketplaceReviewStatus status;
  final String? sellerResponse;
  final DateTime? sellerRespondedAt;
  final int helpfulCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isVisible => status == MarketplaceReviewStatus.published;
  bool get hasSellerResponse => sellerResponse != null;

  @override
  List<Object?> get props => [
        id,
        productId,
        buyerId,
        sellerId,
        rating,
        title,
        content,
        isVerifiedPurchase,
        status,
        sellerResponse,
        sellerRespondedAt,
        helpfulCount,
        reportCount,
        createdAt,
        updatedAt,
      ];

  MarketplaceReviewEntity copyWith({
    String? id,
    String? productId,
    String? buyerId,
    String? sellerId,
    int? rating,
    String? title,
    String? content,
    bool? isVerifiedPurchase,
    MarketplaceReviewStatus? status,
    String? sellerResponse,
    DateTime? sellerRespondedAt,
    int? helpfulCount,
    int? reportCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceReviewEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      content: content ?? this.content,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      status: status ?? this.status,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      sellerRespondedAt: sellerRespondedAt ?? this.sellerRespondedAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReviewHelpfulEntity extends Equatable {
  const ReviewHelpfulEntity({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String reviewId;
  final String userId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, reviewId, userId, createdAt];

  ReviewHelpfulEntity copyWith({
    String? id,
    String? reviewId,
    String? userId,
    DateTime? createdAt,
  }) {
    return ReviewHelpfulEntity(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Wishlist
// ───────────────────────────────────────────────────────────────────

class WishlistEntity extends Equatable {
  const WishlistEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, productId, createdAt];

  WishlistEntity copyWith({
    String? id,
    String? userId,
    String? productId,
    DateTime? createdAt,
  }) {
    return WishlistEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Promo Code
// ───────────────────────────────────────────────────────────────────

class PromoCodeEntity extends Equatable {
  const PromoCodeEntity({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxUses = 0,
    this.currentUses = 0,
    this.minOrderAmount = 0,
    this.maxDiscountAmount = 0,
    this.applicableProductTypes = const [],
    this.applicableSellerIds = const [],
    required this.startsAt,
    required this.expiresAt,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String? description;
  final DiscountType discountType;
  final double discountValue;
  final int maxUses;
  final int currentUses;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final List<MarketplaceProductType> applicableProductTypes;
  final List<String> applicableSellerIds;
  final DateTime startsAt;
  final DateTime expiresAt;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed getters
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startsAt) &&
        now.isBefore(expiresAt) &&
        hasUsesRemaining;
  }

  bool get hasUsesRemaining => maxUses == 0 || currentUses < maxUses;

  @override
  List<Object?> get props => [
        id,
        code,
        description,
        discountType,
        discountValue,
        maxUses,
        currentUses,
        minOrderAmount,
        maxDiscountAmount,
        applicableProductTypes,
        applicableSellerIds,
        startsAt,
        expiresAt,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];

  PromoCodeEntity copyWith({
    String? id,
    String? code,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    int? maxUses,
    int? currentUses,
    double? minOrderAmount,
    double? maxDiscountAmount,
    List<MarketplaceProductType>? applicableProductTypes,
    List<String>? applicableSellerIds,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoCodeEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      applicableProductTypes:
          applicableProductTypes ?? this.applicableProductTypes,
      applicableSellerIds: applicableSellerIds ?? this.applicableSellerIds,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Commission Rate & Commission Record
// ───────────────────────────────────────────────────────────────────

class CommissionRateEntity extends Equatable {
  const CommissionRateEntity({
    required this.id,
    required this.productType,
    required this.licenseType,
    required this.commissionRate,
    this.isActive = true,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final MarketplaceProductType productType;
  final MarketplaceLicenseType licenseType;
  final double commissionRate;
  final bool isActive;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCurrentlyEffective {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(effectiveFrom) &&
        (effectiveTo == null || now.isBefore(effectiveTo!));
  }

  @override
  List<Object?> get props => [
        id,
        productType,
        licenseType,
        commissionRate,
        isActive,
        effectiveFrom,
        effectiveTo,
        createdBy,
        createdAt,
        updatedAt,
      ];

  CommissionRateEntity copyWith({
    String? id,
    MarketplaceProductType? productType,
    MarketplaceLicenseType? licenseType,
    double? commissionRate,
    bool? isActive,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommissionRateEntity(
      id: id ?? this.id,
      productType: productType ?? this.productType,
      licenseType: licenseType ?? this.licenseType,
      commissionRate: commissionRate ?? this.commissionRate,
      isActive: isActive ?? this.isActive,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CommissionRecordEntity extends Equatable {
  const CommissionRecordEntity({
    required this.id,
    required this.orderItemId,
    required this.sellerId,
    required this.commissionType,
    required this.commissionRate,
    required this.commissionAmount,
    required this.sellerRevenue,
    this.currency = 'NGN',
    required this.createdAt,
  });

  final String id;
  final String orderItemId;
  final String sellerId;
  final CommissionType commissionType;
  final double commissionRate;
  final double commissionAmount;
  final double sellerRevenue;
  final String currency;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        orderItemId,
        sellerId,
        commissionType,
        commissionRate,
        commissionAmount,
        sellerRevenue,
        currency,
        createdAt,
      ];

  CommissionRecordEntity copyWith({
    String? id,
    String? orderItemId,
    String? sellerId,
    CommissionType? commissionType,
    double? commissionRate,
    double? commissionAmount,
    double? sellerRevenue,
    String? currency,
    DateTime? createdAt,
  }) {
    return CommissionRecordEntity(
      id: id ?? this.id,
      orderItemId: orderItemId ?? this.orderItemId,
      sellerId: sellerId ?? this.sellerId,
      commissionType: commissionType ?? this.commissionType,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      sellerRevenue: sellerRevenue ?? this.sellerRevenue,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Analytics
// ───────────────────────────────────────────────────────────────────

class SellerAnalyticsEntity extends Equatable {
  const SellerAnalyticsEntity({
    required this.id,
    required this.sellerId,
    required this.date,
    this.views = 0,
    this.sales = 0,
    this.revenue = 0,
    this.uniqueVisitors = 0,
    this.conversionRate = 0,
    this.averageRating = 0,
    this.newReviews = 0,
    required this.createdAt,
  });

  final String id;
  final String sellerId;
  final DateTime date;
  final int views;
  final int sales;
  final double revenue;
  final int uniqueVisitors;
  final double conversionRate;
  final double averageRating;
  final int newReviews;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        sellerId,
        date,
        views,
        sales,
        revenue,
        uniqueVisitors,
        conversionRate,
        averageRating,
        newReviews,
        createdAt,
      ];

  SellerAnalyticsEntity copyWith({
    String? id,
    String? sellerId,
    DateTime? date,
    int? views,
    int? sales,
    double? revenue,
    int? uniqueVisitors,
    double? conversionRate,
    double? averageRating,
    int? newReviews,
    DateTime? createdAt,
  }) {
    return SellerAnalyticsEntity(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      date: date ?? this.date,
      views: views ?? this.views,
      sales: sales ?? this.sales,
      revenue: revenue ?? this.revenue,
      uniqueVisitors: uniqueVisitors ?? this.uniqueVisitors,
      conversionRate: conversionRate ?? this.conversionRate,
      averageRating: averageRating ?? this.averageRating,
      newReviews: newReviews ?? this.newReviews,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProductAnalyticsEntity extends Equatable {
  const ProductAnalyticsEntity({
    required this.id,
    required this.productId,
    required this.date,
    this.views = 0,
    this.downloads = 0,
    this.sales = 0,
    this.revenue = 0,
    this.searchImpressions = 0,
    this.clickThroughRate = 0,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final DateTime date;
  final int views;
  final int downloads;
  final int sales;
  final double revenue;
  final int searchImpressions;
  final double clickThroughRate;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        productId,
        date,
        views,
        downloads,
        sales,
        revenue,
        searchImpressions,
        clickThroughRate,
        createdAt,
      ];

  ProductAnalyticsEntity copyWith({
    String? id,
    String? productId,
    DateTime? date,
    int? views,
    int? downloads,
    int? sales,
    double? revenue,
    int? searchImpressions,
    double? clickThroughRate,
    DateTime? createdAt,
  }) {
    return ProductAnalyticsEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      date: date ?? this.date,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
      sales: sales ?? this.sales,
      revenue: revenue ?? this.revenue,
      searchImpressions: searchImpressions ?? this.searchImpressions,
      clickThroughRate: clickThroughRate ?? this.clickThroughRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Search & AI Recommendation
// ───────────────────────────────────────────────────────────────────

class MarketplaceSearchLogEntity extends Equatable {
  const MarketplaceSearchLogEntity({
    required this.id,
    this.userId,
    required this.query,
    this.filters,
    this.resultsCount = 0,
    this.clickedProductId,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final String query;
  final Map<String, dynamic>? filters;
  final int resultsCount;
  final String? clickedProductId;
  final DateTime createdAt;

  bool get hasClick => clickedProductId != null;

  @override
  List<Object?> get props => [
        id,
        userId,
        query,
        filters,
        resultsCount,
        clickedProductId,
        createdAt,
      ];

  MarketplaceSearchLogEntity copyWith({
    String? id,
    String? userId,
    String? query,
    Map<String, dynamic>? filters,
    int? resultsCount,
    String? clickedProductId,
    DateTime? createdAt,
  }) {
    return MarketplaceSearchLogEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      resultsCount: resultsCount ?? this.resultsCount,
      clickedProductId: clickedProductId ?? this.clickedProductId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AIRecommendationEntity extends Equatable {
  const AIRecommendationEntity({
    required this.id,
    required this.userId,
    required this.productId,
    required this.recommendationType,
    this.recommendationReason,
    this.score = 0,
    this.wasClicked = false,
    this.wasPurchased = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String recommendationType;
  final String? recommendationReason;
  final double score;
  final bool wasClicked;
  final bool wasPurchased;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        productId,
        recommendationType,
        recommendationReason,
        score,
        wasClicked,
        wasPurchased,
        createdAt,
      ];

  AIRecommendationEntity copyWith({
    String? id,
    String? userId,
    String? productId,
    String? recommendationType,
    String? recommendationReason,
    double? score,
    bool? wasClicked,
    bool? wasPurchased,
    DateTime? createdAt,
  }) {
    return AIRecommendationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      recommendationType: recommendationType ?? this.recommendationType,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      score: score ?? this.score,
      wasClicked: wasClicked ?? this.wasClicked,
      wasPurchased: wasPurchased ?? this.wasPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Quality Check
// ───────────────────────────────────────────────────────────────────

class QualityCheckEntity extends Equatable {
  const QualityCheckEntity({
    required this.id,
    required this.productId,
    required this.overallScore,
    this.grammarScore = 0,
    this.spellingScore = 0,
    this.formattingScore = 0,
    this.curriculumAlignmentScore = 0,
    this.readingLevel = 0,
    this.readingLevelLabel,
    this.duplicateCheckResult,
    this.accuracyFlag = false,
    this.accuracyDetails,
    this.suggestions = const [],
    this.flaggedIssues = const [],
    required this.checkedAt,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final double overallScore;
  final double grammarScore;
  final double spellingScore;
  final double formattingScore;
  final double curriculumAlignmentScore;
  final double readingLevel;
  final String? readingLevelLabel;
  final Map<String, dynamic>? duplicateCheckResult;
  final bool accuracyFlag;
  final Map<String, dynamic>? accuracyDetails;
  final List<String> suggestions;
  final List<String> flaggedIssues;
  final DateTime checkedAt;
  final DateTime createdAt;

  // Computed getter
  QualityCheckStatus get computedStatus {
    if (overallScore >= 80) return QualityCheckStatus.passed;
    if (overallScore >= 50) return QualityCheckStatus.needsImprovement;
    return QualityCheckStatus.failed;
  }

  bool get hasIssues => flaggedIssues.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        productId,
        overallScore,
        grammarScore,
        spellingScore,
        formattingScore,
        curriculumAlignmentScore,
        readingLevel,
        readingLevelLabel,
        duplicateCheckResult,
        accuracyFlag,
        accuracyDetails,
        suggestions,
        flaggedIssues,
        checkedAt,
        createdAt,
      ];

  QualityCheckEntity copyWith({
    String? id,
    String? productId,
    double? overallScore,
    double? grammarScore,
    double? spellingScore,
    double? formattingScore,
    double? curriculumAlignmentScore,
    double? readingLevel,
    String? readingLevelLabel,
    Map<String, dynamic>? duplicateCheckResult,
    bool? accuracyFlag,
    Map<String, dynamic>? accuracyDetails,
    List<String>? suggestions,
    List<String>? flaggedIssues,
    DateTime? checkedAt,
    DateTime? createdAt,
  }) {
    return QualityCheckEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      overallScore: overallScore ?? this.overallScore,
      grammarScore: grammarScore ?? this.grammarScore,
      spellingScore: spellingScore ?? this.spellingScore,
      formattingScore: formattingScore ?? this.formattingScore,
      curriculumAlignmentScore:
          curriculumAlignmentScore ?? this.curriculumAlignmentScore,
      readingLevel: readingLevel ?? this.readingLevel,
      readingLevelLabel: readingLevelLabel ?? this.readingLevelLabel,
      duplicateCheckResult:
          duplicateCheckResult ?? this.duplicateCheckResult,
      accuracyFlag: accuracyFlag ?? this.accuracyFlag,
      accuracyDetails: accuracyDetails ?? this.accuracyDetails,
      suggestions: suggestions ?? this.suggestions,
      flaggedIssues: flaggedIssues ?? this.flaggedIssues,
      checkedAt: checkedAt ?? this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Dispute
// ───────────────────────────────────────────────────────────────────

class DisputeEntity extends Equatable {
  const DisputeEntity({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.reason,
    this.description,
    required this.status,
    this.resolution,
    this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String reason;
  final String? description;
  final DisputeStatus status;
  final String? resolution;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isResolved =>
      status == DisputeStatus.resolved || status == DisputeStatus.closed;
  bool get isOpen => status == DisputeStatus.open;

  @override
  List<Object?> get props => [
        id,
        orderId,
        buyerId,
        sellerId,
        reason,
        description,
        status,
        resolution,
        resolvedBy,
        createdAt,
        updatedAt,
      ];

  DisputeEntity copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    String? reason,
    String? description,
    DisputeStatus? status,
    String? resolution,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DisputeEntity(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Notification
// ───────────────────────────────────────────────────────────────────

class MarketplaceNotificationEntity extends Equatable {
  const MarketplaceNotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final MarketplaceNotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        data,
        isRead,
        createdAt,
      ];

  MarketplaceNotificationEntity copyWith({
    String? id,
    String? userId,
    MarketplaceNotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MarketplaceNotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Saved Search
// ───────────────────────────────────────────────────────────────────

class SavedSearchEntity extends Equatable {
  const SavedSearchEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.filters,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final Map<String, dynamic> filters;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, name, filters, createdAt];

  SavedSearchEntity copyWith({
    String? id,
    String? userId,
    String? name,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
  }) {
    return SavedSearchEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
