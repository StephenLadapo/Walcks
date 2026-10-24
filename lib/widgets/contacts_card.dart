import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttercontactpicker_plus/fluttercontactpicker_plus.dart';

import '../models/emergency_contact.dart';
import '../theme.dart';
import 'common.dart';

/// Opens the add/edit contact form. Returns the saved contact, or null when
/// the user cancels.
Future<EmergencyContact?> showContactForm(
  BuildContext context, {
  EmergencyContact? existing,
}) {
  return showDialog<EmergencyContact>(
    context: context,
    builder: (_) => ContactFormDialog(existing: existing),
  );
}

class ContactFormDialog extends StatefulWidget {
  const ContactFormDialog({super.key, this.existing});

  final EmergencyContact? existing;

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9()\-\s]{7,}$');
  static final RegExp _emailPattern = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _relationship;
  late final TextEditingController _email;

  bool _picking = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final EmergencyContact? existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _relationship = TextEditingController(text: existing?.relationship ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickFromDevice() async {
    if (kIsWeb && !FlutterContactPicker.available) {
      WalcksToast.show(
        context,
        'This browser does not support contact selection. '
        'Please enter the details manually.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() => _picking = true);
    try {
      final picked = await FlutterContactPicker.pickPhoneContact();
      final name = picked.fullName?.trim() ?? '';
      final phone = picked.phoneNumber?.number?.trim() ?? '';
      if (!mounted) return;

      if (name.isEmpty || phone.isEmpty) {
        WalcksToast.show(
          context,
          'The selected contact needs a name and phone number.',
          error: true,
        );
        return;
      }

      setState(() {
        _name.text = name;
        _phone.text = phone;
      });
    } catch (_) {
      if (!mounted) return;
      WalcksToast.show(
        context,
        'Contact selection was cancelled or unavailable. '
        'You can enter the details manually.',
        icon: Icons.info_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      EmergencyContact(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relationship: _relationship.text.trim(),
        email: _email.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = math.min(440, MediaQuery.sizeOf(context).width - 72);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Text(
        _editing ? 'Edit Emergency Contact' : 'Add Emergency Contact',
        style: WalcksText.sectionTitle,
      ),
      content: SizedBox(
        width: width,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _picking ? null : _pickFromDevice,
                  icon: _picking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.contacts_outlined, size: 20),
                  label: Text(
                    _picking
                        ? 'Opening contacts...'
                        : 'Select from phone contacts',
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'e.g. Sarah Mokoena',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final String text = (value ?? '').trim();
                    if (text.isEmpty) return 'Please enter a name.';
                    if (text.length < 2) return 'That name looks too short.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'e.g. +27 82 123 4567',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                  validator: (value) {
                    final String text = (value ?? '').trim();
                    if (text.isEmpty) return 'Please enter a phone number.';
                    if (!_phonePattern.hasMatch(text)) {
                      return 'Enter a valid phone number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _relationship,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (optional)',
                    hintText: 'e.g. Family, Friend, Partner',
                    prefixIcon: Icon(Icons.favorite_border_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'e.g. sarah@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    final String text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    if (!_emailPattern.hasMatch(text)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Save changes' : 'Save contact'),
        ),
      ],
    );
  }
}

/// White card that lists the user's emergency contacts, or shows an elegant
/// empty state with the circular add button.
class ContactsCard extends StatelessWidget {
  const ContactsCard({
    super.key,
    required this.contacts,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  final List<EmergencyContact> contacts;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<EmergencyContact> onEdit;
  final ValueChanged<EmergencyContact> onDelete;
  final ValueChanged<EmergencyContact> onCall;

  @override
  Widget build(BuildContext context) {
    return WalcksSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emergency Contacts',
                  style: WalcksText.sectionTitle,
                ),
              ),
              if (contacts.isNotEmpty) _MiniAddButton(onPressed: onAdd),
            ],
          ),
          const SizedBox(height: 20),
          if (loading)
            SizedBox(
              height: 96,
              child: Center(
                child: CircularProgressIndicator(
                  color: WalcksColors.primary,
                  strokeWidth: 2.6,
                ),
              ),
            )
          else if (contacts.isEmpty)
            _EmptyState(onAdd: onAdd)
          else
            _ContactGrid(
              contacts: contacts,
              onEdit: onEdit,
              onDelete: onDelete,
              onCall: onCall,
            ),
        ],
      ),
    );
  }
}

class _MiniAddButton extends StatelessWidget {
  const _MiniAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Add another emergency contact',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WalcksColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: WalcksColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Add Contact',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: WalcksColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const Widget icon = _EmptyIcon();
    const Widget copy = _EmptyCopy();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 124),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              children: [
                icon,
                const SizedBox(height: 16),
                copy,
                const SizedBox(height: 22),
                CircleAddButton(
                  label: 'Add Contact',
                  onPressed: onAdd,
                  semanticLabel: 'Add emergency contact',
                ),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      SizedBox(width: 18),
                      Flexible(child: copy),
                      SizedBox(width: 18),
                      _DashedArrow(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              CircleAddButton(
                label: 'Add Contact',
                onPressed: onAdd,
                semanticLabel: 'Add emergency contact',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: WalcksColors.lavender,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.groups_rounded, color: WalcksColors.primary, size: 30),
    );
  }
}

class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No contacts added yet',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: WalcksColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add an emergency contact to get started.',
          style: TextStyle(fontSize: 13.5, color: WalcksColors.textSecondary),
        ),
      ],
    );
  }
}

class _DashedArrow extends StatelessWidget {
  const _DashedArrow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 76,
      height: 40,
      child: CustomPaint(painter: _DashedArrowPainter()),
    );
  }
}

class _DashedArrowPainter extends CustomPainter {
  const _DashedArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.02,
        size.width * 0.9,
        size.height * 0.34,
      );

    final Paint paint = Paint()
      ..color = WalcksColors.primary.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dash = 6;
    const double gap = 5;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }

    final Offset tip = Offset(size.width * 0.9, size.height * 0.34);
    final Paint head = Paint()
      ..color = WalcksColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tip, tip.translate(-9, -1), head);
    canvas.drawLine(tip, tip.translate(-2, 9), head);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ContactGrid extends StatelessWidget {
  const _ContactGrid({
    required this.contacts,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  final List<EmergencyContact> contacts;
  final ValueChanged<EmergencyContact> onEdit;
  final ValueChanged<EmergencyContact> onDelete;
  final ValueChanged<EmergencyContact> onCall;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 660
            ? 2
            : 1;
        const double gap = 16;
        final double itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final contact in contacts)
              SizedBox(
                width: itemWidth,
                child: _ContactTile(
                  contact: contact,
                  onEdit: () => onEdit(contact),
                  onDelete: () => onDelete(contact),
                  onCall: () => onCall(contact),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      lift: 4,
      clickable: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WalcksColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WalcksColors.border),
          boxShadow: walcksSoftShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: WalcksColors.textMain,
                        ),
                      ),
                      if (contact.relationship.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          contact.relationship,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: WalcksColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ContactLine(icon: Icons.call_outlined, value: contact.phone),
            if (contact.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ContactLine(
                icon: Icons.mail_outline_rounded,
                value: contact.email,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PillAction(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: WalcksColors.teal,
                    tooltip: 'Call ${contact.name}',
                    onTap: onCall,
                  ),
                ),
                const SizedBox(width: 8),
                _SquareIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit ${contact.name}',
                  color: WalcksColors.primary,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _SquareIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete ${contact.name}',
                  color: WalcksColors.coral,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: WalcksColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: WalcksColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
