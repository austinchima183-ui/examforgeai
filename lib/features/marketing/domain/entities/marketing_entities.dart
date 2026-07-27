import 'package:equatable/equatable.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum CampaignType {
  email(value: 'email', label: 'Email'),
  sms(value: 'sms', label: 'SMS'),
  push(value: 'push', label: 'Push Notification'),
  inApp(value: 'in_app', label: 'In-App');

  const CampaignType({required this.value, required this.label});
  final String value;
  final String label;

  static CampaignType fromString(String value) {
    return CampaignType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CampaignType.email,
    );
  }
}

enum AffiliateStatus {
  pending(value: 'pending', label: 'Pending'),
  active(value: 'active', label: 'Active'),
  suspended(value: 'suspended', label: 'Suspended'),
  terminated(value: 'terminated', label: 'Terminated');

  const AffiliateStatus({required this.value, required this.label});
  final String value;
  final String label;

  static AffiliateStatus fromString(String value) {
    return AffiliateStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AffiliateStatus.pending,
    );
  }
}

enum ProposalStatus {
  draft(value: 'draft', label: 'Draft'),
  sent(value: 'sent', label: 'Sent'),
  viewed(value: 'viewed', label: 'Viewed'),
  accepted(value: 'accepted', label: 'Accepted'),
  rejected(value: 'rejected', label: 'Rejected'),
  expired(value: 'expired', label: 'Expired');

  const ProposalStatus({required this.value, required this.label});
  final String value;
  final String label;

  static ProposalStatus fromString(String value) {
    return ProposalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProposalStatus.draft,
    );
  }
}

// ============================================================================
// ENTITIES
// ============================================================================

class LandingPage extends Equatable {
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

  const LandingPage({
    required this.id,
    required this.slug,
    required this.title,
    required this.isPublished,
    required this.sections,
    this.seoTitle,
    this.seoDescription,
    this.ogImageUrl,
    this.publishedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, slug, title, isPublished, sections, seoTitle, seoDescription, ogImageUrl, publishedAt, createdBy, createdAt, updatedAt];

  LandingPage copyWith({
    String? id, String? slug, String? title, bool? isPublished, Map<String, dynamic>? sections,
    String? seoTitle, String? seoDescription, String? ogImageUrl, DateTime? publishedAt,
    String? createdBy, DateTime? createdAt, DateTime? updatedAt,
  }) => LandingPage(
    id: id ?? this.id, slug: slug ?? this.slug, title: title ?? this.title, isPublished: isPublished ?? this.isPublished,
    sections: sections ?? this.sections, seoTitle: seoTitle ?? this.seoTitle, seoDescription: seoDescription ?? this.seoDescription,
    ogImageUrl: ogImageUrl ?? this.ogImageUrl, publishedAt: publishedAt ?? this.publishedAt, createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class BlogPost extends Equatable {
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

  const BlogPost({
    required this.id, required this.title, required this.slug, required this.excerpt,
    required this.content, required this.contentRich, this.featuredImageUrl,
    required this.category, required this.tags, required this.authorId, required this.status,
    required this.viewsCount, required this.likesCount, required this.isFeatured,
    this.seoTitle, this.seoDescription, this.publishedAt,
    required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, slug, excerpt, content, contentRich, featuredImageUrl, category, tags, authorId, status, viewsCount, likesCount, isFeatured, seoTitle, seoDescription, publishedAt, createdAt, updatedAt];

  BlogPost copyWith({
    String? id, String? title, String? slug, String? excerpt, String? content,
    Map<String, dynamic>? contentRich, String? featuredImageUrl, String? category,
    List<String>? tags, String? authorId, String? status, int? viewsCount, int? likesCount,
    bool? isFeatured, String? seoTitle, String? seoDescription, DateTime? publishedAt,
    DateTime? createdAt, DateTime? updatedAt,
  }) => BlogPost(
    id: id ?? this.id, title: title ?? this.title, slug: slug ?? this.slug, excerpt: excerpt ?? this.excerpt,
    content: content ?? this.content, contentRich: contentRich ?? this.contentRich, featuredImageUrl: featuredImageUrl ?? this.featuredImageUrl,
    category: category ?? this.category, tags: tags ?? this.tags, authorId: authorId ?? this.authorId, status: status ?? this.status,
    viewsCount: viewsCount ?? this.viewsCount, likesCount: likesCount ?? this.likesCount, isFeatured: isFeatured ?? this.isFeatured,
    seoTitle: seoTitle ?? this.seoTitle, seoDescription: seoDescription ?? this.seoDescription, publishedAt: publishedAt ?? this.publishedAt,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class EmailCampaign extends Equatable {
  final String id;
  final String name;
  final CampaignType campaignType;
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

  const EmailCampaign({
    required this.id, required this.name, required this.campaignType, required this.subject,
    required this.body, this.bodyHtml, required this.targetAudience, required this.status,
    this.scheduledAt, this.sentAt, required this.recipientCount, required this.openCount,
    required this.clickCount, required this.bounceCount, required this.metadata,
    required this.createdBy, required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, campaignType, subject, body, bodyHtml, targetAudience, status, scheduledAt, sentAt, recipientCount, openCount, clickCount, bounceCount, metadata, createdBy, createdAt, updatedAt];

  double get openRate => recipientCount > 0 ? openCount / recipientCount : 0.0;
  double get clickRate => recipientCount > 0 ? clickCount / recipientCount : 0.0;
  double get bounceRate => recipientCount > 0 ? bounceCount / recipientCount : 0.0;

  EmailCampaign copyWith({
    String? id, String? name, CampaignType? campaignType, String? subject, String? body,
    String? bodyHtml, Map<String, dynamic>? targetAudience, String? status, DateTime? scheduledAt,
    DateTime? sentAt, int? recipientCount, int? openCount, int? clickCount, int? bounceCount,
    Map<String, dynamic>? metadata, String? createdBy, DateTime? createdAt, DateTime? updatedAt,
  }) => EmailCampaign(
    id: id ?? this.id, name: name ?? this.name, campaignType: campaignType ?? this.campaignType,
    subject: subject ?? this.subject, body: body ?? this.body, bodyHtml: bodyHtml ?? this.bodyHtml,
    targetAudience: targetAudience ?? this.targetAudience, status: status ?? this.status,
    scheduledAt: scheduledAt ?? this.scheduledAt, sentAt: sentAt ?? this.sentAt,
    recipientCount: recipientCount ?? this.recipientCount, openCount: openCount ?? this.openCount,
    clickCount: clickCount ?? this.clickCount, bounceCount: bounceCount ?? this.bounceCount,
    metadata: metadata ?? this.metadata, createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ReferralProgram extends Equatable {
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

  const ReferralProgram({
    required this.id, required this.schoolId, required this.name, required this.description,
    required this.rewardType, required this.rewardValue, required this.referralCode,
    required this.isActive, this.maxReferrals, required this.totalReferrals,
    required this.metadata, required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, schoolId, name, description, rewardType, rewardValue, referralCode, isActive, maxReferrals, totalReferrals, metadata, createdAt, updatedAt];

  ReferralProgram copyWith({
    String? id, String? schoolId, String? name, String? description, String? rewardType,
    double? rewardValue, String? referralCode, bool? isActive, int? maxReferrals,
    int? totalReferrals, Map<String, dynamic>? metadata, DateTime? createdAt, DateTime? updatedAt,
  }) => ReferralProgram(
    id: id ?? this.id, schoolId: schoolId ?? this.schoolId, name: name ?? this.name,
    description: description ?? this.description, rewardType: rewardType ?? this.rewardType,
    rewardValue: rewardValue ?? this.rewardValue, referralCode: referralCode ?? this.referralCode,
    isActive: isActive ?? this.isActive, maxReferrals: maxReferrals ?? this.maxReferrals,
    totalReferrals: totalReferrals ?? this.totalReferrals, metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Referral extends Equatable {
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

  const Referral({
    required this.id, required this.referralProgramId, required this.referrerId,
    required this.referralCode, required this.referredEmail, this.referredId,
    required this.status, required this.rewardIssued, this.rewardIssuedAt,
    required this.metadata, required this.createdAt,
  });

  @override
  List<Object?> get props => [id, referralProgramId, referrerId, referralCode, referredEmail, referredId, status, rewardIssued, rewardIssuedAt, metadata, createdAt];

  Referral copyWith({
    String? id, String? referralProgramId, String? referrerId, String? referralCode,
    String? referredEmail, String? referredId, String? status, bool? rewardIssued,
    DateTime? rewardIssuedAt, Map<String, dynamic>? metadata, DateTime? createdAt,
  }) => Referral(
    id: id ?? this.id, referralProgramId: referralProgramId ?? this.referralProgramId,
    referrerId: referrerId ?? this.referrerId, referralCode: referralCode ?? this.referralCode,
    referredEmail: referredEmail ?? this.referredEmail, referredId: referredId ?? this.referredId,
    status: status ?? this.status, rewardIssued: rewardIssued ?? this.rewardIssued,
    rewardIssuedAt: rewardIssuedAt ?? this.rewardIssuedAt, metadata: metadata ?? this.metadata,
    createdAt: createdAt ?? this.createdAt,
  );
}

class Affiliate extends Equatable {
  final String id;
  final String userId;
  final String affiliateCode;
  final AffiliateStatus status;
  final double commissionRate;
  final double totalEarnings;
  final double pendingEarnings;
  final double paidEarnings;
  final int referralsCount;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Affiliate({
    required this.id, required this.userId, required this.affiliateCode, required this.status,
    required this.commissionRate, required this.totalEarnings, required this.pendingEarnings,
    required this.paidEarnings, required this.referralsCount, required this.metadata,
    required this.createdAt, required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, affiliateCode, status, commissionRate, totalEarnings, pendingEarnings, paidEarnings, referralsCount, metadata, createdAt, updatedAt];

  Affiliate copyWith({
    String? id, String? userId, String? affiliateCode, AffiliateStatus? status,
    double? commissionRate, double? totalEarnings, double? pendingEarnings,
    double? paidEarnings, int? referralsCount, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt,
  }) => Affiliate(
    id: id ?? this.id, userId: userId ?? this.userId, affiliateCode: affiliateCode ?? this.affiliateCode,
    status: status ?? this.status, commissionRate: commissionRate ?? this.commissionRate,
    totalEarnings: totalEarnings ?? this.totalEarnings, pendingEarnings: pendingEarnings ?? this.pendingEarnings,
    paidEarnings: paidEarnings ?? this.paidEarnings, referralsCount: referralsCount ?? this.referralsCount,
    metadata: metadata ?? this.metadata, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
  );
}

class AffiliateReferral extends Equatable {
  final String id;
  final String affiliateId;
  final String? referredId;
  final String referredEmail;
  final String? subscriptionId;
  final double commissionEarned;
  final String status;
  final DateTime? paidAt;
  final DateTime createdAt;

  const AffiliateReferral({
    required this.id, required this.affiliateId, this.referredId, required this.referredEmail,
    this.subscriptionId, required this.commissionEarned, required this.status, this.paidAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, affiliateId, referredId, referredEmail, subscriptionId, commissionEarned, status, paidAt, createdAt];

  AffiliateReferral copyWith({
    String? id, String? affiliateId, String? referredId, String? referredEmail,
    String? subscriptionId, double? commissionEarned, String? status, DateTime? paidAt, DateTime? createdAt,
  }) => AffiliateReferral(
    id: id ?? this.id, affiliateId: affiliateId ?? this.affiliateId, referredId: referredId ?? this.referredId,
    referredEmail: referredEmail ?? this.referredEmail, subscriptionId: subscriptionId ?? this.subscriptionId,
    commissionEarned: commissionEarned ?? this.commissionEarned, status: status ?? this.status,
    paidAt: paidAt ?? this.paidAt, createdAt: createdAt ?? this.createdAt,
  );
}
