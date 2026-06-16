import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24);
    final isDark = context.isDarkMode;
    // Base color for the glass effect (white for both, or slightly tinted)
    final glassColor = color ?? Colors.white;
    
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glassColor.withOpacity(isDark ? 0.12 : 0.6),
                glassColor.withOpacity(isDark ? 0.02 : 0.2),
              ],
            ),
            borderRadius: effectiveBorderRadius,
            border: border ?? Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 20,
                spreadRadius: -5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
