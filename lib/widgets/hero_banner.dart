import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Large gradient hero banner with the two-line headline, CTA and illustration.
class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, required this.onStartWalk});

  final VoidCallback onStartWalk;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= 820;
        return ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            decoration: BoxDecoration(gradient: walcksHeroGradient),
            padding: EdgeInsets.all(wide ? 32 : 24),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 11,
                        child: _HeroCopy(
                          onStartWalk: onStartWalk,
                          headingSize: 42,
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(flex: 9, child: HeroIllustration()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCopy(onStartWalk: onStartWalk, headingSize: 32),
                      const SizedBox(height: 22),
                      const HeroIllustration(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onStartWalk, required this.headingSize});

  final VoidCallback onStartWalk;
  final double headingSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle headingStyle = TextStyle(
      fontSize: headingSize,
      fontWeight: FontWeight.w800,
      height: 1.12,
      letterSpacing: -0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Every step\n',
                style: headingStyle.copyWith(color: WalcksColors.navy),
              ),
              TextSpan(
                text: 'protected.',
                style: headingStyle.copyWith(color: WalcksColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            'Add your emergency contacts and start a monitored walk '
            'for peace of mind.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: WalcksColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 26),
        GradientCta(
          label: 'Start Monitored Walk',
          icon: Icons.directions_walk_rounded,
          onPressed: onStartWalk,
        ),
      ],
    );
  }
}

/// Vector-style illustration: an evening city scene with a central security
/// shield and two walkers - a man in blue on the left and a woman in purple
/// on the right.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Illustration of a man in a blue jacket and a woman in a purple hoodie '
          'walking through an evening city with a shield behind them.',
      child: ColorFiltered(
        // The illustration is drawn in daytime colours; in dark mode it is
        // multiplied down into a night-time scene.
        colorFilter: ColorFilter.mode(
          WalcksColors.isDark ? const Color(0xFF5A5182) : Colors.white,
          BlendMode.multiply,
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 10,
          child: CustomPaint(painter: _HeroPainter()),
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  static const double _w = 640;
  static const double _h = 400;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);
    _paintSky(canvas);
    _paintSun(canvas);
    _paintClouds(canvas);
    _paintBirds(canvas);
    _paintCity(canvas);
    _paintGround(canvas);
    _paintPath(canvas);
    _paintTrees(canvas);
    _paintLamps(canvas);
    _paintShield(canvas);
    _paintWalker(canvas, baseX: 128, female: false);
    _paintWalker(canvas, baseX: 502, female: true);
    canvas.restore();
  }

  void _paintSky(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, _w, _h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDE6FF), Color(0xFFFFE6D5)],
        ).createShader(rect),
    );
  }

  void _paintSun(Canvas canvas) {
    const Offset center = Offset(452, 136);
    canvas.drawCircle(
      center,
      94,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x88FFE3AE), Color(0x00FFE3AE)],
        ).createShader(Rect.fromCircle(center: center, radius: 94)),
    );
    canvas.drawCircle(center, 44, Paint()..color = const Color(0xFFFFD79B));
  }

  void _paintClouds(Canvas canvas) {
    _cloud(canvas, const Offset(150, 74), 0.95);
    _cloud(canvas, const Offset(524, 60), 0.72);
  }

  void _cloud(Canvas canvas, Offset origin, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(center: origin, width: 92 * scale, height: 34 * scale),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: origin.translate(-26 * scale, 8 * scale),
        width: 62 * scale,
        height: 28 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: origin.translate(28 * scale, 6 * scale),
        width: 68 * scale,
        height: 28 * scale,
      ),
      paint,
    );
  }

  void _paintBirds(Canvas canvas) {
    _bird(canvas, const Offset(250, 66), 1);
    _bird(canvas, const Offset(278, 56), 0.9);
    _bird(canvas, const Offset(306, 70), 0.8);
  }

  void _bird(Canvas canvas, Offset origin, double scale) {
    final paint = Paint()
      ..color = const Color(0xFF6B5B95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(origin.dx - 8 * scale, origin.dy)
      ..quadraticBezierTo(
        origin.dx - 4 * scale,
        origin.dy - 6 * scale,
        origin.dx,
        origin.dy,
      )
      ..quadraticBezierTo(
        origin.dx + 4 * scale,
        origin.dy - 6 * scale,
        origin.dx + 8 * scale,
        origin.dy,
      );
    canvas.drawPath(path, paint);
  }

  void _paintCity(Canvas canvas) {
    const double baseline = 300;
    const List<List<double>> buildings = [
      [14, 52, 96],
      [74, 42, 132],
      [122, 58, 108],
      [188, 46, 150],
      [242, 64, 120],
      [314, 50, 142],
      [372, 56, 104],
      [436, 44, 128],
      [488, 62, 112],
      [560, 54, 146],
    ];

    final windowPaint = Paint()
      ..color = const Color(0xFFFFF3E2).withValues(alpha: 0.7);

    for (int i = 0; i < buildings.length; i++) {
      final double x = buildings[i][0];
      final double width = buildings[i][1];
      final double height = buildings[i][2];
      final Rect rect = Rect.fromLTWH(x, baseline - height, width, height);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFC9BCF0)
              : const Color(0xFFB7A6EC),
      );

      for (double wy = rect.top + 14; wy < baseline - 16; wy += 22) {
        for (double wx = rect.left + 10; wx < rect.right - 12; wx += 18) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(wx, wy, 8, 11),
              const Radius.circular(2),
            ),
            windowPaint,
          );
        }
      }
    }
  }

  void _paintGround(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 300, _w, _h - 300),
      Paint()..color = const Color(0xFFF4EFFF),
    );
  }

  void _paintPath(Canvas canvas) {
    final path = Path()
      ..moveTo(-20, 392)
      ..quadraticBezierTo(200, 334, 420, 352)
      ..quadraticBezierTo(560, 362, 660, 354)
      ..lineTo(660, 400)
      ..lineTo(-20, 400)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE7DEFB));
  }

  void _paintTrees(Canvas canvas) {
    _tree(canvas, 64, 302, 0.95);
    _tree(canvas, 600, 304, 1.05);
    _shrub(canvas, 116, 302, 0.8);
  }

  void _tree(Canvas canvas, double x, double baseY, double scale) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, baseY - 16 * scale),
          width: 9 * scale,
          height: 36 * scale,
        ),
        Radius.circular(4 * scale),
      ),
      Paint()..color = const Color(0xFF4B3A86),
    );
    canvas.drawCircle(
      Offset(x - 12 * scale, baseY - 42 * scale),
      20 * scale,
      Paint()..color = const Color(0xFF6E4FD6),
    );
    canvas.drawCircle(
      Offset(x + 12 * scale, baseY - 44 * scale),
      18 * scale,
      Paint()..color = const Color(0xFF8B65F5),
    );
    canvas.drawCircle(
      Offset(x, baseY - 64 * scale),
      22 * scale,
      Paint()..color = const Color(0xFF8B65F5),
    );
  }

  void _shrub(Canvas canvas, double x, double baseY, double scale) {
    canvas.drawCircle(
      Offset(x, baseY - 12 * scale),
      16 * scale,
      Paint()..color = const Color(0xFF8059EC),
    );
    canvas.drawCircle(
      Offset(x + 16 * scale, baseY - 8 * scale),
      12 * scale,
      Paint()..color = const Color(0xFFA98CF7),
    );
  }

  void _paintLamps(Canvas canvas) {
    _lamp(canvas, 190, 336);
    _lamp(canvas, 462, 340);
  }

  void _lamp(Canvas canvas, double x, double baseY) {
    final pole = Paint()
      ..color = const Color(0xFF2A2440)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, baseY), Offset(x, baseY - 92), pole);
    canvas.drawLine(Offset(x, baseY - 92), Offset(x + 22, baseY - 92), pole);

    const Offset bulb = Offset(22, -84);
    final Offset bulbCenter = Offset(x + bulb.dx, baseY + bulb.dy);
    canvas.drawCircle(
      bulbCenter,
      28,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x99FFE0A8), Color(0x00FFE0A8)],
        ).createShader(Rect.fromCircle(center: bulbCenter, radius: 28)),
    );
    canvas.drawCircle(bulbCenter, 7, Paint()..color = const Color(0xFFFFD98F));
  }

  void _paintShield(Canvas canvas) {
    const Offset center = Offset(320, 206);

    canvas.drawCircle(
      center,
      152,
      Paint()
        ..shader = RadialGradient(
          colors: [
            WalcksColors.primary.withValues(alpha: 0.10),
            WalcksColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 152)),
    );

    canvas.drawCircle(
      center,
      132,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = WalcksColors.primary.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      108,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = WalcksColors.primary.withValues(alpha: 0.22),
    );

    canvas.drawPath(
      _shieldPath(center, 62, 78),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WalcksColors.primary, WalcksColors.primaryLight],
            ).createShader(
              Rect.fromCenter(center: center, width: 130, height: 164),
            ),
    );

    final check = Path()
      ..moveTo(center.dx - 24, center.dy + 2)
      ..lineTo(center.dx - 8, center.dy + 18)
      ..lineTo(center.dx + 25, center.dy - 17);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  Path _shieldPath(Offset center, double halfWidth, double halfHeight) {
    final path = Path()
      ..moveTo(center.dx, center.dy - halfHeight)
      ..lineTo(center.dx + halfWidth, center.dy - halfHeight + 20)
      ..lineTo(center.dx + halfWidth, center.dy + 12)
      ..quadraticBezierTo(
        center.dx + halfWidth,
        center.dy + halfHeight - 14,
        center.dx,
        center.dy + halfHeight,
      )
      ..quadraticBezierTo(
        center.dx - halfWidth,
        center.dy + halfHeight - 14,
        center.dx - halfWidth,
        center.dy + 12,
      )
      ..lineTo(center.dx - halfWidth, center.dy - halfHeight + 20)
      ..close();
    return path;
  }

  void _paintWalker(
    Canvas canvas, {
    required double baseX,
    required bool female,
  }) {
    const Color skin = Color(0xFFF3C9A6);
    const Color hairColor = Color(0xFF2A2440);
    const Color shoeColor = Color(0xFF1B1830);

    final Color jacket = female
        ? const Color(0xFF8B65F5)
        : const Color(0xFF3978E8);
    final Color trousers = female
        ? const Color(0xFF2A2440)
        : const Color(0xFF111638);
    final double halfTorso = female ? 17 : 20;

    final jacketPaint = Paint()
      ..color = jacket
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final trouserPaint = Paint()
      ..color = trousers
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Back arm.
    canvas.drawPath(
      Path()
        ..moveTo(baseX - 8, 238)
        ..lineTo(baseX - 22, 262)
        ..lineTo(baseX - 18, 286),
      jacketPaint,
    );

    // Legs, mid-stride.
    canvas.drawPath(
      Path()
        ..moveTo(baseX - 5, 286)
        ..lineTo(baseX - 16, 314)
        ..lineTo(baseX - 24, 340),
      trouserPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(baseX + 5, 286)
        ..lineTo(baseX + 14, 314)
        ..lineTo(baseX + 20, 340),
      trouserPaint,
    );

    // Shoes.
    final shoePaint = Paint()..color = shoeColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(baseX - 27, 344), width: 21, height: 10),
        const Radius.circular(5),
      ),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(baseX + 24, 344), width: 23, height: 10),
        const Radius.circular(5),
      ),
      shoePaint,
    );

    // Torso.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(baseX - halfTorso, 226, halfTorso * 2, 64),
        Radius.circular(female ? 15 : 17),
      ),
      Paint()..color = jacket,
    );

    // Neck.
    canvas.drawRect(
      Rect.fromCenter(center: Offset(baseX + 1, 222), width: 12, height: 14),
      Paint()..color = skin,
    );

    // Hair.
    if (female) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(baseX - 14, 216), width: 19, height: 48),
        Paint()..color = hairColor,
      );
      canvas.drawCircle(
        Offset(baseX - 8, 200),
        5,
        Paint()..color = WalcksColors.primaryLight,
      );
    }
    canvas.drawCircle(Offset(baseX + 1, 206), 18, Paint()..color = hairColor);
    canvas.drawCircle(Offset(baseX + 5, 209), 15, Paint()..color = skin);
    canvas.drawCircle(Offset(baseX + 11, 207), 1.8, Paint()..color = hairColor);

    // Front arm holding a phone.
    canvas.drawPath(
      Path()
        ..moveTo(baseX + 9, 238)
        ..lineTo(baseX + 24, 258)
        ..lineTo(baseX + 19, 278),
      jacketPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(baseX + 15, 264, 10, 16),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1B1830),
    );
  }

  @override
  bool shouldRepaint(covariant _HeroPainter oldDelegate) => false;
}
