import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/communication_entities.dart';
import 'online_status_indicator.dart';

// ─── ConversationTile ─────────────────────────────────────────────────────────

/// A list tile showing a conversation preview with avatar, name, last message,
/// timestamp, unread count badge, muted/pinned icons, and online indicator.
///
/// ```dart
/// ConversationTile(
///   conversation: convo,
///   onTap: () => openChat(convo.id),
///   onLongPress: () => showOptions(convo.id),
/// )
/// ```
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.onLongPress,
  });

  /// The conversation entity to display.
  final ConversationEntity conversation;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  String _displayName() {
    if (conversation.name != null && conversation.name!.isNotEmpty) {
      return conversation.name!;
    }
    final others = conversation.participants
        .where((p) => p.userName != null)
        .map((p) => p.userName!)
        .toList();
    if (others.isEmpty) return 'Conversation';
    if (others.length == 1) return others.first;
    if (others.length == 2) return '${others[0]} & ${others[1]}';
    return '${others[0]}, ${others[1]} +${others.length - 2}';
  }

  String? _avatarInitial() {
    final name = _displayName();
    return name.isNotEmpty ? name[0].toUpperCase() : null;
  }

  bool _hasOnlineParticipant() =>
      conversation.participants.any((p) => p.isOnline);

  // ─── Builders ──────────────────────────────────────────────────────────

  Widget _buildAvatar(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;
    final isGroup = conversation.type != ConversationType.direct;

    if (conversation.avatarUrl != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(conversation.avatarUrl!),
          ),
          if (_hasOnlineParticipant() && !isGroup)
            Positioned(
              right: -1,
              bottom: -1,
              child: OnlineStatusIndicator(
                isOnline: true,
                size: 12,
              ),
            ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isGroup
                ? cs.tertiaryContainer
                : cs.primary.withOpacity(isDark ? 0.25 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isGroup
                ? Icon(Icons.group_rounded,
                    size: Spacings.mdIcon, color: cs.onTertiaryContainer)
                : Text(
                    _avatarInitial() ?? '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: AppTypography.wBold,
                      color: isGroup
                          ? cs.onTertiaryContainer
                          : cs.primary,
                      height: 1.0,
                    ),
                  ),
          ),
        ),
        if (_hasOnlineParticipant() && !isGroup)
          Positioned(
            right: -1,
            bottom: -1,
            child: OnlineStatusIndicator(isOnline: true, size: 12),
          ),
      ],
    );
  }

  Widget _buildUnreadBadge(BuildContext context) {
    if (conversation.unreadCount <= 0) return const SizedBox.shrink();
    final count = conversation.unreadCount;
    final display = count > 99 ? '99+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.seed,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      constraints: const BoxConstraints(minWidth: 20),
      child: Text(
        display,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 10,
          fontWeight: AppTypography.wBold,
          color: Colors.white,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(context),
            const SizedBox(width: Spacings.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _displayName(),
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: conversation.unreadCount > 0
                                      ? AppTypography.wBold
                                      : AppTypography.wMedium,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation.isPinned) ...[
                              const SizedBox(width: Spacings.xs),
                              Icon(Icons.push_pin_rounded,
                                  size: Spacings.smIcon,
                                  color: cs.onSurfaceVariant),
                            ],
                            if (conversation.isMuted) ...[
                              const SizedBox(width: Spacings.xs),
                              Icon(Icons.notifications_off_rounded,
                                  size: Spacings.smIcon,
                                  color: cs.onSurfaceVariant),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: tt.labelSmall?.copyWith(
                          color: conversation.unreadCount > 0
                              ? AppColors.seed
                              : cs.onSurfaceVariant,
                          fontWeight: conversation.unreadCount > 0
                              ? AppTypography.wSemiBold
                              : AppTypography.wRegular,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Spacings.xs),

                  // Bottom row: last message + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessageText ?? 'No messages yet',
                          style: tt.bodySmall?.copyWith(
                            color: conversation.unreadCount > 0
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight: conversation.unreadCount > 0
                                ? AppTypography.wMedium
                                : AppTypography.wRegular,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      _buildUnreadBadge(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
