import 'package:flutter/material.dart';
import 'space_background.dart';
import 'package:google_fonts/google_fonts.dart';

class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _enterCtrl;
  late Animation<double> _eyebrowAnim, _titleAnim, _featuresAnim, _contactAnim;
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();

    _eyebrowAnim = _interval(0.0, 0.25);
    _titleAnim = _interval(0.15, 0.50);
    _featuresAnim = _interval(0.40, 0.75);
    _contactAnim = _interval(0.65, 1.00);
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(parent: _enterCtrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _enterCtrl.dispose();
    _scrollCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  void _goBack() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Space background with parallax ──────────────────────────────────
          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, __) => SpaceBackground(
              scrollOffset: _scrollCtrl.hasClients ? _scrollCtrl.offset : 0,
            ),
          ),

          // ── Back button ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white.withValues(alpha: 0.55),
                onPressed: _goBack,
              ),
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: mq.size.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Eyebrow
                      _fade(_eyebrowAnim, _lift(_eyebrowAnim,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFF00D9FF).withValues(alpha: 0.07),
                          ),
                          child: Text('FOR ORGANISATIONS',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 11, letterSpacing: 2.8,
                              color: const Color(0xFF00D9FF).withValues(alpha: 0.85),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 28),

                      // Title
                      _fade(_titleAnim, _lift(_titleAnim,
                        child: Column(
                          children: [
                            Text('Empower Your Institution',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 42, fontWeight: FontWeight.w900,
                                color: Colors.white, height: 1.15, letterSpacing: 0.4)),
                            const SizedBox(height: 16),
                            // Semi-transparent background for text readability
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ClassFlow Pro connects your entire institution. Manage student-teacher timetables, co-ordinate events across departments, and keep everyone organised in one unified platform.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16, color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 48),

                      // Features
                      _fade(_featuresAnim, _lift(_featuresAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Why ClassFlow Pro?',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: 0.2)),
                            const SizedBox(height: 20),
                            _orgFeature('100+ Students', 'Manage thousands of students and staff effortlessly'),
                            _orgFeature('Smart Timetables', 'Automated class and event scheduling across departments'),
                            _orgFeature('Real-time Sync', 'All changes reflected instantly across your institution'),
                            _orgFeature('Priority Support', 'Dedicated support team ready to assist you'),
                          ],
                        ),
                      )),
                      const SizedBox(height: 52),

                      // Contact form
                      _fade(_contactAnim, _lift(_contactAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.25)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Get in Touch',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 20, fontWeight: FontWeight.w800,
                                      color: Colors.white, letterSpacing: 0.2)),
                                  const SizedBox(height: 24),
                                  _inputField('Full Name', _nameCtrl, ''),
                                  const SizedBox(height: 14),
                                  _inputField('School/Institution', _schoolCtrl, ''),
                                  const SizedBox(height: 14),
                                  _inputField('Email', _emailCtrl, ''),
                                  const SizedBox(height: 24),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Thank you! A representative will contact you within 24 hours at ${_emailCtrl.text}',
                                            style: GoogleFonts.dmSans(fontSize: 14),
                                          ),
                                          backgroundColor: const Color(0xFF00D9FF),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00D9FF), Color(0xFF06D6D6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                              color: const Color(0xFF00D9FF).withValues(alpha: 0.25),
                                              blurRadius: 24, offset: const Offset(0, 8)),
                                        ],
                                      ),
                                      child: Text('Send Inquiry',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: const Color(0xFF040D18),
                                          fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text('A representative will contact you immediately with pricing and implementation details.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.white.withValues(alpha: 0.50),
                                letterSpacing: 0.3, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orgFeature(String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: const Color(0xFF00D9FF).withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: const Color(0xFF00D9FF), letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(desc,
            style: GoogleFonts.dmSans(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.65),
              height: 1.5, fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _inputField(String label, TextEditingController ctrl, String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            style: GoogleFonts.dmSans(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.30)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.60), width: 1.5),
              ),
            ),
          ),
        ],
      );

  Widget _fade(Animation<double> anim, Widget child) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) => Opacity(opacity: anim.value.clamp(0.0, 1.0), child: child),
  );

  Widget _lift(Animation<double> anim, {required Widget child}) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, 28 * (1 - anim.value)),
      child: child,
    ),
  );
}
