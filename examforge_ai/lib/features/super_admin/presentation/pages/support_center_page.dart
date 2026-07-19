import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Color _priorityColor(TicketPriority priority) {
  switch (priority) {
    case TicketPriority.low:
      return Colors.grey;
    case TicketPriority.medium:
      return AppColors.info;
    case TicketPriority.high:
      return Colors.orange;
    case TicketPriority.urgent:
      return AppColors.error;
    case TicketPriority.critical:
      return AppColors.errorDark;
  }
}

Color _statusColor(TicketStatus status) {
  switch (status) {
    case TicketStatus.open:
      return AppColors.info;
    case TicketStatus.inProgress:
      return Colors.orange;
    case TicketStatus.waitingOnUser:
      return AppColors.warning;
    case TicketStatus.waitingOnThirdParty:
      return AppColors.warning;
    case TicketStatus.resolved:
      return AppColors.success;
    case TicketStatus.closed:
      return Colors.grey;
    case TicketStatus.reopened:
      return AppColors.info;
  }
}

String _formatTimeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK TYPE ENUM (local to this feature)
// ═══════════════════════════════════════════════════════════════════════════════

enum FeedbackType {
  bugReport('bug_report', 'Bug Report', Icons.bug_report_rounded),
  featureRequest('feature_request', 'Feature Request', Icons.lightbulb_outline),
  complaint('complaint', 'Complaint', Icons.sentiment_dissatisfied_outlined),
  compliment('compliment', 'Compliment', Icons.sentiment_satisfied_outlined),
  suggestion('suggestion', 'Suggestion', Icons.tips_and_updates_outlined),
  rating('rating', 'Rating', Icons.star_outline_rounded);

  const FeedbackType(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  static FeedbackType fromString(String v) => FeedbackType.values.firstWhere(
        (e) => e.value == v,
        orElse: () => FeedbackType.suggestion,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORT CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Support Center page for the Super Admin.
///
/// Features:
/// - **Tickets tab**: Searchable, filterable ticket list with assign/escalate/resolve actions
/// - **Feedback tab**: User feedback cards with type filtering and star ratings
class SupportCenterPage extends ConsumerStatefulWidget {
  const SupportCenterPage({super.key});

  @override
  ConsumerState<SupportCenterPage> createState() =>
      _SupportCenterPageState();
}

class _SupportCenterPageState extends ConsumerState<SupportCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ─── Ticket Filters ─────────────────────────────────────────────────────

  final _searchController = TextEditingController();
  TicketStatus? _filterStatus;
  TicketPriority? _filterPriority;
  TicketCategory? _filterCategory;

  // ─── Feedback Filters ───────────────────────────────────────────────────

  FeedbackType? _filterFeedbackType;

  static const _tabs = [
    Tab(icon: Icon(Icons.confirmation_number_outlined), text: 'Tickets'),
    Tab(icon: Icon(Icons.feedback_outlined), text: 'Feedback'),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTabData(_tabController.index);
    }
  }

  void _loadData() {
    _loadTabData(_tabController.index);
  }

  void _loadTabData(int index) {
    final notifier = ref.read(supportCenterProvider.notifier);
    switch (index) {
      case 0:
        notifier.loadTickets(
          status: _filterStatus,
          priority: _filterPriority,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
        break;
      case 1:
        // Feedback is loaded alongside tickets; no separate load method
        notifier.loadTickets();
        break;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportCenterProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error snackbar messages
    ref.listen<SupportCenterState>(supportCenterProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(supportCenterProvider.notifier).state =
            ref.read(supportCenterProvider).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(supportCenterProvider.notifier).state =
            ref.read(supportCenterProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Support Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: state.isLoading && state.tickets.isEmpty
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null && state.tickets.isEmpty
              ? _buildErrorState(state.error!, cs)
              : Column(
                  children: [
                    // ─── Tab Bar ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: _tabs,
                        labelColor: cs.primary,
                        unselectedLabelColor:
                            cs.onSurface.withValues(alpha: 0.6),
                        indicatorColor: cs.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                      ),
                    ),

                    // ─── Tab Content ──────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TicketsTab(
                            searchController: _searchController,
                            filterStatus: _filterStatus,
                            filterPriority: _filterPriority,
                            filterCategory: _filterCategory,
                            onSearchChanged: (_) => _loadData(),
                            onStatusChanged: (status) {
                              setState(() => _filterStatus = status);
                              _loadData();
                            },
                            onPriorityChanged: (priority) {
                              setState(() => _filterPriority = priority);
                              _loadData();
                            },
                            onCategoryChanged: (category) {
                              setState(() => _filterCategory = category);
                              _loadData();
                            },
                          ),
                          _FeedbackTab(
                            filterFeedbackType: _filterFeedbackType,
                            onFeedbackTypeChanged: (type) {
                              setState(() => _filterFeedbackType = type);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // ─── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorState(String error, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: Spacings.xlIcon, color: cs.error),
            const SizedBox(height: Spacings.lg),
            Text(
              error,
              style: AppTypography.wRegular.copyWith(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacings.lg),
            FilledButton.tonal(
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TICKETS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _TicketsTab extends StatelessWidget {
  const _TicketsTab({
    required this.searchController,
    required this.filterStatus,
    required this.filterPriority,
    required this.filterCategory,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController searchController;
  final TicketStatus? filterStatus;
  final TicketPriority? filterPriority;
  final TicketCategory? filterCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TicketStatus?> onStatusChanged;
  final ValueChanged<TicketPriority?> onPriorityChanged;
  final ValueChanged<TicketCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(supportCenterProvider);
      final cs = Theme.of(context).colorScheme;

      return Column(
        children: [
          // ─── Search & Filters ─────────────────────────────────────
          Padding(
            padding: Spacings.paddingScreen,
            child: Column(
              children: [
                AdminSearchBar(
                  controller: searchController,
                  hint: 'Search tickets by subject or number...',
                  onChanged: onSearchChanged,
                ),
                const SizedBox(height: Spacings.md),
                _buildFilterRow(cs),
              ],
            ),
          ),

          // ─── Count ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Row(
              children: [
                Text(
                  '${state.tickets.length} ${state.tickets.length == 1 ? 'ticket' : 'tickets'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Ticket List ──────────────────────────────────────────
          Expanded(
            child: state.tickets.isEmpty
                ? const AdminEmptyState(
                    message: 'No tickets found',
                    icon: Icons.confirmation_number_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.read(supportCenterProvider.notifier).loadTickets(
                            status: filterStatus,
                            priority: filterPriority,
                            search: searchController.text.trim().isEmpty
                                ? null
                                : searchController.text.trim(),
                          );
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: Spacings.paddingScreen,
                      itemCount: state.tickets.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacings.sm),
                      itemBuilder: (context, index) {
                        return _TicketCard(
                          ticket: state.tickets[index],
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterRow(ColorScheme cs) {
    return Row(
      children: [
        // Status dropdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              DropdownButtonFormField<TicketStatus?>(
                value: filterStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: Spacings.borderRadiusMd),
                  contentPadding: Spacings.paddingInput,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<TicketStatus?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...TicketStatus.values.map(
                    (s) => DropdownMenuItem<TicketStatus?>(
                      value: s,
                      child: Text(s.label),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacings.md),
        // Priority dropdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Priority',
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              DropdownButtonFormField<TicketPriority?>(
                value: filterPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: Spacings.borderRadiusMd),
                  contentPadding: Spacings.paddingInput,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<TicketPriority?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...TicketPriority.values.map(
                    (p) => DropdownMenuItem<TicketPriority?>(
                      value: p,
                      child: Text(p.label),
                    ),
                  ),
                ],
                onChanged: onPriorityChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacings.md),
        // Category dropdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: AppTypography.wSemiBold.copyWith(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              DropdownButtonFormField<TicketCategory?>(
                value: filterCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: Spacings.borderRadiusMd),
                  contentPadding: Spacings.paddingInput,
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<TicketCategory?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ...TicketCategory.values.map(
                    (c) => DropdownMenuItem<TicketCategory?>(
                      value: c,
                      child: Text(c.label),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TICKET CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priColor = _priorityColor(ticket.priority);
    final staColor = _statusColor(ticket.status);

    return Card(
      elevation: ticket.isEscalated
          ? Spacings.elevationMd
          : Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: ticket.isEscalated
            ? BorderSide(color: AppColors.error.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: Spacings.borderRadiusMd,
        onTap: () => _showTicketDetail(context),
        child: Padding(
          padding: Spacings.paddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Row 1: Ticket # + Subject ───────────────────────
              Row(
                children: [
                  Text(
                    '#${ticket.ticketNumber}',
                    style: AppTypography.wSemiBold.copyWith(
                      fontSize: 12,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  if (ticket.isEscalated)
                    StatusBadge(
                      label: 'Escalated',
                      color: AppColors.error,
                      icon: Icons.arrow_upward,
                    ),
                  const Spacer(),
                  StatusBadge(
                    label: ticket.priority.label,
                    color: priColor,
                  ),
                  const SizedBox(width: Spacings.sm),
                  StatusBadge(
                    label: ticket.status.label,
                    color: staColor,
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),

              // ─── Row 2: Subject ──────────────────────────────────
              Text(
                ticket.subject,
                style: AppTypography.wSemiBold.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.sm),

              // ─── Row 3: Reporter + Assigned + Date ───────────────
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    ticket.reporterId,
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: Spacings.lg),
                  Icon(Icons.assignment_ind_outlined,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    ticket.assignedTo ?? 'Unassigned',
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 12,
                      color: ticket.assignedTo != null
                          ? cs.onSurface.withValues(alpha: 0.6)
                          : AppColors.warning,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule_rounded,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    _formatTimeAgo(ticket.createdAt),
                    style: AppTypography.wRegular.copyWith(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),

              // ─── Action Buttons ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAssignDialog(context),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Assign'),
                  ),
                  const SizedBox(width: Spacings.sm),
                  TextButton.icon(
                    onPressed: () => _showEscalateDialog(context),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('Escalate'),
                  ),
                  const SizedBox(width: Spacings.sm),
                  FilledButton.tonal.icon(
                    onPressed: () => _showResolveDialog(context),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Resolve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetail(BuildContext context) {
    // Navigate to ticket detail or expand inline — placeholder for now
  }

  void _showAssignDialog(BuildContext context) {
    final userSearchController = TextEditingController();
    String selectedUser = '';

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(builder: (context, ref, _) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                'Assign Ticket #${ticket.ticketNumber}',
                style: AppTypography.wSemiBold.copyWith(fontSize: 18),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a user to assign this ticket to:',
                      style: AppTypography.wRegular.copyWith(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: Spacings.lg),
                    TextField(
                      controller: userSearchController,
                      decoration: InputDecoration(
                        labelText: 'User ID or Email',
                        hintText: 'Enter user ID to assign',
                        prefixIcon: const Icon(Icons.search, size: Spacings.mdIcon),
                        border: OutlineInputBorder(
                            borderRadius: Spacings.borderRadiusMd),
                        contentPadding: Spacings.paddingInput,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() => selectedUser = value.trim());
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    userSearchController.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedUser.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          ref
                              .read(supportCenterProvider.notifier)
                              .assignTicket(ticket.id, selectedUser);
                          userSearchController.dispose();
                        },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  void _showEscalateDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final targetUserController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(builder: (context, ref, _) {
        return AlertDialog(
          title: Text(
            'Escalate Ticket #${ticket.ticketNumber}',
            style: AppTypography.wSemiBold.copyWith(fontSize: 18),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escalate this ticket to a higher-level support agent.',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: Spacings.lg),
                TextField(
                  controller: targetUserController,
                  decoration: InputDecoration(
                    labelText: 'Escalate To (User ID)',
                    hintText: 'Enter target user ID',
                    prefixIcon: const Icon(Icons.person_outline, size: Spacings.mdIcon),
                    border: OutlineInputBorder(
                        borderRadius: Spacings.borderRadiusMd),
                    contentPadding: Spacings.paddingInput,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Why is this being escalated?',
                    border: OutlineInputBorder(
                        borderRadius: Spacings.borderRadiusMd),
                    contentPadding: Spacings.paddingInput,
                    isDense: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                reasonController.dispose();
                targetUserController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final target = targetUserController.text.trim();
                if (target.isEmpty) return;
                Navigator.of(dialogContext).pop();
                // TODO: Call escalate when notifier method is available
                // ref.read(supportCenterProvider.notifier).escalateTicket(
                //   ticket.id, target, reasonController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ticket escalated'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                reasonController.dispose();
                targetUserController.dispose();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Escalate'),
            ),
          ],
        );
      }),
    );
  }

  void _showResolveDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(builder: (context, ref, _) {
        return AlertDialog(
          title: Text(
            'Resolve Ticket #${ticket.ticketNumber}',
            style: AppTypography.wSemiBold.copyWith(fontSize: 18),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${ticket.subject}"',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.lg),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Resolution Notes',
                    hintText: 'Describe how the issue was resolved...',
                    border: OutlineInputBorder(
                        borderRadius: Spacings.borderRadiusMd),
                    contentPadding: Spacings.paddingInput,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                notesController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final notes = notesController.text.trim();
                if (notes.isEmpty) return;
                Navigator.of(dialogContext).pop();
                ref
                    .read(supportCenterProvider.notifier)
                    .resolveTicket(ticket.id, notes);
                notesController.dispose();
              },
              child: const Text('Resolve'),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({
    required this.filterFeedbackType,
    required this.onFeedbackTypeChanged,
  });

  final FeedbackType? filterFeedbackType;
  final ValueChanged<FeedbackType?> onFeedbackTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(supportCenterProvider);
      final cs = Theme.of(context).colorScheme;

      // Derive feedback from tickets tagged with feedback metadata
      // In production this would come from a dedicated feedback endpoint
      final feedbackItems = state.tickets
          .where((t) =>
              t.category == TicketCategory.featureRequest ||
              t.category == TicketCategory.bugReport ||
              t.tags?.any((tag) => tag.startsWith('feedback_')) == true)
          .toList();

      // Apply feedback type filter
      final filteredItems = filterFeedbackType != null
          ? feedbackItems.where((t) {
              if (filterFeedbackType == FeedbackType.bugReport &&
                  t.category == TicketCategory.bugReport) {
                return true;
              }
              if (filterFeedbackType == FeedbackType.featureRequest &&
                  t.category == TicketCategory.featureRequest) {
                return true;
              }
              return t.tags?.contains('feedback_${filterFeedbackType!.value}') ==
                  true;
            }).toList()
          : feedbackItems;

      return Column(
        children: [
          // ─── Filter ───────────────────────────────────────────────
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback Type',
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      DropdownButtonFormField<FeedbackType?>(
                        value: filterFeedbackType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: Spacings.borderRadiusMd),
                          contentPadding: Spacings.paddingInput,
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<FeedbackType?>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...FeedbackType.values.map(
                            (type) => DropdownMenuItem<FeedbackType?>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(type.icon, size: 16),
                                  const SizedBox(width: Spacings.sm),
                                  Text(type.label),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: onFeedbackTypeChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Count ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
            child: Row(
              children: [
                Text(
                  '${filteredItems.length} ${filteredItems.length == 1 ? 'item' : 'items'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Feedback List ────────────────────────────────────────
          Expanded(
            child: filteredItems.isEmpty
                ? const AdminEmptyState(
                    message: 'No feedback found',
                    icon: Icons.feedback_outlined,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Spacings.paddingScreen,
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Spacings.sm),
                    itemBuilder: (context, index) {
                      final ticket = filteredItems[index];
                      return _FeedbackCard(ticket: ticket);
                    },
                  ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FEEDBACK CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.ticket});
  final SupportTicket ticket;

  FeedbackType _feedbackType() {
    if (ticket.category == TicketCategory.bugReport) {
      return FeedbackType.bugReport;
    }
    if (ticket.category == TicketCategory.featureRequest) {
      return FeedbackType.featureRequest;
    }
    // Check tags for feedback type
    for (final tag in ticket.tags ?? <String>[]) {
      if (tag.startsWith('feedback_')) {
        return FeedbackType.fromString(tag.replaceFirst('feedback_', ''));
      }
    }
    return FeedbackType.suggestion;
  }

  int _rating() => ticket.satisfactionRating ?? 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fbType = _feedbackType();
    final rating = _rating();

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Row 1: Title + Type Badge ──────────────────────────
            Row(
              children: [
                Icon(fbType.icon, color: cs.primary, size: Spacings.mdIcon),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  label: fbType.label,
                  color: _feedbackTypeColor(fbType),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // ─── Row 2: User ───────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: Spacings.xs),
                Text(
                  ticket.reporterId,
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                // ─── Star Rating ────────────────────────────────────
                if (rating > 0) ...[
                  _StarRating(rating: rating),
                ],
              ],
            ),
            const SizedBox(height: Spacings.sm),

            // ─── Row 3: Content Preview ─────────────────────────────
            Text(
              ticket.description,
              style: AppTypography.wRegular.copyWith(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Spacings.sm),

            // ─── Row 4: Date ────────────────────────────────────────
            Text(
              _formatTimeAgo(ticket.createdAt),
              style: AppTypography.wRegular.copyWith(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _feedbackTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bugReport:
        return AppColors.error;
      case FeedbackType.featureRequest:
        return AppColors.info;
      case FeedbackType.complaint:
        return Colors.orange;
      case FeedbackType.compliment:
        return AppColors.success;
      case FeedbackType.suggestion:
        return AppColors.seed;
      case FeedbackType.rating:
        return AppColors.warning;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAR RATING WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(
          starValue <= rating
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: 14,
          color: starValue <= rating ? AppColors.warning : Colors.grey,
        );
      }),
    );
  }
}
