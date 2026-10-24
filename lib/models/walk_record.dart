import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// How a monitored walk ended.
enum WalkOutcome { completed, stopped }

/// A monitored walk that was actually recorded by the user.
class WalkRecord {
  WalkRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.destination,
    required this.startLabel,
    this.endLabel = '',
    this.gpsUpdates = 0,
    this.outcome = WalkOutcome.stopped,
  });

  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String destination;
  final String startLabel;
  final String endLabel;
  final int gpsUpdates;
  final WalkOutcome outcome;

  Duration get duration => endTime.difference(startTime);

  String get outcomeLabel =>
      outcome == WalkOutcome.completed ? 'Completed' : 'Stopped early';

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'destination': destination,
        'startLabel': startLabel,
        'endLabel': endLabel,
        'gpsUpdates': gpsUpdates,
        'outcome': outcome.name,
      };

  factory WalkRecord.fromJson(Map<String, dynamic> json) {
    final String outcomeName = (json['outcome'] as String?) ?? 'stopped';
    return WalkRecord(
      id: (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      startTime:
          DateTime.tryParse((json['startTime'] as String?) ?? '') ??
              DateTime.now(),
      endTime: DateTime.tryParse((json['endTime'] as String?) ?? '') ??
          DateTime.now(),
      destination: (json['destination'] as String?) ?? '',
      startLabel: (json['startLabel'] as String?) ?? '',
      endLabel: (json['endLabel'] as String?) ?? '',
      gpsUpdates: (json['gpsUpdates'] as num?)?.toInt() ?? 0,
      outcome: outcomeName == 'completed'
          ? WalkOutcome.completed
          : WalkOutcome.stopped,
    );
  }
}

/// Persists completed/stopped walks on the device using the app's existing
/// local storage approach.
class WalkHistoryRepository {
  static const String storageKey = 'walcks_walk_history';
  static const int maxRecords = 200;

  Future<List<WalkRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <WalkRecord>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final records = decoded
        .map(
          (item) =>
              WalkRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    records.sort((a, b) => b.startTime.compareTo(a.startTime));
    return records;
  }

  Future<void> add(WalkRecord record) async {
    final records = await load();
    records.insert(0, record);
    await save(records.take(maxRecords).toList());
  }

  Future<void> save(List<WalkRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
