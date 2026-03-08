/// GamificationPopupService & GamificationPopup - Celebratory Status Notifications
/// 
/// Displays motivational popups with animations and sounds when events are 
/// completed, missed, or attendance is marked.
/// 
/// Features:
/// - Pop-up animations with celebratory effects for completed events
/// - Positive/neutral/negative animations based on event status
/// - Point/streak calculation and display
/// - Sound effects for engaging feedback
/// - Custom messages based on event type
/// 
/// Enhances user engagement through gamification mechanics and positive reinforcement.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../backend/data_provider.dart';
import 'theme.dart';

class GamificationPopupService {
  /// Shared AudioPlayer for gamification sounds. Exposed so other services
  /// (e.g. StreakTierPopupService) can stop it before playing their own sound.
  static final AudioPlayer audioPlayer = AudioPlayer();

  /// Stop gamification audio immediately (call before playing tier sounds).
  static Future<void> stopAudio() async {
    try { await audioPlayer.stop(); } catch (_) {}
  }

  /// Show the gamification popup.
  ///
  /// [context] must be a valid, mounted BuildContext (call this BEFORE
  /// popping the calling dialog so the context is still in the tree).
  static Future<void> showEventStatusPopup(
    BuildContext context,
    String eventTitle,
    String statusType, // 'completed', 'missed', 'cancelled', 'present', 'absent'
  ) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final now = DateTime.now();
    final statsBefore = dataProvider.getDayGamificationStats(now);

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (dialogContext) => GamificationPopup(
        eventTitle: eventTitle,
        statusType: statusType,
        statsBefore: statsBefore,
      ),
    );
  }
}

class GamificationPopup extends StatefulWidget {
  final String eventTitle;
  final String statusType;
  final Map<String, int> statsBefore;

  const GamificationPopup({
    super.key,
    required this.eventTitle,
    required this.statusType,
    required this.statsBefore,
  });

  @override
  State<GamificationPopup> createState() => _GamificationPopupState();
}

class _GamificationPopupState extends State<GamificationPopup>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _bounceController;
  late AnimationController _particleController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    
    // Slide in animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // Scale pulse animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _slideController.forward();
    _bounceController.forward();
    _particleController.repeat();
    _scaleController.repeat();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _playSound();
    });

    // Auto close after 4 seconds
    _autoCloseTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _playSound() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (dataProvider.muteRingtone) return;

    try {
      GamificationPopupService.audioPlayer.stop().then(
        (_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')),
      );
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _slideController.dispose();
    _bounceController.dispose();
    _particleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getPopupConfig();
    final accentColor = config['primaryColor'] as Color;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Floating counter particles (behind popup)
          ..._buildFloatingCounters(accentColor),
          
          // Main popup
          SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
              ),
              child: _buildMainContent(context, accentColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCounters(Color accentColor) {
    return List.generate(3, (index) {
      final baseDelay = index * 300;
      return Positioned(
        left: 50 + (index * 30).toDouble(),
        bottom: 100.0,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -1.5),
          ).animate(
            CurvedAnimation(
              parent: _particleController,
              curve: Interval(
                (baseDelay / 1600).clamp(0.0, 1.0),
                ((baseDelay + 800) / 1600).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(
                parent: _particleController,
                curve: Interval(
                  (baseDelay / 1600).clamp(0.0, 1.0),
                  ((baseDelay + 800) / 1600).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                '+${(index + 1) * 10}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMainContent(BuildContext context, Color accentColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF111827);
    final textColorSecondary = isDarkMode
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF4B5563);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 340,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A).withValues(alpha: 0.95),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF9FAFB).withValues(alpha: 0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.5 : 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0.4 : 0.15),
            blurRadius: 60,
            spreadRadius: 10,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.08),
            blurRadius: 40,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top decorative line
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0),
                  accentColor,
                  accentColor.withValues(alpha: 0),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 32),

          // Animated emoji/icon
          ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1).animate(
              CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
            ),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating gradient ring
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(parent: _particleController, curve: Curves.linear),
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            accentColor.withValues(alpha: 0),
                            accentColor.withValues(alpha: 0.4),
                            accentColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Emoji
                  Text(
                    _getPopupConfig()['emoji'] as String,
                    style: const TextStyle(
                      fontSize: 55,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title with shimmer effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [accentColor, accentColor.withValues(alpha: 0.6), accentColor],
              stops: const [0, 0.5, 1],
            ).createShader(bounds),
            child: Text(
              _getPopupConfig()['title'] as String,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 18),

          // Event name badge with glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: isDarkMode ? 0.5 : 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              widget.eventTitle,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 28),

          // Motivational message
          Text(
            _getPopupConfig()['message'] as String,
            style: TextStyle(
              color: textColorSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.5,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 36),

          // Stats Display with animations
          _buildAnimatedStatsDisplay(context, accentColor),

          const SizedBox(height: 28),

          // Bottom decorative line
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0),
                  accentColor,
                  accentColor.withValues(alpha: 0),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatsDisplay(BuildContext context, Color accentColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF111827);
    final textColorSecondary = isDarkMode
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF6B7280);

    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        final statsNow = dataProvider.getDayGamificationStats(DateTime.now());
        final successful = statsNow['successful'] ?? 0;
        final unsuccessful = statsNow['unsuccessful'] ?? 0;

        return Column(
          children: [
            Text(
              "TODAY'S PROGRESS",
              style: TextStyle(
                color: textColorSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                // Success stat
                Expanded(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _bounceController,
                        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.successGreen.withValues(alpha: 0.2),
                            AppTheme.successGreen.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.successGreen.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.successGreen.withValues(alpha: 0.3),
                                  AppTheme.successGreen.withValues(alpha: 0.15),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.successGreen.withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '✓',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$successful',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: textColorSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Unsuccessful stat
                Expanded(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _bounceController,
                        curve: const Interval(0.3, 0.9, curve: Curves.elasticOut),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.errorRed.withValues(alpha: 0.2),
                            AppTheme.errorRed.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorRed.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.errorRed.withValues(alpha: 0.3),
                                  AppTheme.errorRed.withValues(alpha: 0.15),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.errorRed.withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '✕',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$unsuccessful',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Missed',
                            style: TextStyle(
                              color: textColorSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _getPopupConfig() {
    switch (widget.statusType) {
      case 'completed':
        return {
          'bgTop': const Color(0xFF4CAF50).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFF45a049).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFF4CAF50),
          'titleColor': Colors.white,
          'emoji': '🎉',
          'title': 'LOCKED IN!',
          'message': 'You absolutely crushed it! Keep that momentum going! 🔥',
        };
      case 'present':
        return {
          'bgTop': const Color(0xFF2196F3).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFF1976D2).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFF2196F3),
          'titleColor': Colors.white,
          'emoji': '⭐',
          'title': 'PERFECT!',
          'message': 'Perfect attendance! You\'re on fire! Let\'s keep it up!',
        };
      case 'missed':
        return {
          'bgTop': const Color(0xFFFF6B6B).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFFEE5A52).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFFFF6B6B),
          'titleColor': Colors.white,
          'emoji': '😞',
          'title': 'MISSED',
          'message': 'Next time you got this! Don\'t give up! 💪',
        };
      case 'absent':
        return {
          'bgTop': const Color(0xFFFF9800).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFFF57C00).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFFFF9800),
          'titleColor': Colors.white,
          'emoji': '😴',
          'title': 'ABSENT',
          'message': 'Make sure to catch the next one! You can do it!',
        };
      case 'cancelled':
        return {
          'bgTop': const Color(0xFF9C27B0).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFF8E24AA).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFF9C27B0),
          'titleColor': Colors.white,
          'emoji': 'ℹ️',
          'title': 'CANCELLED',
          'message': 'Event was cancelled - no worries at all!',
        };
      default:
        return {
          'bgTop': const Color(0xFF2196F3).withValues(alpha: 0.85),
          'bgBottom': const Color(0xFF1976D2).withValues(alpha: 0.85),
          'primaryColor': const Color(0xFF2196F3),
          'titleColor': Colors.white,
          'emoji': '✓',
          'title': 'MARKED',
          'message': 'Event status recorded!',
        };
    }
  }
}
