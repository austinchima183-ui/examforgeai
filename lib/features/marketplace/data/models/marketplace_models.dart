import '../../domain/entities/marketplace_entities.dart';

// ============================================================================
// UTILITY HELPERS
// ============================================================================

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    final aVal = a[key];
    final bVal = b[key];
    if (aVal is Map<String, dynamic> && bVal is Map<String, dynamic>) {
      if (!_mapEquals(aVal, bVal)) return false;
    } else if (aVal is List && bVal is List) {
      if (aVal.length != bVal.length) return false;
      for (var i = 0; i < aVal.length; i++) {
        if (aVal[i] is Map<String, dynamic> &&
            bVal[i] is Map<String, dynamic>) {
          if (!_mapEquals(aVal[i] as Map<String, dynamic>,
              bVal[i] as Map<String, dynamic>,)) {
            return false;
          }
        } else if (aVal[i] != bVal[i]) {
          return false;
        }
      }
    } else if (aVal != bVal) {
      return false;
    }
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] is Map<String, dynamic> && b[i] is Map<String, dynamic>) {
      if (!_mapEquals(a[i] as Map<String, dynamic>,
          b[i] as Map<String, dynamic>,)) {
        return false;
      }
    } else if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

// ============================================================================
// 1. MARKETPLACE CATEGORY MODEL
// ============================================================================

class MarketplaceCategoryModel {
  const MarketplaceCategoryModel({
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

  factory MarketplaceCategoryModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategoryModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String? ?? json['parentId'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      sortOrder:
          json['sort_order'] as int? ?? json['sortOrder'] as int? ?? 0,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parent_id': parentId,
        'name': name,
        'slug': slug,
        'description': description,
        'icon': icon,
        'sort_order': sortOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MarketplaceCategoryModel.fromEntity(
      MarketplaceCategoryEntity entity,) {
    return MarketplaceCategoryModel(
      id: entity.id,
      parentId: entity.parentId,
      name: entity.name,
      slug: entity.slug,
      description: entity.description,
      icon: entity.icon,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MarketplaceCategoryEntity toEntity() {
    return MarketplaceCategoryEntity(
      id: id,
      parentId: parentId,
      name: name,
      slug: slug,
      description: description,
      icon: icon,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MarketplaceCategoryModel copyWith({
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
    return MarketplaceCategoryModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceCategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentId == other.parentId &&
          name == other.name &&
          slug == other.slug &&
          description == other.description &&
          icon == other.icon &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 2. SELLER PROFILE MODEL
// ============================================================================

class SellerProfileModel {
  const SellerProfileModel({
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

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    return SellerProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      displayName: json['display_name'] as String? ?? json['displayName'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      status: MarketplaceSellerStatus.fromString(
              json['status'] as String?,) ??
          MarketplaceSellerStatus.pendingVerification,
      verificationLevel: json['verification_level'] as int? ??
          json['verificationLevel'] as int? ??
          0,
      totalSales: json['total_sales'] as int? ?? json['totalSales'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num? ??
              json['totalRevenue'] as num?)
          ?.toDouble() ??
          0,
      averageRating: (json['average_rating'] as num? ??
              json['averageRating'] as num?)
          ?.toDouble() ??
          0,
      totalReviews:
          json['total_reviews'] as int? ?? json['totalReviews'] as int? ?? 0,
      totalProducts: json['total_products'] as int? ??
          json['totalProducts'] as int? ??
          0,
      bankAccountEncrypted: json['bank_account_encrypted'] as String? ??
          json['bankAccountEncrypted'] as String?,
      payoutMethod: json['payout_method'] as String? ??
          json['payoutMethod'] as String?,
      payoutDetailsEncrypted: json['payout_details_encrypted'] as String? ??
          json['payoutDetailsEncrypted'] as String?,
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : json['verifiedAt'] != null
              ? DateTime.parse(json['verifiedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'status': status.value,
        'verification_level': verificationLevel,
        'total_sales': totalSales,
        'total_revenue': totalRevenue,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'total_products': totalProducts,
        'bank_account_encrypted': bankAccountEncrypted,
        'payout_method': payoutMethod,
        'payout_details_encrypted': payoutDetailsEncrypted,
        'is_verified': isVerified,
        'verified_at': verifiedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SellerProfileModel.fromEntity(SellerProfileEntity entity) {
    return SellerProfileModel(
      id: entity.id,
      userId: entity.userId,
      displayName: entity.displayName,
      bio: entity.bio,
      avatarUrl: entity.avatarUrl,
      status: entity.status,
      verificationLevel: entity.verificationLevel,
      totalSales: entity.totalSales,
      totalRevenue: entity.totalRevenue,
      averageRating: entity.averageRating,
      totalReviews: entity.totalReviews,
      totalProducts: entity.totalProducts,
      bankAccountEncrypted: entity.bankAccountEncrypted,
      payoutMethod: entity.payoutMethod,
      payoutDetailsEncrypted: entity.payoutDetailsEncrypted,
      isVerified: entity.isVerified,
      verifiedAt: entity.verifiedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  SellerProfileEntity toEntity() {
    return SellerProfileEntity(
      id: id,
      userId: userId,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      status: status,
      verificationLevel: verificationLevel,
      totalSales: totalSales,
      totalRevenue: totalRevenue,
      averageRating: averageRating,
      totalReviews: totalReviews,
      totalProducts: totalProducts,
      bankAccountEncrypted: bankAccountEncrypted,
      payoutMethod: payoutMethod,
      payoutDetailsEncrypted: payoutDetailsEncrypted,
      isVerified: isVerified,
      verifiedAt: verifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SellerProfileModel copyWith({
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
    return SellerProfileModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerProfileModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          displayName == other.displayName &&
          bio == other.bio &&
          avatarUrl == other.avatarUrl &&
          status == other.status &&
          verificationLevel == other.verificationLevel &&
          totalSales == other.totalSales &&
          totalRevenue == other.totalRevenue &&
          averageRating == other.averageRating &&
          totalReviews == other.totalReviews &&
          totalProducts == other.totalProducts &&
          bankAccountEncrypted == other.bankAccountEncrypted &&
          payoutMethod == other.payoutMethod &&
          payoutDetailsEncrypted == other.payoutDetailsEncrypted &&
          isVerified == other.isVerified &&
          verifiedAt == other.verifiedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 3. MARKETPLACE PRODUCT MODEL
// ============================================================================

class MarketplaceProductModel {
  const MarketplaceProductModel({
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

  factory MarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceProductModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      categoryId:
          json['category_id'] as String? ?? json['categoryId'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      productType: MarketplaceProductType.fromString(
              json['product_type'] as String? ??
                  json['productType'] as String?,) ??
          MarketplaceProductType.other,
      subject: json['subject'] as String?,
      classLevel:
          json['class_level'] as String? ?? json['classLevel'] as String?,
      curriculum: json['curriculum'] as String?,
      language: json['language'] as String?,
      previewImages:
          (json['preview_images'] as List<dynamic>? ??
                  json['previewImages'] as List<dynamic>?)
              ?.cast<String>() ??
              [],
      previewDocuments:
          (json['preview_documents'] as List<dynamic>? ??
                  json['previewDocuments'] as List<dynamic>?)
              ?.cast<String>() ??
              [],
      fullDocumentUrls:
          (json['full_document_urls'] as List<dynamic>? ??
                  json['fullDocumentUrls'] as List<dynamic>?)
              ?.cast<String>() ??
              [],
      price:
          (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num? ??
              json['originalPrice'] as num?)
          ?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'NGN',
      licenseType: MarketplaceLicenseType.fromString(
              json['license_type'] as String? ??
                  json['licenseType'] as String?,) ??
          MarketplaceLicenseType.personal,
      licenseConfig: json['license_config'] as Map<String, dynamic>? ??
          json['licenseConfig'] as Map<String, dynamic>?,
      version: json['version'] as String? ?? '1.0.0',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      aiGeneratedSummary: json['ai_generated_summary'] as String? ??
          json['aiGeneratedSummary'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ??
          json['isAiGenerated'] as bool? ??
          false,
      isFeatured:
          json['is_featured'] as bool? ?? json['isFeatured'] as bool? ?? false,
      isFree: json['is_free'] as bool? ?? json['isFree'] as bool? ?? false,
      status: MarketplaceProductStatus.fromString(
              json['status'] as String?,) ??
          MarketplaceProductStatus.draft,
      qualityScore: (json['quality_score'] as num? ??
              json['qualityScore'] as num?)
          ?.toDouble() ??
          0,
      qualityCheckStatus: QualityCheckStatus.fromString(
              json['quality_check_status'] as String? ??
                  json['qualityCheckStatus'] as String?,) ??
          QualityCheckStatus.pending,
      qualityCheckDetails:
          json['quality_check_details'] as Map<String, dynamic>? ??
              json['qualityCheckDetails'] as Map<String, dynamic>?,
      totalSales:
          json['total_sales'] as int? ?? json['totalSales'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num? ??
              json['totalRevenue'] as num?)
          ?.toDouble() ??
          0,
      averageRating: (json['average_rating'] as num? ??
              json['averageRating'] as num?)
          ?.toDouble() ??
          0,
      totalReviews:
          json['total_reviews'] as int? ?? json['totalReviews'] as int? ?? 0,
      downloadCount: json['download_count'] as int? ??
          json['downloadCount'] as int? ??
          0,
      viewCount:
          json['view_count'] as int? ?? json['viewCount'] as int? ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : json['publishedAt'] != null
              ? DateTime.parse(json['publishedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : json['deletedAt'] != null
              ? DateTime.parse(json['deletedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'category_id': categoryId,
        'title': title,
        'slug': slug,
        'description': description,
        'product_type': productType.value,
        'subject': subject,
        'class_level': classLevel,
        'curriculum': curriculum,
        'language': language,
        'preview_images': previewImages,
        'preview_documents': previewDocuments,
        'full_document_urls': fullDocumentUrls,
        'price': price,
        'original_price': originalPrice,
        'currency': currency,
        'license_type': licenseType.value,
        'license_config': licenseConfig,
        'version': version,
        'tags': tags,
        'ai_generated_summary': aiGeneratedSummary,
        'is_ai_generated': isAiGenerated,
        'is_featured': isFeatured,
        'is_free': isFree,
        'status': status.value,
        'quality_score': qualityScore,
        'quality_check_status': qualityCheckStatus.value,
        'quality_check_details': qualityCheckDetails,
        'total_sales': totalSales,
        'total_revenue': totalRevenue,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'download_count': downloadCount,
        'view_count': viewCount,
        'published_at': publishedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  factory MarketplaceProductModel.fromEntity(MarketplaceProductEntity entity) {
    return MarketplaceProductModel(
      id: entity.id,
      sellerId: entity.sellerId,
      categoryId: entity.categoryId,
      title: entity.title,
      slug: entity.slug,
      description: entity.description,
      productType: entity.productType,
      subject: entity.subject,
      classLevel: entity.classLevel,
      curriculum: entity.curriculum,
      language: entity.language,
      previewImages: entity.previewImages,
      previewDocuments: entity.previewDocuments,
      fullDocumentUrls: entity.fullDocumentUrls,
      price: entity.price,
      originalPrice: entity.originalPrice,
      currency: entity.currency,
      licenseType: entity.licenseType,
      licenseConfig: entity.licenseConfig,
      version: entity.version,
      tags: entity.tags,
      aiGeneratedSummary: entity.aiGeneratedSummary,
      isAiGenerated: entity.isAiGenerated,
      isFeatured: entity.isFeatured,
      isFree: entity.isFree,
      status: entity.status,
      qualityScore: entity.qualityScore,
      qualityCheckStatus: entity.qualityCheckStatus,
      qualityCheckDetails: entity.qualityCheckDetails,
      totalSales: entity.totalSales,
      totalRevenue: entity.totalRevenue,
      averageRating: entity.averageRating,
      totalReviews: entity.totalReviews,
      downloadCount: entity.downloadCount,
      viewCount: entity.viewCount,
      publishedAt: entity.publishedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  MarketplaceProductEntity toEntity() {
    return MarketplaceProductEntity(
      id: id,
      sellerId: sellerId,
      categoryId: categoryId,
      title: title,
      slug: slug,
      description: description,
      productType: productType,
      subject: subject,
      classLevel: classLevel,
      curriculum: curriculum,
      language: language,
      previewImages: previewImages,
      previewDocuments: previewDocuments,
      fullDocumentUrls: fullDocumentUrls,
      price: price,
      originalPrice: originalPrice,
      currency: currency,
      licenseType: licenseType,
      licenseConfig: licenseConfig,
      version: version,
      tags: tags,
      aiGeneratedSummary: aiGeneratedSummary,
      isAiGenerated: isAiGenerated,
      isFeatured: isFeatured,
      isFree: isFree,
      status: status,
      qualityScore: qualityScore,
      qualityCheckStatus: qualityCheckStatus,
      qualityCheckDetails: qualityCheckDetails,
      totalSales: totalSales,
      totalRevenue: totalRevenue,
      averageRating: averageRating,
      totalReviews: totalReviews,
      downloadCount: downloadCount,
      viewCount: viewCount,
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  MarketplaceProductModel copyWith({
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
    return MarketplaceProductModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sellerId == other.sellerId &&
          categoryId == other.categoryId &&
          title == other.title &&
          slug == other.slug &&
          description == other.description &&
          productType == other.productType &&
          subject == other.subject &&
          classLevel == other.classLevel &&
          curriculum == other.curriculum &&
          language == other.language &&
          _listEquals(previewImages, other.previewImages) &&
          _listEquals(previewDocuments, other.previewDocuments) &&
          _listEquals(fullDocumentUrls, other.fullDocumentUrls) &&
          price == other.price &&
          originalPrice == other.originalPrice &&
          currency == other.currency &&
          licenseType == other.licenseType &&
          _mapEquals(licenseConfig, other.licenseConfig) &&
          version == other.version &&
          _listEquals(tags, other.tags) &&
          aiGeneratedSummary == other.aiGeneratedSummary &&
          isAiGenerated == other.isAiGenerated &&
          isFeatured == other.isFeatured &&
          isFree == other.isFree &&
          status == other.status &&
          qualityScore == other.qualityScore &&
          qualityCheckStatus == other.qualityCheckStatus &&
          _mapEquals(qualityCheckDetails, other.qualityCheckDetails) &&
          totalSales == other.totalSales &&
          totalRevenue == other.totalRevenue &&
          averageRating == other.averageRating &&
          totalReviews == other.totalReviews &&
          downloadCount == other.downloadCount &&
          viewCount == other.viewCount &&
          publishedAt == other.publishedAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hashAll([
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
      ]);
}

// ============================================================================
// 4. PRODUCT VERSION MODEL
// ============================================================================

class ProductVersionModel {
  const ProductVersionModel({
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

  factory ProductVersionModel.fromJson(Map<String, dynamic> json) {
    return ProductVersionModel(
      id: json['id'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      version: json['version'] as String,
      changelog: json['changelog'] as String?,
      documentUrls:
          (json['document_urls'] as List<dynamic>? ??
                  json['documentUrls'] as List<dynamic>?)
              ?.cast<String>() ??
              [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'version': version,
        'changelog': changelog,
        'document_urls': documentUrls,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductVersionModel.fromEntity(ProductVersionEntity entity) {
    return ProductVersionModel(
      id: entity.id,
      productId: entity.productId,
      version: entity.version,
      changelog: entity.changelog,
      documentUrls: entity.documentUrls,
      createdAt: entity.createdAt,
    );
  }

  ProductVersionEntity toEntity() {
    return ProductVersionEntity(
      id: id,
      productId: productId,
      version: version,
      changelog: changelog,
      documentUrls: documentUrls,
      createdAt: createdAt,
    );
  }

  ProductVersionModel copyWith({
    String? id,
    String? productId,
    String? version,
    String? changelog,
    List<String>? documentUrls,
    DateTime? createdAt,
  }) {
    return ProductVersionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      version: version ?? this.version,
      changelog: changelog ?? this.changelog,
      documentUrls: documentUrls ?? this.documentUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVersionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          version == other.version &&
          changelog == other.changelog &&
          _listEquals(documentUrls, other.documentUrls) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        productId,
        version,
        changelog,
        Object.hashAll(documentUrls),
        createdAt,
      );
}

// ============================================================================
// 5. CART ITEM MODEL
// ============================================================================

class CartItemModel {
  const CartItemModel({
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
  final MarketplaceProductModel? product;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      cartId: json['cart_id'] as String? ?? json['cartId'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      licenseType: MarketplaceLicenseType.fromString(
              json['license_type'] as String? ??
                  json['licenseType'] as String?,) ??
          MarketplaceLicenseType.personal,
      quantity: json['quantity'] as int? ?? 1,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : json['addedAt'] != null
              ? DateTime.parse(json['addedAt'] as String)
              : DateTime.now(),
      product: json['product'] != null
          ? MarketplaceProductModel.fromJson(
              json['product'] as Map<String, dynamic>,)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cart_id': cartId,
        'product_id': productId,
        'license_type': licenseType.value,
        'quantity': quantity,
        'added_at': addedAt.toIso8601String(),
      };

  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      id: entity.id,
      cartId: entity.cartId,
      productId: entity.productId,
      licenseType: entity.licenseType,
      quantity: entity.quantity,
      addedAt: entity.addedAt,
      product: entity.product != null
          ? MarketplaceProductModel.fromEntity(entity.product!)
          : null,
    );
  }

  CartItemEntity toEntity() {
    return CartItemEntity(
      id: id,
      cartId: cartId,
      productId: productId,
      licenseType: licenseType,
      quantity: quantity,
      addedAt: addedAt,
      product: product?.toEntity(),
    );
  }

  CartItemModel copyWith({
    String? id,
    String? cartId,
    String? productId,
    MarketplaceLicenseType? licenseType,
    int? quantity,
    DateTime? addedAt,
    MarketplaceProductModel? product,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      licenseType: licenseType ?? this.licenseType,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      product: product ?? this.product,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          cartId == other.cartId &&
          productId == other.productId &&
          licenseType == other.licenseType &&
          quantity == other.quantity &&
          addedAt == other.addedAt &&
          product == other.product;

  @override
  int get hashCode => Object.hash(
        id,
        cartId,
        productId,
        licenseType,
        quantity,
        addedAt,
        product,
      );
}

// ============================================================================
// 6. CART MODEL
// ============================================================================

class CartModel {
  const CartModel({
    required this.id,
    required this.userId,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final List<CartItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  // toJson omits items — they are handled separately in the DB layer.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CartModel.fromEntity(CartEntity entity) {
    return CartModel(
      id: entity.id,
      userId: entity.userId,
      items: entity.items
          .map((e) => CartItemModel.fromEntity(e))
          .toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CartEntity toEntity() {
    return CartEntity(
      id: id,
      userId: userId,
      items: items.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          _listEquals(items, other.items) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        Object.hashAll(items),
        createdAt,
        updatedAt,
      );
}

// ============================================================================
// 7. ORDER ITEM MODEL
// ============================================================================

class OrderItemModel {
  const OrderItemModel({
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? json['orderId'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      licenseType: MarketplaceLicenseType.fromString(
              json['license_type'] as String? ??
                  json['licenseType'] as String?,) ??
          MarketplaceLicenseType.personal,
      priceAtPurchase: (json['price_at_purchase'] as num? ??
              json['priceAtPurchase'] as num?)
          ?.toDouble() ??
          0,
      platformFee: (json['platform_fee'] as num? ??
              json['platformFee'] as num?)
          ?.toDouble() ??
          0,
      sellerRevenue: (json['seller_revenue'] as num? ??
              json['sellerRevenue'] as num?)
          ?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'NGN',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'product_id': productId,
        'seller_id': sellerId,
        'license_type': licenseType.value,
        'price_at_purchase': priceAtPurchase,
        'platform_fee': platformFee,
        'seller_revenue': sellerRevenue,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
      };

  factory OrderItemModel.fromEntity(OrderItemEntity entity) {
    return OrderItemModel(
      id: entity.id,
      orderId: entity.orderId,
      productId: entity.productId,
      sellerId: entity.sellerId,
      licenseType: entity.licenseType,
      priceAtPurchase: entity.priceAtPurchase,
      platformFee: entity.platformFee,
      sellerRevenue: entity.sellerRevenue,
      currency: entity.currency,
      createdAt: entity.createdAt,
    );
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      orderId: orderId,
      productId: productId,
      sellerId: sellerId,
      licenseType: licenseType,
      priceAtPurchase: priceAtPurchase,
      platformFee: platformFee,
      sellerRevenue: sellerRevenue,
      currency: currency,
      createdAt: createdAt,
    );
  }

  OrderItemModel copyWith({
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
    return OrderItemModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          productId == other.productId &&
          sellerId == other.sellerId &&
          licenseType == other.licenseType &&
          priceAtPurchase == other.priceAtPurchase &&
          platformFee == other.platformFee &&
          sellerRevenue == other.sellerRevenue &&
          currency == other.currency &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 8. MARKETPLACE ORDER MODEL
// ============================================================================

class MarketplaceOrderModel {
  const MarketplaceOrderModel({
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
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String? ?? json['buyerId'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      orderNumber: json['order_number'] as String? ??
          json['orderNumber'] as String,
      status: MarketplaceOrderStatus.fromString(json['status'] as String?) ??
          MarketplaceOrderStatus.pending,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platform_fee'] as num? ??
              json['platformFee'] as num?)
          ?.toDouble() ??
          0,
      taxAmount: (json['tax_amount'] as num? ?? json['taxAmount'] as num?)
          ?.toDouble() ??
          0,
      discountAmount: (json['discount_amount'] as num? ??
              json['discountAmount'] as num?)
          ?.toDouble() ??
          0,
      totalAmount: (json['total_amount'] as num? ??
              json['totalAmount'] as num?)
          ?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'NGN',
      promoCodeId: json['promo_code_id'] as String? ??
          json['promoCodeId'] as String?,
      flutterwaveTxRef: json['flutterwave_tx_ref'] as String? ??
          json['flutterwaveTxRef'] as String?,
      flutterwaveFlwRef: json['flutterwave_flw_ref'] as String? ??
          json['flutterwaveFlwRef'] as String?,
      paymentMethod: json['payment_method'] as String? ??
          json['paymentMethod'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : json['paidAt'] != null
              ? DateTime.parse(json['paidAt'] as String)
              : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'order_number': orderNumber,
        'status': status.value,
        'subtotal': subtotal,
        'platform_fee': platformFee,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'currency': currency,
        'promo_code_id': promoCodeId,
        'flutterwave_tx_ref': flutterwaveTxRef,
        'flutterwave_flw_ref': flutterwaveFlwRef,
        'payment_method': paymentMethod,
        'paid_at': paidAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MarketplaceOrderModel.fromEntity(MarketplaceOrderEntity entity) {
    return MarketplaceOrderModel(
      id: entity.id,
      buyerId: entity.buyerId,
      sellerId: entity.sellerId,
      orderNumber: entity.orderNumber,
      status: entity.status,
      subtotal: entity.subtotal,
      platformFee: entity.platformFee,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      totalAmount: entity.totalAmount,
      currency: entity.currency,
      promoCodeId: entity.promoCodeId,
      flutterwaveTxRef: entity.flutterwaveTxRef,
      flutterwaveFlwRef: entity.flutterwaveFlwRef,
      paymentMethod: entity.paymentMethod,
      paidAt: entity.paidAt,
      items: entity.items.map((e) => OrderItemModel.fromEntity(e)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MarketplaceOrderEntity toEntity() {
    return MarketplaceOrderEntity(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      orderNumber: orderNumber,
      status: status,
      subtotal: subtotal,
      platformFee: platformFee,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      totalAmount: totalAmount,
      currency: currency,
      promoCodeId: promoCodeId,
      flutterwaveTxRef: flutterwaveTxRef,
      flutterwaveFlwRef: flutterwaveFlwRef,
      paymentMethod: paymentMethod,
      paidAt: paidAt,
      items: items.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MarketplaceOrderModel copyWith({
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
    List<OrderItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceOrderModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceOrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          buyerId == other.buyerId &&
          sellerId == other.sellerId &&
          orderNumber == other.orderNumber &&
          status == other.status &&
          subtotal == other.subtotal &&
          platformFee == other.platformFee &&
          taxAmount == other.taxAmount &&
          discountAmount == other.discountAmount &&
          totalAmount == other.totalAmount &&
          currency == other.currency &&
          promoCodeId == other.promoCodeId &&
          flutterwaveTxRef == other.flutterwaveTxRef &&
          flutterwaveFlwRef == other.flutterwaveFlwRef &&
          paymentMethod == other.paymentMethod &&
          paidAt == other.paidAt &&
          _listEquals(items, other.items) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
        Object.hashAll(items),
        createdAt,
        updatedAt,
      );
}

// ============================================================================
// 9. MARKETPLACE PURCHASE MODEL
// ============================================================================

class MarketplacePurchaseModel {
  const MarketplacePurchaseModel({
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

  factory MarketplacePurchaseModel.fromJson(Map<String, dynamic> json) {
    return MarketplacePurchaseModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String? ?? json['buyerId'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      orderItemId: json['order_item_id'] as String? ??
          json['orderItemId'] as String,
      licenseType: MarketplaceLicenseType.fromString(
              json['license_type'] as String? ??
                  json['licenseType'] as String?,) ??
          MarketplaceLicenseType.personal,
      licenseKey: json['license_key'] as String? ??
          json['licenseKey'] as String?,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      downloadCount: json['download_count'] as int? ??
          json['downloadCount'] as int? ??
          0,
      lastDownloadedAt: json['last_downloaded_at'] != null
          ? DateTime.parse(json['last_downloaded_at'] as String)
          : json['lastDownloadedAt'] != null
              ? DateTime.parse(json['lastDownloadedAt'] as String)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyer_id': buyerId,
        'product_id': productId,
        'order_item_id': orderItemId,
        'license_type': licenseType.value,
        'license_key': licenseKey,
        'is_active': isActive,
        'expires_at': expiresAt?.toIso8601String(),
        'download_count': downloadCount,
        'last_downloaded_at': lastDownloadedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory MarketplacePurchaseModel.fromEntity(
      MarketplacePurchaseEntity entity,) {
    return MarketplacePurchaseModel(
      id: entity.id,
      buyerId: entity.buyerId,
      productId: entity.productId,
      orderItemId: entity.orderItemId,
      licenseType: entity.licenseType,
      licenseKey: entity.licenseKey,
      isActive: entity.isActive,
      expiresAt: entity.expiresAt,
      downloadCount: entity.downloadCount,
      lastDownloadedAt: entity.lastDownloadedAt,
      createdAt: entity.createdAt,
    );
  }

  MarketplacePurchaseEntity toEntity() {
    return MarketplacePurchaseEntity(
      id: id,
      buyerId: buyerId,
      productId: productId,
      orderItemId: orderItemId,
      licenseType: licenseType,
      licenseKey: licenseKey,
      isActive: isActive,
      expiresAt: expiresAt,
      downloadCount: downloadCount,
      lastDownloadedAt: lastDownloadedAt,
      createdAt: createdAt,
    );
  }

  MarketplacePurchaseModel copyWith({
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
    return MarketplacePurchaseModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplacePurchaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          buyerId == other.buyerId &&
          productId == other.productId &&
          orderItemId == other.orderItemId &&
          licenseType == other.licenseType &&
          licenseKey == other.licenseKey &&
          isActive == other.isActive &&
          expiresAt == other.expiresAt &&
          downloadCount == other.downloadCount &&
          lastDownloadedAt == other.lastDownloadedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 10. MARKETPLACE REVIEW MODEL
// ============================================================================

class MarketplaceReviewModel {
  const MarketplaceReviewModel({
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

  factory MarketplaceReviewModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceReviewModel(
      id: json['id'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      buyerId: json['buyer_id'] as String? ?? json['buyerId'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      rating: json['rating'] as int? ?? 0,
      title: json['title'] as String?,
      content: json['content'] as String?,
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ??
          json['isVerifiedPurchase'] as bool? ??
          false,
      status: MarketplaceReviewStatus.fromString(json['status'] as String?) ??
          MarketplaceReviewStatus.published,
      sellerResponse: json['seller_response'] as String? ??
          json['sellerResponse'] as String?,
      sellerRespondedAt: json['seller_responded_at'] != null
          ? DateTime.parse(json['seller_responded_at'] as String)
          : json['sellerRespondedAt'] != null
              ? DateTime.parse(json['sellerRespondedAt'] as String)
              : null,
      helpfulCount:
          json['helpful_count'] as int? ?? json['helpfulCount'] as int? ?? 0,
      reportCount:
          json['report_count'] as int? ?? json['reportCount'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'rating': rating,
        'title': title,
        'content': content,
        'is_verified_purchase': isVerifiedPurchase,
        'status': status.value,
        'seller_response': sellerResponse,
        'seller_responded_at': sellerRespondedAt?.toIso8601String(),
        'helpful_count': helpfulCount,
        'report_count': reportCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MarketplaceReviewModel.fromEntity(MarketplaceReviewEntity entity) {
    return MarketplaceReviewModel(
      id: entity.id,
      productId: entity.productId,
      buyerId: entity.buyerId,
      sellerId: entity.sellerId,
      rating: entity.rating,
      title: entity.title,
      content: entity.content,
      isVerifiedPurchase: entity.isVerifiedPurchase,
      status: entity.status,
      sellerResponse: entity.sellerResponse,
      sellerRespondedAt: entity.sellerRespondedAt,
      helpfulCount: entity.helpfulCount,
      reportCount: entity.reportCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  MarketplaceReviewEntity toEntity() {
    return MarketplaceReviewEntity(
      id: id,
      productId: productId,
      buyerId: buyerId,
      sellerId: sellerId,
      rating: rating,
      title: title,
      content: content,
      isVerifiedPurchase: isVerifiedPurchase,
      status: status,
      sellerResponse: sellerResponse,
      sellerRespondedAt: sellerRespondedAt,
      helpfulCount: helpfulCount,
      reportCount: reportCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  MarketplaceReviewModel copyWith({
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
    return MarketplaceReviewModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceReviewModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          buyerId == other.buyerId &&
          sellerId == other.sellerId &&
          rating == other.rating &&
          title == other.title &&
          content == other.content &&
          isVerifiedPurchase == other.isVerifiedPurchase &&
          status == other.status &&
          sellerResponse == other.sellerResponse &&
          sellerRespondedAt == other.sellerRespondedAt &&
          helpfulCount == other.helpfulCount &&
          reportCount == other.reportCount &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 11. REVIEW HELPFUL MODEL
// ============================================================================

class ReviewHelpfulModel {
  const ReviewHelpfulModel({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String reviewId;
  final String userId;
  final DateTime createdAt;

  factory ReviewHelpfulModel.fromJson(Map<String, dynamic> json) {
    return ReviewHelpfulModel(
      id: json['id'] as String,
      reviewId: json['review_id'] as String? ?? json['reviewId'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'review_id': reviewId,
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReviewHelpfulModel.fromEntity(ReviewHelpfulEntity entity) {
    return ReviewHelpfulModel(
      id: entity.id,
      reviewId: entity.reviewId,
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }

  ReviewHelpfulEntity toEntity() {
    return ReviewHelpfulEntity(
      id: id,
      reviewId: reviewId,
      userId: userId,
      createdAt: createdAt,
    );
  }

  ReviewHelpfulModel copyWith({
    String? id,
    String? reviewId,
    String? userId,
    DateTime? createdAt,
  }) {
    return ReviewHelpfulModel(
      id: id ?? this.id,
      reviewId: reviewId ?? this.reviewId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHelpfulModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reviewId == other.reviewId &&
          userId == other.userId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, reviewId, userId, createdAt);
}

// ============================================================================
// 12. WISHLIST MODEL
// ============================================================================

class WishlistModel {
  const WishlistModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_id': productId,
        'created_at': createdAt.toIso8601String(),
      };

  factory WishlistModel.fromEntity(WishlistEntity entity) {
    return WishlistModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      createdAt: entity.createdAt,
    );
  }

  WishlistEntity toEntity() {
    return WishlistEntity(
      id: id,
      userId: userId,
      productId: productId,
      createdAt: createdAt,
    );
  }

  WishlistModel copyWith({
    String? id,
    String? userId,
    String? productId,
    DateTime? createdAt,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WishlistModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          productId == other.productId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, userId, productId, createdAt);
}

// ============================================================================
// 13. PROMO CODE MODEL
// ============================================================================

class PromoCodeModel {
  const PromoCodeModel({
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

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      discountType: DiscountType.fromString(
              json['discount_type'] as String? ??
                  json['discountType'] as String?,) ??
          DiscountType.percentage,
      discountValue: (json['discount_value'] as num? ??
              json['discountValue'] as num?)
          ?.toDouble() ??
          0,
      maxUses: json['max_uses'] as int? ?? json['maxUses'] as int? ?? 0,
      currentUses:
          json['current_uses'] as int? ?? json['currentUses'] as int? ?? 0,
      minOrderAmount: (json['min_order_amount'] as num? ??
              json['minOrderAmount'] as num?)
          ?.toDouble() ??
          0,
      maxDiscountAmount: (json['max_discount_amount'] as num? ??
              json['maxDiscountAmount'] as num?)
          ?.toDouble() ??
          0,
      applicableProductTypes: (json['applicable_product_types']
                      as List<dynamic>? ??
                  json['applicableProductTypes'] as List<dynamic>?)
              ?.map((e) => MarketplaceProductType.fromString(e as String?) ?? MarketplaceProductType.other)
              .toList() ??
          [],
      applicableSellerIds: (json['applicable_seller_ids'] as List<dynamic>? ??
              json['applicableSellerIds'] as List<dynamic>?)
          ?.cast<String>() ??
          [],
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : json['startsAt'] != null
              ? DateTime.parse(json['startsAt'] as String)
              : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : DateTime.now(),
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'description': description,
        'discount_type': discountType.value,
        'discount_value': discountValue,
        'max_uses': maxUses,
        'current_uses': currentUses,
        'min_order_amount': minOrderAmount,
        'max_discount_amount': maxDiscountAmount,
        'applicable_product_types':
            applicableProductTypes.map((e) => e.value).toList(),
        'applicable_seller_ids': applicableSellerIds,
        'starts_at': startsAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': isActive,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PromoCodeModel.fromEntity(PromoCodeEntity entity) {
    return PromoCodeModel(
      id: entity.id,
      code: entity.code,
      description: entity.description,
      discountType: entity.discountType,
      discountValue: entity.discountValue,
      maxUses: entity.maxUses,
      currentUses: entity.currentUses,
      minOrderAmount: entity.minOrderAmount,
      maxDiscountAmount: entity.maxDiscountAmount,
      applicableProductTypes: entity.applicableProductTypes,
      applicableSellerIds: entity.applicableSellerIds,
      startsAt: entity.startsAt,
      expiresAt: entity.expiresAt,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  PromoCodeEntity toEntity() {
    return PromoCodeEntity(
      id: id,
      code: code,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      maxUses: maxUses,
      currentUses: currentUses,
      minOrderAmount: minOrderAmount,
      maxDiscountAmount: maxDiscountAmount,
      applicableProductTypes: applicableProductTypes,
      applicableSellerIds: applicableSellerIds,
      startsAt: startsAt,
      expiresAt: expiresAt,
      isActive: isActive,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  PromoCodeModel copyWith({
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
    return PromoCodeModel(
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
      applicableSellerIds:
          applicableSellerIds ?? this.applicableSellerIds,
      startsAt: startsAt ?? this.startsAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromoCodeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          description == other.description &&
          discountType == other.discountType &&
          discountValue == other.discountValue &&
          maxUses == other.maxUses &&
          currentUses == other.currentUses &&
          minOrderAmount == other.minOrderAmount &&
          maxDiscountAmount == other.maxDiscountAmount &&
          _listEquals(applicableProductTypes, other.applicableProductTypes) &&
          _listEquals(applicableSellerIds, other.applicableSellerIds) &&
          startsAt == other.startsAt &&
          expiresAt == other.expiresAt &&
          isActive == other.isActive &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        code,
        description,
        discountType,
        discountValue,
        maxUses,
        currentUses,
        minOrderAmount,
        maxDiscountAmount,
        Object.hashAll(applicableProductTypes),
        Object.hashAll(applicableSellerIds),
        startsAt,
        expiresAt,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      );
}

// ============================================================================
// 14. COMMISSION RATE MODEL
// ============================================================================

class CommissionRateModel {
  const CommissionRateModel({
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

  factory CommissionRateModel.fromJson(Map<String, dynamic> json) {
    return CommissionRateModel(
      id: json['id'] as String,
      productType: MarketplaceProductType.fromString(
              json['product_type'] as String? ??
                  json['productType'] as String?,) ??
          MarketplaceProductType.other,
      licenseType: MarketplaceLicenseType.fromString(
              json['license_type'] as String? ??
                  json['licenseType'] as String?,) ??
          MarketplaceLicenseType.personal,
      commissionRate:
          (json['commission_rate'] as num? ?? json['commissionRate'] as num?)
              ?.toDouble() ??
          0,
      isActive:
          json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'] as String)
          : json['effectiveFrom'] != null
              ? DateTime.parse(json['effectiveFrom'] as String)
              : DateTime.now(),
      effectiveTo: json['effective_to'] != null
          ? DateTime.parse(json['effective_to'] as String)
          : json['effectiveTo'] != null
              ? DateTime.parse(json['effectiveTo'] as String)
              : null,
      createdBy:
          json['created_by'] as String? ?? json['createdBy'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_type': productType.value,
        'license_type': licenseType.value,
        'commission_rate': commissionRate,
        'is_active': isActive,
        'effective_from': effectiveFrom.toIso8601String(),
        'effective_to': effectiveTo?.toIso8601String(),
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory CommissionRateModel.fromEntity(CommissionRateEntity entity) {
    return CommissionRateModel(
      id: entity.id,
      productType: entity.productType,
      licenseType: entity.licenseType,
      commissionRate: entity.commissionRate,
      isActive: entity.isActive,
      effectiveFrom: entity.effectiveFrom,
      effectiveTo: entity.effectiveTo,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CommissionRateEntity toEntity() {
    return CommissionRateEntity(
      id: id,
      productType: productType,
      licenseType: licenseType,
      commissionRate: commissionRate,
      isActive: isActive,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  CommissionRateModel copyWith({
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
    return CommissionRateModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionRateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productType == other.productType &&
          licenseType == other.licenseType &&
          commissionRate == other.commissionRate &&
          isActive == other.isActive &&
          effectiveFrom == other.effectiveFrom &&
          effectiveTo == other.effectiveTo &&
          createdBy == other.createdBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 15. COMMISSION RECORD MODEL
// ============================================================================

class CommissionRecordModel {
  const CommissionRecordModel({
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

  factory CommissionRecordModel.fromJson(Map<String, dynamic> json) {
    return CommissionRecordModel(
      id: json['id'] as String,
      orderItemId: json['order_item_id'] as String? ??
          json['orderItemId'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      commissionType: CommissionType.fromString(
              json['commission_type'] as String? ??
                  json['commissionType'] as String?,) ??
          CommissionType.platform,
      commissionRate: (json['commission_rate'] as num? ??
              json['commissionRate'] as num?)
          ?.toDouble() ??
          0,
      commissionAmount: (json['commission_amount'] as num? ??
              json['commissionAmount'] as num?)
          ?.toDouble() ??
          0,
      sellerRevenue: (json['seller_revenue'] as num? ??
              json['sellerRevenue'] as num?)
          ?.toDouble() ??
          0,
      currency: json['currency'] as String? ?? 'NGN',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_item_id': orderItemId,
        'seller_id': sellerId,
        'commission_type': commissionType.value,
        'commission_rate': commissionRate,
        'commission_amount': commissionAmount,
        'seller_revenue': sellerRevenue,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
      };

  factory CommissionRecordModel.fromEntity(CommissionRecordEntity entity) {
    return CommissionRecordModel(
      id: entity.id,
      orderItemId: entity.orderItemId,
      sellerId: entity.sellerId,
      commissionType: entity.commissionType,
      commissionRate: entity.commissionRate,
      commissionAmount: entity.commissionAmount,
      sellerRevenue: entity.sellerRevenue,
      currency: entity.currency,
      createdAt: entity.createdAt,
    );
  }

  CommissionRecordEntity toEntity() {
    return CommissionRecordEntity(
      id: id,
      orderItemId: orderItemId,
      sellerId: sellerId,
      commissionType: commissionType,
      commissionRate: commissionRate,
      commissionAmount: commissionAmount,
      sellerRevenue: sellerRevenue,
      currency: currency,
      createdAt: createdAt,
    );
  }

  CommissionRecordModel copyWith({
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
    return CommissionRecordModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionRecordModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderItemId == other.orderItemId &&
          sellerId == other.sellerId &&
          commissionType == other.commissionType &&
          commissionRate == other.commissionRate &&
          commissionAmount == other.commissionAmount &&
          sellerRevenue == other.sellerRevenue &&
          currency == other.currency &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        orderItemId,
        sellerId,
        commissionType,
        commissionRate,
        commissionAmount,
        sellerRevenue,
        currency,
        createdAt,
      );
}

// ============================================================================
// 16. SELLER ANALYTICS MODEL
// ============================================================================

class SellerAnalyticsModel {
  const SellerAnalyticsModel({
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

  factory SellerAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SellerAnalyticsModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      views: json['views'] as int? ?? 0,
      sales: json['sales'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      uniqueVisitors: json['unique_visitors'] as int? ??
          json['uniqueVisitors'] as int? ??
          0,
      conversionRate: (json['conversion_rate'] as num? ??
              json['conversionRate'] as num?)
          ?.toDouble() ??
          0,
      averageRating: (json['average_rating'] as num? ??
              json['averageRating'] as num?)
          ?.toDouble() ??
          0,
      newReviews:
          json['new_reviews'] as int? ?? json['newReviews'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'date': date.toIso8601String(),
        'views': views,
        'sales': sales,
        'revenue': revenue,
        'unique_visitors': uniqueVisitors,
        'conversion_rate': conversionRate,
        'average_rating': averageRating,
        'new_reviews': newReviews,
        'created_at': createdAt.toIso8601String(),
      };

  factory SellerAnalyticsModel.fromEntity(SellerAnalyticsEntity entity) {
    return SellerAnalyticsModel(
      id: entity.id,
      sellerId: entity.sellerId,
      date: entity.date,
      views: entity.views,
      sales: entity.sales,
      revenue: entity.revenue,
      uniqueVisitors: entity.uniqueVisitors,
      conversionRate: entity.conversionRate,
      averageRating: entity.averageRating,
      newReviews: entity.newReviews,
      createdAt: entity.createdAt,
    );
  }

  SellerAnalyticsEntity toEntity() {
    return SellerAnalyticsEntity(
      id: id,
      sellerId: sellerId,
      date: date,
      views: views,
      sales: sales,
      revenue: revenue,
      uniqueVisitors: uniqueVisitors,
      conversionRate: conversionRate,
      averageRating: averageRating,
      newReviews: newReviews,
      createdAt: createdAt,
    );
  }

  SellerAnalyticsModel copyWith({
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
    return SellerAnalyticsModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellerAnalyticsModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sellerId == other.sellerId &&
          date == other.date &&
          views == other.views &&
          sales == other.sales &&
          revenue == other.revenue &&
          uniqueVisitors == other.uniqueVisitors &&
          conversionRate == other.conversionRate &&
          averageRating == other.averageRating &&
          newReviews == other.newReviews &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 17. PRODUCT ANALYTICS MODEL
// ============================================================================

class ProductAnalyticsModel {
  const ProductAnalyticsModel({
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

  factory ProductAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return ProductAnalyticsModel(
      id: json['id'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      views: json['views'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      sales: json['sales'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      searchImpressions: json['search_impressions'] as int? ??
          json['searchImpressions'] as int? ??
          0,
      clickThroughRate: (json['click_through_rate'] as num? ??
              json['clickThroughRate'] as num?)
          ?.toDouble() ??
          0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'date': date.toIso8601String(),
        'views': views,
        'downloads': downloads,
        'sales': sales,
        'revenue': revenue,
        'search_impressions': searchImpressions,
        'click_through_rate': clickThroughRate,
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductAnalyticsModel.fromEntity(ProductAnalyticsEntity entity) {
    return ProductAnalyticsModel(
      id: entity.id,
      productId: entity.productId,
      date: entity.date,
      views: entity.views,
      downloads: entity.downloads,
      sales: entity.sales,
      revenue: entity.revenue,
      searchImpressions: entity.searchImpressions,
      clickThroughRate: entity.clickThroughRate,
      createdAt: entity.createdAt,
    );
  }

  ProductAnalyticsEntity toEntity() {
    return ProductAnalyticsEntity(
      id: id,
      productId: productId,
      date: date,
      views: views,
      downloads: downloads,
      sales: sales,
      revenue: revenue,
      searchImpressions: searchImpressions,
      clickThroughRate: clickThroughRate,
      createdAt: createdAt,
    );
  }

  ProductAnalyticsModel copyWith({
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
    return ProductAnalyticsModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAnalyticsModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          date == other.date &&
          views == other.views &&
          downloads == other.downloads &&
          sales == other.sales &&
          revenue == other.revenue &&
          searchImpressions == other.searchImpressions &&
          clickThroughRate == other.clickThroughRate &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 18. MARKETPLACE SEARCH LOG MODEL
// ============================================================================

class MarketplaceSearchLogModel {
  const MarketplaceSearchLogModel({
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

  factory MarketplaceSearchLogModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceSearchLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      query: json['query'] as String,
      filters: json['filters'] as Map<String, dynamic>?,
      resultsCount: json['results_count'] as int? ??
          json['resultsCount'] as int? ??
          0,
      clickedProductId: json['clicked_product_id'] as String? ??
          json['clickedProductId'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'query': query,
        'filters': filters,
        'results_count': resultsCount,
        'clicked_product_id': clickedProductId,
        'created_at': createdAt.toIso8601String(),
      };

  factory MarketplaceSearchLogModel.fromEntity(
      MarketplaceSearchLogEntity entity,) {
    return MarketplaceSearchLogModel(
      id: entity.id,
      userId: entity.userId,
      query: entity.query,
      filters: entity.filters,
      resultsCount: entity.resultsCount,
      clickedProductId: entity.clickedProductId,
      createdAt: entity.createdAt,
    );
  }

  MarketplaceSearchLogEntity toEntity() {
    return MarketplaceSearchLogEntity(
      id: id,
      userId: userId,
      query: query,
      filters: filters,
      resultsCount: resultsCount,
      clickedProductId: clickedProductId,
      createdAt: createdAt,
    );
  }

  MarketplaceSearchLogModel copyWith({
    String? id,
    String? userId,
    String? query,
    Map<String, dynamic>? filters,
    int? resultsCount,
    String? clickedProductId,
    DateTime? createdAt,
  }) {
    return MarketplaceSearchLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      resultsCount: resultsCount ?? this.resultsCount,
      clickedProductId: clickedProductId ?? this.clickedProductId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceSearchLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          query == other.query &&
          _mapEquals(filters, other.filters) &&
          resultsCount == other.resultsCount &&
          clickedProductId == other.clickedProductId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        query,
        filters.hashCode,
        resultsCount,
        clickedProductId,
        createdAt,
      );
}

// ============================================================================
// 19. AI RECOMMENDATION MODEL
// ============================================================================

class AIRecommendationModel {
  const AIRecommendationModel({
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

  factory AIRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AIRecommendationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      recommendationType: json['recommendation_type'] as String? ??
          json['recommendationType'] as String,
      recommendationReason: json['recommendation_reason'] as String? ??
          json['recommendationReason'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      wasClicked:
          json['was_clicked'] as bool? ?? json['wasClicked'] as bool? ?? false,
      wasPurchased: json['was_purchased'] as bool? ??
          json['wasPurchased'] as bool? ??
          false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_id': productId,
        'recommendation_type': recommendationType,
        'recommendation_reason': recommendationReason,
        'score': score,
        'was_clicked': wasClicked,
        'was_purchased': wasPurchased,
        'created_at': createdAt.toIso8601String(),
      };

  factory AIRecommendationModel.fromEntity(AIRecommendationEntity entity) {
    return AIRecommendationModel(
      id: entity.id,
      userId: entity.userId,
      productId: entity.productId,
      recommendationType: entity.recommendationType,
      recommendationReason: entity.recommendationReason,
      score: entity.score,
      wasClicked: entity.wasClicked,
      wasPurchased: entity.wasPurchased,
      createdAt: entity.createdAt,
    );
  }

  AIRecommendationEntity toEntity() {
    return AIRecommendationEntity(
      id: id,
      userId: userId,
      productId: productId,
      recommendationType: recommendationType,
      recommendationReason: recommendationReason,
      score: score,
      wasClicked: wasClicked,
      wasPurchased: wasPurchased,
      createdAt: createdAt,
    );
  }

  AIRecommendationModel copyWith({
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
    return AIRecommendationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      recommendationType: recommendationType ?? this.recommendationType,
      recommendationReason:
          recommendationReason ?? this.recommendationReason,
      score: score ?? this.score,
      wasClicked: wasClicked ?? this.wasClicked,
      wasPurchased: wasPurchased ?? this.wasPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRecommendationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          productId == other.productId &&
          recommendationType == other.recommendationType &&
          recommendationReason == other.recommendationReason &&
          score == other.score &&
          wasClicked == other.wasClicked &&
          wasPurchased == other.wasPurchased &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        productId,
        recommendationType,
        recommendationReason,
        score,
        wasClicked,
        wasPurchased,
        createdAt,
      );
}

// ============================================================================
// 20. QUALITY CHECK MODEL
// ============================================================================

class QualityCheckModel {
  const QualityCheckModel({
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

  factory QualityCheckModel.fromJson(Map<String, dynamic> json) {
    return QualityCheckModel(
      id: json['id'] as String,
      productId:
          json['product_id'] as String? ?? json['productId'] as String,
      overallScore:
          (json['overall_score'] as num? ?? json['overallScore'] as num?)
              ?.toDouble() ??
          0,
      grammarScore: (json['grammar_score'] as num? ??
              json['grammarScore'] as num?)
          ?.toDouble() ??
          0,
      spellingScore: (json['spelling_score'] as num? ??
              json['spellingScore'] as num?)
          ?.toDouble() ??
          0,
      formattingScore: (json['formatting_score'] as num? ??
              json['formattingScore'] as num?)
          ?.toDouble() ??
          0,
      curriculumAlignmentScore: (json['curriculum_alignment_score'] as num? ??
              json['curriculumAlignmentScore'] as num?)
          ?.toDouble() ??
          0,
      readingLevel: (json['reading_level'] as num? ??
              json['readingLevel'] as num?)
          ?.toDouble() ??
          0,
      readingLevelLabel: json['reading_level_label'] as String? ??
          json['readingLevelLabel'] as String?,
      duplicateCheckResult:
          json['duplicate_check_result'] as Map<String, dynamic>? ??
              json['duplicateCheckResult'] as Map<String, dynamic>?,
      accuracyFlag: json['accuracy_flag'] as bool? ??
          json['accuracyFlag'] as bool? ??
          false,
      accuracyDetails: json['accuracy_details'] as Map<String, dynamic>? ??
          json['accuracyDetails'] as Map<String, dynamic>?,
      suggestions:
          (json['suggestions'] as List<dynamic>?)?.cast<String>() ?? [],
      flaggedIssues:
          (json['flagged_issues'] as List<dynamic>? ??
                  json['flaggedIssues'] as List<dynamic>?)
              ?.cast<String>() ??
              [],
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : json['checkedAt'] != null
              ? DateTime.parse(json['checkedAt'] as String)
              : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'overall_score': overallScore,
        'grammar_score': grammarScore,
        'spelling_score': spellingScore,
        'formatting_score': formattingScore,
        'curriculum_alignment_score': curriculumAlignmentScore,
        'reading_level': readingLevel,
        'reading_level_label': readingLevelLabel,
        'duplicate_check_result': duplicateCheckResult,
        'accuracy_flag': accuracyFlag,
        'accuracy_details': accuracyDetails,
        'suggestions': suggestions,
        'flagged_issues': flaggedIssues,
        'checked_at': checkedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory QualityCheckModel.fromEntity(QualityCheckEntity entity) {
    return QualityCheckModel(
      id: entity.id,
      productId: entity.productId,
      overallScore: entity.overallScore,
      grammarScore: entity.grammarScore,
      spellingScore: entity.spellingScore,
      formattingScore: entity.formattingScore,
      curriculumAlignmentScore: entity.curriculumAlignmentScore,
      readingLevel: entity.readingLevel,
      readingLevelLabel: entity.readingLevelLabel,
      duplicateCheckResult: entity.duplicateCheckResult,
      accuracyFlag: entity.accuracyFlag,
      accuracyDetails: entity.accuracyDetails,
      suggestions: entity.suggestions,
      flaggedIssues: entity.flaggedIssues,
      checkedAt: entity.checkedAt,
      createdAt: entity.createdAt,
    );
  }

  QualityCheckEntity toEntity() {
    return QualityCheckEntity(
      id: id,
      productId: productId,
      overallScore: overallScore,
      grammarScore: grammarScore,
      spellingScore: spellingScore,
      formattingScore: formattingScore,
      curriculumAlignmentScore: curriculumAlignmentScore,
      readingLevel: readingLevel,
      readingLevelLabel: readingLevelLabel,
      duplicateCheckResult: duplicateCheckResult,
      accuracyFlag: accuracyFlag,
      accuracyDetails: accuracyDetails,
      suggestions: suggestions,
      flaggedIssues: flaggedIssues,
      checkedAt: checkedAt,
      createdAt: createdAt,
    );
  }

  QualityCheckModel copyWith({
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
    return QualityCheckModel(
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
      duplicateCheckResult: duplicateCheckResult ?? this.duplicateCheckResult,
      accuracyFlag: accuracyFlag ?? this.accuracyFlag,
      accuracyDetails: accuracyDetails ?? this.accuracyDetails,
      suggestions: suggestions ?? this.suggestions,
      flaggedIssues: flaggedIssues ?? this.flaggedIssues,
      checkedAt: checkedAt ?? this.checkedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityCheckModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          overallScore == other.overallScore &&
          grammarScore == other.grammarScore &&
          spellingScore == other.spellingScore &&
          formattingScore == other.formattingScore &&
          curriculumAlignmentScore == other.curriculumAlignmentScore &&
          readingLevel == other.readingLevel &&
          readingLevelLabel == other.readingLevelLabel &&
          _mapEquals(duplicateCheckResult, other.duplicateCheckResult) &&
          accuracyFlag == other.accuracyFlag &&
          _mapEquals(accuracyDetails, other.accuracyDetails) &&
          _listEquals(suggestions, other.suggestions) &&
          _listEquals(flaggedIssues, other.flaggedIssues) &&
          checkedAt == other.checkedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        productId,
        overallScore,
        grammarScore,
        spellingScore,
        formattingScore,
        curriculumAlignmentScore,
        readingLevel,
        readingLevelLabel,
        duplicateCheckResult.hashCode,
        accuracyFlag,
        accuracyDetails.hashCode,
        Object.hashAll(suggestions),
        Object.hashAll(flaggedIssues),
        checkedAt,
        createdAt,
      );
}

// ============================================================================
// 21. DISPUTE MODEL
// ============================================================================

class DisputeModel {
  const DisputeModel({
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

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? json['orderId'] as String,
      buyerId: json['buyer_id'] as String? ?? json['buyerId'] as String,
      sellerId: json['seller_id'] as String? ?? json['sellerId'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: DisputeStatus.fromString(json['status'] as String?) ??
          DisputeStatus.open,
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String? ??
          json['resolvedBy'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'reason': reason,
        'description': description,
        'status': status.value,
        'resolution': resolution,
        'resolved_by': resolvedBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DisputeModel.fromEntity(DisputeEntity entity) {
    return DisputeModel(
      id: entity.id,
      orderId: entity.orderId,
      buyerId: entity.buyerId,
      sellerId: entity.sellerId,
      reason: entity.reason,
      description: entity.description,
      status: entity.status,
      resolution: entity.resolution,
      resolvedBy: entity.resolvedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DisputeEntity toEntity() {
    return DisputeEntity(
      id: id,
      orderId: orderId,
      buyerId: buyerId,
      sellerId: sellerId,
      reason: reason,
      description: description,
      status: status,
      resolution: resolution,
      resolvedBy: resolvedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DisputeModel copyWith({
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
    return DisputeModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisputeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          buyerId == other.buyerId &&
          sellerId == other.sellerId &&
          reason == other.reason &&
          description == other.description &&
          status == other.status &&
          resolution == other.resolution &&
          resolvedBy == other.resolvedBy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
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
      );
}

// ============================================================================
// 22. MARKETPLACE NOTIFICATION MODEL
// ============================================================================

class MarketplaceNotificationModel {
  const MarketplaceNotificationModel({
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

  factory MarketplaceNotificationModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceNotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      type: MarketplaceNotificationType.fromString(json['type'] as String?) ??
          MarketplaceNotificationType.purchaseSuccess,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.value,
        'title': title,
        'message': message,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  factory MarketplaceNotificationModel.fromEntity(
      MarketplaceNotificationEntity entity,) {
    return MarketplaceNotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      title: entity.title,
      message: entity.message,
      data: entity.data,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
    );
  }

  MarketplaceNotificationEntity toEntity() {
    return MarketplaceNotificationEntity(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  MarketplaceNotificationModel copyWith({
    String? id,
    String? userId,
    MarketplaceNotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MarketplaceNotificationModel(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceNotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          title == other.title &&
          message == other.message &&
          _mapEquals(data, other.data) &&
          isRead == other.isRead &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        type,
        title,
        message,
        data.hashCode,
        isRead,
        createdAt,
      );
}

// ============================================================================
// 23. SAVED SEARCH MODEL
// ============================================================================

class SavedSearchModel {
  const SavedSearchModel({
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

  factory SavedSearchModel.fromJson(Map<String, dynamic> json) {
    return SavedSearchModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      name: json['name'] as String,
      filters: json['filters'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'filters': filters,
        'created_at': createdAt.toIso8601String(),
      };

  factory SavedSearchModel.fromEntity(SavedSearchEntity entity) {
    return SavedSearchModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      filters: entity.filters,
      createdAt: entity.createdAt,
    );
  }

  SavedSearchEntity toEntity() {
    return SavedSearchEntity(
      id: id,
      userId: userId,
      name: name,
      filters: filters,
      createdAt: createdAt,
    );
  }

  SavedSearchModel copyWith({
    String? id,
    String? userId,
    String? name,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
  }) {
    return SavedSearchModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedSearchModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          _mapEquals(filters, other.filters) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        name,
        filters.hashCode,
        createdAt,
      );
}
