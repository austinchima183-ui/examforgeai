import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../../domain/usecases/send_parent_message_usecase.dart';
import '../providers/parent_messaging_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT MESSAGING PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Secure messaging page for parent-teacher communication.
///
/// Presents two views:
/// - **Threads list** (default): Shows all conversation threads with
///   avatar, name, role badge, last message preview, unread count,
///   timestamp, and optional student name tag.
/// - **Conversation view** (shown when a thread is selected): Shows
///   message bubbles with date separators, read receipts, and an
///   input bar for composing new messages.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// loads data in [initState] via [WidgetsBinding.instance.addPostFrameCallback],
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentMessagingPage extends ConsumerStatefulWidget {
  const ParentMessagingPage({super.key});

  @override
  ConsumerState<ParentMessagingPage> createState() => _State();
}

class _State extends ConsumerState<ParentMessagingPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// The currently selected thread, or `null` to show the threads list.
  ParentMessageThreadEntity? _selectedThread;

  /// Search query for filtering threads.
  String _searchQuery = '';

  /// Controller for the message input field.
  final TextEditingController _messageController = TextEditingController();

  /// Scroll controller for the conversation messages list.
  final ScrollController _scrollController = ScrollController();

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentMessagingProvider.notifier).loadThreads();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messagingState = ref.watch(parentMessagingProvider);

    return Scaffold(
      appBar: _selectedThread != null
          ? _buildConversationAppBar(context, messagingState)
          : AppAppBar(
              title: 'Messages',
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Compose',
                  onPressed: () {
                    // TODO: Navigate to compose new message
                  },
                ),
              ],
            ),
      body: _selectedThread != null
          ? _buildConversationView(context, messagingState)
          : _buildThreadsView(context, messagingState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATION APP BAR
  // ═══════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildConversationAppBar(
    BuildContext context,
    ParentMessagingState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final thread = _selectedThread!;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() => _selectedThread = null);
          ref.read(parentMessagingProvider.notifier).loadThreads();
        },
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Text(
              thread.otherUserName.isNotEmpty
                  ? thread.otherUserName[0].toUpperCase()
                  : '?',
              style: tt.labelMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: AppTypography.wBold,
              ),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.otherUserName,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _roleLabel(thread.otherUserRole),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // THREADS LIST VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildThreadsView(
    BuildContext context,
    ParentMessagingState state,
  ) {
    // Loading state
    if (state.isLoading && state.threads.isEmpty) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.threads.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(parentMessagingProvider.notifier).loadThreads(),
      );
    }

    // Filter threads by search query
    final threads = _filterThreads(state.threads);

    return Column(
      children: [
        // ─── Search Bar ───────────────────────────────────────────
        _buildSearchBar(context),

        // ─── Threads List ─────────────────────────────────────────
        Expanded(
          child: threads.isEmpty
              ? AppEmptyState.noMessages(
                  title: 'No Messages Yet',
                  subtitle:
                      'Start a conversation with a teacher.',
                  actionLabel: 'Compose',
                  onAction: () {
                    // TODO: Navigate to compose
                  },
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(parentMessagingProvider.notifier).loadThreads(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacings.xxl),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.xs),
                    itemBuilder: (_, index) =>
                        _buildThreadCard(context, threads[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────

  Widget _buildSearchBar(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search messages…',
          hintStyle: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: cs.onSurfaceVariant,
            size: Spacings.mdIcon,
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: const OutlineInputBorder(
            borderRadius: Spacings.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  // ─── Thread Card ────────────────────────────────────────────────────

  Widget _buildThreadCard(
    BuildContext context,
    ParentMessageThreadEntity thread,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final hasUnread = thread.unreadCount > 0;
    final initial = thread.otherUserName.isNotEmpty
        ? thread.otherUserName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: hasUnread
            ? cs.primaryContainer.withValues(alpha: 0.15)
            : cs.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: InkWell(
          onTap: () => _openThread(thread),
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    initial,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.md),

                // Name, role, last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Name
                          Expanded(
                            child: Text(
                              thread.otherUserName,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: hasUnread
                                    ? AppTypography.wBold
                                    : AppTypography.wSemiBold,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                            child: Text(
                              _roleLabel(thread.otherUserRole),
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.xs),
                      // Last message preview
                      if (thread.lastMessage != null)
                        Text(
                          thread.lastMessage!.body,
                          style: tt.bodySmall?.copyWith(
                            fontWeight: hasUnread
                                ? AppTypography.wSemiBold
                                : AppTypography.wRegular,
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Student name tag
                      if (thread.studentName != null) ...[
                        const SizedBox(height: Spacings.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          child: Text(
                            thread.studentName!,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: Spacings.sm),

                // Unread count + timestamp
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Timestamp
                    if (thread.lastMessage != null)
                      Text(
                        _formatTimeAgo(thread.lastMessage!.createdAt),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: Spacings.xs),
                    // Unread count badge
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: Spacings.borderRadiusFull,
                        ),
                        child: Text(
                          '${thread.unreadCount}',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: AppTypography.wBold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATION VIEW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildConversationView(
    BuildContext context,
    ParentMessagingState state,
  ) {
    final messages = state.messages;

    return Column(
      children: [
        // ─── Messages List ────────────────────────────────────────
        Expanded(
          child: state.isLoading && messages.isEmpty
              ? _buildShimmerLoading(context)
              : messages.isEmpty
                  ? AppEmptyState.noMessages(
                      title: 'No Messages',
                      subtitle: 'Start the conversation below.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(parentMessagingProvider.notifier)
                          .loadMessages(_selectedThread!.threadId),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.lg,
                          vertical: Spacings.md,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (_, index) {
                          final message = messages[index];
                          final showDateSeparator = _shouldShowDateSeparator(
                            messages,
                            index,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateSeparator)
                                _buildDateSeparator(
                                  context,
                                  message.createdAt,
                                ),
                              _buildMessageBubble(context, message),
                            ],
                          );
                        },
                      ),
                    ),
        ),

        // ─── Input Bar ────────────────────────────────────────────
        _buildInputBar(context, state),
      ],
    );
  }

  // ─── Message Bubble ─────────────────────────────────────────────────

  Widget _buildMessageBubble(
    BuildContext context,
    ParentMessageEntity message,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isSent = message.direction == MessageDirection.outgoing;
    final isRead = message.readAt != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.width * 0.75,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            decoration: BoxDecoration(
              color: isSent ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(Spacings.mdRadius),
                topRight: const Radius.circular(Spacings.mdRadius),
                bottomLeft: Radius.circular(
                  isSent ? Spacings.mdRadius : Spacings.xs,
                ),
                bottomRight: Radius.circular(
                  isSent ? Spacings.xs : Spacings.mdRadius,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message body
                Text(
                  message.body,
                  style: tt.bodyMedium?.copyWith(
                    color: isSent ? cs.onPrimary : cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                // Timestamp + read receipt
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: isSent
                            ? cs.onPrimary.withValues(alpha: 0.7)
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    if (isSent) ...[
                      const SizedBox(width: Spacings.xs),
                      Icon(
                        isRead
                            ? Icons.done_all
                            : Icons.done,
                        size: Spacings.smIcon,
                        color: isRead
                            ? cs.onPrimary.withValues(alpha: 0.7)
                            : cs.onPrimary.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Date Separator ─────────────────────────────────────────────────

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.md,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            _formatDate(date),
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Input Bar ──────────────────────────────────────────────────────

  Widget _buildInputBar(BuildContext context, ParentMessagingState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Container(
      padding: EdgeInsets.only(
        left: Spacings.lg,
        right: Spacings.lg,
        top: Spacings.sm,
        bottom: Spacings.lg + context.mediaQuery.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(
              Icons.attach_file_outlined,
              color: cs.onSurfaceVariant,
              size: Spacings.mdIcon,
            ),
            onPressed: () {
              // TODO: Handle attachment
            },
            tooltip: 'Attach file',
          ),
          const SizedBox(width: Spacings.xs),
          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: const OutlineInputBorder(
                  borderRadius: Spacings.borderRadiusMd,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.sm,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(state),
            ),
          ),
          const SizedBox(width: Spacings.xs),
          // Send button
          IconButton(
            icon: Icon(
              Icons.send,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
            onPressed: state.isSending ? null : () => _sendMessage(state),
            tooltip: 'Send',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(
              6,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: Spacings.md),
                child: Row(
                  children: [
                    AppLoadingShimmer.box(
                      width: 48,
                      height: 48,
                      shape: BoxShape.circle,
                    ),
                    SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLoadingShimmer.box(
                            width: 140,
                            height: 14,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          SizedBox(height: Spacings.sm),
                          AppLoadingShimmer.box(
                            height: 12,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Opens a conversation thread and loads its messages.
  void _openThread(ParentMessageThreadEntity thread) {
    setState(() => _selectedThread = thread);
    ref.read(parentMessagingProvider.notifier).loadMessages(thread.threadId);
  }

  /// Sends a message in the current conversation.
  void _sendMessage(ParentMessagingState state) {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedThread == null) return;

    _messageController.clear();
    ref.read(parentMessagingProvider.notifier).sendMessage(
      SendMessageParams(
        recipientId: _selectedThread!.otherUserId,
        subject: _selectedThread!.lastMessage?.subject ?? 'Message',
        body: text,
      ),
    );

    // Auto-scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTERING
  // ═══════════════════════════════════════════════════════════════════════

  /// Filters threads by the current search query.
  List<ParentMessageThreadEntity> _filterThreads(
    List<ParentMessageThreadEntity> threads,
  ) {
    if (_searchQuery.isEmpty) return threads;
    final query = _searchQuery.toLowerCase();
    return threads.where((thread) {
      return thread.otherUserName.toLowerCase().contains(query) ||
          (thread.studentName?.toLowerCase().contains(query) ?? false) ||
          (thread.lastMessage?.body.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns a human-readable role label.
  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
        return 'Teacher';
      case 'admin':
        return 'Admin';
      case 'principal':
        return 'Principal';
      default:
        return role[0].toUpperCase() + role.substring(1);
    }
  }

  /// Determines whether a date separator should be shown before [index].
  bool _shouldShowDateSeparator(
    List<ParentMessageEntity> messages,
    int index,
  ) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  /// Formats a [DateTime] as a short date string for separators.
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  /// Formats a [DateTime] as a short time string for message bubbles.
  String _formatMessageTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats a [DateTime] as a relative time-ago string.
  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(dt);
  }
}
