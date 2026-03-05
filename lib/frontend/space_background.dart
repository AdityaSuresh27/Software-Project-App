/// Shared space / galaxy background used across WelcomeScreen & GetStartedPage.
/// Includes parallax stars, moons, dark planets, asteroids, aurora glows,
/// shooting stars, twinkling, and subtle constant micro-motion.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

class SpaceBackground extends StatefulWidget {
  final double scrollOffset;
  const SpaceBackground({super.key, this.scrollOffset = 0});

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with TickerProviderStateMixin {
  late AnimationController _microMotionCtrl;
  late AnimationController _twinkleCtrl;
  late List<_ShootingStar> _shootingStars;
  Timer? _shootingStarTimer;

  @override
  void initState() {
    super.initState();
    _shootingStars = [];

    // Continuous gentle micro-motion
    _microMotionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Twinkling pulse
    _twinkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Spawn shooting stars at random intervals (every 3-5 seconds), max 2 concurrent
    _shootingStarTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        // Update each star's progress based on elapsed time
        final now = DateTime.now();
        for (final s in _shootingStars) {
          final elapsed = now.difference(s.spawnTime).inMilliseconds;
          s.progress = (elapsed / 2000.0).clamp(0.0, 1.0); // 2 second streak
        }
        
        // Remove finished stars
        _shootingStars.removeWhere((s) => s.progress >= 1.0);
        
        // Only spawn if we have fewer than 2 concurrent
        if (_shootingStars.length < 2) {
          // Random chance to spawn (roughly every 3-5 seconds at 50ms ticks)
          if (math.Random().nextDouble() < 0.035) {
            _shootingStars.add(_ShootingStar.random(1080, 2400));
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _shootingStarTimer?.cancel();
    _microMotionCtrl.dispose();
    _twinkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final so = widget.scrollOffset;
    final drift = _microMotionCtrl.value;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF020B14),
              Color(0xFF071828),
              Color(0xFF0A2030),
              Color(0xFF060E1A),
            ],
            stops: [0.0, 0.4, 0.72, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Aurora glow – top right
            Positioned(
              top: -200 + so * 0.18 + math.sin(drift * math.pi * 2) * 2.5,
              right: -120 + math.cos(drift * math.pi * 1.7) * 1.8,
              child: _glowOrb(520, const Color(0xFF00D9FF), 0.06),
            ),
            // Aurora glow – mid left
            Positioned(
              top: h * 0.35 + so * 0.12 + math.sin((drift + 0.3) * math.pi * 2) * 2.0,
              left: -180 + math.cos((drift + 0.3) * math.pi * 1.5) * 2.2,
              child: _glowOrb(480, const Color(0xFF0077B6), 0.07),
            ),
            // Aurora glow – bottom right
            Positioned(
              bottom: -260 + so * 0.10 + math.sin((drift + 0.6) * math.pi * 2) * 2.8,
              right: -100 + math.cos((drift + 0.6) * math.pi * 1.9) * 1.5,
              child: _glowOrb(600, const Color(0xFF023E8A), 0.09),
            ),

            // Stars with twinkling
            ..._stars(w, h, so, _twinkleCtrl.value),

            // Moons with micro-drift
            _par(left: w * 0.04, base: 240, so: so, r: 0.32, drift: drift, driftAmp: 3.2,
                child: _MoonWidget(size: 120, color: const Color(0xFFB5D8E8))),
            _par(right: w * 0.05, base: 560, so: so, r: 0.25, drift: drift, driftAmp: 2.8,
                child: _MoonWidget(size: 88, color: const Color(0xFF6EC6C6))),
            _par(left: w * 0.22, base: 1080, so: so, r: 0.20, drift: drift, driftAmp: 2.2,
                child: _MoonWidget(size: 105, color: const Color(0xFF8DBBD4))),

            // Dark planets with micro-drift
            _par(right: w * 0.16, base: 155, so: so, r: 0.44, drift: drift, driftAmp: 3.5,
                child: _PlanetWidget(size: 44, body: const Color(0xFF1A0B32), ringColor: const Color(0xFF4B1080), hasRing: true)),
            _par(left: w * 0.52, base: 430, so: so, r: 0.36, drift: drift, driftAmp: 2.6,
                child: _PlanetWidget(size: 30, body: const Color(0xFF0B2514), ringColor: Colors.transparent, hasRing: false)),
            _par(left: w * 0.07, base: 695, so: so, r: 0.28, drift: drift, driftAmp: 3.0,
                child: _PlanetWidget(size: 52, body: const Color(0xFF0E1E38), ringColor: const Color(0xFF1C3A62), hasRing: true)),
            _par(right: w * 0.11, base: 940, so: so, r: 0.24, drift: drift, driftAmp: 2.4,
                child: _PlanetWidget(size: 26, body: const Color(0xFF1E0B0E), ringColor: Colors.transparent, hasRing: false)),
            _par(left: w * 0.60, base: 1260, so: so, r: 0.30, drift: drift, driftAmp: 2.9,
                child: _PlanetWidget(size: 36, body: const Color(0xFF181805), ringColor: const Color(0xFF38380A), hasRing: true)),

            // Tiny dark asteroid orbs with micro-drift
            ..._asteroids(w, h, so, drift),

            // Shooting stars
            ..._buildShootingStars(w, h),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShootingStars(double w, double h) {
    return _shootingStars.map((star) {
      final opacity = (1.0 - star.progress) * star.baseOpacity;
      return Positioned(
        left: star.x,
        top: star.y,
        child: Transform.rotate(
          angle: star.angle,
          child: Container(
            width: star.length,
            height: star.thickness,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: opacity),
                  Colors.white.withValues(alpha: opacity * 0.5),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  static Widget _glowOrb(double size, Color c, double a) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [c.withValues(alpha: a), Colors.transparent]),
    ),
  );

  static Widget _par({double? left, double? right, required double base,
      required double so, required double r, required double drift, required double driftAmp, required Widget child}) {
    final top = base + so * r + math.sin(drift * math.pi * 2) * driftAmp;
    final offsetX = math.cos((drift + (left ?? right ?? 0) * 0.1) * math.pi * 1.8) * (driftAmp * 0.6);
    if (left != null) return Positioned(left: left + offsetX, top: top, child: child);
    return Positioned(right: right! + offsetX, top: top, child: child);
  }

  static List<Widget> _stars(double w, double h, double so, double twinkle) {
    final rng = math.Random(17);
    return List.generate(100, (i) {
      final x = rng.nextDouble() * w;
      final baseY = rng.nextDouble() * h * 2.8;
      final y = (baseY + so * 0.5) % (h * 1.7);
      final sz = rng.nextDouble() * 1.8 + 0.3;
      final baseOp = rng.nextDouble() * 0.65 + 0.25;
      
      // Subtle twinkling — each star at different phase
      final phase = rng.nextDouble() * math.pi * 2;
      final twinkleAmount = math.sin(twinkle * math.pi * 2 + phase) * 0.15;
      final op = (baseOp + twinkleAmount).clamp(0.15, 0.90);
      
      return Positioned(
        left: x, top: y,
        child: Container(
          width: sz, height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: op),
            boxShadow: sz > 1.4
                ? [BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: op * 0.22), blurRadius: 3)]
                : null,
          ),
        ),
      );
    });
  }

  static List<Widget> _asteroids(double w, double h, double so, double drift) {
    final rng = math.Random(53);
    const colors = [Color(0xFF0C1D2B), Color(0xFF180B1E), Color(0xFF091C1C), Color(0xFF131009), Color(0xFF100C0C)];
    return List.generate(24, (i) {
      final x = rng.nextDouble() * w;
      final baseY = rng.nextDouble() * h * 3.0;
      final y = (baseY + so * 0.55) % (h * 1.9);
      final sz = rng.nextDouble() * 9 + 3;
      final col = colors[i % colors.length];
      
      // Micro-motion for asteroids
      final driftX = math.sin((drift + i * 0.05) * math.pi * 2) * 1.5;
      final driftY = math.cos((drift + i * 0.07) * math.pi * 1.5) * 1.2;
      
      return Positioned(
        left: x + driftX, top: y + driftY,
        child: Container(
          width: sz, height: sz * (0.6 + rng.nextDouble() * 0.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sz * 0.45),
            color: col.withValues(alpha: 0.9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 0.5),
          ),
        ),
      );
    });
  }
}

// ── Shooting star model ──────────────────────────────────────────────────────
class _ShootingStar {
  final double startX, startY;
  final double endX, endY;
  final double thickness;
  final double length;
  final double angle;
  final double baseOpacity;
  final DateTime spawnTime;
  double progress = 0.0;

  _ShootingStar({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.thickness,
    required this.length,
    required this.angle,
    required this.baseOpacity,
    required this.spawnTime,
  });

  double get x => startX + (endX - startX) * progress;
  double get y => startY + (endY - startY) * progress;

  factory _ShootingStar.random(double screenWidth, double screenHeight) {
    final rng = math.Random();

    // Random start position OUTSIDE the visible screen
    // Choose random edge (top, left, or top-left corner area)
    final edge = rng.nextInt(3);
    late double startX, startY;
    
    if (edge == 0) {
      // Top edge
      startX = rng.nextDouble() * screenWidth;
      startY = -50 - rng.nextDouble() * 200;
    } else if (edge == 1) {
      // Left edge
      startX = -50 - rng.nextDouble() * 200;
      startY = rng.nextDouble() * screenHeight * 0.7;
    } else {
      // Top-left diagonal
      startX = -100 - rng.nextDouble() * 300;
      startY = -100 - rng.nextDouble() * 300;
    }

    // End position: travel across screen
    // Random direction: mostly rightward/downward but can vary
    final travelAngle = rng.nextDouble() * (math.pi / 3) + (math.pi / 6); // 30-90 degrees
    final distance = rng.nextDouble() * 400 + 300; // 300-700 pixels
    final endX = startX + math.cos(travelAngle) * distance;
    final endY = startY + math.sin(travelAngle) * distance;

    // Very thin, but variable
    final thickness = rng.nextDouble() * 0.8 + 0.2; // 0.2 to 1.0
    final length = rng.nextDouble() * 120 + 80; // 80 to 200

    // Angle of the streak
    final dx = endX - startX;
    final dy = endY - startY;
    final angle = math.atan2(dy, dx);

    // Faint opacity
    final baseOpacity = rng.nextDouble() * 0.35 + 0.15; // 0.15 to 0.5

    return _ShootingStar(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      thickness: thickness,
      length: length,
      angle: angle,
      baseOpacity: baseOpacity,
      spawnTime: DateTime.now(),
    );
  }
}

// ── Moon widget ──────────────────────────────────────────────────────────────
class _MoonWidget extends StatelessWidget {
  final double size;
  final Color color;
  const _MoonWidget({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MoonPainter(color: color),
    size: Size(size, size),
  );
}

class _MoonPainter extends CustomPainter {
  final Color color;
  const _MoonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color.withValues(alpha: 0.86));

    // Shadow side
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    // 3 crater zones, uneven
    final rng = math.Random(color.toARGB32());
    _craterZone(canvas, Offset(cx * 0.52, cy * 0.58), r, rng);
    _craterZone(canvas, Offset(cx * 1.38, cy * 1.28), r, rng);
    _craterZone(canvas, Offset(cx * 1.08, cy * 0.40), r, rng);

    // Rim highlight
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
  }

  void _craterZone(Canvas canvas, Offset zone, double moonR, math.Random rng) {
    final radii = [0.060, 0.040, 0.027];
    for (int i = 0; i < 3; i++) {
      final cr = moonR * radii[i];
      final off = Offset(rng.nextDouble() * 12 - 6, rng.nextDouble() * 12 - 6);
      canvas.drawCircle(zone + off, cr, Paint()..color = Colors.black.withValues(alpha: 0.28));
      canvas.drawCircle(zone + off, cr, Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke..strokeWidth = 0.6);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.color != color;
}

// ── Planet widget ────────────────────────────────────────────────────────────
class _PlanetWidget extends StatelessWidget {
  final double size;
  final Color body;
  final Color ringColor;
  final bool hasRing;
  const _PlanetWidget({required this.size, required this.body, required this.ringColor, required this.hasRing});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PlanetPainter(body: body, ring: ringColor, hasRing: hasRing),
    size: Size(size, size),
  );
}

class _PlanetPainter extends CustomPainter {
  final Color body, ring;
  final bool hasRing;
  const _PlanetPainter({required this.body, required this.ring, required this.hasRing});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    if (hasRing) _drawRing(canvas, Offset(cx, cy), r, behind: true);
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = body.withValues(alpha: 0.92));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..shader = RadialGradient(center: const Alignment(-0.4, -0.4),
        colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent])
          .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = ring.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0);
    if (hasRing) _drawRing(canvas, Offset(cx, cy), r, behind: false);
  }

  void _drawRing(Canvas canvas, Offset c, double pr, {required bool behind}) {
    final rect = Rect.fromCenter(center: c + const Offset(0, 4), width: pr * 2.9, height: pr * 0.55);
    final p = Paint()
      ..color = ring.withValues(alpha: behind ? 0.55 : 0.35)
      ..style = PaintingStyle.stroke..strokeWidth = pr * 0.22;
    canvas.drawArc(rect, behind ? math.pi : 0, math.pi, false, p);
  }

  @override
  bool shouldRepaint(_PlanetPainter o) => o.body != body || o.hasRing != hasRing;
}
