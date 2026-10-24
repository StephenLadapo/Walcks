import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/emergency_contact.dart';
import '../services/sms_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Instant Alerts view: shows the emergency-alert configuration Walcks supports
/// (the message template and the contacts that will be alerted) and reports the
/// real delivery result of an alert attempt. It never claims an alert was
/// delivered when it was not.
class AlertsPage extends StatefulWidget {
  const AlertsPage({
    super.key,
    required this.contacts,
    required this.settings,
    required this.onSaveSettings,
  });

  final List<EmergencyContact> contacts;
  final AppSettings settings;
  final Future<void> Function(AppSettings settings) onSaveSettings;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late final TextEditingController _template;

  bool _testing = false;
  bool _savedTemplate = false;
  List<_DeliveryResult>? _results;

  @override
  void initState() {
    super.initState();
    _template = TextEditingController(
      text: widget.settings.alertMessageTemplate,
    );
    _template.addListener(() {
      if (_savedTemplate) setState(() => _savedTemplate = false);
    });
  }

  @override
  void dispose() {
    _template.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    final String value = _template.text.trim();
    if (value.isEmpty) {
      WalcksToast.show(
        context,
        'The alert message cannot be empty.',
        error: true,
      );
      return;
    }

    try {
      await widget.onSaveSettings(
        widget.settings.copyWith(alertMessageTemplate: value),
      );
      if (!mounted) return;
      setState(() => _savedTemplate = true);
      WalcksToast.show(context, 'Alert message saved.');
    } catch (_) {
      if (!mounted) return;
      WalcksToast.show(
        context,
        'Could not save the alert message.',
        error: true,
      );
    }
  }

  Future<void> _sendTestAlert() async {
    if (widget.contacts.isEmpty) return;

    setState(() {
      _testing = true;
      _results = null;
    });

    const String message =
        'Walcks test alert. This is a test from the Walcks app.';
    final List<_DeliveryResult> results = <_DeliveryResult>[];

    for (final contact in widget.contacts) {
      try {
        await SmsService.sendSms(phone: contact.phone, message: message);
        results.add(
          _DeliveryResult(contact.name, 'Sent to your device SMS app', true),
        );
      } on PlatformException catch (error) {
        results.add(
          _DeliveryResult(
            contact.name,
            error.message?.isNotEmpty == true
                ? error.message!
                : 'Rejected by the device (${error.code})',
            false,
          ),
        );
      } on MissingPluginException {
        results.add(
          _DeliveryResult(
            contact.name,
            'Automatic SMS is not available on this platform',
            false,
          ),
        );
      } catch (_) {
        results.add(_DeliveryResult(contact.name, 'Sending failed', false));
      }
    }

    if (!mounted) return;
    setState(() {
      _testing = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasContacts = widget.contacts.isNotEmpty;
    final bool anySent = _results?.any((result) => result.delivered) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const WalcksPageHeading(
          title: 'Instant Alerts',
          subtitle: 'Configure and test the emergency alert Walcks sends.',
          icon: Icons.notifications_active_rounded,
        ),
        const SizedBox(height: 22),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Alert delivery status', style: WalcksText.cardTitle),
              const SizedBox(height: 14),
              if (_results == null)
                const WalcksNotice(
                  message:
                      'Not tested yet. Send a test alert to see the real '
                      'delivery result for each contact. Walcks only reports a '
                      'result once the device has actually answered.',
                )
              else ...[
                WalcksNotice(
                  message: anySent
                      ? 'At least one alert was handed to your device SMS app. '
                            'Final delivery still depends on your network and '
                            'carrier.'
                      : 'No alert could be delivered. Nothing was sent to your '
                            'contacts.',
                  icon: anySent
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  accent: anySent ? WalcksColors.teal : WalcksColors.coral,
                ),
                const SizedBox(height: 14),
                for (final result in _results!) ...[
                  _ResultRow(result: result),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 16),
              GradientCta(
                label: _testing ? 'Sending test alert...' : 'Send test alert',
                icon: Icons.send_rounded,
                onPressed: (!hasContacts || _testing) ? null : _sendTestAlert,
                expand: true,
              ),
              if (!hasContacts) ...[
                const SizedBox(height: 12),
                WalcksNotice(
                  message: 'Add an emergency contact before sending an alert.',
                  icon: Icons.person_add_alt_1_rounded,
                  accent: WalcksColors.coral,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Alert message', style: WalcksText.cardTitle),
              const SizedBox(height: 4),
              Text(
                'Used when a monitored walk starts or ends. '
                'Use {from} and {to} for your live position and destination.',
                style: WalcksText.small,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _template,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message template',
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saveTemplate,
                  icon: Icon(
                    _savedTemplate ? Icons.check_rounded : Icons.save_outlined,
                  ),
                  label: Text(_savedTemplate ? 'Saved' : 'Save message'),
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
              Text(
                'Contacts that will be alerted',
                style: WalcksText.cardTitle,
              ),
              const SizedBox(height: 14),
              if (!hasContacts)
                Text(
                  'No emergency contacts saved yet. Add contacts from the '
                  'Contacts page and they will receive your alerts.',
                  style: WalcksText.body,
                )
              else
                for (final contact in widget.contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: walcksPrimaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            initialsFor(contact.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: WalcksColors.textMain,
                                ),
                              ),
                              Text(contact.phone, style: WalcksText.small),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WalcksNotice(
          message:
              'Automatic SMS alerts need the native "walcks/sms" bridge '
              'in the Android host. This project does not implement that '
              'bridge, so on the web build and on a default Android host the '
              'test above reports the failure instead of a false success. '
              'You can still call your contacts directly from the Contacts '
              'page.',
          icon: Icons.build_outlined,
          accent: WalcksColors.coral,
        ),
      ],
    );
  }
}

class _DeliveryResult {
  const _DeliveryResult(this.contactName, this.detail, this.delivered);

  final String contactName;
  final String detail;
  final bool delivered;
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final _DeliveryResult result;

  @override
  Widget build(BuildContext context) {
    final Color accent = result.delivered
        ? WalcksColors.teal
        : WalcksColors.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.delivered
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.contactName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: WalcksColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: WalcksColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
