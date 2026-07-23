import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/create_calendar_event_usecase.dart';
import '../providers/calendar_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE EVENT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form to create calendar event.
///
/// Fields: title, description, type dropdown, start/end date-time pickers,
/// all-day toggle, location, meeting link, attendee selector, RSVP toggle.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({super.key});

  @override
  ConsumerState<CreateEventPage> createState() => _State();
}

class _State extends ConsumerState<CreateEventPage> {
  // ─── Controllers ────────────────────────────────────────────────────

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  // ─── State ──────────────────────────────────────────────────────────

  CalendarEventType _eventType = CalendarEventType.custom;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isAllDay = false;
  bool _rsvpRequired = false;
  final _formKey = GlobalKey<FormState>();

  static const _eventTypes = CalendarEventType.values;

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Create Event',
        actions: [
          TextButton(
            onPressed: state.isCreating ? null : _save,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Title ────────────────────────────────────────
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: Spacings.lg),

                  // ─── Description ──────────────────────────────────
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: Spacings.lg),

                  // ─── Event Type ───────────────────────────────────
                  _buildSectionLabel('Event Type'),
                  const SizedBox(height: Spacings.sm),
                  DropdownButtonFormField<CalendarEventType>(
                    initialValue: _eventType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setState(() => _eventType = v ?? CalendarEventType.custom),
                  ),
                  const SizedBox(height: Spacings.lg),

                  // ─── All Day Toggle ───────────────────────────────
                  SwitchListTile(
                    title: Text('All Day', style: Theme.of(context).textTheme.bodyMedium),
                    value: _isAllDay,
                    onChanged: (v) => setState(() => _isAllDay = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: Spacings.md),

                  // ─── Start Date/Time ──────────────────────────────
                  _buildSectionLabel('Start'),
                  const SizedBox(height: Spacings.sm),
                  _buildDateTimeRow(isStart: true),
                  const SizedBox(height: Spacings.lg),

                  // ─── End Date/Time ────────────────────────────────
                  _buildSectionLabel('End'),
                  const SizedBox(height: Spacings.sm),
                  _buildDateTimeRow(isStart: false),
                  const SizedBox(height: Spacings.lg),

                  // ─── Location ─────────────────────────────────────
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),

                  // ─── Meeting Link ─────────────────────────────────
                  TextFormField(
                    controller: _meetingLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Link',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.videocam_outlined),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: Spacings.lg),

                  // ─── RSVP Toggle ──────────────────────────────────
                  SwitchListTile(
                    title: Text('RSVP Required', style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text('Attendees must confirm their attendance', style: Theme.of(context).textTheme.bodySmall),
                    value: _rsvpRequired,
                    onChanged: (v) => setState(() => _rsvpRequired = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: Spacings.xl),

                  // ─── Buttons ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.isCreating ? null : _save,
                          child: state.isCreating
                              ? const SizedBox(width: 20, height: 20, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small))
                              : const Text('Create Event'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.isCreating)
            const AppLoadingOverlay(message: 'Creating event…'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DATE/TIME ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDateTimeRow({required bool isStart}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final date = isStart ? _startDate : _endDate;
    final time = isStart ? _startTime : _endTime;

    return Row(
      children: [
        // Date picker
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(isStart: isStart),
            borderRadius: Spacings.borderRadiusMd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.md),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
                  const SizedBox(width: Spacings.sm),
                  Text('${date.day}/${date.month}/${date.year}', style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.md),
        // Time picker
        if (!_isAllDay)
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(isStart: isStart),
              borderRadius: Spacings.borderRadiusMd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.md),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.sm),
                    Text(time.format(context), style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PICKERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════════════════

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = DateTime(
      _startDate.year, _startDate.month, _startDate.day,
      _isAllDay ? 0 : _startTime.hour, _isAllDay ? 0 : _startTime.minute,
    );
    final endDateTime = DateTime(
      _endDate.year, _endDate.month, _endDate.day,
      _isAllDay ? 23 : _endTime.hour, _isAllDay ? 59 : _endTime.minute,
    );

    ref.read(calendarProvider.notifier).createEvent(
      CreateCalendarEventParams(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventType: _eventType,
        startTime: startDateTime,
        endTime: endDateTime,
        isAllDay: _isAllDay,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        meetingLink: _meetingLinkController.text.trim().isEmpty ? null : _meetingLinkController.text.trim(),
        rsvpRequired: _rsvpRequired,
      ),
    );

    Navigator.of(context).pop();
  }
}
