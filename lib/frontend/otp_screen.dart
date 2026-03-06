/// OtpScreen - One-Time Password Verification
/// 
/// Verification screen for multi-factor authentication during sign-up.
/// Redesigned with parallax scrollable background matching entry page aesthetics.
/// 
/// Features:
/// - 6-digit OTP input with individual digit boxes
/// - Auto-focus movement between boxes
/// - Shake animation on incorrect OTP
/// - Resend OTP option with countdown timer
/// - Auto-clear and auto-advance on digit entry
/// - Error state indicators
/// - Loading state during verification
/// - Parallax space background
/// - Staggered entrance animations
/// 
/// User enters OTP sent via email/SMS to verify account creation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'space_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  // One controller per digit box — lets us read and clear each field independently.
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _scrollCtrl = ScrollController();

  bool _hasError = false;
  bool _isVerifying = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  late AnimationController _enterCtrl;
  late Animation<double> _eyebrowAnim, _titleAnim, _otpAnim, _buttonAnim;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();

    _eyebrowAnim = _interval(0.0, 0.25);
    _titleAnim = _interval(0.15, 0.50);
    _otpAnim = _interval(0.40, 0.75);
    _buttonAnim = _interval(0.65, 1.00);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(parent: _enterCtrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    _enterCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Joins all six fields into a single string for validation.
  String get _otpValue => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpValue.length < 6) {
      _triggerError();
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Intentionally permissive: any 6-digit number passes.
    // Replace this check with a real TOTP or backend validation later.
    final isValid = RegExp(r'^\d{6}$').hasMatch(_otpValue);

    if (isValid) {
      // Return true to auth_screen so it can proceed to MainNavigation.
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isVerifying = false);
      _triggerError();
    }
  }

  void _triggerError() {
    setState(() => _hasError = true);
    _shakeController.forward(from: 0).then((_) {
      // Clear error highlight after the animation settles so the user
      // isn't staring at red fields while they type the next attempt.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _hasError = false);
      });
    });
    // Clear all fields and refocus the first box for a clean retry.
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        // Auto-advance to the next box as soon as a digit is entered.
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered — dismiss keyboard and verify immediately
        // without requiring the user to tap the button.
        _focusNodes[index].unfocus();
        _verify();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    // Handle backspace on an empty field by jumping back to the previous box.
    // Without this, the user would be stuck unable to correct earlier digits.
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _goBack() {
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Parallax space background ────────────────────────────────────
          AnimatedBuilder(
            animation: _scrollCtrl,
            builder: (_, __) => SpaceBackground(
              scrollOffset: _scrollCtrl.hasClients ? _scrollCtrl.offset : 0,
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
                      // Eyebrow badge
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
                            child: Text('VERIFY ACCOUNT',
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
                            Text('Confirm Your Identity',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 42, fontWeight: FontWeight.w900,
                                  color: Colors.white, height: 1.15, letterSpacing: 0.4)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Enter the 6-digit code sent to your email address to verify this is really you.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16, color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.15),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 48),

                      // OTP input boxes
                      _fade(_otpAnim, _lift(_otpAnim,
                        child: Column(
                          children: [
                            // Shake the entire row of boxes on a failed attempt.
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                final offset = _shakeController.isAnimating
                                    ? 8 *
                                        (0.5 - (_shakeAnimation.value - 0.5).abs()) *
                                        (_shakeAnimation.value < 0.5 ? -1 : 1)
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(offset * 4, 0),
                                  child: child,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Expanded(
                                    child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: KeyboardListener(
                                      focusNode: FocusNode(),
                                      onKeyEvent: (event) => _onKeyEvent(index, event),
                                      child: SizedBox(
                                        height: 64,
                                        child: TextFormField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          maxLength: 1,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: _hasError 
                                                ? const Color(0xFFFF6B6B)
                                                : Colors.white,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero,
                                            filled: true,
                                            fillColor: _hasError
                                                ? const Color(0xFFFF6B6B).withValues(alpha: 0.08)
                                                : Colors.white.withValues(alpha: 0.05),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _hasError
                                                    ? const Color(0xFFFF6B6B)
                                                    : const Color(0xFF00D9FF).withValues(alpha: 0.25),
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _hasError
                                                    ? const Color(0xFFFF6B6B)
                                                    : const Color(0xFF00D9FF).withValues(alpha: 0.25),
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _hasError 
                                                    ? const Color(0xFFFF6B6B)
                                                    : const Color(0xFF00D9FF),
                                                width: 2.5,
                                              ),
                                            ),
                                          ),
                                          onChanged: (value) =>
                                              _onDigitEntered(index, value),
                                        ),
                                      ),
                                    ),
                                  ),
                                  );
                                }),
                              ),
                            ),

                            if (_hasError) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Invalid code. Please try again.',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFFF6B6B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),

                      const SizedBox(height: 48),

                      // Buttons
                      _fade(_buttonAnim, _lift(_buttonAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Verify button
                            GestureDetector(
                              onTap: _isVerifying ? null : _verify,
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
                                child: Center(
                                  child: _isVerifying
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              const Color(0xFF040D18).withValues(alpha: 0.85),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Verify Code',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF040D18),
                                            fontSize: 17, fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Cancel button
                            GestureDetector(
                              onTap: _goBack,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF00D9FF).withValues(alpha: 0.38),
                                      width: 1.2),
                                  color: const Color(0xFF00D9FF).withValues(alpha: 0.05),
                                ),
                                child: Center(
                                  child: Text('Cancel and Go Back',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(alpha: 0.90),
                                      fontSize: 15, fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Back button (on top of scroll so taps register) ─────────────────────
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
