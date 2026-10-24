import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_settings.dart';
import 'models/emergency_contact.dart';
import 'models/reminder.dart';
import 'models/walk_record.dart';
import 'screens/alerts_page.dart';
import 'screens/journey_page.dart';
import 'screens/reminders_page.dart';
import 'screens/routes_page.dart';
import 'screens/settings_page.dart';
import 'screens/walk_history_page.dart';
import 'theme.dart';
import 'widgets/app_header.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/common.dart';
import 'widgets/contacts_card.dart';
import 'widgets/feature_cards.dart';
import 'widgets/hero_banner.dart';

void main() {
  runApp(const WalcksApp());
}

/// Owns the light/dark preference so the whole app can be rebuilt in the
/// chosen palette.
class WalcksApp extends StatefulWidget {
  const WalcksApp({super.key});

  @override
  State<WalcksApp> createState() => _WalcksAppState();
}

class _WalcksAppState extends State<WalcksApp> with WidgetsBindingObserver {
  final SettingsRepository _settingsRepository = SettingsRepository();

  WalcksThemeMode _themeMode = WalcksThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == WalcksThemeMode.system && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final AppSettings settings = await _settingsRepository.load();
      if (!mounted) return;
      setState(() => _themeMode = settings.themeMode);
    } catch (_) {
      // Keep the system default when the stored preference cannot be read.
    }
  }

  Future<void> _setThemeMode(WalcksThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      await _settingsRepository.saveThemeMode(mode);
    } catch (_) {
      // The choice still applies for this session; it just will not persist.
    }
  }

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  @override
  Widget build(BuildContext context) {
    final Brightness resolved = switch (_themeMode) {
      WalcksThemeMode.light => Brightness.light,
      WalcksThemeMode.dark => Brightness.dark,
      WalcksThemeMode.system => _platformBrightness,
    };
    WalcksColors.apply(resolved);

    return MaterialApp(
      title: 'Walcks',
      debugShowCheckedModeBanner: false,
      theme: buildWalcksTheme(WalcksPalette.light, Brightness.light),
      darkTheme: buildWalcksTheme(WalcksPalette.dark, Brightness.dark),
      themeMode: switch (_themeMode) {
        WalcksThemeMode.light => ThemeMode.light,
        WalcksThemeMode.dark => ThemeMode.dark,
        WalcksThemeMode.system => ThemeMode.system,
      },
      themeAnimationDuration: Duration.zero,
      home: DashboardShell(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

/// Responsive Walcks dashboard: fixed sidebar on desktop, compact rail on
/// tablet and a drawer on mobile. Every navigation entry and feature card is
/// wired to the feature it represents.
class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final WalcksThemeMode themeMode;
  final ValueChanged<WalcksThemeMode> onThemeModeChanged;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final ContactRepository _contactRepository = ContactRepository();
  final WalkHistoryRepository _historyRepository = WalkHistoryRepository();
  final ReminderRepository _reminderRepository = ReminderRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<EmergencyContact> _contacts = <EmergencyContact>[];
  AppSettings _settings = AppSettings();
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait<Object>([
        _contactRepository.load(),
        _settingsRepository.load(),
      ]);
      if (!mounted) return;
      setState(() {
        _contacts = (results[0] as List<EmergencyContact>)
            .take(ContactRepository.maxContacts)
            .toList();
        _settings = results[1] as AppSettings;
      });
    } catch (_) {
      if (mounted) {
        WalcksToast.show(
          context,
          'Could not load your saved Walcks data.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    await _settingsRepository.save(settings);
    if (!mounted) return;
    setState(() => _settings = settings);
  }

  Future<void> _clearContacts() async {
    await _contactRepository.save(<EmergencyContact>[]);
    if (!mounted) return;
    setState(() => _contacts = <EmergencyContact>[]);
  }

  String _normalisePhone(String phone) => phone.replaceAll(RegExp(r'\s+'), '');

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _addContact() async {
    if (_loading) {
      WalcksToast.show(
        context,
        'Please wait while contacts are loading.',
        icon: Icons.hourglass_empty_rounded,
      );
      return;
    }

    if (_contacts.length >= ContactRepository.maxContacts) {
      WalcksToast.show(
        context,
        'You can add up to ${ContactRepository.maxContacts} '
        'emergency contacts.',
        error: true,
      );
      return;
    }

    final created = await showContactForm(context);
    if (created == null || !mounted) return;

    final duplicate = _contacts.any(
      (contact) =>
          _normalisePhone(contact.phone) == _normalisePhone(created.phone),
    );
    if (duplicate) {
      WalcksToast.show(
        context,
        'This phone number is already saved.',
        error: true,
      );
      return;
    }

    final previous = List<EmergencyContact>.from(_contacts);
    setState(() => _contacts = [..._contacts, created]);

    try {
      await _contactRepository.save(_contacts);
      if (!mounted) return;
      WalcksToast.show(
        context,
        '${created.name} was added to your emergency contacts.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _contacts = previous);
      WalcksToast.show(
        context,
        'Could not save the contact. Please try again.',
        error: true,
      );
    }
  }

  Future<void> _editContact(EmergencyContact contact) async {
    final updated = await showContactForm(context, existing: contact);
    if (updated == null || !mounted) return;

    final duplicate = _contacts.any(
      (other) =>
          other.id != contact.id &&
          _normalisePhone(other.phone) == _normalisePhone(updated.phone),
    );
    if (duplicate) {
      WalcksToast.show(
        context,
        'This phone number is already saved.',
        error: true,
      );
      return;
    }

    final previous = List<EmergencyContact>.from(_contacts);
    final index = _contacts.indexWhere((item) => item.id == contact.id);
    if (index == -1) return;

    setState(() => _contacts = [
          for (int i = 0; i < _contacts.length; i++)
            if (i == index) updated else _contacts[i],
        ]);

    try {
      await _contactRepository.save(_contacts);
      if (!mounted) return;
      WalcksToast.show(context, 'Contact updated.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _contacts = previous);
      WalcksToast.show(
        context,
        'Could not update the contact.',
        error: true,
      );
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirmed = await showWalcksConfirmDialog(
      context,
      title: 'Remove contact?',
      message: '${contact.name} will be removed from your emergency contacts.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final previous = List<EmergencyContact>.from(_contacts);
    setState(() =>
        _contacts = _contacts.where((item) => item.id != contact.id).toList());

    try {
      await _contactRepository.save(_contacts);
      if (!mounted) return;
      WalcksToast.show(context, '${contact.name} was removed.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _contacts = previous);
      WalcksToast.show(
        context,
        'Could not remove the contact.',
        error: true,
      );
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    final Uri uri = Uri(scheme: 'tel', path: contact.phone);
    bool launched = false;

    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      WalcksToast.show(
        context,
        'Calling is not available here. ${contact.name}: ${contact.phone}',
        icon: Icons.call_outlined,
      );
    }
  }

  void _startWalk({String? destination}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JourneyPage(
          contacts: _contacts,
          historyRepository: _historyRepository,
          settingsRepository: _settingsRepository,
          initialDestination: destination,
        ),
      ),
    );
  }

  void _pushPage(String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: WalcksColors.background,
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFeature(int index) {
    switch (index) {
      case 0:
        // Smart Tracking opens the real monitored walk workflow.
        _startWalk();
        break;
      case 1:
        // Instant Alerts opens the alert configuration and status page.
        _pushPage(
          'Instant Alerts',
          AlertsPage(
            contacts: _contacts,
            settings: _settings,
            onSaveSettings: _saveSettings,
          ),
        );
        break;
      case 2:
        // Safe Routes opens the real routes view.
        _select(2);
        break;
      case 3:
        // Stay Connected opens the emergency contacts.
        _select(0);
        break;
    }
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 1:
        return WalkHistoryPage(
          repository: _historyRepository,
          onStartWalk: () => _startWalk(),
        );
      case 2:
        return RoutesPage(
          historyRepository: _historyRepository,
          onStartWalk: (destination) => _startWalk(destination: destination),
        );
      case 3:
        return RemindersPage(repository: _reminderRepository);
      case 4:
        return SettingsPage(
          settings: _settings,
          onSave: _saveSettings,
          historyRepository: _historyRepository,
          reminderRepository: _reminderRepository,
          onClearContacts: _clearContacts,
          contactCount: _contacts.length,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMain(BuildContext context, {required bool mobile}) {
    return SafeArea(
      child: SingleChildScrollView(
        key: ValueKey<int>(_selectedIndex),
        padding: EdgeInsets.fromLTRB(
          mobile ? 18 : 36,
          mobile ? 12 : 28,
          mobile ? 18 : 36,
          40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              displayName: _settings.displayName,
              onOpenProfile: () => _select(4),
              onOpenSettings: () => _select(4),
              leading: mobile
                  ? IconButton(
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu_rounded),
                      color: WalcksColors.navy,
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    )
                  : null,
            ),
            SizedBox(height: mobile ? 18 : 26),
            if (_selectedIndex == 0) ...[
              HeroBanner(onStartWalk: () => _startWalk()),
              const SizedBox(height: 26),
              ContactsCard(
                contacts: _contacts,
                loading: _loading,
                onAdd: _addContact,
                onEdit: _editContact,
                onDelete: _deleteContact,
                onCall: _callContact,
              ),
              const SizedBox(height: 26),
              FeatureCards(onSelected: _openFeature),
            ] else
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _pageForIndex(_selectedIndex),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool mobile = width < 820;
        final bool tablet = width >= 820 && width < 1180;

        if (mobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: WalcksColors.background,
            drawer: Drawer(
              width: 310,
              backgroundColor: WalcksColors.sidebar,
              child: AppSidebar(
                selectedIndex: _selectedIndex,
                onSelect: (index) {
                  Navigator.of(context).pop();
                  _select(index);
                },
              ),
            ),
            body: _buildMain(context, mobile: true),
          );
        }

        return Scaffold(
          backgroundColor: WalcksColors.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSidebar(
                selectedIndex: _selectedIndex,
                onSelect: _select,
                compact: tablet,
              ),
              Expanded(child: _buildMain(context, mobile: false)),
            ],
          ),
        );
      },
    );
  }
}
