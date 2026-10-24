import 'package:flutter/services.dart';

/// Thin wrapper around the native `walcks/sms` method channel that the original
/// Walcks implementation used for SIM selection and sending SMS.
///
/// The channel is only provided by a native host that registers it. When that
/// bridge is missing every call throws and callers must surface the real
/// outcome instead of pretending a message was delivered.
class SmsService {
  SmsService._();

  static const MethodChannel _channel = MethodChannel('walcks/sms');

  /// Returns the device SIM cards.
  ///
  /// Throws [MissingPluginException] when no native bridge is registered, and
  /// [PlatformException] for permission or SIM errors.
  static Future<List<Map<String, dynamic>>> getSims() async {
    final List<dynamic>? sims =
        await _channel.invokeMethod<List<dynamic>>('getSims');
    if (sims == null) return <Map<String, dynamic>>[];
    return sims
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Sends an SMS through the native bridge.
  static Future<void> sendSms({
    required String phone,
    required String message,
    int? subscriptionId,
  }) async {
    await _channel.invokeMethod<void>('sendSms', <String, dynamic>{
      'phone': phone,
      'message': message,
      'subscriptionId': subscriptionId,
    });
  }
}
