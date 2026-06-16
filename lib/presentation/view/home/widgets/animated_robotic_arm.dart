import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class AnimatedRoboticArm extends StatefulWidget {
  const AnimatedRoboticArm({super.key});

  @override
  State<AnimatedRoboticArm> createState() => _AnimatedRoboticArmState();
}

class _AnimatedRoboticArmState extends State<AnimatedRoboticArm> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value;
            return LinearGradient(
              colors: [
                Colors.transparent,
                context.accentPrimary.withOpacity(0.8), // Matched orange glow from hazemove text
                Colors.white,                           // Bright reflection
                context.accentPrimary.withOpacity(0.8),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
              begin: Alignment(-2.0 + (sweep * 4), -1.0),
              end: Alignment(0.0 + (sweep * 4), 1.0),
            ).createShader(bounds);
          },
          child: CustomPaint(
            size: const Size(320, 240),
            painter: RoboticArmPainter(
              progress: _controller.value,
              fillColor: Colors.grey.shade500.withOpacity(0.15),
              outlineColor: context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              railColor: Colors.grey.shade500.withOpacity(0.1),
              highlightColor: Colors.grey.shade300.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}

class RoboticArmPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color fillColor;
  final Color outlineColor;
  final Color railColor;
  final Color highlightColor;

  RoboticArmPainter({
    required this.progress,
    required this.fillColor,
    required this.outlineColor,
    required this.railColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 // Thinner, more elegant lines
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
      
    final Paint railPaint = Paint()
      ..color = railColor
      ..style = PaintingStyle.fill;
      
    final Paint railHighlight = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 1. Draw Sleek Linear Rail
    // We make it a modern thin double-track
    final Rect railOuter = Rect.fromLTWH(20, h - 15, w - 40, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(railOuter, const Radius.circular(5)), railPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(railOuter, const Radius.circular(5)), outlinePaint);
    
    // Draw inner glowing line for the track
    canvas.drawLine(Offset(30, h - 10), Offset(w - 30, h - 10), railHighlight);

    // 2. Calculate Base Position (sliding back and forth)
    final double curvedProgress = Curves.easeInOutSine.transform(progress);
    final double railTravel = w - 120;
    final double baseX = 60 + (railTravel * curvedProgress);
    final double baseY = h - 15;

    // Draw Sleek Base
    final Rect baseRect = Rect.fromLTWH(baseX - 25, baseY - 30, 50, 30);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(6)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(6)), outlinePaint);
    
    // Base details
    canvas.drawLine(Offset(baseX - 10, baseY - 15), Offset(baseX + 10, baseY - 15), outlinePaint..strokeWidth = 1.5);

    // Kinematics Angles based on progress
    // The arm sweeps in a realistic way while moving on the rail
    final double shoulderAngle = math.pi / 2.5 + (math.sin(curvedProgress * math.pi) * (math.pi / 4));
    final double elbowAngle = -math.pi / 1.5 + (math.cos(curvedProgress * math.pi * 2) * (math.pi / 4));
    final double wristAngle = math.pi / 4 + (math.sin(curvedProgress * math.pi * 3) * (math.pi / 6));

    // Save canvas state
    canvas.save();
    
    // Move to shoulder joint
    canvas.translate(baseX, baseY - 40);
    _drawJoint(canvas, fillPaint, outlinePaint);

    // Rotate shoulder (negative because y-axis goes down in Canvas)
    canvas.rotate(-shoulderAngle);
    
    // Draw Lower Arm
    final double lowerArmLength = 90;
    _drawArmSegment(canvas, lowerArmLength, fillPaint, outlinePaint);
    
    // Move to Elbow
    canvas.translate(lowerArmLength, 0);
    _drawJoint(canvas, fillPaint, outlinePaint);

    // Rotate elbow
    canvas.rotate(-elbowAngle);

    // Draw Upper Arm
    final double upperArmLength = 75;
    _drawArmSegment(canvas, upperArmLength, fillPaint, outlinePaint);

    // Move to Wrist
    canvas.translate(upperArmLength, 0);
    _drawJoint(canvas, fillPaint, outlinePaint);

    // Rotate wrist
    canvas.rotate(-wristAngle);

    // Draw Gripper
    _drawGripper(canvas, fillPaint, outlinePaint, progress);

    canvas.restore();
    outlinePaint.strokeWidth = 6; // Reset stroke width
  }

  void _drawArmSegment(Canvas canvas, double length, Paint fill, Paint outline) {
    // Thinner, sleeker arm segment
    final Rect armRect = Rect.fromLTWH(0, -12, length, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(armRect, const Radius.circular(12)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(armRect, const Radius.circular(12)), outline);
    
    // Draw an inner line for minimalist mechanical detail
    final Paint detailPaint = Paint()
      ..color = outline.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(20, 0), Offset(length - 20, 0), detailPaint);
  }

  void _drawJoint(Canvas canvas, Paint fill, Paint outline) {
    // Smaller, more refined joints
    canvas.drawCircle(Offset.zero, 16, fill);
    canvas.drawCircle(Offset.zero, 16, outline);
    
    final Paint innerFill = Paint()..color = outline.color;
    canvas.drawCircle(Offset.zero, 6, innerFill);
    
    final Paint highlightFill = Paint()..color = fill.color;
    canvas.drawCircle(Offset.zero, 2, highlightFill);
  }

  void _drawGripper(Canvas canvas, Paint fill, Paint outline, double progress) {
    // Jaws opening/closing rapidly to simulate grabbing
    final double jawOpen = 2 + 10 * math.sin(progress * math.pi * 8).abs();

    // Top Jaw
    final Path topJaw = Path()
      ..moveTo(8, -8)
      ..lineTo(20, -15 - jawOpen)
      ..lineTo(45, -15 - jawOpen)
      ..lineTo(55, -5 - jawOpen)
      ..lineTo(45, -5 - jawOpen)
      ..lineTo(25, -5 - jawOpen)
      ..lineTo(15, -2)
      ..close();
      
    canvas.drawPath(topJaw, fill);
    canvas.drawPath(topJaw, outline);

    // Bottom Jaw
    final Path bottomJaw = Path()
      ..moveTo(8, 8)
      ..lineTo(20, 15 + jawOpen)
      ..lineTo(45, 15 + jawOpen)
      ..lineTo(55, 5 + jawOpen)
      ..lineTo(45, 5 + jawOpen)
      ..lineTo(25, 5 + jawOpen)
      ..lineTo(15, 2)
      ..close();
      
    canvas.drawPath(bottomJaw, fill);
    canvas.drawPath(bottomJaw, outline);
    
    // Draw an extra joint circle over the base to mimic the image's wrist connection
    canvas.drawCircle(Offset(5, 0), 16, fill);
    canvas.drawCircle(Offset(5, 0), 16, outline);
  }

  @override
  bool shouldRepaint(covariant RoboticArmPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
