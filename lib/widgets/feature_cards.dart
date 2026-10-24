import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// A single promo feature shown under the contacts card.
class WalcksFeature {
  const WalcksFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color background;
}

/// The four promo features. Built per call so the tints follow the active
/// light or dark palette.
List<WalcksFeature> get walcksFeatures => <WalcksFeature>[
  WalcksFeature(
    title: 'Smart Tracking',
    description: 'Real-time location tracking for your safety.',
    icon: Icons.gpp_good_rounded,
    accent: WalcksColors.teal,
    background: WalcksColors.mintSoft,
  ),
  WalcksFeature(
    title: 'Instant Alerts',
    description: 'Get notified automatically in case of an emergency.',
    icon: Icons.notifications_active_rounded,
    accent: WalcksColors.coral,
    background: WalcksColors.peachSoft,
  ),
  WalcksFeature(
    title: 'Safe Routes',
    description: 'Discover and choose the safest routes.',
    icon: Icons.place_rounded,
    accent: WalcksColors.blue,
    background: WalcksColors.blueSoft,
  ),
  WalcksFeature(
    title: 'Stay Connected',
    description: 'Keep your loved ones informed, always.',
    icon: Icons.groups_rounded,
    accent: WalcksColors.primary,
    background: WalcksColors.lavenderSoft,
  ),
];

/// Four equal-width feature cards in a single row on desktop, wrapping down to
/// two columns on tablet and one column on mobile.
class FeatureCards extends StatelessWidget {
  const FeatureCards({super.key, required this.onSelected});

  /// Called with the index of the tapped feature.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 1040
            ? 4
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        const double gap = 18;
        final double itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final List<Widget> rows = [];
        for (int start = 0; start < walcksFeatures.length; start += columns) {
          final int end = (start + columns).clamp(0, walcksFeatures.length);
          rows.add(
            Row(
              children: [
                for (int i = start; i < end; i++) ...[
                  if (i > start) const SizedBox(width: gap),
                  SizedBox(
                    width: itemWidth,
                    height: 224,
                    child: _FeatureCard(
                      feature: walcksFeatures[i],
                      onTap: () => onSelected(i),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final WalcksFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${feature.title}. ${feature.description}',
      child: HoverLift(
        lift: 5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: feature.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: feature.accent.withValues(alpha: 0.18),
                ),
              ),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: WalcksColors.isDark
                            ? feature.accent.withValues(alpha: 0.16)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: walcksSoftShadow,
                      ),
                      child: Icon(
                        feature.icon,
                        color: feature.accent,
                        size: 25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      feature.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: WalcksColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          feature.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: WalcksColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: feature.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
