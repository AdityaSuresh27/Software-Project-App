import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'space_background.dart';
import 'auth_screen.dart';
import 'welcome_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _eyebrowAnim, _titleAnim, _dividerAnim,
      _card1Anim, _card2Anim, _footerAnim;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();

    _eyebrowAnim = _interval(0.00, 0.28);
    _titleAnim   = _interval(0.16, 0.54);
    _dividerAnim = _interval(0.40, 0.62);
    _card1Anim   = _interval(0.50, 0.78);
    _card2Anim   = _interval(0.62, 0.90);
    _footerAnim  = _interval(0.76, 1.00);
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(parent: _enterCtrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _enterCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _go({required bool signUp}) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => AuthScreen(isSignUp: signUp),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _goBack() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => const WelcomeScreen(),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeInOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 680),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Shared galaxy background with parallax scroll ────────────────
          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, __) => SpaceBackground(
              scrollOffset: _scrollCtrl.hasClients ? _scrollCtrl.offset : 0,
            ),
          ),

          // ── Back arrow ───────────────────────────────────────────────────
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

          // ── Scrollable content ───────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: mq.size.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  // Eyebrow
                  _fade(_eyebrowAnim, _lift(_eyebrowAnim,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF00D9FF).withValues(alpha: 0.35)),
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFF00D9FF).withValues(alpha: 0.07),
                        ),
                        child: Text('GET STARTED',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 11, letterSpacing: 2.8,
                            color: const Color(0xFF00D9FF).withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700)),
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),

                  // Title
                  _fade(_titleAnim, _lift(_titleAnim,
                    child: Column(
                      children: [
                        Text('Ready to Organize?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 42, fontWeight: FontWeight.w900,
                              color: Colors.white, height: 1.15, letterSpacing: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Choose how you want to get started.\nYour academic command center awaits.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 16, color: Colors.white.withValues(alpha: 0.62),
                              height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.15)),
                        ],
                      ),
                  )),
                  const SizedBox(height: 44),

                  // Thin divider
                  _fade(_dividerAnim,
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          const Color(0xFF00D9FF).withValues(alpha: 0.0),
                          const Color(0xFF00D9FF).withValues(alpha: 0.25),
                          const Color(0xFF00D9FF).withValues(alpha: 0.0),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Create Account (primary)
                  _fade(_card1Anim, _lift(_card1Anim,
                    child: GestureDetector(
                      onTap: () => _go(signUp: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D9FF), Color(0xFF06D6D6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.30),
                                blurRadius: 32, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_rounded,
                                color: Color(0xFF040D18), size: 20),
                            const SizedBox(width: 10),
                            Text('Create Account',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF040D18),
                                fontSize: 17.5, fontWeight: FontWeight.w800,
                                letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 14),

                  // Sign In (secondary / outlined)
                  _fade(_card2Anim, _lift(_card2Anim,
                    child: GestureDetector(
                      onTap: () => _go(signUp: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF00D9FF).withValues(alpha: 0.38),
                              width: 1.2),
                          color: const Color(0xFF00D9FF).withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded,
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.85),
                                size: 20),
                            const SizedBox(width: 10),
                            Text('Sign In',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 17.5, fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 44),

                  // Footer
                  _fade(_footerAnim,
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.dmSans(
                            fontSize: 11, color: Colors.white.withValues(alpha: 0.35),
                            height: 1.7),
                          children: [
                            const TextSpan(text: 'By continuing you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              recognizer: TapGestureRecognizer()..onTap = () {},
                              style: TextStyle(
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.65),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF00D9FF).withValues(alpha: 0.40)),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              recognizer: TapGestureRecognizer()..onTap = () {},
                              style: TextStyle(
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.65),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF00D9FF).withValues(alpha: 0.40)),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
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
