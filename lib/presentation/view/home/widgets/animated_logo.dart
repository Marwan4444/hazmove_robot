import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hazmove_robot/presentation/view/root/cubit/robot_control_cubit.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';

class AnimatedHazMoveLogo extends StatefulWidget {
  final ConnectionStatus status;

  const AnimatedHazMoveLogo({super.key, required this.status});

  @override
  State<AnimatedHazMoveLogo> createState() => _AnimatedHazMoveLogoState();
}

class _AnimatedHazMoveLogoState extends State<AnimatedHazMoveLogo> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryGlow;
    Color secondaryGlow;
    
    switch (widget.status) {
      case ConnectionStatus.connected:
        primaryGlow = context.accentGreen;
        secondaryGlow = const Color(0xFF00FFCC); // Bright Cyan
        break;
      case ConnectionStatus.connecting:
        primaryGlow = Colors.orangeAccent;
        secondaryGlow = Colors.yellow;
        break;
      case ConnectionStatus.disconnected:
        primaryGlow = Colors.orange;
        secondaryGlow = Colors.deepOrange;
        break;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _spinController]),
      builder: (context, child) {
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbital dashed ring
              Transform.rotate(
                angle: -_spinController.value * 2 * math.pi,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGlow.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              
              // Orbiting Particles System
              Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 15,
                        left: 110,
                        child: _buildParticle(primaryGlow, 8),
                      ),
                      Positioned(
                        bottom: 35,
                        right: 25,
                        child: _buildParticle(secondaryGlow, 5),
                      ),
                      Positioned(
                        top: 100,
                        left: -4,
                        child: _buildParticle(primaryGlow, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // Middle breathing glow
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlow.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: secondaryGlow.withOpacity(0.1),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                    border: Border.all(
                      color: primaryGlow.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Inner Premium Glass Core
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                // Shimmering Gradient Mask for Text & Icon
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      context.textPrimary,
                      primaryGlow,
                      context.textPrimary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment(-1.0 + (_spinController.value * 2), -1.0),
                    end: Alignment(1.0 + (_spinController.value * 2), 1.0),
                    tileMode: TileMode.mirror,
                  ).createShader(bounds),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.precision_manufacturing,
                        color: context.textPrimary, // Fallback color
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'hazemove',
                        style: TextStyle(
                          color: context.textPrimary, // Fallback color
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 10,
            spreadRadius: 3,
          )
        ],
      ),
    );
  }
}
