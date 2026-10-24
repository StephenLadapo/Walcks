import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/reminder.dart';
import '../models/walk_record.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Settings for the profile stored on this device, the walk preferences that
/// really affect behaviour, and the local data the user can manage.
/// Walcks has no account system, so there is no sign-in or sign-out here.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onSave,
    required this.historyRepository,
    required this.reminderRepository,
    required this.onClearContacts,
    required this.contactCount,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings settings) onSave;
  final WalkHistoryRepository historyRepository;
  final ReminderRepository reminderRepository;
  final Future<void> Function() onClearContacts;
  final int contactCount;
  final WalcksThemeMode themeMode;
  final ValueChanged<WalcksThemeMode> onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name;
  bool _savingName = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.displayName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final String value = _name.text.trim();
    if (value.isEmpty) {
      WalcksToast.show(context, 'Please enter a display name.', error: true);
      return;
    }

    setState(() => _savingName = true);
    try {
      await widget.onSave(widget.settings.copyWith(displayName: value));
      if (!mounted) return;
      WalcksToast.show(context, 'Profile name saved.');
    } catch (_) {
      if (!mounted) return;
      WalcksToast.show(context, 'Could not save your name.', error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _setNotify(bool value) async {
    try {
      await widget.onSave(
        widget.settings.copyWith(notifyContactsOnStart: value),
      );
    } catch (_) {
      if (!mounted) return;
      WalcksToast.show(context, 'Could not save the preference.', error: true);
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Clear walk history?',
      message: 'All saved walk records will be permanently removed from this '
          'device.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(widget.historyRepository.clear, 'Walk history cleared.');
  }

  Future<void> _clearReminders() async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Clear reminders?',
      message: 'All reminders will be permanently removed from this device.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(widget.reminderRepository.clear, 'Reminders cleared.');
  }

  Future<void> _deleteEverything() async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Delete all app data?',
      message: 'Your emergency contacts, walk history and reminders will be '
          'permanently removed from this device. This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await _run(() async {
      await widget.historyRepository.clear();
      await widget.reminderRepository.clear();
      await widget.onClearContacts();
    }, 'All Walcks data was deleted from this device.');
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      WalcksToast.show(context, success);
    } catch (_) {
      if (!mounted) return;
      WalcksToast.show(context, 'That action failed. Please try again.',
          error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WalcksPageHeading(
          title: 'Settings',
          subtitle: 'Your profile and local Walcks preferences.',
          icon: Icons.settings_rounded,
        ),
        const SizedBox(height: 22),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profile', style: WalcksText.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Walcks stores everything on this device. There is no online '
                'account, so this name is only used inside the app.',
                style: WalcksText.small,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _savingName ? null : _saveName,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_savingName ? 'Saving...' : 'Save profile'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Appearance', style: WalcksText.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Choose how Walcks looks. System follows your device theme.',
                style: WalcksText.small,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<WalcksThemeMode>(
                  segments: const [
                    ButtonSegment<WalcksThemeMode>(
                      value: WalcksThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System'),
                    ),
                    ButtonSegment<WalcksThemeMode>(
                      value: WalcksThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    ButtonSegment<WalcksThemeMode>(
                      value: WalcksThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: <WalcksThemeMode>{widget.themeMode},
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: WalcksColors.card,
                    foregroundColor: WalcksColors.textSecondary,
                    selectedBackgroundColor: WalcksColors.lavender,
                    selectedForegroundColor: WalcksColors.primary,
                    side: BorderSide(color: WalcksColors.border),
                  ),
                  onSelectionChanged: (selection) =>
                      widget.onThemeModeChanged(selection.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Walk preferences', style: WalcksText.cardTitle),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: widget.settings.notifyContactsOnStart,
                  onChanged: _busy ? null : _setNotify,
                  activeThumbColor: WalcksColors.primary,
                  title: Text(
                    'Notify contacts when a walk starts',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: WalcksColors.textMain,
                    ),
                  ),
                  subtitle: Text(
                    'Walcks will attempt to send your alert message when a '
                    'monitored walk begins.',
                    style: WalcksText.small,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Your data', style: WalcksText.cardTitle),
              const SizedBox(height: 4),
              Text(
                '${widget.contactCount} emergency '
                '${widget.contactCount == 1 ? 'contact' : 'contacts'} saved on '
                'this device.',
                style: WalcksText.small,
              ),
              const SizedBox(height: 16),
              _DataAction(
                icon: Icons.history_rounded,
                label: 'Clear walk history',
                onPressed: _busy ? null : _clearHistory,
              ),
              const SizedBox(height: 10),
              _DataAction(
                icon: Icons.notifications_none_rounded,
                label: 'Clear reminders',
                onPressed: _busy ? null : _clearReminders,
              ),
              const SizedBox(height: 10),
              _DataAction(
                icon: Icons.delete_forever_rounded,
                label: 'Delete all app data',
                destructive: true,
                onPressed: _busy ? null : _deleteEverything,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('About Walcks', style: WalcksText.cardTitle),
              SizedBox(height: 12),
              _AboutRow(
                icon: Icons.verified_outlined,
                text: 'Working in this build: emergency contacts, monitored '
                    'walks with live GPS tracking, walk history, reminders, '
                    'routes and these settings.',
              ),
              SizedBox(height: 10),
              _AboutRow(
                icon: Icons.build_outlined,
                text: 'Needs extra setup: automatic SMS alerts (native '
                    '"walcks/sms" bridge), device notifications for reminders, '
                    'and destination lookup on the web.',
              ),
              SizedBox(height: 10),
              _AboutRow(
                icon: Icons.lock_outline_rounded,
                text: 'All data is stored only on this device. Walcks has no '
                    'server, so nothing is uploaded.',
              ),
              SizedBox(height: 10),
              _AboutRow(
                icon: Icons.info_outline_rounded,
                text: 'Walcks version 1.0.0',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final Color color =
        destructive ? WalcksColors.coral : WalcksColors.textMain;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        alignment: Alignment.centerLeft,
        foregroundColor: color,
        side: BorderSide(
          color: destructive
              ? WalcksColors.coral.withValues(alpha: 0.4)
              : WalcksColors.border,
        ),
      ),
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: WalcksColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: WalcksText.body)),
      ],
    );
  }
}
