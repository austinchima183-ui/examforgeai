import '../../domain/entities/marketing_entities.dart';

// ============================================================================
// LANDING PAGE MODEL
// ============================================================================

class LandingPageModel {
  final String id;
  final String slug;
  final String title;
  final bool isPublished;
  final Map<String, dynamic> sections;
  final String? seoTitle;
  final String? seoDescription;
  final String? ogImageUrl;
  final DateTime? publishedAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LandingPageModel({
    required this.id, required this.slug, required this.title, required this.isPublished,
    required this.sections, this.seoTitle, this.seoDescription, this.ogImageUrl,
    this.publishedAt, required this.createdBy, required this.createdAt, required this.updatedAt,
  });

  factory LandingPageModel.fromJson(Map<String, dynamic> json) => LandingPageModel(
    id: json['id'] as String, slug: json['slug'] as String, title: json['title'] as String,
    isPublished: json['is_published'] as bool? ?? false,
    sections: Map<String, dynamic>.from(json['sections'] as Map? ?? {}),
    seoTitle: json['seo_title'] as String?, seoDescription: json['seo_description'] as String?,
    ogImageUrl: json['og_image_url'] as String?,
    publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'slug': slug, 'title': title, 'is_published': isPublished,
    'sections': sections, 'seo_title': seoTitle, 'seo_description': seoDescription,
    'og_image_url': ogImageUrl, 'published_at': publishedAt?.toIso8601String(),
    'created_by': createdBy, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  LandingPage toEntity() => LandingPage(
    id: id, slug: slug, title: title, isPublished: isPublished, sections: sections,
    seoTitle: seoTitle, seoDescription: seoDescription, ogImageUrl: ogImageUrl,
    publishedAt: publishedAt, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ============================================================================
// BLOG POST MODEL
// ============================================================================

class BlogPostModel {
  final String id;
  final String title;
  final String slug;
  final String excerpt;
  final String content;
  final Map<String, dynamic> contentRich;
  final String? featuredImageUrl;
  final String category;
  final List<String> tags;
  final String authorId;
  final String status;
  final int viewsCount;
  final int likesCount;
  final bool isFeatured;
  final String? seoTitle;
  final String? seoDescription;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BlogPostModel({
    required this.id, required this.title, required this.slug, required this.excerpt,
    required this.content, required this.contentRich, this.featuredImageUrl,
    required this.category, required this.tags, required this.authorId, required this.status,
    required this.viewsCount, required this.likesCount, required this.isFeatured,
    this.seoTitle, this.seoDescription, this.publishedAt,
    required this.createdAt, required this.updatedAt,
  });

  factory BlogPostModel.fromJson(Map<String, dynamic> json) => BlogPostModel(
    id: json['id'] as String, title: json['title'] as String, slug: json['slug'] as String,
    excerpt: json['excerpt'] as String, content: json['content'] as String,
    contentRich: Map<String, dynamic>.from(json['content_rich'] as Map? ?? {}),
    featuredImageUrl: json['featured_image_url'] as String?,
    category: json['category'] as String,
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    authorId: json['author_id'] as String, status: json['status'] as String? ?? 'draft',
    viewsCount: json['views_count'] as int? ?? 0, likesCount: json['likes_count'] as int? ?? 0,
    isFeatured: json['is_featured'] as bool? ?? false,
    seoTitle: json['seo_title'] as String?, seoDescription: json['seo_description'] as String?,
    publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
    createdAt: DateTime.parse(json['created_at'] as String), updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'slug': slug, 'excerpt': excerpt, 'content': content,
    'content_rich': contentRich, 'featured_image_url': featuredImageUrl, 'category': category,
    'tags': tags, 'author_id': authorId, 'status': status, 'views_count': viewsCount,
    'likes_count': likesCount, 'is_featured': isFeatured, 'seo_title': seoTitle,
    'seo_description': seoDescription, 'published_at': publishedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  BlogPost toEntity() => BlogPost(
    id: id, title: title, slug: slug, excerpt: excerpt, content: content,
    contentRich: contentRich, featuredImageUrl: featuredImageUrl, category: category,
    tags: tags, authorId: authorId, status: status, viewsCount: viewsCount,
    likesCount: likesCount, isFeatured: isFeatured, seoTitle: seoTitle,
    seoDescription: seoDescription, publishedAt: publishedAt, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ============================================================================
// EMAIL CAMPAIGN MODEL
// ============================================================================

class EmailCampaignModel {
  final String id;
  final String name;
  final String campaignType;
  final String subject;
  final String body;
  final String? bodyHtml;
  final Map<String, dynamic> targetAudience;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int recipientCount;
  final int openCount;
  final int clickCount;
  final int bounceCount;
  final Map<String, dynamic> metadata;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmailCampaignModel({
    required this.id, required this.name, required this.campaignType, required this.subject,
    required this.body, this.bodyHtml, required this.targetAudience, required this.status,
    this.scheduledAt, this.sentAt, required this.recipientCount, required this.openCount,
    required this.clickCount, required this.bounceCount, required this.metadata,
    required this.createdBy, required this.createdAt, required this.updatedAt,
  });

  factory EmailCampaignModel.fromJson(Map<String, dynamic> json) => EmailCampaignModel(
    id: json['id'] as String, name: json['name'] as String,
    campaignType: json['campaign_type'] as String, subject: json['subject'] as String,
    body: json['body'] as String, bodyHtml: json['body_html'] as String?,
    targetAudience: Map<String, dynamic>.from(json['target_audience'] as Map? ?? {}),
    status: json['status'] as String? ?? 'draft',
    scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
    sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
    recipientCount: json['recipient_count'] as int? ?? 0, openCount: json['open_count'] as int? ?? 0,
    clickCount: json['click_count'] as int? ?? 0, bounceCount: json['bounce_count'] as int? ?? 0,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    createdBy: json['created_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String), updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'campaign_type': campaignType, 'subject': subject,
    'body': body, 'body_html': bodyHtml, 'target_audience': targetAudience, 'status': status,
    'scheduled_at': scheduledAt?.toIso8601String(), 'sent_at': sentAt?.toIso8601String(),
    'recipient_count': recipientCount, 'open_count': openCount, 'click_count': clickCount,
    'bounce_count': bounceCount, 'metadata': metadata, 'created_by': createdBy,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  EmailCampaign toEntity() => EmailCampaign(
    id: id, name: name, campaignType: CampaignType.fromString(campaignType),
    subject: subject, body: body, bodyHtml: bodyHtml, targetAudience: targetAudience,
    status: status, scheduledAt: scheduledAt, sentAt: sentAt, recipientCount: recipientCount,
    openCount: openCount, clickCount: clickCount, bounceCount: bounceCount,
    metadata: metadata, createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ============================================================================
// REFERRAL PROGRAM MODEL
// ============================================================================

class ReferralProgramModel {
  final String id;
  final String schoolId;
  final String name;
  final String description;
  final String rewardType;
  final double rewardValue;
  final String referralCode;
  final bool isActive;
  final int? maxReferrals;
  final int totalReferrals;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralProgramModel({
    required this.id, required this.schoolId, required this.name, required this.description,
    required this.rewardType, required this.rewardValue, required this.referralCode,
    required this.isActive, this.maxReferrals, required this.totalReferrals,
    required this.metadata, required this.createdAt, required this.updatedAt,
  });

  factory ReferralProgramModel.fromJson(Map<String, dynamic> json) => ReferralProgramModel(
    id: json['id'] as String, schoolId: json['school_id'] as String, name: json['name'] as String,
    description: json['description'] as String, rewardType: json['reward_type'] as String,
    rewardValue: (json['reward_value'] as num?)?.toDouble() ?? 0.0,
    referralCode: json['referral_code'] as String, isActive: json['is_active'] as bool? ?? true,
    maxReferrals: json['max_referrals'] as int?, totalReferrals: json['total_referrals'] as int? ?? 0,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String), updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'school_id': schoolId, 'name': name, 'description': description,
    'reward_type': rewardType, 'reward_value': rewardValue, 'referral_code': referralCode,
    'is_active': isActive, 'max_referrals': maxReferrals, 'total_referrals': totalReferrals,
    'metadata': metadata, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  ReferralProgram toEntity() => ReferralProgram(
    id: id, schoolId: schoolId, name: name, description: description, rewardType: rewardType,
    rewardValue: rewardValue, referralCode: referralCode, isActive: isActive,
    maxReferrals: maxReferrals, totalReferrals: totalReferrals, metadata: metadata,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ============================================================================
// REFERRAL MODEL
// ============================================================================

class ReferralModel {
  final String id;
  final String referralProgramId;
  final String referrerId;
  final String referralCode;
  final String referredEmail;
  final String? referredId;
  final String status;
  final bool rewardIssued;
  final DateTime? rewardIssuedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const ReferralModel({
    required this.id, required this.referralProgramId, required this.referrerId,
    required this.referralCode, required this.referredEmail, this.referredId,
    required this.status, required this.rewardIssued, this.rewardIssuedAt,
    required this.metadata, required this.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
    id: json['id'] as String, referralProgramId: json['referral_program_id'] as String,
    referrerId: json['referrer_id'] as String, referralCode: json['referral_code'] as String,
    referredEmail: json['referred_email'] as String, referredId: json['referred_id'] as String?,
    status: json['status'] as String? ?? 'pending', rewardIssued: json['reward_issued'] as bool? ?? false,
    rewardIssuedAt: json['reward_issued_at'] != null ? DateTime.parse(json['reward_issued_at'] as String) : null,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'referral_program_id': referralProgramId, 'referrer_id': referrerId,
    'referral_code': referralCode, 'referred_email': referredEmail, 'referred_id': referredId,
    'status': status, 'reward_issued': rewardIssued, 'reward_issued_at': rewardIssuedAt?.toIso8601String(),
    'metadata': metadata, 'created_at': createdAt.toIso8601String(),
  };

  Referral toEntity() => Referral(
    id: id, referralProgramId: referralProgramId, referrerId: referrerId,
    referralCode: referralCode, referredEmail: referredEmail, referredId: referredId,
    status: status, rewardIssued: rewardIssued, rewardIssuedAt: rewardIssuedAt,
    metadata: metadata, createdAt: createdAt,
  );
}

// ============================================================================
// AFFILIATE MODEL
// ============================================================================

class AffiliateModel {
  final String id;
  final String userId;
  final String affiliateCode;
  final String status;
  final double commissionRate;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final int referralsCount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AffiliateModel({
    required this.id, required this.userId, required this.affiliateCode, required this.status,
    required this.commissionRate, required this.totalEarnings, required this.pendingEarnings,
    required this.paidEarnings, required this.referralsCount, required this.metadata,
    required this.createdAt, required this.updatedAt,
  });

  factory AffiliateModel.fromJson(Map<String, dynamic> json) => AffiliateModel(
    id: json['id'] as String, userId: json['user_id'] as String,
    affiliateCode: json['affiliate_code'] as String, status: json['status'] as String? ?? 'pending',
    commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
    totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
    pendingEarnings: (json['pending_earnings'] as num?)?.toDouble() ?? 0.0,
    paidEarnings: (json['paid_earnings'] as num?)?.toDouble() ?? 0.0,
    referralsCount: json['referrals_count'] as int? ?? 0,
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    createdAt: DateTime.parse(json['created_at'] as String), updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'affiliate_code': affiliateCode, 'status': status,
    'commission_rate': commissionRate, 'total_earnings': totalEarnings,
    'pending_earnings': pendingEarnings, 'paid_earnings': paidEarnings,
    'referrals_count': referralsCount, 'metadata': metadata,
    'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
  };

  Affiliate toEntity() => Affiliate(
    id: id, userId: userId, affiliateCode: affiliateCode, status: AffiliateStatus.fromString(status),
    commissionRate: commissionRate, totalEarnings: totalEarnings, pendingEarnings: pendingEarnings,
    paidEarnings: paidEarnings, referralsCount: referralsCount, metadata: metadata,
    createdAt: createdAt, updatedAt: updatedAt,
  );
}

// ============================================================================
// AFFILIATE REFERRAL MODEL
// ============================================================================

class AffiliateReferralModel {
  final String id;
  final String affiliateId;
  final String? referredId;
  final String referredEmail;
  final String? subscriptionId;
  final double commissionEarned;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const AffiliateReferralModel({
    required this.id, required this.affiliateId, this.referredId, required this.referredEmail,
    this.subscriptionId, required this.commissionEarned, required this.status, this.paidAt,
    required this.createdAt,
  });

  factory AffiliateReferralModel.fromJson(Map<String, dynamic> json) => AffiliateReferralModel(
    id: json['id'] as String, affiliateId: json['affiliate_id'] as String,
    referredId: json['referred_id'] as String?, referredEmail: json['referred_email'] as String,
    subscriptionId: json['subscription_id'] as String?,
    commissionEarned: (json['commission_earned'] as num?)?.toDouble() ?? 0.0,
    status: json['status'] as String? ?? 'pending',
    paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'affiliate_id': affiliateId, 'referred_id': referredId,
    'referred_email': referredEmail, 'subscription_id': subscriptionId,
    'commission_earned': commissionEarned, 'status': status,
    'paid_at': paidAt?.toIso8601String(), 'created_at': createdAt.toIso8601String(),
  };

  AffiliateReferral toEntity() => AffiliateReferral(
    id: id, affiliateId: affiliateId, referredId: referredId, referredEmail: referredEmail,
    subscriptionId: subscriptionId, commissionEarned: commissionEarned, status: status,
    paidAt: paidAt, createdAt: createdAt,
  );
}
