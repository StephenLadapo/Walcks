import 'package:flutter/material.dart';

import '../theme.dart';

/// Purple shield brand mark used in the sidebar and empty states.
class WalcksBrandMark extends StatelessWidget {
  const WalcksBrandMark({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: walcksPrimaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: WalcksColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.18),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.62),
          Icon(
            Icons.location_on_rounded,
            color: WalcksColors.primary,
            size: size * 0.26,
          ),
        ],
      ),
    );
  }
}

/// Wraps a widget so it lifts slightly on hover (desktop) and shows a pointer.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.lift = 5,
    this.clickable = true,
  });

  final Widget child;
  final double lift;
  final bool clickable;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool lifted = _hovering && !reduceMotion;

    return MouseRegion(
      cursor: widget.clickable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, lifted ? -widget.lift : 0, 0),
        child: widget.child,
      ),
    );
  }
}

/// Purple gradient call-to-action button with a hover brighten + lift.
class GradientCta extends StatefulWidget {
  const GradientCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 54,
    this.expand = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  State<GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<GradientCta> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool lifted = _hovering && enabled && !reduceMotion;

    final Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: widget.height,
      transform: Matrix4.translationValues(0, lifted ? -3 : 0, 0),
      decoration: BoxDecoration(
        gradient: walcksPrimaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: WalcksColors.primary.withValues(
                    alpha: lifted ? 0.5 : 0.38,
                  ),
                  blurRadius: lifted ? 28 : 22,
                  offset: Offset(0, lifted ? 16 : 12),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (lifted)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: widget.expand
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

/// Circular purple add button with a label underneath.
class CircleAddButton extends StatelessWidget {
  const CircleAddButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: label,
            child: HoverLift(
              lift: 3,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: walcksPrimaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: WalcksColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible toast notification helper.
class WalcksToast {
  WalcksToast._();

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    IconData? icon,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: error
              ? WalcksColors.coral
              : WalcksColors.toastBackground,
          content: Row(
            children: [
              Icon(
                icon ??
                    (error
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}

/// A soft white surface card with the standard Walcks border, radius and shadow.
class WalcksSurface extends StatelessWidget {
  const WalcksSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: WalcksColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WalcksColors.border),
        boxShadow: walcksCardShadow,
      ),
      child: child,
    );
  }
}

/// Formats a display name into initials, e.g. "Ada Lovelace" -> "AL".
String initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// Title (and optional subtitle) shown at the top of each section page.
class WalcksPageHeading extends StatelessWidget {
  const WalcksPageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WalcksColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: WalcksColors.primary, size: 23),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WalcksText.sectionTitle.copyWith(fontSize: 22),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: WalcksText.body),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Inline notice used to communicate real limitations honestly.
class WalcksNotice extends StatelessWidget {
  const WalcksNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.accent,
  });

  final String message;
  final IconData icon;

  /// Accent colour. Falls back to the brand primary when null.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color accent = this.accent ?? WalcksColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: WalcksColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog. Returns true only when the user confirms.
Future<bool> showWalcksConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: WalcksText.sectionTitle),
      content: Text(message, style: WalcksText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: WalcksColors.coral)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Formats a walk duration like "1 h 05 min" or "12 min 30 s".
String formatWalkDuration(Duration duration) {
  if (duration.isNegative || duration.inSeconds < 60) {
    return '${duration.inSeconds.clamp(0, 59)} s';
  }
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }
  return '$minutes min';
}

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date and time like "17 Oct 2026, 14:05".
String formatWalcksDateTime(DateTime value) {
  final DateTime local = value.toLocal();
  final String minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]} ${local.year}, '
      '${local.hour}:$minute';
}
