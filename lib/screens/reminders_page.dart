import 'package:flutter/material.dart';

import '../models/reminder.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Safety reminders saved on the device. Walcks stores and manages them for
/// real, but this build does not deliver device notifications, so the
/// limitation is stated plainly.
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key, required this.repository});

  final ReminderRepository repository;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<SafetyReminder> _reminders = <SafetyReminder>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reminders = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      WalcksToast.show(context, 'Could not load your reminders.', error: true);
    }
  }

  Future<void> _persist(List<SafetyReminder> next) async {
    final previous = List<SafetyReminder>.from(_reminders);
    setState(() => _reminders = next);
    try {
      await widget.repository.save(next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reminders = previous);
      WalcksToast.show(context, 'Could not save your reminders.', error: true);
    }
  }

  Future<void> _add() async {
    final created = await showDialog<SafetyReminder>(
      context: context,
      builder: (_) => const _ReminderDialog(),
    );
    if (created == null || !mounted) return;

    await _persist(<SafetyReminder>[..._reminders, created]);
    if (!mounted) return;
    WalcksToast.show(context, 'Reminder saved.');
  }

  Future<void> _edit(SafetyReminder reminder) async {
    final updated = await showDialog<SafetyReminder>(
      context: context,
      builder: (_) => _ReminderDialog(existing: reminder),
    );
    if (updated == null || !mounted) return;

    await _persist(<SafetyReminder>[
      for (final item in _reminders)
        if (item.id == reminder.id) updated else item,
    ]);
    if (!mounted) return;
    WalcksToast.show(context, 'Reminder updated.');
  }

  Future<void> _delete(SafetyReminder reminder) async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Delete reminder?',
      message: '"${reminder.title}" will be removed from this device.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _persist(_reminders.where((item) => item.id != reminder.id).toList());
    if (!mounted) return;
    WalcksToast.show(context, 'Reminder deleted.');
  }

  Future<void> _toggle(SafetyReminder reminder, bool enabled) async {
    await _persist(<SafetyReminder>[
      for (final item in _reminders)
        if (item.id == reminder.id)
          SafetyReminder(
            id: item.id,
            title: item.title,
            hour: item.hour,
            minute: item.minute,
            days: item.days,
            enabled: enabled,
          )
        else
          item,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: WalcksPageHeading(
                title: 'Reminders',
                subtitle: 'Plan the safety check-ins for your walks.',
                icon: Icons.notifications_none_rounded,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        WalcksNotice(
          message:
              'Reminders are stored on this device and shown inside '
              'Walcks. This build does not schedule device notifications, so '
              'Walcks cannot alert you while the app is closed.',
          icon: Icons.notifications_off_outlined,
          accent: WalcksColors.coral,
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: _loading
              ? SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: WalcksColors.primary,
                      strokeWidth: 2.6,
                    ),
                  ),
                )
              : _reminders.isEmpty
              ? const _EmptyReminders()
              : Column(
                  children: [
                    for (int i = 0; i < _reminders.length; i++) ...[
                      if (i > 0) const Divider(height: 22),
                      _ReminderRow(
                        reminder: _reminders[i],
                        onToggle: (value) => _toggle(_reminders[i], value),
                        onEdit: () => _edit(_reminders[i]),
                        onDelete: () => _delete(_reminders[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: WalcksColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.alarm_add_rounded,
              color: WalcksColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: WalcksColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a reminder for the times you usually walk.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: WalcksColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final SafetyReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: reminder.enabled
                ? WalcksColors.lavender
                : WalcksColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            reminder.timeLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: reminder.enabled
                  ? WalcksColors.primary
                  : WalcksColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reminder.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: WalcksColors.textMain,
                ),
              ),
              const SizedBox(height: 3),
              Text(reminder.daysLabel, style: WalcksText.small),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit reminder',
          onPressed: onEdit,
          icon: Icon(
            Icons.edit_outlined,
            size: 19,
            color: WalcksColors.primary,
          ),
        ),
        IconButton(
          tooltip: 'Delete reminder',
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 19,
            color: WalcksColors.coral,
          ),
        ),
        Switch(
          value: reminder.enabled,
          onChanged: onToggle,
          activeThumbColor: WalcksColors.primary,
        ),
      ],
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({this.existing});

  final SafetyReminder? existing;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late final TextEditingController _title;
  late TimeOfDay _time;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _time = TimeOfDay(hour: existing?.hour ?? 7, minute: existing?.minute ?? 0);
    _days = {...(existing?.days ?? const <int>[])};
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final String text = _title.text.trim();
    if (text.isEmpty) {
      WalcksToast.show(context, 'Please name your reminder.', error: true);
      return;
    }

    Navigator.of(context).pop(
      SafetyReminder(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: text,
        hour: _time.hour,
        minute: _time.minute,
        days: _days.toList()..sort(),
        enabled: widget.existing?.enabled ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> dayLabels = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.existing == null ? 'Add Reminder' : 'Edit Reminder',
        style: WalcksText.sectionTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reminder',
                hintText: 'e.g. Time for my evening walk',
                prefixIcon: Icon(Icons.alarm_rounded),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded, size: 20),
              label: Text('Time: ${_time.format(context)}'),
            ),
            const SizedBox(height: 18),
            Text(
              'Repeat on (leave empty for every day)',
              style: WalcksText.small,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(dayLabels[day - 1]),
                    selected: _days.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _days.add(day);
                      } else {
                        _days.remove(day);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.existing == null ? 'Save reminder' : 'Save changes',
          ),
        ),
      ],
    );
  }
}
