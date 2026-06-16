import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class PremiumAnimatedText extends StatefulWidget {
  final String text;

  const PremiumAnimatedText({super.key, required this.text});

  @override
  State<PremiumAnimatedText> createState() => _PremiumAnimatedTextState();
}

class _PremiumAnimatedTextState extends State<PremiumAnimatedText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // A 3-second cycle for a slow, premium breathing and shimmering effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  context.textPrimary.withOpacity(0.6),
                  context.accentPrimary.withOpacity(0.8), // Orange glow
                  Colors.white,                           // Bright light reflection
                  context.accentPrimary.withOpacity(0.8),
                  context.textPrimary.withOpacity(0.6),
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                begin: Alignment(_shimmerAnimation.value - 1, -1),
                end: Alignment(_shimmerAnimation.value + 1, 1),
              ).createShader(bounds);
            },
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                shadows: [
                  // Gives the text a 3D elevated look
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
