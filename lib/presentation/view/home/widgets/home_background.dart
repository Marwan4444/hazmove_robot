import 'package:flutter/material.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';

class HomeBackground extends StatelessWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.isDarkMode
              ? [
                  Colors.black,
                  const Color(0xFF110500),
                  const Color(0xFF662200),
                  Colors.orange.shade800,
                ]
              : [
                  Colors.white,
                  const Color(0xFFFFF0E5),
                  const Color(0xFFFFD1B3),
                  Colors.orange.shade400,
                ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ),
      ),
    );
  }
}
