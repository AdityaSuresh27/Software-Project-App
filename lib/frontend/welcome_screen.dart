import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'get_started_page.dart';
import 'space_background.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();

  // Rope state – tracks how far the knot has been pulled DOWN from rest
  double _knotPull = 0.0;
  bool _showDragHint = false;

  // Header entrance controllers
  late AnimationController _headerCtrl;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;

  // Feature stagger
  late AnimationController _featureCtrl;
  late List<Animation<double>> _featureAnims;

  // Rope idle gentle sway
  late AnimationController _swayCtrl;
  late Animation<double> _swayAnim;

  static const _featureCount = 5;

  static const _features = [
    _Feature('01', 'Unified Event System',
        'Classes, exams, deadlines and assignments — all managed in one clean, intelligent view.',
        Icons.event_note_rounded, Color(0xFF00D9FF)),
    _Feature('02', 'Smart Organization',
        'Powerful filtering by subject, priority, and date. Always know what matters most right now.',
        Icons.layers_rounded, Color(0xFF06D6D6)),
    _Feature('03', 'Attendance Tracking',
        'Live attendance monitoring with a smart 75% predictor that alerts you before it is too late.',
        Icons.fact_check_rounded, Color(0xFF4FC3F7)),
    _Feature('04', 'Gamification & Streaks',
        'Earn badges, build daily streaks and unlock rewards for consistently staying on top of it all.',
        Icons.emoji_events_rounded, Color(0xFF00BFA5)),
    _Feature('05', 'Voice Notes & Files',
        'Record voice memos and attach files directly to events — your notes, exactly where you need them.',
        Icons.mic_rounded, Color(0xFF5BC8FF)),
  ];

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();
    _titleFade = CurvedAnimation(parent: _headerCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic));
    _subtitleFade = CurvedAnimation(parent: _headerCtrl,
        curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic));

    _featureCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _featureAnims = List.generate(_featureCount, (i) {
      final s = i * 0.15;
      final e = (s + 0.32).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _featureCtrl,
          curve: Interval(s, e, curve: Curves.easeOutQuint));
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _featureCtrl.forward();
    });

    _swayCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _swayAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
        CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _headerCtrl.dispose();
    _featureCtrl.dispose();
    _swayCtrl.dispose();
    super.dispose();
  }

  void _navigateForward() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => const GetStartedPage(),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeInOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 680),
    ));
  }

  void _onRopeDrag(DragUpdateDetails d) {
    // Positive dy = dragging DOWN — that's what we want to trigger navigation
    setState(() {
      _knotPull = (_knotPull + d.delta.dy).clamp(-10.0, 200.0);
      if (_knotPull > 140) {
        _knotPull = 0;
        _navigateForward();
      }
    });
  }

  void _onRopeDragEnd(DragEndDetails _) {
    setState(() => _knotPull = 0.0);
  }

  void _onRopeTap() => setState(() => _showDragHint = !_showDragHint);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    // Rope widget spans full height so knot can move freely
    final ropeRestY = screenH * 0.46; // knot rests here when idle
    final knotY = ropeRestY + _knotPull;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _scroll,
            builder: (_, __) => SpaceBackground(
              scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────
          SingleChildScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(mq),
                _sectionLabel('FEATURES'),
                ..._features.asMap().entries.map((e) => _featureCard(e.value, e.key)),
                _ctaSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Rope ─────────────────────────────────────────────────────────
          Positioned(
            right: 18,
            top: 0,
            width: 28,
            height: screenH,
            child: GestureDetector(
              onVerticalDragUpdate: _onRopeDrag,
              onVerticalDragEnd: _onRopeDragEnd,
              onTap: _onRopeTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _swayAnim,
                builder: (_, __) => CustomPaint(
                  painter: _RopePainter(
                    knotY: knotY,
                    idleSway: _swayAnim.value,
                  ),
                ),
              ),
            ),
          ),

          // ── Drag hint bubble ─────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            right: 52,
            top: knotY - 14,
            child: AnimatedOpacity(
              opacity: _showDragHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.15), blurRadius: 12),
                    ],
                  ),
                  child: Text('Pull down ↓',
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: const Color(0xFF00D9FF),
                      fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(MediaQueryData mq) {
    return Padding(
      padding: EdgeInsets.only(
        top: mq.padding.top + 64,
        bottom: 56,
        left: 28,
        right: 52, // leave room for the rope
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow chip
          AnimatedBuilder(
            animation: _titleFade,
            builder: (_, __) => Opacity(
              opacity: _titleFade.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.07),
                ),
                child: Text('ACADEMIC PLANNER',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, letterSpacing: 2.8,
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ClassFlow — guaranteed single line
          AnimatedBuilder(
            animation: _titleFade,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -32 * (1 - _titleFade.value)),
              child: Opacity(
                opacity: _titleFade.value,
                child: ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB0E8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(r),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('ClassFlow',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        height: 1.0,
                      )),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Thin accent underline
          AnimatedBuilder(
            animation: _titleFade,
            builder: (_, __) => Opacity(
              opacity: _titleFade.value,
              child: Container(
                width: 56,
                height: 3.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9FF), Color(0xFF06D6D6)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Typewriter subtitle — starts when subtitleFade is non-zero
          AnimatedBuilder(
            animation: _subtitleFade,
            builder: (_, __) => Opacity(
              opacity: _subtitleFade.value,
              child: _subtitleFade.value > 0.05
                  ? _Typewriter(
                      key: const ValueKey('sub'),
                      text: 'Your academic journey,\nbeautifully organized.',
                      duration: const Duration(milliseconds: 3600),
                      style: GoogleFonts.dmSans(
                        fontSize: 19,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.25,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 36),

          // Scroll indicator
          AnimatedBuilder(
            animation: _subtitleFade,
            builder: (_, __) => Opacity(
              opacity: (_subtitleFade.value * 0.55).clamp(0, 0.55),
              child: Row(
                children: [
                  Icon(Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 8),
                  Text('Scroll to explore features',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                      letterSpacing: 0.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
    child: Row(
      children: [
        Container(width: 20, height: 1.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF00D9FF).withValues(alpha: 0),
              const Color(0xFF00D9FF).withValues(alpha: 0.5)
            ]),
          )),
        const SizedBox(width: 12),
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 10.5, letterSpacing: 3.4,
            color: const Color(0xFF00D9FF).withValues(alpha: 0.6),
            fontWeight: FontWeight.w700)),
      ],
    ),
  );

  // ── Feature card ────────────────────────────────────────────────────────────

  Widget _featureCard(_Feature f, int idx) {
    return AnimatedBuilder(
      animation: _featureAnims[idx],
      builder: (_, child) {
        final v = _featureAnims[idx].value;
        return Opacity(
          opacity: v.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, 32 * (1 - v)), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: f.color.withValues(alpha: 0.18), width: 1),
            boxShadow: [
              BoxShadow(
                color: f.color.withValues(alpha: 0.06),
                blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Faint background number
                Positioned(
                  right: -4, bottom: -8,
                  child: Text(f.number,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: f.color.withValues(alpha: 0.055),
                      height: 1,
                    )),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            f.color.withValues(alpha: 0.22),
                            f.color.withValues(alpha: 0.06),
                          ]),
                          border: Border.all(color: f.color.withValues(alpha: 0.35), width: 1),
                        ),
                        child: Icon(f.icon, color: f.color, size: 24),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: 0.2)),
                            const SizedBox(height: 8),
                            Text(f.description,
                              style: GoogleFonts.dmSans(
                                fontSize: 13.5, color: Colors.white.withValues(alpha: 0.62),
                                height: 1.6, fontWeight: FontWeight.w400, letterSpacing: 0.1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CTA ─────────────────────────────────────────────────────────────────────

  Widget _ctaSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF00D9FF).withValues(alpha: 0.0),
                const Color(0xFF00D9FF).withValues(alpha: 0.30),
                const Color(0xFF00D9FF).withValues(alpha: 0.0),
              ]),
            ),
          ),
          const SizedBox(height: 42),

          // Solid CTA button
          GestureDetector(
            onTap: _navigateForward,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF06D6D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00D9FF).withValues(alpha: 0.30),
                    blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Text('Begin Your Journey',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF040D18),
                  fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
          ),
          const SizedBox(height: 18),

          // Rope hint
          Text('or pull the rope on the right →',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12, letterSpacing: 0.4, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Rope Painter ─────────────────────────────────────────────────────────────
//
// Top anchor: (cx, 2)  — fixed at top of widget
// Knot:       (cx + idleSway, knotY) — moves DOWN when user drags
// Catenary approximated with a cubic Bezier for natural drape

class _RopePainter extends CustomPainter {
  final double knotY;   // absolute Y of the knot (in widget space)
  final double idleSway;

  const _RopePainter({required this.knotY, required this.idleSway});

  @override
  void paint(Canvas canvas, Size size) {
    if (knotY <= 0) return;
    final cx = size.width / 2;
    const anchorY = 2.0;

    final knotX = cx + idleSway;
    final ky = knotY.clamp(anchorY + 10, size.height);

    // Control points for a natural hanging curve
    final cp1x = cx + idleSway * 0.25;
    final cp1y = anchorY + (ky - anchorY) * 0.35;
    final cp2x = knotX - idleSway * 0.15;
    final cp2y = anchorY + (ky - anchorY) * 0.72;

    final path = Path()
      ..moveTo(cx, anchorY)
      ..cubicTo(cp1x, cp1y, cp2x, cp2y, knotX, ky);

    // Dark shadow/depth strand (left offset)
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF001F3F).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round);

    // Main rope body (thicker)
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF0099CC).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round);

    // Mid-tone fiber strands
    for (int i = 0; i < 3; i++) {
      final offset = Offset(
        math.sin(i * math.pi / 1.5) * 1.2,
        math.cos(i * 0.7) * 0.8,
      );
      final strandPath = Path()
        ..moveTo(cx + offset.dx, anchorY + offset.dy)
        ..cubicTo(cp1x + offset.dx * 0.5, cp1y, cp2x + offset.dx * 0.3, cp2y, knotX + offset.dx * 0.4, ky);
      canvas.drawPath(strandPath, Paint()
        ..color = const Color(0xFF00D9FF).withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round);
    }

    // Soft outer glow
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Bright highlight thread (right side)
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round);

    // Anchor pin at top (more realistic)
    final pinRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, anchorY + 6), width: 9, height: 14),
      const Radius.circular(2));
    canvas.drawRRect(pinRect, Paint()
      ..color = const Color(0xFF003D6B).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill);
    canvas.drawRRect(pinRect, Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);

    // Rope ending knot with better detail
    // Outer glow
    canvas.drawCircle(Offset(knotX, ky), 16, Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // Main knot body
    canvas.drawCircle(Offset(knotX, ky), 9, Paint()
      ..color = const Color(0xFF0099CC).withValues(alpha: 0.95));
    // Highlight
    canvas.drawCircle(Offset(knotX - 2.5, ky - 2.5), 3, Paint()
      ..color = Colors.white.withValues(alpha: 0.40));
    // Rim
    canvas.drawCircle(Offset(knotX, ky), 9, Paint()
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_RopePainter o) => o.knotY != knotY || o.idleSway != idleSway;
}

// ── Typewriter widget ─────────────────────────────────────────────────────────

class _Typewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  const _Typewriter({super.key, required this.text, this.style, required this.duration});

  @override
  State<_Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<_Typewriter> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _chars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)..forward();
    _chars = IntTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _chars,
      builder: (_, __) {
        final shown = widget.text.substring(0, _chars.value);
        final typing = _chars.value < widget.text.length;
        final cursorA = typing ? (0.25 + 0.75 * math.sin(_ctrl.value * 28).abs()) : 0.0;
        return RichText(
          text: TextSpan(text: shown, style: widget.style, children: typing
              ? [TextSpan(text: '▍', style: (widget.style ?? const TextStyle()).copyWith(
                  color: const Color(0xFF00D9FF).withValues(alpha: cursorA),
                  fontSize: (widget.style?.fontSize ?? 16) * 0.72))]
              : []),
        );
      },
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Feature {
  final String number, title, description;
  final IconData icon;
  final Color color;
  const _Feature(this.number, this.title, this.description, this.icon, this.color);
}
