import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../modules/robot_control/domain/entities/robot_arm_entity.dart';
import '../../../../core/extensions/theme_extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Isometric 3D Robot Arm Simulator
// ─────────────────────────────────────────────────────────────────────────────
class RobotArmVisualization extends StatelessWidget {
  final RobotArmEntity? robotArm;
  final bool isConnected;

  const RobotArmVisualization({
    super.key,
    this.robotArm,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF111520)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? context.accentPrimary.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'SIMULATOR VIEW',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
          // ── Status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SimStatusBar(robotArm: robotArm, isConnected: isConnected),
          ),
          const SizedBox(height: 6),
          // ── 3D Canvas
          SizedBox(
            height: 218,
            child: CustomPaint(
              size: const Size(double.infinity, 218),
              painter: IsometricRobotPainter(
                robotArm: robotArm,
                isDarkMode: context.isDarkMode,
                accentColor: context.accentPrimary,
              ),
            ),
          ),
          // ── Ruler
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: _RulerWidget(
              robotArm: robotArm,
              isDarkMode: context.isDarkMode,
              accentColor: context.accentPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Bar Widget
// ─────────────────────────────────────────────────────────────────────────────
class _SimStatusBar extends StatelessWidget {
  final RobotArmEntity? robotArm;
  final bool isConnected;

  const _SimStatusBar({required this.robotArm, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final connected = isConnected && robotArm != null;
    final mode = robotArm?.mode.name.toUpperCase() ?? 'MANUAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.black.withOpacity(0.35)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorder.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          _StatusChip(
            dot: connected ? context.accentGreen : Colors.grey,
            label: 'STATUS',
            value: connected ? 'CONNECTED' : 'OFFLINE',
            valueColor: connected ? context.accentGreen : context.textSecondary,
            context: context,
          ),
          _vLine(context),
          _StatusChip(
            icon: Icons.settings_input_component_outlined,
            label: 'MODE',
            value: mode,
            context: context,
          ),
          _vLine(context),
          _StatusChip(
            icon: Icons.speed_outlined,
            label: 'SPEED',
            value: '1X',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _vLine(BuildContext context) => Expanded(
        child: Center(
          child: Container(
            width: 1,
            height: 24,
            color: context.cardBorder,
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final Color? dot;
  final IconData? icon;
  final String label;
  final String value;
  final Color? valueColor;
  final BuildContext context;

  const _StatusChip({
    this.dot,
    this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Expanded(
      flex: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (dot != null) ...[
            _GlowDot(color: dot!),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, color: context.textSecondary, size: 12),
            const SizedBox(width: 4),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.textHint,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? context.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  final Color color;
  const _GlowDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.75), blurRadius: 7, spreadRadius: 1),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ruler Widget
// ─────────────────────────────────────────────────────────────────────────────
class _RulerWidget extends StatelessWidget {
  final RobotArmEntity? robotArm;
  final bool isDarkMode;
  final Color accentColor;

  const _RulerWidget({
    required this.robotArm,
    required this.isDarkMode,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final pos = robotArm?.linearRail.currentPosition ?? 50.0;
    return Column(
      children: [
        SizedBox(
          height: 20,
          child: CustomPaint(
            size: const Size(double.infinity, 20),
            painter: _RulerPainter(
              isDarkMode: isDarkMode,
              position: pos,
              accentColor: accentColor,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['0 cm', '25 cm', '50 cm', '75 cm', '100 cm']
              .map((l) => Text(
                    l,
                    style: TextStyle(
                      color: context.textHint,
                      fontSize: 7.5,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter: Isometric 3D Robot
// ─────────────────────────────────────────────────────────────────────────────
class IsometricRobotPainter extends CustomPainter {
  final RobotArmEntity? robotArm;
  final bool isDarkMode;
  final Color accentColor;

  IsometricRobotPainter({
    required this.robotArm,
    required this.isDarkMode,
    required this.accentColor,
  });

  late double _ox;
  late double _oy;

  static const double _sc = 10.8;

  Offset _p(double x, double y, double z) {
    const double cos30 = 0.866025;
    const double sin30 = 0.5;
    return Offset(
      _ox + (x - y) * _sc * cos30,
      _oy + (x + y) * _sc * sin30 - z * _sc,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ox = size.width * 0.47;
    _oy = size.height * 0.73;

    _drawGrid(canvas, size);
    _drawRail(canvas);

    if (robotArm != null) {
      _drawRobot(canvas);
    } else {
      _drawGhostArm(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.03)
      ..strokeWidth = 0.5;
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawRail(Canvas canvas) {
    final platformTop  = isDarkMode ? const Color(0xFF263040) : const Color(0xFFCBD5E1);
    final platformFront= isDarkMode ? const Color(0xFF1E2A38) : const Color(0xFFB0BAC8);
    final platformSide = isDarkMode ? const Color(0xFF16202C) : const Color(0xFF94A3B8);
    final trackTop     = isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final trackFront   = isDarkMode ? const Color(0xFF374151) : const Color(0xFF6B7280);
    final trackSide    = isDarkMode ? const Color(0xFF1F2937) : const Color(0xFF4B5563);
    final sleeperC     = isDarkMode ? const Color(0xFF1A2330) : const Color(0xFFD1D5DB);

    _drawIsoBox(canvas, -10, -1.6, -0.35, 20, 3.2, 0.35,
        top: platformTop, front: platformFront, side: platformSide);
    _drawIsoBox(canvas, -10, -1.3, 0, 20, 0.3, 0.5,
        top: trackTop, front: trackFront, side: trackSide);
    _drawIsoBox(canvas, -10, 0.9, 0, 20, 0.3, 0.5,
        top: trackTop, front: trackFront, side: trackSide);

    for (double x = -9.5; x <= 9.5; x += 2.6) {
      _drawIsoBox(canvas, x - 0.12, -1.3, 0, 0.24, 2.2, 0.18,
          top: sleeperC,
          front: Color.lerp(sleeperC, Colors.black, 0.22)!,
          side: Color.lerp(sleeperC, Colors.black, 0.42)!);
    }
  }

  void _drawRobot(Canvas canvas) {
    final arm = robotArm!;
    final railX = arm.linearRail.currentPosition / 5.0 - 10.0;
    final baseRad = arm.baseRotation.currentDegrees * math.pi / 180.0;
    final armDirX = math.sin(baseRad);
    final armDirY = -math.cos(baseRad);

    final shoulderDeg = arm.servos[1].currentAngle.toDouble();
    final elbowDeg    = arm.servos[2].currentAngle.toDouble();
    final wristDeg    = arm.servos[3].currentAngle.toDouble();
    final gripperDeg  = arm.servos[4].currentAngle.toDouble();

    final theta0 = (90.0 - shoulderDeg) * math.pi / 180.0;
    final theta1 = theta0 + (elbowDeg  - 90.0) * math.pi / 180.0;
    final theta2 = theta1 + (wristDeg  - 45.0) * math.pi / 180.0;

    const double baseTopZ  = 2.1;
    const double lowerLen  = 3.6;
    const double upperLen  = 2.9;
    const double wristLen  = 1.9;

    final j0 = [railX, 0.0, baseTopZ];
    final j1 = [
      j0[0] + lowerLen * math.sin(theta0) * armDirX,
      j0[1] + lowerLen * math.sin(theta0) * armDirY,
      j0[2] + lowerLen * math.cos(theta0),
    ];
    final j2 = [
      j1[0] + upperLen * math.sin(theta1) * armDirX,
      j1[1] + upperLen * math.sin(theta1) * armDirY,
      j1[2] + upperLen * math.cos(theta1),
    ];
    final j3 = [
      j2[0] + wristLen * math.sin(theta2) * armDirX,
      j2[1] + wristLen * math.sin(theta2) * armDirY,
      j2[2] + wristLen * math.cos(theta2),
    ];

    final p0 = _p(j0[0], j0[1], j0[2]);
    final p1 = _p(j1[0], j1[1], j1[2]);
    final p2 = _p(j2[0], j2[1], j2[2]);
    final p3 = _p(j3[0], j3[1], j3[2]);

    _drawIsoBox(
      canvas, railX - 1.5, -1.5, 0, 3.0, 3.0, 1.3,
      top:   Color.lerp(accentColor, Colors.white, 0.22)!,
      front: accentColor,
      side:  Color.lerp(accentColor, Colors.black, 0.42)!,
    );
    _drawIsoBox(
      canvas, railX - 0.8, -0.8, 1.3, 1.6, 1.6, 0.85,
      top:   Color.lerp(accentColor, Colors.white, 0.06)!,
      front: Color.lerp(accentColor, Colors.black, 0.28)!,
      side:  Color.lerp(accentColor, Colors.black, 0.58)!,
    );

    const armBodyColor = Color(0xFF5A6478);
    _drawArmSegment(canvas, p0, p1, 15.0, armBodyColor);
    _drawArmSegment(canvas, p1, p2, 11.0, armBodyColor);
    _drawArmSegment(canvas, p2, p3,  8.0, armBodyColor);

    _drawGripper(canvas, p2, p3, gripperDeg);

    _drawJointBall(canvas, p0, 9.0, const Color(0xFF3D4A5C));
    _drawJointBall(canvas, p1, 7.5, const Color(0xFF3D4A5C));
    _drawJointBall(canvas, p2, 6.0, const Color(0xFF3D4A5C));
    _drawJointBall(canvas, p3, 5.0, accentColor.withOpacity(0.90));

    _drawRotationArc(canvas, p1, 22, accentColor, -math.pi / 2,  math.pi * 0.48);
    _drawRotationArc(canvas, p2, 17, accentColor, -math.pi * 0.85, math.pi * 0.62);

    _drawJointLabel(canvas, p1, 'J3', '${elbowDeg.round()}°',   const Offset(16, -24));
    _drawJointLabel(canvas, p2, 'J4', '${wristDeg.round()}°',   const Offset(-58, -8));
    _drawJointLabel(canvas, p3, 'J5', '${gripperDeg.round()}°', const Offset(-55,  6));

    _drawRailPositionLabel(canvas, _p(railX, 0, 0),
        arm.linearRail.currentPosition);
  }

  void _drawIsoBox(
    Canvas canvas,
    double x, double y, double z,
    double w, double d, double h, {
    required Color top,
    required Color front,
    required Color side,
  }) {
    final tfl = _p(x,   y,   z + h);
    final tfr = _p(x+w, y,   z + h);
    final tbr = _p(x+w, y+d, z + h);
    final tbl = _p(x,   y+d, z + h);
    final bfl = _p(x,   y,   z    );
    final bfr = _p(x+w, y,   z    );
    final bbr = _p(x+w, y+d, z    );

    _fillFace(canvas, [tfl, tfr, bfr, bfl], front);
    _fillFace(canvas, [tfr, tbr, bbr, bfr], side);
    _fillFace(canvas, [tfl, tfr, tbr, tbl], top);
  }

  void _fillFace(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7);
  }

  void _drawArmSegment(Canvas canvas, Offset from, Offset to, double width, Color color) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 2) return;

    final nx = -dy / len;
    final ny =  dx / len;
    final hw = width / 2;

    final face = Path()
      ..moveTo(from.dx + nx * hw, from.dy + ny * hw)
      ..lineTo(to.dx   + nx * hw, to.dy   + ny * hw)
      ..lineTo(to.dx   - nx * hw, to.dy   - ny * hw)
      ..lineTo(from.dx - nx * hw, from.dy - ny * hw)
      ..close();

    canvas.drawPath(face, Paint()..color = color);

    const de = 4.5;
    final shadow = Path()
      ..moveTo(from.dx + nx * hw,      from.dy + ny * hw     )
      ..lineTo(to.dx   + nx * hw,      to.dy   + ny * hw     )
      ..lineTo(to.dx   + nx * hw + de, to.dy   + ny * hw + de)
      ..lineTo(from.dx + nx * hw + de, from.dy + ny * hw + de)
      ..close();

    canvas.drawPath(shadow, Paint()..color = Colors.black.withOpacity(0.38));

    canvas.drawLine(
      Offset(from.dx - nx * hw, from.dy - ny * hw),
      Offset(to.dx   - nx * hw, to.dy   - ny * hw),
      Paint()
        ..color = Colors.white.withOpacity(0.10)
        ..strokeWidth = 1.5,
    );

    canvas.drawPath(face, Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  void _drawJointBall(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(Offset(c.dx + 1.5, c.dy + 1.5), r,
        Paint()..color = Colors.black.withOpacity(0.35));
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(c, r * 0.60, Paint()
      ..color = accentColor.withOpacity(0.55));
    canvas.drawCircle(
      Offset(c.dx - r * 0.28, c.dy - r * 0.30),
      r * 0.32,
      Paint()..color = Colors.white.withOpacity(0.30),
    );
  }

  void _drawRotationArc(Canvas canvas, Offset center, double radius, Color color,
      double startAngle, double sweepAngle) {
    final paint = Paint()
      ..color = color.withOpacity(0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false, paint,
    );

    final endA = startAngle + sweepAngle;
    final ax = center.dx + radius * math.cos(endA);
    final ay = center.dy + radius * math.sin(endA);
    final tang = endA + math.pi / 2;

    canvas.drawLine(Offset(ax, ay),
      Offset(ax + 6.5 * math.cos(tang - 0.45), ay + 6.5 * math.sin(tang - 0.45)), paint);
    canvas.drawLine(Offset(ax, ay),
      Offset(ax + 6.5 * math.cos(tang + 0.45), ay + 6.5 * math.sin(tang + 0.45)), paint);
  }

  void _drawJointLabel(Canvas canvas, Offset joint, String jName, String angle, Offset offset) {
    final px = joint.dx + offset.dx;
    final py = joint.dy + offset.dy;

    final bgColor = isDarkMode ? const Color(0xFF0B0F18) : const Color(0xFF1E293B);

    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(
          text: '$jName ',
          style: TextStyle(
            color: accentColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(
          text: angle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    const padH = 6.5;
    const padV = 4.0;
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(px - padH, py - padV,
          tp.width + padH * 2, tp.height + padV * 2),
      const Radius.circular(7),
    );

    canvas.drawRRect(pill, Paint()..color = bgColor);
    canvas.drawRRect(pill, Paint()
      ..color = accentColor.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9);

    canvas.drawLine(
      joint,
      Offset(px + tp.width / 2, py + tp.height / 2),
      Paint()
        ..color = accentColor.withOpacity(0.28)
        ..strokeWidth = 0.8,
    );

    tp.paint(canvas, Offset(px, py));
  }

  void _drawGripper(Canvas canvas, Offset wrist, Offset tip, double gripperDeg) {
    final dx = tip.dx - wrist.dx;
    final dy = tip.dy - wrist.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 2) return;

    final ux = dx / len;
    final uy = dy / len;
    final nx = -uy;
    final ny =  ux;

    final opening = (gripperDeg / 180.0) * 18.0 + 4.0;

    canvas.drawLine(
      tip,
      Offset(tip.dx + ux * 9, tip.dy + uy * 9),
      Paint()
        ..color = const Color(0xFF4A5568)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    final base = Offset(tip.dx + ux * 9, tip.dy + uy * 9);

    final fingerPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final lf = Offset(base.dx + ux * 18 + nx * opening, base.dy + uy * 18 + ny * opening);
    canvas.drawLine(base, lf, fingerPaint);
    canvas.drawCircle(lf, 4.0, Paint()..color = const Color(0xFF4A5568));

    final rf = Offset(base.dx + ux * 18 - nx * opening, base.dy + uy * 18 - ny * opening);
    canvas.drawLine(base, rf, fingerPaint);
    canvas.drawCircle(rf, 4.0, Paint()..color = const Color(0xFF4A5568));

    canvas.drawCircle(tip, 5, Paint()..color = accentColor.withOpacity(0.55));
  }

  void _drawRailPositionLabel(Canvas canvas, Offset pos, double positionCm) {
    final paint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(pos.dx, pos.dy + 6), Offset(pos.dx, pos.dy + 18), paint);
    canvas.drawLine(Offset(pos.dx - 4, pos.dy + 13), Offset(pos.dx, pos.dy + 18), paint);
    canvas.drawLine(Offset(pos.dx + 4, pos.dy + 13), Offset(pos.dx, pos.dy + 18), paint);

    final tp = TextPainter(
      text: TextSpan(
        text: '${positionCm.round()} cm',
        style: TextStyle(
          color: accentColor,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + 20));
  }

  void _drawGhostArm(Canvas canvas) {
    const ghostC = Color(0x08FFFFFF);
    _drawIsoBox(canvas, -1.5, -1.5, 0, 3.0, 3.0, 1.3,
        top: ghostC, front: ghostC, side: ghostC);
  }

  @override
  bool shouldRepaint(covariant IsometricRobotPainter old) {
    return old.robotArm != robotArm || old.isDarkMode != isDarkMode;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter: Ruler strip
// ─────────────────────────────────────────────────────────────────────────────
class _RulerPainter extends CustomPainter {
  final bool isDarkMode;
  final double position;
  final Color accentColor;

  _RulerPainter({
    required this.isDarkMode,
    required this.position,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackColor = isDarkMode ? const Color(0xFF374151) : const Color(0xFFCBD5E1);
    final tickColor  = isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height / 2 - 2, size.width, 4),
        const Radius.circular(2),
      ),
      Paint()..color = trackColor,
    );

    final aw = (position / 100.0).clamp(0.0, 1.0) * size.width;
    if (aw > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height / 2 - 2, aw, 4),
          const Radius.circular(2),
        ),
        Paint()..color = accentColor.withOpacity(0.55),
      );
    }

    for (int i = 0; i <= 20; i++) {
      final x     = (i / 20.0) * size.width;
      final major = i % 5 == 0;
      canvas.drawLine(
        Offset(x, major ? 0 : 5),
        Offset(x, major ? size.height : size.height - 5),
        Paint()
          ..color = major ? tickColor : tickColor.withOpacity(0.38)
          ..strokeWidth = major ? 1.5 : 0.8,
      );
    }

    final tx = (position / 100.0).clamp(0.0, 1.0) * size.width;
    canvas.drawCircle(Offset(tx, size.height / 2), 6, Paint()..color = accentColor);
    canvas.drawCircle(Offset(tx, size.height / 2), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.position != position || old.isDarkMode != isDarkMode;
}
