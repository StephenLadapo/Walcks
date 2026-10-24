import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Top bar of the main content: greeting and a working account menu.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.displayName,
    required this.onOpenProfile,
    required this.onOpenSettings,
    this.leading,
  });

  /// Name shown in the greeting and on the avatar.
  final String displayName;

  /// Opens the profile section (Settings).
  final VoidCallback onOpenProfile;

  /// Opens the Settings page.
  final VoidCallback onOpenSettings;

  /// Optional leading widget, used for the navigation button on small screens.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        const Spacer(),
        _ProfileMenu(
          displayName: displayName,
          onOpenProfile: onOpenProfile,
          onOpenSettings: onOpenSettings,
        ),
      ],
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.displayName,
    required this.onOpenProfile,
    required this.onOpenSettings,
  });

  final String displayName;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('About Walcks', style: WalcksText.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Walcks helps you walk with confidence by keeping your emergency '
              'contacts and monitored walks in one place.',
              style: WalcksText.body,
            ),
            SizedBox(height: 14),
            Text(
              'Everything is stored only on this device. Walcks has no server, '
              'no online account and nothing is uploaded.',
              style: WalcksText.body,
            ),
            SizedBox(height: 14),
            Text('Version 1.0.0', style: WalcksText.small),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      offset: const Offset(0, 58),
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onOpenProfile();
            break;
          case 'settings':
            onOpenSettings();
            break;
          case 'about':
            _showAbout(context);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: _MenuRow(icon: Icons.person_outline_rounded, label: 'Profile'),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: _MenuRow(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        PopupMenuItem<String>(
          value: 'about',
          child: _MenuRow(
            icon: Icons.info_outline_rounded,
            label: 'About Walcks',
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: 'Account menu for $displayName',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 13,
                      color: WalcksColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: WalcksColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WalcksColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initialsFor(displayName),
                  style: TextStyle(
                    color: WalcksColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: WalcksColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: WalcksColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: WalcksColors.textMain,
          ),
        ),
      ],
    );
  }
}
