import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safety_app/main.dart';
import 'package:safety_app/models/app_settings.dart';
import 'package:safety_app/models/emergency_contact.dart';
import 'package:safety_app/models/walk_record.dart';

/// The geolocator plugin has no native host in the test environment, so the
/// Routes page is driven through its real "location services are off" path.
const MethodChannel _geolocatorChannel =
    MethodChannel('flutter.baseflow.com/geolocator');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, (MethodCall call) async {
      if (call.method == 'isLocationServiceEnabled') return false;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocatorChannel, null);
  });

  test('walk history repository saves, loads and clears records', () async {
    final repository = WalkHistoryRepository();

    expect(await repository.load(), isEmpty);

    await repository.add(
      WalkRecord(
        id: 'walk-1',
        startTime: DateTime(2026, 10, 17, 8),
        endTime: DateTime(2026, 10, 17, 8, 30),
        destination: 'Public Library',
        startLabel: '-26.204100, 28.047300',
        gpsUpdates: 12,
      ),
    );

    final loaded = await repository.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.destination, 'Public Library');
    expect(loaded.first.duration.inMinutes, 30);
    expect(loaded.first.outcome, WalkOutcome.stopped);

    await repository.clear();
    expect(await repository.load(), isEmpty);
  });

  test('settings repository round-trips the stored profile', () async {
    final repository = SettingsRepository();

    final defaults = await repository.load();
    expect(defaults.displayName, 'User');
    expect(defaults.notifyContactsOnStart, isTrue);

    await repository.save(
      defaults.copyWith(displayName: 'Sanele', notifyContactsOnStart: false),
    );

    final loaded = await repository.load();
    expect(loaded.displayName, 'Sanele');
    expect(loaded.notifyContactsOnStart, isFalse);
    expect(loaded.alertMessageTemplate, defaultAlertTemplate);
  });

  testWidgets('dashboard renders the hero, contacts and feature cards',
      (tester) async {
    await _pumpApp(tester);

    expect(find.text('Start Monitored Walk'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
    expect(find.text('No contacts added yet'), findsOneWidget);
    expect(find.text('Smart Tracking'), findsOneWidget);
    expect(find.text('Instant Alerts'), findsOneWidget);
    expect(find.text('Safe Routes'), findsOneWidget);
    expect(find.text('Stay Connected'), findsOneWidget);
  });

  testWidgets('a contact can be added, persisted and deleted with confirmation',
      (tester) async {
    _useDesktopSurface(tester);
    await _pumpApp(tester);

    await tester.ensureVisible(find.byTooltip('Add Contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add Contact'));
    await tester.pumpAndSettle();
    expect(find.text('Add Emergency Contact'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sarah Mokoena');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '+27 82 123 4567',
    );
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();

    expect(find.text('Sarah Mokoena'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);

    final stored = await ContactRepository().load();
    expect(stored, hasLength(1));
    expect(stored.first.name, 'Sarah Mokoena');
    expect(stored.first.phone, '+27 82 123 4567');

    await tester.ensureVisible(find.byTooltip('Delete Sarah Mokoena'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Sarah Mokoena'));
    await tester.pumpAndSettle();
    expect(find.text('Remove contact?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Sarah Mokoena'), findsNothing);
    expect(await ContactRepository().load(), isEmpty);

    await _flushToasts(tester);
  });

  testWidgets('every navigation item opens its own page', (tester) async {
    _useDesktopSurface(tester);
    await _pumpApp(tester);

    await tester.tap(find.text('Walk History'));
    await tester.pumpAndSettle();
    expect(find.text('No walks recorded yet'), findsOneWidget);

    await tester.tap(find.text('Routes'));
    await tester.pumpAndSettle();
    expect(find.text('Your current location'), findsOneWidget);
    expect(find.text('Recent destinations'), findsOneWidget);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('No reminders yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Walk preferences'), findsOneWidget);
    expect(find.text('Your data'), findsOneWidget);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency Contacts'), findsOneWidget);
  });

  testWidgets('mobile layout exposes the same navigation through a drawer',
      (tester) async {
    _useMobileSurface(tester);
    await _pumpApp(tester);

    expect(find.byTooltip('Open navigation'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    expect(find.text('Walk History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(find.text('No reminders yet'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const WalcksApp());
  await tester.pumpAndSettle();
}

void _useDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void _useMobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 950);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Lets any snackbar timers fire so the test exits without pending timers.
Future<void> _flushToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}
