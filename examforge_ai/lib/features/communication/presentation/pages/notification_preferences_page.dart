import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/notification_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// NOTIFICATION PREFERENCES PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Per-category notification preference toggles.
///
/// Features:
/// - Per-category toggle grid (message, assignment, exam, result,
///   attendance, announcement, system, payment)
/// - Each category has 4 channel toggles: In-App, Push, Email, SMS
/// - Quiet hours toggle with time pickers
/// - Digest settings (daily/weekly)
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() => _State();
}

class _State extends ConsumerState<NotificationPreferencesPage> {
  // ─── State ──────────────────────────────────────────────────────────

  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);
  String _digestFrequency = 'daily';
  bool _digestEnabled = false;

  /// Per-category channel toggles: category → {channel → enabled}
  late final Map<String, Map<String, bool>> _toggles;

  static const _categories = [
    _PrefCategory(key: 'message', label: 'Messages', icon: Icons.chat_outlined),
    _PrefCategory(key: 'assignment', label: 'Assignments', icon: Icons.assignment_outlined),
    _PrefCategory(key: 'exam', label: 'Exams', icon: Icons.quiz_outlined),
    _PrefCategory(key: 'result', label: 'Results', icon: Icons.bar_chart_outlined),
    _PrefCategory(key: 'attendance', label: 'Attendance', icon: Icons.calendar_today_outlined),
    _PrefCategory(key: 'announcement', label: 'Announcements', icon: Icons.campaign_outlined),
    _PrefCategory(key: 'system', label: 'System', icon: Icons.info_outline),
    _PrefCategory(key: 'payment', label: 'Payments', icon: Icons.payment_outlined),
  ];

  static const _channels = ['inApp', 'push', 'email', 'sms'];
  static const _channelLabels = ['In-App', 'Push', 'Email', 'SMS'];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _toggles = {
      for (final cat in _categories)
        cat.key: {for (final ch in _channels) ch: true},
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadPreferences();
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    // Apply loaded preferences
    if (state.preferences != null && !_applied) {
      _applyPreferences(state.preferences!);
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Notification Preferences',
        actions: [
          TextButton(
            onPressed: () => _savePreferences(),
            child: Text(
              'Save',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading && state.preferences == null
          ? const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : state.error != null && state.preferences == null
              ? AppErrorState.genericError(
                  message: state.error,
                  onRetry: () => ref.read(notificationProvider.notifier).loadPreferences(),
                )
              : _buildBody(),
    );
  }

  bool _applied = false;

  void _applyPreferences(NotificationPreferencesEntity prefs) {
    _applied = true;
    final prefMap = prefs.preferences;
    for (final cat in _categories) {
      if (prefMap[cat.key] is Map) {
        final catPrefs = prefMap[cat.key] as Map;
        for (final ch in _channels) {
          if (catPrefs[ch] is bool) {
            _toggles[cat.key]![ch] = catPrefs[ch] as bool;
          }
        }
      }
    }
    setState(() {
      _quietHoursEnabled = prefs.quietHoursEnabled;
      _digestEnabled = prefs.digestEnabled;
      _digestFrequency = prefs.digestFrequency;
      _quietStart = _parseTimeOfDay(prefs.quietHoursStart);
      _quietEnd = _parseTimeOfDay(prefs.quietHoursEnd);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Category Toggles Grid ─────────────────────────────
          _buildSectionTitle('Notification Channels'),
          const SizedBox(height: Spacings.md),
          _buildChannelHeader(),
          const SizedBox(height: Spacings.sm),
          ..._categories.map((cat) => _buildCategoryRow(cat)),
          const SizedBox(height: Spacings.xxl),

          // ─── Quiet Hours ───────────────────────────────────────
          _buildSectionTitle('Quiet Hours'),
          const SizedBox(height: Spacings.md),
          _buildQuietHours(),
          const SizedBox(height: Spacings.xxl),

          // ─── Digest Settings ───────────────────────────────────
          _buildSectionTitle('Digest'),
          const SizedBox(height: Spacings.md),
          _buildDigestSettings(),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CATEGORY TOGGLES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Text(
      title,
      style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
    );
  }

  Widget _buildChannelHeader() {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Row(
        children: _channelLabels.map((l) => Expanded(
          child: Center(
            child: Text(l, style: tt.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCategoryRow(_PrefCategory cat) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacings.xs),
      child: Row(
        children: [
          // Icon + Label
          SizedBox(
            width: 56,
            child: Row(
              children: [
                Icon(cat.icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          Expanded(
            child: Text(cat.label, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
          ),
          // Channel toggles
          ..._channels.map((ch) => Expanded(
            child: Center(
              child: Switch(
                value: _toggles[cat.key]![ch]!,
                onChanged: (v) => setState(() => _toggles[cat.key]![ch] = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUIET HOURS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuietHours() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Enable Quiet Hours', style: tt.bodyMedium?.copyWith(color: cs.onSurface))),
                Switch(value: _quietHoursEnabled, onChanged: (v) => setState(() => _quietHoursEnabled = v)),
              ],
            ),
            if (_quietHoursEnabled) ...[
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Start',
                      time: _quietStart,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: Spacings.lg),
                  Expanded(
                    child: _buildTimePicker(
                      label: 'End',
                      time: _quietEnd,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: Spacings.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.md),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: Spacings.xs),
            Text(
              time.format(context),
              style: tt.titleMedium?.copyWith(fontWeight: AppTypography.wSemiBold, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DIGEST SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDigestSettings() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: Spacings.elevationNone,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
      child: Padding(
        padding: Spacings.paddingCard,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Enable Digest', style: tt.bodyMedium?.copyWith(color: cs.onSurface))),
                Switch(value: _digestEnabled, onChanged: (v) => setState(() => _digestEnabled = v)),
              ],
            ),
            if (_digestEnabled) ...[
              const SizedBox(height: Spacings.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ],
                selected: {_digestFrequency},
                onSelectionChanged: (s) => setState(() => _digestFrequency = s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  void _savePreferences() {
    final prefs = <String, dynamic>{
      for (final cat in _categories) cat.key: Map<String, bool>.from(_toggles[cat.key]!),
    };
    prefs['quietHoursEnabled'] = _quietHoursEnabled;
    prefs['quietHoursStart'] = '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}';
    prefs['quietHoursEnd'] = '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}';
    prefs['digestEnabled'] = _digestEnabled;
    prefs['digestFrequency'] = _digestFrequency;

    ref.read(notificationProvider.notifier).updatePreferences(prefs);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0);
    }
    return const TimeOfDay(hour: 22, minute: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _PrefCategory {
  const _PrefCategory({required this.key, required this.label, required this.icon});
  final String key;
  final String label;
  final IconData icon;
}
