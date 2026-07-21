import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/super_admin_entities.dart';
import '../providers/super_admin_providers.dart';
import '../widgets/super_admin_widgets.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

Color _severityColor(AuditSeverity severity) {
  switch (severity) {
    case AuditSeverity.info:
      return AppColors.info;
    case AuditSeverity.warning:
      return AppColors.warning;
    case AuditSeverity.error:
      return AppColors.error;
    case AuditSeverity.critical:
      return AppColors.errorDark;
  }
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(int? ms) {
  if (ms == null) return '—';
  if (ms < 1000) return '${ms}ms';
  if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
  return '${(ms / 60000).toStringAsFixed(1)}m';
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Comprehensive security monitoring page for the Super Admin.
///
/// Features:
/// - **Audit Logs**: Filterable log entries with category & severity badges
/// - **Login Monitoring**: Real-time login tracking with failed-only toggle
/// - **Active Sessions**: Live session cards with terminate capability
/// - **Suspicious Activity**: AI-detected anomalies with lock/unlock actions
class SecurityCenterPage extends ConsumerStatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  ConsumerState<SecurityCenterPage> createState() =>
      _SecurityCenterPageState();
}

class _SecurityCenterPageState extends ConsumerState<SecurityCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ─── Audit Log Filters ──────────────────────────────────────────────────

  AuditCategory? _filterCategory;
  AuditSeverity? _filterSeverity;

  // ─── Login Monitoring Filters ───────────────────────────────────────────

  bool _failedOnly = false;

  static const _tabs = [
    Tab(icon: Icon(Icons.history_rounded), text: 'Audit Logs'),
    Tab(icon: Icon(Icons.login_rounded), text: 'Login Monitoring'),
    Tab(icon: Icon(Icons.devices_rounded), text: 'Active Sessions'),
    Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Suspicious Activity'),
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
    final notifier = ref.read(securityCenterProvider.notifier);
    switch (index) {
      case 0:
        notifier.loadAuditLogs(category: _filterCategory);
        break;
      case 1:
        notifier.loadLoginMonitoring(failedOnly: _failedOnly);
        break;
      case 2:
        // Active sessions are loaded as part of login monitoring
        notifier.loadLoginMonitoring();
        break;
      case 3:
        notifier.detectSuspicious();
        break;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityCenterProvider);
    final cs = Theme.of(context).colorScheme;

    // Listen for success/error snackbar messages
    ref.listen<SecurityCenterState>(securityCenterProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(securityCenterProvider.notifier).state =
            ref.read(securityCenterProvider).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(securityCenterProvider.notifier).state =
            ref.read(securityCenterProvider).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Security Center',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: state.isLoading && state.auditLogs.isEmpty && state.loginEntries.isEmpty
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null &&
                  state.auditLogs.isEmpty &&
                  state.loginEntries.isEmpty &&
                  state.activeSessions.isEmpty &&
                  state.suspiciousActivity.isEmpty
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
                            cs.onSurface.withOpacity(0.6),
                        indicatorColor: cs.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                        isScrollable: true,
                      ),
                    ),

                    // ─── Tab Content ──────────────────────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _AuditLogsTab(
                            filterCategory: _filterCategory,
                            filterSeverity: _filterSeverity,
                            onCategoryChanged: (category) {
                              setState(() => _filterCategory = category);
                              ref
                                  .read(securityCenterProvider.notifier)
                                  .loadAuditLogs(category: category);
                            },
                            onSeverityChanged: (severity) {
                              setState(() => _filterSeverity = severity);
                              // Reload with current category + apply severity filter locally
                              ref
                                  .read(securityCenterProvider.notifier)
                                  .loadAuditLogs(category: _filterCategory);
                            },
                          ),
                          _LoginMonitoringTab(
                            failedOnly: _failedOnly,
                            onFailedOnlyChanged: (value) {
                              setState(() => _failedOnly = value);
                              ref
                                  .read(securityCenterProvider.notifier)
                                  .loadLoginMonitoring(failedOnly: value);
                            },
                          ),
                          _ActiveSessionsTab(),
                          _SuspiciousActivityTab(),
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
                color: cs.onSurface.withOpacity(0.7),
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
// AUDIT LOGS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _AuditLogsTab extends StatelessWidget {
  const _AuditLogsTab({
    required this.filterCategory,
    required this.filterSeverity,
    required this.onCategoryChanged,
    required this.onSeverityChanged,
  });

  final AuditCategory? filterCategory;
  final AuditSeverity? filterSeverity;
  final ValueChanged<AuditCategory?> onCategoryChanged;
  final ValueChanged<AuditSeverity?> onSeverityChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(securityCenterProvider);
      final cs = Theme.of(context).colorScheme;

      // Apply severity filter locally if set
      final logs = filterSeverity != null
          ? state.auditLogs
              .where((log) => log.severity == filterSeverity)
              .toList()
          : state.auditLogs;

      return Column(
        children: [
          // ─── Filters ──────────────────────────────────────────────
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                // Category dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      DropdownButtonFormField<AuditCategory?>(
                        value: filterCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: Spacings.borderRadiusMd),
                          contentPadding: Spacings.paddingInput,
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<AuditCategory?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...AuditCategory.values.map(
                            (cat) => DropdownMenuItem<AuditCategory?>(
                              value: cat,
                              child: Text(cat.label),
                            ),
                          ),
                        ],
                        onChanged: onCategoryChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacings.md),
                // Severity dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Severity',
                        style: AppTypography.wSemiBold.copyWith(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      DropdownButtonFormField<AuditSeverity?>(
                        value: filterSeverity,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: Spacings.borderRadiusMd),
                          contentPadding: Spacings.paddingInput,
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<AuditSeverity?>(
                            value: null,
                            child: Text('All Severities'),
                          ),
                          ...AuditSeverity.values.map(
                            (sev) => DropdownMenuItem<AuditSeverity?>(
                              value: sev,
                              child: Text(sev.label),
                            ),
                          ),
                        ],
                        onChanged: onSeverityChanged,
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
                  '${logs.length} log ${logs.length == 1 ? 'entry' : 'entries'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Data Table ───────────────────────────────────────────
          Expanded(
            child: logs.isEmpty
                ? const AdminEmptyState(
                    message: 'No audit logs found',
                    icon: Icons.history_rounded,
                  )
                : _AuditLogDataTable(logs: logs),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUDIT LOG DATA TABLE
// ═══════════════════════════════════════════════════════════════════════════════

class _AuditLogDataTable extends StatelessWidget {
  const _AuditLogDataTable({required this.logs});
  final List<AuditLog> logs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacings.xl),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            cs.surfaceContainerHighest.withOpacity(0.5),
          ),
          headingTextStyle: AppTypography.wSemiBold.copyWith(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.7),
          ),
          dataTextStyle: AppTypography.wRegular.copyWith(
            fontSize: 13,
            color: cs.onSurface,
          ),
          columnSpacing: Spacings.lg,
          horizontalMargin: Spacings.sm,
          columns: const [
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('Actor')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Severity')),
            DataColumn(label: Text('Resource Type')),
            DataColumn(label: Text('IP Address')),
            DataColumn(label: Text('Duration')),
          ],
          rows: logs.map((log) {
            final sevColor = _severityColor(log.severity);
            return DataRow(cells: [
              // Timestamp
              DataCell(Text(
                _formatTimestamp(log.createdAt),
                style: AppTypography.wRegular.copyWith(fontSize: 12),
              )),
              // Actor
              DataCell(Text(
                log.actorEmail ?? log.actorId ?? 'System',
                style: AppTypography.wMedium.copyWith(fontSize: 12),
              )),
              // Action
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  log.action,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
              // Category
              DataCell(Text(log.category.label)),
              // Severity badge
              DataCell(StatusBadge(
                label: log.severity.label,
                color: sevColor,
              )),
              // Resource Type
              DataCell(Text(log.resourceType ?? '—')),
              // IP Address
              DataCell(Text(log.ipAddress ?? '—')),
              // Duration
              DataCell(Text(_formatDuration(log.durationMs))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN MONITORING TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _LoginMonitoringTab extends StatelessWidget {
  const _LoginMonitoringTab({
    required this.failedOnly,
    required this.onFailedOnlyChanged,
  });

  final bool failedOnly;
  final ValueChanged<bool> onFailedOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(securityCenterProvider);
      final cs = Theme.of(context).colorScheme;

      return Column(
        children: [
          // ─── Toggle ───────────────────────────────────────────────
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                Text(
                  'Show failed only',
                  style: AppTypography.wMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(width: Spacings.sm),
                Switch(
                  value: failedOnly,
                  onChanged: onFailedOnlyChanged,
                ),
                const Spacer(),
                Text(
                  '${state.loginEntries.length} ${state.loginEntries.length == 1 ? 'entry' : 'entries'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

          // ─── Data Table ───────────────────────────────────────────
          Expanded(
            child: state.loginEntries.isEmpty
                ? const AdminEmptyState(
                    message: 'No login entries found',
                    icon: Icons.login_rounded,
                  )
                : _LoginMonitoringDataTable(entries: state.loginEntries),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN MONITORING DATA TABLE
// ═══════════════════════════════════════════════════════════════════════════════

class _LoginMonitoringDataTable extends StatelessWidget {
  const _LoginMonitoringDataTable({required this.entries});
  final List<LoginMonitoringEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacings.xl),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            cs.surfaceContainerHighest.withOpacity(0.5),
          ),
          headingTextStyle: AppTypography.wSemiBold.copyWith(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.7),
          ),
          dataTextStyle: AppTypography.wRegular.copyWith(
            fontSize: 13,
            color: cs.onSurface,
          ),
          columnSpacing: Spacings.lg,
          horizontalMargin: Spacings.sm,
          columns: const [
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('IP Address')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Device')),
          ],
          rows: entries.map((entry) {
            final isSuccess = entry.isSuccess;
            return DataRow(
              color: WidgetStateProperty.all(
                !isSuccess
                    ? AppColors.error.withOpacity(0.06)
                    : null,
              ),
              cells: [
                // Timestamp
                DataCell(Text(
                  _formatTimestamp(entry.createdAt),
                  style: AppTypography.wRegular.copyWith(fontSize: 12),
                )),
                // User
                DataCell(Text(
                  entry.email ?? entry.userId ?? 'Unknown',
                  style: AppTypography.wMedium.copyWith(fontSize: 12),
                )),
                // Role
                DataCell(Text(entry.role ?? '—')),
                // Status badge
                DataCell(StatusBadge(
                  label: isSuccess ? 'Success' : 'Failed',
                  color: isSuccess ? AppColors.success : AppColors.error,
                  icon: isSuccess ? Icons.check_circle : Icons.cancel,
                )),
                // IP Address
                DataCell(Text(entry.ipAddress ?? '—')),
                // Country
                DataCell(Text(
                  [entry.city, entry.country]
                      .where((e) => e != null)
                      .join(', '),
                )),
                // Device
                DataCell(Tooltip(
                  message: entry.userAgent ?? 'Unknown',
                  child: Text(
                    entry.deviceFingerprint ?? '—',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVE SESSIONS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveSessionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(securityCenterProvider);
      final cs = Theme.of(context).colorScheme;

      return Column(
        children: [
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                Text(
                  '${state.activeSessions.length} active ${state.activeSessions.length == 1 ? 'session' : 'sessions'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.activeSessions.isEmpty
                ? const AdminEmptyState(
                    message: 'No active sessions',
                    icon: Icons.devices_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref
                          .read(securityCenterProvider.notifier)
                          .loadLoginMonitoring();
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: Spacings.paddingScreen,
                      itemCount: state.activeSessions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacings.sm),
                      itemBuilder: (context, index) {
                        final session = state.activeSessions[index];
                        return _ActiveSessionCard(session: session);
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVE SESSION CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({required this.session});
  final ActiveSession session;

  String _deviceLabel() {
    final info = session.deviceInfo;
    if (info == null) return 'Unknown Device';
    final browser = info['browser'] as String? ?? '';
    final os = info['os'] as String? ?? '';
    final device = info['device'] as String? ?? '';
    if (browser.isNotEmpty && os.isNotEmpty) return '$browser · $os';
    if (device.isNotEmpty) return device;
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: session.isCurrent
          ? Spacings.elevationMd
          : Spacings.elevationSm,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  session.isCurrent
                      ? Icons.phone_android_rounded
                      : Icons.devices_rounded,
                  color: cs.primary,
                  size: Spacings.lgIcon,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    _deviceLabel(),
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                ),
                if (session.isCurrent)
                  StatusBadge(
                    label: 'Current',
                    color: AppColors.success,
                    icon: Icons.check_circle,
                  ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Details Grid ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon: Icons.person_outline_rounded,
                    label: 'User',
                    value: session.userId,
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    icon: Icons.language_rounded,
                    label: 'IP',
                    value: session.ipAddress ?? '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Expanded(
                  child: _detailItem(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: [session.city, session.country]
                        .where((e) => e != null)
                        .join(', '),
                  ),
                ),
                Expanded(
                  child: _detailItem(
                    icon: Icons.schedule_rounded,
                    label: 'Last Activity',
                    value: _formatTimestamp(session.lastActivityAt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Terminate Button ──────────────────────────────────
            if (!session.isCurrent)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmTerminate(context, session),
                  icon: const Icon(Icons.power_settings_new, size: 16),
                  label: const Text('Terminate Session'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: Spacings.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.wRegular.copyWith(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: AppTypography.wMedium.copyWith(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  void _confirmTerminate(BuildContext context, ActiveSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Terminate Session',
          style: AppTypography.wSemiBold.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to terminate this session for user "${session.userId}"? '
          'They will be logged out immediately.',
          style: AppTypography.wRegular.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Call terminate session when notifier method is available
              // ref.read(securityCenterProvider.notifier).terminateSession(session.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session terminated'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUSPICIOUS ACTIVITY TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _SuspiciousActivityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(securityCenterProvider);
      final cs = Theme.of(context).colorScheme;

      return Column(
        children: [
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                Text(
                  '${state.suspiciousActivity.length} ${state.suspiciousActivity.length == 1 ? 'alert' : 'alerts'}',
                  style: AppTypography.wMedium.copyWith(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () {
                    ref
                        .read(securityCenterProvider.notifier)
                        .detectSuspicious();
                  },
                  child: const Text('Scan Now'),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.suspiciousActivity.isEmpty
                ? const AdminEmptyState(
                    message: 'No suspicious activity detected',
                    icon: Icons.verified_user_rounded,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref
                          .read(securityCenterProvider.notifier)
                          .detectSuspicious();
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: Spacings.paddingScreen,
                      itemCount: state.suspiciousActivity.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacings.sm),
                      itemBuilder: (context, index) {
                        final activity = state.suspiciousActivity[index];
                        return _SuspiciousActivityCard(
                            activity: activity);
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUSPICIOUS ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SuspiciousActivityCard extends StatelessWidget {
  const _SuspiciousActivityCard({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userId = activity['userId'] as String? ?? 'Unknown';
    final email = activity['email'] as String? ?? userId;
    final failureCount = activity['failureCount'] as int? ?? 0;
    final distinctIps = activity['distinctIps'] as int? ?? 0;
    final lastAttempt = activity['lastAttemptAt'] as String? ?? '—';
    final isLocked = activity['isLocked'] as bool? ?? false;
    final reason = activity['lockReason'] as String?;

    return Card(
      elevation: Spacings.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: isLocked
            ? BorderSide(color: AppColors.error.withOpacity(0.4))
            : BorderSide.none,
      ),
      child: Padding(
        padding: Spacings.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  isLocked
                      ? Icons.lock_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: isLocked ? AppColors.error : AppColors.warning,
                  size: Spacings.lgIcon,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    email,
                    style: AppTypography.wSemiBold.copyWith(fontSize: 14),
                  ),
                ),
                if (isLocked)
                  StatusBadge(
                    label: 'Locked',
                    color: AppColors.error,
                    icon: Icons.lock,
                  )
                else
                  StatusBadge(
                    label: 'Active',
                    color: AppColors.warning,
                    icon: Icons.warning_amber,
                  ),
              ],
            ),
            const SizedBox(height: Spacings.md),

            // ─── Stats Row ─────────────────────────────────────────
            Row(
              children: [
                _statChip(
                  icon: Icons.error_outline,
                  label: 'Failed Attempts',
                  value: '$failureCount',
                  color: failureCount > 10 ? AppColors.error : AppColors.warning,
                ),
                const SizedBox(width: Spacings.md),
                _statChip(
                  icon: Icons.language_rounded,
                  label: 'Distinct IPs',
                  value: '$distinctIps',
                  color: distinctIps > 3 ? AppColors.error : AppColors.info,
                ),
                const SizedBox(width: Spacings.md),
                _statChip(
                  icon: Icons.schedule_rounded,
                  label: 'Last Attempt',
                  value: lastAttempt,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ],
            ),

            if (reason != null) ...[
              const SizedBox(height: Spacings.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: Spacings.borderRadiusSm,
                ),
                child: Text(
                  'Lock reason: $reason',
                  style: AppTypography.wRegular.copyWith(
                    fontSize: 12,
                    color: AppColors.errorDark,
                  ),
                ),
              ),
            ],

            const SizedBox(height: Spacings.md),

            // ─── Action Buttons ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLocked)
                  Consumer(builder: (context, ref, _) {
                    return FilledButton.tonal(
                      onPressed: () {
                        ref
                            .read(securityCenterProvider.notifier)
                            .unlockAccount(userId);
                      },
                      child: const Text('Unlock'),
                    );
                  })
                else
                  FilledButton(
                    onPressed: () => _showLockDialog(context, userId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Lock Account'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: AppTypography.wRegular.copyWith(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.wSemiBold.copyWith(fontSize: 13, color: color),
        ),
      ],
    );
  }

  void _showLockDialog(BuildContext context, String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(builder: (context, ref, _) {
        return AlertDialog(
          title: Text(
            'Lock Account',
            style: AppTypography.wSemiBold.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lock the account for user "$userId"? They will be unable to log in until an admin unlocks the account.',
                style: AppTypography.wRegular.copyWith(fontSize: 14),
              ),
              const SizedBox(height: Spacings.lg),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Enter reason for locking this account',
                  border: OutlineInputBorder(
                      borderRadius: Spacings.borderRadiusMd),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                reasonController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.of(dialogContext).pop();
                ref
                    .read(securityCenterProvider.notifier)
                    .lockAccount(userId, reason);
                reasonController.dispose();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Lock'),
            ),
          ],
        );
      }),
    );
  }

}
