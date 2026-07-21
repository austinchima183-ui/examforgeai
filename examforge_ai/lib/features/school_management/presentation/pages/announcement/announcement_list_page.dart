import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../../../../shared/models/user_role.dart';
import '../../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/announcement_provider.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../features/school_management/domain/entities/school_management_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Displays a filterable list of school announcements with type filter
/// chips, priority badges, pinned items at top, and role-based actions.
class AnnouncementListPage extends ConsumerStatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  ConsumerState<AnnouncementListPage> createState() =>
      _AnnouncementListPageState();
}

class _AnnouncementListPageState extends ConsumerState<AnnouncementListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  AnnouncementType? _selectedType;

  /// Whether the current user has an admin or teacher role.
  bool get _isAdminOrTeacher {
    final role = ref.read(resolvedUserRoleProvider);
    return role != null &&
        (role.isAdmin || role == UserRole.teacher);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(announcementListProvider.notifier).loadAnnouncements(
            schoolId: 'current-school',
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Colour helpers ────────────────────────────────────────────────

  Color _priorityColor(AnnouncementPriority priority) {
    return switch (priority) {
      AnnouncementPriority.low => const Color(0xFF9CA3AF),
      AnnouncementPriority.normal => const Color(0xFF3B82F6),
      AnnouncementPriority.high => const Color(0xFFF59E0B),
      AnnouncementPriority.urgent => const Color(0xFFEF4444),
    };
  }

  IconData _typeIcon(AnnouncementType type) {
    return switch (type) {
      AnnouncementType.notice => Icons.info_outline_rounded,
      AnnouncementType.event => Icons.event_rounded,
      AnnouncementType.circular => Icons.description_outlined,
      AnnouncementType.holiday => Icons.beach_access_rounded,
      AnnouncementType.emergency => Icons.warning_amber_rounded,
    };
  }

  Color _typeColor(AnnouncementType type) {
    return switch (type) {
      AnnouncementType.notice => AppColors.info,
      AnnouncementType.event => const Color(0xFF8B5CF6),
      AnnouncementType.circular => const Color(0xFF06B6D4),
      AnnouncementType.holiday => AppColors.success,
      AnnouncementType.emergency => AppColors.error,
    };
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(announcementListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Announcements',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() => _isSearchMode = !_isSearchMode);
              if (!_isSearchMode) {
                _searchController.clear();
                ref.read(announcementListProvider.notifier).loadAnnouncements(
                      schoolId: 'current-school',
                    );
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search announcements',
          ),
        ],
        bottom: _isSearchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search announcements...',
                    controller: _searchController,
                    onChanged: (query) {
                      // Future: search
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(announcementListProvider.notifier).loadAnnouncements(
              schoolId: 'current-school',
            ),
        child: Column(
          children: [
            // ─── Type filter chips ───────────────────────────────────
            _buildFilterChips(context),
            // ─── Announcement list ───────────────────────────────────
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
      floatingActionButton: _isAdminOrTeacher
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to announcement form
              },
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('New Announcement'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            )
          : null,
    );
  }

  // ─── Filter chips ──────────────────────────────────────────────────

  Widget _buildFilterChips(BuildContext context) {
    final cs = context.colorScheme;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.sm,
        ),
        children: [
          _TypeChip(
            label: 'All',
            selected: _selectedType == null,
            color: cs.primary,
            onSelected: () {
              setState(() => _selectedType = null);
              ref.read(announcementListProvider.notifier).setTypeFilter(null);
              ref.read(announcementListProvider.notifier).loadAnnouncements(
                    schoolId: 'current-school',
                  );
            },
          ),
          const SizedBox(width: Spacings.sm),
          ...AnnouncementType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: _TypeChip(
                label: type.label,
                selected: _selectedType == type,
                color: _typeColor(type),
                onSelected: () {
                  setState(() => _selectedType = type);
                  ref.read(announcementListProvider.notifier).setTypeFilter(type);
                  ref.read(announcementListProvider.notifier).loadAnnouncements(
                        schoolId: 'current-school',
                        type: type,
                      );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AnnouncementListState state) {
    if (state.isLoading && state.announcements.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && state.announcements.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(announcementListProvider.notifier).loadAnnouncements(
              schoolId: 'current-school',
            ),
      );
    }

    if (state.announcements.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.campaign_outlined,
            title: _isSearchMode ? 'No Matching Announcements' : 'No Announcements',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Create the first announcement for your school.',
            actionLabel: _isSearchMode ? null : 'Create Announcement',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to form
                  },
          ),
        ],
      );
    }

    // Sort: pinned first, then by date
    final sorted = List<AnnouncementEntity>.from(state.announcements)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _AnnouncementCard(
            announcement: sorted[index],
            typeIcon: _typeIcon,
            typeColor: _typeColor,
            priorityColor: _priorityColor,
            isAdminOrTeacher: _isAdminOrTeacher,
            onTap: () {
              // Navigate to detail
            },
            onPublish: (id) {
              ref.read(announcementListProvider.notifier).publishAnnouncement(id);
            },
            onDelete: (id) {
              _confirmDelete(context, id);
            },
          ),
        );
      },
    );
  }

  // ─── Delete confirmation ───────────────────────────────────────────

  void _confirmDelete(BuildContext context, String announcementId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text(
          'Are you sure you want to delete this announcement? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(announcementListProvider.notifier).deleteAnnouncement(announcementId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TYPE FILTER CHIP
// ═══════════════════════════════════════════════════════════════════════

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.20),
      checkmarkColor: color,
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: selected ? color : context.colorScheme.onSurfaceVariant,
        fontWeight: selected ? AppTypography.wSemiBold : AppTypography.wMedium,
      ),
      side: BorderSide(
        color: selected ? color : context.colorScheme.outlineVariant,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT CARD
// ═══════════════════════════════════════════════════════════════════════

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    required this.announcement,
    required this.typeIcon,
    required this.typeColor,
    required this.priorityColor,
    this.isAdminOrTeacher = false,
    this.onTap,
    this.onPublish,
    this.onDelete,
  });

  final AnnouncementEntity announcement;
  final IconData Function(AnnouncementType) typeIcon;
  final Color Function(AnnouncementType) typeColor;
  final Color Function(AnnouncementPriority) priorityColor;
  final bool isAdminOrTeacher;
  final VoidCallback? onTap;
  final void Function(String)? onPublish;
  final void Function(String)? onDelete;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final pColor = priorityColor(announcement.priority);
    final tColor = typeColor(announcement.announcementType);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top row: type icon + title + priority badge ───────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: tColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  typeIcon(announcement.announcementType),
                  size: Spacings.mdIcon,
                  color: tColor,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (announcement.isPinned) ...[
                          Icon(Icons.push_pin_rounded, size: Spacings.smIcon, color: cs.primary),
                          const SizedBox(width: Spacings.xs),
                        ],
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: pColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        announcement.priority.label,
                        style: tt.labelSmall?.copyWith(
                          color: pColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ─── Preview content ───────────────────────────────────────
          Text(
            announcement.content,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacings.md),

          // ─── Date + attachment indicator ───────────────────────────
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                _formatDate(announcement.createdAt),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if (announcement.attachmentUrls.isNotEmpty) ...[
                Icon(Icons.attach_file_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${announcement.attachmentUrls.length}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              if (!announcement.isPublished) ...[
                const SizedBox(width: Spacings.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    'Draft',
                    style: tt.labelSmall?.copyWith(
                      color: AppColors.info,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // ─── Admin/Teacher actions ─────────────────────────────────
          if (isAdminOrTeacher) ...[
            const SizedBox(height: Spacings.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacings.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!announcement.isPublished)
                  TextButton.icon(
                    onPressed: () => onPublish?.call(announcement.id),
                    icon: const Icon(Icons.publish_rounded, size: Spacings.smIcon),
                    label: const Text('Publish'),
                    style: TextButton.styleFrom(foregroundColor: cs.primary),
                  ),
                const SizedBox(width: Spacings.sm),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to edit form
                  },
                  icon: const Icon(Icons.edit_outlined, size: Spacings.smIcon),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
                ),
                const SizedBox(width: Spacings.sm),
                TextButton.icon(
                  onPressed: () => onDelete?.call(announcement.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: Spacings.smIcon),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
