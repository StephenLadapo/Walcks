import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class WalcksNavItem {
  const WalcksNavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

const List<WalcksNavItem> walcksNavItems = [
  WalcksNavItem('Contacts', Icons.groups_rounded),
  WalcksNavItem('Walk History', Icons.history_rounded),
  WalcksNavItem('Routes', Icons.place_rounded),
  WalcksNavItem('Reminders', Icons.notifications_none_rounded),
  WalcksNavItem('Settings', Icons.settings_rounded),
];

/// Fixed-width left navigation with the brand, primary navigation and the
/// promotional safety card.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.compact = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 96 : 310,
      decoration: BoxDecoration(
        color: WalcksColors.sidebar,
        border: Border(right: BorderSide(color: WalcksColors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 0 : 24,
                26,
                compact ? 0 : 24,
                20,
              ),
              child: compact
                  ? const Center(child: WalcksBrandMark(size: 46))
                  : Row(
                      children: [
                        const WalcksBrandMark(size: 46),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Text(
                            'Walcks',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: WalcksColors.navy,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
                itemCount: walcksNavItems.length,
                itemBuilder: (context, index) => _NavItem(
                  item: walcksNavItems[index],
                  selected: index == selectedIndex,
                  compact: compact,
                  onTap: () => onSelect(index),
                ),
              ),
            ),
            if (!compact)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: _SafetyCard(),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final WalcksNavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final Color background = selected
        ? WalcksColors.lavender
        : _hovering
        ? WalcksColors.lavender.withValues(alpha: 0.6)
        : Colors.transparent;
    final Color foreground = selected
        ? WalcksColors.primary
        : WalcksColors.navy;

    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: widget.compact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(widget.item.icon, size: 22, color: foreground),
          if (!widget.compact) ...[
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                widget.item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final Widget interactive = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: content,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: widget.compact
            ? Tooltip(message: widget.item.label, child: interactive)
            : interactive,
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: WalcksColors.lavender,
        child: Stack(
          children: [
            Positioned(
              right: -34,
              top: -34,
              child: _softCircle(96, Colors.white.withValues(alpha: 0.55)),
            ),
            Positioned(
              right: 26,
              bottom: -38,
              child: _softCircle(
                74,
                WalcksColors.primary.withValues(alpha: 0.10),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: walcksPrimaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: WalcksColors.primary.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your safety matters',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: WalcksColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Walcks monitors your safety and helps keep your loved ones '
                  'informed, every step of the way.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: WalcksColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
