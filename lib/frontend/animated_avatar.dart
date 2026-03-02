/// AnimatedAvatar - Game-like Avatar Display with Advanced Animations
/// 
/// Features:
/// - Face outline with black stroke
/// - Multiple body shapes (circle, square, rounded, hexagon)
/// - Advanced eye system with moving pupils
/// - Dynamic mouth with movement
/// - Glasses and bowtie accessories
/// - Eye blinking animation

import 'package:flutter/material.dart';
import '../backend/models.dart';

class AnimatedAvatar extends StatefulWidget {
  final Avatar avatar;
  final double size;
  final bool autoAnimate;
  final VoidCallback? onTap;

  const AnimatedAvatar({
    super.key,
    required this.avatar,
    this.size = 120,
    this.autoAnimate = true,
    this.onTap,
  });

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _eyeMoveController;
  late AnimationController _mouthController;
  late AnimationController _bodyController;
  late Animation<double> _blinkAnimation;
  late Animation<double> _eyeMoveAnimation;
  late Animation<double> _mouthAnimation;
  late Animation<double> _bodyAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.autoAnimate) {
      // Blinking animation
      _blinkController = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
      _blinkAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
      );
      Future.delayed(const Duration(seconds: 3), _startBlinkLoop);

      // Eye movement left-right
      _eyeMoveController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      _eyeMoveAnimation = Tween<double>(begin: -1, end: 1).animate(
        CurvedAnimation(parent: _eyeMoveController, curve: Curves.easeInOut),
      );
      _eyeMoveController.repeat(reverse: true);

      // Mouth movement
      _mouthController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      );
      _mouthAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
      );
      _mouthController.repeat(reverse: true);

      // Body movement
      _bodyController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      _bodyAnimation = Tween<double>(begin: -1, end: 1).animate(
        CurvedAnimation(parent: _bodyController, curve: Curves.easeInOut),
      );
      _bodyController.repeat(reverse: true);
    }
  }

  void _startBlinkLoop() {
    if (mounted) {
      _blinkController.forward().then((_) {
        // Reverse to open eyes again
        if (mounted) {
          _blinkController.reverse().then((_) {
            // Schedule next blink after 3 seconds
            Future.delayed(const Duration(seconds: 3), _startBlinkLoop);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _eyeMoveController.dispose();
    _mouthController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap?.call,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _blinkAnimation,
            _eyeMoveAnimation,
            _mouthAnimation,
            _bodyAnimation,
          ]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_bodyAnimation.value * widget.size * 0.02, 0),
              child: CustomPaint(
                painter: AvatarPainter(
                  avatar: widget.avatar,
                  blinkValue: _blinkAnimation.value,
                  eyeMoveValue: _eyeMoveAnimation.value,
                  mouthValue: _mouthAnimation.value,
                  size: widget.size,
                ),
                size: Size(widget.size, widget.size),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  final Avatar avatar;
  final double blinkValue;
  final double eyeMoveValue;
  final double mouthValue;
  final double size;

  AvatarPainter({
    required this.avatar,
    required this.blinkValue,
    required this.eyeMoveValue,
    required this.mouthValue,
    required this.size,
  });

  Color _hexToColor(String hexString) {
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final bodyColor = _hexToColor(avatar.bodyColor);
    final eyesColor = _hexToColor(avatar.eyesColor);
    final accentColor = _hexToColor(avatar.accentColor);

    final paint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.018
      ..color = Colors.black;

    // Draw body
    final bodyRadius = size * 0.35;
    paint.color = bodyColor;

    if (avatar.bodyStyle == 'circle') {
      canvas.drawCircle(center, bodyRadius, paint);
      canvas.drawCircle(center, bodyRadius, outlinePaint);
    } else if (avatar.bodyStyle == 'square') {
      final rect = Rect.fromCenter(
        center: center,
        width: bodyRadius * 2,
        height: bodyRadius * 2,
      );
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, outlinePaint);
    } else if (avatar.bodyStyle == 'rounded') {
      final rect = Rect.fromCenter(
        center: center,
        width: bodyRadius * 2,
        height: bodyRadius * 2,
      );
      final rRect = RRect.fromRectAndRadius(rect, Radius.circular(bodyRadius * 0.3));
      canvas.drawRRect(rRect, paint);
      canvas.drawRRect(rRect, outlinePaint);
    }

    // Draw facial features
    final eyeSpacing = size * 0.13;
    final eyeSize = size * 0.11;
    final leftEyeCenter = Offset(center.dx - eyeSpacing, center.dy + size * 0.02);
    final rightEyeCenter = Offset(center.dx + eyeSpacing, center.dy + size * 0.02);

    _drawEyes(canvas, leftEyeCenter, rightEyeCenter, eyeSize, eyesColor, outlinePaint);

    // Draw mouth
    final mouthY = center.dy + size * 0.18;
    _drawMouth(canvas, Offset(center.dx, mouthY), accentColor, outlinePaint);

    // Draw accessories
    if (avatar.hasGlasses) {
      _drawGlasses(canvas, leftEyeCenter, rightEyeCenter, eyeSize);
    }
  }

  void _drawEyes(
    Canvas canvas,
    Offset leftEyeCenter,
    Offset rightEyeCenter,
    double eyeSize,
    Color eyesColor,
    Paint outlinePaint,
  ) {
    if (avatar.eyesStyle == 'x_eyes') {
      // X eyes - cannot blink, positioned higher
      final linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = size * 0.022
        ..strokeCap = StrokeCap.round;
      
      final yOffset = -size * 0.02; // Move X eyes up
      final leftEyePos = Offset(leftEyeCenter.dx, leftEyeCenter.dy + yOffset);
      final rightEyePos = Offset(rightEyeCenter.dx, rightEyeCenter.dy + yOffset);
      
      // Left eye X
      canvas.drawLine(
        Offset(leftEyePos.dx - eyeSize * 0.35, leftEyePos.dy - eyeSize * 0.35),
        Offset(leftEyePos.dx + eyeSize * 0.35, leftEyePos.dy + eyeSize * 0.35),
        linePaint,
      );
      canvas.drawLine(
        Offset(leftEyePos.dx + eyeSize * 0.35, leftEyePos.dy - eyeSize * 0.35),
        Offset(leftEyePos.dx - eyeSize * 0.35, leftEyePos.dy + eyeSize * 0.35),
        linePaint,
      );
      
      // Right eye X
      canvas.drawLine(
        Offset(rightEyePos.dx - eyeSize * 0.35, rightEyePos.dy - eyeSize * 0.35),
        Offset(rightEyePos.dx + eyeSize * 0.35, rightEyePos.dy + eyeSize * 0.35),
        linePaint,
      );
      canvas.drawLine(
        Offset(rightEyePos.dx + eyeSize * 0.35, rightEyePos.dy - eyeSize * 0.35),
        Offset(rightEyePos.dx - eyeSize * 0.35, rightEyePos.dy + eyeSize * 0.35),
        linePaint,
      );
      return;
    }

    // Round or square eyes - both open with moving pupils and blinking
    _drawSingleEye(canvas, leftEyeCenter, eyeSize, eyesColor, outlinePaint);
    _drawSingleEye(canvas, rightEyeCenter, eyeSize, eyesColor, outlinePaint);
  }

  void _drawSingleEye(
    Canvas canvas,
    Offset eyeCenter,
    double eyeSize,
    Color eyesColor,
    Paint outlinePaint,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw eye white (full eye when open, closing from top and bottom when blinking)
    paint.color = Colors.white;
    
    // blinkValue goes from 0 (open) to 1 (closed)
    // When at 1, eye is fully closed, so we draw less height
    final eyeOpenness = 1 - blinkValue; // 1 when open, 0 when closed
    final eyeHeight = eyeSize * 2 * eyeOpenness;
    final eyeYOffset = -eyeSize + (eyeSize * blinkValue); // Shift up/down based on blink
    
    if (avatar.eyesStyle == 'round') {
      if (blinkValue < 0.95) {
        // Eye is mostly open - draw circle/ellipse
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(eyeCenter.dx, eyeCenter.dy + eyeYOffset),
            width: eyeSize * 2,
            height: eyeHeight,
          ),
          paint,
        );
      } else {
        // Eye is closed - just draw a line
        final linePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = size * 0.02
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(eyeCenter.dx - eyeSize * 0.8, eyeCenter.dy),
          Offset(eyeCenter.dx + eyeSize * 0.8, eyeCenter.dy),
          linePaint,
        );
        return;
      }

      // Calculate pupil position based on eye movement
      final pupilOffset = eyeMoveValue * eyeSize * 0.5;
      final pupilCenter = Offset(eyeCenter.dx + pupilOffset, eyeCenter.dy + eyeYOffset);
      
      // Draw pupil with eyesColor (bigger pupils)
      paint.color = eyesColor;
      final pupilSize = eyeSize * 0.5;
      canvas.drawCircle(pupilCenter, pupilSize, paint);
      
      // White highlight on pupil (top-right)
      paint.color = Colors.white;
      canvas.drawCircle(
        Offset(pupilCenter.dx + pupilSize * 0.35, pupilCenter.dy - pupilSize * 0.35),
        pupilSize * 0.35,
        paint,
      );
      
      // Draw eye outline
      outlinePaint.color = Colors.black;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(eyeCenter.dx, eyeCenter.dy + eyeYOffset),
          width: eyeSize * 2,
          height: eyeHeight,
        ),
        outlinePaint,
      );
    } else if (avatar.eyesStyle == 'square') {
      if (blinkValue < 0.95) {
        final rect = Rect.fromCenter(
          center: Offset(eyeCenter.dx, eyeCenter.dy + eyeYOffset),
          width: eyeSize * 2,
          height: eyeHeight,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, outlinePaint);

        // Calculate pupil position
        final pupilOffset = eyeMoveValue * eyeSize * 0.5;
        final pupilCenter = Offset(eyeCenter.dx + pupilOffset, eyeCenter.dy + eyeYOffset);
        
        // Draw pupil with eyesColor (bigger pupils)
        paint.color = eyesColor;
        final pupilSize = eyeSize * 0.45;
        final pupilRect = Rect.fromCenter(
          center: pupilCenter,
          width: pupilSize * 2,
          height: pupilSize * 2,
        );
        canvas.drawRect(pupilRect, paint);
        
        // White highlight (top-right corner)
        paint.color = Colors.white;
        canvas.drawRect(
          Rect.fromLTWH(
            pupilCenter.dx + pupilSize * 0.3,
            pupilCenter.dy - pupilSize * 0.3,
            pupilSize * 0.6,
            pupilSize * 0.6,
          ),
          paint,
        );
      } else {
        // Eye closed - horizontal line
        final linePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = size * 0.02
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(eyeCenter.dx - eyeSize * 0.8, eyeCenter.dy),
          Offset(eyeCenter.dx + eyeSize * 0.8, eyeCenter.dy),
          linePaint,
        );
      }
    }
  }

  void _drawMouth(
    Canvas canvas,
    Offset mouthCenter,
    Color mouthColor,
    Paint outlinePaint,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;
    final drawPaint = Paint()
      ..color = mouthColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.018
      ..strokeCap = StrokeCap.round;

    if (avatar.mouthStyle == 'smile') {
      // Smile with movement
      final mouthMovement = mouthValue * size * 0.02;
      drawPaint.color = mouthColor;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(mouthCenter.dx, mouthCenter.dy + mouthMovement),
          width: size * 0.2,
          height: size * 0.12,
        ),
        0,
        3.14159,
        false,
        drawPaint,
      );
    } else if (avatar.mouthStyle == 'neutral') {
      // Straight line with slight movement
      final mouthMovement = mouthValue * size * 0.01;
      drawPaint.color = mouthColor;
      canvas.drawLine(
        Offset(mouthCenter.dx - size * 0.1, mouthCenter.dy + mouthMovement),
        Offset(mouthCenter.dx + size * 0.1, mouthCenter.dy + mouthMovement),
        drawPaint,
      );
    } else if (avatar.mouthStyle == 'surprised') {
      // O mouth that expands with movement
      paint.color = mouthColor;
      final mouthRadius = size * 0.05 + (mouthValue * size * 0.01);
      canvas.drawCircle(mouthCenter, mouthRadius, paint);
      canvas.drawCircle(mouthCenter, mouthRadius, outlinePaint);
    } else if (avatar.mouthStyle == 'box') {
      // Box mouth - square with cute look and black outline
      paint.color = mouthColor;
      paint.style = PaintingStyle.fill;
      
      // Black outline for box mouth
      final blackOutline = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.018;
      
      final boxWidth = size * 0.16;
      final boxHeight = size * 0.08;
      final mouthMovement = mouthValue * size * 0.01;
      
      final rect = Rect.fromCenter(
        center: Offset(mouthCenter.dx, mouthCenter.dy + mouthMovement),
        width: boxWidth,
        height: boxHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size * 0.015)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size * 0.015)),
        blackOutline,
      );
    }
  }

  void _drawGlasses(
    Canvas canvas,
    Offset leftEye,
    Offset rightEye,
    double eyeSize,
  ) {
    final strokePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.024;

    final glassRadius = eyeSize * 1.0;
    
    // Position glasses higher and centered on eyes
    final glassYOffset = -size * 0.03;
    final leftGlassCenter = Offset(leftEye.dx, leftEye.dy + glassYOffset);
    final rightGlassCenter = Offset(rightEye.dx, rightEye.dy + glassYOffset);

    // Left glass frame
    canvas.drawCircle(leftGlassCenter, glassRadius, strokePaint);
    // Right glass frame
    canvas.drawCircle(rightGlassCenter, glassRadius, strokePaint);
    // Bridge connecting glasses
    strokePaint.strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(leftGlassCenter.dx + glassRadius - size * 0.02, leftGlassCenter.dy),
      Offset(rightGlassCenter.dx - glassRadius + size * 0.02, rightGlassCenter.dy),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) {
    return oldDelegate.blinkValue != blinkValue ||
        oldDelegate.eyeMoveValue != eyeMoveValue ||
        oldDelegate.mouthValue != mouthValue ||
        oldDelegate.avatar != avatar;
  }
}

