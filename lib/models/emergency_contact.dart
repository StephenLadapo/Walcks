import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// An emergency contact saved by the user.
class EmergencyContact {
  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
    this.email = '',
  });

  final String id;
  String name;
  String phone;
  String relationship;
  String email;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'email': email,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      relationship: (json['relationship'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

/// Persists emergency contacts on the device (existing Walcks storage key is
/// reused so previously saved contacts are preserved).
class ContactRepository {
  static const String storageKey = 'walcks_emergency_contacts';
  static const int maxContacts = 5;

  Future<List<EmergencyContact>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <EmergencyContact>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) => EmergencyContact.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> save(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final data = contacts.map((contact) => contact.toJson()).toList();
    await prefs.setString(storageKey, jsonEncode(data));
  }
}
