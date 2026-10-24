import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A safety reminder saved on the device.
class SafetyReminder {
  SafetyReminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.days = const <int>[],
    this.enabled = true,
  });

  final String id;
  String title;
  int hour;
  int minute;

  /// Weekdays as 1 (Monday) .. 7 (Sunday). Empty means every day.
  List<int> days;
  bool enabled;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get daysLabel {
    if (days.isEmpty) return 'Every day';
    const List<String> names = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    final List<int> sorted = [...days]..sort();
    return sorted.map((day) => names[(day - 1).clamp(0, 6)]).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'days': days,
        'enabled': enabled,
      };

  factory SafetyReminder.fromJson(Map<String, dynamic> json) {
    return SafetyReminder(
      id: (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: (json['title'] as String?) ?? '',
      hour: (json['hour'] as num?)?.toInt() ?? 7,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      days: ((json['days'] as List<dynamic>?) ?? const <dynamic>[])
          .map((day) => (day as num).toInt())
          .toList(),
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}

class ReminderRepository {
  static const String storageKey = 'walcks_reminders';

  Future<List<SafetyReminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <SafetyReminder>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              SafetyReminder.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> save(List<SafetyReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
