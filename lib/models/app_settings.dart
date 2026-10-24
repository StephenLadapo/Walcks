import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Default message used when notifying emergency contacts about a walk.
const String defaultAlertTemplate =
    'I am walking from {from} to {to}. '
    'My journey is being monitored with Walcks.';

/// How the app chooses between the light and dark palettes.
enum WalcksThemeMode {
  system('system', 'System'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const WalcksThemeMode(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static WalcksThemeMode fromStorage(String? value) {
    return WalcksThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => WalcksThemeMode.system,
    );
  }
}

/// User preferences stored on the device. Walcks has no account system, so
/// these settings live on the device only.
class AppSettings {
  AppSettings({
    this.displayName = 'User',
    this.alertMessageTemplate = defaultAlertTemplate,
    this.notifyContactsOnStart = true,
    this.themeMode = WalcksThemeMode.system,
  });

  String displayName;
  String alertMessageTemplate;
  bool notifyContactsOnStart;
  WalcksThemeMode themeMode;

  AppSettings copyWith({
    String? displayName,
    String? alertMessageTemplate,
    bool? notifyContactsOnStart,
    WalcksThemeMode? themeMode,
  }) {
    return AppSettings(
      displayName: displayName ?? this.displayName,
      alertMessageTemplate: alertMessageTemplate ?? this.alertMessageTemplate,
      notifyContactsOnStart:
          notifyContactsOnStart ?? this.notifyContactsOnStart,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'alertMessageTemplate': alertMessageTemplate,
        'notifyContactsOnStart': notifyContactsOnStart,
        'themeMode': themeMode.storageValue,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      displayName: (json['displayName'] as String?) ?? 'User',
      alertMessageTemplate:
          (json['alertMessageTemplate'] as String?) ?? defaultAlertTemplate,
      notifyContactsOnStart:
          (json['notifyContactsOnStart'] as bool?) ?? true,
      themeMode: WalcksThemeMode.fromStorage(json['themeMode'] as String?),
    );
  }
}

class SettingsRepository {
  static const String storageKey = 'walcks_settings';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return AppSettings();
    return AppSettings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(settings.toJson()));
  }

  /// Persists only the theme choice, keeping every other saved preference.
  Future<void> saveThemeMode(WalcksThemeMode mode) async {
    final AppSettings current = await load();
    await save(current.copyWith(themeMode: mode));
  }
}
