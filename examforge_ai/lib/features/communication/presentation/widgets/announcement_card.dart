import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/entities/communication_entities.dart';
import 'priority_badge.dart';


// ─── AnnouncementCard ─────────────────────────────────────────────────────────

/// A card widget for displaying an announcement preview with title, body
/// excerpt, type/priority badges, author, time, pinned icon, view count,
/// and acknowledge button.
///
/// ```dart
/// AnnouncementCard(
///   announcement: announcement,
///   onTap: () => openAnnouncement(announcement.id),
///   onAcknowledge: () => ack(announcement.id),
/// )
/// ```
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.onAcknowledge,
  });

  final AnnouncementEntity announcement;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ─── Type Badge Builder ───────────────────────────────────────────────

  Widget _buildTypeBadge(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final type = announcement.announcementType;
    final color = _typeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: AppTypography.wSemiBold,
          letterSpacing: AppTypography.lsCaption,
          color: isDark ? color.withValues(alpha: 0.9) : color,
        ),
      ),
    );
  }

  Color _typeColor(AnnouncementType type) {
    return switch (type) {
      AnnouncementType.emergency => const Color(0xFFDC2626),
      AnnouncementType.examination => const Color(0xFF7C3AED),
      AnnouncementType.holiday => const Color(0xFF16A34A),
      AnnouncementType.event => AppColors.seed,
      AnnouncementType.schoolWide => AppColors.info,
      AnnouncementType.timetableUpdate => const Color(0xFFEA580C),
      _ => const Color(0xFF6B7280),
    };
  }

  // ─── Acknowledge Button ───────────────────────────────────────────────

  Widget _buildAckButton(BuildContext context) {
    final cs = context.colorScheme;
    final isAcknowledged = announcement.acknowledgedBy.isNotEmpty;

    if (isAcknowledged) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: Spacings.smIcon, color: AppColors.success,),
          SizedBox(width: Spacings.xs),
          Text(
            'Acknowledged',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: AppTypography.wMedium,
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: onAcknowledge,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.xs,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: cs.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
      ),
      child: Text(
        'Acknowledge',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: AppTypography.wSemiBold,
          color: cs.primary,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Type badge + Priority badge + Pinned ─────────
          Row(
            children: [
              _buildTypeBadge(context),
              const SizedBox(width: Spacings.sm),
              PriorityBadge(priority: announcement.priority.value),
              const Spacer(),
              if (announcement.isPinned)
                Icon(Icons.push_pin_rounded,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              if (announcement.isAiGenerated) ...[
                const SizedBox(width: Spacings.xs),
                Icon(Icons.auto_awesome_rounded,
                    size: Spacings.smIcon, color: cs.tertiary,),
              ],
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Title ─────────────────────────────────────────────────
          Text(
            announcement.title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Spacings.sm),

          // ── Body Excerpt ──────────────────────────────────────────
          Text(
            announcement.body,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: Spacings.md),

          // ── Footer: Author + Time + Views + Acknowledge ───────────
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Expanded(
                child: Text(
                  announcement.authorName,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Icon(Icons.access_time_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                _relativeTime(announcement.createdAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (announcement.viewCount > 0) ...[
                const SizedBox(width: Spacings.md),
                Icon(Icons.visibility_outlined,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant,),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${announcement.viewCount}',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          // ── Acknowledge button ────────────────────────────────────
          if (announcement.priority == AnnouncementPriority.urgent ||
              announcement.priority == AnnouncementPriority.high) ...[
            const SizedBox(height: Spacings.md),
            _buildAckButton(context),
          ],
        ],
      ),
    );
  }
}
