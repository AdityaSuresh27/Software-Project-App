/// StreakTierPopup — Planet-based Streak Rank System
///
/// Students start at Neptune (outermost planet) and work inward toward the Sun
/// by consistently completing non-class tasks on time.
///
///  PLANETS (outer  inner / weakest  strongest) 
///   0  Neptune     0–9   streak points
///   1  Uranus     10–24
///   2  Saturn     25–44
///   3  Jupiter    45–69
///   4  Mars       70–99
///   5  Earth     100–134
///   6  Venus     135–174
///   7  Mercury   175–219
///   8  Sun       220+
///
///  STREAK RULES 
///   +1   Complete any non-class task (meeting, personal, assignment, exam, etc.)
///   5   PENALTY — Mark a non-class task as Missed
///   1   Undo a completed task (before due date — no penalty, just reverting)
///   +5   Undo a missed task (reverses the penalty)
///   Class events never count.
///
///  PLANET CIRCLE 
///   PlanetCircle widget — painted circle with each planet unique look,
///   used as the profile avatar border/background ring.
///
///  SOUNDS 
///   Rank-up    assets/win.mp3   (respects muteRingtone)
///   Rank-down  assets/lose.mp3

import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'gamification_popup.dart';
import 'theme.dart';

// 
//  Planet tier data
// 

class StreakTierInfo {
  final int tier;          // 0 = Neptune (weakest), 8 = Sun (strongest)
  final String name;
  final String emoji;
  final Color color;       // Primary planet colour
  final Color glowColor;   // Glow / ring colour
  final int minStreak;
  final String description;
  final bool hasRings;     // Saturn only

  const StreakTierInfo({
    required this.tier,
    required this.name,
    required this.emoji,
    required this.color,
    required this.glowColor,
    required this.minStreak,
    required this.description,
    this.hasRings = false,
  });
}

// 
//  StreakService — tiers + helpers
// 

class StreakService {
  static const List<StreakTierInfo> tiers = [
    // 0 — Neptune
    StreakTierInfo(
      tier: 0,
      name: 'Neptune',
      emoji: '',
      color: Color(0xFF3F51B5),
      glowColor: Color(0xFF7986CB),
      minStreak: 0,
      description: 'A frozen giant, far from the Sun. Complete tasks to travel inward!',
    ),
    // 1 — Uranus
    StreakTierInfo(
      tier: 1,
      name: 'Uranus',
      emoji: '',
      color: Color(0xFF4DD0E1),
      glowColor: Color(0xFF80DEEA),
      minStreak: 10,
      description: "You're tilting the odds in your favour — keep it steady!",
    ),
    // 2 — Saturn
    StreakTierInfo(
      tier: 2,
      name: 'Saturn',
      emoji: '',
      color: Color(0xFFD4AC6E),
      glowColor: Color(0xFFE8C88A),
      minStreak: 25,
      description: 'Ringed and radiant — your consistency is on full display!',
      hasRings: true,
    ),
    // 3 — Jupiter
    StreakTierInfo(
      tier: 3,
      name: 'Jupiter',
      emoji: '',
      color: Color(0xFFD4825A),
      glowColor: Color(0xFFE8A87C),
      minStreak: 45,
      description: 'The largest planet — your work ethic is growing to match it!',
    ),
    // 4 — Mars
    StreakTierInfo(
      tier: 4,
      name: 'Mars',
      emoji: '',
      color: Color(0xFFE53935),
      glowColor: Color(0xFFEF9A9A),
      minStreak: 70,
      description: 'The red warrior planet — fighting hard for every deadline!',
    ),
    // 5 — Earth
    StreakTierInfo(
      tier: 5,
      name: 'Earth',
      emoji: '',
      color: Color(0xFF43A047),
      glowColor: Color(0xFF81C784),
      minStreak: 100,
      description: "Home turf — you're thriving in your natural habitat!",
    ),
    // 6 — Venus
    StreakTierInfo(
      tier: 6,
      name: 'Venus',
      emoji: '',
      color: Color(0xFFF9A825),
      glowColor: Color(0xFFFFD54F),
      minStreak: 135,
      description: 'Blazing bright — almost as hot as the Sun itself!',
    ),
    // 7 — Mercury
    StreakTierInfo(
      tier: 7,
      name: 'Mercury',
      emoji: '',
      color: Color(0xFF78909C),
      glowColor: Color(0xFFB0BEC5),
      minStreak: 175,
      description: 'So close to the Sun you can feel the heat. Elite dedication!',
    ),
    // 8 — Sun
    StreakTierInfo(
      tier: 8,
      name: 'Sun',
      emoji: '',
      color: Color(0xFFFDD835),
      glowColor: Color(0xFFFFEE58),
      minStreak: 220,
      description: 'You ARE the Sun — the centre of everything. Legendary!',
    ),
  ];

  /// Returns the 0-based tier index (0 = Neptune, 8 = Sun).
  static int getTierIndex(int streak) {
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (streak >= tiers[i].minStreak) return i;
    }
    return 0;
  }

  static StreakTierInfo getTierInfo(int tierIndex) =>
      tiers[tierIndex.clamp(0, tiers.length - 1)];

  /// Next planet name + required points (null when at Sun).
  static String? nextPlanetHint(int currentTierIndex) {
    if (currentTierIndex >= tiers.length - 1) return null;
    final next = tiers[currentTierIndex + 1];
    return '${next.minStreak} points to reach ${next.name} ${next.emoji}';
  }
}

// 
//  PlanetCircle — circular planet badge (profile avatar background)
// 

/// A circular painted planet badge representing the student's current rank.
/// Use as the decorative ring around a profile avatar.
///
/// ```dart
/// PlanetCircle(tierIndex: StreakService.getTierIndex(dataProvider.streakCount), size: 88)
/// ```
class PlanetCircle extends StatefulWidget {
  final int tierIndex;
  final double size;
  final bool animate;

  const PlanetCircle({
    super.key,
    required this.tierIndex,
    this.size = 88,
    this.animate = true,
  });

  @override
  State<PlanetCircle> createState() => _PlanetCircleState();
}

class _PlanetCircleState extends State<PlanetCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(PlanetCircle old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.animate && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = StreakService.getTierInfo(widget.tierIndex);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _PlanetPainter(
          info: info,
          angle: _ctrl.value * 2 * math.pi,
        ),
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  final StreakTierInfo info;
  final double angle;

  const _PlanetPainter({required this.info, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // outer glow ring
    final glowPaint = Paint()
      ..color = info.glowColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius * 0.88, glowPaint);

    // planet body (radial gradient)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.85,
        colors: [
          _lighten(info.color, 0.3),
          info.color,
          _darken(info.color, 0.3),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.72));
    canvas.drawCircle(center, radius * 0.72, bodyPaint);

    // Saturn rings (drawn on top so they clearly cross the body)
    if (info.hasRings) _drawRings(canvas, center, radius);

    // Sun rays
    if (info.tier == 8) _drawSunRays(canvas, center, radius, angle);

    // crisp border ring
    final borderPaint = Paint()
      ..color = info.glowColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.07;
    canvas.drawCircle(center, radius * 0.72, borderPaint);
  }

  void _drawRings(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, 0.30);

    final r1 = Paint()
      ..color = info.glowColor.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.10;
    canvas.drawCircle(Offset.zero, radius * 1.02, r1);

    final r2 = Paint()
      ..color = info.color.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06;
    canvas.drawCircle(Offset.zero, radius * 1.20, r2);

    canvas.restore();
  }

  void _drawSunRays(Canvas canvas, Offset center, double radius, double angle) {
    final rayPaint = Paint()
      ..color = info.glowColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final a = angle + (i * math.pi / 4);
      final innerR = radius * 0.80;
      final outerR = radius * 0.98;
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(a), center.dy + innerR * math.sin(a)),
        Offset(center.dx + outerR * math.cos(a), center.dy + outerR * math.sin(a)),
        rayPaint,
      );
    }
  }

  Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(_PlanetPainter old) =>
      old.angle != angle || old.info.tier != info.tier;
}

// 
//  StreakTierPopupService
// 

class StreakTierPopupService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> showTierChange(
    BuildContext context, {
    required int oldTier,
    required int newTier,
    required bool muteRingtone,
    required int streakCount,
  }) async {
    final rankUp = newTier > oldTier;
    if (!muteRingtone) {
      try {
        // Stop any lingering gamification popup sound first so there's no conflict
        await GamificationPopupService.stopAudio();
        await _player.stop();
        await _player.play(AssetSource(rankUp ? 'win.mp3' : 'lose.mp3'));
      } catch (e) {
        debugPrint('StreakTierPopup sound error: $e');
      }
    }

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => StreakTierPopup(
        oldTier: oldTier,
        newTier: newTier,
        streakCount: streakCount,
      ),
    );
  }
}

// 
//  StreakTierPopup widget
// 

class StreakTierPopup extends StatefulWidget {
  final int oldTier;
  final int newTier;
  final int streakCount;

  const StreakTierPopup({
    super.key,
    required this.oldTier,
    required this.newTier,
    required this.streakCount,
  });

  @override
  State<StreakTierPopup> createState() => _StreakTierPopupState();
}

class _StreakTierPopupState extends State<StreakTierPopup>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _bounceCtrl;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _bounceCtrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _slideCtrl.forward();
    _bounceCtrl.forward();
    _autoClose = Timer(const Duration(milliseconds: 5500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _slideCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  bool get _rankUp => widget.newTier > widget.oldTier;

  @override
  Widget build(BuildContext context) {
    final tierInfo = StreakService.getTierInfo(widget.newTier);
    final accentColor = _rankUp ? tierInfo.color : AppTheme.errorRed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827);
    final subColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideCtrl, curve: Curves.elasticOut),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E2A3A), const Color(0xFF0A0F1E)]
                    : [Colors.white, const Color(0xFFF0F4FF)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.65 : 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 55,
                  spreadRadius: 8,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _accentBar(accentColor),
                const SizedBox(height: 24),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.4, end: 1.0).animate(
                    CurvedAnimation(
                        parent: _bounceCtrl, curve: Curves.elasticOut),
                  ),
                  child: PlanetCircle(
                    tierIndex: widget.newTier,
                    size: 110,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.7),
                      accentColor
                    ],
                    stops: const [0, 0.5, 1],
                  ).createShader(b),
                  child: Text(
                    _rankUp ? 'RANK UP! ' : 'RANK DROPPED',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          accentColor.withValues(alpha: isDark ? 0.55 : 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tierInfo.emoji,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tierInfo.name,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              tierInfo.description,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ' ${widget.streakCount} streak points',
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _getMessage(tierInfo.name),
                  style: TextStyle(
                    color: subColor,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _buildPlanetRow(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _autoClose?.cancel();
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _rankUp ? 'Keep it up! ' : 'Bounce back! ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _accentBar(accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accentBar(Color c) => Container(
        height: 2,
        width: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withValues(alpha: 0), c, c.withValues(alpha: 0)],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      );

  Widget _buildPlanetRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(StreakService.tiers.length, (i) {
          final isCurrent = widget.newTier == i;
          final double sz = isCurrent ? 28 : 18;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: PlanetCircle(
              tierIndex: i,
              size: sz,
              animate: isCurrent,
            ),
          );
        }),
      ),
    );
  }

  String _getMessage(String name) {
    if (_rankUp) {
      switch (name) {
        case 'Uranus':
          return "You left Neptune! You're building real momentum now! ";
        case 'Saturn':
          return "You've got rings to show for it — consistency is your superpower!";
        case 'Jupiter':
          return 'The giant awakens! Your work ethic is enormous! ';
        case 'Mars':
          return 'Red-hot focus! You are a warrior of deadlines! ';
        case 'Earth':
          return "Back home at the top — you've truly found your groove! ";
        case 'Venus':
          return 'Blazing bright! Almost there — the Sun is within reach! ';
        case 'Mercury':
          return 'Elite-level dedication! One step from the ultimate rank! ';
        case 'Sun':
          return 'LEGENDARY! You reached the Sun — the centre of everything! ';
        default:
          return 'Great work! Keep the momentum going!';
      }
    }
    return "Don't give up — every planet is a stepping stone.\nYou're at $name now. Bounce back stronger! ";
  }
}
