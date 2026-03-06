/// AuthScreen - User Login Interface
/// 
/// Login screen for user authentication with email/password support.
/// 
/// Features:
/// - Email/password login form
/// - "Forgot Password" link for password recovery
/// - Sign up redirect for new users
/// - Multi-factor authentication (MFA) option
/// - OTP verification on sign-up
/// - Avatar customisation on successful sign-up (after OTP verification)
/// - Persistent session tracking (saved in SharedPreferences)
/// - Form validation
/// 
/// On successful sign-up: OTP verification → Avatar customisation → MainNavigation.
/// On successful login: (MFA if enabled) → MainNavigation.
/// On failed login, displays error message with retry option.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'main_navigation.dart';
import 'forgot_password_page.dart';
import 'otp_screen.dart';
import 'avatar_customizer.dart';
import 'space_background.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;

  const AuthScreen({super.key, this.isSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  late AnimationController _enterCtrl;
  late Animation<double> _eyebrowAnim, _titleAnim, _formAnim, _buttonAnim;

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.isSignUp;
    
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();

    _eyebrowAnim = _interval(0.0, 0.25);
    _titleAnim = _interval(0.15, 0.50);
    _formAnim = _interval(0.40, 0.75);
    _buttonAnim = _interval(0.65, 1.00);
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(parent: _enterCtrl,
          curve: Interval(begin, end, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _enterCtrl.dispose();
    _scrollCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        
        await dataProvider.signIn();

        if (dataProvider.mfaEnabled && _isLogin) {
          // Route through OTP screen before entering the app
          setState(() => _isLoading = false);
          final verified = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const OtpScreen(),
            ),
          );
          if (verified == true && mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainNavigation(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                            parent: animation, curve: Curves.easeOutCubic),
                      ),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        } else if (!_isLogin) {
          // For sign up, always show OTP screen
          setState(() => _isLoading = false);
          final verified = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const OtpScreen(),
            ),
          );
          if (verified == true && mounted) {
            // After OTP verification on sign-up, show avatar customiser
            final selectedAvatar = await showDialog<Avatar>(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: AvatarCustomizer(
                    initialAvatar: Avatar(),
                    onAvatarSelected: (avatar) {},
                  ),
                ),
              ),
            );
            
            if (selectedAvatar != null && mounted) {
              // Save the selected avatar
              await dataProvider.setAvatar(selectedAvatar);
              
              // Navigate to home
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MainNavigation(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                              parent: animation, curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            }
          }
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigation(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      }
    }
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

          // ── Back button ──────────────────────────────────────────────────
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
                constraints: BoxConstraints(minHeight: mq.size.height - 100),
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
                            child: Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
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
                            Text(_isLogin ? 'Welcome Back' : 'Get Started',
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
                                _isLogin 
                                    ? 'Sign in to your ClassFlow account and manage your academic life effortlessly.'
                                    : 'Create your ClassFlow account and unlock a world of seamless scheduling and organisation.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16, color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.7, fontWeight: FontWeight.w400, letterSpacing: 0.15),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 44),

                      // Form
                      _fade(_formAnim, _lift(_formAnim,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name field (sign up only)
                              if (!_isLogin) ...[
                                _buildFormField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  prefixIcon: Icons.person_outline,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email field
                              _buildFormField(
                                label: 'Email',
                                controller: _emailController,
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              _buildFormField(
                                label: 'Password',
                                controller: _passwordController,
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                        ? Icons.visibility_outlined 
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white.withValues(alpha: 0.50),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Forgot password link
                              if (_isLogin) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: Text('Forgot Password?',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12, 
                                        color: const Color(0xFF00D9FF).withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline)),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      )),

                      // Buttons
                      _fade(_buttonAnim, _lift(_buttonAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Submit button
                            GestureDetector(
                              onTap: _isLoading ? null : _submitForm,
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
                                  child: _isLoading
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
                                          _isLogin ? 'Sign In' : 'Sign Up',
                                          style: GoogleFonts.spaceGrotesk(
                                            color: const Color(0xFF040D18),
                                            fontSize: 17, fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin 
                                      ? 'Don\'t have an account? ' 
                                      : 'Already have an account? ',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13, 
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w400),
                                ),
                                GestureDetector(
                                  onTap: _toggleMode,
                                  child: Text(
                                    _isLogin ? 'Sign Up' : 'Sign In',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: const Color(0xFF00D9FF),
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 12, color: Colors.white.withValues(alpha: 0.65),
          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.25), fontSize: 15),
          prefixIcon: Icon(prefixIcon, 
            color: const Color(0xFF00D9FF).withValues(alpha: 0.60), size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF00D9FF).withValues(alpha: 0.60), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.60)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFFFF6B6B), width: 1.5),
          ),
          errorStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFFFF6B6B)),
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

